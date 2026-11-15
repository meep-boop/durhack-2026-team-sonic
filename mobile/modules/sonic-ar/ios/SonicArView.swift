import ARKit
import ExpoModulesCore
import RealityKit

class SonicArView: ExpoView, ARSessionDelegate {
  let onPlaneDetected = EventDispatcher()
  let onImageDetected = EventDispatcher()
  let onMeasure = EventDispatcher()
  let onError = EventDispatcher()

  private(set) var mode = "place"
  private(set) var markerUri: String?
  private(set) var markerWidth: Double = 0.15

  private let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
  private let coaching = ARCoachingOverlayView()
  private var needsConfiguration = true
  private var reportedPlane = false
  private var placedAnchors: [AnchorEntity] = []
  private var measureRoot: AnchorEntity?
  private var measureStart: SIMD3<Float>?

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    backgroundColor = .black

    arView.session.delegate = self
    arView.renderOptions.insert(.disableMotionBlur)
    addSubview(arView)

    coaching.session = arView.session
    coaching.activatesAutomatically = true
    coaching.goal = .anyPlane
    addSubview(coaching)

    arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    arView.frame = bounds
    coaching.frame = bounds
  }

  // The camera only runs while the AR tab is on screen; leaving the tab pauses it to save battery.
  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      arView.session.pause()
    } else {
      needsConfiguration = true
      applyConfigurationIfNeeded()
    }
  }

  // MARK: Props

  func setMode(_ newMode: String) {
    guard newMode != mode else { return }
    mode = newMode
    needsConfiguration = true
  }

  func setMarker(uri: String?, width: Double) {
    guard uri != markerUri || width != markerWidth else { return }
    markerUri = uri
    markerWidth = width
    if mode == "image" { needsConfiguration = true }
  }

  func applyConfigurationIfNeeded() {
    guard needsConfiguration, window != nil else { return }
    needsConfiguration = false

    guard ARWorldTrackingConfiguration.isSupported else {
      onError(["message": "This device doesn't support ARKit world tracking."])
      return
    }

    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal, .vertical]
    config.environmentTexturing = .automatic

    // LiDAR mesh makes measuring hit real surfaces (edges, objects), not just flat planes.
    if mode == "measure", ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
      config.sceneReconstruction = .mesh
    }

    if mode == "image" {
      if let images = loadMarker() {
        config.detectionImages = images
        config.maximumNumberOfTrackedImages = 1
      }
      coaching.goal = .tracking
    } else {
      coaching.goal = .anyPlane
    }

    clearContent()
    reportedPlane = false
    arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
  }

  func reset() {
    needsConfiguration = true
    applyConfigurationIfNeeded()
  }

  private func loadMarker() -> Set<ARReferenceImage>? {
    guard let uri = markerUri, let url = URL(string: uri), url.isFileURL,
          let cgImage = UIImage(contentsOfFile: url.path)?.cgImage else {
      onError(["message": "Marker image isn't loaded yet."])
      return nil
    }
    let reference = ARReferenceImage(cgImage, orientation: .up, physicalWidth: CGFloat(markerWidth))
    reference.name = "marker"
    return [reference]
  }

  private func clearContent() {
    placedAnchors.forEach { arView.scene.removeAnchor($0) }
    placedAnchors.removeAll()
    clearMeasurement()
  }

  // MARK: Taps

  @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
    let point = gesture.location(in: arView)
    guard let hit = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first else { return }

    switch mode {
    case "place":
      placeBox(at: hit.worldTransform)
    case "measure":
      let column = hit.worldTransform.columns.3
      addMeasurePoint(SIMD3(column.x, column.y, column.z))
    default:
      break
    }
  }

  private func placeBox(at transform: simd_float4x4) {
    let anchor = AnchorEntity(world: transform)
    let size: Float = 0.1
    let box = ModelEntity(
      mesh: .generateBox(size: size, cornerRadius: 0.008),
      materials: [SimpleMaterial(color: .systemBlue, roughness: 0.35, isMetallic: false)]
    )
    // Raycast hits put +Y along the surface normal, so this sits the box on the surface instead of half inside it.
    box.position.y = size / 2
    box.generateCollisionShapes(recursive: false)
    arView.installGestures([.translation, .rotation, .scale], for: box)

    anchor.addChild(box)
    arView.scene.addAnchor(anchor)
    placedAnchors.append(anchor)
  }

  // MARK: Measure

  private func addMeasurePoint(_ point: SIMD3<Float>) {
    guard let start = measureStart else {
      clearMeasurement()
      let root = AnchorEntity(world: .zero)
      arView.scene.addAnchor(root)
      measureRoot = root
      root.addChild(makeDot(at: point))
      measureStart = point
      return
    }

    measureRoot?.addChild(makeDot(at: point))
    measureRoot?.addChild(makeLine(from: start, to: point))
    measureStart = nil
    onMeasure(["meters": Double(simd_distance(start, point))])
  }

  private func clearMeasurement() {
    if let root = measureRoot { arView.scene.removeAnchor(root) }
    measureRoot = nil
    measureStart = nil
  }

  private func makeDot(at point: SIMD3<Float>) -> ModelEntity {
    let dot = ModelEntity(mesh: .generateSphere(radius: 0.006), materials: [UnlitMaterial(color: .systemYellow)])
    dot.position = point
    return dot
  }

  private func makeLine(from start: SIMD3<Float>, to end: SIMD3<Float>) -> ModelEntity {
    let length = simd_distance(start, end)
    let line = ModelEntity(
      mesh: .generateBox(size: SIMD3(0.002, 0.002, length)),
      materials: [UnlitMaterial(color: .systemYellow)]
    )
    let middle = (start + end) / 2
    // look(at:) points the entity's -Z axis at the target, which is the axis the box is stretched along.
    line.look(at: end, from: middle, relativeTo: nil)
    return line
  }

  // MARK: ARSessionDelegate (called on the main queue)

  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for anchor in anchors {
      if anchor is ARPlaneAnchor, !reportedPlane {
        reportedPlane = true
        onPlaneDetected()
      } else if let image = anchor as? ARImageAnchor {
        showOverlay(on: image)
        onImageDetected(["name": image.referenceImage.name ?? "marker"])
      }
    }
  }

  func session(_ session: ARSession, didFailWithError error: Error) {
    onError(["message": error.localizedDescription])
  }

  private func showOverlay(on image: ARImageAnchor) {
    let anchor = AnchorEntity(anchor: image)
    let size = image.referenceImage.physicalSize

    let plane = ModelEntity(
      mesh: .generatePlane(width: Float(size.width), depth: Float(size.height)),
      materials: [SimpleMaterial(color: UIColor.systemBlue.withAlphaComponent(0.45), isMetallic: false)]
    )
    let cubeSize = Float(size.width) * 0.4
    let cube = ModelEntity(
      mesh: .generateBox(size: cubeSize, cornerRadius: cubeSize * 0.08),
      materials: [SimpleMaterial(color: .systemYellow, roughness: 0.3, isMetallic: true)]
    )
    cube.position.y = cubeSize / 2

    anchor.addChild(plane)
    anchor.addChild(cube)
    arView.scene.addAnchor(anchor)
    placedAnchors.append(anchor)
  }
}
