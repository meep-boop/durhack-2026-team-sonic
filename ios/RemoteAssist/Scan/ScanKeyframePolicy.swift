import Foundation
import simd

/// Which camera frames become scan photos: one each time the phone has moved or turned enough, none while it moves so
/// fast the photo smears, and no more than a training run can use.
struct ScanKeyframePolicy {
  struct Sample: Equatable {
    var transform: simd_float4x4
    var time: TimeInterval
  }

  enum Verdict: Equatable { case keep, skip, tooFast, full }

  var minTravel: Float = 0.04
  /// About 8°.
  var minTurn: Float = 0.14
  var minInterval: TimeInterval = 0.2
  /// Starting guesses for where a 1920×1440 frame starts to smear, not measured: tune them on the first real scan.
  var maxSpeed: Float = 0.4
  var maxTurnRate: Float = 0.8
  var maxPhotos = 400

  /// `previous` is the frame just before this one (for speed); `lastKept` is the last photo taken (for spacing).
  func judge(_ sample: Sample, previous: Sample?, lastKept: Sample?, kept: Int) -> Verdict {
    guard kept < maxPhotos else { return .full }
    if let previous, sample.time > previous.time {
      let dt = Float(sample.time - previous.time)
      if Self.travel(previous, sample) / dt > maxSpeed || Self.turn(previous, sample) / dt > maxTurnRate {
        return .tooFast
      }
    }
    guard let lastKept else { return .keep }
    guard sample.time - lastKept.time >= minInterval else { return .skip }
    return Self.travel(lastKept, sample) >= minTravel || Self.turn(lastKept, sample) >= minTurn ? .keep : .skip
  }

  static func travel(_ a: Sample, _ b: Sample) -> Float {
    simd_distance(position(a.transform), position(b.transform))
  }

  /// The angle between the two camera orientations, in radians.
  static func turn(_ a: Sample, _ b: Sample) -> Float {
    let alignment = abs(simd_dot(simd_quatf(a.transform).vector, simd_quatf(b.transform).vector))
    return 2 * acos(min(1, alignment))
  }

  private static func position(_ m: simd_float4x4) -> SIMD3<Float> {
    SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
  }
}
