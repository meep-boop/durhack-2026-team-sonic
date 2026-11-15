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
  /// Hands-free voice commands are on: the mic stays open between steps.
  private var listening = false

  private var session: AVAudioSession { .sharedInstance() }

  /// iOS sometimes restarts its whole audio server (the log shows "AudioSession was invalidated", then haptics
  /// errors). Every session setting is lost: put back whatever is active now. VoiceGuide and VoiceCommands rebuild
  /// their own players and engines on the same notification.
  private var resetObserver: NSObjectProtocol?

  init() {
    resetObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil
    ) { [weak self] _ in
      self?.queue.async { self?.restoreAfterReset() }
    }
  }

  private func restoreAfterReset() {
    ARSessionController.log.notice("Media services were reset: restoring the audio session")
    if callActive {
      attempt("setCategory") { try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP]) }
      attempt("setActive") { try session.setActive(true) }
      attempt("overrideOutputAudioPort") { try session.overrideOutputAudioPort(speakerOn ? .speaker : .none) }
    } else if listening || playbackActive {
      attempt("setCategory") {
        try session.setCategory(listening ? .playAndRecord : .playback, mode: listening ? .default : .spokenAudio,
                                options: listening ? [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers] : [.duckOthers])
      }
      attempt("setActive") { try session.setActive(true) }
    }
  }

  func beginCall(speakerOn: Bool) {
    queue.async {
      self.callActive = true
      self.speakerOn = speakerOn
      self.attempt("setCategory") { try self.session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP]) }
      self.attempt("setActive") { try self.session.setActive(true) }
      self.attempt("overrideOutputAudioPort") { try self.session.overrideOutputAudioPort(speakerOn ? .speaker : .none) }
    }
  }

  func setSpeaker(_ on: Bool) {
    queue.async {
      self.speakerOn = on
      guard self.callActive else { return }
      self.attempt("overrideOutputAudioPort") { try self.session.overrideOutputAudioPort(on ? .speaker : .none) }
    }
  }

  func endCall() {
    queue.async {
      guard self.callActive else { return }
      self.callActive = false
      // Hand the session back to whoever still needs it instead of pulling it away under them.
      if self.listening || self.playbackActive {
        self.applyCategory()
      } else {
        self.attempt("setActive") { try self.session.setActive(false, options: .notifyOthersOnDeactivation) }
      }
    }
  }

  /// Opens the mic for voice commands; `ready` runs on `queue` once the session can record.
  func beginListening(ready: @escaping () -> Void) {
    queue.async {
      self.listening = true
      self.applyCategory()
      self.attempt("setActive") { try self.session.setActive(true) }
      ready()
    }
  }

  /// `stopped` runs on `queue` before the session changes, so the mic engine can stop first.
  func endListening(stopped: @escaping () -> Void) {
    queue.async {
      stopped()
      guard self.listening else { return }
      self.listening = false
      guard !self.callActive else { return }
      if self.playbackActive {
        self.applyCategory()
      } else {
        self.attempt("setActive") { try self.session.setActive(false, options: .notifyOthersOnDeactivation) }
      }
    }
  }

  /// Outside a call: play-and-record while listening (the speaker still reads steps), plain playback otherwise.
  private func applyCategory() {
    guard !callActive else { return }
    if listening {
      // Only when it changes: re-setting the category under a running mic engine interrupts it.
      guard session.category != .playAndRecord || session.mode != .default else { return }
      attempt("setCategory") { try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers]) }
    } else if session.category != .playback {
      attempt("setCategory") { try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers]) }
    }
  }

  /// Must be called on `queue`. During a call the session is already play-and-record and stays that way.
  func activateForPlaybackOnQueue() {
    dispatchPrecondition(condition: .onQueue(queue))
    applyCategory()
    // During a call or while listening it's already active; between steps it's still active from the last one.
    if !callActive && !listening && !playbackActive { attempt("setActive") { try session.setActive(true) } }
    playbackActive = true
  }

  /// Must be called on `queue`, when reading aloud stops or finishes.
  func playbackEndedOnQueue() {
    dispatchPrecondition(condition: .onQueue(queue))
    guard playbackActive else { return }
    playbackActive = false
    if !callActive && !listening { attempt("setActive(false)") { try session.setActive(false, options: .notifyOthersOnDeactivation) } }
  }

  /// Every session call goes through here: a failure used to vanish behind `try?`, which is why "no sound" left no
  /// trace in the log.
  private func attempt(_ what: String, _ body: () throws -> Void) {
    do {
      try body()
    } catch {
      ARSessionController.log.error("Audio session \(what, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
