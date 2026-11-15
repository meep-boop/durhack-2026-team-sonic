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

/// Controls while the expert is on the line.
struct InCallBar: View {
  let call: CallManager

  var body: some View {
    HStack(spacing: 18) {
      Label(call.state == .reconnecting ? "Reconnecting…" : (call.state == .connecting ? "Connecting…" : "Expert is watching"), systemImage: "eye.fill")
        .font(.footnote.weight(.semibold))
        .labelStyle(.titleAndIcon)
        .foregroundStyle(call.state == .live ? .primary : .secondary)
      Spacer(minLength: 0)
      control(call.isMuted ? "mic.slash.fill" : "mic.fill", active: call.isMuted, label: call.isMuted ? "Unmute" : "Mute", action: call.toggleMute)
      control(call.isSpeakerOn ? "speaker.wave.2.fill" : "speaker.fill", active: call.isSpeakerOn, label: "Speaker", action: call.toggleSpeaker)
      Button(action: call.hangUp) {
        Image(systemName: "phone.down.fill").frame(width: 44, height: 44)
      }
      .background(.red, in: Circle())
      .foregroundStyle(.white)
      .accessibilityLabel("End call")
    }
    .padding(.leading, 18)
    .padding(.trailing, 8)
    .padding(.vertical, 8)
    .glassBackground(in: Capsule())
  }

  private func control(_ symbol: String, active: Bool, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol).frame(width: 44, height: 44)
    }
    .background(active ? Color.white.opacity(0.9) : Color.white.opacity(0.15), in: Circle())
    .foregroundStyle(active ? .black : .white)
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
