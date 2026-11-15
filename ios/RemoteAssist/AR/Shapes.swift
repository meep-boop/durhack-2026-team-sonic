import RealityKit
import UIKit

enum Shapes {
  static func bar(from start: SIMD3<Float>, to end: SIMD3<Float>, thickness: Float, color: UIColor) -> ModelEntity {
    let length = simd_distance(start, end)
    let bar = ModelEntity(
      mesh: .generateBox(size: SIMD3(thickness, thickness, length)),
      materials: [UnlitMaterial(color: color)]
    )
    // look(at:) aims -Z at the target, which is the axis the box is stretched along.
    bar.look(at: end, from: (start + end) / 2, relativeTo: nil)
    return bar
  }

  /// Four bars around the printed marker, lying in the anchor's X–Z plane.
  static func markerOutline(width: Float, height: Float) -> Entity {
    let root = Entity()
    let x = width / 2, z = height / 2, y: Float = 0.001
    let corners: [SIMD3<Float>] = [[-x, y, -z], [x, y, -z], [x, y, z], [-x, y, z]]
    for i in 0..<4 {
      root.addChild(bar(from: corners[i], to: corners[(i + 1) % 4], thickness: 0.003, color: .systemGreen))
    }
    return root
  }

  /// Red +X, green +Y, blue +Z, with a ball on each positive end, so you can read which printed edge each axis
  /// points to (Apple doesn't document it, and the protocol depends on it).
  static func axisGizmo(length: Float = 0.08) -> Entity {
    let root = Entity()
    let axes: [(SIMD3<Float>, UIColor)] = [([length, 0, 0], .systemRed), ([0, length, 0], .systemGreen), ([0, 0, length], .systemBlue)]
    for (end, color) in axes {
      root.addChild(bar(from: .zero, to: end, thickness: 0.004, color: color))
      let cap = ModelEntity(mesh: .generateSphere(radius: 0.007), materials: [UnlitMaterial(color: color)])
      cap.position = end
      root.addChild(cap)
    }
    return root
  }

  /// The 12 edges of a box of full extents `size`, centred on the origin, plus a faint fill.
  static func highlightBox(size: SIMD3<Float>) -> Entity {
    let root = Entity()
    let fill = ModelEntity(
      mesh: .generateBox(size: size),
      materials: [UnlitMaterial(color: Theme.accentUI.withAlphaComponent(0.18))]
    )
    root.addChild(fill)

    let h = size / 2
    let corners: [SIMD3<Float>] = [
      [-h.x, -h.y, -h.z], [h.x, -h.y, -h.z], [h.x, -h.y, h.z], [-h.x, -h.y, h.z],
      [-h.x, h.y, -h.z], [h.x, h.y, -h.z], [h.x, h.y, h.z], [-h.x, h.y, h.z],
    ]
    let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)]
    for (a, b) in edges {
      root.addChild(bar(from: corners[a], to: corners[b], thickness: 0.0012, color: Theme.accentUI))
    }
    return root
  }

  private static var modelCache: [ModelName: Entity] = [:]
  private static var missingModels: Set<ModelName> = []

  /// Loads every bundled model in the background at launch, so the first step that uses one doesn't stall a frame
  /// while its USDZ is read from disk.
  @MainActor
  static func preloadModels() async {
    for name in ModelName.known where modelCache[name] == nil && !missingModels.contains(name) {
      do {
        modelCache[name] = try await Entity(named: name.rawValue)
      } catch {
        missingModels.insert(name)
      }
    }
  }

  /// @laura's model from assets/models/ (tip at the origin, +Y up, metres), or a simple stand-in if it won't load.
  static func model(_ name: ModelName) -> Entity {
    if let cached = modelCache[name] { return cached.clone(recursive: true) }
    guard !missingModels.contains(name), let loaded = try? Entity.load(named: name.rawValue) else {
      missingModels.insert(name)
      return placeholder(for: name)
    }
    modelCache[name] = loaded
    return loaded.clone(recursive: true)
  }

  /// Loops the action until the step changes, along `axis` (in the model's frame), as assets/models/README.md says:
  /// pull is +axis, push is -axis, unscrew spins around it, flip and rotate90 turn about it.
  static func animate(_ entity: Entity, action: Action, axis: SIMD3<Float>) {
    let direction = simd_length(axis) > 0 ? simd_normalize(axis) : SIMD3<Float>(0, 1, 0)
    let start = entity.transform
    var end = start
    var mode = AnimationRepeatMode.autoReverse
    var duration = 0.8

    switch action {
    case .pull:
      end.translation += direction * 0.02
    case .push:
      end.translation -= direction * 0.02
    case .unscrew:
      // Anticlockwise seen from +axis (out of the hole), the way a screw comes undone. Spin, not a from–to half
      // turn: a half turn starts and ends at the same orientation, so it could play in either direction.
      spin(entity, anticlockwise: true, axis: direction)
      return
    case .flip:
      end.rotation = simd_quatf(angle: .pi, axis: direction) * start.rotation
      duration = 1.2
    case .rotate90:
      end.rotation = simd_quatf(angle: .pi / 2, axis: direction) * start.rotation
    }

    let definition = FromToByAnimation(from: start, to: end, duration: duration, timing: .easeInOut, bindTarget: .transform, repeatMode: mode)
    if let animation = try? AnimationResource.generate(with: definition) {
      entity.playAnimation(animation)
    }
  }

  /// Stand-ins for when a model file is missing.
  static func placeholder(for model: ModelName) -> ModelEntity {
    let metal = SimpleMaterial(color: .lightGray, roughness: 0.25, isMetallic: true)
    switch model {
    case .screw:
      return ModelEntity(mesh: .generateCylinder(height: 0.012, radius: 0.004), materials: [metal])
    case .bolt:
      return ModelEntity(mesh: .generateCylinder(height: 0.02, radius: 0.006), materials: [metal])
    case .screwdriver:
      return ModelEntity(mesh: .generateCylinder(height: 0.12, radius: 0.004), materials: [SimpleMaterial(color: .systemRed, isMetallic: false)])
    case .arrow:
      return ModelEntity(mesh: .generateCone(height: 0.03, radius: 0.01), materials: [SimpleMaterial(color: .systemOrange, isMetallic: false)])
    case .hand:
      return ModelEntity(mesh: .generateSphere(radius: 0.015), materials: [SimpleMaterial(color: .systemPink, isMetallic: false)])
    case .cablePlug:
      return ModelEntity(mesh: .generateBox(size: [0.01, 0.014, 0.01], cornerRadius: 0.001), materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)])
    case .ssd:
      // An M.2 2280 stick: 22 × 80 mm, lying flat, its connector edge at the origin along +Z.
      let stick = ModelEntity(mesh: .generateBox(size: [0.022, 0.0025, 0.08], cornerRadius: 0.0005), materials: [SimpleMaterial(color: .systemGreen, roughness: 0.6, isMetallic: false)])
      stick.position = [0, 0.00125, 0.04]
      let root = ModelEntity()
      root.addChild(stick)
      return root
    case .other:
      return ModelEntity(mesh: .generateBox(size: 0.015, cornerRadius: 0.002), materials: [SimpleMaterial(color: .systemPurple, isMetallic: false)])
    }
  }

  enum PinKind {
    /// From the laptop layout: where this step's parts are.
    case guide
    /// Tapped by the expert on the live video.
    case expert
    /// A screw going back into the hole it came out of.
    case refit

    var color: UIColor {
      switch self {
      case .guide: Theme.accentUI
      case .expert: .white
      case .refit: Theme.accentSoftUI
      }
    }
  }

  private static let tintName = "pin-tint"
  private static let ringName = "pin-ring"
  private static let tagName = "pin-tag"

  /// A numbered pin standing on the surface: a pulsing ring, a stem, a ball and "3 · screw" above it.
  /// Built along +Y, so a transform from `PinMath.standing` makes it stand up off any surface.
  static func pin(number: Int, label text: String, kind: PinKind) -> Entity {
    let root = Entity()
    let tint = UnlitMaterial(color: kind.color)
    let ring = ModelEntity(mesh: .generateCylinder(height: 0.001, radius: 0.011), materials: [UnlitMaterial(color: kind.color.withAlphaComponent(0.55))])
    ring.name = ringName
    root.addChild(ring)
    let stem = ModelEntity(mesh: .generateCylinder(height: 0.035, radius: 0.0012), materials: [tint])
    stem.position.y = 0.0175
    stem.name = tintName
    root.addChild(stem)
    let head = ModelEntity(mesh: .generateSphere(radius: 0.007), materials: [tint])
    head.position.y = 0.037
    head.name = tintName
    root.addChild(head)
    let tag = label("\(number) · \(text)", size: 0.011)
    tag.position.y = 0.05
    tag.name = tagName
    root.addChild(tag)
    pulse(ring)
    return root
  }

  /// Green with a tick once the user has done it; back to its kind's colour if they untick it.
  static func setPin(_ pin: Entity, done: Bool, number: Int, label text: String, kind: PinKind) {
    let color = done ? UIColor.systemGreen : kind.color
    for child in pin.children {
      guard let model = child as? ModelEntity, child.name == tintName || child.name == ringName else { continue }
      model.model?.materials = [UnlitMaterial(color: color.withAlphaComponent(child.name == ringName ? 0.55 : 1))]
    }
    if let old = pin.children.first(where: { $0.name == tagName }) {
      let tag = label(done ? "✓ \(number)" : "\(number) · \(text)", size: 0.011)
      tag.position = old.position
      tag.name = tagName
      old.removeFromParent()
      pin.addChild(tag)
    }
  }

  /// "Work here": a translucent quad lying on the surface through four world points, with a glowing outline.
  /// Its parent should be a world anchor at the origin, since the points are already in world space.
  static func focusArea(corners: [SIMD3<Float>], normal: SIMD3<Float>, label text: String) -> Entity {
    let root = Entity()
    guard corners.count == 4 else { return root }
    // Lifted 2 mm off the surface so it doesn't flicker against the real laptop's depth.
    let lifted = corners.map { $0 + simd_normalize(normal) * 0.002 }

    var descriptor = MeshDescriptor(name: "focus")
    descriptor.positions = MeshBuffers.Positions(lifted)
    // Both windings, so it shows whichever side the camera is on.
    descriptor.primitives = .triangles([0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2])
    if let mesh = try? MeshResource.generate(from: [descriptor]) {
      let fill = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: Theme.accentUI.withAlphaComponent(0.22))])
      root.addChild(fill)
      if let animation = try? AnimationResource.generate(with: FromToByAnimation<Float>(
        from: 0.45, to: 1, duration: 1.1, timing: .easeInOut, bindTarget: .opacity, repeatMode: .autoReverse
      )) {
        fill.components.set(OpacityComponent(opacity: 1))
        fill.playAnimation(animation)
      }
    }
    for i in 0..<4 {
      root.addChild(bar(from: lifted[i], to: lifted[(i + 1) % 4], thickness: 0.0025, color: Theme.accentUI))
    }
    let centre = lifted.reduce(.zero, +) / 4
    let tag = label(text, size: 0.013)
    tag.position = centre + simd_normalize(normal) * 0.03
    root.addChild(tag)
    return root
  }

  /// The laptop's footprint on the table: a purple outline that says "locked on".
  static func laptopOutline(corners: [SIMD3<Float>], normal: SIMD3<Float>) -> Entity {
    let root = Entity()
    guard corners.count == 4 else { return root }
    let lifted = corners.map { $0 + simd_normalize(normal) * 0.002 }
    for i in 0..<4 {
      root.addChild(bar(from: lifted[i], to: lifted[(i + 1) % 4], thickness: 0.004, color: Theme.accentUI))
    }
    // A dot on the top-left corner, so it's clear which way round the laptop was read.
    let dot = ModelEntity(mesh: .generateSphere(radius: 0.006), materials: [UnlitMaterial(color: .white)])
    dot.position = lifted[0]
    root.addChild(dot)
    return root
  }

  /// Where the first corner was tapped, while waiting for the second.
  static func cornerMarker() -> Entity {
    let root = Entity()
    root.addChild(ModelEntity(mesh: .generateSphere(radius: 0.008), materials: [UnlitMaterial(color: Theme.accentUI)]))
    let ring = ModelEntity(mesh: .generateCylinder(height: 0.001, radius: 0.016), materials: [UnlitMaterial(color: Theme.accentUI.withAlphaComponent(0.5))])
    root.addChild(ring)
    pulse(ring)
    return root
  }

  /// A see-through screwdriver standing on a pin, turning the way the user should turn theirs.
  static func ghostTool(anticlockwise: Bool) -> Entity {
    let tool = model(.screwdriver)
    tool.components.set(OpacityComponent(opacity: 0.45))
    spin(tool, anticlockwise: anticlockwise)
    return tool
  }

  /// Quarter turns repeated forever about the entity's +Y. A half turn (π) is ambiguous: the start and end
  /// orientations are the same, so the interpolation can go either way. A quarter turn always goes the stated way.
  /// Seen from +Y looking down at the screw head, a positive angle is anticlockwise: undoing it.
  static func spin(_ entity: Entity, anticlockwise: Bool, axis: SIMD3<Float> = [0, 1, 0], duration: Double = 0.35) {
    let start = entity.transform
    var end = start
    end.rotation = simd_quatf(angle: (anticlockwise ? 1 : -1) * .pi / 2, axis: simd_normalize(axis)) * start.rotation
    let definition = FromToByAnimation(from: start, to: end, duration: duration, timing: .linear, bindTarget: .transform, repeatMode: .repeat)
    if let animation = try? AnimationResource.generate(with: definition) {
      entity.playAnimation(animation)
    }
  }

  private static func pulse(_ ring: Entity) {
    var pulse = Transform(scale: [1.8, 1, 1.8])
    pulse.translation = ring.position
    if let animation = try? AnimationResource.generate(with: FromToByAnimation(
      from: ring.transform, to: pulse, duration: 0.9, timing: .easeInOut, bindTarget: .transform, repeatMode: .autoReverse
    )) {
      ring.playAnimation(animation)
    }
  }

  static func label(_ text: String, size: CGFloat = 0.012) -> Entity {
    let mesh = MeshResource.generateText(text, extrusionDepth: 0.0005, font: .systemFont(ofSize: size, weight: .semibold))
    let model = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .white)])
    // Text meshes start at their bottom-left corner; centre it over the object.
    let bounds = model.visualBounds(relativeTo: nil)
    model.position = [-bounds.center.x, 0, 0]
    let root = Entity()
    root.addChild(model)
    root.components.set(BillboardComponent())
    return root
  }
}
