import SwiftUI

/// "Scan the room": record a scan lined up with the marker, then send it to the laptop, where the Spark trains a splat
/// from it (pipeline/README.md). The camera stays undimmed above the card, so the person can see what they're scanning.
struct ScanView: View {
  let ar: ARSessionController
  let relayURL: URL?
  let onClose: () -> Void

  @State private var recorder = ScanRecorder()
  @State private var phase: Phase = .ready

  private enum Phase: Equatable {
    case ready, recording, saving
    case saved(URL)
    case sending(Double)
    case sent(String)
    case failed(String, URL?)
  }

  var body: some View {
    VStack {
      Spacer()
      VStack(alignment: .leading, spacing: 10) {
        Text("Scan the room").font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
        Text(headline).font(.title2.weight(.bold)).foregroundStyle(.white)
        Text(detail).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        if case .sending(let fraction) = phase {
          ProgressView(value: fraction).tint(Theme.accent)
        }
        buttons.padding(.top, 4)
      }
      .padding(18)
      .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
      .padding(.horizontal, 16)
      .padding(.bottom, 8)
    }
    .onAppear { ar.scanRecorder = recorder }
    .onDisappear {
      ar.scanRecorder = nil
      if phase == .recording { recorder.cancel() }
    }
  }

  private var headline: String {
    switch phase {
    case .ready: ar.markerSeen ? "Ready to scan" : "Find the marker first"
    case .recording: "\(recorder.photoCount) photos"
    case .saving: "Saving…"
    case .saved: "Scan saved"
    case .sending(let fraction): "Sending… \(Int(fraction * 100))%"
    case .sent: "On the laptop"
    case .failed: "That didn't work"
    }
  }

  private var detail: String {
    switch phase {
    case .ready:
      "Walk slowly round the laptop at three heights, then make close passes over the screws. Start and finish with "
        + "the whole marker in view."
    case .recording:
      if recorder.movingTooFast { "Slower: the photos are smearing." }
      else if ar.markerTracked { "Marker in view. Keep going round." }
      else { "Keep going. Come back to the marker before you stop." }
    case .saving:
      "Writing the last photos and the camera positions."
    case .saved:
      if let host = relayURL?.host() { "Send it to the laptop at \(host). Keep the app open while it sends." }
      else { "Connect to the relay from the menu first, so the app knows the laptop's address." }
    case .sending:
      "Keep the app open."
    case .sent(let name):
      "Saved there as \(name). Next, train it on the Spark (pipeline/README.md)."
    case .failed(let message, _):
      message
    }
  }

  @ViewBuilder private var buttons: some View {
    HStack(spacing: 10) {
      switch phase {
      case .ready:
        if ar.markerSeen {
          primary("Start", start)
        } else {
          waitingForMarker
        }
        secondary("Back", onClose)
      case .recording:
        primary("Stop and save", stop)
      case .saving, .sending:
        EmptyView()
      case .saved(let folder):
        primary("Send to laptop", disabled: ScanUploader.endpoint(relay: relayURL) == nil) { send(folder) }
        secondary("Done", onClose)
      case .sent:
        primary("Done", onClose)
        secondary("Scan again") { phase = .ready }
      case .failed(_, let folder):
        if let folder { primary("Send again") { send(folder) } }
        secondary("Back", onClose)
      }
    }
  }

  private func primary(_ title: String, disabled: Bool = false, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
    }
    .buttonStyle(.borderedProminent)
    .tint(Theme.accent)
    .disabled(disabled)
  }

  /// A disabled prominent button all but vanishes on the glass card, so before the marker is seen this says what's
  /// missing instead, in plain view. The scan still can't start without it: it's lined up from the marker.
  private var waitingForMarker: some View {
    Label("Point at the marker to start", systemImage: "viewfinder")
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(.white.opacity(0.18), in: Capsule())
      .accessibilityAddTraits(.isStaticText)
  }

  private func secondary(_ title: String, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
    }
    .buttonStyle(.bordered)
  }

  private func start() {
    do {
      try recorder.start()
      phase = .recording
    } catch {
      phase = .failed(error.localizedDescription, nil)
    }
  }

  private func stop() {
    phase = .saving
    Task {
      do {
        phase = .saved(try await recorder.finish())
      } catch {
        phase = .failed(error.localizedDescription, nil)
      }
    }
  }

  private func send(_ folder: URL) {
    guard let endpoint = ScanUploader.endpoint(relay: relayURL) else { return }
    phase = .sending(0)
    Task {
      do {
        let name = try await ScanUploader.send(folder, to: endpoint) { fraction in
          Task { @MainActor in
            if case .sending = phase { phase = .sending(fraction) }
          }
        }
        phase = .sent(name)
      } catch {
        phase = .failed(error.localizedDescription, folder)
      }
    }
  }
}
