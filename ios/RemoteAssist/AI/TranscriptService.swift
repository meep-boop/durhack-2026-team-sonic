import Foundation

/// The call transcript runs on the expert's page (it already has both voices), through ElevenLabs Scribe realtime.
/// The ElevenLabs key stays on this phone: the phone mints single-use tokens (15 minutes, consumed on use) and hands
/// them to the page over the call's own data channel, so the key is never sent anywhere but to ElevenLabs.
/// API: https://elevenlabs.io/docs/api-reference/speech-to-text/v-1-speech-to-text-realtime
enum TranscriptService {
  static var apiKey: String? { Secrets.value("ElevenLabsAPIKey") }

  enum Failure: LocalizedError {
    case noKey
    case http(Int, String)

    var errorDescription: String? {
      switch self {
      case .noKey: "No ElevenLabs key on the phone"
      case .http(let code, let body): "ElevenLabs returned \(code): \(body.prefix(160))"
      }
    }
  }

  static func mintToken() async throws -> String {
    guard let apiKey else { throw Failure.noKey }
    var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/single-use-token/realtime_scribe")!)
    request.httpMethod = "POST"
    request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
    request.timeoutInterval = 10
    let (data, response) = try await URLSession.shared.data(for: request)
    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard status == 200, let token = (try? JSONDecoder().decode(TokenResponse.self, from: data))?.token else {
      throw Failure.http(status, String(decoding: data, as: UTF8.self))
    }
    return token
  }

  private struct TokenResponse: Decodable { var token: String }
}

/// One line of the call, as the expert's page heard it.
struct TranscriptLine: Identifiable, Equatable {
  enum Speaker: String { case expert, user }
  var id: String
  var speaker: Speaker
  var text: String
  var at: Date

  var speakerName: String { speaker == .expert ? "Expert" : "You" }
}
