import SwiftUI

struct Onboarding: View {
  let onFinish: () -> Void
  @State private var page = 0

  private let pages: [(symbol: String, title: String, body: String)] = [
    ("hand.raised.fingers.spread.fill", "Fix it yourself, calmly",
     "Remote Assist shows you exactly what to do, one step at a time, right on top of the real thing."),
    ("qrcode", "Find the marker",
     "Place the printed marker (180 mm square) next to the device. Your phone uses it to line every step up with the real parts."),
    ("person.wave.2.fill", "An expert is one tap away",
     "If you get stuck, an expert can see your camera and talk you through it. Your steps keep working even if the internet drops."),
  ]

  var body: some View {
    VStack(spacing: 0) {
      TabView(selection: $page) {
        ForEach(pages.indices, id: \.self) { i in
          VStack(spacing: 24) {
            Spacer()
            Image(systemName: pages[i].symbol)
              .font(.system(size: 72, weight: .semibold))
              .foregroundStyle(.tint)
              .symbolEffect(.bounce, value: page == i)
            Text(pages[i].title)
              .font(.largeTitle.weight(.bold))
              .multilineTextAlignment(.center)
            Text(pages[i].body)
              .font(.body)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
            Spacer()
          }
          .tag(i)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))

      Button {
        if page < pages.count - 1 {
          withAnimation { page += 1 }
        } else {
          onFinish()
        }
      } label: {
        Text(page < pages.count - 1 ? "Continue" : "Get started")
          .font(.headline)
          .frame(maxWidth: .infinity, minHeight: 54)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.capsule)
      .padding(.horizontal, 24)
      .padding(.bottom, 12)

      Button("Skip", action: onFinish)
        .font(.subheadline)
        .padding(.bottom, 24)
        .opacity(page < pages.count - 1 ? 1 : 0)
    }
  }
}

/// Corner brackets that breathe until the marker is found, so a first-time user knows what to point at.
struct FindMarkerHint: View {
  /// Opens the laptop guide, for anyone working on the laptop without the printed marker.
  var onUseAI: () -> Void = {}

  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        ForEach(0..<4, id: \.self) { corner in
          Bracket()
            .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 44, height: 44)
            .rotationEffect(.degrees(Double(corner) * 90))
            .offset(x: corner == 0 || corner == 3 ? -78 : 78, y: corner < 2 ? -78 : 78)
        }
      }
      .frame(width: 200, height: 200)
      .phaseAnimator([1.0, 0.9]) { $0.scaleEffect($1) } animation: { _ in .easeInOut(duration: 1.1) }

      Text("Point at the marker")
        .font(.headline)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassBackground(in: Capsule())
        .allowsHitTesting(false)

      Button(action: onUseAI) {
        Label("No marker? Start the laptop guide", systemImage: "laptopcomputer")
          .font(.subheadline.weight(.semibold))
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
      }
      .buttonStyle(.plain)
      .glassBackground(in: Capsule())
    }
  }

  private struct Bracket: Shape {
    func path(in rect: CGRect) -> Path {
      var path = Path()
      path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      return path
    }
  }
}
