import XCTest
@testable import RemoteAssist

final class GuideDecodingTests: XCTestCase {
  func testSampleGuideDecodes() throws {
    let guide = try GuidePlayer.loadBundled()
    XCTAssertEqual(guide.id, "sample-ssd-swap")
    XCTAssertEqual(guide.marker.width, 0.18, accuracy: 0.0001)
    XCTAssertEqual(guide.marker.width, MarkerSpec.widthMeters, accuracy: 0.0001)
    XCTAssertEqual(guide.steps.map(\.id), ["s1", "s2", "s3", "s4"])

    let fitted = try XCTUnwrap(guide.steps.last?.objects.first)
    XCTAssertEqual(fitted.model, .hand)
    XCTAssertEqual(fitted.expect, Expect(region: "ssd-bay", present: true))
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

  /// An `expect` in a shape this build doesn't know is dropped, and the rest of the object still decodes.
  func testOddExpectDoesNotSinkTheObject() throws {
    let json = #"{"id":"o1","model":"screw","pos":[0,0,0],"rot":[0,0,0,1],"size":[0.01,0.01,0.01],"action":null,"axis":[0,1,0],"expect":{"port":"usb","cable":"in"}}"#
    let object = try JSONDecoder().decode(GuideObject.self, from: Data(json.utf8))
    XCTAssertEqual(object.model, .screw)
    XCTAssertNil(object.expect)
  }
}
