import Foundation
import simd

/// What the phone can tell about the marker it's following: how far it is, how big ARKit thinks the print really is,
/// and whether it's lying flat. Pure, for the debug line, the log and the "lay it flat" warning.
struct MarkerReading: Equatable {
  /// Camera to marker centre, metres.
  var distance: Float
  /// ARKit's estimate of the print's real width, metres (the configured width times its scale factor).
  var seenWidth: Float
  var scale: Float
  /// How much the marker's face points up: 1 lying flat face up, 0 standing on its edge, -1 face down.
  var flatness: Float

  /// Within about 35° of lying flat. The guide's positions assume the marker lies on the table beside the laptop: a
  /// marker standing up (on a screen, propped on something) turns every part up into the air in front of it.
  var isFlat: Bool { flatness > 0.82 }

  static func describe(transform: simd_float4x4, scale: Float, physicalWidth: Float, cameraPosition: SIMD3<Float>) -> MarkerReading {
    let centre = SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    let normal = simd_normalize(SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z))
    return MarkerReading(
      distance: simd_distance(centre, cameraPosition),
      seenWidth: physicalWidth * scale,
      scale: scale,
      flatness: simd_dot(normal, SIMD3(0, 1, 0))
    )
  }

  /// A measured point as the dashboard's Position (cm) fields want it: x, y, z in centimetres from the marker centre.
  static func positionText(_ point: SIMD3<Float>) -> String {
    String(format: "x %.1f · y %.1f · z %.1f cm", point.x * 100, point.y * 100, point.z * 100)
  }

  var line: String {
    let pose = isFlat ? "lying flat" : (flatness < -0.5 ? "face down" : "standing up")
    return String(format: "Marker %.0f cm away · seen %.1f cm wide (×%.2f) · %@", distance * 100, seenWidth * 100, scale, pose)
  }
}
