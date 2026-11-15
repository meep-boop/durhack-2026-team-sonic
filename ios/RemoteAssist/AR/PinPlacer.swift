import CoreGraphics
import simd

/// Where the camera was and how it saw, for one frame. Kept so a point found in a photo seconds ago (by Gemini, or
/// by the expert tapping the video) is turned into a 3D ray through the camera that took that photo, not through
/// wherever the phone points now. Projecting through the current frame is why pins used to drift with the hand.
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
  /// The photo sent to Gemini and the video sent to the expert are the sensor image turned upright for a phone held
  /// in portrait (`CIImage.oriented(.right)`): the sensor's row 0 ends up on the right, its column 0 at the top.
  static func sensorPixel(for point: UprightPoint, resolution: CGSize) -> CGPoint {
    CGPoint(x: point.y * resolution.width, y: (1 - point.x) * resolution.height)
  }

  /// The inverse of `sensorPixel`, for tests and for mapping crops back.
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

  /// Gemini's native box is `[ymin, xmin, ymax, xmax]` on 0–1000. Returns upright fractions.
  static func rect(fromBox2D box: [Double]) -> CGRect? {
    guard box.count == 4 else { return nil }
    let ymin = box[0] / 1000, xmin = box[1] / 1000, ymax = box[2] / 1000, xmax = box[3] / 1000
    let rect = CGRect(x: min(xmin, xmax), y: min(ymin, ymax), width: abs(xmax - xmin), height: abs(ymax - ymin))
    let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
    let clipped = rect.intersection(unit)
    return clipped.isNull ? nil : clipped
  }

  /// A square crop around a small box, in pixels of an image of `imageSize`: 2.5× the box, at least `minSide`,
  /// kept inside the image. A screw is a few pixels in the whole photo; zoomed in, Gemini can find its centre.
  static func cropRect(around box: CGRect, imageSize: CGSize, minSide: CGFloat = 256) -> CGRect {
    let boxPixels = CGRect(
      x: box.minX * imageSize.width, y: box.minY * imageSize.height,
      width: box.width * imageSize.width, height: box.height * imageSize.height
    )
    let side = min(max(max(boxPixels.width, boxPixels.height) * 2.5, minSide), min(imageSize.width, imageSize.height)).rounded()
    // Whole pixels, and still square: `integral` would grow a fractional rect by a pixel on one side.
    let x = min(max(0, (boxPixels.midX - side / 2).rounded()), imageSize.width - side)
    let y = min(max(0, (boxPixels.midY - side / 2).rounded()), imageSize.height - side)
    return CGRect(x: x, y: y, width: side, height: side)
  }

  /// A point Gemini gave as `[y, x]` on 0–1000 inside `crop`, back to upright fractions of the whole image.
  static func point(fromCropPoint yx: [Double], crop: CGRect, imageSize: CGSize) -> UprightPoint? {
    guard yx.count == 2 else { return nil }
    let x = crop.minX + yx[1] / 1000 * crop.width
    let y = crop.minY + yx[0] / 1000 * crop.height
    return CGPoint(x: x / imageSize.width, y: y / imageSize.height)
  }
}
