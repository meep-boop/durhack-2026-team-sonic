import CoreGraphics
import Foundation
import Observation
import UIKit

/// Looks at the laptop through the camera with Gemini, works out the SSD swap, and checks each step.
/// Everything it says is labelled AI-generated in the UI, and it refuses to guide when the swap looks unsafe.
@Observable
final class LaptopAssistant {
  struct Identification: Codable, Equatable {
    var isLaptop: Bool
    var make: String
    var model: String
    var confidence: Double
    var ssdUserReplaceable: String  // "yes" | "no" | "unknown"
    var ssdFormFactor: String
    var warnings: [String]
    var tools: [String]
  }

  struct PlannedStep: Codable, Equatable {
    var title: String
    var detail: String
    /// What the camera should look for to point at this step, e.g. "the screws on the bottom panel".
    var lookFor: String
    var caution: String?
    /// "remove" (taking screws or parts out), "refit" (putting them back) or "other". Drives screw memory and which
    /// way the ghost screwdriver turns. Optional so a plan without it still decodes.
    var phase: String?
  }

  /// One part found in the photo, as an upright point.
  struct LocatedItem: Equatable {
    var point: UprightPoint
    var label: String
    /// Set when this one differs from the rest, e.g. "longer screw".
    var note: String?
  }

  struct Located: Equatable {
    var items: [LocatedItem]
    /// The four corners of the area to work on (upright points, clockwise from top-left), if the AI gave one.
    var focus: [UprightPoint]?
    var focusLabel: String
  }

  /// "yes" | "no" | "unknown" for each, judged only from the photo.
  struct SafetyCheck: Codable, Equatable {
    var chargerUnplugged: String
    var poweredOff: String
    var laptopUpsideDown: String
    var onSoftSurface: String
    var issues: [String]

    var allClear: Bool { [chargerUnplugged, poweredOff, laptopUpsideDown, onSoftSurface].allSatisfy { $0 == "yes" } }
  }

  struct Check: Codable, Equatable {
    var done: Bool
    var confidence: Double
    var feedback: String
  }

  enum Phase: Equatable {
    case idle, working(String), identified, failed(String)
  }

  private(set) var phase: Phase = .idle
  private(set) var identification: Identification?
  private(set) var plan: [PlannedStep] = []
  private(set) var lastCheck: Check?
  private(set) var safety: SafetyCheck?
  /// True when the user started despite the AI not seeing everything as safe (they confirmed they'd checked).
  private(set) var safetyOverridden = false

  var isAvailable: Bool { client != nil }
  private let client = GeminiClient.fromBundle()

  // MARK: Identify and plan

  func identify(jpeg: Data) async {
    guard let client else { return }
    phase = .working("Looking at your laptop…")
    do {
      let found = try await client.generate(
        Identification.self,
        prompt: """
        You help a nervous, non-technical person replace the SSD in their own laptop. Look at the photo.
        Identify the laptop as precisely as you honestly can (make and model family; say "Unknown" rather than guess).
        confidence is 0 to 1 for the identification. ssdUserReplaceable is "yes", "no" (soldered storage, e.g. most
        MacBooks since 2016), or "unknown". ssdFormFactor e.g. "M.2 2280 NVMe", "2.5-inch SATA", "soldered", "unknown".
        warnings: short, concrete safety notes (unplug the charger, battery, static, warranty). tools: what they need.
        If the photo does not show a laptop, set isLaptop false.
        """,
        jpeg: jpeg,
        schema: Self.identificationSchema
      )
      identification = found
      guard found.isLaptop else {
        phase = .failed("I can't see a laptop. Point the camera at the whole laptop and try again.")
        return
      }
      phase = .working("Planning the steps…")
      plan = try await client.generate(
        PlanEnvelope.self,
        prompt: """
        Write the step-by-step procedure to replace the SSD in this laptop: \(found.make) \(found.model),
        SSD form factor \(found.ssdFormFactor). The reader has never opened a computer. 8 to 12 steps, each one
        physical action, in order: shut down and unplug, discharge static, flip onto a soft cloth, remove the bottom
        panel screws (say how many and where if you know this model), lift the panel from a safe edge, disconnect the
        battery if this model needs it, find the SSD, remove its retaining screw, slide it out at about 30 degrees,
        insert the new one, refit the screw, reassemble, power on and check it's detected. title is at most 6 words.
        detail is 1 to 2 plain sentences. lookFor names the part to point at for that step. caution only when there's a
        real risk. phase is "remove" for a step that takes screws or parts out, "refit" for one that puts them back,
        otherwise "other".
        """,
        jpeg: nil,
        schema: Self.planSchema
      ).steps
      phase = .identified
    } catch {
      phase = .failed(error.localizedDescription)
    }
  }

  /// The plan as a guide the normal player can walk. It has no marker-frame objects: pins come from `locate`.
  func guide() -> Guide? {
    guard let identification, !plan.isEmpty else { return nil }
    return Guide(
      id: "ai-ssd-\(UUID().uuidString.prefix(8).lowercased())",
      rev: 1,
      title: "Replace the SSD · \(identification.make) \(identification.model)",
      marker: Marker(name: MarkerSpec.imageName, width: MarkerSpec.widthMeters, height: MarkerSpec.widthMeters),
      steps: plan.enumerated().map { index, step in
        let caution = step.caution.map { "\n⚠️ \($0)" } ?? ""
        return Step(id: "ai\(index + 1)", text: "\(step.title)\n\(step.detail)\(caution)", objects: [])
      }
    )
  }

  func lookFor(stepIndex: Int) -> String? {
    plan.indices.contains(stepIndex) ? plan[stepIndex].lookFor : nil
  }

  // MARK: Point and check

  func phase(stepIndex: Int) -> String? {
    plan.indices.contains(stepIndex) ? plan[stepIndex].phase : nil
  }

  /// Finds every `target` in the photo in two passes.
  /// - Pass 1, whole photo: a box per part plus the area to work on, in Gemini's own `box_2d` format.
  /// - Pass 2, small parts only (screws): a zoomed crop around each box, asking for the exact centre. At 1536 px a
  ///   laptop screw is a handful of pixels; in a 256 px crop it fills the frame.
  func locate(_ target: String, step: String, snapshot: ARSessionController.Snapshot) async throws -> Located {
    guard let client else { return Located(items: [], focus: nil, focusLabel: "") }
    let found = try await client.generate(
      LocateEnvelope.self,
      prompt: """
      This photo shows a laptop. The person is doing this step: "\(step)".
      Find every \(target) you can actually see. One item per individual part (one per screw), up to 16.
      box_2d is [ymin, xmin, ymax, xmax], each normalised to 0-1000 over the image height and width. label is 1 to 3
      words. note only when this part differs from the others (for example "longer screw" or "under a rubber foot").
      focus is the box around the whole area the person should work on for this step (for example the bottom panel).
      If you can't see any, return an empty list. Never invent a part.
      """,
      jpeg: snapshot.jpeg,
      schema: Self.locateSchema
    )

    let imageSize = CGSize(width: snapshot.image.width, height: snapshot.image.height)
    let boxes = found.items.prefix(16).compactMap { item in PinMath.rect(fromBox2D: item.box_2d).map { (item, $0) } }

    var items: [LocatedItem] = Array(repeating: LocatedItem(point: .zero, label: ""), count: boxes.count)
    // Four crops at a time: quick, without tripping Gemini's rate limit.
    for chunk in stride(from: 0, to: boxes.count, by: 4) {
      try await withThrowingTaskGroup(of: (Int, LocatedItem).self) { group in
        for index in chunk..<min(chunk + 4, boxes.count) {
          let (item, rect) = boxes[index]
          group.addTask {
            let centre = CGPoint(x: rect.midX, y: rect.midY)
            var located = LocatedItem(point: centre, label: item.label, note: item.note)
            if max(rect.width, rect.height) < 0.12,
               let refined = try? await self.refine(item.label, box: rect, image: snapshot.image, imageSize: imageSize, client: client) {
              located.point = refined
            }
            return (index, located)
          }
        }
        for try await (index, item) in group { items[index] = item }
      }
    }

    let focusRect = found.focus.flatMap { PinMath.rect(fromBox2D: $0.box_2d) }
    let corners = focusRect.map { r in
      [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
    }
    return Located(items: items, focus: corners, focusLabel: found.focus?.label ?? "Work here")
  }

  private func refine(_ label: String, box: CGRect, image: CGImage, imageSize: CGSize, client: GeminiClient) async throws -> UprightPoint? {
    let crop = PinMath.cropRect(around: box, imageSize: imageSize)
    guard let cropped = image.cropping(to: crop), let jpeg = UIImage(cgImage: cropped).jpegData(compressionQuality: 0.9) else { return nil }
    let answer = try await client.generate(
      RefineEnvelope.self,
      prompt: """
      This is a zoomed-in crop of a laptop around one \(label). Find that \(label).
      point is [y, x], normalised to 0-1000 over this crop's height and width, at its exact centre (for a screw, the
      centre of its head). If it isn't in the crop, set found to false.
      """,
      jpeg: jpeg,
      schema: Self.refineSchema
    )
    guard answer.found else { return nil }
    return PinMath.point(fromCropPoint: answer.point, crop: crop, imageSize: imageSize)
  }

  /// Before the first step: is it safe to open this laptop now? Judged only from what the photo shows.
  func checkSafety(jpeg: Data) async {
    guard let client else { return }
    safety = nil
    safetyOverridden = false
    safety = try? await client.generate(
      SafetyCheck.self,
      prompt: """
      Someone is about to open this laptop to replace its SSD. Judge only from this photo, answering "yes", "no" or
      "unknown" for each. chargerUnplugged: no charging cable is plugged into the laptop. poweredOff: the laptop is
      off (no lit screen, power or keyboard lights). laptopUpsideDown: the underside is facing up. onSoftSurface: it
      lies on a cloth, towel or mat, not bare metal or carpet. issues: short, specific things to fix before starting.
      Say "unknown" rather than guess.
      """,
      jpeg: jpeg,
      schema: Self.safetySchema
    )
  }

  /// The user confirmed they checked themselves, after the AI couldn't see everything as safe.
  func overrideSafety() {
    safetyOverridden = true
  }

  func check(step: String, jpeg: Data) async {
    guard let client else { return }
    lastCheck = nil
    do {
      lastCheck = try await client.generate(
        Check.self,
        prompt: """
        The person was asked to do this step: "\(step)". Look at the photo and judge only what is visible.
        done is true only if the photo clearly shows the step finished. confidence is 0 to 1. feedback is one short,
        kind, specific sentence: what looks right, or exactly what to fix. If the photo can't show it, say so.
        """,
        jpeg: jpeg,
        schema: Self.checkSchema
      )
    } catch {
      lastCheck = Check(done: false, confidence: 0, feedback: "Couldn't check: \(error.localizedDescription)")
    }
  }

  func reset() {
    phase = .idle
    identification = nil
    plan = []
    lastCheck = nil
    safety = nil
    safetyOverridden = false
  }

  // MARK: Schemas

  private struct PlanEnvelope: Codable { var steps: [PlannedStep] }
  private struct LocateEnvelope: Codable {
    struct Item: Codable {
      var box_2d: [Double]
      var label: String
      var note: String?
    }
    struct Focus: Codable {
      var box_2d: [Double]
      var label: String
    }
    var items: [Item]
    var focus: Focus?
  }
  private struct RefineEnvelope: Codable {
    var found: Bool
    var point: [Double]
  }

  private static let identificationSchema: [String: Any] = [
    "type": "object",
    "properties": [
      "isLaptop": ["type": "boolean"],
      "make": ["type": "string"],
      "model": ["type": "string"],
      "confidence": ["type": "number"],
      "ssdUserReplaceable": ["type": "string", "enum": ["yes", "no", "unknown"]],
      "ssdFormFactor": ["type": "string"],
      "warnings": ["type": "array", "items": ["type": "string"]],
      "tools": ["type": "array", "items": ["type": "string"]],
    ],
    "required": ["isLaptop", "make", "model", "confidence", "ssdUserReplaceable", "ssdFormFactor", "warnings", "tools"],
  ]

  private static let planSchema: [String: Any] = [
    "type": "object",
    "properties": [
      "steps": [
        "type": "array",
        "items": [
          "type": "object",
          "properties": [
            "title": ["type": "string"],
            "detail": ["type": "string"],
            "lookFor": ["type": "string"],
            "caution": ["type": "string"],
            "phase": ["type": "string", "enum": ["remove", "refit", "other"]],
          ],
          "required": ["title", "detail", "lookFor", "phase"],
        ],
      ],
    ],
    "required": ["steps"],
  ]

  private static let box: [String: Any] = [
    "type": "array", "items": ["type": "integer"], "minItems": 4, "maxItems": 4,
  ]

  private static let locateSchema: [String: Any] = [
    "type": "object",
    "properties": [
      "items": [
        "type": "array",
        "items": [
          "type": "object",
          "properties": ["box_2d": box, "label": ["type": "string"], "note": ["type": "string"]],
          "required": ["box_2d", "label"],
        ],
      ],
      "focus": [
        "type": "object",
        "properties": ["box_2d": box, "label": ["type": "string"]],
        "required": ["box_2d", "label"],
      ],
    ],
    "required": ["items"],
  ]

  private static let refineSchema: [String: Any] = [
    "type": "object",
    "properties": [
      "found": ["type": "boolean"],
      "point": ["type": "array", "items": ["type": "integer"], "minItems": 2, "maxItems": 2],
    ],
    "required": ["found", "point"],
  ]

  private static let tri: [String: Any] = ["type": "string", "enum": ["yes", "no", "unknown"]]

  private static let safetySchema: [String: Any] = [
    "type": "object",
    "properties": [
      "chargerUnplugged": tri,
      "poweredOff": tri,
      "laptopUpsideDown": tri,
      "onSoftSurface": tri,
      "issues": ["type": "array", "items": ["type": "string"]],
    ],
    "required": ["chargerUnplugged", "poweredOff", "laptopUpsideDown", "onSoftSurface", "issues"],
  ]

  private static let checkSchema: [String: Any] = [
    "type": "object",
    "properties": [
      "done": ["type": "boolean"],
      "confidence": ["type": "number"],
      "feedback": ["type": "string"],
    ],
    "required": ["done", "confidence", "feedback"],
  ]
}
