import UIKit

/// A one-file record of the repair: what was fixed, when each step was done, what the AI and the rig said, and a
/// photo at the end. Shareable as a PDF, for the customer, the expert or the warranty desk.
enum RepairReport {
  struct StepLine {
    var number: Int
    var text: String
    var doneAt: Date?
    var rig: StepVerified?
    var aiCheck: LaptopAssistant.Check?
  }

  struct Input {
    var title: String
    var device: String?
    var deviceConfidence: Double?
    var startedAt: Date
    var finishedAt: Date
    var steps: [StepLine]
    var safety: LaptopAssistant.SafetyCheck?
    var safetyOverridden: Bool
    var aiGenerated: Bool
    var photo: UIImage?
    var stepSource: String? = nil
    var transcript: [TranscriptLine] = []
  }

  /// Writes the PDF to a temporary file and returns its URL.
  static func render(_ input: Input) throws -> URL {
    let page = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4 in points
    let margin: CGFloat = 48
    let width = page.width - margin * 2
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Repair report.pdf")

    let data = UIGraphicsPDFRenderer(bounds: page).pdfData { context in
      var y = margin
      context.beginPage()

      func ensure(_ height: CGFloat) {
        if y + height > page.height - margin {
          context.beginPage()
          y = margin
        }
      }
      func write(_ text: String, _ font: UIFont, _ color: UIColor = .black, gap: CGFloat = 6) {
        let attributed = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
        let height = attributed.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil).height.rounded(.up)
        ensure(height)
        attributed.draw(with: CGRect(x: margin, y: y, width: width, height: height), options: [.usesLineFragmentOrigin], context: nil)
        y += height + gap
      }

      let time = Date.FormatStyle(date: .omitted, time: .shortened)
      write("Repair report", .systemFont(ofSize: 26, weight: .bold), gap: 4)
      write(input.title, .systemFont(ofSize: 15, weight: .semibold), .darkGray)
      if let device = input.device {
        let confidence = input.deviceConfidence.map { " (AI identification, \(Int(($0 * 100).rounded()))% sure)" } ?? ""
        write("Device: \(device)\(confidence)", .systemFont(ofSize: 12))
      }
      let minutes = max(1, Int(input.finishedAt.timeIntervalSince(input.startedAt) / 60))
      write("\(input.startedAt.formatted(date: .abbreviated, time: .shortened)) to \(input.finishedAt.formatted(time)) · \(minutes) min", .systemFont(ofSize: 12), gap: 14)

      if let safety = input.safety {
        write("Safety check before starting", .systemFont(ofSize: 14, weight: .semibold))
        let rows = [("Charger unplugged", safety.chargerUnplugged), ("Switched off", safety.poweredOff),
                    ("Upside down", safety.laptopUpsideDown), ("On a soft surface", safety.onSoftSurface)]
        write(rows.map { "\($0.0): \($0.1)" }.joined(separator: " · "), .systemFont(ofSize: 11))
        if input.safetyOverridden {
          write("The user confirmed they had checked themselves where the AI couldn't tell.", .italicSystemFont(ofSize: 11), .darkGray)
        }
        y += 8
      }

      write(input.stepSource.map { "Steps · \($0)" } ?? "Steps", .systemFont(ofSize: 14, weight: .semibold))
      for step in input.steps {
        let done = step.doneAt.map { "done \($0.formatted(time))" } ?? "not done"
        write("\(step.number). \(step.text.replacingOccurrences(of: "\n", with: " · "))", .systemFont(ofSize: 11), gap: 2)
        var notes = [done]
        // The relay doesn't authenticate senders, so the rig's verdict is reported as what arrived, not as proof.
        if let rig = step.rig { notes.append(rig.ok ? "rig (via relay): correct" : "rig (via relay): \(rig.detail ?? "not right")") }
        if let check = step.aiCheck { notes.append("AI check: \(check.done ? "looks done" : "not yet") (\(check.feedback))") }
        write(notes.joined(separator: " · "), .systemFont(ofSize: 10), .darkGray, gap: 8)
      }

      if let photo = input.photo {
        let scale = min(width / photo.size.width, 300 / photo.size.height)
        let size = CGSize(width: photo.size.width * scale, height: photo.size.height * scale)
        ensure(size.height + 30)
        y += 6
        write("At the end", .systemFont(ofSize: 14, weight: .semibold))
        photo.draw(in: CGRect(x: margin, y: y, width: size.width, height: size.height))
        y += size.height + 12
      }

      if !input.transcript.isEmpty {
        y += 6
        write("Call with the expert (transcribed live by ElevenLabs)", .systemFont(ofSize: 14, weight: .semibold))
        for line in input.transcript {
          write("\(line.at.formatted(time))  \(line.speaker == .expert ? "Expert" : "On-site"): \(line.text)", .systemFont(ofSize: 10), gap: 3)
        }
        y += 6
      }

      if input.aiGenerated {
        write("Steps, identification and checks were generated by AI (Google Gemini) from camera photos. They are guidance, not a guarantee.", .italicSystemFont(ofSize: 9), .gray)
      }
      write("Made with Remote Assist · Team Sonic, DurHack 2026", .systemFont(ofSize: 9), .gray)
    }
    try data.write(to: url, options: .atomic)
    return url
  }
}
