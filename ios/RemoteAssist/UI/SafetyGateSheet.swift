import SwiftUI

/// Before the first step: the AI looks at the laptop and says whether it's safe to open it now. The guide starts when
/// everything checks out, or when the user confirms they've checked themselves; the AI never silently waves it through.
struct SafetyGateView: View {
  let assistant: LaptopAssistant
  let checking: Bool
  let onCheckAgain: () -> Void
  let onStart: () -> Void
  @State private var confirmingOverride = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Label("Safety check", systemImage: "checkmark.shield.fill")
        .font(.title2.weight(.bold))

      if checking {
        HStack(spacing: 12) {
          ProgressView()
          Text("Looking at your laptop…").font(.headline)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
      } else if let safety = assistant.safety {
        VStack(alignment: .leading, spacing: 10) {
          row("Charger unplugged", safety.chargerUnplugged)
          row("Laptop switched off", safety.poweredOff)
          row("Upside down, underside facing you", safety.laptopUpsideDown)
          row("On a soft cloth or mat", safety.onSoftSurface)
        }
        if !safety.issues.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Text("Fix before you start").font(.headline)
            ForEach(safety.issues, id: \.self) { Text("• \($0)").foregroundStyle(.secondary) }
          }
        }
        if safety.allClear {
          startButton("All clear. Start the guide", action: onStart)
        } else {
          startButton("Check again", action: onCheckAgain)
          overrideButton
        }
      } else {
        Label("I couldn't check this time. Make sure the charger is out and the laptop is off before you start.", systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
        startButton("Check again", action: onCheckAgain)
        overrideButton
      }

      Label("AI-generated from one photo. You're the one who knows for sure.", systemImage: "sparkles")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .confirmationDialog("Have you checked yourself?", isPresented: $confirmingOverride, titleVisibility: .visible) {
      Button("Yes: unplugged, off, on a soft surface") {
        assistant.overrideSafety()
        onStart()
      }
      Button("Not yet", role: .cancel) {}
    } message: {
      Text("Opening a laptop that's on or charging can damage it or hurt you.")
    }
  }

  private var overrideButton: some View {
    Button("I've checked myself, continue") { confirmingOverride = true }
      .font(.subheadline)
      .frame(maxWidth: .infinity)
  }

  private func startButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 50)
    }
    .buttonStyle(.borderedProminent)
    .buttonBorderShape(.capsule)
  }

  private func row(_ title: String, _ answer: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: symbol(answer)).foregroundStyle(color(answer))
      Text(title)
      Spacer()
      Text(answer == "yes" ? "Looks good" : (answer == "no" ? "Not yet" : "Can't tell"))
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private func symbol(_ answer: String) -> String {
    switch answer {
    case "yes": "checkmark.circle.fill"
    case "no": "xmark.octagon.fill"
    default: "questionmark.circle.fill"
    }
  }

  private func color(_ answer: String) -> Color {
    switch answer {
    case "yes": .green
    case "no": .red
    default: .orange
    }
  }
}
