import Foundation
import Observation

/// Walks the guide one step at a time. Steps are tracked by id, as the contract asks, so later guide edits
/// (task 6) can't shift which step is current.
@Observable
final class GuidePlayer {
  let guide: Guide
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

  func restart() {
    currentStepId = guide.steps.first?.id
  }

  static func loadBundled(named name: String = "sample-guide", bundle: Bundle = .main) throws -> Guide {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
      throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
    }
    return try JSONDecoder().decode(Guide.self, from: Data(contentsOf: url))
  }
}
