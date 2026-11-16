import AVFoundation
import Observation
import Speech
import os

/// Hands-free control: "next", "back", "show me", "repeat", "call the expert", for when both
/// hands are on a screwdriver. Apple's speech recogniser, on the device when it supports that (so it works offline
/// and nothing leaves the phone). Paused while the app is talking, so it doesn't hear itself, and during a call,
/// when WebRTC owns the mic.
@Observable
final class VoiceCommands {
  enum Command: Equatable {
    case next, back, showMe, repeatStep, callExpert
  }

  private(set) var isOn = false
  /// The command just heard, shown briefly so the user knows it landed.
  private(set) var heard: String?
  private(set) var problem: String?

  @ObservationIgnored var onCommand: ((Command) -> Void)?

  @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-GB")) ?? SFSpeechRecognizer()
  /// Replaced after a media-services reset, when the old engine can't start again.
  @ObservationIgnored private var engine = AVAudioEngine()
  @ObservationIgnored private let audio = AudioSessionCoordinator.shared
  /// The mic tap runs on an audio thread and appends to whichever request is current.
  @ObservationIgnored private let request = OSAllocatedUnfairLock<SFSpeechAudioBufferRecognitionRequest?>(initialState: nil)
  @ObservationIgnored private var task: SFSpeechRecognitionTask?
  @ObservationIgnored private var suspended = false
  @ObservationIgnored private var engineRunning = false
  /// How much of the running transcript has already been turned into commands.
  @ObservationIgnored private var consumed = 0
  @ObservationIgnored private var lastFired = Date.distantPast

  /// Phrases checked longest first, so "call the expert" isn't read as something shorter.
  private static let phrases: [(String, Command)] = [
    ("call the expert", .callExpert), ("call expert", .callExpert),
    ("show me where", .showMe), ("show me", .showMe),
    ("next step", .next), ("go back", .back), ("say again", .repeatStep),
    ("next", .next), ("done", .next), ("finished", .next),
    ("back", .back), ("previous", .back), ("where", .showMe),
    ("repeat", .repeatStep), ("help", .callExpert),
  ]

  init() {
    NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self else { return }
      self.endTask()
      self.engineRunning = false
      self.engine = AVAudioEngine()
      self.resumeIfPossible()
    }
  }

  func toggle() {
    isOn ? stop() : start()
  }

  func start() {
    problem = nil
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        guard status == .authorized else {
          self.problem = "Allow Speech Recognition for Sonic Assist in Settings"
          return
        }
        AVAudioApplication.requestRecordPermission { granted in
          DispatchQueue.main.async {
            guard granted else {
              self.problem = "Allow the microphone for Sonic Assist in Settings"
              return
            }
            guard self.recognizer?.isAvailable == true else {
              self.problem = "Speech recognition isn't available right now"
              return
            }
            self.isOn = true
            self.resumeIfPossible()
          }
        }
      }
    }
  }

  func stop() {
    isOn = false
    pause()
  }

  /// While the app reads a step aloud, during a call, or in the background.
  func setSuspended(_ value: Bool) {
    guard suspended != value else { return }
    suspended = value
    value ? pause() : resumeIfPossible()
  }

  // MARK: Engine and recognition (main)

  private func resumeIfPossible() {
    guard isOn, !suspended, task == nil else { return }
    if engineRunning {
      beginTask()
      return
    }
    let input = engine.inputNode
    audio.beginListening { [weak self] in
      guard let self else { return }
      let format = input.outputFormat(forBus: 0)
      guard format.sampleRate > 0 else { return }
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [request] buffer, _ in
        request.withLock { $0?.append(buffer) }
      }
      self.engine.prepare()
      let started = (try? self.engine.start()) != nil
      DispatchQueue.main.async {
        self.engineRunning = started
        if started { self.beginTask() } else { self.problem = "Couldn't open the microphone"; self.isOn = false }
      }
    }
  }

  private func pause() {
    endTask()
    guard engineRunning else { return }
    engineRunning = false
    let engine = engine
    audio.endListening {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
    }
  }

  private func beginTask() {
    guard let recognizer, task == nil else { return }
    let new = SFSpeechAudioBufferRecognitionRequest()
    new.shouldReportPartialResults = true
    new.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
    new.taskHint = .confirmation
    new.contextualStrings = Self.phrases.map(\.0)
    request.withLock { $0 = new }
    consumed = 0
    task = recognizer.recognitionTask(with: new) { [weak self] result, error in
      DispatchQueue.main.async { self?.handle(result, error: error) }
    }
  }

  private func endTask() {
    request.withLock { $0?.endAudio(); $0 = nil }
    task?.cancel()
    task = nil
  }

  private func handle(_ result: SFSpeechRecognitionResult?, error: Error?) {
    if let result {
      let text = result.bestTranscription.formattedString.lowercased()
      if text.count > consumed {
        let fresh = String(text.dropFirst(consumed))
        if let (phrase, command) = Self.match(fresh), Date().timeIntervalSince(lastFired) > 1 {
          consumed = text.count
          lastFired = Date()
          heard = phrase
          onCommand?(command)
          Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            if self?.heard == phrase { self?.heard = nil }
          }
        }
      }
    }
    // A recognition task ends after a pause or about a minute; start a fresh one so listening never just stops.
    if error != nil || result?.isFinal == true {
      task = nil
      request.withLock { $0 = nil }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        guard let self, self.isOn, !self.suspended, self.engineRunning else { return }
        self.beginTask()
      }
    }
  }

  /// The first command phrase in the words, matched on whole words.
  static func match(_ text: String) -> (String, Command)? {
    let words = text.lowercased().split { !$0.isLetter && $0 != "-" }.map { $0.replacingOccurrences(of: "-", with: "") }
    let joined = " " + words.joined(separator: " ") + " "
    return phrases.first { joined.contains(" \($0.0) ") }
  }
}
