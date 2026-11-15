import SwiftUI

/// Before a demo: is the AI really reachable, and is the voice really ElevenLabs? One tap each, with the exact error,
/// so a missing key or a wrong model name shows up here instead of as "nothing happens" on stage.
struct SystemCheckSection: View {
  let assistant: LaptopAssistant
  let voice: VoiceGuide

  private enum Status: Equatable {
    case idle, running, ok(String), failed(String)
  }

  @State private var gemini: Status = .idle
  @State private var eleven: Status = .idle

  var body: some View {
    Section {
      row(
        title: "Gemini",
        detail: assistant.modelName.map { "Key set · \($0)" } ?? "No key: add GEMINI_API_KEY to ios/Secrets.xcconfig, run xcodegen, rebuild",
        status: gemini,
        enabled: assistant.isAvailable
      ) {
        gemini = .running
        Task {
          do {
            let seconds = try await assistant.ping()
            gemini = .ok(String(format: "Answered in %.1f s", seconds))
          } catch {
            gemini = .failed(error.localizedDescription)
          }
        }
      }
      row(
        title: "ElevenLabs voice",
        detail: voice.usesElevenLabs ? "Key set" : "No key: steps use the iOS voice. Add ELEVENLABS_API_KEY to ios/Secrets.xcconfig",
        status: eleven,
        enabled: voice.usesElevenLabs
      ) {
        eleven = .running
        voice.checkVoice { problem in
          eleven = problem.map { .failed($0) } ?? .ok("You should hear it now")
        }
      }
    } header: {
      Text("System check")
    } footer: {
      Text("Keys stay on this phone, in the git-ignored ios/Secrets.xcconfig. Never commit them.")
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
