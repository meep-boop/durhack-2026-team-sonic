import Foundation

/// A thin REST client for Gemini's generateContent with an image and a JSON schema for the answer.
struct GeminiClient {
  let apiKey: String
  let model: String

  static func fromBundle() -> GeminiClient? {
    guard let key = Secrets.value("GeminiAPIKey") else { return nil }
    return GeminiClient(apiKey: key, model: Secrets.value("GeminiModel") ?? "gemini-3.8-flash")
  }

  enum Failure: LocalizedError {
    case http(Int, String)
    case empty(String)

    var errorDescription: String? {
      switch self {
      case .http(let code, let body): "Gemini returned \(code): \(body.prefix(200))"
      case .empty(let reason): "Gemini gave no answer (\(reason))"
      }
    }
  }

  func generate<T: Decodable>(_ type: T.Type, prompt: String, jpeg: Data?, schema: [String: Any]) async throws -> T {
    var parts: [[String: Any]] = [["text": prompt]]
    if let jpeg {
      parts.append(["inlineData": ["mimeType": "image/jpeg", "data": jpeg.base64EncodedString()]])
    }
    let body: [String: Any] = [
      "contents": [["role": "user", "parts": parts]],
      "generationConfig": [
        "responseMimeType": "application/json",
        "responseJsonSchema": schema,
        "temperature": 0.2,
      ],
    ]

    var request = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    request.timeoutInterval = 45

    let (data, response) = try await URLSession.shared.data(for: request)
    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard status == 200 else { throw Failure.http(status, String(decoding: data, as: UTF8.self)) }

    let envelope = try JSONDecoder().decode(Envelope.self, from: data)
    guard let candidate = envelope.candidates?.first else {
      throw Failure.empty(envelope.promptFeedback?.blockReason ?? "no candidates")
    }
    // Thinking models can return thought parts first; only the non-thought text is the answer.
    let text = (candidate.content?.parts ?? []).filter { $0.thought != true }.compactMap(\.text).joined()
    guard !text.isEmpty else { throw Failure.empty(candidate.finishReason ?? "no text") }
    return try JSONDecoder().decode(T.self, from: Data(text.utf8))
  }

  private struct Envelope: Decodable {
    struct Candidate: Decodable {
      struct Content: Decodable {
        struct Part: Decodable {
          var text: String?
          var thought: Bool?
        }
        var parts: [Part]?
      }
      var content: Content?
      var finishReason: String?
    }
    struct Feedback: Decodable { var blockReason: String? }
    var candidates: [Candidate]?
    var promptFeedback: Feedback?
  }
}
