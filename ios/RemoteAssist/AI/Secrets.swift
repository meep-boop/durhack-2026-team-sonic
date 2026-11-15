import Foundation

/// Keys come from the git-ignored ios/Secrets.xcconfig through Info.plist. An empty value means "feature off".
enum Secrets {
  static func value(_ key: String) -> String? {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    // An unset build setting arrives as an empty string or the literal $(NAME).
    return trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : trimmed
  }
}
