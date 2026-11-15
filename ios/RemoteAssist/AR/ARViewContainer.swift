import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
  let controller: ARSessionController

  /// The session is started by ContentView once onboarding is closed, so the camera prompt isn't hidden under it.
  func makeUIView(context: Context) -> ARView {
    controller.ensureRunning()
    return controller.arView
  }

  func updateUIView(_ uiView: ARView, context: Context) {}

  // No dismantleUIView: pausing the session here, behind the controller's back, left it thinking it was running, so
  // nothing ever restarted the camera. The controller alone starts, pauses and resumes it.
}
