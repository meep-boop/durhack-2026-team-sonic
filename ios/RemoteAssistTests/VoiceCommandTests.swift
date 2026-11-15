import XCTest
@testable import RemoteAssist

final class VoiceCommandTests: XCTestCase {
  func testPhrasesMapToCommands() {
    XCTAssertEqual(VoiceCommands.match("okay next")?.1, .next)
    XCTAssertEqual(VoiceCommands.match("Done.")?.1, .next)
    XCTAssertEqual(VoiceCommands.match("show me where")?.1, .showMe)
    XCTAssertEqual(VoiceCommands.match("show me")?.1, .showMe)
    XCTAssertEqual(VoiceCommands.match("go back")?.1, .back)
    XCTAssertEqual(VoiceCommands.match("please call the expert")?.1, .callExpert)
    XCTAssertEqual(VoiceCommands.match("say again")?.1, .repeatStep)
  }

  /// Whole words only: "nextdoor" or "backpack" must not move the guide.
  func testWordsInsideOtherWordsDontCount() {
    XCTAssertNil(VoiceCommands.match("backpack"))
    XCTAssertNil(VoiceCommands.match("showroom backpack"))
    XCTAssertNil(VoiceCommands.match("unscrew the panel"))
  }
}
