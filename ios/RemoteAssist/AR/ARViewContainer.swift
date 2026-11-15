import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
  let controller: ARSessionController

  /// The session is started by ContentView once onboarding is closed, so the camera prompt isn't hidden under it.
  func makeUIView(context: Context) -> ARView {
    controller.arView
  }

  func updateUIView(_ uiView: ARView, context: Context) {}

  static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
    uiView.session.pause()
  }
}
