import ARKit
import ExpoModulesCore

public class SonicArModule: Module {
  public func definition() -> ModuleDefinition {
    Name("SonicAr")

    Function("isSupported") { () -> Bool in
      ARWorldTrackingConfiguration.isSupported
    }

    Function("hasLidar") { () -> Bool in
      ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    View(SonicArView.self) {
      Events("onPlaneDetected", "onImageDetected", "onMeasure", "onError")

      Prop("mode") { (view: SonicArView, mode: String) in
        view.setMode(mode)
      }

      Prop("markerUri") { (view: SonicArView, uri: String?) in
        view.setMarker(uri: uri, width: view.markerWidth)
      }

      Prop("markerWidth") { (view: SonicArView, width: Double) in
        view.setMarker(uri: view.markerUri, width: width)
      }

      OnViewDidUpdateProps { (view: SonicArView) in
        view.applyConfigurationIfNeeded()
      }

      // ARSession and RealityKit scene changes must happen on the main thread.
      AsyncFunction("reset") { (view: SonicArView) in
        view.reset()
      }.runOnQueue(.main)
    }
  }
}
