import XCTest
import simd
@testable import RemoteAssist

final class VerifiedProcedureTests: XCTestCase {
  private func id(_ make: String, _ model: String) -> LaptopAssistant.Identification {
    .init(isLaptop: true, make: make, model: model, confidence: 0.9, ssdUserReplaceable: "yes", ssdFormFactor: "M.2 2280", warnings: [], tools: [])
  }

  /// The demo laptop gets the steps from the team's research (§ 17, Dell's manual), not a generated plan.
  func testDellLatitude5530UsesDellsSteps() throws {
    let procedure = try XCTUnwrap(VerifiedProcedures.match(id("Dell", "Latitude 5530")))
    XCTAssertTrue(procedure.captiveScrews)
    let text = procedure.steps.map { "\($0.title) \($0.detail)" }.joined(separator: " ")
    XCTAssertTrue(text.contains("Service Mode"))
    XCTAssertTrue(text.contains("8 screws"))
    XCTAssertTrue(text.contains("#0 Phillips"))
    XCTAssertEqual(procedure.steps.count, 12, "Laura's checked list (progress.md 02:11)")
    XCTAssertTrue(text.contains("one screw that holds the SSD"), "no bracket on the demo laptop")
    // Every remove group comes back on a refit step, so screw memory can pair them.
    let removed = Set(procedure.steps.filter { $0.phase == "remove" }.map(\.lookFor))
    let refitted = Set(procedure.steps.filter { $0.phase == "refit" }.map(\.lookFor))
    XCTAssertEqual(removed, refitted)
  }

  func testOtherLaptopsKeepTheAIPlan() {
    XCTAssertNil(VerifiedProcedures.match(id("Lenovo", "ThinkPad T14")))
    XCTAssertNil(VerifiedProcedures.match(id("Dell", "XPS 13")))
  }

  func testScrewMemoryBringsBackTheRightGroup() {
    var memory = ScrewMemory()
    func pin(_ n: Int) -> ARSessionController.PinInfo {
      .init(id: UUID(), number: n, label: "screw", kind: .ai, done: true, transform: matrix_identity_float4x4, photoPoint: nil)
    }
    memory.remember(pin(1), group: "cover", note: nil, photo: nil)
    memory.remember(pin(2), group: "cover", note: nil, photo: nil)
    memory.remember(pin(1), group: "ssd", note: "longer", photo: nil)
    XCTAssertEqual(memory.group(for: "cover"), "cover")
    XCTAssertEqual(memory.entries(in: "cover").count, 2)
    XCTAssertEqual(memory.group(for: "ssd"), "ssd")
    XCTAssertEqual(memory.group(for: "something else"), "ssd", "an unmatched refit step takes the latest group")
  }
}
