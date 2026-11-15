import SwiftUI

struct StepCard: View {
  struct PinProgress: Equatable {
    var done: Int
    var total: Int
    var verb: String
  }

  /// The one thing worth saying under the step right now, if anything.
  struct Note: Equatable {
    var text: String
    var symbol: String
    var tint: Color = Theme.accent
  }

  let player: GuidePlayer
  /// Marker guides only make sense once the marker is found; the laptop guide doesn't use it.
  let canAdvance: Bool
  var note: Note? = nil
  /// The finished guide's PDF report, once it's made.
  var reportURL: URL? = nil
  /// Ahmed's UNO Q rig's verdict on this step, when it checks it.
  var verification: StepVerified? = nil
  let onNext: () -> Void
  let onBack: () -> Void
  /// On the first step, Back leaves the guide instead (when there's somewhere to go back to).
  var onLeave: (() -> Void)? = nil

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let step = player.currentStep, let index = player.currentIndex {
        ProgressSegments(steps: player.guide.steps, current: index, done: player.doneStepIds)

        VStack(alignment: .leading, spacing: 6) {
          Text("STEP \(index + 1) OF \(player.guide.steps.count)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
          Text(step.text)
            .font(.title2.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .id(step.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        }

        if let note {
          Label(note.text, systemImage: note.symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(note.tint)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .animation(.snappy, value: note)
        }

        if let verification {
          Label(
            verification.ok ? "Checked by the rig: correct" : (verification.detail ?? "The rig says this isn't right yet"),
            systemImage: verification.ok ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
          )
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(verification.ok ? .green : .orange)
          .sensoryFeedback(verification.ok ? .success : .warning, trigger: verification)
        }

        HStack(spacing: 12) {
          let leaves = index == 0 && onLeave != nil
          Button(action: leaves ? (onLeave ?? {}) : onBack) {
            Image(systemName: leaves ? "rectangle.portrait.and.arrow.right" : "chevron.left")
              .font(.headline)
              .frame(width: 52, height: 52)
          }
          .buttonStyle(.bordered)
          .buttonBorderShape(.circle)
          .disabled(index == 0 && !leaves)
          .accessibilityLabel(leaves ? "Leave this guide" : "Previous step")

          Button(action: onNext) {
            Label(index + 1 == player.guide.steps.count ? "Finish" : "Done, next step", systemImage: index + 1 == player.guide.steps.count ? "checkmark" : "arrow.right")
              .font(.headline)
              .frame(maxWidth: .infinity, minHeight: 52)
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
          .disabled(!canAdvance)
        }

      } else {
        CompletionView(title: player.guide.title, reportURL: reportURL, onRestart: player.restart)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassBackground(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .animation(.snappy, value: player.currentStepId)
    .sensoryFeedback(.success, trigger: player.currentStepId)
  }
}

/// Green for steps really tapped done (by id), so a jump from the expert or a guide replay doesn't fake progress.
private struct ProgressSegments: View {
  let steps: [Step]
  let current: Int
  let done: Set<String>

  var body: some View {
    HStack(spacing: 4) {
      ForEach(steps.indices, id: \.self) { i in
        Capsule()
          .fill(i == current ? Theme.accent : (done.contains(steps[i].id) ? Color.white : Color.secondary.opacity(0.3)))
          .frame(height: 5)
      }
    }
    .accessibilityHidden(true)
  }
}

private struct CompletionView: View {
  let title: String
  let reportURL: URL?
  let onRestart: () -> Void
  @State private var appeared = false

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 56))
        .foregroundStyle(.green)
        .symbolEffect(.bounce, value: appeared)
      Text("All done").font(.title2.weight(.bold))
      Text("You finished “\(title)”. Nice work.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      HStack(spacing: 10) {
        if let reportURL {
          ShareLink(item: reportURL, preview: SharePreview("Repair report", image: Image(systemName: "doc.richtext"))) {
            Label("Share report", systemImage: "square.and.arrow.up")
          }
          .buttonStyle(.borderedProminent)
        }
        Button("Start again", action: onRestart)
          .buttonStyle(.bordered)
      }
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity)
    .onAppear { appeared = true }
  }
}
