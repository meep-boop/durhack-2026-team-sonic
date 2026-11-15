import SwiftUI
import VisionKit

struct ConnectionSheet: View {
  let relay: RelayClient
  let assistant: LaptopAssistant
  let voice: VoiceGuide
  /// The AR session and the QR scanner can't share the camera, so AR pauses while scanning.
  let pauseAR: () -> Void
  let resumeAR: () -> Void

  @State private var text = ""
  @State private var scanning = false
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack {
            Circle().fill(statusColor).frame(width: 10, height: 10)
            Text(statusText)
            Spacer()
            if relay.state == .connected {
              Text(relay.expertOnline ? "Expert online" : "Expert offline").foregroundStyle(.secondary)
            }
          }
          if let error = relay.lastError, relay.state != .connected {
            Text(error).font(.footnote).foregroundStyle(.red)
          }
        }

        if DataScannerViewController.isSupported {
          Section {
            Button {
              pauseAR()
              scanning = true
            } label: {
              Label("Scan the expert's QR code", systemImage: "qrcode.viewfinder")
            }
          } footer: {
            Text("The expert's call page shows a QR code with the relay address.")
          }
        }

        Section("Or type the address") {
          TextField("ws://192.168.1.20:8080", text: $text)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onSubmit(connectTyped)
          Button("Connect", action: connectTyped)
            .disabled(URL(string: text)?.scheme?.hasPrefix("ws") != true)
        }

        if relay.state != .off {
          Section {
            Button("Disconnect", role: .destructive) { relay.disconnect() }
          }
        }

        SystemCheckSection(assistant: assistant, voice: voice)
      }
      .navigationTitle("Connection")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
      }
    }
    .onAppear { text = relay.url?.absoluteString ?? "" }
    .fullScreenCover(isPresented: $scanning, onDismiss: resumeAR) {
      QRScanner { value in
        scanning = false
        if let url = URL(string: value), url.scheme == "ws" || url.scheme == "wss" {
          text = value
          relay.connect(to: url)
          dismiss()
        }
      } onCancel: {
        scanning = false
      }
      .ignoresSafeArea()
    }
  }

  private func connectTyped() {
    guard let url = URL(string: text.trimmingCharacters(in: .whitespaces)), url.scheme == "ws" || url.scheme == "wss" else { return }
    relay.connect(to: url)
    dismiss()
  }

  private var statusColor: Color {
    switch relay.state {
    case .connected: .green
    case .connecting: .orange
    case .off: .secondary
    }
  }

  private var statusText: String {
    switch relay.state {
    case .connected: "Connected to the relay"
    case .connecting: "Connecting…"
    case .off: "Not connected (the guide still works offline)"
    }
  }
}

struct QRScanner: UIViewControllerRepresentable {
  let onFound: (String) -> Void
  let onCancel: () -> Void

  func makeUIViewController(context: Context) -> UINavigationController {
    let scanner = DataScannerViewController(
      recognizedDataTypes: [.barcode(symbologies: [.qr])],
      qualityLevel: .balanced,
      isHighlightingEnabled: true
    )
    scanner.delegate = context.coordinator
    scanner.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { _ in onCancel() })
    scanner.navigationItem.title = "Scan the relay QR"
    try? scanner.startScanning()
    return UINavigationController(rootViewController: scanner)
  }

  func updateUIViewController(_ controller: UINavigationController, context: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator(onFound: onFound) }

  final class Coordinator: NSObject, DataScannerViewControllerDelegate {
    let onFound: (String) -> Void
    private var done = false

    init(onFound: @escaping (String) -> Void) { self.onFound = onFound }

    func dataScanner(_ scanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
      for case let .barcode(code) in items {
        guard !done, let value = code.payloadStringValue else { continue }
        done = true
        scanner.stopScanning()
        onFound(value)
      }
    }
  }
}
