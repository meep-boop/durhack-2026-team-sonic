import CoreGraphics
import simd

/// Where the camera was and how it saw, for one frame. Kept so the expert's tap on a video frame that left the phone a
/// moment ago is turned into a 3D ray through the camera that filmed it, not through wherever the phone points now.
struct CameraContext: Equatable {
  var transform: simd_float4x4
  var intrinsics: simd_float3x3
  /// The sensor image size in pixels, landscape (ARKit's capturedImage).
  var imageResolution: CGSize
  var timestamp: Double
}

/// A point in the upright (portrait) photo, as fractions of its width and height from the top-left.
typealias UprightPoint = CGPoint

enum PinMath {
  /// The video sent to the expert is the sensor image turned upright for a phone held in portrait (`CIImage.oriented(.right)`): the sensor's row 0 ends up on the right, its column 0 at the top.
  static func sensorPixel(for point: UprightPoint, resolution: CGSize) -> CGPoint {
    CGPoint(x: point.y * resolution.width, y: (1 - point.x) * resolution.height)
  }

  /// The inverse of `sensorPixel`.
  static func uprightPoint(forSensorPixel pixel: CGPoint, resolution: CGSize) -> UprightPoint {
    CGPoint(x: 1 - pixel.y / resolution.height, y: pixel.x / resolution.width)
  }

  /// A world-space ray from the camera through the point. ARKit's camera looks down -Z with +Y up, while image rows
  /// grow downwards, hence the minus on y.
  static func ray(for point: UprightPoint, in camera: CameraContext) -> (origin: SIMD3<Float>, direction: SIMD3<Float>) {
    let pixel = sensorPixel(for: point, resolution: camera.imageResolution)
    let k = camera.intrinsics
    let fx = k.columns.0.x, fy = k.columns.1.y, cx = k.columns.2.x, cy = k.columns.2.y
    let local = SIMD4<Float>((Float(pixel.x) - cx) / fx, -(Float(pixel.y) - cy) / fy, -1, 0)
    let world = camera.transform * local
    let origin = SIMD3(camera.transform.columns.3.x, camera.transform.columns.3.y, camera.transform.columns.3.z)
    return (origin, simd_normalize(SIMD3(world.x, world.y, world.z)))
  }

  /// Where a ray meets an infinite plane, if it does in front of the camera.
  static func intersect(
    origin: SIMD3<Float>, direction: SIMD3<Float>, planePoint: SIMD3<Float>, planeNormal: SIMD3<Float>
  ) -> SIMD3<Float>? {
    let denominator = simd_dot(direction, planeNormal)
    guard abs(denominator) > 1e-5 else { return nil }
    let t = simd_dot(planePoint - origin, planeNormal) / denominator
    guard t > 0.02, t < 5 else { return nil }
    return origin + direction * t
  }

  /// A transform at `position` whose +Y is `normal`, so a pin or tool stands straight up off the surface.
  static func standing(at position: SIMD3<Float>, normal: SIMD3<Float>) -> simd_float4x4 {
    let up = simd_normalize(normal)
    let rotation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: up)
    var matrix = simd_float4x4(rotation)
    matrix.columns.3 = SIMD4(position.x, position.y, position.z, 1)
    return matrix
  }
}
