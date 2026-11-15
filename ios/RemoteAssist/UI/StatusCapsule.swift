import SwiftUI

/// One glass capsule for everything the user might worry about: is the marker found, is the link up, is anyone there.
struct StatusCapsule: View {
  let ar: ARSessionController
  let relay: RelayClient
  let call: CallManager
  /// On the laptop guide: whether its corners are set (shown instead of the marker, which it doesn't use).
  var laptopLocked: Bool? = nil
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      // Words when they fit, icons alone when they don't: never one syllable per line.
      ViewThatFits(in: .horizontal) {
        segments(labelled: true)
        segments(labelled: false)
      }
      .font(.footnote.weight(.semibold))
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .glassBackground(in: Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Status: \(markerLabel), \(relayLabel). Tap for connection settings.")
  }

  private func segments(labelled: Bool) -> some View {
    HStack(spacing: labelled ? 12 : 14) {
      if let laptopLocked {
        item("laptopcomputer", laptopLocked ? .green : .orange, laptopLocked ? "Locked" : "Set up", labelled)
      } else {
        item("viewfinder", markerColor, markerLabel, labelled)
      }
      Divider().frame(height: 14)
      item("antenna.radiowaves.left.and.right", relayColor, relayLabel, labelled)
      if relay.state == .connected {
        Divider().frame(height: 14)
        item("person.fill", relay.expertOnline ? .green : .secondary, relay.expertOnline ? "Expert" : "No expert", labelled)
      }
    }
    .fixedSize()
  }

  private func item(_ symbol: String, _ color: Color, _ label: String, _ labelled: Bool) -> some View {
    HStack(spacing: 5) {
      Image(systemName: symbol).foregroundStyle(color)
      if labelled { Text(label).lineLimit(1) }
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
  /// Solid translucent black with a hairline edge. Not Liquid Glass or a material: those re-blur the live camera
  /// behind them every frame, and with a dozen of them over ARView the GPU ran out of drawables.
  func glassBackground<S: Shape>(in shape: S) -> some View {
    self
      .background(Color.black.opacity(0.62), in: shape)
      .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 1))
  }
}
