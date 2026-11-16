import Foundation

/// Sends a saved scan to the laptop's scan inbox (pipeline/scan-inbox.ts) as one zip. The laptop is found from the
/// relay address the app already has: the same host, port 8090.
enum ScanUploader {
  static let port = 8090

  enum UploadError: LocalizedError {
    case refused(Int, String)

    var errorDescription: String? {
      switch self {
      case .refused(let status, let body): "The laptop refused the scan (HTTP \(status)). \(body)"
      }
    }
  }

  static func endpoint(relay: URL?) -> URL? {
    guard let host = relay?.host(), !host.isEmpty else { return nil }
    var components = URLComponents()
    components.scheme = "http"
    components.host = host
    components.port = port
    components.path = "/scan"
    return components.url
  }

  /// Returns the file name the laptop saved it under. `progress` is called off main with 0...1.
  static func send(_ folder: URL, to endpoint: URL, progress: @escaping (Double) -> Void) async throws -> String {
    let zip = try zipped(folder)
    defer { try? FileManager.default.removeItem(at: zip) }
    var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
    components?.queryItems = [URLQueryItem(name: "name", value: folder.lastPathComponent)]
    guard let url = components?.url else { throw URLError(.badURL) }
    var request = URLRequest(url: url, timeoutInterval: 120)
    request.httpMethod = "POST"
    request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
    let (data, response) = try await URLSession.shared.upload(for: request, fromFile: zip, delegate: ProgressDelegate(progress))
    guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
    guard (200..<300).contains(http.statusCode) else {
      throw UploadError.refused(http.statusCode, String(data: data, encoding: .utf8) ?? "")
    }
    struct Reply: Decodable { let saved: String }
    return try JSONDecoder().decode(Reply.self, from: data).saved
  }

  /// iOS has no zip API, but a file coordinator reading a folder "for uploading" hands back a zip of it.
  private static func zipped(_ folder: URL) throws -> URL {
    var coordinatorError: NSError?
    var moved: Result<URL, Error>?
    NSFileCoordinator().coordinate(readingItemAt: folder, options: .forUploading, error: &coordinatorError) { zip in
      // The coordinator deletes its zip when this block returns, so it's moved somewhere that lasts.
      let target = FileManager.default.temporaryDirectory.appendingPathComponent("\(folder.lastPathComponent).zip")
      try? FileManager.default.removeItem(at: target)
      moved = Result {
        try FileManager.default.moveItem(at: zip, to: target)
        return target
      }
    }
    if let coordinatorError { throw coordinatorError }
    guard let moved else { throw CocoaError(.fileReadUnknown) }
    return try moved.get()
  }

  private final class ProgressDelegate: NSObject, URLSessionTaskDelegate {
    let report: (Double) -> Void

    init(_ report: @escaping (Double) -> Void) {
      self.report = report
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
      guard totalBytesExpectedToSend > 0 else { return }
      report(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
    }
  }
}
