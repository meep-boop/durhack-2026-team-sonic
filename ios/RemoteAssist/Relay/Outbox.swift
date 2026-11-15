import Foundation

/// Finished steps waiting for the relay's receipt. Ahmed's rule (relay `8756560`, `fixtures/fake-phone.ts` is the
/// reference): a tap leaves the queue only when the relay sends that same `step.done` back. A successful socket write
/// proves nothing: the link can die with the frame still in a buffer. Until the receipt arrives the tap is resent (on
/// reconnect, and if a receipt is overdue); the relay drops repeats by `doneId`, so resending is always safe.
struct Outbox: Equatable {
  private(set) var items: [StepDone] = []
  /// When each tap was last written to the socket; not saved, so after a relaunch everything counts as unsent.
  private var sentAt: [String: Date] = [:]

  init(items: [StepDone] = []) {
    self.items = items
  }

  var count: Int { items.count }

  mutating func enqueue(_ tap: StepDone) {
    guard !items.contains(where: { $0.doneId == tap.doneId }) else { return }
    items.append(tap)
  }

  /// The relay saved this tap. Returns whether it was ours and still queued.
  @discardableResult
  mutating func receipt(_ doneId: String) -> Bool {
    sentAt[doneId] = nil
    guard let index = items.firstIndex(where: { $0.doneId == doneId }) else { return false }
    items.remove(at: index)
    return true
  }

  /// The relay refused taps for a guide it doesn't have: they can never get a receipt, so waiting is pointless.
  mutating func drop(guideId: String) {
    items.removeAll { $0.guideId == guideId }
  }

  /// A new connection: nothing written to the old one can be trusted.
  mutating func forgetSends() {
    sentAt = [:]
  }

  /// The taps to write now, in tap order: never sent on this connection, or sent more than `resendAfter` ago with no
  /// receipt. Marks them sent at `now`.
  mutating func due(now: Date = Date(), resendAfter: TimeInterval = 4) -> [StepDone] {
    let due = items.filter { tap in sentAt[tap.doneId].map { now.timeIntervalSince($0) >= resendAfter } ?? true }
    for tap in due { sentAt[tap.doneId] = now }
    return due
  }
}
