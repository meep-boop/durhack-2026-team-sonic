import ARKit
import CoreImage
import Observation
import RealityKit
import UIKit
import os

/// Owns the AR session: finds the marker under world tracking and pins the guide to where the marker was last seen.
///
/// Threading: ARKit calls the delegate on `sessionQueue`, never on main. Each queued delegate call holds its ARFrame,
/// so with the delegate on main, any busy moment on main (SwiftUI, audio setup) used to pile up ARKit's frames until
/// it logged "retaining 11 ARFrames" and stopped sending camera images. Now the per-frame work (call video, pose)
/// finishes on `sessionQueue`, and main only gets the marker's latest state, coalesced to one hop at a time.
/// Observable state and every RealityKit entity are touched on main only.
@Observable
final class ARSessionController: NSObject, ARSessionDelegate {
  private(set) var markerTracked = false
  private(set) var markerSeen = false
  private(set) var errorMessage: String?
  /// True while the marker was found once but isn't visible right now, for long enough to be worth saying.
  private(set) var markerLostForAWhile = false

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

  @ObservationIgnored let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
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
  @ObservationIgnored private var pinAnchors: [AnchorEntity] = []
  @ObservationIgnored private let imageContext = CIContext()
  @ObservationIgnored private var glideEndsAt: Date = .distantPast
  @ObservationIgnored private var lostTimer: Task<Void, Never>?
  @ObservationIgnored private var thermalObserver: NSObjectProtocol?

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
    config.planeDetection = []
    config.automaticImageScaleEstimationEnabled = true
    configuration = config
    applyThermalLimits(to: config)

    arView.session.delegateQueue = sessionQueue
    arView.session.delegate = self
    arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    isRunning = true

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
  }

  func pause() {
    guard isRunning else { return }
    isRunning = false
    arView.session.pause()
  }

  /// Picks up where it left off (no reset), so the guide is still on the marker after the QR scanner closes or the
  /// app comes back from the background.
  func resume() {
    guard let configuration, !isRunning else { return }
    isRunning = true
    arView.session.run(configuration)
  }

  /// Hands and arms in front of the boxes hide them, as a real object would, unless the phone is running hot.
  private func applyThermalLimits(to config: ARWorldTrackingConfiguration) {
    let hot = ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    if !hot, ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
      config.frameSemantics.insert(.personSegmentationWithDepth)
    } else {
      config.frameSemantics.remove(.personSegmentationWithDepth)
    }
  }

  // MARK: Camera snapshots and AI pins (main)

  /// The current camera image, upright for a phone held in portrait, as a JPEG small enough to send to Gemini.
  func snapshotJPEG(maxSide: CGFloat = 1024) -> Data? {
    guard isRunning, let buffer = arView.session.currentFrame?.capturedImage else { return nil }
    let upright = CIImage(cvPixelBuffer: buffer).oriented(.right)
    let scale = min(1, maxSide / max(upright.extent.width, upright.extent.height))
    let image = upright.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    return imageContext.jpegRepresentation(of: image, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
  }

  /// Drops a pin on the real surface under each point, given as fractions of the portrait snapshot (top-left origin).
  /// Returns how many points hit a surface.
  @discardableResult
  func placePins(_ points: [(x: Double, y: Double, label: String)]) -> Int {
    clearPins()
    guard let frame = arView.session.currentFrame else { return 0 }
    let viewSize = arView.bounds.size
    // The snapshot was the sensor image turned upright, so undo that turn, then let ARKit map sensor → screen.
    let toView = frame.displayTransform(for: .portrait, viewportSize: viewSize)
    var placed = 0
    for point in points {
      let sensor = CGPoint(x: point.y, y: 1 - point.x).applying(toView)
      let screen = CGPoint(x: sensor.x * viewSize.width, y: sensor.y * viewSize.height)
      guard let hit = arView.raycast(from: screen, allowing: .estimatedPlane, alignment: .any).first else { continue }
      let anchor = AnchorEntity(world: hit.worldTransform)
      anchor.addChild(Shapes.pin(label: point.label))
      arView.scene.addAnchor(anchor)
      pinAnchors.append(anchor)
      placed += 1
    }
    return placed
  }

  func clearPins() {
    pinAnchors.forEach { arView.scene.removeAnchor($0) }
    pinAnchors.removeAll()
  }

  // MARK: ARSessionDelegate (sessionQueue)

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    let timestamp = frame.timestamp
    let cameraTransform = frame.camera.transform

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

  func session(_ session: ARSession, didFailWithError error: Error) {
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
