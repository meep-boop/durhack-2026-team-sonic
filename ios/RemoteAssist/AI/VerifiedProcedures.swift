import Foundation

/// Step lists checked against the maker's own service manual, used instead of Gemini's plan when the AI recognises
/// the laptop. The demo laptop is Ahmed's Dell Latitude 5530; its steps come from the team's research, `research/ledger.md`
/// § 17 (context branch, 2026-11-15), which read Dell's service manual:
/// - Before working inside: https://www.dell.com/support/manuals/en-us/latitude-15-5530-laptop/latitude_5530_sm/before-working-inside-your-computer
/// - Removing the base cover (eight captive screws, scribe): …/latitude_5530_sm/removing-the-base-cover
/// - Screw list (#0 Phillips): …/latitude_5530_sm/screw-list
/// - Removing the M.2 2280 SSD (M2x4, or bracket with two M2x3): …/latitude_5530_sm/removing-the-m2-2280-solid-state-drive
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
  private static let ssdScrews = "the SSD screw or bracket screws"

  static let latitude5530 = Procedure(
    source: "Dell's service manual",
    captiveScrews: true,
    locateHint: "This is a Dell Latitude 5530: its base cover has eight captive screws.",
    steps: [
      step("Shut down and unplug", "Save your work, shut the laptop down, and unplug the charger and anything else connected.", "the charger port"),
      step("Enter Service Mode", "Hold the B key and press the power button for 3 seconds, until the Dell logo. It beeps three times and switches off: the battery is now cut off.", "the power button",
           caution: "If it won't enter Service Mode, ask the expert: the battery cable has to be disconnected instead."),
      step("Take out the SIM and microSD", "Remove the SIM card tray and the microSD card, if either is fitted.", "the SIM and microSD card slots"),
      step("Turn it over", "Close the lid and lay the laptop upside down on a soft cloth, base cover facing you.", "the base cover"),
      step("Loosen the eight screws", "With a #0 Phillips screwdriver, loosen all eight base cover screws. They stay in the cover: turn each until it's free.", coverScrews, phase: "remove"),
      step("Release the top edge", "Put a plastic scribe in the U-shaped indents along the top edge and gently pry the cover up.", "the U-shaped indents on the top edge",
           caution: "Use plastic, not metal: a metal tool scratches the case and can short the board."),
      step("Lift the cover off", "Lift the base cover away by its left and right sides.", "the base cover edges"),
      step("Check how the SSD is held", "Find the M.2 SSD. Is it held by one small screw (M2x4), or by a metal bracket with two screws (M2x3)?", "the M.2 SSD"),
      step("Undo the SSD screws", "Remove the one M2x4 screw, or the two M2x3 screws and lift the bracket off. If the bracket's thermal pad comes loose, stick it back on.", ssdScrews, phase: "remove"),
      step("Slide the SSD out", "Slide the SSD out of its slot at an angle.", "the M.2 SSD"),
      step("Slide it back in", "Slide the same SSD back into its slot at an angle, then press it down flat.", "the M.2 slot"),
      step("Refit the SSD screws", "Put back the bracket and its two M2x3 screws, or the one M2x4 screw.", ssdScrews, phase: "refit"),
      step("Refit the base cover", "Line the cover up with the screw holes and press around the edges until it snaps into place.", "the base cover"),
      step("Tighten the eight screws", "Tighten all eight captive screws with the #0 Phillips screwdriver.", coverScrews, phase: "refit"),
      step("Power on and check", "Connect the charger (that ends Service Mode), switch on, and check the SSD is detected.", "the power button"),
    ]
  )

  private static func step(_ title: String, _ detail: String, _ lookFor: String, caution: String? = nil, phase: String = "other") -> LaptopAssistant.PlannedStep {
    LaptopAssistant.PlannedStep(title: title, detail: detail, lookFor: lookFor, caution: caution, phase: phase)
  }
}
