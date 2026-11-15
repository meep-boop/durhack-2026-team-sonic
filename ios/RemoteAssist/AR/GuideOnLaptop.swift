import simd

/// Puts an expert's guide on the real laptop instead of beside the marker. A guide's positions are in the marker's
/// frame, laid out for a laptop centred among its parts with its long side along the marker's +X; until the scans are
/// calibrated nobody knows where that laptop really is relative to the marker. Once the user locks the laptop (two
/// corner taps), the guide's frame is moved so that centre sits on the laptop's centre and +X runs along its top
/// edge: every part lands on the laptop, in the guide's own layout.
enum GuideOnLaptop {
  /// The centre (x, z) of every part in every step, in the marker's frame: where the guide's laptop sits.
  static func centre(of guide: Guide) -> SIMD2<Float> {
    let points = guide.steps.flatMap(\.objects).map(\.pos.simd)
    guard let first = points.first else { return .zero }
    var low = SIMD2(first.x, first.z), high = low
    for p in points {
      low = simd_min(low, SIMD2(p.x, p.z))
      high = simd_max(high, SIMD2(p.x, p.z))
    }
    return (low + high) / 2
  }

  /// The world transform for the guide's frame. +X runs along the laptop's top edge, +Y out of its cover, and +Z is
  /// their cross product, so it's always a proper rotation (never mirrored, whatever way the corners were tapped).
  static func transform(frame: LaptopFrame, guideCentre: SIMD2<Float>) -> simd_float4x4 {
    let x = simd_normalize(frame.xAxis)
    let y = simd_normalize(frame.normal)
    let z = simd_normalize(simd_cross(x, y))
    let laptopCentre = frame.origin + frame.xAxis * frame.size.x / 2 + frame.yAxis * frame.size.y / 2
    let translation = laptopCentre - x * guideCentre.x - z * guideCentre.y
    return simd_float4x4(
      SIMD4(x, 0), SIMD4(y, 0), SIMD4(z, 0), SIMD4(translation, 1)
    )
  }
}
