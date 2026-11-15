import SwiftUI
import UIKit

/// Black and white with one purple accent (Salman, 2026-11-15). Purple marks what to look at or press; green and red
/// only ever mean done and wrong.
enum Theme {
  /// #8B5CF6
  static let accentUI = UIColor(red: 0x8B / 255, green: 0x5C / 255, blue: 0xF6 / 255, alpha: 1)
  /// #C4B5FD, for screws going back in: the same family, clearly not "find this".
  static let accentSoftUI = UIColor(red: 0xC4 / 255, green: 0xB5 / 255, blue: 0xFD / 255, alpha: 1)

  static let accent = Color(uiColor: accentUI)
  static let accentSoft = Color(uiColor: accentSoftUI)
}
