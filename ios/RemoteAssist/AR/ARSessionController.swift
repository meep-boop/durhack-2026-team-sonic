import ARKit
import CoreImage
import Observation
import RealityKit
import UIKit

/// Owns the AR session: finds the marker under world tracking and pins the guide to where the marker was last seen.
@Observable
final class ARSessionController: NSObject, ARSessionDelegate {
  private(set) var markerTracked = false
  private(set) var markerSeen = false
  private(set) var errorMessage: String?

  /// The step being shown. Drawn as soon as the marker is found, and redrawn when it changes.
  var step: Step? {
    didSet { if step != oldValue { renderStep() } }
  }

  /// Camera poses in the marker frame, about 5 a second, once the marker has been seen.
  @ObservationIgnored var onPose: ((PoseUpdate) -> Void)?
  /// Every camera frame, for the live call. Must return fast: it runs on ARKit's delegate queue.
  @ObservationIgnored var onCameraFrame: ((CVPixelBuffer, TimeInterval) -> Void)?
  @ObservationIgnored private var markerTransform: simd_float4x4?
  @ObservationIgnored private var lastPoseTime: TimeInterval = 0

  @ObservationIgnored let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
  /// A world anchor, not an image anchor: RealityKit hides image-anchored content the moment the image is covered
  /// (a hand reaching in, the marker leaving the frame). This one stays put and only follows the marker while ARKit
  /// can actually see it.
  @ObservationIgnored private var markerAnchor: AnchorEntity?
  /// Scaled by ARKit's size estimate, so a marker shown smaller (say on a laptop screen) still lines everything up.
  @ObservationIgnored private let markerRoot = Entity()
  @ObservationIgnored private let stepRoot = Entity()
  @ObservationIgnored private var configuration: ARWorldTrackingConfiguration?
  @ObservationIgnored private let coaching = ARCoachingOverlayView()
  @ObservationIgnored private var pinAnchors: [AnchorEntity] = []
  @ObservationIgnored private let imageContext = CIContext()

  func start() {
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
    // Hands and arms in front of the boxes hide them, as a real object would.
    if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
      config.frameSemantics.insert(.personSegmentationWithDepth)
    }

    configuration = config
    arView.session.delegate = self
    arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

    // Apple's own "move your phone" guidance whenever tracking is poor.
    coaching.session = arView.session
    coaching.goal = .tracking
    coaching.activatesAutomatically = true
    coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    coaching.frame = arView.bounds
    if coaching.superview == nil { arView.addSubview(coaching) }
  }

  func pause() {
    arView.session.pause()
  }

  /// Picks up where it left off (no reset), so the guide is still on the marker after the QR scanner closes.
  func resume() {
    guard let configuration else { return }
    arView.session.run(configuration)
  }

  // MARK: Camera snapshots and AI pins

  /// The current camera image, upright for a phone held in portrait, as a JPEG small enough to send to Gemini.
  func snapshotJPEG(maxSide: CGFloat = 1024) -> Data? {
    guard let buffer = arView.session.currentFrame?.capturedImage else { return nil }
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

  // MARK: ARSessionDelegate (main queue)

  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for case let image as ARImageAnchor in anchors {
      attach(to: image)
    }
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    for case let image as ARImageAnchor in anchors {
      if markerTracked != image.isTracked { markerTracked = image.isTracked }
      // While covered, ARKit's last pose for the image goes stale, so keep the guide where it was.
      guard image.isTracked else { continue }
      follow(image)
    }
  }

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    onCameraFrame?(frame.capturedImage, frame.timestamp)
    guard let onPose, let markerTransform, frame.timestamp - lastPoseTime >= 0.2 else { return }
    lastPoseTime = frame.timestamp
    // The contract's frame is the marker's, so the camera is expressed relative to the marker anchor.
    let camera = markerTransform.inverse * frame.camera.transform
    let position = SIMD3(camera.columns.3.x, camera.columns.3.y, camera.columns.3.z)
    onPose(PoseUpdate(
      t: Int64(Date().timeIntervalSince1970 * 1000),
      camera: Pose(p: Vec3(position), q: Quat(simd_quatf(camera))),
      markerTracked: markerTracked
    ))
  }

  func session(_ session: ARSession, didFailWithError error: Error) {
    errorMessage = error.localizedDescription
  }

  // MARK: Content

  private func attach(to image: ARImageAnchor) {
    markerAnchor.map { arView.scene.removeAnchor($0) }

    let anchor = AnchorEntity(world: image.transform)
    let size = image.referenceImage.physicalSize
    markerRoot.children.removeAll()
    markerRoot.addChild(Shapes.markerOutline(width: Float(size.width), height: Float(size.height)))
    markerRoot.addChild(Shapes.axisGizmo())
    markerRoot.addChild(stepRoot)
    markerRoot.scale = SIMD3(repeating: Float(image.estimatedScaleFactor))
    anchor.addChild(markerRoot)
    arView.scene.addAnchor(anchor)

    markerAnchor = anchor
    markerTransform = image.transform
    markerSeen = true
    markerTracked = image.isTracked
  }

  private func follow(_ image: ARImageAnchor) {
    guard let markerAnchor else { return }
    let target = Transform(matrix: image.transform)
    let jump = simd_distance(markerAnchor.transform.translation, target.translation)
    // Small corrections are applied straight away; a big re-find after the marker was covered glides instead of jumping.
    if jump > 0.02 {
      markerAnchor.move(to: target, relativeTo: nil, duration: 0.15, timingFunction: .easeOut)
    } else {
      markerAnchor.transform = target
    }
    markerTransform = image.transform
    markerRoot.scale = SIMD3(repeating: Float(image.estimatedScaleFactor))
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
