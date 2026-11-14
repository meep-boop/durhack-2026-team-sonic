import Foundation
import Observation

/// Walks the guide one step at a time. Steps are tracked by id, as the contract asks, so later guide edits
/// (task 6) can't shift which step is current.
@Observable
final class GuidePlayer {
  private(set) var guide: Guide
  private(set) var currentStepId: String?

  init(guide: Guide) {
    self.guide = guide
    currentStepId = guide.steps.first?.id
  }

  var currentIndex: Int? { guide.steps.firstIndex { $0.id == currentStepId } }
  var currentStep: Step? { currentIndex.map { guide.steps[$0] } }
  var isFinished: Bool { currentStepId == nil }

  func next() {
    guard let index = currentIndex else { return }
    let nextIndex = index + 1
    currentStepId = nextIndex < guide.steps.count ? guide.steps[nextIndex].id : nil
  }

  func back() {
    guard let index = currentIndex, index > 0 else { return }
    currentStepId = guide.steps[index - 1].id
  }

  func restart() {
    currentStepId = guide.steps.first?.id
  }

  /// `guide.set` always carries the whole guide. Stay on the current step if it still exists (ids, not positions,
  /// so an inserted step doesn't move us); a new guide starts from its first step.
  func replace(with newGuide: Guide) {
    let keep = newGuide.id == guide.id && newGuide.steps.contains { $0.id == currentStepId }
    guide = newGuide
    if !keep { currentStepId = newGuide.steps.first?.id }
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
