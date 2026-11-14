import CoreGraphics
import Foundation
import Observation

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
  }

  struct Point: Codable, Equatable {
    var x: Double
    var y: Double
    var label: String
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
        real risk.
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

  /// Points in the photo as fractions (0–1) of its width and height, top-left origin.
  func locate(_ target: String, jpeg: Data) async throws -> [Point] {
    guard let client else { return [] }
    let found = try await client.generate(
      PointsEnvelope.self,
      prompt: """
      In this photo of a laptop, find: \(target). Return up to 6 points, one per item (for example one per screw).
      x and y are integers from 0 to 1000: x across the image width from the left, y down the image height from the
      top. label is 1 to 3 words. If you can't see it, return an empty list. Never invent a point.
      """,
      jpeg: jpeg,
      schema: Self.pointsSchema
    )
    return found.points.map { Point(x: $0.x / 1000, y: $0.y / 1000, label: $0.label) }
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
  }

  // MARK: Schemas

  private struct PlanEnvelope: Codable { var steps: [PlannedStep] }
  private struct PointsEnvelope: Codable { var points: [Point] }

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
          ],
          "required": ["title", "detail", "lookFor"],
        ],
      ],
    ],
    "required": ["steps"],
  ]

  private static let pointsSchema: [String: Any] = [
    "type": "object",
    "properties": [
      "points": [
        "type": "array",
        "items": [
          "type": "object",
          "properties": ["x": ["type": "number"], "y": ["type": "number"], "label": ["type": "string"]],
          "required": ["x", "y", "label"],
        ],
      ],
    ],
    "required": ["points"],
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
