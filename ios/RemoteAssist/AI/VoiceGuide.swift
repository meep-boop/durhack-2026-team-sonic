import AVFoundation
import Foundation

/// Reads steps aloud: ElevenLabs when there's a key and a network, the built-in iOS voice otherwise, so the guide
/// never goes quiet because the internet did.
///
/// Playback and audio-session work run on the audio coordinator's serial queue (see AudioSessionCoordinator for
/// why), and only the network fetch is async. Everything mutable below is touched on that queue only.
final class VoiceGuide: NSObject {
  private let apiKey = Secrets.value("ElevenLabsAPIKey")
  private let voiceId = Secrets.value("ElevenLabsVoiceID") ?? "JBFqnCBsd6RMkjVDRZzb"
  private let model = Secrets.value("ElevenLabsModel") ?? "eleven_multilingual_v2"

  private let audio = AudioSessionCoordinator.shared
  private var queue: DispatchQueue { audio.queue }

  private var cache: [String: Data] = [:]
  private var player: AVAudioPlayer?
  private var fallback = AVSpeechSynthesizer()
  private var fetch: URLSessionDataTask?
  /// Bumped by every speak and stop, so a late network answer for an old step is dropped.
  private var generation = 0

  var usesElevenLabs: Bool { apiKey != nil }
  /// Called on main when reading aloud starts and stops, so voice commands don't hear the app talking.
  var onSpeakingChanged: ((Bool) -> Void)?
  private var speaking = false {
    didSet {
      guard speaking != oldValue else { return }
      let value = speaking
      DispatchQueue.main.async { self.onSpeakingChanged?(value) }
    }
  }

  override init() {
    super.init()
    fallback.delegate = self
    // After iOS restarts its audio server, the old player and synthesizer are dead objects: make new ones.
    NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil) { [weak self] _ in
      guard let self else { return }
      self.queue.async {
        self.player = nil
        self.fallback = AVSpeechSynthesizer()
        self.fallback.delegate = self
        self.speaking = false
      }
    }
  }

  func speak(_ text: String) {
    let spoken = text.replacingOccurrences(of: "⚠️", with: "Careful:")
    queue.async {
      // The next step follows straight away, so keep the session up rather than flap it off and on.
      self.stopOnQueue(endSession: false)
      let gen = self.generation
      if let cached = self.cache[spoken] {
        self.play(cached, orSay: spoken, gen: gen)
      } else if let request = self.elevenLabsRequest(for: spoken) {
        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
          let ok = (response as? HTTPURLResponse)?.statusCode == 200
          self.queue.async {
            guard gen == self.generation else { return }
            if ok, let data { self.cache[spoken] = data }
            self.play(ok ? data : nil, orSay: spoken, gen: gen)
          }
        }
        self.fetch = task
        task.resume()
      } else {
        self.play(nil, orSay: spoken, gen: gen)
      }
    }
  }

  func stop() {
    queue.async { self.stopOnQueue(endSession: true) }
  }

  /// For the system check: says "Voice check" in the ElevenLabs voice. `done` gets nil when ElevenLabs answered and
  /// played, or why it didn't (on main).
  func checkVoice(_ done: @escaping (String?) -> Void) {
    let finish = { (problem: String?) in DispatchQueue.main.async { done(problem) } }
    guard let request = elevenLabsRequest(for: "Voice check. ElevenLabs is working.") else {
      return finish("No ELEVENLABS_API_KEY in ios/Secrets.xcconfig: steps use the iOS voice")
    }
    URLSession.shared.dataTask(with: request) { data, response, error in
      let status = (response as? HTTPURLResponse)?.statusCode ?? 0
      guard status == 200, let data else {
        let body = data.map { String(decoding: $0.prefix(160), as: UTF8.self) } ?? error?.localizedDescription ?? ""
        return finish("ElevenLabs returned \(status): \(body)")
      }
      self.queue.async {
        self.stopOnQueue(endSession: false)
        self.play(data, orSay: "Voice check", gen: self.generation)
        finish(nil)
      }
    }.resume()
  }

  // MARK: On the audio queue

  private func stopOnQueue(endSession: Bool) {
    generation += 1
    fetch?.cancel()
    fetch = nil
    player?.stop()
    player = nil
    if fallback.isSpeaking { fallback.stopSpeaking(at: .immediate) }
    if endSession {
      speaking = false
      audio.playbackEndedOnQueue()
    }
  }

  private func play(_ data: Data?, orSay text: String, gen: Int) {
    guard gen == generation else { return }
    audio.activateForPlaybackOnQueue()
    speaking = true
    if let data, let player = try? AVAudioPlayer(data: data) {
      player.delegate = self
      self.player = player
      if player.play() { return }
    }
    fallback.speak(AVSpeechUtterance(string: text))
  }

  private func elevenLabsRequest(for text: String) -> URLRequest? {
    guard let apiKey else { return nil }
    var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)?output_format=mp3_44100_128")!)
    request.httpMethod = "POST"
    request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 8
    request.httpBody = try? JSONSerialization.data(withJSONObject: [
      "text": text,
      "model_id": model,
      "voice_settings": ["stability": 0.6, "similarity_boost": 0.75],
    ])
    return request
  }
}

extension VoiceGuide: AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    queue.async {
      guard player === self.player else { return }
      self.player = nil
      self.speaking = false
      self.audio.playbackEndedOnQueue()
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    queue.async {
      guard !synthesizer.isSpeaking, self.player == nil else { return }
      self.speaking = false
      self.audio.playbackEndedOnQueue()
    }
  }
}
