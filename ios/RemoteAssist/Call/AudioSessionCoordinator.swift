import AVFoundation

/// The one owner of AVAudioSession, shared by the call and the read-aloud voice.
///
/// Every session call blocks (setActive can take hundreds of ms), so they all run on one serial queue, never on main
/// and never inside Swift concurrency: on main they stalled the AR delegate, and inside a Task they set off the
/// "unsafeForcedSync called from Swift Concurrent context" warnings. One owner also means hanging up can't deactivate
/// the session under a step that's being read aloud, and reading a step can't flip the category under a live call.
final class AudioSessionCoordinator {
  static let shared = AudioSessionCoordinator()

  /// Serial; also the queue VoiceGuide plays on, so playback and session changes never interleave.
  let queue = DispatchQueue(label: "audio-session", qos: .userInitiated)

  private var callActive = false
  private var speakerOn = true
  private var playbackActive = false

  private var session: AVAudioSession { .sharedInstance() }

  func beginCall(speakerOn: Bool) {
    queue.async {
      self.callActive = true
      self.speakerOn = speakerOn
      try? self.session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
      try? self.session.setActive(true)
      try? self.session.overrideOutputAudioPort(speakerOn ? .speaker : .none)
    }
  }

  func setSpeaker(_ on: Bool) {
    queue.async {
      self.speakerOn = on
      guard self.callActive else { return }
      try? self.session.overrideOutputAudioPort(on ? .speaker : .none)
    }
  }

  func endCall() {
    queue.async {
      guard self.callActive else { return }
      self.callActive = false
      if self.playbackActive {
        // A step is being read: hand the session back to playback instead of pulling it away.
        try? self.session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      } else {
        try? self.session.setActive(false, options: .notifyOthersOnDeactivation)
      }
    }
  }

  /// Must be called on `queue`. During a call the session is already play-and-record and stays that way.
  func activateForPlaybackOnQueue() {
    dispatchPrecondition(condition: .onQueue(queue))
    if !callActive, session.category != .playback {
      try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }
    // During a call it's already active; between steps it's still active from the last one.
    if !callActive && !playbackActive { try? session.setActive(true) }
    playbackActive = true
  }

  /// Must be called on `queue`, when reading aloud stops or finishes.
  func playbackEndedOnQueue() {
    dispatchPrecondition(condition: .onQueue(queue))
    guard playbackActive else { return }
    playbackActive = false
    if !callActive { try? session.setActive(false, options: .notifyOthersOnDeactivation) }
  }
}
