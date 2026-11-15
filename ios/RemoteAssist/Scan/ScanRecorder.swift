import ARKit
import CoreImage
import ImageIO
import Observation
import os

/// Records a scan of the room inside the app: photos picked as the phone moves, each with the camera's position and
/// lens, plus the feature points ARKit tracked. It writes nerfstudio's `transforms.json` layout with every pose and
/// point in the marker's frame (metres, the contract's frame), so a splat trained from it (pipeline/train_scan.py)
/// sits on the marker without the four corner clicks a Scaniverse scan needs.
///
/// Threading: `consider` runs on the AR session queue and only copies, because ARKit wants its buffers back at once.
/// JPEG encoding and file writes run on `work`, in order. Observable state: main only.
@Observable
final class ScanRecorder {
  static let log = Logger(subsystem: "com.teamsonic.remoteassist", category: "scan")

  private(set) var photoCount = 0
  /// True while the phone has recently moved too fast for a sharp photo, so the screen can say "slower".
  private(set) var movingTooFast = false

  @ObservationIgnored private let policy = ScanKeyframePolicy()
  @ObservationIgnored private let work = DispatchQueue(label: "scan-writer", qos: .utility)
  @ObservationIgnored private let context = CIContext()
  @ObservationIgnored private let state = OSAllocatedUnfairLock(initialState: State())

  /// Photos copied but not yet written. Past this the next photo is skipped: each copy holds about 4 MB.
  private static let maxBacklog = 6
  private static let minimumPhotos = 20
  private static let maxPoints = 60_000

  private struct State {
    var recording = false
    var folder: URL?
    var marker: simd_float4x4?
    var previous: ScanKeyframePolicy.Sample?
    var lastKept: ScanKeyframePolicy.Sample?
    var frames: [KeptFrame] = []
    var points: [UInt64: SIMD3<Float>] = [:]
    var encoding = 0
    var lastTooFastAt: TimeInterval = -.infinity
    var tooFast = false
  }

  private struct KeptFrame {
    var file: String
    var cameraInWorld: simd_float4x4
    var intrinsics: simd_float3x3
    var width: Int
    var height: Int
    var time: TimeInterval
  }

  private struct Ticket {
    var index: Int
    var folder: URL
  }

  enum ScanError: LocalizedError {
    case notStarted, markerNeverSeen, tooFewPhotos(Int)

    var errorDescription: String? {
      switch self {
      case .notStarted: "The scan never started."
      case .markerNeverSeen: "The marker was never seen, so the scan can't be lined up. Start with the marker in view."
      case .tooFewPhotos(let count): "Only \(count) photos: walk further round the laptop, more slowly."
      }
    }
  }

  // MARK: Main

  /// Starts a new scan folder under Documents/Scans.
  func start() throws {
    let folder = Self.scansDirectory.appendingPathComponent("scan-\(Self.stamp())", isDirectory: true)
    try FileManager.default.createDirectory(at: folder.appendingPathComponent("images"), withIntermediateDirectories: true)
    photoCount = 0
    movingTooFast = false
    state.withLock { $0 = State(recording: true, folder: folder) }
  }

  /// Stops recording, waits for the photos still being written, then writes `transforms.json` and `points.ply`.
  func finish() async throws -> URL {
    let (frames, points, marker, folder) = state.withLock { s in
      s.recording = false
      return (s.frames, Array(s.points.values), s.marker, s.folder)
    }
    guard let folder else { throw ScanError.notStarted }
    guard let marker else { throw ScanError.markerNeverSeen }
    guard frames.count >= Self.minimumPhotos else { throw ScanError.tooFewPhotos(frames.count) }
    return try await withCheckedThrowingContinuation { continuation in
      // The queue is serial, so this runs after every photo queued before it.
      work.async {
        continuation.resume(with: Result {
          try Self.writeIndex(frames: frames, points: points, marker: marker, to: folder)
          Self.log.notice("Scan saved: \(frames.count, privacy: .public) photos, \(points.count, privacy: .public) points")
          return folder
        })
      }
    }
  }

  /// Leaving mid-scan throws the half-made scan away.
  func cancel() {
    let folder = state.withLock { s -> URL? in
      s.recording = false
      return s.folder
    }
    guard let folder else { return }
    work.async { try? FileManager.default.removeItem(at: folder) }
  }

  // MARK: AR session queue

  /// One camera frame. `marker` is the marker's last tracked pose in the world, nil until it's been seen.
  func consider(_ frame: ARFrame, marker: simd_float4x4?) {
    guard case .normal = frame.camera.trackingState else { return }
    let sample = ScanKeyframePolicy.Sample(transform: frame.camera.transform, time: frame.timestamp)
    guard let ticket = decide(sample, marker: marker) else { return }
    guard let image = Self.copy(frame.capturedImage) else {
      state.withLock { $0.encoding -= 1 }
      return
    }
    let kept = KeptFrame(
      file: String(format: "images/%05d.jpg", ticket.index),
      cameraInWorld: sample.transform,
      intrinsics: frame.camera.intrinsics,
      width: Int(frame.camera.imageResolution.width),
      height: Int(frame.camera.imageResolution.height),
      time: sample.time
    )
    let points = frame.rawFeaturePoints.map { Array(zip($0.identifiers, $0.points)) } ?? []
    state.withLock { s in
      s.frames.append(kept)
      for (id, point) in points where s.points.count < Self.maxPoints || s.points[id] != nil {
        s.points[id] = point
      }
    }
    let url = ticket.folder.appendingPathComponent(kept.file)
    work.async { [weak self] in self?.write(image, to: url) }
  }

  private func decide(_ sample: ScanKeyframePolicy.Sample, marker: simd_float4x4?) -> Ticket? {
    let (ticket, tooFastChanged) = state.withLock { s -> (Ticket?, Bool?) in
      guard s.recording, let folder = s.folder else { return (nil, nil) }
      if let marker { s.marker = marker }
      let verdict = policy.judge(sample, previous: s.previous, lastKept: s.lastKept, kept: s.frames.count)
      s.previous = sample
      // Held for a moment after the last fast frame, so the hint doesn't flicker on and off.
      if verdict == .tooFast { s.lastTooFastAt = sample.time }
      let tooFast = sample.time - s.lastTooFastAt < 0.6
      var changed: Bool?
      if tooFast != s.tooFast {
        s.tooFast = tooFast
        changed = tooFast
      }
      guard verdict == .keep, s.encoding < Self.maxBacklog else { return (nil, changed) }
      s.lastKept = sample
      s.encoding += 1
      return (Ticket(index: s.frames.count, folder: folder), changed)
    }
    if let tooFastChanged {
      DispatchQueue.main.async { [weak self] in self?.movingTooFast = tooFastChanged }
    }
    return ticket
  }

  /// A deep copy of the camera image, so ARKit's buffer goes back to its pool straight away.
  private static func copy(_ source: CVPixelBuffer) -> CVPixelBuffer? {
    CVPixelBufferLockBaseAddress(source, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(source, .readOnly) }
    var made: CVPixelBuffer?
    let attributes = [kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any]()] as CFDictionary
    let status = CVPixelBufferCreate(
      nil, CVPixelBufferGetWidth(source), CVPixelBufferGetHeight(source),
      CVPixelBufferGetPixelFormatType(source), attributes, &made
    )
    guard status == kCVReturnSuccess, let made else { return nil }
    CVPixelBufferLockBaseAddress(made, [])
    defer { CVPixelBufferUnlockBaseAddress(made, []) }
    for plane in 0..<CVPixelBufferGetPlaneCount(source) {
      guard let from = CVPixelBufferGetBaseAddressOfPlane(source, plane),
            let to = CVPixelBufferGetBaseAddressOfPlane(made, plane) else { return nil }
      let rows = CVPixelBufferGetHeightOfPlane(source, plane)
      let fromStride = CVPixelBufferGetBytesPerRowOfPlane(source, plane)
      let toStride = CVPixelBufferGetBytesPerRowOfPlane(made, plane)
      if fromStride == toStride {
        memcpy(to, from, rows * fromStride)
      } else {
        for row in 0..<rows {
          memcpy(to + row * toStride, from + row * fromStride, min(fromStride, toStride))
        }
      }
    }
    return made
  }

  // MARK: Writer queue

  private func write(_ buffer: CVPixelBuffer, to url: URL) {
    defer { state.withLock { $0.encoding -= 1 } }
    let options = [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.9]
    guard let data = context.jpegRepresentation(of: CIImage(cvPixelBuffer: buffer), colorSpace: Self.sRGB, options: options) else {
      Self.log.error("Scan photo not encoded: \(url.lastPathComponent, privacy: .public)")
      return
    }
    do {
      try data.write(to: url)
    } catch {
      // The trainer skips frames whose photo is missing, so one lost photo doesn't spoil the scan.
      Self.log.error("Scan photo not written: \(error.localizedDescription, privacy: .public)")
      return
    }
    DispatchQueue.main.async { [weak self] in self?.photoCount += 1 }
  }

  private static func writeIndex(frames: [KeptFrame], points: [SIMD3<Float>], marker: simd_float4x4, to folder: URL) throws {
    // One marker pose for the whole scan, ARKit's latest (it refines the pose each time it sees the marker), keeps
    // the scan rigid: a per-frame pose would add the marker's jitter to every camera.
    let markerFromWorld = marker.inverse
    let index = ScanIndex(
      markerWidthM: MarkerSpec.widthMeters,
      worldFromMarker: rows(marker),
      frames: frames.map { frame in
        // simd matrices are column-major: column 2 of the intrinsics holds cx and cy.
        ScanIndex.Frame(
          filePath: frame.file,
          transformMatrix: rows(markerFromWorld * frame.cameraInWorld),
          flX: frame.intrinsics[0][0], flY: frame.intrinsics[1][1],
          cx: frame.intrinsics[2][0], cy: frame.intrinsics[2][1],
          w: frame.width, h: frame.height, time: frame.time
        )
      }
    )
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.sortedKeys]
    try encoder.encode(index).write(to: folder.appendingPathComponent("transforms.json"), options: .atomic)

    var ply = "ply\nformat ascii 1.0\nelement vertex \(points.count)\nproperty float x\nproperty float y\nproperty float z\nend_header\n"
    ply.reserveCapacity(ply.count + points.count * 32)
    for point in points {
      let p = markerFromWorld * SIMD4(point, 1)
      ply += "\(p.x) \(p.y) \(p.z)\n"
    }
    try Data(ply.utf8).write(to: folder.appendingPathComponent("points.ply"), options: .atomic)
  }

  /// Row-major, as nerfstudio's `transform_matrix` is written.
  private static func rows(_ m: simd_float4x4) -> [[Float]] {
    (0..<4).map { row in (0..<4).map { column in m[column][row] } }
  }

  private static var scansDirectory: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Scans", isDirectory: true)
  }

  private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

  private static func stamp() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(from: Date())
  }
}

/// `transforms.json`: nerfstudio's layout, so its tools can read a scan too. Poses are camera-to-marker with ARKit's
/// camera axes (+X right, +Y up, looking down −Z), which are nerfstudio's; images stay in the sensor's landscape
/// orientation, which is what the intrinsics describe.
struct ScanIndex: Encodable {
  var format = "remote-assist-scan/1"
  var frameOfReference = "marker"
  var markerWidthM: Float
  var worldFromMarker: [[Float]]
  var cameraModel = "PINHOLE"
  var plyFilePath = "points.ply"
  var frames: [Frame]

  struct Frame: Encodable {
    var filePath: String
    var transformMatrix: [[Float]]
    var flX: Float
    var flY: Float
    var cx: Float
    var cy: Float
    var w: Int
    var h: Int
    var time: Double
  }
}
