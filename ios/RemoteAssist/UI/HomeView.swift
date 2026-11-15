import SwiftUI

/// The first screen: what are you fixing? Two big choices over the live camera, and nothing else to work out.
struct HomeView: View {
  let relayConnected: Bool
  let onLaptop: () -> Void
  let onMarker: () -> Void
  let onScan: () -> Void
  let onSettings: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.55).ignoresSafeArea()

      VStack(alignment: .leading, spacing: 16) {
        Spacer()
        Text("Remote Assist")
          .font(.caption.weight(.bold))
          .foregroundStyle(Theme.accent)
        Text("What are you fixing?")
          .font(.largeTitle.weight(.bold))

        choice(
          symbol: "laptopcomputer",
          title: "Fix the Dell laptop",
          detail: "Swap the SSD in 12 steps. No marker needed: you'll tap two corners of the laptop.",
          action: onLaptop
        )
        choice(
          symbol: "qrcode.viewfinder",
          title: "Follow the expert's guide",
          detail: relayConnected
            ? "Connected. Point the camera at the printed marker."
            : "Uses the printed marker. Connect to the expert from the menu to get their guide.",
          action: onMarker
        )
        choice(
          symbol: "cube.transparent",
          title: "Scan the room",
          detail: "For the expert: record a 3D scan lined up with the marker and send it to the laptop.",
          action: onScan
        )

        Spacer()
        Button(action: onSettings) {
          Label("Connection and system check", systemImage: "gearshape")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(.bottom, 8)
      }
      .padding(.horizontal, 20)
    }
  }

  private func choice(symbol: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(alignment: .top, spacing: 14) {
        Image(systemName: symbol)
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(Theme.accent)
          .frame(width: 44)
        VStack(alignment: .leading, spacing: 4) {
          Text(title).font(.title3.weight(.bold)).foregroundStyle(.white)
          Text(detail).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.leading)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right").foregroundStyle(.secondary).padding(.top, 6)
      }
      .padding(18)
      .glassBackground(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}
