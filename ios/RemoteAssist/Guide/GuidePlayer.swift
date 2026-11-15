import Foundation
import Observation

/// Walks the guide one step at a time. Steps are tracked by id, as the contract asks, so later guide edits
/// (task 6) can't shift which step is current.
@Observable
final class GuidePlayer {
  private(set) var guide: Guide
  private(set) var currentStepId: String?
  /// Steps the user has tapped Done on, by id. The relay no longer replays step.set to phones, so the phone owns
  /// its own place and progress across reconnects and guide edits.
  private(set) var doneStepIds: Set<String> = []

  init(guide: Guide) {
    self.guide = guide
    currentStepId = guide.steps.first?.id
  }

  var currentIndex: Int? { guide.steps.firstIndex { $0.id == currentStepId } }
  var currentStep: Step? { currentIndex.map { guide.steps[$0] } }
  var isFinished: Bool { currentStepId == nil }

  func next() {
    guard let index = currentIndex else { return }
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

  static func loadBundled(named name: String = "sample-guide", bundle: Bundle = .main) throws -> Guide {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
      throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
    }
    return try JSONDecoder().decode(Guide.self, from: Data(contentsOf: url))
  }
}
