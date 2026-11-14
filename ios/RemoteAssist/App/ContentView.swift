import SwiftUI
import UIKit

struct ContentView: View {
  @State var player: GuidePlayer
  @State private var ar = ARSessionController()

  var body: some View {
    ZStack {
      ARViewContainer(controller: ar)
        .ignoresSafeArea()

      VStack(spacing: 12) {
        StatusPill(ar: ar, guideMarker: player.guide.marker)
        Spacer()
        StepPanel(player: player, markerSeen: ar.markerSeen)
      }
      .padding()
    }
    .onAppear { ar.step = player.currentStep }
    .onChange(of: player.currentStepId) { ar.step = player.currentStep }
  }
}

private struct StatusPill: View {
  let ar: ARSessionController
  let guideMarker: Marker

  private var widthMismatch: Bool { abs(guideMarker.width - MarkerSpec.widthMeters) > 0.001 }

  var body: some View {
    VStack(spacing: 4) {
      HStack(spacing: 8) {
        Circle()
          .fill(ar.markerTracked ? .green : (ar.markerSeen ? .orange : .gray))
          .frame(width: 10, height: 10)
        Text(statusText).font(.subheadline.weight(.semibold))
        Text("iOS \(UIDevice.current.systemVersion)").font(.caption).foregroundStyle(.secondary)
      }
      if let error = ar.errorMessage {
        Text(error).font(.caption).foregroundStyle(.red)
      }
      if widthMismatch {
        Text("Guide expects a \(Int(guideMarker.width * 100)) cm marker; app is set to \(Int(MarkerSpec.widthMeters * 100)) cm")
          .font(.caption)
          .foregroundStyle(.yellow)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial, in: Capsule())
  }

  private var statusText: String {
    if ar.markerTracked { return "Marker tracked" }
    if ar.markerSeen { return "Marker out of view (holding)" }
    return "Point at the marker"
  }
}

private struct StepPanel: View {
  let player: GuidePlayer
  let markerSeen: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(player.guide.title).font(.caption).foregroundStyle(.secondary)

      if let step = player.currentStep, let index = player.currentIndex {
        Text("Step \(index + 1) of \(player.guide.steps.count)").font(.caption.weight(.bold))
        Text(step.text).font(.title3.weight(.semibold))
        Button(action: player.next) {
          Text(index + 1 == player.guide.steps.count ? "Finish" : "Next")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!markerSeen)
      } else {
        Text("Guide complete").font(.title3.weight(.semibold))
        Button("Start again", action: player.restart)
          .buttonStyle(.bordered)
          .controlSize(.large)
          .frame(maxWidth: .infinity)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
  }
}
