import SwiftUI

/// The laptop button: what this guide is, where its steps come from, and a safety checklist the user ticks before
/// the first step.
struct LaptopGuideSheet: View {
  let laptop: LaptopGuide
  let onStart: (Guide) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var confirmingOverride = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "laptopcomputer.and.arrow.down").font(.system(size: 44)).foregroundStyle(Theme.accent)
            Text("Swap the SSD").font(.title2.weight(.bold))
            Text(laptop.device).font(.headline).foregroundStyle(.secondary)
            Label(laptop.stepSource, systemImage: "checkmark.seal.fill")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.green)
            Text("\(laptop.steps.count) steps. No marker needed: the expert can point at each part on your camera, and the pins land on the real laptop.")
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading, spacing: 12) {
            Label("Before you start", systemImage: "checkmark.shield").font(.headline)
            ForEach(LaptopGuide.safetyItems, id: \.id) { item in
              Toggle(isOn: binding(item.id)) { Text(item.text) }
                .toggleStyle(CheckToggleStyle())
            }
          }

          Button {
            laptop.allSafe ? start() : (confirmingOverride = true)
          } label: {
            Label(laptop.allSafe ? "Start the guide" : "Start anyway", systemImage: "play.fill")
              .font(.headline)
              .frame(maxWidth: .infinity, minHeight: 50)
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
        }
        .padding(24)
      }
      .navigationTitle("Laptop guide")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
      .confirmationDialog("Not everything is ticked", isPresented: $confirmingOverride, titleVisibility: .visible) {
        Button("I've checked it myself, start") {
          laptop.overrideSafety()
          start()
        }
        Button("Go back", role: .cancel) {}
      } message: {
        Text("Opening a laptop that's on or charging can damage it or hurt you.")
      }
    }
  }

  private func binding(_ id: String) -> Binding<Bool> {
    Binding(
      get: { laptop.safetyChecked.contains(id) },
      set: { on in if on { laptop.safetyChecked.insert(id) } else { laptop.safetyChecked.remove(id) } }
    )
  }

  private func start() {
    onStart(laptop.guide())
    dismiss()
  }
}

/// A row you tick, with a big tap target.
private struct CheckToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button { configuration.isOn.toggle() } label: {
      HStack(spacing: 12) {
        Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
          .font(.title3)
          .foregroundStyle(configuration.isOn ? Theme.accent : .secondary)
        configuration.label.foregroundStyle(.primary)
        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.selection, trigger: configuration.isOn)
  }
}

/// Under a laptop-guide step: where the steps come from, how pins get there, and the ghost screwdriver toggle.
struct LaptopStepTools: View {
  let laptop: LaptopGuide
  @Binding var ghostToolOn: Bool

  var body: some View {
    HStack {
      Label("\(laptop.stepSource) · the expert taps to pin parts", systemImage: "checkmark.seal")
        .font(.caption2)
        .foregroundStyle(.secondary)
      Spacer(minLength: 8)
      Toggle(isOn: $ghostToolOn) { Image(systemName: "screwdriver") }
        .toggleStyle(.button)
        .controlSize(.mini)
        .accessibilityLabel(ghostToolOn ? "Hide the ghost screwdriver" : "Show the ghost screwdriver")
    }
  }
}
