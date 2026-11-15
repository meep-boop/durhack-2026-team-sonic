import Foundation

/// Small JSON files in Application Support, for state that must survive the app being killed: the offline outbox
/// (finished steps not yet confirmed by the relay) and the user's place in the guide. Writes are atomic, so a kill mid-write
/// leaves the previous file, never half of one.
enum Persistence {
  private static let queue = DispatchQueue(label: "persistence", qos: .utility)

  static var directory: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("RemoteAssist", isDirectory: true)
  }

  /// Encodes now (so later changes can't race the write) and writes in the background.
  static func save<T: Encodable>(_ value: T, as name: String) {
    guard let data = try? JSONEncoder().encode(value) else { return }
    queue.async {
      try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try? data.write(to: url(name), options: .atomic)
    }
  }

  static func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
    // Waits for any write still queued, so a load right after a save sees it.
    queue.sync {}
    guard let data = try? Data(contentsOf: url(name)) else { return nil }
    return try? JSONDecoder().decode(type, from: data)
  }

  static func remove(_ name: String) {
    queue.async { try? FileManager.default.removeItem(at: url(name)) }
  }

  private static func url(_ name: String) -> URL {
    directory.appendingPathComponent("\(name).json")
  }
}
