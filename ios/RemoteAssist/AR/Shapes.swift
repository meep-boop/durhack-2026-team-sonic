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
      materials: [UnlitMaterial(color: UIColor.systemYellow.withAlphaComponent(0.18))]
    )
    root.addChild(fill)

    let h = size / 2
    let corners: [SIMD3<Float>] = [
      [-h.x, -h.y, -h.z], [h.x, -h.y, -h.z], [h.x, -h.y, h.z], [-h.x, -h.y, h.z],
      [-h.x, h.y, -h.z], [h.x, h.y, -h.z], [h.x, h.y, h.z], [-h.x, h.y, h.z],
    ]
    let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4), (0, 4), (1, 5), (2, 6), (3, 7)]
    for (a, b) in edges {
      root.addChild(bar(from: corners[a], to: corners[b], thickness: 0.0012, color: .systemYellow))
    }
    return root
  }

  /// Stand-ins until @laura's USDZ models land in assets/models/.
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
    }
  }

  static func label(_ text: String) -> Entity {
    let mesh = MeshResource.generateText(text, extrusionDepth: 0.0005, font: .systemFont(ofSize: 0.012, weight: .semibold))
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
