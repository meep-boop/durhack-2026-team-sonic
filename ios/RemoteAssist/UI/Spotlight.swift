import Observation
import QuartzCore
import SwiftUI

/// The spotlight's decisions, kept pure so they can be tested: how the beam eases, when it's worth redrawing, and when
/// the target counts as on screen. Redrawing only on real movement is the whole point: a beam that re-rendered every
/// tick kept the GPU and main thread so busy that taps timed out and ARKit's frames piled up.
enum SpotlightPolicy {
  /// One easing step towards `target`, snapping once every edge is within 1.5 pt so a still target settles exactly.
  static func ease(from previous: CGRect?, to target: CGRect) -> CGRect {
    guard let previous else { return target }
    let close = abs(previous.minX - target.minX) < 1.5 && abs(previous.minY - target.minY) < 1.5
      && abs(previous.width - target.width) < 1.5 && abs(previous.height - target.height) < 1.5
    if close { return target }
    let t: CGFloat = 0.35
    return CGRect(
      x: previous.minX + (target.minX - previous.minX) * t, y: previous.minY + (target.minY - previous.minY) * t,
      width: previous.width + (target.width - previous.width) * t, height: previous.height + (target.height - previous.height) * t
    )
  }

  /// Worth publishing: some edge moved by more than a point.
  static func moved(_ a: CGRect, _ b: CGRect) -> Bool {
    abs(a.minX - b.minX) > 1 || abs(a.minY - b.minY) > 1 || abs(a.width - b.width) > 1 || abs(a.height - b.height) > 1
  }

  /// On screen, with hysteresis: a showing beam stays until its centre is 40 pt off screen; a hidden one comes back
  /// only once the centre is 20 pt inside. No flicker at the border.
  static func onScreen(centre: CGPoint, bounds: CGRect, wasBeam: Bool) -> Bool {
    bounds.insetBy(dx: wasBeam ? -40 : 20, dy: wasBeam ? -40 : 20).contains(centre)
  }

  /// Which way to move the phone for a target off screen (`direction`: x right, y down), in words anyone can follow
  /// without reading the guide: the bigger component wins.
  static func turn(for direction: CGVector) -> (words: String, symbol: String) {
    if abs(direction.dx) >= abs(direction.dy) {
      return direction.dx >= 0 ? ("Turn right", "arrow.right") : ("Turn left", "arrow.left")
    }
    return direction.dy >= 0 ? ("Look down", "arrow.down") : ("Look up", "arrow.up")
  }

  /// The projected points' bounding box, padded, at least big enough to read as a beam, clipped to the screen.
  static func beamRect(around points: [CGPoint], in bounds: CGRect) -> CGRect? {
    guard let first = points.first else { return nil }
    var rect = points.dropFirst().reduce(CGRect(origin: first, size: .zero)) { $0.union(CGRect(origin: $1, size: .zero)) }
    rect = rect.insetBy(dx: -44, dy: -44)
    if rect.width < 150 { rect = rect.insetBy(dx: -(150 - rect.width) / 2, dy: 0) }
    if rect.height < 150 { rect = rect.insetBy(dx: 0, dy: -(150 - rect.height) / 2) }
    let clipped = rect.intersection(bounds)
    return clipped.isNull ? nil : clipped
  }
}

/// Follows what the user should look at and says where it is on screen: in a beam, or off one edge.
/// A 15 Hz timer projects the target, but `state` only changes when something visibly moved.
///
/// A timer, not a CADisplayLink: with ARKit's delegate on main, this display link asking for 10–20 fps froze the camera
/// (RealityKit got about 17 of 60 drawables, "nextDrawable returning nil" every other frame). Measured on an iPhone 16,
/// iOS 26.3.1: the same build with a timer drew all 60, and so did the display link with the delegate off main.
@Observable
final class SpotlightTracker {
  enum State: Equatable {
    case hidden
    /// On screen: the area to light up, in view points.
    case beam(CGRect, label: String)
    /// Off screen: which way to turn (unit vector, x right, y down).
    case edge(CGVector, label: String)
  }

  private(set) var state: State = .hidden
  /// Bumped when the target swings into view, for a haptic. Read only by the overlay.
  private(set) var arrivals = 0
  /// Off after the user taps the dimmed area; back on for the next step or the expert's next pin.
  var enabled = true

  @ObservationIgnored private weak var ar: ARSessionController?
  @ObservationIgnored private var timer: Timer?
  @ObservationIgnored private var smoothed: CGRect?

  func start(_ ar: ARSessionController) {
    self.ar = ar
    guard timer == nil else { return }
    let timer = Timer(timeInterval: 1.0 / 15, repeats: true) { [weak self] _ in self?.tick() }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    smoothed = nil
    setState(.hidden)
  }

  private func tick() {
    guard enabled, let ar, let target = ar.spotlightTarget(), !target.points.isEmpty else {
      smoothed = nil
      setState(.hidden)
      return
    }
    let bounds = ar.arView.bounds
    let projected = target.points.compactMap(ar.project)
    let wasBeam: Bool
    if case .beam = state { wasBeam = true } else { wasBeam = false }

    if projected.count == target.points.count, let rect = SpotlightPolicy.beamRect(around: projected, in: bounds),
       SpotlightPolicy.onScreen(centre: CGPoint(x: rect.midX, y: rect.midY), bounds: bounds, wasBeam: wasBeam) {
      let eased = SpotlightPolicy.ease(from: wasBeam ? smoothed : nil, to: rect)
      smoothed = eased
      if !wasBeam { arrivals += 1 }
      if case .beam(let shown, let label) = state, label == target.label, !SpotlightPolicy.moved(shown, eased) { return }
      setState(.beam(eased, label: target.label))
    } else {
      smoothed = nil
      let centroid = target.points.reduce(.zero, +) / Float(target.points.count)
      guard let direction = ar.screenDirection(to: centroid) else { return setState(.hidden) }
      // Only a real change of side redraws the edge glow.
      if case .edge(let shown, let label) = state, label == target.label,
         abs(shown.dx - direction.dx) < 0.15, abs(shown.dy - direction.dy) < 0.15 { return }
      setState(.edge(direction, label: target.label))
    }
  }

  private func setState(_ new: State) {
    if new != state { state = new }
  }
}

/// Everything dims except a soft beam over the work area, like a torch. Off screen, the edge facing it glows.
struct SpotlightOverlay: View {
  let tracker: SpotlightTracker

  var body: some View {
    GeometryReader { proxy in
      switch tracker.state {
      case .hidden:
        Color.clear.allowsHitTesting(false)
      case .beam(let rect, let label):
        beam(rect, label: label, size: proxy.size)
      case .edge(let direction, let label):
        edgeGlow(direction, label: label, size: proxy.size)
      }
    }
    .ignoresSafeArea()
    .animation(.easeInOut(duration: 0.25), value: stateKind)
    // Here, not on the main screen: observing the tracker there re-rendered the whole UI with every beam update.
    .sensoryFeedback(.selection, trigger: tracker.arrivals)
  }

  private var stateKind: Int {
    switch tracker.state {
    case .hidden: 0
    case .beam: 1
    case .edge: 2
    }
  }

  private func beam(_ rect: CGRect, label: String, size: CGSize) -> some View {
    ZStack(alignment: .topLeading) {
      // One even-odd fill and a few strokes: no blur filter and no offscreen pass, so a redraw costs almost nothing.
      Canvas { context, size in
        let radius = min(rect.width, rect.height) / 3
        var dim = Path(CGRect(origin: .zero, size: size))
        dim.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
        context.fill(dim, with: .color(.black.opacity(0.5)), style: FillStyle(eoFill: true))
        let edge = Path(roundedRect: rect, cornerRadius: radius)
        context.stroke(edge, with: .color(Theme.accent.opacity(0.18)), lineWidth: 14)
        context.stroke(edge, with: .color(Theme.accent.opacity(0.35)), lineWidth: 6)
        context.stroke(edge, with: .color(Theme.accent), lineWidth: 2)
      }
      // Taps inside the beam reach the AR view (to tick pins); a tap on the dimmed area turns the spotlight off.
      .contentShape(DimmedArea(hole: rect), eoFill: true)
      .onTapGesture { tracker.enabled = false }

      Label(label, systemImage: "light.max")
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassBackground(in: Capsule())
        .fixedSize()
        .position(x: rect.midX, y: min(rect.maxY + 22, size.height - 40))
        .allowsHitTesting(false)
    }
    .transition(.opacity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Spotlight on \(label). Tap outside it to turn the spotlight off.")
  }

  private func edgeGlow(_ direction: CGVector, label: String, size: CGSize) -> some View {
    let point = Self.edgePoint(direction, in: size)
    return ZStack {
      RadialGradient(colors: [Theme.accent.opacity(0.75), .clear], center: .center, startRadius: 0, endRadius: 170)
        .frame(width: 340, height: 340)
        .position(point)
      // Words and a big arrow, not just a glow: anyone holding the phone knows which way to move it.
      let turn = SpotlightPolicy.turn(for: direction)
      VStack(spacing: 4) {
        Image(systemName: turn.symbol).font(.system(size: 34, weight: .bold))
        Text(turn.words).font(.headline.weight(.bold))
        Text(label).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.75))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .glassBackground(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .fixedSize()
      .position(Self.inset(point, toward: CGPoint(x: size.width / 2, y: size.height / 2), by: 90))
    }
    .allowsHitTesting(false)
    .transition(.opacity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(label) is off screen. \(SpotlightPolicy.turn(for: direction).words).")
  }

  /// Where a ray from the screen centre along `direction` leaves the screen.
  static func edgePoint(_ direction: CGVector, in size: CGSize) -> CGPoint {
    let centre = CGPoint(x: size.width / 2, y: size.height / 2)
    let tx = direction.dx == 0 ? .infinity : (direction.dx > 0 ? size.width - centre.x : -centre.x) / direction.dx
    let ty = direction.dy == 0 ? .infinity : (direction.dy > 0 ? size.height - centre.y : -centre.y) / direction.dy
    let t = min(tx, ty)
    return CGPoint(x: centre.x + direction.dx * t, y: centre.y + direction.dy * t)
  }

  private static func inset(_ point: CGPoint, toward centre: CGPoint, by distance: CGFloat) -> CGPoint {
    let dx = centre.x - point.x, dy = centre.y - point.y
    let length = max(hypot(dx, dy), 1)
    return CGPoint(x: point.x + dx / length * distance, y: point.y + dy / length * distance)
  }
}

/// The whole screen minus the beam, for hit-testing with even-odd fill.
private struct DimmedArea: Shape {
  let hole: CGRect

  func path(in rect: CGRect) -> Path {
    var path = Path(rect)
    path.addRoundedRect(in: hole, cornerSize: CGSize(width: 24, height: 24))
    return path
  }
}
