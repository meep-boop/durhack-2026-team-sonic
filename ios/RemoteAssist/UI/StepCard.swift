import SwiftUI

struct StepCard: View {
  struct PinProgress: Equatable {
    var done: Int
    var total: Int
    var verb: String
  }

  let player: GuidePlayer
  /// Marker guides only make sense once the marker is found; AI laptop guides don't use it.
  let canAdvance: Bool
  let outboxCount: Int
  @Binding var voiceOn: Bool
  var tools: AnyView? = nil
  /// "3 of 8 done" while there are pins to tick on this step.
  var pinProgress: PinProgress? = nil
  /// Hands-free voice commands: on or off, the command just heard, and why it can't run.
  var handsFree: (on: Bool, heard: String?, problem: String?) = (false, nil, nil)
  var onToggleHandsFree: () -> Void = {}
  /// The finished guide's PDF report, once it's made.
  var reportURL: URL? = nil
  /// Ahmed's UNO Q rig's verdict on this step, when it checks it.
  var verification: StepVerified? = nil
  let onNext: () -> Void
  let onBack: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let step = player.currentStep, let index = player.currentIndex {
        ProgressSegments(steps: player.guide.steps, current: index, done: player.doneStepIds)

        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text("STEP \(index + 1) OF \(player.guide.steps.count)")
              .font(.caption.weight(.bold))
              .foregroundStyle(.secondary)
            Spacer()
            if let heard = handsFree.heard {
              Text("“\(heard)”")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .transition(.opacity.combined(with: .scale))
            }
            Button(action: onToggleHandsFree) {
              Image(systemName: handsFree.on ? "mic.fill" : "mic.slash")
                .font(.subheadline)
                .frame(width: 32, height: 32)
                .symbolEffect(.pulse, isActive: handsFree.on)
            }
            .buttonStyle(.plain)
            .foregroundStyle(handsFree.on ? Color.accentColor : .secondary)
            .accessibilityLabel(handsFree.on ? "Stop hands-free commands" : "Hands-free: say next, back, check my work")
            Button {
              voiceOn.toggle()
            } label: {
              Image(systemName: voiceOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.subheadline)
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(voiceOn ? Color.accentColor : .secondary)
            .accessibilityLabel(voiceOn ? "Stop reading steps aloud" : "Read steps aloud")
          }
          Text(step.text)
            .font(.title2.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .id(step.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        }

        if let problem = handsFree.problem {
          Label(problem, systemImage: "mic.badge.xmark").font(.footnote).foregroundStyle(.orange)
        } else if handsFree.on, handsFree.heard == nil {
          Text("Say “next”, “back”, “show me where”, “check my work” or “repeat”")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if let tools { tools }

        if let pinProgress {
          HStack(spacing: 8) {
            Image(systemName: pinProgress.done == pinProgress.total ? "checkmark.circle.fill" : "hand.tap.fill")
              .foregroundStyle(pinProgress.done == pinProgress.total ? .green : .accentColor)
            Text(pinProgress.done == pinProgress.total
              ? "All \(pinProgress.total) \(pinProgress.verb). Tap Done."
              : "\(pinProgress.done) of \(pinProgress.total) \(pinProgress.verb) · tap each pin as you go")
              .font(.subheadline.weight(.semibold))
              .contentTransition(.numericText())
          }
          .animation(.snappy, value: pinProgress)
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

        if outboxCount > 0 {
          Label("\(outboxCount) finished step\(outboxCount == 1 ? "" : "s") will sync when you're back online", systemImage: "icloud.slash")
            .font(.footnote)
            .foregroundStyle(.orange)
        }

        HStack(spacing: 12) {
          Button(action: onBack) {
            Image(systemName: "chevron.left")
              .font(.headline)
              .frame(width: 52, height: 52)
          }
          .buttonStyle(.bordered)
          .buttonBorderShape(.circle)
          .disabled(index == 0)
          .accessibilityLabel("Previous step")

          Button(action: onNext) {
            Label(index + 1 == player.guide.steps.count ? "Finish" : "Done, next step", systemImage: index + 1 == player.guide.steps.count ? "checkmark" : "arrow.right")
              .font(.headline)
              .frame(maxWidth: .infinity, minHeight: 52)
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.capsule)
          .disabled(!canAdvance)
        }

        if !canAdvance {
          Text("Point the camera at the marker to start.")
            .font(.footnote)
            .foregroundStyle(.secondary)
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
          .fill(i == current ? Color.accentColor : (done.contains(steps[i].id) ? Color.green : Color.secondary.opacity(0.3)))
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
