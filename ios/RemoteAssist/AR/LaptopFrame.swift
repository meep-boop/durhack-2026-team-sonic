import CoreGraphics
import simd

/// The laptop's own coordinate frame on the table, from two tapped corners. Positions in a layout are millimetres
/// from the top-left corner (x along the top edge, the one with the U-shaped notches; y down the cover), so once the
/// frame is known every screw lands where it really is, with no marker.
struct LaptopFrame: Equatable {
  /// The top-left corner, in world space.
  var origin: SIMD3<Float>
  /// Unit vector along the top edge.
  var xAxis: SIMD3<Float>
  /// Unit vector down the cover, from the top edge towards the bottom.
  var yAxis: SIMD3<Float>
  /// Up, out of the cover.
  var normal: SIMD3<Float>
  /// The laptop's footprint, metres.
  var size: SIMD2<Float>

  enum Problem: Error, Equatable {
    case tooClose, tooFar, sameSpot
  }

  /// From the top-left corner A and the opposite corner C on the surface, the surface normal, and the laptop's real
  /// footprint (metres). Two diagonals give two mirror-image rectangles; `screenRight` (the world direction that is
  /// "right" on the phone's screen) picks the one where the top edge runs left to right, as the user sees it.
  /// The tapped diagonal must be within 15 % of the real one, or the taps missed the corners.
  static func make(
    a: SIMD3<Float>, c: SIMD3<Float>, normal: SIMD3<Float>, footprint: SIMD2<Float>, screenRight: SIMD3<Float>
  ) -> Result<LaptopFrame, Problem> {
    let up = simd_normalize(normal)
    var diagonal = c - a
    diagonal -= simd_dot(diagonal, up) * up
    let length = simd_length(diagonal)
    guard length > 0.01 else { return .failure(.sameSpot) }
    let expected = simd_length(footprint)
    if length < expected * 0.85 { return .failure(.tooClose) }
    if length > expected * 1.15 { return .failure(.tooFar) }

    let direction = diagonal / length
    let angle = atan2(footprint.y, footprint.x)
    // Rodrigues' rotation about `up`; `direction` lies in the plane, so the dot term vanishes.
    func rotated(_ theta: Float) -> SIMD3<Float> {
      simd_normalize(direction * cos(theta) + simd_cross(up, direction) * sin(theta))
    }
    let candidates = [rotated(angle), rotated(-angle)]
    let xAxis = candidates.max { simd_dot($0, screenRight) < simd_dot($1, screenRight) }!
    // Down the cover: whatever of the diagonal isn't along the top edge.
    let yAxis = simd_normalize(direction - simd_dot(direction, xAxis) * xAxis)
    return .success(LaptopFrame(origin: a, xAxis: xAxis, yAxis: yAxis, normal: up, size: footprint))
  }

  /// A layout position (millimetres from the top-left corner) in world space.
  func world(mm: CGPoint) -> SIMD3<Float> {
    origin + xAxis * Float(mm.x / 1000) + yAxis * Float(mm.y / 1000)
  }

  /// A world point as a layout position, for teaching where a part is.
  func mm(of point: SIMD3<Float>) -> CGPoint {
    let offset = point - origin
    return CGPoint(x: Double(simd_dot(offset, xAxis) * 1000), y: Double(simd_dot(offset, yAxis) * 1000))
  }

  /// A pin or tool standing on the cover at a layout position.
  func transform(mm: CGPoint) -> simd_float4x4 {
    PinMath.standing(at: world(mm: mm), normal: normal)
  }

  /// The four corners, clockwise from top-left, in world space.
  var corners: [SIMD3<Float>] {
    let w = size.x * 1000, h = size.y * 1000
    return [CGPoint(x: 0, y: 0), CGPoint(x: CGFloat(w), y: 0), CGPoint(x: CGFloat(w), y: CGFloat(h)), CGPoint(x: 0, y: CGFloat(h))]
      .map { world(mm: $0) }
  }
}
