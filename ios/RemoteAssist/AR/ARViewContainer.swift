import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
  let controller: ARSessionController

  func makeUIView(context: Context) -> ARView {
    controller.start()
    return controller.arView
  }

  func updateUIView(_ uiView: ARView, context: Context) {}

  static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
    uiView.session.pause()
  }
}
