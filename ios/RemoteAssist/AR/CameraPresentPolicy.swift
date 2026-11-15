import Foundation

/// When the live feed (`CameraFeedView`) covers the AR view, and what to do about an AR view or camera that stopped.
/// Pure, so the timing can be tested; `ARSessionController` asks it ten times a second.
enum CameraPresentPolicy {
  /// No drawn frame for this long while the camera runs: the AR view is stuck, so the feed covers it.
  static let stuckAfter: TimeInterval = 0.25
  /// A longer gap between two drawn frames breaks a run of steady drawing (one dropped frame at 60 fps is 33 ms).
  static let steadyGap: TimeInterval = 0.05
  /// Steady drawing this long uncovers the AR view; any less and a struggling view flips back and forth.
  static let steadyFor: TimeInterval = 1
  /// Covered this long: a fresh AR view is built underneath, then each next try waits longer.
  static let replaceAfter: TimeInterval = 2
  /// No camera frames this long: re-run the session, and again every `rerunEvery`.
  static let silentAfter: TimeInterval = 2
  static let rerunEvery: TimeInterval = 3

  struct Input {
    var now: TimeInterval
    /// The last start, resume or view replacement: nothing drawn before it counts.
    var startedAt: TimeInterval
    var lastFrameAt: TimeInterval
    var lastPresentAt: TimeInterval
    /// When the current run of steady drawing began.
    var steadySince: TimeInterval
    var feedShown: Bool
    var feedShownAt: TimeInterval
    var lastReplaceAt: TimeInterval
    /// Fresh AR views built while this cover has been up.
    var replacements: Int
    var lastRerunAt: TimeInterval
  }

  struct Decision: Equatable {
    var showFeed: Bool
    var replaceView = false
    var rerunSession = false
    var cameraSilent = false
  }

  static func decide(_ s: Input) -> Decision {
    if s.now - max(s.lastFrameAt, s.startedAt) > silentAfter {
      // Nothing new to show either way: the feed holds the last picture rather than whatever the AR view has.
      return Decision(showFeed: true, rerunSession: s.now - s.lastRerunAt >= rerunEvery, cameraSilent: true)
    }
    let drawing = s.lastPresentAt >= s.startedAt && s.now - s.lastPresentAt <= stuckAfter
    let steady = drawing && s.now - max(s.steadySince, s.startedAt) >= steadyFor
    let show = s.feedShown ? !steady : !drawing
    // A view that's drawing again is left to settle, even while it isn't steady enough to uncover yet.
    let replace = show && s.feedShown && !drawing
      && s.now - s.feedShownAt >= replaceAfter
      && s.now - s.lastReplaceAt >= replaceInterval(after: s.replacements)
    return Decision(showFeed: show, replaceView: replace)
  }

  /// The first fresh view comes as soon as the cover has been up `replaceAfter`; then 5, 10, 20 s apart, and every
  /// 30 s after that. Each one rebuilds RealityKit's renderer, so a view that keeps failing isn't rebuilt every second.
  static func replaceInterval(after replacements: Int) -> TimeInterval {
    replacements == 0 ? 0 : min(30, 5 * pow(2, Double(replacements - 1)))
  }
}
