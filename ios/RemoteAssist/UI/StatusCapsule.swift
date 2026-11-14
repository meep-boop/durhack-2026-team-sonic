import SwiftUI

/// One glass capsule for everything the user might worry about: is the marker found, is the link up, is anyone there.
struct StatusCapsule: View {
  let ar: ARSessionController
  let relay: RelayClient
  let call: CallManager
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 14) {
        item("viewfinder", markerColor, markerLabel)
        Divider().frame(height: 16)
        item("antenna.radiowaves.left.and.right", relayColor, relayLabel)
        if relay.state == .connected {
          Divider().frame(height: 16)
          item("person.fill", relay.expertOnline ? .green : .secondary, relay.expertOnline ? "Expert" : "No expert")
        }
        if call.state == .live {
          Divider().frame(height: 16)
          HStack(spacing: 5) {
            Circle().fill(.red).frame(width: 8, height: 8)
              .phaseAnimator([1.0, 0.3]) { $0.opacity($1) } animation: { _ in .easeInOut(duration: 0.8) }
            Text("LIVE").font(.caption.weight(.heavy))
          }
        }
      }
      .font(.footnote.weight(.semibold))
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .glassBackground(in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Status: \(markerLabel), \(relayLabel). Tap for connection settings.")
  }

  private func item(_ symbol: String, _ color: Color, _ label: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: symbol).foregroundStyle(color)
      Text(label)
    }
  }

  private var markerColor: Color { ar.markerTracked ? .green : (ar.markerSeen ? .orange : .secondary) }
  private var markerLabel: String { ar.markerTracked ? "Locked" : (ar.markerSeen ? "Holding" : "Searching") }

  private var relayColor: Color {
    switch relay.state {
    case .connected: .green
    case .connecting: .orange
    case .off: .secondary
    }
  }

  private var relayLabel: String {
    switch relay.state {
    case .connected: "Live"
    case .connecting: "Reconnecting"
    case .off: "Offline"
    }
  }
}

extension View {
  /// Liquid Glass on iOS 26, the system material before it.
  @ViewBuilder
  func glassBackground<S: Shape>(in shape: S) -> some View {
    if #available(iOS 26.0, *) {
      self.glassEffect(.regular, in: shape)
    } else {
      self.background(.ultraThinMaterial, in: shape)
    }
  }
}
