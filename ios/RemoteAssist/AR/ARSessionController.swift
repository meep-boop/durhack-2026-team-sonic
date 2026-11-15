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

  /// A pin on the real surface: from the AI, from the expert tapping the video, or a screw going back in.
  struct PinInfo: Identifiable, Equatable {
    let id: UUID
    let number: Int
    let label: String
    let kind: Shapes.PinKind
    var done: Bool
    /// Where it stands in the world (+Y is the surface normal), kept for screw memory.
    let transform: simd_float4x4
    /// Where it was in the photo it came from, for the screw map.
    let photoPoint: UprightPoint?
    var position: SIMD3<Float> { SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z) }
  }

  private(set) var pins: [PinInfo] = []
  private(set) var hasFocusArea = false
  /// Set while the ghost screwdriver should show on the next pin: the way to turn, or nil to hide it.
  var ghostTurnsAnticlockwise: Bool? {
    didSet { if ghostTurnsAnticlockwise != oldValue { updateGhost(rebuild: true) } }
  }
  /// Called on main when the user taps a pin to tick or untick it.
  @ObservationIgnored var onPinToggled: ((PinInfo) -> Void)?

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
  @ObservationIgnored private var pinEntities: [UUID: (anchor: AnchorEntity, arAnchor: ARAnchor, entity: Entity)] = [:]
  @ObservationIgnored private var focusAnchor: AnchorEntity?
  @ObservationIgnored private var focusCorners: [SIMD3<Float>] = []
  @ObservationIgnored private var focusLabel = ""
  @ObservationIgnored private var ghost: Entity?
  @ObservationIgnored private var ghostPinId: UUID?
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
    // Surfaces are what AI pins and expert taps land on. Without them, raycasts guessed (often the desk, or air).
    config.planeDetection = [.horizontal, .vertical]
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
    arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))

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

  // MARK: Snapshots (main)

  /// A photo plus the camera that took it. Points found in the photo later are projected through `camera`.
  struct Snapshot {
    let camera: CameraContext
    /// Full resolution, upright for a phone held in portrait. Crops for the zoomed second pass come from this.
    let image: CGImage
    /// Scaled to at most `maxSide`, for Gemini's first pass.
    let jpeg: Data
  }

  func captureSnapshot(maxSide: CGFloat = 1536) -> Snapshot? {
    guard isRunning, let frame = arView.session.currentFrame else { return nil }
    let camera = CameraContext(frame)
    let upright = CIImage(cvPixelBuffer: frame.capturedImage).oriented(.right)
    guard let image = imageContext.createCGImage(upright, from: upright.extent) else { return nil }
    let scale = min(1, maxSide / max(upright.extent.width, upright.extent.height))
    let scaled = upright.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let jpeg = imageContext.jpegRepresentation(of: scaled, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:]) else { return nil }
    return Snapshot(camera: camera, image: image, jpeg: jpeg)
  }

  /// The current camera image as a JPEG, for the AI's identify and check calls.
  func snapshotJPEG(maxSide: CGFloat = 1024) -> Data? {
    captureSnapshot(maxSide: maxSide)?.jpeg
  }

  /// True once ARKit has found a horizontal surface (the desk or the laptop's underside) to put pins on.
  var hasHorizontalSurface: Bool {
    arView.session.currentFrame?.anchors.contains { ($0 as? ARPlaneAnchor)?.alignment == .horizontal } ?? false
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

  /// Places numbered pins (and the "Work here" area) for points in a photo, through the camera that took it.
  /// Returns how many pins landed on a surface.
  @discardableResult
  func placePins(
    _ points: [(point: UprightPoint, label: String)],
    focus: [UprightPoint]? = nil,
    focusLabel: String = "Work here",
    camera: CameraContext,
    kind: Shapes.PinKind = .ai
  ) -> Int {
    var surfaces = points.map { surfacePoint(for: $0.point, camera: camera) }
    // The laptop's underside is flat: a point the raycast missed goes onto the plane of one that hit.
    let reference = surfaces.compactMap { $0 }.first
    for i in surfaces.indices where surfaces[i] == nil {
      surfaces[i] = fallbackSurfacePoint(for: points[i].point, camera: camera, reference: reference)
    }

    // Reading order (top to bottom, then left to right), so "screw 1" is where a person would start.
    let ordered = zip(points, surfaces)
      .compactMap { item, surface in surface.map { (item, $0) } }
      .sorted { a, b in
        let rowA = (a.0.point.y / 0.08).rounded(), rowB = (b.0.point.y / 0.08).rounded()
        return rowA == rowB ? a.0.point.x < b.0.point.x : rowA < rowB
      }
    let firstNumber = (pins.filter { $0.kind == kind }.map(\.number).max() ?? 0) + 1
    for (offset, (item, surface)) in ordered.enumerated() {
      addPin(
        number: firstNumber + offset, label: item.label, kind: kind,
        transform: PinMath.standing(at: surface.position, normal: surface.normal), photoPoint: item.point
      )
    }

    if let focus, focus.count == 4 {
      let corners = focus.map { surfacePoint(for: $0, camera: camera) ?? fallbackSurfacePoint(for: $0, camera: camera, reference: reference) }
      if corners.allSatisfy({ $0 != nil }) {
        showFocus(corners: corners.compactMap { $0 }, label: focusLabel)
      }
    }
    updateGhost(rebuild: false)
    return ordered.count
  }

  /// Puts back pins at transforms saved earlier (screw memory), numbered as given.
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

  /// Clears pins of the given kinds (all by default) and the "Work here" area.
  func clearPins(kinds: Set<Shapes.PinKind> = [.ai, .expert, .refit], focus: Bool = true) {
    for pin in pins where kinds.contains(pin.kind) {
      if let entry = pinEntities.removeValue(forKey: pin.id) {
        arView.scene.removeAnchor(entry.anchor)
        arView.session.remove(anchor: entry.arAnchor)
      }
    }
    pins.removeAll { kinds.contains($0.kind) }
    if focus {
      focusAnchor.map { arView.scene.removeAnchor($0) }
      focusAnchor = nil
      focusCorners = []
      hasFocusArea = false
    }
    updateGhost(rebuild: false)
  }

  private func addPin(number: Int, label: String, kind: Shapes.PinKind, transform: simd_float4x4, photoPoint: UprightPoint?) {
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
  }

  private func showFocus(corners: [SurfacePoint], label: String) {
    focusAnchor.map { arView.scene.removeAnchor($0) }
    let normal = simd_normalize(corners.map(\.normal).reduce(.zero, +))
    let anchor = AnchorEntity(world: matrix_identity_float4x4)
    anchor.addChild(Shapes.focusArea(corners: corners.map(\.position), normal: normal, label: label))
    arView.scene.addAnchor(anchor)
    focusAnchor = anchor
    focusCorners = corners.map(\.position)
    focusLabel = label
    hasFocusArea = true
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

  /// The ghost screwdriver sits on the first pin not yet done (AI or refit pins only).
  private func updateGhost(rebuild: Bool) {
    let target = pins.first { !$0.done && $0.kind != .expert }
    guard let anticlockwise = ghostTurnsAnticlockwise, let target, let anchor = pinEntities[target.id]?.anchor else {
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

  /// The expert's newest pin first, then the "Work here" area, then the pins still to do, then the marker step.
  func spotlightTarget() -> SpotlightTarget? {
    if let expert = pins.last(where: { $0.kind == .expert && !$0.done }) {
      return SpotlightTarget(points: [expert.position], label: "Expert: \(expert.label)")
    }
    if !focusCorners.isEmpty, pins.contains(where: { !$0.done }) || pins.isEmpty {
      return SpotlightTarget(points: focusCorners, label: focusLabel)
    }
    let pending = pins.filter { !$0.done }
    if !pending.isEmpty {
      let label = pending.count == 1 ? "\(pending[0].number) · \(pending[0].label)" : "\(pending.count) left"
      return SpotlightTarget(points: pending.map(\.position), label: label)
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
    shared.withLock { state in
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
