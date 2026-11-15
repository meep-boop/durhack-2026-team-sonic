import XCTest
import simd
@testable import RemoteAssist

final class VerifiedProcedureTests: XCTestCase {
  /// The laptop guide is the team's research (§ 17, Dell's manual, checked on the laptop by Laura).
  func testDellLatitude5530UsesDellsSteps() throws {
    let procedure = VerifiedProcedures.latitude5530
    XCTAssertTrue(procedure.captiveScrews)
    let text = procedure.steps.map { "\($0.title) \($0.detail)" }.joined(separator: " ")
    XCTAssertTrue(text.contains("Service Mode"))
    XCTAssertTrue(text.contains("8 screws"))
    XCTAssertTrue(text.contains("#0 Phillips"))
    XCTAssertEqual(procedure.steps.count, 12, "Laura's checked list (progress.md 02:11)")
    XCTAssertTrue(text.contains("one screw that holds it"), "no bracket on the demo laptop")
    XCTAssertTrue(text.contains("next to the fan"), "where Laura found the SSD")
    // Every remove group comes back on a refit step, so screw memory can pair them.
    let removed = Set(procedure.steps.filter { $0.phase == "remove" }.map(\.lookFor))
    let refitted = Set(procedure.steps.filter { $0.phase == "refit" }.map(\.lookFor))
    XCTAssertEqual(removed, refitted)
  }

  func testScrewMemoryBringsBackTheRightGroup() {
    var memory = ScrewMemory()
    func pin(_ n: Int) -> ARSessionController.PinInfo {
      .init(id: UUID(), number: n, label: "screw", kind: .expert, done: true, transform: matrix_identity_float4x4, photoPoint: nil)
    }
    memory.remember(pin(1), group: "cover", note: nil, photo: nil)
    memory.remember(pin(2), group: "cover", note: nil, photo: nil)
    memory.remember(pin(1), group: "ssd", note: "longer", photo: nil)
    XCTAssertEqual(memory.group(for: "cover"), "cover")
    XCTAssertEqual(memory.entries(in: "cover").count, 2)
    XCTAssertEqual(memory.group(for: "ssd"), "ssd")
    XCTAssertEqual(memory.group(for: "something else"), "ssd", "an unmatched refit step takes the latest group")
  }

  /// The laptop guide's steps line up with the player's, so phase and part lookups hit the right step.
  func testLaptopGuideMatchesItsProcedure() {
    let laptop = LaptopGuide()
    let guide = laptop.guide()
    XCTAssertEqual(guide.id, LaptopGuide.guideId)
    XCTAssertEqual(guide.steps.count, laptop.steps.count)
    XCTAssertEqual(laptop.phase(stepIndex: 3), "remove")
    XCTAssertEqual(laptop.lookFor(stepIndex: 3), laptop.lookFor(stepIndex: 10))
    XCTAssertFalse(laptop.allSafe)
    LaptopGuide.safetyItems.forEach { laptop.safetyChecked.insert($0.id) }
    XCTAssertTrue(laptop.allSafe)
  }
}
