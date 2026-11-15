import SwiftUI

/// Everything that isn't "do this step" lives in one ⋯ menu, so the camera screen has a single obvious button.
struct GuideMenu: View {
  let isLaptopGuide: Bool
  let frameLocked: Bool
  let teaching: Bool
  let inCall: Bool
  let layoutFile: URL?
  @Binding var voiceOn: Bool
  @Binding var ghostToolOn: Bool
  @Binding var arDebug: Bool
  let handsFreeOn: Bool
  let onConnect: () -> Void
  let onTranscript: () -> Void
  let onSetup: () -> Void
  let onTeach: () -> Void
  let onUndoTeach: () -> Void
  let onHandsFree: () -> Void
  let onLeave: () -> Void

  var body: some View {
    Menu {
      Section {
        Button(action: onConnect) { Label("Connect to the expert · system check", systemImage: "antenna.radiowaves.left.and.right") }
        if inCall {
          Button(action: onTranscript) { Label("Call transcript", systemImage: "captions.bubble") }
        }
      }

      if isLaptopGuide {
        Section("Laptop") {
          Button(action: onSetup) { Label(frameLocked ? "Re-do the corners" : "Set up the laptop", systemImage: "viewfinder") }
          if frameLocked {
            Button(action: onTeach) {
              Label(teaching ? "Stop teaching positions" : "Teach part positions", systemImage: "hand.point.up.left")
            }
            if teaching {
              Button(action: onUndoTeach) { Label("Undo the last mark", systemImage: "arrow.uturn.backward") }
            }
            if let layoutFile {
              ShareLink(item: layoutFile) { Label("Share the layout", systemImage: "square.and.arrow.up") }
            }
          }
          Toggle(isOn: $ghostToolOn) { Label("Ghost screwdriver", systemImage: "screwdriver") }
        }
      }

      Section("Voice") {
        Toggle(isOn: $voiceOn) { Label("Read steps aloud", systemImage: "speaker.wave.2") }
        Toggle(isOn: $arDebug) { Label("Show AR debug", systemImage: "ruler") }
        Button(action: onHandsFree) {
          Label(handsFreeOn ? "Turn hands-free off" : "Hands-free (say “next”)", systemImage: handsFreeOn ? "mic.fill" : "mic")
        }
      }

      Section {
        Button(role: .destructive, action: onLeave) { Label("Leave this guide", systemImage: "rectangle.portrait.and.arrow.right") }
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.headline)
        .frame(width: 44, height: 44)
        .glassBackground(in: Circle())
    }
    .accessibilityLabel("More")
  }
}
