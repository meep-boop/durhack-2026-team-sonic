import SwiftUI
import simd

/// Where the laptop setup is: finding the table, then the two corners.
enum LaptopSetupStage: Equatable {
  case surface
  case cornerA
  /// The first corner, and the surface's normal there.
  case cornerB(SIMD3<Float>, SIMD3<Float>)

  var number: Int {
    switch self {
    case .surface: 1
    case .cornerA: 2
    case .cornerB: 3
    }
  }
}

/// One instruction at a time, so anyone can line the AR up with the laptop: find the surface, tap one corner, tap
/// the opposite one. The AR view stays visible underneath; taps on it go to ARKit.
struct LaptopSetupCoach: View {
  let stage: LaptopSetupStage
  let problem: String?
  let onCancel: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("SET UP THE LAPTOP · \(stage.number) OF 3")
          .font(.caption.weight(.bold))
          .foregroundStyle(.secondary)
        Spacer()
        Button("Cancel", action: onCancel).font(.footnote.weight(.semibold))
      }

      HStack(spacing: 6) {
        ForEach(1...3, id: \.self) { i in
          Capsule()
            .fill(i < stage.number ? Color.white : (i == stage.number ? Theme.accent : Color.secondary.opacity(0.3)))
            .frame(height: 5)
        }
      }

      HStack(alignment: .top, spacing: 12) {
        Image(systemName: symbol)
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(Theme.accent)
          .frame(width: 40)
          .symbolEffect(.pulse, options: .repeating)
        VStack(alignment: .leading, spacing: 4) {
          Text(title).font(.headline)
          Text(detail).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
      }

      if let problem {
        Label(problem, systemImage: "exclamationmark.triangle.fill")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.orange)
      }
    }
    .padding(16)
    .glassBackground(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .animation(.snappy, value: stage)
    .sensoryFeedback(.impact(weight: .light), trigger: stage)
  }

  private var symbol: String {
    switch stage {
    case .surface: "iphone.gen3.radiowaves.left.and.right"
    case .cornerA: "hand.tap.fill"
    case .cornerB: "arrow.down.right.circle.fill"
    }
  }

  private var title: String {
    switch stage {
    case .surface: "Find the laptop's surface"
    case .cornerA: "Tap the top-left corner"
    case .cornerB: "Now tap the opposite corner"
    }
  }

  private var detail: String {
    switch stage {
    case .surface: "Lay the laptop face down. Hold the phone about 40 cm above it and move it slowly, so the camera sees the whole cover."
    case .cornerA: "The top edge is the one with the U-shaped notches. Tap exactly on its left-hand corner, on the screen."
    case .cornerB: "Tap the bottom-right corner, diagonally across. A purple outline will lock onto the laptop."
    }
  }
}
