import ARKit
import Combine
import CoreImage
import Observation
import RealityKit
import UIKit
import os

/// Owns the AR session: finds the marker under world tracking and pins the guide to where the marker was last seen.
///
/// Threading: ARKit calls the delegate on main (RealityKit's ARView renders from the same session, and moving the
/// delegate off main coincided with every drawable allocation failing: a frozen camera). The delegate stays light:
/// it copies a few matrices, scales the call video when a call wants it, and returns, so ARFrames are never held.
/// The marker's latest state still reaches the rest of main coalesced to one hop at a time. `CameraLab` can move the
/// delegate back to a background queue, to test on the device. Observable state and RealityKit entities: main only.
@Observable
final class ARSessionController: NSObject, ARSessionDelegate {
  /// One line per lifecycle event (phase, memory, interruption), so a device log shows what came before any trouble.
  static let log = Logger(subsystem: "com.teamsonic.remoteassist", category: "ar")

  private(set) var markerTracked = false
  private(set) var markerSeen = false
  private(set) var errorMessage: String?
  /// True while the marker was found once but isn't visible right now, for long enough to be worth saying.
  private(set) var markerLostForAWhile = false

  /// A pin on the real surface: from the expert tapping the video, or a screw going back in.
  struct PinInfo: Identifiable, Equatable {
    let id: UUID
    let number: Int
    let label: String
    let kind: Shapes.PinKind
    var done: Bool
    /// Where it stands in the world (+Y is the surface normal), kept for screw memory.
    var transform: simd_float4x4
    /// Where it was in the photo it came from, for the screw map.
    var photoPoint: UprightPoint?
    var position: SIMD3<Float> { SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z) }
  }

  private(set) var pins: [PinInfo] = []
  /// Set while the ghost screwdriver should show on the next pin: the way to turn, or nil to hide it.
  var ghostTurnsAnticlockwise: Bool? {
    didSet { if ghostTurnsAnticlockwise != oldValue { updateGhost(rebuild: true) } }
  }
  /// Called on main when the user taps a pin to tick or untick it.
  @ObservationIgnored var onPinToggled: ((PinInfo) -> Void)?

  /// What a tap on the camera view means: tick a pin, or mark a point on the surface (setting the laptop's corners,
  /// teaching where a screw is).
  enum TapMode { case pins, surface }
  @ObservationIgnored var tapMode: TapMode = .pins
  /// In `.surface` mode: where the tap met the surface, and the surface's normal. Main thread.
  @ObservationIgnored var onSurfaceTap: ((SIMD3<Float>, SIMD3<Float>) -> Void)?

  /// The step being shown. Drawn as soon as the marker is found, and redrawn when it changes.
  var step: Step? {
    didSet { if step != oldValue { renderStep() } }
  }

  /// Camera poses in the marker frame, about 5 a second, once the marker has been seen. Called on main.
  @ObservationIgnored var onPose: ((PoseUpdate) -> Void)?
  /// Every camera frame, for the live call. Called on the AR session queue; it must finish its work with the buffer
  /// before it returns (copy or convert it), because ARKit wants the buffer back straight away.
  @ObservationIgnored var onCameraFrame: ((CVPixelBuffer, TimeInterval) -> Void)? {
    get { shared.withLock { $0.onCameraFrame } }
    set { shared.withLock { $0.onCameraFrame = newValue } }
  }

  /// Replaced by a fresh one (same session, same anchors) if it ever stops getting drawables: see `replaceView`.
  @ObservationIgnored private(set) var arView: ARView = CameraView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
  @ObservationIgnored private weak var host: CameraHost?
  /// When the view was last replaced, to cap automatic replacements.
  @ObservationIgnored private var replacements: [TimeInterval] = []
  /// A world anchor, not an image anchor: RealityKit hides image-anchored content the moment the image is covered
  /// (a hand reaching in, the marker leaving the frame). This one stays put and only follows the marker while ARKit
  /// can actually see it.
  @ObservationIgnored private var markerAnchor: AnchorEntity?
  /// Scaled by ARKit's size estimate, so a marker shown smaller (say on a laptop screen) still lines everything up.
  @ObservationIgnored private let markerRoot = Entity()
  @ObservationIgnored private let stepRoot = Entity()
  @ObservationIgnored private var configuration: ARWorldTrackingConfiguration?
  @ObservationIgnored private var isRunning = false
  @ObservationIgnored private let coaching = ARCoachingOverlayView()
  @ObservationIgnored private var pinEntities: [UUID: (anchor: AnchorEntity, arAnchor: ARAnchor, entity: Entity)] = [:]
  @ObservationIgnored private var focusAnchor: AnchorEntity?
  @ObservationIgnored private var focusCorners: [SIMD3<Float>] = []
  @ObservationIgnored private var focusLabel = ""
  @ObservationIgnored private var outlineAnchor: AnchorEntity?
  @ObservationIgnored private var cornerAnchor: AnchorEntity?
  @ObservationIgnored private var ghost: Entity?
  @ObservationIgnored private var ghostPinId: UUID?
  @ObservationIgnored private let imageContext = CIContext()
  @ObservationIgnored private var glideEndsAt: Date = .distantPast
  @ObservationIgnored private var lostTimer: Task<Void, Never>?
  @ObservationIgnored private var thermalObserver: NSObjectProtocol?
  @ObservationIgnored private var memoryObserver: NSObjectProtocol?
  @ObservationIgnored private var watchdog: Timer?
  @ObservationIgnored private var watchdogRestarts = 0
  /// When the session was last (re)started, so silence is measured from then, not from boot.
  @ObservationIgnored private var runStartedAt: TimeInterval = 0
  /// Set when the camera stopped sending frames and a restart didn't bring it back.
  private(set) var cameraStalled = false
  /// RealityKit scene updates since the last health line. They keep ticking even when no drawable can be had, so
  /// they show the render loop is alive, not that frames reach the screen.
  @ObservationIgnored private var renderSubscription: Cancellable?
  @ObservationIgnored private var rendersSinceLog = 0
  @ObservationIgnored private var lastHealthLog: TimeInterval = 0
  /// Set on the first memory warning: people occlusion stays off for the rest of the run.
  @ObservationIgnored private var lowMemory = false

  @ObservationIgnored private let sessionQueue = DispatchQueue(label: "ar-session", qos: .userInteractive)
  @ObservationIgnored private let shared = OSAllocatedUnfairLock(initialState: Shared())

  /// What the session queue and main share. Always behind `shared`'s lock.
  private struct Shared {
    var onCameraFrame: ((CVPixelBuffer, TimeInterval) -> Void)?
    /// The marker's last tracked pose, for expressing the camera in the marker frame.
    var markerTransform: simd_float4x4?
    var lastPoseTime: TimeInterval = 0
    /// The newest marker state waiting for main, and whether a hop to main is already queued.
    var pending: MarkerSample?
    var hopQueued = false
    /// When the last camera frame arrived (system uptime), for the watchdog.
    var lastFrameAt: TimeInterval = 0
    var framesSinceLog = 0
    /// When a rendered frame last reached a drawable (RealityKit's post-process callback only runs when it does).
    var lastPresentAt: TimeInterval = 0
    var presentsSinceLog = 0
    /// The last ~2.5 s of camera poses, so an expert's tap on a video frame that left the phone a moment ago is
    /// projected through the camera that filmed it.
    var cameraHistory: [CameraContext] = []
  }

  /// A copy of what main needs from an ARImageAnchor, so no ARKit object crosses threads.
  private struct MarkerSample {
    var transform: simd_float4x4
    var isTracked: Bool
    var scale: Float
    var size: CGSize
    var isNew: Bool
  }

  deinit {
    thermalObserver.map(NotificationCenter.default.removeObserver)
    memoryObserver.map(NotificationCenter.default.removeObserver)
  }

  // MARK: Lifecycle (main)

  /// Starts the session once. Later calls do nothing; use `resume()` after `pause()`.
  func start() {
    guard configuration == nil else { return }
    guard ARWorldTrackingConfiguration.isSupported else {
      errorMessage = "This iPhone doesn't support ARKit world tracking."
      return
    }
    guard let cgImage = UIImage(named: MarkerSpec.imageName)?.cgImage else {
      errorMessage = "Marker image '\(MarkerSpec.imageName)' is missing from the app."
      return
    }

    let reference = ARReferenceImage(cgImage, orientation: .up, physicalWidth: CGFloat(MarkerSpec.widthMeters))
    reference.name = MarkerSpec.imageName
    // The runtime version of Xcode's AR resource warnings: too little detail or too uniform a pattern to track.
    reference.validate { [weak self] error in
      guard let error else { return }
      DispatchQueue.main.async { self?.errorMessage = "Marker image problem: \(error.localizedDescription)" }
    }

    // World tracking (not image-only tracking) keeps the guide where it was when the marker leaves the frame.
    // One tracked image keeps its anchor updating every frame instead of only on detection.
    let config = ARWorldTrackingConfiguration()
    config.detectionImages = [reference]
    config.maximumNumberOfTrackedImages = 1
    // No plane detection: every raycast uses ARKit's estimated planes. Turning it on later meant re-running a live
    // session, and every re-run made RealityKit rebuild its render graph and then fail every drawable (the frozen
    // camera). The session is configured once, here.
    config.planeDetection = CameraLab.planesAlways ? [.horizontal] : []
    config.automaticImageScaleEstimationEnabled = true
    configuration = config
    applyThermalLimits(to: config)

    configure(arView)
    if CameraLab.delegateOffMain { arView.session.delegateQueue = sessionQueue }
    arView.session.delegate = self
    arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    isRunning = true
    markRestarted()
    startWatchdog()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      guard let self else { return }
      let b = self.arView.bounds
      Self.log.notice("AR started: view \(Int(b.width), privacy: .public)×\(Int(b.height), privacy: .public) pt at \(self.arView.contentScaleFactor, privacy: .public)x · lab: \(CameraLab.summary, privacy: .public)")
    }

    // Apple's own "move your phone" guidance whenever tracking is poor.
    coaching.session = arView.session
    coaching.goal = .tracking
    coaching.activatesAutomatically = true
    coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    coaching.frame = arView.bounds
    if coaching.superview == nil { arView.addSubview(coaching) }

    // A hot phone drops the people-occlusion model first: it's the most expensive thing the session runs.
    thermalObserver = NotificationCenter.default.addObserver(
      forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main
    ) { [weak self] _ in
      guard let self, let configuration = self.configuration else { return }
      let before = configuration.frameSemantics
      self.applyThermalLimits(to: configuration)
      if self.isRunning, configuration.frameSemantics != before { self.arView.session.run(configuration) }
    }
    memoryObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
    ) { [weak self] _ in
      guard let self, !self.lowMemory, let configuration = self.configuration else { return }
      self.lowMemory = true
      Self.log.notice("Memory warning: people occlusion off for the rest of the run")
      let before = configuration.frameSemantics
      self.applyThermalLimits(to: configuration)
      if self.isRunning, configuration.frameSemantics != before { self.arView.session.run(configuration) }
    }
  }

  /// Everything a fresh AR view needs, for the first one and any replacement. Motion blur smears the camera when the
  /// phone moves; everything else stays at RealityKit's defaults. Never override contentScaleFactor or the layer's
  /// scale: RealityKit sizes its own drawables, and forcing 2x made every allocation fail.
  private func configure(_ view: ARView) {
    view.renderOptions.insert(.disableMotionBlur)
    if !Self.handsInFront { view.renderOptions.insert(.disablePersonOcclusion) }
    // The one place that proves a frame reached the screen: RealityKit only calls this with a drawable to draw into.
    // The copy is the whole post-process (none), one GPU blit per frame.
    view.renderCallbacks.postProcess = { [shared] context in
      if let blit = context.commandBuffer.makeBlitCommandEncoder() {
        blit.copy(from: context.sourceColorTexture, to: context.targetColorTexture)
        blit.endEncoding()
      }
      let now = ProcessInfo.processInfo.systemUptime
      shared.withLock { state in
        state.lastPresentAt = now
        state.presentsSinceLog += 1
      }
    }
    renderSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
      self?.rendersSinceLog += 1
    }
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
  }

  /// Puts the current AR view in SwiftUI's host (once, when SwiftUI makes it).
  func attach(to host: CameraHost) {
    self.host = host
    arView.removeFromSuperview()
    arView.frame = host.bounds
    host.addSubview(arView)
    if isRunning { arView.isHidden = false }
  }

  /// A fresh AR view on the same running session, with every anchor moved across, in place of one that can't get
  /// drawables any more (the "camera visible but frozen" failure). Tracking, pins and the laptop outline survive.
  func replaceView(reason: String) {
    let old = arView
    Self.log.error("Camera view replaced: \(reason, privacy: .public)")
    let fresh = CameraView(frame: old.frame, cameraMode: .ar, automaticallyConfigureSession: false)
    fresh.session = old.session
    fresh.session.delegate = self
    configure(fresh)
    for anchor in Array(old.scene.anchors) {
      old.scene.removeAnchor(anchor)
      fresh.scene.addAnchor(anchor)
    }
    coaching.removeFromSuperview()
    coaching.frame = fresh.bounds
    fresh.addSubview(coaching)
    fresh.isHidden = old.isHidden

    old.renderCallbacks.postProcess = nil
    old.removeFromSuperview()
    // The old view lets go of the real session, so only the new one renders it.
    old.session = ARSession()
    arView = fresh
    if let host {
      fresh.frame = host.bounds
      host.addSubview(fresh)
    }
    markRestarted()
  }

  /// Silence is measured from here after any (re)start, so a fresh run isn't mistaken for a stall.
  private func markRestarted() {
    let now = ProcessInfo.processInfo.systemUptime
    runStartedAt = now
    shared.withLock { $0.lastPresentAt = now }
  }

  /// Once a second, while running and active:
  /// - no camera frames for 2 s: re-run the session once (the camera really stopped, so there's nothing to lose);
  /// - camera frames arriving but none reaching the screen for 1 s: replace the AR view (up to 3 times a minute);
  /// - neither helped: `cameraStalled`, which the screen shows with a Restart camera button.
  private func startWatchdog() {
    watchdog?.invalidate()
    watchdog = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.checkHealth()
    }
  }

  private func checkHealth() {
    guard isRunning, UIApplication.shared.applicationState == .active, let configuration else { return }
    let now = ProcessInfo.processInfo.systemUptime
    let (lastFrame, frames, lastPresent, presents) = shared.withLock { state in
      defer {
        state.framesSinceLog = 0
        state.presentsSinceLog = 0
      }
      return (state.lastFrameAt, state.framesSinceLog, state.lastPresentAt, state.presentsSinceLog)
    }
    framesInWindow += frames
    presentsInWindow += presents
    logHealthIfDue(now: now)

    let silent = now - max(lastFrame, runStartedAt)
    if silent > 2 {
      if watchdogRestarts < 1 {
        watchdogRestarts += 1
        Self.log.error("No camera frames for \(Int(silent), privacy: .public) s: restarting the AR session")
        markRestarted()
        arView.session.run(configuration)
      } else if !cameraStalled {
        Self.log.error("Camera still silent after a restart")
        cameraStalled = true
      }
      return
    }

    // Only a view that's on screen can be expected to draw, and a fresh one gets 3 s to compile its shaders.
    let notPresenting = now - max(lastPresent, runStartedAt)
    if notPresenting > 1, now - runStartedAt > 3, arView.window != nil, !arView.isHidden {
      replacements = replacements.filter { now - $0 < 60 }
      if replacements.count < 3 {
        replacements.append(now)
        replaceView(reason: String(format: "nothing reached the screen for %.1f s while the camera ran", notPresenting))
      } else if !cameraStalled {
        Self.log.error("Camera view still not drawing after 3 replacements this minute")
        cameraStalled = true
      }
      return
    }

    if cameraStalled { cameraStalled = false }
    watchdogRestarts = 0
  }

  @ObservationIgnored private var framesInWindow = 0
  @ObservationIgnored private var presentsInWindow = 0

  /// One line every 10 s: camera frames and renders per second, and how much memory the app has left. A device log
  /// then shows whether anything degrades before a stall.
  private func logHealthIfDue(now: TimeInterval) {
    if lastHealthLog == 0 { lastHealthLog = now }
    let span = now - lastHealthLog
    guard span >= 10 else { return }
    let fps = Double(framesInWindow) / span
    let rps = Double(rendersSinceLog) / span
    let shown = Double(presentsInWindow) / span
    let freeMB = os_proc_available_memory() / 1_048_576
    Self.log.notice("AR health: camera \(Int(fps.rounded()), privacy: .public) fps · on screen \(Int(shown.rounded()), privacy: .public) fps · scene updates \(Int(rps.rounded()), privacy: .public)/s · \(freeMB, privacy: .public) MB free")
    framesInWindow = 0
    presentsInWindow = 0
    rendersSinceLog = 0
    lastHealthLog = now
  }

  /// The user's way out: a fresh AR view on the same session, and the session resumed if it had stopped.
  func restartCamera() {
    watchdogRestarts = 0
    replacements = []
    cameraStalled = false
    replaceView(reason: "Restart camera (user)")
    if !isRunning { resume() }
  }

  /// Also hides the view: a paused session doesn't stop ARView's render loop, and a hidden view asks the GPU for
  /// nothing (a backgrounded app asking for drawables is what floods "nextDrawable returning nil").
  func pause() {
    guard isRunning else { return }
    isRunning = false
    arView.session.pause()
    arView.isHidden = true
    Self.log.notice("AR paused and hidden")
  }

  /// Picks up where it left off (no reset), so the guide is still on the marker after the QR scanner closes or the
  /// app comes back from the background.
  func resume() {
    guard let configuration, !isRunning else { return }
    isRunning = true
    arView.isHidden = false
    markRestarted()
    lastHealthLog = 0
    framesInWindow = 0
    presentsInWindow = 0
    rendersSinceLog = 0
    arView.session.run(configuration)
    Self.log.notice("AR resumed")
  }

  /// People occlusion (hands hiding the guide, as a real object would) runs a neural network on every frame. Off
  /// unless the user turns it on in the system check, and off again when the phone is hot or short of memory.
  static var handsInFront: Bool {
    get { UserDefaults.standard.bool(forKey: "handsInFront") }
    set { UserDefaults.standard.set(newValue, forKey: "handsInFront") }
  }

  func setHandsInFront(_ on: Bool) {
    Self.handsInFront = on
    if on { arView.renderOptions.remove(.disablePersonOcclusion) } else { arView.renderOptions.insert(.disablePersonOcclusion) }
    guard let configuration else { return }
    applyThermalLimits(to: configuration)
    if isRunning { arView.session.run(configuration) }
  }

  private func applyThermalLimits(to config: ARWorldTrackingConfiguration) {
    let hot = ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    if Self.handsInFront, !hot, !lowMemory, ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
      config.frameSemantics.insert(.personSegmentationWithDepth)
    } else {
      config.frameSemantics.remove(.personSegmentationWithDepth)
    }
  }


  /// The current camera image, upright for a phone held in portrait, as a JPEG (the report's closing photo).
  func snapshotJPEG(maxSide: CGFloat = 1024) -> Data? {
    guard isRunning, let buffer = arView.session.currentFrame?.capturedImage else { return nil }
    let upright = CIImage(cvPixelBuffer: buffer).oriented(.right)
    let scale = min(1, maxSide / max(upright.extent.width, upright.extent.height))
    let image = upright.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    return imageContext.jpegRepresentation(of: image, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
  }

  /// True once ARKit can place things on a flat surface at the middle of the screen. Uses estimated planes, so it
  /// works without plane detection (which would need a session re-run to turn on).
  var hasHorizontalSurface: Bool {
    let centre = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
    return !arView.raycast(from: centre, allowing: .estimatedPlane, alignment: .horizontal).isEmpty
  }

  /// The world direction that is "right" on the phone's screen: the camera's +Y (its axes are the sensor's, landscape).
  var screenRightInWorld: SIMD3<Float>? {
    guard let t = arView.session.currentFrame?.camera.transform else { return nil }
    return simd_normalize(SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z))
  }

  /// Apple's coaching overlay: "find a surface" while setting up the laptop, "keep tracking" otherwise.
  func setCoachingGoal(_ goal: ARCoachingOverlayView.Goal) {
    coaching.goal = goal
  }

  // MARK: Laptop frame, zones (main)

  /// The purple outline around the laptop once its corners are set; nil takes it away.
  func showLaptopOutline(_ frame: LaptopFrame?) {
    outlineAnchor.map { arView.scene.removeAnchor($0) }
    outlineAnchor = nil
    guard let frame else { return }
    let anchor = AnchorEntity(world: matrix_identity_float4x4)
    anchor.addChild(Shapes.laptopOutline(corners: frame.corners, normal: frame.normal))
    arView.scene.addAnchor(anchor)
    outlineAnchor = anchor
  }

  /// A pulsing marker on the first tapped corner; nil takes it away.
  func showCornerMarker(at position: SIMD3<Float>?) {
    cornerAnchor.map { arView.scene.removeAnchor($0) }
    cornerAnchor = nil
    guard let position else { return }
    var transform = matrix_identity_float4x4
    transform.columns.3 = SIMD4(position.x, position.y, position.z, 1)
    let anchor = AnchorEntity(world: transform)
    anchor.addChild(Shapes.cornerMarker())
    arView.scene.addAnchor(anchor)
    cornerAnchor = anchor
  }

  /// "Work here": a zone of the laptop lit on the surface, which the spotlight also follows.
  func showFocus(corners: [SIMD3<Float>], normal: SIMD3<Float>, label: String) {
    clearFocus()
    let anchor = AnchorEntity(world: matrix_identity_float4x4)
    anchor.addChild(Shapes.focusArea(corners: corners, normal: normal, label: label))
    arView.scene.addAnchor(anchor)
    focusAnchor = anchor
    focusCorners = corners
    focusLabel = label
  }

  func clearFocus() {
    focusAnchor.map { arView.scene.removeAnchor($0) }
    focusAnchor = nil
    focusCorners = []
  }

  /// The camera as it was `secondsAgo`, from the last ~2.5 s.
  func cameraContext(secondsAgo: Double) -> CameraContext? {
    shared.withLock { state in
      guard let latest = state.cameraHistory.last else { return nil }
      let target = latest.timestamp - secondsAgo
      return state.cameraHistory.min { abs($0.timestamp - target) < abs($1.timestamp - target) }
    }
  }

  // MARK: Pins (main)

  private struct SurfacePoint {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
  }


  func placeStoredPins(_ stored: [(number: Int, label: String, transform: simd_float4x4)], kind: Shapes.PinKind) {
    for item in stored {
      addPin(number: item.number, label: item.label, kind: kind, transform: item.transform, photoPoint: nil)
    }
    updateGhost(rebuild: false)
  }

  /// The expert tapped the live video: a pin where they tapped, through the camera that filmed that frame.
  func placeExpertPin(at point: UprightPoint, label: String, secondsAgo: Double) -> Bool {
    guard let camera = cameraContext(secondsAgo: secondsAgo) else { return false }
    guard let surface = surfacePoint(for: point, camera: camera)
      ?? fallbackSurfacePoint(for: point, camera: camera, reference: nil) else { return false }
    let number = (pins.filter { $0.kind == .expert }.map(\.number).max() ?? 0) + 1
    addPin(number: number, label: label, kind: .expert, transform: PinMath.standing(at: surface.position, normal: surface.normal), photoPoint: nil)
    return true
  }

  /// Clears pins of the given kinds (all by default).
  func clearPins(kinds: Set<Shapes.PinKind> = [.guide, .expert, .refit]) {
    for pin in pins where kinds.contains(pin.kind) {
      if let entry = pinEntities.removeValue(forKey: pin.id) {
        arView.scene.removeAnchor(entry.anchor)
        arView.session.remove(anchor: entry.arAnchor)
      }
    }
    pins.removeAll { kinds.contains($0.kind) }
    updateGhost(rebuild: false)
  }

  @discardableResult
  private func addPin(number: Int, label: String, kind: Shapes.PinKind, transform: simd_float4x4, photoPoint: UprightPoint?) -> UUID {
    // A session anchor, not a free world position, so ARKit keeps refining where it is as it learns the room.
    let arAnchor = ARAnchor(name: "pin", transform: transform)
    arView.session.add(anchor: arAnchor)
    let anchor = AnchorEntity(anchor: arAnchor)
    let entity = Shapes.pin(number: number, label: label, kind: kind)
    anchor.addChild(entity)
    arView.scene.addAnchor(anchor)
    let info = PinInfo(id: UUID(), number: number, label: label, kind: kind, done: false, transform: transform, photoPoint: photoPoint)
    pinEntities[info.id] = (anchor, arAnchor, entity)
    pins.append(info)
    return info.id
  }

  private func surfacePoint(for point: UprightPoint, camera: CameraContext) -> SurfacePoint? {
    let ray = PinMath.ray(for: point, in: camera)
    // Real detected planes first: they're measured. Estimated planes are ARKit's guess from feature points.
    for target in [ARRaycastQuery.Target.existingPlaneGeometry, .estimatedPlane] {
      let query = ARRaycastQuery(origin: ray.origin, direction: ray.direction, allowing: target, alignment: .any)
      if let hit = arView.session.raycast(query).first {
        let t = hit.worldTransform
        return SurfacePoint(position: SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z), normal: SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z))
      }
    }
    return nil
  }

  private func fallbackSurfacePoint(for point: UprightPoint, camera: CameraContext, reference: SurfacePoint?) -> SurfacePoint? {
    let ray = PinMath.ray(for: point, in: camera)
    if let reference, let hit = PinMath.intersect(origin: ray.origin, direction: ray.direction, planePoint: reference.position, planeNormal: reference.normal) {
      return SurfacePoint(position: hit, normal: reference.normal)
    }
    // Otherwise the nearest detected horizontal plane, extended past its measured edges.
    let planes = arView.session.currentFrame?.anchors.compactMap { $0 as? ARPlaneAnchor }.filter { $0.alignment == .horizontal } ?? []
    let hits = planes.compactMap { plane -> SurfacePoint? in
      let t = plane.transform
      let normal = SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z)
      guard let hit = PinMath.intersect(origin: ray.origin, direction: ray.direction, planePoint: SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z), planeNormal: normal) else { return nil }
      return SurfacePoint(position: hit, normal: normal)
    }
    return hits.min { simd_distance($0.position, ray.origin) < simd_distance($1.position, ray.origin) }
  }

  @objc private func tapped(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: arView)
    if tapMode == .surface {
      // A measured plane first; ARKit's estimate from feature points if the tap is past a plane's edge.
      let hit = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal).first
        ?? arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
      guard let t = hit?.worldTransform else { return }
      onSurfaceTap?(SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z), SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z))
      return
    }
    // Nearest pin on screen within a finger's width: kinder than hit-testing a 7 mm ball.
    let nearest = pins.indices
      .compactMap { i -> (Int, CGFloat)? in
        guard let screen = arView.project(pins[i].position + SIMD3(pins[i].transform.columns.1.x, pins[i].transform.columns.1.y, pins[i].transform.columns.1.z) * 0.02) else { return nil }
        return (i, hypot(screen.x - location.x, screen.y - location.y))
      }
      .min { $0.1 < $1.1 }
    guard let (index, distance) = nearest, distance < 50 else { return }
    pins[index].done.toggle()
    let pin = pins[index]
    if let entity = pinEntities[pin.id]?.entity {
      Shapes.setPin(entity, done: pin.done, number: pin.number, label: pin.label, kind: pin.kind)
    }
    updateGhost(rebuild: false)
    onPinToggled?(pin)
  }

  /// The ghost screwdriver sits on the first pin not yet done.
  private func updateGhost(rebuild: Bool) {
    let target = pins.first { !$0.done }
    // On the pin entity itself (not its anchor), so it follows the pin when a refined point moves it.
    guard let anticlockwise = ghostTurnsAnticlockwise, let target, let anchor = pinEntities[target.id]?.entity else {
      ghost?.removeFromParent()
      ghost = nil
      ghostPinId = nil
      return
    }
    if rebuild || ghost == nil {
      ghost?.removeFromParent()
      ghost = Shapes.ghostTool(anticlockwise: anticlockwise)
      ghostPinId = nil
    }
    guard let ghost, ghostPinId != target.id else { return }
    ghost.removeFromParent()
    anchor.addChild(ghost)
    ghostPinId = target.id
  }

  // MARK: Spotlight (main)

  /// What the spotlight should light up right now, as world points, plus what to call it.
  struct SpotlightTarget {
    var points: [SIMD3<Float>]
    var label: String
  }

  /// The pins still to do, then the step's zone of the laptop, then the marker step.
  func spotlightTarget() -> SpotlightTarget? {
    let pending = pins.filter { !$0.done }
    if !pending.isEmpty {
      let label = pending.count == 1 ? "\(pending[0].number) · \(pending[0].label)" : "\(pending.count) left"
      return SpotlightTarget(points: pending.map(\.position), label: label)
    }
    if !focusCorners.isEmpty {
      return SpotlightTarget(points: focusCorners, label: focusLabel)
    }
    if markerSeen, !stepRoot.children.isEmpty {
      let points = stepRoot.children.map { $0.position(relativeTo: nil) }
      return SpotlightTarget(points: points, label: step?.objects.first?.label ?? "Here")
    }
    return nil
  }

  func project(_ point: SIMD3<Float>) -> CGPoint? {
    arView.project(point)
  }

  /// Which way to turn the phone to face a point: a unit vector in screen space (x right, y down).
  func screenDirection(to point: SIMD3<Float>) -> CGVector? {
    guard let camera = arView.session.currentFrame?.camera.transform else { return nil }
    let local = camera.inverse * SIMD4(point.x, point.y, point.z, 1)
    // The camera's axes are the sensor's (landscape): its +Y is the portrait screen's right, its +X the screen's down.
    let vector = CGVector(dx: CGFloat(local.y), dy: CGFloat(local.x))
    let length = hypot(vector.dx, vector.dy)
    return length > 1e-4 ? CGVector(dx: vector.dx / length, dy: vector.dy / length) : nil
  }

  // MARK: ARSessionDelegate (sessionQueue)

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    let timestamp = frame.timestamp
    let cameraTransform = frame.camera.transform
    let cameraContext = CameraContext(frame)
    let now = ProcessInfo.processInfo.systemUptime
    shared.withLock { state in
      state.lastFrameAt = now
      state.framesSinceLog += 1
      state.cameraHistory.append(cameraContext)
      if state.cameraHistory.count > 150 { state.cameraHistory.removeFirst(state.cameraHistory.count - 150) }
    }

    // Synchronous: the handler copies what it needs, so ARKit's buffer is free again when this returns.
    if let onCameraFrame { onCameraFrame(frame.capturedImage, timestamp) }

    let pose: PoseUpdate? = shared.withLock { state in
      guard let marker = state.markerTransform, timestamp - state.lastPoseTime >= 0.2 else { return nil }
      state.lastPoseTime = timestamp
      // The contract's frame is the marker's, so the camera is expressed relative to the marker anchor.
      let camera = marker.inverse * cameraTransform
      return PoseUpdate(
        t: Int64(Date().timeIntervalSince1970 * 1000),
        camera: Pose(p: Vec3(SIMD3(camera.columns.3.x, camera.columns.3.y, camera.columns.3.z)), q: Quat(simd_quatf(camera))),
        markerTracked: false  // set on main below, where markerTracked lives
      )
    }
    if var pose {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        pose.markerTracked = self.markerTracked
        self.onPose?(pose)
      }
    }
  }

  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    receive(anchors, isNew: true)
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    receive(anchors, isNew: false)
  }

  func sessionWasInterrupted(_ session: ARSession) {
    Self.log.notice("AR session interrupted (camera taken by another task)")
  }

  func sessionInterruptionEnded(_ session: ARSession) {
    Self.log.notice("AR session interruption ended")
  }

  func session(_ session: ARSession, didFailWithError error: Error) {
    Self.log.error("AR session failed: \(error.localizedDescription, privacy: .public)")
    DispatchQueue.main.async { [weak self] in self?.errorMessage = error.localizedDescription }
  }

  private func receive(_ anchors: [ARAnchor], isNew: Bool) {
    guard let image = anchors.lazy.compactMap({ $0 as? ARImageAnchor }).first else { return }
    let sample = MarkerSample(
      transform: image.transform,
      isTracked: image.isTracked,
      scale: Float(image.estimatedScaleFactor),
      size: image.referenceImage.physicalSize,
      isNew: isNew
    )
    let hop = shared.withLock { state -> Bool in
      // While covered, ARKit's last pose for the image goes stale, so poses keep using the last tracked one.
      if sample.isTracked || isNew { state.markerTransform = sample.transform }
      var merged = sample
      // A coalesced "added" must not be lost under a later "updated".
      if state.pending?.isNew == true { merged.isNew = true }
      state.pending = merged
      guard !state.hopQueued else { return false }
      state.hopQueued = true
      return true
    }
    if hop {
      DispatchQueue.main.async { [weak self] in self?.applyPendingMarker() }
    }
  }

  // MARK: Content (main)

  private func applyPendingMarker() {
    let sample: MarkerSample? = shared.withLock { state in
      state.hopQueued = false
      defer { state.pending = nil }
      return state.pending
    }
    guard let sample else { return }

    if sample.isNew || markerAnchor == nil {
      attach(sample)
    } else if sample.isTracked {
      follow(sample, reacquired: !markerTracked)
    }
    if markerTracked != sample.isTracked {
      markerTracked = sample.isTracked
      updateLostHint()
    }
  }

  private func attach(_ sample: MarkerSample) {
    markerAnchor.map { arView.scene.removeAnchor($0) }

    let anchor = AnchorEntity(world: sample.transform)
    markerRoot.children.removeAll()
    markerRoot.addChild(Shapes.markerOutline(width: Float(sample.size.width), height: Float(sample.size.height)))
    markerRoot.addChild(Shapes.axisGizmo())
    markerRoot.addChild(stepRoot)
    markerRoot.scale = SIMD3(repeating: sample.scale)
    anchor.addChild(markerRoot)
    arView.scene.addAnchor(anchor)

    markerAnchor = anchor
    markerSeen = true
  }

  private func follow(_ sample: MarkerSample, reacquired: Bool) {
    guard let markerAnchor else { return }
    let target = Transform(matrix: sample.transform)
    let jump = simd_distance(markerAnchor.transform.translation, target.translation)
    if reacquired && jump > 0.02 {
      // Found again after being covered: glide there once instead of jumping.
      markerAnchor.move(to: target, relativeTo: nil, duration: 0.2, timingFunction: .easeOut)
      glideEndsAt = Date().addingTimeInterval(0.2)
    } else if Date() >= glideEndsAt {
      // Never restart or fight a glide that's already running; once it lands, follow every update exactly.
      markerAnchor.transform = target
    }
    markerRoot.scale = SIMD3(repeating: sample.scale)
  }

  /// After 3 s of not seeing the marker, the UI says the guide is holding where it was.
  private func updateLostHint() {
    lostTimer?.cancel()
    if markerTracked || !markerSeen {
      markerLostForAWhile = false
      return
    }
    lostTimer = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(3))
      guard let self, !Task.isCancelled, !self.markerTracked else { return }
      self.markerLostForAWhile = true
    }
  }

  private func renderStep() {
    stepRoot.children.removeAll()
    guard let step else { return }

    for object in step.objects {
      // Positions are already in the marker frame (contracts/protocol.ts), so they go straight onto the anchor.
      let node = Entity()
      node.position = object.pos.simd
      node.orientation = object.rot.simd
      node.addChild(Shapes.highlightBox(size: object.size.simd))
      let model = Shapes.model(object.model)
      node.addChild(model)
      if let action = object.action {
        // The contract's axis is in the marker frame; the model lives in the object's rotated frame.
        Shapes.animate(model, action: action, axis: object.rot.simd.inverse.act(object.axis.simd))
      }
      if let text = object.label {
        let label = Shapes.label(text)
        label.position = [0, object.size.y / 2 + 0.012, 0]
        node.addChild(label)
      }
      stepRoot.addChild(node)
    }
  }
}

extension CameraContext {
  init(_ frame: ARFrame) {
    self.init(
      transform: frame.camera.transform,
      intrinsics: frame.camera.intrinsics,
      imageResolution: frame.camera.imageResolution,
      timestamp: frame.timestamp
    )
  }
}
