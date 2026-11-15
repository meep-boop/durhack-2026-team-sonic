import SwiftUI

/// Before a demo: is the voice really ElevenLabs (it also mints the call transcript's tokens)? One tap, with the
/// exact error, so a missing or wrong key shows up here instead of as "nothing happens" on stage.
struct SystemCheckSection: View {
  let voice: VoiceGuide
  var onHandsInFront: (Bool) -> Void = { _ in }
  @State private var mic = MicCheck()
  @State private var handsInFront = ARSessionController.handsInFront

  private enum Status: Equatable {
    case idle, running, ok(String), failed(String)
  }

  @State private var eleven: Status = .idle
  @State private var labDelegate = CameraLab.delegateOffMain
  @State private var labPlanes = CameraLab.planesAlways
  @State private var labOverlays = CameraLab.overlaysOff

  var body: some View {
    checks
    cameraLab
  }

  /// Only for chasing a frozen camera: each switch brings back one thing from the build where it froze.
  private var cameraLab: some View {
    Section {
      Toggle("AR updates off the main thread", isOn: $labDelegate)
        .onChange(of: labDelegate) { CameraLab.delegateOffMain = labDelegate }
      Toggle("Surface detection always on", isOn: $labPlanes)
        .onChange(of: labPlanes) { CameraLab.planesAlways = labPlanes }
      Toggle("No spotlight or dimming", isOn: $labOverlays)
        .onChange(of: labOverlays) { CameraLab.overlaysOff = labOverlays }
    } header: {
      Text("Camera lab")
    } footer: {
      Text("Leave these off. If the camera ever freezes, turn one on, close and reopen the app, and send the log. It starts with \"lab:\" so we can see which one does it.")
    }
  }

  private var checks: some View {
    Section {
      row(
        title: "ElevenLabs voice",
        detail: voice.usesElevenLabs ? "Key set: voice and call transcript" : "No key: steps use the iOS voice and there's no transcript. Add ELEVENLABS_API_KEY to ios/Secrets.xcconfig",
        status: eleven,
        enabled: voice.usesElevenLabs
      ) {
        eleven = .running
        voice.checkVoice { problem in
          eleven = problem.map { .failed($0) } ?? .ok("You should hear it now")
        }
      }
      micRow
      Toggle(isOn: $handsInFront) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Hands in front of the guide")
          Text("Your hands hide the 3D parts, like real objects. Uses a lot more battery and GPU, and can freeze the camera when switched: if it does, tap Restart camera or reopen the app.")
            .font(.footnote).foregroundStyle(.secondary)
        }
      }
      .onChange(of: handsInFront) { onHandsInFront(handsInFront) }
    } header: {
      Text("System check")
    } footer: {
      Text("Keys stay on this phone, in the git-ignored ios/Secrets.xcconfig. Never commit them.")
    }
  }

  private var micRow: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: micIcon).foregroundStyle(micColor)
        Text("Microphone").font(.headline)
        Spacer()
        if mic.status == .listening {
          ProgressView()
        } else {
          Button("Test", action: mic.run).buttonStyle(.bordered).controlSize(.small)
        }
      }
      if mic.status == .listening {
        ProgressView(value: Double(mic.level)).tint(Theme.accent)
        Text("Say something…").font(.footnote).foregroundStyle(.secondary)
      }
      switch mic.status {
      case .denied: Text("Microphone access is off: Settings → Remote Assist → Microphone").font(.footnote).foregroundStyle(.red)
      case .done(let peak) where peak < 0.05: Text("Heard nothing. Check nothing is covering the mic, or another app is using it.").font(.footnote).foregroundStyle(.orange)
      case .done: Text("Working: the expert will hear you").font(.footnote).foregroundStyle(.green)
      case .failed(let message): Text(message).font(.footnote).foregroundStyle(.red)
      default: EmptyView()
      }
    }
    .padding(.vertical, 2)
  }

  private var micIcon: String {
    switch mic.status {
    case .done(let peak): peak < 0.05 ? "mic.slash.fill" : "checkmark.circle.fill"
    case .denied, .failed: "xmark.octagon.fill"
    default: "mic"
    }
  }

  private var micColor: Color {
    switch mic.status {
    case .done(let peak): peak < 0.05 ? .orange : .green
    case .denied, .failed: .red
    default: .secondary
    }
  }

  private func row(title: String, detail: String, status: Status, enabled: Bool, test: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: icon(status, enabled: enabled)).foregroundStyle(color(status, enabled: enabled))
        Text(title).font(.headline)
        Spacer()
        if status == .running {
          ProgressView()
        } else {
          Button("Test", action: test).disabled(!enabled).buttonStyle(.bordered).controlSize(.small)
        }
      }
      Text(detail).font(.footnote).foregroundStyle(.secondary)
      switch status {
      case .ok(let message): Text(message).font(.footnote).foregroundStyle(.green)
      case .failed(let message): Text(message).font(.footnote).foregroundStyle(.red).textSelection(.enabled)
      default: EmptyView()
      }
    }
    .padding(.vertical, 2)
  }

  private func icon(_ status: Status, enabled: Bool) -> String {
    switch status {
    case .ok: "checkmark.circle.fill"
    case .failed: "xmark.octagon.fill"
    default: enabled ? "circle.dashed" : "key.slash"
    }
  }

  private func color(_ status: Status, enabled: Bool) -> Color {
    switch status {
    case .ok: .green
    case .failed: .red
    default: enabled ? .secondary : .orange
    }
  }
}
