import XCTest
@testable import RemoteAssist

/// The live camera must never freeze or go black: the feed covers the AR view the moment it stops drawing, stays until
/// it draws steadily again, and the camera itself is re-run while it's silent.
final class CameraPresentPolicyTests: XCTestCase {
  /// Started at 100 s, camera and AR view both healthy at 110 s, feed hidden.
  private func healthy(at now: TimeInterval = 110) -> CameraPresentPolicy.Input {
    .init(
      now: now, startedAt: 100, lastFrameAt: now - 0.016, lastPresentAt: now - 0.016, steadySince: 101,
      feedShown: false, feedShownAt: 0, lastReplaceAt: 0, replacements: 0, lastRerunAt: 0
    )
  }

  func testAHealthyViewKeepsTheFeedHidden() {
    XCTAssertEqual(CameraPresentPolicy.decide(healthy()), .init(showFeed: false))
  }

  func testTheFeedCoversAViewThatStopsDrawingWithinAQuarterSecond() {
    var s = healthy()
    s.lastPresentAt = s.now - 0.2
    XCTAssertFalse(CameraPresentPolicy.decide(s).showFeed, "a couple of dropped frames is not a freeze")
    s.lastPresentAt = s.now - 0.3
    XCTAssertTrue(CameraPresentPolicy.decide(s).showFeed)
  }

  func testAFreshStartIsCoveredUntilTheViewHasDrawn() {
    var s = healthy()
    s.startedAt = s.now - 0.5
    s.lastPresentAt = s.startedAt - 0.01  // drawn by the old view, before the restart
    XCTAssertTrue(CameraPresentPolicy.decide(s).showFeed, "launch, resume and a replacement must never show black")
  }

  func testTheFeedStaysUntilTheViewDrawsSteadilyForASecond() {
    var s = healthy()
    s.feedShown = true
    s.feedShownAt = s.now - 1.5
    s.steadySince = s.now - 0.5
    XCTAssertTrue(CameraPresentPolicy.decide(s).showFeed, "drawing again, but not for long enough yet")
    s.steadySince = s.now - 1.1
    XCTAssertFalse(CameraPresentPolicy.decide(s).showFeed)
  }

  func testAStrugglingViewDoesNotFlipBackAndForth() {
    // 17 frames a second reach the screen: each gap breaks the steady run, so it never counts as steady.
    var s = healthy()
    s.feedShown = true
    s.feedShownAt = s.now - 1
    s.lastPresentAt = s.now - 0.03
    s.steadySince = s.lastPresentAt
    XCTAssertTrue(CameraPresentPolicy.decide(s).showFeed)
  }

  func testSteadinessFromBeforeARestartDoesNotCount() {
    var s = healthy()
    s.feedShown = true
    s.startedAt = s.now - 0.4
    s.steadySince = s.now - 5
    XCTAssertTrue(CameraPresentPolicy.decide(s).showFeed)
  }

  func testAFreshViewIsBuiltUnderTheFeedAfterTwoSecondsThenLessOften() {
    var s = healthy()
    s.lastPresentAt = s.now - 3
    s.feedShown = true
    s.feedShownAt = s.now - 1.9
    XCTAssertFalse(CameraPresentPolicy.decide(s).replaceView)
    s.feedShownAt = s.now - 2.1
    XCTAssertTrue(CameraPresentPolicy.decide(s).replaceView)

    s.replacements = 1
    s.lastReplaceAt = s.now - 4
    XCTAssertFalse(CameraPresentPolicy.decide(s).replaceView, "the second try waits 5 s")
    s.lastReplaceAt = s.now - 5
    XCTAssertTrue(CameraPresentPolicy.decide(s).replaceView)

    XCTAssertEqual(CameraPresentPolicy.replaceInterval(after: 2), 10)
    XCTAssertEqual(CameraPresentPolicy.replaceInterval(after: 3), 20)
    XCTAssertEqual(CameraPresentPolicy.replaceInterval(after: 9), 30)
  }

  func testAViewIsNeverReplacedWhileItDraws() {
    var s = healthy()
    s.feedShown = true
    s.feedShownAt = s.now - 10
    s.steadySince = s.now - 0.2
    XCTAssertFalse(CameraPresentPolicy.decide(s).replaceView)
  }

  func testASilentCameraIsReRunEveryThreeSecondsBehindTheLastPicture() {
    var s = healthy()
    s.lastFrameAt = s.now - 2.5
    s.lastPresentAt = s.now - 2.5
    let first = CameraPresentPolicy.decide(s)
    XCTAssertTrue(first.cameraSilent)
    XCTAssertTrue(first.showFeed)
    XCTAssertTrue(first.rerunSession)
    XCTAssertFalse(first.replaceView, "a new AR view can't fix a camera that sends nothing")

    s.lastRerunAt = s.now - 2
    XCTAssertFalse(CameraPresentPolicy.decide(s).rerunSession)
    s.lastRerunAt = s.now - 3
    XCTAssertTrue(CameraPresentPolicy.decide(s).rerunSession)
  }

  func testSilenceIsMeasuredFromTheLastRestart() {
    var s = healthy()
    s.lastFrameAt = s.now - 5
    s.startedAt = s.now - 1
    XCTAssertFalse(CameraPresentPolicy.decide(s).cameraSilent, "a re-run session gets 2 s to send its first frame")
  }
}
