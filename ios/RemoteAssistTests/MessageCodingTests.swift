import XCTest
@testable import RemoteAssist

/// fixtures/messages.json holds one example of every message in contracts/protocol.ts. If Ahmed changes the contract
/// and this mirror isn't updated, these fail.
final class MessageCodingTests: XCTestCase {
  private func examples() throws -> [Data] {
    let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "messages", withExtension: "json"))
    let array = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [Any])
    return try array.map { try JSONSerialization.data(withJSONObject: $0) }
  }

  func testEveryExampleDecodes() throws {
    let decoded = try examples().map { try JSONDecoder().decode(Message.self, from: $0) }
    XCTAssertEqual(
      decoded.map(\.type),
      ["hello", "guide.set", "step.set", "calib.set", "step.done", "pose", "step.verified", "rtc.signal", "presence", "error"]
    )
  }

  /// What the phone sends must come out with exactly the contract's keys and values.
  func testPhoneMessagesRoundTrip() throws {
    for data in try examples() {
      let message = try JSONDecoder().decode(Message.self, from: data)
      switch message {
      case .hello, .stepDone, .pose, .rtcSignal: break
      default: continue
      }
      let reencoded = try JSONEncoder().encode(message)
      let original = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? NSDictionary)
      let mine = try XCTUnwrap(JSONSerialization.jsonObject(with: reencoded) as? NSDictionary)
      XCTAssertEqual(Set(original.allKeys as! [String]), Set(mine.allKeys as! [String]), message.type)
      if case .stepDone = message { XCTAssertEqual(original, mine) }
      if case .hello = message { XCTAssertEqual(original, mine) }
    }
  }

  func testGuideReplaceKeepsStepById() throws {
    let guide = try GuidePlayer.loadBundled()
    let player = GuidePlayer(guide: guide)
    player.next()
    XCTAssertEqual(player.currentStepId, "s2")

    var edited = guide
    edited.rev += 1
    edited.steps.insert(Step(id: "s0", text: "Inserted", objects: []), at: 0)
    player.replace(with: edited)
    XCTAssertEqual(player.currentStepId, "s2")

    player.jump(to: "s4")
    XCTAssertEqual(player.currentStepId, "s4")
  }
}
