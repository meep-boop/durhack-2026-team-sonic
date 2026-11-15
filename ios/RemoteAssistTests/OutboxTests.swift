import XCTest
@testable import RemoteAssist

/// Ahmed's receipt rule: a tap leaves the queue only when the relay sends it back.
final class OutboxTests: XCTestCase {
  private func tap(_ id: String) -> StepDone {
    StepDone(guideId: "g", rev: 1, stepId: "s-\(id)", doneId: id, at: 0)
  }

  func testWritingATapDoesNotRemoveIt() {
    var outbox = Outbox()
    outbox.enqueue(tap("a"))
    XCTAssertEqual(outbox.due().map(\.doneId), ["a"])
    XCTAssertEqual(outbox.count, 1, "a written tap stays until its receipt")
  }

  func testReceiptRemovesOnlyThatTap() {
    var outbox = Outbox()
    ["a", "b", "c"].forEach { outbox.enqueue(tap($0)) }
    XCTAssertTrue(outbox.receipt("b"))
    XCTAssertEqual(outbox.items.map(\.doneId), ["a", "c"])
    XCTAssertFalse(outbox.receipt("b"), "a repeat receipt is harmless")
    XCTAssertFalse(outbox.receipt("someone-else"))
  }

  func testDueIsInTapOrderAndNotRepeatedTooSoon() {
    var outbox = Outbox()
    let start = Date()
    ["a", "b"].forEach { outbox.enqueue(tap($0)) }
    XCTAssertEqual(outbox.due(now: start).map(\.doneId), ["a", "b"])
    XCTAssertEqual(outbox.due(now: start.addingTimeInterval(1)).count, 0)
    outbox.enqueue(tap("c"))
    XCTAssertEqual(outbox.due(now: start.addingTimeInterval(1)).map(\.doneId), ["c"])
  }

  func testOverdueTapsAreResent() {
    var outbox = Outbox()
    let start = Date()
    outbox.enqueue(tap("a"))
    _ = outbox.due(now: start)
    XCTAssertEqual(outbox.due(now: start.addingTimeInterval(4.1)).map(\.doneId), ["a"])
  }

  func testReconnectResendsTheWholeQueue() {
    var outbox = Outbox()
    let start = Date()
    ["a", "b"].forEach { outbox.enqueue(tap($0)) }
    _ = outbox.due(now: start)
    outbox.forgetSends()
    XCTAssertEqual(outbox.due(now: start.addingTimeInterval(0.5)).map(\.doneId), ["a", "b"])
  }

  func testTheSameTapIsQueuedOnce() {
    var outbox = Outbox()
    outbox.enqueue(tap("a"))
    outbox.enqueue(tap("a"))
    XCTAssertEqual(outbox.count, 1)
  }
}
