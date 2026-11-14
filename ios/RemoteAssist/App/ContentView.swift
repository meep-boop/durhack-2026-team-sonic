import SwiftUI
import UIKit

struct ContentView: View {
  @State var player: GuidePlayer
  @State private var ar = ARSessionController()
  @State private var relay = RelayClient()
  @State private var showingRelaySettings = false

  var body: some View {
    ZStack {
      ARViewContainer(controller: ar)
        .ignoresSafeArea()

      VStack(spacing: 12) {
        HStack(alignment: .top) {
          StatusPill(ar: ar, guideMarker: player.guide.marker)
          Spacer(minLength: 8)
          RelayPill(relay: relay) { showingRelaySettings = true }
        }
        Spacer()
        StepPanel(player: player, markerSeen: ar.markerSeen, onNext: next)
      }
      .padding()
    }
    .sheet(isPresented: $showingRelaySettings) {
      RelaySettings(relay: relay)
        .presentationDetents([.medium])
    }
    .onAppear(perform: wire)
    // Step is compared by value, so a guide.set that edits the current step's objects redraws it too.
    .onChange(of: player.currentStep) { ar.step = player.currentStep }
  }

  private func wire() {
    ar.step = player.currentStep
    ar.onPose = { [relay] pose in relay.sendPose(pose) }
    relay.onGuide = { [player] guide in player.replace(with: guide) }
    relay.onStepSet = { [player] message in
      if message.guideId == player.guide.id { player.jump(to: message.stepId) }
    }
    relay.connectSaved()
  }

  private func next() {
    guard let step = player.currentStep else { return }
    relay.sendStepDone(guide: player.guide, stepId: step.id)
    player.next()
  }
}

private struct StatusPill: View {
  let ar: ARSessionController
  let guideMarker: Marker

  private var widthMismatch: Bool { abs(guideMarker.width - MarkerSpec.widthMeters) > 0.001 }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        Circle()
          .fill(ar.markerTracked ? .green : (ar.markerSeen ? .orange : .gray))
          .frame(width: 10, height: 10)
        Text(statusText).font(.subheadline.weight(.semibold))
      }
      Text("iOS \(UIDevice.current.systemVersion)").font(.caption2).foregroundStyle(.secondary)
      if let error = ar.errorMessage {
        Text(error).font(.caption).foregroundStyle(.red)
      }
      if widthMismatch {
        Text("Guide expects a \(Int(guideMarker.width * 1000)) mm marker; app is set to \(Int(MarkerSpec.widthMeters * 1000)) mm")
          .font(.caption)
          .foregroundStyle(.yellow)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private var statusText: String {
    if ar.markerTracked { return "Marker tracked" }
    if ar.markerSeen { return "Marker out of view" }
    return "Point at the marker"
  }
}

private struct RelayPill: View {
  let relay: RelayClient
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .trailing, spacing: 2) {
        HStack(spacing: 6) {
          Circle().fill(color).frame(width: 10, height: 10)
          Text(title).font(.subheadline.weight(.semibold))
        }
        if relay.state == .connected {
          Text(relay.expertOnline ? "Expert online" : "Expert offline").font(.caption2).foregroundStyle(.secondary)
        }
        if relay.outboxCount > 0 {
          Text("\(relay.outboxCount) step\(relay.outboxCount == 1 ? "" : "s") waiting to send").font(.caption2).foregroundStyle(.orange)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
  }

  private var title: String {
    switch relay.state {
    case .off: "Offline"
    case .connecting: "Connecting…"
    case .connected: "Live"
    }
  }

  private var color: Color {
    switch relay.state {
    case .off: .gray
    case .connecting: .orange
    case .connected: .green
    }
  }
}

private struct RelaySettings: View {
  let relay: RelayClient
  @State private var text = ""
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("ws://192.168.1.20:8080", text: $text)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        } header: {
          Text("Relay address")
        } footer: {
          Text("The relay prints it when it starts (npm start in relay/). Phone and laptop must be on the same Wi-Fi or hotspot.")
        }
        if let error = relay.lastError {
          Section("Last problem") { Text(error).foregroundStyle(.red) }
        }
        Section {
          Button("Connect") {
            if let url = URL(string: text.trimmingCharacters(in: .whitespaces)), url.scheme == "ws" || url.scheme == "wss" {
              relay.connect(to: url)
              dismiss()
            }
          }
          if relay.state != .off {
            Button("Disconnect", role: .destructive) { relay.disconnect() }
          }
        }
      }
      .navigationTitle("Relay")
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear { text = relay.url?.absoluteString ?? "" }
  }
}

private struct StepPanel: View {
  let player: GuidePlayer
  let markerSeen: Bool
  let onNext: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(player.guide.title).font(.caption).foregroundStyle(.secondary)

      if let step = player.currentStep, let index = player.currentIndex {
        Text("Step \(index + 1) of \(player.guide.steps.count)").font(.caption.weight(.bold))
        Text(step.text).font(.title3.weight(.semibold))
        Button(action: onNext) {
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
