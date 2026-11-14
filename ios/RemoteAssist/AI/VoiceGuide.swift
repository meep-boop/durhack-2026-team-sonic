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
  private let fallback = AVSpeechSynthesizer()
  private var fetch: URLSessionDataTask?
  /// Bumped by every speak and stop, so a late network answer for an old step is dropped.
  private var generation = 0

  var usesElevenLabs: Bool { apiKey != nil }

  override init() {
    super.init()
    fallback.delegate = self
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

  // MARK: On the audio queue

  private func stopOnQueue(endSession: Bool) {
    generation += 1
    fetch?.cancel()
    fetch = nil
    player?.stop()
    player = nil
    if fallback.isSpeaking { fallback.stopSpeaking(at: .immediate) }
    if endSession { audio.playbackEndedOnQueue() }
  }

  private func play(_ data: Data?, orSay text: String, gen: Int) {
    guard gen == generation else { return }
    audio.activateForPlaybackOnQueue()
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
      self.audio.playbackEndedOnQueue()
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    queue.async { if !synthesizer.isSpeaking { self.audio.playbackEndedOnQueue() } }
  }
}
