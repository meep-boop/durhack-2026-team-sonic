import XCTest
import simd
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

  func testAnUnscrewIsTwoTurnsRising15mmIn1point6s() {
    let steps = Shapes.unscrewSteps()
    XCTAssertEqual(steps.count, 8, "quarter turns, so no step can go the wrong way round")
    XCTAssertEqual(steps.map(\.duration).reduce(0, +), 1.6, accuracy: 1e-9)
    XCTAssertEqual(steps.map(\.rise).reduce(0, +), 0.015, accuracy: 1e-6)
    XCTAssertEqual(steps.map(\.angle).reduce(0, +), 4 * .pi, accuracy: 1e-5)
  }

  func testAMarkerLyingFlatIsReadAsFlatAndSizedFromTheEstimate() {
    var flat = matrix_identity_float4x4
    flat.columns.3 = SIMD4(0, 0, -0.5, 1)
    let reading = MarkerReading.describe(transform: flat, scale: 1.1, physicalWidth: 0.18, cameraPosition: .zero)
    XCTAssertTrue(reading.isFlat)
    XCTAssertEqual(reading.distance, 0.5, accuracy: 1e-5)
    XCTAssertEqual(reading.seenWidth, 0.198, accuracy: 1e-5)
  }

  func testAMarkerStandingUpOnAScreenIsNotFlat() {
    // Rotated 90° about X: its face (+Y) now points along the floor, towards the viewer.
    let upright = simd_float4x4(simd_quatf(angle: .pi / 2, axis: [1, 0, 0]))
    let reading = MarkerReading.describe(transform: upright, scale: 1, physicalWidth: 0.18, cameraPosition: [0, 0, 1])
    XCTAssertFalse(reading.isFlat)
    XCTAssertTrue(reading.line.contains("standing up"))
  }

  func testAMeasuredPointReadsInTheDashboardsCentimetres() {
    XCTAssertEqual(MarkerReading.positionText([0.312, 0.012, -0.098]), "x 31.2 · y 1.2 · z -9.8 cm")
  }
}
