import Foundation

/// Step lists checked against the maker's own service manual, used instead of Gemini's plan when the AI recognises
/// the laptop. The demo laptop is Ahmed's Dell Latitude 5530; its steps come from the team's research, `research/ledger.md`
/// § 17 (context branch, 2026-11-15), which read Dell's service manual:
/// - Before working inside: https://www.dell.com/support/manuals/en-us/latitude-15-5530-laptop/latitude_5530_sm/before-working-inside-your-computer
/// - Removing the base cover (eight captive screws, scribe): …/latitude_5530_sm/removing-the-base-cover
/// - Screw list (#0 Phillips): …/latitude_5530_sm/screw-list
/// - Removing the M.2 2280 SSD (one M2x4, or a bracket with two M2x3): …/latitude_5530_sm/removing-the-m2-2280-solid-state-drive
/// Laura then checked the steps on the laptop itself (no bracket, one screw), and that check wins.
/// Gemini still finds the parts on camera and checks the work; it just doesn't write these steps.
enum VerifiedProcedures {
  struct Procedure {
    /// Shown on the step card and in the report, e.g. "Dell's service manual".
    var source: String
    /// The base cover's screws stay in the cover when loosened.
    var captiveScrews: Bool
    /// Told to the locator so it looks for the right number of screws.
    var locateHint: String
    var steps: [LaptopAssistant.PlannedStep]
  }

  static func match(_ id: LaptopAssistant.Identification) -> Procedure? {
    let make = id.make.lowercased(), model = id.model.lowercased()
    if make.contains("dell") && model.contains("5530") { return latitude5530 }
    return nil
  }

  private static let coverScrews = "the eight base cover screws"
  private static let ssdScrew = "the screw that holds the SSD"

  /// Laura's list, checked on Ahmed's laptop (progress.md 2026-11-15 02:11, ledger § 17): 8 captive screws on the base
  /// cover, no bracket over the SSD, one screw on it. Same SSD out and back in.
  static let latitude5530 = Procedure(
    source: "Dell's service manual, checked on the demo laptop",
    captiveScrews: true,
    locateHint: "This is a Dell Latitude 5530: its base cover has eight captive screws.",
    steps: [
      step("Shut down and unplug", "Save your work, shut down, and unplug the charger and anything else.", "the charger port"),
      step("Enter Service Mode", "Hold B and press the power button for 3 seconds. After 3 beeps it switches off in Service Mode, with the power cut.", "the power button",
           caution: "If it won't beep three times, ask the expert before going on."),
      step("Turn it face down", "Close the lid and lay the laptop face down (in the board's corner stops, if you're using the board).", "the base cover"),
      step("Loosen the 8 screws", "Loosen the 8 screws on the base cover with a #0 Phillips. They stay in the cover.", coverScrews, phase: "remove"),
      step("Lift at the notches", "Lift the cover at the U-shaped notches on the top edge with a plastic pry tool.", "the U-shaped notches on the top edge",
           caution: "Plastic only: a metal tool scratches the case and can short the board."),
      step("Lift the cover off", "Hold the left and right sides and lift the cover off.", "the base cover edges"),
      step("Undo the SSD screw", "Undo the one screw that holds the SSD.", ssdScrew, phase: "remove"),
      step("Slide the SSD out", "Slide the SSD out of its slot at an angle.", "the M.2 SSD"),
      step("Slide it back in", "Slide the same SSD back in at the same angle and press it flat.", "the M.2 slot"),
      step("Put the SSD screw back", "Put the SSD's screw back.", ssdScrew, phase: "refit"),
      step("Cover on, 8 screws in", "Snap the cover back on and tighten the 8 screws.", coverScrews, phase: "refit"),
      step("Power on", "Plug the charger in (this ends Service Mode), then turn the laptop on.", "the charger port"),
    ]
  )

  private static func step(_ title: String, _ detail: String, _ lookFor: String, caution: String? = nil, phase: String = "other") -> LaptopAssistant.PlannedStep {
    LaptopAssistant.PlannedStep(title: title, detail: detail, lookFor: lookFor, caution: caution, phase: phase)
  }
}
