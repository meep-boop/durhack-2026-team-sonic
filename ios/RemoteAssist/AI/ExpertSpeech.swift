import Foundation

/// What the expert says that the phone acts on, from the call's live transcript. Only short, command-like lines count:
/// the phrase plus filler ("okay, next step", "now look left please"). A phrase inside a longer sentence ("I'll go
/// back to that later") is talk, not a command, and a wrong jump mid-repair is worse than a missed one.
enum ExpertSpeech {
  enum Direction: String, Equatable, CaseIterable {
    case left, right, up, down
  }

  enum Command: Equatable {
    case next, back, look(Direction), clear
  }

  static let phrases: [(String, Command)] = [
    ("next step", .next),
    ("previous step", .back), ("go back", .back),
    ("look left", .look(.left)), ("turn left", .look(.left)),
    ("look right", .look(.right)), ("turn right", .look(.right)),
    ("look up", .look(.up)), ("look down", .look(.down)),
    ("clear the marks", .clear), ("clear the pins", .clear), ("clear that", .clear),
  ]

  /// Words that can sit around a command without making it a sentence.
  static let fillers: Set<String> = [
    "okay", "ok", "alright", "so", "now", "please", "then", "and", "just", "a", "bit", "little", "slightly", "more",
    "for", "me", "can", "you", "could", "lets", "go", "to", "the", "your", "phone", "camera", "um", "uh",
  ]

  static func command(in text: String) -> Command? {
    let words = text.lowercased()
      .split { !$0.isLetter && $0 != "'" && $0 != "’" }
      .map { $0.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "’", with: "") }
      .filter { !$0.isEmpty }
    for (phrase, command) in phrases {
      let target = phrase.split(separator: " ").map(String.init)
      guard target.count <= words.count else { continue }
      for start in 0...(words.count - target.count) where Array(words[start..<start + target.count]) == target {
        let rest = words[..<start] + words[(start + target.count)...]
        if rest.allSatisfy(fillers.contains) { return command }
      }
    }
    return nil
  }

  /// What the phone shows for a direction: the same words and arrow as the spotlight's edge cue.
  static func cue(for direction: Direction) -> (words: String, symbol: String) {
    switch direction {
    case .left: ("Look left", "arrow.left")
    case .right: ("Look right", "arrow.right")
    case .up: ("Look up", "arrow.up")
    case .down: ("Look down", "arrow.down")
    }
  }
}
