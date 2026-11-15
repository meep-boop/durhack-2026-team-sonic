import Foundation

/// On-device switches that put back one thing at a time from the build where the camera froze, read at launch.
/// If the camera ever freezes again, flip one per launch to find which one does it. All off is the safe setup.
enum CameraLab {
  static var delegateOffMain: Bool {
    get { UserDefaults.standard.bool(forKey: "lab.delegateOffMain") }
    set { UserDefaults.standard.set(newValue, forKey: "lab.delegateOffMain") }
  }

  static var planesAlways: Bool {
    get { UserDefaults.standard.bool(forKey: "lab.planesAlways") }
    set { UserDefaults.standard.set(newValue, forKey: "lab.planesAlways") }
  }

  static var overlaysOff: Bool {
    get { UserDefaults.standard.bool(forKey: "lab.overlaysOff") }
    set { UserDefaults.standard.set(newValue, forKey: "lab.overlaysOff") }
  }

  static var summary: String {
    let on = [("delegate-off-main", delegateOffMain), ("planes-always", planesAlways), ("overlays-off", overlaysOff)]
      .filter(\.1).map(\.0)
    return on.isEmpty ? "safe defaults" : on.joined(separator: ", ")
  }
}
