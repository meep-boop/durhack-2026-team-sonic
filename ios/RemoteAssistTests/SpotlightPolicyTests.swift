import XCTest
@testable import RemoteAssist

/// The spotlight must go quiet when nothing moves: a beam that redrew every tick starved the GPU and main thread.
final class SpotlightPolicyTests: XCTestCase {
  func testAStillTargetSettlesExactlyAndStopsChanging() {
    let target = CGRect(x: 100, y: 200, width: 180, height: 160)
    var rect = CGRect(x: 40, y: 120, width: 220, height: 220)
    var steps = 0
    while rect != target, steps < 60 {
      rect = SpotlightPolicy.ease(from: rect, to: target)
      steps += 1
    }
    XCTAssertEqual(rect, target, "easing must land exactly, or it redraws forever")
    XCTAssertLessThan(steps, 30)
    XCTAssertFalse(SpotlightPolicy.moved(SpotlightPolicy.ease(from: rect, to: target), rect))
  }

  func testTinyJitterIsNotWorthARedraw() {
    let a = CGRect(x: 100, y: 100, width: 150, height: 150)
    XCTAssertFalse(SpotlightPolicy.moved(a, a.offsetBy(dx: 0.6, dy: -0.4)))
    XCTAssertTrue(SpotlightPolicy.moved(a, a.offsetBy(dx: 3, dy: 0)))
  }

  func testBeamDoesNotFlickerAtTheScreenEdge() {
    let bounds = CGRect(x: 0, y: 0, width: 400, height: 800)
    let atEdge = CGPoint(x: 405, y: 400)  // just off the right edge
    XCTAssertTrue(SpotlightPolicy.onScreen(centre: atEdge, bounds: bounds, wasBeam: true), "a showing beam holds on")
    XCTAssertFalse(SpotlightPolicy.onScreen(centre: atEdge, bounds: bounds, wasBeam: false), "a hidden one waits until well inside")
    XCTAssertTrue(SpotlightPolicy.onScreen(centre: CGPoint(x: 300, y: 400), bounds: bounds, wasBeam: false))
    XCTAssertFalse(SpotlightPolicy.onScreen(centre: CGPoint(x: 460, y: 400), bounds: bounds, wasBeam: true))
  }

  func testAnOffScreenTargetSaysWhichWayToMoveThePhone() {
    XCTAssertEqual(SpotlightPolicy.turn(for: CGVector(dx: -1, dy: 0.2)).words, "Turn left")
    XCTAssertEqual(SpotlightPolicy.turn(for: CGVector(dx: 0.9, dy: -0.3)).words, "Turn right")
    XCTAssertEqual(SpotlightPolicy.turn(for: CGVector(dx: 0.2, dy: -1)).words, "Look up")
    XCTAssertEqual(SpotlightPolicy.turn(for: CGVector(dx: -0.1, dy: 0.95)).words, "Look down")
    XCTAssertEqual(SpotlightPolicy.turn(for: CGVector(dx: 0.2, dy: -1)).symbol, "arrow.up")
  }
}
