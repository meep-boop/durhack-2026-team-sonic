import SwiftUI

struct ARViewContainer: UIViewRepresentable {
  let controller: ARSessionController

  /// SwiftUI owns the host; the controller owns the AR view inside it and may replace it at any time.
  func makeUIView(context: Context) -> CameraHost {
    let host = CameraHost()
    controller.attach(to: host)
    return host
  }

  func updateUIView(_ uiView: CameraHost, context: Context) {}

  // No dismantleUIView: pausing the session here, behind the controller's back, left it thinking it was running, so
  // nothing ever restarted the camera. The controller alone starts, pauses and resumes it.
}
