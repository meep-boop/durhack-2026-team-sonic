import SwiftUI

/// "Help me with my laptop": identify it, show what the AI is sure of and what worries it, then start the guide.
struct LaptopAssistantSheet: View {
  let assistant: LaptopAssistant
  let snapshot: () -> Data?
  let onStart: (Guide) -> Void
  let onAskExpert: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          switch assistant.phase {
          case .idle:
            intro
          case .working(let message):
            HStack(spacing: 12) {
              ProgressView()
              Text(message).font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
          case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            scanButton("Try again")
          case .identified:
            if let id = assistant.identification { result(id) }
          }
        }
        .padding(24)
      }
      .navigationTitle("Laptop assistant")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }
  }

  private var intro: some View {
    VStack(alignment: .leading, spacing: 16) {
      Image(systemName: "laptopcomputer.and.arrow.down")
        .font(.system(size: 48))
        .foregroundStyle(.tint)
      Text("Replace your laptop's SSD").font(.title2.weight(.bold))
      Text("Hold your phone so the whole laptop is in view (underside up works best), then tap the button. The AI identifies it and writes the steps for your exact model.")
        .foregroundStyle(.secondary)
      scanButton("Look at my laptop")
      Label("AI-generated guidance. An expert can join any time.", systemImage: "sparkles")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  private func scanButton(_ title: String) -> some View {
    Button {
      guard let jpeg = snapshot() else { return }
      Task { await assistant.identify(jpeg: jpeg) }
    } label: {
      Label(title, systemImage: "camera.viewfinder")
        .font(.headline)
        .frame(maxWidth: .infinity, minHeight: 50)
    }
    .buttonStyle(.borderedProminent)
    .buttonBorderShape(.capsule)
  }

  @ViewBuilder
  private func result(_ id: LaptopAssistant.Identification) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("\(id.make) \(id.model)").font(.title2.weight(.bold))
      HStack(spacing: 8) {
        ConfidenceBadge(value: id.confidence)
        Text(id.ssdFormFactor).font(.subheadline).foregroundStyle(.secondary)
      }
    }

    if id.ssdUserReplaceable == "no" {
      Label("This model's storage looks soldered to the board, so it can't be swapped at home. Please talk to an expert before opening it.", systemImage: "hand.raised.fill")
        .foregroundStyle(.red)
      Button("Ask the expert", action: onAskExpert).buttonStyle(.borderedProminent)
    } else {
      if id.ssdUserReplaceable == "unknown" {
        Label("I'm not sure this model's SSD can be swapped. Check with the expert if anything looks different from the steps.", systemImage: "questionmark.circle")
          .foregroundStyle(.orange)
      }
      if !id.tools.isEmpty {
        section("You'll need", id.tools, symbol: "wrench.and.screwdriver")
      }
      if !id.warnings.isEmpty {
        section("Before you start", id.warnings, symbol: "exclamationmark.shield")
      }
      Button {
        if let guide = assistant.guide() {
          onStart(guide)
          dismiss()
        }
      } label: {
        Label("Start the \(assistant.plan.count)-step guide", systemImage: "play.fill")
          .font(.headline)
          .frame(maxWidth: .infinity, minHeight: 50)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.capsule)
    }

    Button("Not my laptop? Scan again") { assistant.reset() }
      .font(.subheadline)
      .frame(maxWidth: .infinity)
  }

  private func section(_ title: String, _ items: [String], symbol: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: symbol).font(.headline)
      ForEach(items, id: \.self) { item in
        Text("• \(item)").foregroundStyle(.secondary)
      }
    }
  }
}

struct ConfidenceBadge: View {
  let value: Double

  var body: some View {
    let percent = Int((value * 100).rounded())
    Text("\(percent)% sure")
      .font(.caption.weight(.bold))
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(color.opacity(0.2), in: Capsule())
      .foregroundStyle(color)
  }

  private var color: Color { value >= 0.75 ? .green : (value >= 0.45 ? .orange : .red) }
}

/// The AI helpers under an AI-generated step: look again for the parts, and check the work.
struct AIStepTools: View {
  let assistant: LaptopAssistant
  let busy: Bool
  @Binding var ghostToolOn: Bool
  let onShowWhere: () -> Void
  let onCheck: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        Button(action: onShowWhere) {
          Label("Re-scan", systemImage: "viewfinder").frame(maxWidth: .infinity)
        }
        Button(action: onCheck) {
          Label("Check my work", systemImage: "checkmark.viewfinder").frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.bordered)
      .disabled(busy)

      if busy {
        ProgressView().frame(maxWidth: .infinity)
      } else if let check = assistant.lastCheck {
        HStack(alignment: .top, spacing: 8) {
          Image(systemName: check.done ? "checkmark.seal.fill" : "arrow.uturn.backward.circle.fill")
            .foregroundStyle(check.done ? .green : .orange)
          Text(check.feedback).font(.subheadline)
          Spacer(minLength: 0)
          ConfidenceBadge(value: check.confidence)
        }
      }

      HStack {
        Label("AI-placed: check each one before you unscrew", systemImage: "sparkles")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Spacer(minLength: 8)
        Toggle(isOn: $ghostToolOn) {
          Image(systemName: "screwdriver")
        }
        .toggleStyle(.button)
        .controlSize(.mini)
        .accessibilityLabel(ghostToolOn ? "Hide the ghost screwdriver" : "Show the ghost screwdriver")
      }
    }
  }
}
