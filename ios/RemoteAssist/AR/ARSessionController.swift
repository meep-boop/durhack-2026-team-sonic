import ARKit
import Combine
import CoreImage
import Observation
import RealityKit
import UIKit
import os

/// Owns the AR session: finds the marker under world tracking and pins the guide to where the marker was last seen.
///
/// The camera on screen never depends on RealityKit alone: every frame also goes to `CameraFeedView`, which covers the
/// AR view whenever it stops drawing (`CameraPresentPolicy`), so the picture stays live while RealityKit recovers.
///
/// Threading: ARKit calls the delegate on `sessionQueue`, so the live feed and the call video keep moving while main
/// is busy. The delegate stays light: it copies a few matrices, hands the frame on, and returns, so ARFrames are never
/// held. The marker's latest state reaches main coalesced to one hop at a time. Observable state and RealityKit
/// entities: main only.
@Observable
final class ARSessionController: NSObject, ARSessionDelegate {
  /// One line per lifecycle event (phase, memory, interruption), so a device log shows what came before any trouble.
  static let log = Logger(subsystem: "com.teamsonic.remoteassist", category: "ar")

  private(set) var markerTracked = false
  private(set) var markerSeen = false
  private(set) var errorMessage: String?
  /// True while the marker was found once but isn't visible right now, for long enough to be worth saying.
  private(set) var markerLostForAWhile = false
  /// One line for the AR debug strip: the marker's distance, seen size and pose, and how far this step's parts are
  /// from it. Updated at most twice a second.
  private(set) var debugLine = ""
  /// The marker is seen but not lying flat, so the guide's parts would hang in the air: the screen says to lay it down.
  private(set) var markerNotFlat = false
  @ObservationIgnored private var lastDebugUpdate: TimeInterval = 0
  @ObservationIgnored private var lastDebugLog: TimeInterval = 0
  @ObservationIgnored private var stepRangeText = ""
  @ObservationIgnored private var markerOutline: Entity?
  /// True while the expert's guide is locked to the laptop (two corner taps) instead of placed from the marker.
  private(set) var guideOnLaptop = false
  @ObservationIgnored private var laptopGuideAnchor: AnchorEntity?

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
  /// Set while the scan screen is open: it sees every frame, with the marker's last tracked pose.
  @ObservationIgnored var scanRecorder: ScanRecorder? {
    get { shared.withLock { $0.scanRecorder } }
    set { shared.withLock { $0.scanRecorder = newValue } }
  }

  /// Made on first use, not with the controller: SwiftUI can build and drop a @State's initial value, and every ARView
  /// starts a whole RealityKit renderer. Replaced by a fresh one (same session, same anchors) if it stops drawing.
  var arView: ARView {
    if let view { return view }
    let made = makeView(frame: host?.bounds ?? .zero)
    view = made
    return made
  }
  @ObservationIgnored private var view: ARView?
  @ObservationIgnored private weak var host: CameraHost?
  @ObservationIgnored private var feedShown = false
  @ObservationIgnored private var feedShownAt: TimeInterval = 0
  @ObservationIgnored private var lastReplaceAt: TimeInterval = 0
  /// Fresh AR views built while the feed has been covering, to space out the next try.
  @ObservationIgnored private var replacementsWhileCovered = 0
  @ObservationIgnored private var lastRerunAt: TimeInterval = 0
  /// Session re-runs since the camera went silent; the screen says so after two.
  @ObservationIgnored private var silentReruns = 0
  @ObservationIgnored private var lastCheck: TimeInterval = 0
  @ObservationIgnored private var coveredInWindow: TimeInterval = 0
  @ObservationIgnored private static var viewsMade = 0
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
  /// When the session or the AR view was last (re)started, so silence is measured from then, not from boot.
  @ObservationIgnored private var runStartedAt: TimeInterval = 0
  /// Set when the camera stopped sending frames and re-running the session hasn't brought it back.
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
    var scanRecorder: ScanRecorder?
    var feed: CameraFeedView?
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
    /// When the current run of drawn frames without a gap began.
    var steadySince: TimeInterval = 0
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
    // Tables (horizontal planes) from the start, so marks land on a measured surface instead of ARKit's guess, which
    // slid when the phone moved. Set once here and never changed: re-running a live session is what used to make
    // RealityKit rebuild its renderer and fail every drawable. The freeze itself was a display link (research § 20).
    config.planeDetection = [.horizontal]
    config.automaticImageScaleEstimationEnabled = true
    configuration = config
    applyThermalLimits(to: config)

    arView.session.delegateQueue = sessionQueue
    arView.session.delegate = self
    arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    isRunning = true
    markRestarted()
    startWatchdog()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      guard let self else { return }
      let b = self.arView.bounds
      Self.log.notice("AR started: view \(Int(b.width), privacy: .public)×\(Int(b.height), privacy: .public) pt at \(self.arView.contentScaleFactor, privacy: .public)x")
    }

    // Apple's own "move your phone" guidance whenever tracking is poor.
    coaching.session = arView.session
    coaching.goal = .tracking
    coaching.activatesAutomatically = true

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

  /// A fresh AR view, for the first one and any replacement. Motion blur smears the camera when the phone moves;
  /// everything else stays at RealityKit's defaults. Never override contentScaleFactor or the layer's scale:
  /// RealityKit sizes its own drawables, and forcing 2x made every allocation fail.
  private func makeView(frame: CGRect) -> ARView {
    Self.viewsMade += 1
    Self.log.notice("Camera view #\(Self.viewsMade, privacy: .public) made")
    let view = CameraView(frame: frame, cameraMode: .ar, automaticallyConfigureSession: false)
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
        if now - state.lastPresentAt > CameraPresentPolicy.steadyGap { state.steadySince = now }
        state.lastPresentAt = now
        state.presentsSinceLog += 1
      }
    }
    renderSubscription = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
      self?.rendersSinceLog += 1
    }
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
    return view
  }

  /// Puts the AR view, the live feed and the coaching overlay in SwiftUI's host (once, when SwiftUI makes it).
  func attach(to host: CameraHost) {
    self.host = host
    shared.withLock { $0.feed = host.feed }
    host.feed.isHidden = !feedShown
    let view = arView
    view.removeFromSuperview()
    host.install(view)
    coaching.removeFromSuperview()
    host.installOverlay(coaching)
    if isRunning { view.isHidden = false }
  }

  /// A fresh AR view on the same running session, with every anchor moved across, in place of one that stopped
  /// drawing. It goes in under the live feed, which stays on top until the new view draws steadily, so the swap is
  /// never seen as black. Tracking, pins and the laptop outline survive.
  func replaceView(reason: String) {
    guard let old = view else { return }
    Self.log.error("Camera view replaced: \(reason, privacy: .public)")
    setFeed(true, reason: "replacing the AR view")
    let fresh = makeView(frame: old.frame)
    fresh.session = old.session
    fresh.session.delegate = self
    for anchor in Array(old.scene.anchors) {
      old.scene.removeAnchor(anchor)
      fresh.scene.addAnchor(anchor)
    }
    fresh.isHidden = old.isHidden

    old.renderCallbacks.postProcess = nil
    old.removeFromSuperview()
    // The old view lets go of the real session, so only the new one renders it.
    old.session = ARSession()
    view = fresh
    host?.install(fresh)
    markRestarted()
  }

  /// Silence and drawing are measured from here after any (re)start: frames drawn by an old view or before a pause
  /// prove nothing about now.
  private func markRestarted() {
    runStartedAt = ProcessInfo.processInfo.systemUptime
  }

  private func setFeed(_ show: Bool, reason: String) {
    guard show != feedShown else { return }
    feedShown = show
    host?.feed.isHidden = !show
    if show {
      feedShownAt = ProcessInfo.processInfo.systemUptime
    } else {
      replacementsWhileCovered = 0
    }
    Self.log.notice("Camera feed \(show ? "shown" : "hidden", privacy: .public): \(reason, privacy: .public)")
  }

  /// Ten times a second while running and active, `CameraPresentPolicy` decides whether the live feed covers the AR
  /// view, whether to build a fresh AR view under it, and whether to re-run a silent camera. In the common run-loop
  /// mode, so it keeps checking while a sheet is being dragged.
  private func startWatchdog() {
    watchdog?.invalidate()
    let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.checkHealth()
    }
    RunLoop.main.add(timer, forMode: .common)
    watchdog = timer
  }

  private func checkHealth() {
    guard isRunning, UIApplication.shared.applicationState == .active, let configuration else {
      lastCheck = 0
      return
    }
    let now = ProcessInfo.processInfo.systemUptime
    if lastCheck > 0, feedShown { coveredInWindow += now - lastCheck }
    lastCheck = now
    let (lastFrame, frames, lastPresent, steadySince, presents) = shared.withLock { state in
      defer {
        state.framesSinceLog = 0
        state.presentsSinceLog = 0
      }
      return (state.lastFrameAt, state.framesSinceLog, state.lastPresentAt, state.steadySince, state.presentsSinceLog)
    }
    framesInWindow += frames
    presentsInWindow += presents
    logHealthIfDue(now: now)

    let decision = CameraPresentPolicy.decide(.init(
      now: now, startedAt: runStartedAt, lastFrameAt: lastFrame, lastPresentAt: lastPresent, steadySince: steadySince,
      feedShown: feedShown, feedShownAt: feedShownAt, lastReplaceAt: lastReplaceAt,
      replacements: replacementsWhileCovered, lastRerunAt: lastRerunAt
    ))

    if decision.showFeed != feedShown {
      let reason = decision.cameraSilent ? "no camera frames"
        : decision.showFeed ? (lastPresent >= runStartedAt ? "the AR view stopped drawing" : "the AR view isn't drawing yet")
        : "the AR view is drawing steadily"
      setFeed(decision.showFeed, reason: reason)
    }
    if decision.rerunSession {
      silentReruns += 1
      lastRerunAt = now
      Self.log.error("No camera frames for \(Int(now - max(lastFrame, self.runStartedAt)), privacy: .public) s: re-running the AR session (try \(self.silentReruns, privacy: .public))")
      markRestarted()
      arView.session.run(configuration)
    }
    if !decision.cameraSilent { silentReruns = 0 }
    if decision.replaceView {
      replacementsWhileCovered += 1
      lastReplaceAt = now
      replaceView(reason: String(format: "nothing drawn for %.1f s while the camera ran", now - max(lastPresent, feedShownAt)))
    }
    let stalled = decision.cameraSilent && silentReruns >= 2
    if cameraStalled != stalled { cameraStalled = stalled }
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
    let covered = Int((coveredInWindow / span * 100).rounded())
    let freeMB = os_proc_available_memory() / 1_048_576
    Self.log.notice("AR health: camera \(Int(fps.rounded()), privacy: .public) fps · on screen \(Int(shown.rounded()), privacy: .public) fps · scene updates \(Int(rps.rounded()), privacy: .public)/s · feed covering \(covered, privacy: .public)% · \(freeMB, privacy: .public) MB free")
    framesInWindow = 0
    presentsInWindow = 0
    rendersSinceLog = 0
    coveredInWindow = 0
    lastHealthLog = now
  }

  /// The user's way out of a silent camera: a fresh AR view, and the session run again (or resumed).
  func restartCamera() {
    cameraStalled = false
    silentReruns = 0
    replaceView(reason: "Restart camera (user)")
    guard let configuration else { return }
    if isRunning {
      lastRerunAt = ProcessInfo.processInfo.systemUptime
      arView.session.run(configuration)
    } else {
      resume()
    }
  }

  /// Also hides the view: a paused session doesn't stop ARView's render loop, and a hidden view asks the GPU for
  /// nothing (a backgrounded app asking for drawables is what floods "nextDrawable returning nil"). The feed keeps
  /// the last picture up meanwhile, so coming back shows that instead of black until the camera is live again.
  func pause() {
    guard isRunning else { return }
    isRunning = false
    arView.session.pause()
    arView.isHidden = true
    setFeed(true, reason: "paused")
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
    coveredInWindow = 0
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
    lastSurface = SurfacePoint(position: frame.corners[0], normal: frame.normal)
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

  /// Moves the guide's parts onto the real laptop (`GuideOnLaptop.transform`), or back onto the marker with nil.
  func lockGuide(_ transform: simd_float4x4?) {
    laptopGuideAnchor.map { arView.scene.removeAnchor($0) }
    laptopGuideAnchor = nil
    guard let transform else {
      markerRoot.addChild(stepRoot)
      if guideOnLaptop { guideOnLaptop = false }
      Self.log.notice("Guide back on the marker")
      return
    }
    let anchor = AnchorEntity(world: transform)
    anchor.addChild(stepRoot)
    arView.scene.addAnchor(anchor)
    laptopGuideAnchor = anchor
    if !guideOnLaptop { guideOnLaptop = true }
    if debugLine.isEmpty || !debugLine.hasPrefix("Guide locked") { debugLine = "Guide locked to the laptop · " + stepRangeText }
    Self.log.notice("Guide locked to the laptop at (\(transform.columns.3.x, format: .fixed(precision: 2), privacy: .public), \(transform.columns.3.y, format: .fixed(precision: 2), privacy: .public), \(transform.columns.3.z, format: .fixed(precision: 2), privacy: .public))")
  }

  /// Where a world point is in the marker's frame, the frame guide positions are written in; nil before the marker
  /// has been found. Measuring with this is what lines a guide up with the real laptop: whatever way the marker's axes
  /// turn out to run, a position measured here is placed back on the same spot.
  func markerFramePoint(_ world: SIMD3<Float>) -> SIMD3<Float>? {
    guard let markerAnchor else { return nil }
    let local = markerAnchor.transformMatrix(relativeTo: nil).inverse * SIMD4(world.x, world.y, world.z, 1)
    return SIMD3(local.x, local.y, local.z)
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

  /// The last surface anything landed on (an expert pin, a tapped corner, the laptop's frame). With plane detection
  /// off for good, ARKit's estimate often finds nothing under a tap on a plain desk; the ray then meets this plane,
  /// which is nearly always the same desk.
  @ObservationIgnored private var lastSurface: SurfacePoint?
  /// The expert's marked area: lit on the surface, and the first thing the spotlight shows.
  @ObservationIgnored private var expertAreaAnchor: AnchorEntity?
  @ObservationIgnored private var expertAreaCorners: [SIMD3<Float>] = []
  @ObservationIgnored private var expertAreaLabel = ""


  func placeStoredPins(_ stored: [(number: Int, label: String, transform: simd_float4x4)], kind: Shapes.PinKind) {
    for item in stored {
      addPin(number: item.number, label: item.label, kind: kind, transform: item.transform, photoPoint: nil)
    }
    updateGhost(rebuild: false)
  }

  /// The expert tapped the live video: a pin where they tapped, through the camera that filmed that frame. One thing
  /// at a time: a pin replaces the expert's marked area.
  func placeExpertPin(at point: UprightPoint, label: String, secondsAgo: Double, turn anticlockwise: Bool? = nil) -> Bool {
    guard let camera = cameraContext(secondsAgo: secondsAgo) else { return false }
    guard let surface = surfacePoint(for: point, camera: camera)
      ?? fallbackSurfacePoint(for: point, camera: camera, reference: lastSurface) else { return false }
    lastSurface = surface
    clearExpertArea()
    let number = (pins.filter { $0.kind == .expert }.map(\.number).max() ?? 0) + 1
    let id = addPin(number: number, label: label, kind: .expert, transform: PinMath.standing(at: surface.position, normal: surface.normal), photoPoint: nil)
    // "Unscrew this": the turning arrow and the see-through screwdriver, on the pin itself so they follow it.
    if let anticlockwise, let entity = pinEntities[id]?.entity {
      entity.addChild(Shapes.turnCue(anticlockwise: anticlockwise))
    }
    return true
  }

  /// The expert dragged a box on the live video: that patch of the surface is lit and the spotlight dims everything
  /// else. `corners` go round the box in order. All four land on one plane (the one under the box's centre, else
  /// under any corner, else the last surface), so the area stays a flat, clean shape. It replaces the expert's pins.
  /// How far an area's corner may be from the box's centre: more than a laptop's half-diagonal, less than a desk.
  static let areaReach: Float = 0.45

  /// The box the expert dragged, as four points on the surface under it (clockwise from the top-left as drawn) and
  /// that surface's normal; nil when there's no surface at all. Each corner is where its ray meets the plane under the
  /// box's centre, pulled in to at most `areaReach` from the centre: drawn from an angle, a box round a laptop meets the
  /// table far away at its top corners, and refusing those turned normal areas red.
  private func footprint(_ points: [UprightPoint], secondsAgo: Double, label: String, kind: String) -> (corners: [SIMD3<Float>], normal: SIMD3<Float>)? {
    guard points.count == 4, let camera = cameraContext(secondsAgo: secondsAgo) else { return nil }
    let centre = UprightPoint(x: points.map(\.x).reduce(0, +) / 4, y: points.map(\.y).reduce(0, +) / 4)
    guard let plane = surfacePoint(for: centre, camera: camera)
      ?? points.lazy.compactMap({ self.surfacePoint(for: $0, camera: camera) }).first
      ?? lastSurface else {
      Self.log.notice("\(kind, privacy: .public) \"\(label, privacy: .public)\" missed: no surface under the box")
      return nil
    }
    let up = simd_normalize(plane.normal)
    let centreRay = PinMath.ray(for: centre, in: camera)
    let middle = PinMath.intersect(origin: centreRay.origin, direction: centreRay.direction, planePoint: plane.position, planeNormal: up) ?? plane.position
    var pulled = 0
    let corners = points.map { point -> SIMD3<Float> in
      let ray = PinMath.ray(for: point, in: camera)
      let hit = PinMath.intersect(origin: ray.origin, direction: ray.direction, planePoint: plane.position, planeNormal: up)
      // A ray that never meets the plane (above the horizon) still points somewhere along it.
      var along = ray.direction - simd_dot(ray.direction, up) * up
      if simd_length(along) < 1e-4 { along = SIMD3(1, 0, 0) }
      let target = hit ?? middle + simd_normalize(along) * Self.areaReach
      let corner = PinMath.pulledIn(target, toward: middle, limit: Self.areaReach)
      if corner != target { pulled += 1 }
      return corner
    }
    Self.log.notice("\(kind, privacy: .public) \"\(label, privacy: .public)\": placed, centre \(simd_distance(middle, centreRay.origin), format: .fixed(precision: 2), privacy: .public) m from the camera, \(pulled, privacy: .public)/4 corners pulled in")
    lastSurface = plane
    return (corners, up)
  }

  func placeExpertArea(corners points: [UprightPoint], label: String, secondsAgo: Double) -> Bool {
    guard let (corners, normal) = footprint(points, secondsAgo: secondsAgo, label: label, kind: "Area") else { return false }
    showExpertMark(Shapes.focusArea(corners: corners, normal: normal, label: label), corners: corners, label: label)
    return true
  }

  /// How a box the expert drew moves on the phone.
  enum BoxMotion: String { case still, flip, turn }

  /// The expert dragged a box and picked a motion: a 3D block on that footprint, 2 cm high, turning over or round.
  func placeExpertBox(corners points: [UprightPoint], label: String, secondsAgo: Double, motion: BoxMotion) -> Bool {
    guard let (corners, normal) = footprint(points, secondsAgo: secondsAgo, label: label, kind: "Box") else { return false }
    let frame = Shapes.boxFrame(corners: corners, normal: normal, height: 0.02)
    let root = Entity()
    let block = Shapes.solidBox(size: frame.size)
    block.transform = Transform(matrix: frame.transform)
    root.addChild(block)
    let axisX = SIMD3(frame.transform.columns.0.x, frame.transform.columns.0.y, frame.transform.columns.0.z)
    switch motion {
    case .flip: Shapes.animate(block, action: .flip, axis: axisX)
    case .turn: Shapes.animate(block, action: .rotate90, axis: normal)
    case .still: break
    }
    let tag = Shapes.chip(badge: nil, text: label, badgeColor: Theme.accentUI)
    tag.position = corners.reduce(.zero, +) / 4 + normal * 0.06
    root.addChild(tag)
    showExpertMark(root, corners: corners, label: label)
    Self.log.notice("Box \"\(label, privacy: .public)\": \(frame.size.x, format: .fixed(precision: 2), privacy: .public) × \(frame.size.z, format: .fixed(precision: 2), privacy: .public) m, \(motion.rawValue, privacy: .public)")
    return true
  }

  /// One thing at a time: a new area or box replaces the expert's previous marks.
  private func showExpertMark(_ entity: Entity, corners: [SIMD3<Float>], label: String) {
    clearPins(kinds: [.expert])
    clearExpertArea()
    let anchor = AnchorEntity(world: matrix_identity_float4x4)
    anchor.addChild(entity)
    arView.scene.addAnchor(anchor)
    expertAreaAnchor = anchor
    expertAreaCorners = corners
    expertAreaLabel = label
  }

  func clearExpertArea() {
    expertAreaAnchor.map { arView.scene.removeAnchor($0) }
    expertAreaAnchor = nil
    expertAreaCorners = []
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

  /// Farther than this from the camera, a hit is a guess through a gap, not the laptop in front of the user: a missed
  /// mark (red on the console, try again) beats a wrong one.
  static let maxReach: Float = 1.5

  private func surfacePoint(for point: UprightPoint, camera: CameraContext) -> SurfacePoint? {
    let ray = PinMath.ray(for: point, in: camera)
    // Measured planes first, then ARKit's guess from feature points, then the table extended past its measured edge.
    let targets: [(ARRaycastQuery.Target, ARRaycastQuery.TargetAlignment)] = [
      (.existingPlaneGeometry, .any), (.estimatedPlane, .any), (.existingPlaneInfinite, .horizontal),
    ]
    for (target, alignment) in targets {
      let query = ARRaycastQuery(origin: ray.origin, direction: ray.direction, allowing: target, alignment: alignment)
      guard let hit = arView.session.raycast(query).first else { continue }
      let t = hit.worldTransform
      let position = SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
      guard simd_distance(position, ray.origin) <= Self.maxReach else { continue }
      return SurfacePoint(position: position, normal: SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z))
    }
    return nil
  }

  private func fallbackSurfacePoint(for point: UprightPoint, camera: CameraContext, reference: SurfacePoint?) -> SurfacePoint? {
    let ray = PinMath.ray(for: point, in: camera)
    if let reference, let hit = PinMath.intersect(origin: ray.origin, direction: ray.direction, planePoint: reference.position, planeNormal: reference.normal),
       simd_distance(hit, ray.origin) <= Self.maxReach {
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
      let surface = SurfacePoint(position: SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z), normal: SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z))
      lastSurface = surface
      onSurfaceTap?(surface.position, surface.normal)
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

  /// The expert's marked area, then the pins still to do, then the step's zone of the laptop, then the marker step:
  /// what the expert marked last is what's lit.
  func spotlightTarget() -> SpotlightTarget? {
    if !expertAreaCorners.isEmpty {
      return SpotlightTarget(points: expertAreaCorners, label: expertAreaLabel)
    }
    // The expert's newest mark alone, not a box round all of them: one thing to look at.
    if let newest = pins.last(where: { $0.kind == .expert && !$0.done }) {
      return SpotlightTarget(points: [newest.position], label: "\(newest.number) · \(newest.label)")
    }
    let pending = pins.filter { !$0.done }
    if !pending.isEmpty {
      let label = pending.count == 1 ? "\(pending[0].number) · \(pending[0].label)" : "\(pending.count) left"
      return SpotlightTarget(points: pending.map(\.position), label: label)
    }
    if !focusCorners.isEmpty {
      return SpotlightTarget(points: focusCorners, label: focusLabel)
    }
    if markerSeen || guideOnLaptop, !stepRoot.children.isEmpty {
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
    let feed = shared.withLock { state in
      state.lastFrameAt = now
      state.framesSinceLog += 1
      state.cameraHistory.append(cameraContext)
      if state.cameraHistory.count > 150 { state.cameraHistory.removeFirst(state.cameraHistory.count - 150) }
      return state.feed
    }

    // Every frame, shown or not, so the feed is already current the moment it has to cover the AR view.
    feed?.enqueue(frame.capturedImage)

    // Synchronous: the handler copies what it needs, so ARKit's buffer is free again when this returns.
    if let onCameraFrame { onCameraFrame(frame.capturedImage, timestamp) }

    let (scanRecorder, marker) = shared.withLock { ($0.scanRecorder, $0.markerTransform) }
    scanRecorder?.consider(frame, marker: marker)

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
    // Only the outline follows ARKit's size estimate, so it matches the print. The parts don't: their positions are
    // real metres from the marker's centre, and the anchor ARKit gives is already metric. Scaling them by the estimate
    // pushed every part proportionally too far (or too near) whenever the print wasn't exactly 18 cm.
    let outline = Shapes.markerOutline(width: Float(sample.size.width), height: Float(sample.size.height))
    outline.scale = [sample.scale, 1, sample.scale]
    markerOutline = outline
    markerRoot.addChild(outline)
    markerRoot.addChild(Shapes.axisGizmo())
    // While the guide is locked to the laptop its parts stay there; the marker only carries its outline.
    if laptopGuideAnchor == nil { markerRoot.addChild(stepRoot) }
    anchor.addChild(markerRoot)
    arView.scene.addAnchor(anchor)

    markerAnchor = anchor
    markerSeen = true
    report(sample, force: true)
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
    markerOutline?.scale = [sample.scale, 1, sample.scale]
    report(sample, force: false)
  }

  /// The debug line (twice a second), the log (every 2 s, or now when forced) and the "lay it flat" warning.
  private func report(_ sample: MarkerSample, force: Bool) {
    let now = ProcessInfo.processInfo.systemUptime
    guard force || now - lastDebugUpdate >= 0.5 else { return }
    lastDebugUpdate = now
    guard let camera = arView.session.currentFrame?.camera.transform else { return }
    let reading = MarkerReading.describe(
      transform: sample.transform, scale: sample.scale, physicalWidth: Float(sample.size.width),
      cameraPosition: SIMD3(camera.columns.3.x, camera.columns.3.y, camera.columns.3.z)
    )
    let line = stepRangeText.isEmpty ? reading.line : reading.line + " · " + stepRangeText
    if debugLine != line { debugLine = line }
    if markerNotFlat != !reading.isFlat { markerNotFlat = !reading.isFlat }
    if force || now - lastDebugLog >= 2 {
      lastDebugLog = now
      Self.log.notice("\(line, privacy: .public) · normal·up \(reading.flatness, format: .fixed(precision: 2), privacy: .public) · tracked \(sample.isTracked, privacy: .public)")
    }
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
    guard let step else {
      stepRangeText = ""
      return
    }
    let distances = step.objects.map { simd_length($0.pos.simd) }
    if let near = distances.min(), let far = distances.max() {
      stepRangeText = String(format: "%d part%@ %.2f–%.2f m from it", distances.count, distances.count == 1 ? "" : "s", near, far)
    } else {
      stepRangeText = "no parts"
    }
    Self.log.notice("Step \(step.id, privacy: .public): \(self.stepRangeText, privacy: .public)")
    for object in step.objects {
      let p = object.pos.simd
      let world = markerAnchor.map { $0.transformMatrix(relativeTo: nil) * SIMD4(p.x, p.y, p.z, 1) }
      Self.log.notice("  \(object.label ?? "part", privacy: .public): marker (\(p.x, format: .fixed(precision: 3), privacy: .public), \(p.y, format: .fixed(precision: 3), privacy: .public), \(p.z, format: .fixed(precision: 3), privacy: .public)) → world \(world.map { String(format: "(%.2f, %.2f, %.2f)", $0.x, $0.y, $0.z) } ?? "(marker not found yet)", privacy: .public)")
    }

    for (index, object) in step.objects.enumerated() {
      // Positions are already in the marker frame (contracts/protocol.ts), so they go straight onto the anchor.
      let node = Entity()
      node.position = object.pos.simd
      node.orientation = object.rot.simd
      // The box and its model together, so a flip or a turn moves the whole part (a laptop-sized box turns over);
      // an unscrew, pull or push moves only the model, out of its box.
      let body = Entity()
      body.addChild(Shapes.highlightBox(size: object.size.simd))
      let ring = Shapes.partRing(radius: max(object.size.x, object.size.z) / 2 + 0.004)
      ring.position.y = -object.size.y / 2 + 0.001
      node.addChild(ring)
      let model = Shapes.model(object.model)
      body.addChild(model)
      node.addChild(body)
      if let action = object.action {
        // The contract's axis is in the marker frame; the model lives in the object's rotated frame.
        let whole = action == .flip || action == .rotate90
        Shapes.animate(whole ? body : model, action: action, axis: object.rot.simd.inverse.act(object.axis.simd), delay: 0.15 * Double(index))
      }
      if let text = object.label {
        let label = Shapes.label(text, size: 0.018)
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
