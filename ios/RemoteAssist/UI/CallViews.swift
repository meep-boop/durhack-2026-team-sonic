import SwiftUI
import WebRTC

/// The expert ringing in, styled like an iOS call banner.
struct IncomingCallBanner: View {
  let call: CallManager

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "person.crop.circle.fill")
        .font(.system(size: 44))
        .foregroundStyle(.white, .blue)
      VStack(alignment: .leading, spacing: 2) {
        Text("Expert").font(.headline)
        Text("wants to see your camera and talk").font(.subheadline).foregroundStyle(.secondary)
      }
      Spacer(minLength: 8)
      Button(action: call.decline) {
        Image(systemName: "phone.down.fill").font(.title3).frame(width: 50, height: 50)
      }
      .background(.red, in: Circle())
      .foregroundStyle(.white)
      .accessibilityLabel("Decline call")
      Button(action: call.accept) {
        Image(systemName: "phone.fill").font(.title3).frame(width: 50, height: 50)
      }
      .background(.green, in: Circle())
      .foregroundStyle(.white)
      .accessibilityLabel("Accept call")
    }
    .padding(14)
    .glassBackground(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    .sensoryFeedback(.impact(weight: .heavy), trigger: call.state)
  }
}

/// The call in one slim bar: a live dot and the call's clock on the left, mute, speaker and end on the right. The
/// transcript lives in the ••• menu, so the bar fits beside it on a phone held in portrait.
struct CallBar: View {
  let call: CallManager

  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(call.state == .live ? Color.red : Color.orange)
        .frame(width: 8, height: 8)
      // The full status if it fits, else just the clock: never wrapped.
      ViewThatFits(in: .horizontal) {
        status(withName: true)
        status(withName: false)
      }
      Spacer(minLength: 4)
      control(call.isMuted ? "mic.slash.fill" : "mic.fill", on: call.isMuted, label: call.isMuted ? "Unmute" : "Mute", action: call.toggleMute)
      control(call.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.fill", on: !call.isSpeakerOn, label: call.isSpeakerOn ? "Speaker on" : "Speaker off", action: call.toggleSpeaker)
      Button(action: call.hangUp) {
        Image(systemName: "phone.down.fill")
          .font(.subheadline.weight(.semibold))
          .frame(width: 38, height: 38)
          .background(Color.red, in: Circle())
          .foregroundStyle(.white)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("End call")
    }
    .padding(.leading, 14)
    .padding(.trailing, 5)
    .padding(.vertical, 5)
    .glassBackground(in: Capsule())
  }

  @ViewBuilder
  private func status(withName: Bool) -> some View {
    HStack(spacing: 5) {
      switch call.state {
      case .live:
        Text("LIVE").font(.caption.weight(.heavy))
        if let since = call.connectedAt {
          Text(since, style: .timer).font(.footnote.weight(.semibold).monospacedDigit())
        }
      case .reconnecting: Text("Reconnecting…").font(.footnote.weight(.semibold))
      default: Text("Connecting…").font(.footnote.weight(.semibold))
      }
      if withName, call.state == .live {
        Text("· Expert").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
      }
    }
    .lineLimit(1)
    .fixedSize()
  }

  /// White when it's in its unusual state (muted, speaker off), so a glance says something is off.
  private func control(_ symbol: String, on: Bool, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.subheadline.weight(.semibold))
        .frame(width: 38, height: 38)
        .background(on ? Color.white : Color.white.opacity(0.14), in: Circle())
        .foregroundStyle(on ? Color.black : Color.white)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }
}

/// The expert's webcam, when they send it.
struct RemoteVideoView: UIViewRepresentable {
  let track: RTCVideoTrack
  /// False in the background: a Metal view drawing there floods the log with "submit GPU work from background".
  var isActive = true

  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeUIView(context: Context) -> RTCMTLVideoView {
    let view = RTCMTLVideoView()
    view.videoContentMode = .scaleAspectFill
    view.clipsToBounds = true
    view.isEnabled = isActive
    track.add(view)
    context.coordinator.track = track
    return view
  }

  func updateUIView(_ view: RTCMTLVideoView, context: Context) {
    view.isEnabled = isActive
    if context.coordinator.track !== track {
      context.coordinator.track?.remove(view)
      track.add(view)
      context.coordinator.track = track
    }
  }

  /// Without this the track keeps a strong reference to the view and keeps rendering into it after it's gone.
  static func dismantleUIView(_ view: RTCMTLVideoView, coordinator: Coordinator) {
    coordinator.track?.remove(view)
    coordinator.track = nil
  }

  final class Coordinator {
    var track: RTCVideoTrack?
  }
}
