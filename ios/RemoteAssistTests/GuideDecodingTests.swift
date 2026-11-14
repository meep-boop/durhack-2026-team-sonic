import XCTest
@testable import RemoteAssist

final class GuideDecodingTests: XCTestCase {
  func testSampleGuideDecodes() throws {
    let guide = try GuidePlayer.loadBundled()
    XCTAssertEqual(guide.id, "sample-cable-move")
    XCTAssertEqual(guide.marker.width, 0.16, accuracy: 0.0001)
    XCTAssertEqual(guide.steps.map(\.id), ["s1", "s2", "s3", "s4"])

    let plug = try XCTUnwrap(guide.steps.last?.objects.first)
    XCTAssertEqual(plug.model, .cablePlug)
    XCTAssertEqual(plug.action, .push)
    XCTAssertEqual(plug.pos, Vec3(0.075, 0.012, 0.11))
  }

  func testPlayerWalksStepsById() throws {
    let player = GuidePlayer(guide: try GuidePlayer.loadBundled())
    var seen: [String] = []
    while let step = player.currentStep {
      seen.append(step.id)
      player.next()
    }
    XCTAssertEqual(seen, ["s1", "s2", "s3", "s4"])
    XCTAssertTrue(player.isFinished)

    player.restart()
    XCTAssertEqual(player.currentStepId, "s1")
  }
}
