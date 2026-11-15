import CoreGraphics
import Foundation

/// Where each part of the laptop is, in millimetres from the top-left corner of the base cover (x along the top
/// edge with the U-shaped notches, y down the cover). Keyed by a step's `lookFor`, so each step knows what to light up.
///
/// Only what we really know is built in: the cover's footprint (Dell's spec) and the notch strip along the top edge
/// (Laura's check). Screw and SSD positions are never guessed: they're taught once by tapping them on the real laptop
/// ("Teach positions"), saved on the phone, and can be shared so the team bundles them with the app.
struct LaptopLayout: Codable, Equatable {
  struct Zone: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var corners: [CGPoint] {
      [CGPoint(x: x, y: y), CGPoint(x: x + width, y: y), CGPoint(x: x + width, y: y + height), CGPoint(x: x, y: y + height)]
    }
  }

  struct Part: Codable, Equatable {
    var points: [CGPoint] = []
    var zone: Zone?
  }

  var device: String
  /// Millimetres.
  var width: Double
  var height: Double
  var parts: [String: Part]

  var footprintMetres: SIMD2<Float> { SIMD2(Float(width / 1000), Float(height / 1000)) }

  func part(for lookFor: String?) -> Part? {
    lookFor.flatMap { parts[$0] }
  }

  /// Whether this part's positions have been taught yet (zones alone don't count).
  func isTaught(_ lookFor: String?) -> Bool {
    !(part(for: lookFor)?.points.isEmpty ?? true)
  }

  mutating func teach(_ point: CGPoint, for lookFor: String) {
    parts[lookFor, default: Part()].points.append(point)
  }

  mutating func undoLast(for lookFor: String) {
    guard parts[lookFor]?.points.isEmpty == false else { return }
    parts[lookFor]?.points.removeLast()
  }

  mutating func clear(_ lookFor: String) {
    parts[lookFor]?.points = []
  }

  // MARK: Built in, saved, bundled

  /// Dell Latitude 5530: 357.8 × 233.3 mm (Dell's spec). The notches sit along the top edge (Laura, 2026-11-15).
  static func dellLatitude5530() -> LaptopLayout {
    let full = Zone(x: 0, y: 0, width: 357.8, height: 233.3)
    return LaptopLayout(
      device: "Dell Latitude 5530",
      width: 357.8,
      height: 233.3,
      parts: [
        "the base cover": Part(zone: full),
        "the base cover edges": Part(zone: full),
        "the eight base cover screws": Part(zone: full),
        "the U-shaped notches on the top edge": Part(zone: Zone(x: 0, y: 0, width: 357.8, height: 15)),
      ]
    )
  }

  private static let file = "laptop-layout"
  private static let bundledName = "dell-latitude-5530-layout"

  /// What the user taught on this phone, else a layout the team bundled with the app, else the built-in one.
  static func load() -> LaptopLayout {
    if let saved = Persistence.load(LaptopLayout.self, from: file) { return saved }
    if let url = Bundle.main.url(forResource: bundledName, withExtension: "json"),
       let data = try? Data(contentsOf: url),
       let bundled = try? JSONDecoder().decode(LaptopLayout.self, from: data) { return bundled }
    return dellLatitude5530()
  }

  func save() {
    Persistence.save(self, as: Self.file)
  }

  /// Pretty JSON in a temporary file, to share with the team (they can bundle it as `dell-latitude-5530-layout.json`).
  func exportFile() -> URL? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(self) else { return nil }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(Self.bundledName).json")
    return (try? data.write(to: url, options: .atomic)) == nil ? nil : url
  }
}
