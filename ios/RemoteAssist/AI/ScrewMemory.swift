import UIKit
import simd

/// Remembers each screw as it comes out (which hole, where in the world, what it looked like), so the refit step can
/// put every one back where it came from. Laptop bottom panels often mix screw lengths, and a long screw in the wrong
/// hole can punch through to the board.
///
/// Screws are grouped by what the remove step looked for ("the eight base cover screws", "the SSD screw…"), so the
/// cover's refit step brings back the cover's holes and the SSD's brings back the SSD's.
struct ScrewMemory: Equatable {
  struct Entry: Equatable, Identifiable {
    var id: UUID
    var group: String
    var number: Int
    var label: String
    var note: String?
    /// Where the hole is in the world (+Y is the surface normal).
    var transform: simd_float4x4
    /// Where it was in the photo, for the map.
    var photoPoint: UprightPoint?
  }

  private(set) var entries: [Entry] = []
  /// The photo each group's screws were found in, downscaled, for the map card.
  private(set) var photos: [String: UIImage] = [:]
  /// Groups in the order they were first used, so a refit step with no exact match takes the latest.
  private var order: [String] = []

  var isEmpty: Bool { entries.isEmpty }

  mutating func remember(_ pin: ARSessionController.PinInfo, group: String, note: String?, photo: CGImage?) {
    guard !entries.contains(where: { $0.id == pin.id }) else { return }
    if !order.contains(group) { order.append(group) }
    if photos[group] == nil, let photo {
      photos[group] = Self.downscaled(photo, maxSide: 900)
    }
    entries.append(Entry(id: pin.id, group: group, number: pin.number, label: pin.label, note: note, transform: pin.transform, photoPoint: pin.photoPoint))
    entries.sort { $0.number < $1.number }
  }

  mutating func forget(_ id: UUID) {
    entries.removeAll { $0.id == id }
  }

  mutating func reset() {
    entries = []
    photos = [:]
    order = []
  }

  /// The group a refit step should bring back: the one it names, else the most recent.
  func group(for lookFor: String?) -> String? {
    if let lookFor, entries.contains(where: { $0.group == lookFor }) { return lookFor }
    return order.last { name in entries.contains { $0.group == name } }
  }

  func entries(in group: String) -> [Entry] {
    entries.filter { $0.group == group }
  }

  private static func downscaled(_ image: CGImage, maxSide: CGFloat) -> UIImage {
    let size = CGSize(width: image.width, height: image.height)
    let scale = min(1, maxSide / max(size.width, size.height))
    let target = CGSize(width: size.width * scale, height: size.height * scale)
    return UIGraphicsImageRenderer(size: target).image { _ in
      UIImage(cgImage: image).draw(in: CGRect(origin: .zero, size: target))
    }
  }
}
