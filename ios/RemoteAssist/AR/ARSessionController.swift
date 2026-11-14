import ARKit
import Observation
import RealityKit
import UIKit

/// Owns the AR session: finds the marker under world tracking and pins the guide to its anchor.
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
  @ObservationIgnored private var markerTransform: simd_float4x4?
  @ObservationIgnored private var lastPoseTime: TimeInterval = 0

  @ObservationIgnored let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
  @ObservationIgnored private var markerAnchor: AnchorEntity?
  @ObservationIgnored private let stepRoot = Entity()

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

    arView.session.delegate = self
    arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
  }

  func pause() {
    arView.session.pause()
  }

  // MARK: ARSessionDelegate (main queue)

  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for case let image as ARImageAnchor in anchors {
      attach(to: image)
    }
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    for case let image as ARImageAnchor in anchors {
      markerTransform = image.transform
      if markerTracked != image.isTracked { markerTracked = image.isTracked }
    }
  }

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
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

    let anchor = AnchorEntity(anchor: image)
    let size = image.referenceImage.physicalSize
    anchor.addChild(Shapes.markerOutline(width: Float(size.width), height: Float(size.height)))
    anchor.addChild(Shapes.axisGizmo())
    anchor.addChild(stepRoot)
    arView.scene.addAnchor(anchor)

    markerAnchor = anchor
    markerTransform = image.transform
    markerSeen = true
    markerTracked = image.isTracked
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
      node.addChild(Shapes.placeholder(for: object.model))
      if let text = object.label {
        let label = Shapes.label(text)
        label.position = [0, object.size.y / 2 + 0.012, 0]
        node.addChild(label)
      }
      stepRoot.addChild(node)
    }
  }
}
