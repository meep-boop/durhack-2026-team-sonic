import SwiftUI

/// Subtitles: what the expert is saying right now, just above the step card, so a noisy room or a quiet voice
/// doesn't lose an instruction. Only the expert: the user knows what they said, and their mic also hears the room. A
/// finished line stays 5 s, then goes.
struct CaptionStrip: View {
  let call: CallManager
  @State private var expiredLineId: String?
  /// The "transcript off" notice shows for 5 s, then gets out of the way (it stays in the transcript sheet).
  @State private var expiredProblem: String?

  private var lastExpertLine: TranscriptLine? { call.transcript.last { $0.speaker == .expert } }

  private var line: TranscriptLine? {
    if let caption = call.caption, caption.speaker == .expert { return caption }
    guard let last = lastExpertLine, last.id != expiredLineId else { return nil }
    return last
  }

  var body: some View {
    Group {
      if let line {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Image(systemName: "waveform").font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
          Text(line.text)
            .font(.callout.weight(.semibold))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .glassBackground(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Expert: \(line.text)")
      } else if let problem = call.transcriptProblem, problem != expiredProblem {
        Label(problem, systemImage: "captions.bubble")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .glassBackground(in: Capsule())
      }
    }
    .animation(.easeInOut(duration: 0.2), value: line?.id)
    .task(id: call.transcriptProblem) {
      guard let problem = call.transcriptProblem else { return }
      try? await Task.sleep(for: .seconds(5))
      if !Task.isCancelled { expiredProblem = problem }
    }
    .task(id: lastExpertLine?.id) {
      guard let id = lastExpertLine?.id else { return }
      try? await Task.sleep(for: .seconds(5))
      if !Task.isCancelled { expiredLineId = id }
    }
  }
}

/// The whole call, as text.
struct TranscriptSheet: View {
  let call: CallManager
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollViewReader { proxy in
        List {
          if call.transcript.isEmpty {
            ContentUnavailableView(
              "Nothing yet",
              systemImage: "captions.bubble",
              description: Text(call.transcriptProblem ?? "Lines appear here as you and the expert talk.")
            )
          }
          ForEach(call.transcript) { line in
            VStack(alignment: .leading, spacing: 3) {
              HStack {
                Text(line.speakerName).font(.caption.weight(.heavy)).foregroundStyle(line.speaker == .expert ? Theme.accent : .white)
                Spacer()
                Text(line.at.formatted(date: .omitted, time: .standard)).font(.caption2).foregroundStyle(.secondary)
              }
              Text(line.text)
            }
            .id(line.id)
          }
        }
        .onChange(of: call.transcript.count) {
          withAnimation { proxy.scrollTo(call.transcript.last?.id, anchor: .bottom) }
        }
      }
      .navigationTitle("Call transcript")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        ToolbarItem(placement: .bottomBar) {
          Label("Transcribed live by ElevenLabs", systemImage: "waveform").font(.caption).foregroundStyle(.secondary)
        }
      }
    }
  }
}
