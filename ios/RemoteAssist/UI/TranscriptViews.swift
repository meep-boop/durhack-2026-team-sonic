import SwiftUI

/// What's being said right now on the call, under the in-call bar: live captions, so a noisy room or a quiet voice
/// doesn't lose an instruction.
struct CaptionStrip: View {
  let call: CallManager

  var body: some View {
    if let line = call.caption ?? call.transcript.last {
      HStack(alignment: .top, spacing: 8) {
        Text(line.speakerName)
          .font(.caption.weight(.heavy))
          .foregroundStyle(line.speaker == .expert ? Theme.accent : .white)
        Text(line.text)
          .font(.subheadline)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)
          .opacity(call.caption == nil ? 0.7 : 1)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .glassBackground(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .animation(.snappy, value: line)
      .accessibilityElement(children: .combine)
    } else if let problem = call.transcriptProblem {
      Label(problem, systemImage: "captions.bubble")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassBackground(in: Capsule())
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
