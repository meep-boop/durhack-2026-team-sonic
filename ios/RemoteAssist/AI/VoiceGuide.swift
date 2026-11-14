import AVFoundation
import Foundation

/// Reads steps aloud: ElevenLabs when there's a key and a network, the built-in iOS voice otherwise, so the guide
/// never goes quiet because the internet did.
final class VoiceGuide: NSObject {
  private let apiKey = Secrets.value("ElevenLabsAPIKey")
  private let voiceId = Secrets.value("ElevenLabsVoiceID") ?? "JBFqnCBsd6RMkjVDRZzb"
  private let model = Secrets.value("ElevenLabsModel") ?? "eleven_multilingual_v2"

  private var cache: [String: Data] = [:]
  private var player: AVAudioPlayer?
  private let fallback = AVSpeechSynthesizer()
  private var currentTask: Task<Void, Never>?

  var usesElevenLabs: Bool { apiKey != nil }

  func speak(_ text: String) {
    stop()
    let spoken = text.replacingOccurrences(of: "⚠️", with: "Careful:")
    currentTask = Task { @MainActor [weak self] in
      guard let self else { return }
      self.prepareSession()
      if let audio = await self.elevenLabsAudio(for: spoken), !Task.isCancelled {
        self.player = try? AVAudioPlayer(data: audio)
        if self.player?.play() == true { return }
      }
      guard !Task.isCancelled else { return }
      self.fallback.speak(AVSpeechUtterance(string: spoken))
    }
  }

  func stop() {
    currentTask?.cancel()
    player?.stop()
    fallback.stopSpeaking(at: .immediate)
  }

  private func elevenLabsAudio(for text: String) async -> Data? {
    guard let apiKey else { return nil }
    if let cached = cache[text] { return cached }

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

    guard let (data, response) = try? await URLSession.shared.data(for: request),
          (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
    cache[text] = data
    return data
  }

  /// During a call the session is already play-and-record for WebRTC; only set playback when nothing else owns it.
  private func prepareSession() {
    let session = AVAudioSession.sharedInstance()
    if session.category != .playAndRecord {
      try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }
    try? session.setActive(true)
  }
}
