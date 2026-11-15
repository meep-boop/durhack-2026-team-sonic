import Foundation
import Observation

/// Walks the guide one step at a time. Steps are tracked by id, as the contract asks, so later guide edits
/// (task 6) can't shift which step is current.
@Observable
final class GuidePlayer {
  private(set) var guide: Guide { didSet { save() } }
  private(set) var currentStepId: String? { didSet { save() } }
  /// Steps the user has tapped Done on, by id. The relay no longer replays step.set to phones, so the phone owns
  /// its own place and progress across reconnects and guide edits.
  private(set) var doneStepIds: Set<String> = [] { didSet { save() } }
  /// Phone clock, ms since the epoch, when each step was tapped done. For the repair report.
  private(set) var doneAt: [String: Int64] = [:]
  private(set) var startedAt = Date()
  /// Set by the app (not tests) to keep the player's state in Application Support across launches.
  @ObservationIgnored var persistenceName: String? { didSet { save() } }

  init(guide: Guide) {
    self.guide = guide
    currentStepId = guide.steps.first?.id
  }

  var currentIndex: Int? { guide.steps.firstIndex { $0.id == currentStepId } }
  var currentStep: Step? { currentIndex.map { guide.steps[$0] } }
  var isFinished: Bool { currentStepId == nil }

  func next() {
    guard let index = currentIndex else { return }
    doneAt[guide.steps[index].id] = Int64(Date().timeIntervalSince1970 * 1000)
    doneStepIds.insert(guide.steps[index].id)
    let nextIndex = index + 1
    currentStepId = nextIndex < guide.steps.count ? guide.steps[nextIndex].id : nil
  }

  func back() {
    guard let index = currentIndex, index > 0 else { return }
    currentStepId = guide.steps[index - 1].id
  }

  func restart() {
    currentStepId = guide.steps.first?.id
    doneStepIds = []
    doneAt = [:]
    startedAt = Date()
  }

  /// `guide.set` always carries the whole guide, and the relay replays it on every reconnect.
  /// - Same guide: stay where we are, by id (an inserted step doesn't move us). A guide finished offline stays
  ///   finished, unless the edit added a step that isn't done yet, which we then go to.
  /// - A different guide starts from its first step.
  func replace(with newGuide: Guide) {
    guard newGuide.id == guide.id else {
      guide = newGuide
      currentStepId = newGuide.steps.first?.id
      doneStepIds = []
      doneAt = [:]
      startedAt = Date()
      return
    }
    guide = newGuide
    let ids = Set(newGuide.steps.map(\.id))
    doneStepIds.formIntersection(ids)
    if let currentStepId, ids.contains(currentStepId) { return }
    if currentStepId == nil {
      self.currentStepId = newGuide.steps.first { !doneStepIds.contains($0.id) }?.id
    } else {
      // The current step was deleted: go to the first step not yet done.
      self.currentStepId = newGuide.steps.first { !doneStepIds.contains($0.id) }?.id ?? newGuide.steps.first?.id
    }
  }

  func jump(to stepId: String) {
    guard guide.steps.contains(where: { $0.id == stepId }) else { return }
    currentStepId = stepId
  }

  // MARK: Persistence

  private struct Saved: Codable {
    var guide: Guide
    var currentStepId: String?
    var doneStepIds: Set<String>
    var doneAt: [String: Int64]
    var startedAt: Date
  }

  /// The player as it was when the app last ran, if it saved one.
  static func restored(from name: String) -> GuidePlayer? {
    guard let saved = Persistence.load(Saved.self, from: name) else { return nil }
    let player = GuidePlayer(guide: saved.guide)
    player.currentStepId = saved.currentStepId
    player.doneStepIds = saved.doneStepIds
    player.doneAt = saved.doneAt
    player.startedAt = saved.startedAt
    player.persistenceName = name
    return player
  }

  private func save() {
    guard let persistenceName else { return }
    Persistence.save(
      Saved(guide: guide, currentStepId: currentStepId, doneStepIds: doneStepIds, doneAt: doneAt, startedAt: startedAt),
      as: persistenceName
    )
  }

  static func loadBundled(named name: String = "sample-guide", bundle: Bundle = .main) throws -> Guide {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
      throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
    }
    return try JSONDecoder().decode(Guide.self, from: Data(contentsOf: url))
  }
}
