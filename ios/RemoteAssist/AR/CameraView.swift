import RealityKit
import UIKit

/// The AR view, plus one log line whenever UIKit does something to it that can make RealityKit rebuild its renderer:
/// leaving or entering a window, a size change, a trait change. The line just before a "Could not resolve material"
/// block in a device log then names what set it off.
final class CameraView: ARView {
  private var loggedSize: CGSize = .zero
  private var watchingTraits = false

  override func didMoveToWindow() {
    super.didMoveToWindow()
    ARSessionController.log.notice("Camera view: \(self.window == nil ? "left" : "entered", privacy: .public) the window")
    guard !watchingTraits else { return }
    watchingTraits = true
    registerForTraitChanges([UITraitDisplayScale.self, UITraitUserInterfaceLevel.self, UITraitUserInterfaceStyle.self]) {
      (view: CameraView, previous: UITraitCollection) in
      let now = view.traitCollection
      ARSessionController.log.notice(
        "Camera view: traits changed (scale \(previous.displayScale, privacy: .public)→\(now.displayScale, privacy: .public), level \(previous.userInterfaceLevel.rawValue, privacy: .public)→\(now.userInterfaceLevel.rawValue, privacy: .public), style \(previous.userInterfaceStyle.rawValue, privacy: .public)→\(now.userInterfaceStyle.rawValue, privacy: .public))"
      )
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard bounds.size != loggedSize else { return }
    ARSessionController.log.notice(
      "Camera view: size \(Int(self.loggedSize.width), privacy: .public)×\(Int(self.loggedSize.height), privacy: .public) → \(Int(self.bounds.width), privacy: .public)×\(Int(self.bounds.height), privacy: .public)"
    )
    loggedSize = bounds.size
  }
}

/// What SwiftUI holds instead of the AR view itself, so the controller can swap in a fresh AR view (when the old one
/// stops drawing) without SwiftUI noticing. Every subview always fills it.
final class CameraHost: UIView {
  override func layoutSubviews() {
    super.layoutSubviews()
    for view in subviews { view.frame = bounds }
  }
}
