import XCTest
import simd
@testable import RemoteAssist

final class ScanKeyframePolicyTests: XCTestCase {
  private let policy = ScanKeyframePolicy()

  private func sample(x: Float = 0, yaw: Float = 0, time: TimeInterval) -> ScanKeyframePolicy.Sample {
    var transform = simd_float4x4(simd_quatf(angle: yaw, axis: [0, 1, 0]))
    transform.columns.3 = [x, 0, 0, 1]
    return .init(transform: transform, time: time)
  }

  func testTheFirstSteadyFrameIsKept() {
    XCTAssertEqual(policy.judge(sample(time: 1), previous: nil, lastKept: nil, kept: 0), .keep)
  }

  func testStandingStillTakesNoMorePhotos() {
    let kept = sample(time: 1)
    let now = sample(x: 0.005, time: 2)
    XCTAssertEqual(policy.judge(now, previous: sample(x: 0.005, time: 1.98), lastKept: kept, kept: 1), .skip)
  }

  func testWalkingFarEnoughTakesAPhoto() {
    let kept = sample(time: 1)
    let now = sample(x: 0.05, time: 2)
    XCTAssertEqual(policy.judge(now, previous: sample(x: 0.049, time: 1.98), lastKept: kept, kept: 1), .keep)
  }

  func testTurningFarEnoughTakesAPhoto() {
    let kept = sample(time: 1)
    let now = sample(yaw: 0.2, time: 2)
    XCTAssertEqual(policy.judge(now, previous: sample(yaw: 0.199, time: 1.98), lastKept: kept, kept: 1), .keep)
  }

  func testPhotosAreSpacedInTime() {
    let kept = sample(time: 1)
    let now = sample(x: 0.05, time: 1.1)
    XCTAssertEqual(policy.judge(now, previous: sample(x: 0.049, time: 1.08), lastKept: kept, kept: 1), .skip)
  }

  func testMovingFastSkipsTheFrame() {
    // 2 cm in one 60 fps frame is 1.2 m/s.
    let previous = sample(x: 0.10, time: 1)
    let now = sample(x: 0.12, time: 1 + 1.0 / 60)
    XCTAssertEqual(policy.judge(now, previous: previous, lastKept: sample(time: 0), kept: 1), .tooFast)
  }

  func testTurningFastSkipsTheFrame() {
    let previous = sample(yaw: 0, time: 1)
    let now = sample(yaw: 0.05, time: 1 + 1.0 / 60)
    XCTAssertEqual(policy.judge(now, previous: previous, lastKept: sample(time: 0), kept: 1), .tooFast)
  }

  func testStopsAtTheCap() {
    XCTAssertEqual(policy.judge(sample(time: 1), previous: nil, lastKept: nil, kept: policy.maxPhotos), .full)
  }

  func testTurnIsTheAngleBetweenOrientations() {
    let turn = ScanKeyframePolicy.turn(sample(yaw: 0, time: 0), sample(yaw: 0.3, time: 0))
    XCTAssertEqual(turn, 0.3, accuracy: 1e-4)
  }
}
