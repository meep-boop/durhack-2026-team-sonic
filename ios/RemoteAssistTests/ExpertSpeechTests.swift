import XCTest
@testable import RemoteAssist

/// The expert's voice moves the phone only on clear commands: a wrong jump mid-repair is worse than a missed one.
final class ExpertSpeechTests: XCTestCase {
  func testEachCommandIsHeard() {
    XCTAssertEqual(ExpertSpeech.command(in: "Next step."), .next)
    XCTAssertEqual(ExpertSpeech.command(in: "Go back"), .back)
    XCTAssertEqual(ExpertSpeech.command(in: "previous step"), .back)
    XCTAssertEqual(ExpertSpeech.command(in: "Look left"), .look(.left))
    XCTAssertEqual(ExpertSpeech.command(in: "Turn right."), .look(.right))
    XCTAssertEqual(ExpertSpeech.command(in: "look up"), .look(.up))
    XCTAssertEqual(ExpertSpeech.command(in: "Look down!"), .look(.down))
    XCTAssertEqual(ExpertSpeech.command(in: "Clear the marks"), .clear)
    XCTAssertEqual(ExpertSpeech.command(in: "clear that"), .clear)
  }

  func testFillerAroundACommandIsFine() {
    XCTAssertEqual(ExpertSpeech.command(in: "Okay, next step."), .next)
    XCTAssertEqual(ExpertSpeech.command(in: "Let's go to the next step"), .next)
    XCTAssertEqual(ExpertSpeech.command(in: "Now look left, please"), .look(.left))
    XCTAssertEqual(ExpertSpeech.command(in: "Can you turn left a bit"), .look(.left))
    XCTAssertEqual(ExpertSpeech.command(in: "OK so go back"), .back)
  }

  func testAPhraseInsideASentenceIsTalkNotACommand() {
    XCTAssertNil(ExpertSpeech.command(in: "I'll go back to that later"))
    XCTAssertNil(ExpertSpeech.command(in: "The next step is to remove the screws"))
    XCTAssertNil(ExpertSpeech.command(in: "Look down at the keyboard"))
    XCTAssertNil(ExpertSpeech.command(in: "That looks right to me"))
    XCTAssertNil(ExpertSpeech.command(in: ""))
  }

  func testEveryDirectionHasWordsAndAnArrow() {
    for direction in ExpertSpeech.Direction.allCases {
      let cue = ExpertSpeech.cue(for: direction)
      XCTAssertTrue(cue.words.lowercased().contains(direction.rawValue))
      XCTAssertTrue(cue.symbol.hasSuffix(direction.rawValue))
    }
  }

  func testTheConsolesTurnActionsBecomeTheRightWayToTurn() {
    XCTAssertEqual(CallManager.ExpertTap.turn(forAction: "unscrew"), true, "unscrewing turns anticlockwise")
    XCTAssertEqual(CallManager.ExpertTap.turn(forAction: "screw-in"), false)
    XCTAssertNil(CallManager.ExpertTap.turn(forAction: nil))
    XCTAssertNil(CallManager.ExpertTap.turn(forAction: "twist"))
    XCTAssertNil(CallManager.ExpertTap.turn(forAction: 3))
  }
}
