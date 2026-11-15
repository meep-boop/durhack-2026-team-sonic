import Foundation
import Observation

/// The laptop guide, with no AI: the team's checked SSD swap for Ahmed's Dell Latitude 5530 (VerifiedProcedures),
/// started from the laptop button without the printed marker. Parts are pinned by the expert tapping the live video;
/// the spotlight, the ghost screwdriver and screw memory follow those pins.
@Observable
final class LaptopGuide {
  struct Instruction: Equatable {
    var title: String
    var detail: String
    /// The part this step is about, e.g. "the eight base cover screws". Also groups screw memory.
    var lookFor: String
    var caution: String?
    /// "remove", "refit" or "other": which way the ghost screwdriver turns, and when screw memory records or replays.
    var phase: String
  }

  /// Stable, so the player keeps its place across launches. The relay has no copy, so taps aren't sent for it.
  static let guideId = "laptop-dell-5530-ssd"

  /// Ticked by the user before the first step; nothing checks these for them.
  static let safetyItems: [(id: String, text: String)] = [
    ("saved", "Work saved and the laptop shut down"),
    ("unplugged", "Charger and everything else unplugged"),
    ("surface", "A clear, soft surface (or the board) to work on"),
    ("tools", "A #0 Phillips screwdriver and a plastic pry tool to hand"),
  ]

  let procedure = VerifiedProcedures.latitude5530
  var safetyChecked: Set<String> = []
  /// The user started before ticking everything, after confirming.
  private(set) var safetyOverridden = false

  var allSafe: Bool { Self.safetyItems.allSatisfy { safetyChecked.contains($0.id) } }
  var steps: [Instruction] { procedure.steps }
  var device: String { procedure.device }
  var stepSource: String { "Steps from \(procedure.source)" }
  var captiveScrews: Bool { procedure.captiveScrews }

  func overrideSafety() {
    safetyOverridden = true
  }

  func resetSafety() {
    safetyChecked = []
    safetyOverridden = false
  }

  func guide() -> Guide {
    Guide(
      id: Self.guideId,
      rev: 1,
      title: "Replace the SSD · \(procedure.device)",
      marker: Marker(name: MarkerSpec.imageName, width: MarkerSpec.widthMeters, height: MarkerSpec.widthMeters),
      steps: steps.enumerated().map { index, step in
        let caution = step.caution.map { "\n⚠️ \($0)" } ?? ""
        return Step(id: "l\(index + 1)", text: "\(step.title)\n\(step.detail)\(caution)", objects: [])
      }
    )
  }

  func phase(stepIndex: Int) -> String? {
    steps.indices.contains(stepIndex) ? steps[stepIndex].phase : nil
  }

  func lookFor(stepIndex: Int) -> String? {
    steps.indices.contains(stepIndex) ? steps[stepIndex].lookFor : nil
  }
}

