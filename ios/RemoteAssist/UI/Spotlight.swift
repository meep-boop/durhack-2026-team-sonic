import Observation
import QuartzCore
import SwiftUI

/// Follows what the user should look at and says where it is on screen: in a beam, or off one edge.
/// A display link at 30 Hz projects the target; the beam eases toward it so it never jitters with tracking noise.
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
  /// Bumped every time the target swings into view, for a haptic.
  private(set) var arrivals = 0
  /// Off after the user taps the dimmed area; back on for the next step or the expert's next pin.
  var enabled = true

  @ObservationIgnored private weak var ar: ARSessionController?
  @ObservationIgnored private var link: CADisplayLink?
  @ObservationIgnored private var smoothed: CGRect?

  func start(_ ar: ARSessionController) {
    self.ar = ar
    guard link == nil else { return }
    let link = CADisplayLink(target: self, selector: #selector(tick))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 20, maximum: 30, preferred: 30)
    link.add(to: .main, forMode: .common)
    self.link = link
  }

  func stop() {
    link?.invalidate()
    link = nil
    state = .hidden
  }

  @objc private func tick() {
    guard enabled, let ar, let target = ar.spotlightTarget(), !target.points.isEmpty else {
      setState(.hidden)
      return
    }
    let bounds = ar.arView.bounds
    let projected = target.points.compactMap(ar.project)
    let centroid = target.points.reduce(.zero, +) / Float(target.points.count)

    if projected.count == target.points.count, let rect = Self.beamRect(around: projected, in: bounds),
       bounds.insetBy(dx: 20, dy: 20).contains(CGPoint(x: rect.midX, y: rect.midY)) {
      // A beam that just arrived jumps into place; one already showing glides.
      let eased: CGRect
      if let smoothed, case .beam = state {
        eased = Self.lerp(smoothed, rect, 0.3)
      } else {
        eased = rect
        arrivals += 1
      }
      smoothed = eased
      setState(.beam(eased, label: target.label))
    } else if let direction = ar.screenDirection(to: centroid) {
      smoothed = nil
      setState(.edge(direction, label: target.label))
    } else {
      setState(.hidden)
    }
  }

  private func setState(_ new: State) {
    if new != state { state = new }
  }

  /// The projected points' bounding box, padded, at least big enough to read as a beam, clipped to the screen.
  private static func beamRect(around points: [CGPoint], in bounds: CGRect) -> CGRect? {
    guard let first = points.first else { return nil }
    var rect = points.dropFirst().reduce(CGRect(origin: first, size: .zero)) { $0.union(CGRect(origin: $1, size: .zero)) }
    rect = rect.insetBy(dx: -44, dy: -44)
    if rect.width < 150 { rect = rect.insetBy(dx: -(150 - rect.width) / 2, dy: 0) }
    if rect.height < 150 { rect = rect.insetBy(dx: 0, dy: -(150 - rect.height) / 2) }
    let clipped = rect.intersection(bounds)
    return clipped.isNull ? nil : clipped
  }

  private static func lerp(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
    CGRect(
      x: a.minX + (b.minX - a.minX) * t, y: a.minY + (b.minY - a.minY) * t,
      width: a.width + (b.width - a.width) * t, height: a.height + (b.height - a.height) * t
    )
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
      Canvas { context, size in
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.55)))
        context.blendMode = .destinationOut
        context.addFilter(.blur(radius: 28))
        context.fill(Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 3), with: .color(.white))
      }
      .compositingGroup()
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
    let angle = Angle(radians: atan2(direction.dy, direction.dx))
    return ZStack {
      RadialGradient(colors: [Color.accentColor.opacity(0.75), .clear], center: .center, startRadius: 0, endRadius: 170)
        .frame(width: 340, height: 340)
        .position(point)
        .blendMode(.screen)
      HStack(spacing: 6) {
        Text(label).font(.footnote.weight(.semibold))
        Image(systemName: "chevron.right").rotationEffect(angle)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .glassBackground(in: Capsule())
      .fixedSize()
      .position(Self.inset(point, toward: CGPoint(x: size.width / 2, y: size.height / 2), by: 70))
    }
    .allowsHitTesting(false)
    .transition(.opacity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(label) is off screen. Turn the phone toward the glow.")
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
