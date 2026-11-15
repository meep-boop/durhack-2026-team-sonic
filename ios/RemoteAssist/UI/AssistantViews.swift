import SwiftUI

/// The laptop guide's safety checklist, as a card over the live camera rather than a sheet: a sheet sliding away from
/// in front of the AR view is the moment the camera used to freeze.
struct LaptopChecklistCard: View {
  let laptop: LaptopGuide
  let onStart: (Guide) -> Void
  let onCancel: () -> Void
  /// Set after a first tap on "Start anyway", so skipping the checklist takes a deliberate second tap.
  @State private var confirmingOverride = false

  var body: some View {
    ZStack {
      if !CameraLab.overlaysOff { Color.black.opacity(0.55).ignoresSafeArea() }

      VStack(alignment: .leading, spacing: 16) {
        Spacer(minLength: 0)
        VStack(alignment: .leading, spacing: 16) {
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Swap the SSD").font(.title2.weight(.bold))
              Text(laptop.device).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
              Label(laptop.stepSource, systemImage: "checkmark.seal.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)
            }
            Spacer(minLength: 8)
            Button("Cancel", action: onCancel).font(.subheadline.weight(.semibold))
          }

          VStack(alignment: .leading, spacing: 12) {
            Text("BEFORE YOU START · \(laptop.steps.count) STEPS")
              .font(.caption.weight(.bold))
              .foregroundStyle(.secondary)
            ForEach(LaptopGuide.safetyItems, id: \.id) { item in
              Toggle(isOn: binding(item.id)) { Text(item.text) }
                .toggleStyle(CheckToggleStyle())
            }
          }

          if confirmingOverride && !laptop.allSafe {
            Label("Opening a laptop that's on or charging can damage it or hurt you.", systemImage: "exclamationmark.triangle.fill")
              .font(.footnote.weight(.semibold))
              .foregroundStyle(.orange)
              .fixedSize(horizontal: false, vertical: true)
          }

          Button(action: startTapped) {
            Label(startTitle, systemImage: "play.fill")
              .font(.headline)
              .frame(maxWidth: .infinity, minHeight: 52)
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
        }
        .padding(20)
        .glassBackground(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
      }
      .padding(.horizontal)
      .padding(.bottom, 8)
    }
    .animation(.snappy, value: confirmingOverride)
    .animation(.snappy, value: laptop.allSafe)
  }

  private var startTitle: String {
    if laptop.allSafe { return "Start the guide" }
    return confirmingOverride ? "I've checked it myself, start" : "Start anyway"
  }

  private func startTapped() {
    if !laptop.allSafe {
      guard confirmingOverride else { confirmingOverride = true; return }
      laptop.overrideSafety()
    }
    onStart(laptop.guide())
  }

  private func binding(_ id: String) -> Binding<Bool> {
    Binding(
      get: { laptop.safetyChecked.contains(id) },
      set: { on in if on { laptop.safetyChecked.insert(id) } else { laptop.safetyChecked.remove(id) } }
    )
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
