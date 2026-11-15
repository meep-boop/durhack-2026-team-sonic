import AVFoundation
import Observation
import WebRTC

/// One call with the expert. The expert always offers (from the dashboard or ios/expert-call); the phone rings, the
/// user accepts, and the phone answers with its microphone and the AR camera. Signalling rides the relay's rtc.signal.
@Observable
final class CallManager: NSObject {
  enum State: Equatable {
    case idle, ringing, connecting, live, reconnecting
  }

  private(set) var state: State = .idle {
    didSet { updateVideoFlow() }
  }
  private(set) var isMuted = false
  private(set) var isSpeakerOn = true
  /// Set when the expert sends their webcam, so the phone can show a face bubble.
  private(set) var remoteVideoTrack: RTCVideoTrack?

  @ObservationIgnored var sendSignal: ((RtcSignal) -> Void)?

  /// The expert tapped a spot on the live video. Fractions of the upright video, plus how long ago (seconds) that
  /// frame left the phone, by the expert page's own estimate.
  struct ExpertTap: Equatable {
    var id: String
    var x: Double
    var y: Double
    var label: String
    var secondsAgo: Double
  }
  /// Called on main; returns whether the tap landed on a surface, which goes back to the expert as ✓ or "missed".
  @ObservationIgnored var onExpertTap: ((ExpertTap) -> Bool)?
  @ObservationIgnored var onExpertClear: (() -> Void)?
  /// Not lazy: the AR session queue pushes frames into it, and a lazy var must not be created from two threads.
  @ObservationIgnored let videoSource: ArFrameVideoSource

  @ObservationIgnored private let factory: RTCPeerConnectionFactory
  @ObservationIgnored private var peer: RTCPeerConnection?
  @ObservationIgnored private var audioTrack: RTCAudioTrack?
  @ObservationIgnored private var videoTrack: RTCVideoTrack?
  @ObservationIgnored private var backgrounded = false
  @ObservationIgnored private let audioSession = AudioSessionCoordinator.shared
  @ObservationIgnored private var control: RTCDataChannel?
  @ObservationIgnored private var pendingOffer: String?
  @ObservationIgnored private var pendingCandidates: [RTCIceCandidate] = []
  @ObservationIgnored private var expertSendsVideo = false

  var isSendingVideo: Bool { state == .connecting || state == .live || state == .reconnecting }

  override init() {
    RTCInitializeSSL()
    factory = RTCPeerConnectionFactory(
      encoderFactory: RTCDefaultVideoEncoderFactory(),
      decoderFactory: RTCDefaultVideoDecoderFactory()
    )
    videoSource = ArFrameVideoSource(factory: factory)
    super.init()
  }

  // MARK: Signalling in

  func receive(_ signal: RtcSignal) {
    switch signal {
    case .offer(let sdp):
      // Anyone on the relay can send an offer, so a second one never cuts into a live call; it can only ring when
      // the phone is free (or replace an unanswered ring), and the user still has to accept it.
      guard state == .idle || state == .ringing else { return }
      pendingOffer = sdp
      pendingCandidates = []
      state = .ringing
    case .answer:
      break  // The phone never offers, so it never expects an answer.
    case .candidate(let candidate, let sdpMid, let sdpMLineIndex):
      let ice = RTCIceCandidate(sdp: candidate, sdpMLineIndex: Int32(sdpMLineIndex ?? 0), sdpMid: sdpMid)
      if let peer, peer.remoteDescription != nil {
        peer.add(ice) { _ in }
      } else {
        pendingCandidates.append(ice)
      }
    }
  }

  // MARK: User actions

  func accept() {
    guard state == .ringing, let offer = pendingOffer else { return }
    pendingOffer = nil
    expertSendsVideo = Self.offerSendsVideo(offer)
    state = .connecting
    audioSession.beginCall(speakerOn: isSpeakerOn)

    let config = RTCConfiguration()
    config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
    config.sdpSemantics = .unifiedPlan
    config.continualGatheringPolicy = .gatherContinually
    let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    guard let peer = factory.peerConnection(with: config, constraints: constraints, delegate: self) else {
      state = .idle
      return
    }
    self.peer = peer

    let audio = factory.audioTrack(with: factory.audioSource(with: constraints), trackId: "phone-audio")
    audioTrack = audio
    audio.isEnabled = !isMuted
    peer.add(audio, streamIds: ["phone"])
    let video = factory.videoTrack(with: videoSource.source, trackId: "phone-camera")
    videoTrack = video
    peer.add(video, streamIds: ["phone"])
    updateVideoFlow()

    // WebRTC calls these back on its own signalling thread; every state change hops to main, and a failure at any
    // step ends the call instead of leaving it stuck on "Connecting…".
    peer.setRemoteDescription(RTCSessionDescription(type: .offer, sdp: offer)) { [weak self] error in
      guard error == nil else { return self?.failCall(peer) ?? () }
      self?.onMain { self?.flushCandidates() }
      peer.answer(for: constraints) { answer, error in
        guard let answer, error == nil else { return self?.failCall(peer) ?? () }
        peer.setLocalDescription(answer) { error in
          guard error == nil else { return self?.failCall(peer) ?? () }
          self?.onMain {
            guard let self, peer === self.peer else { return }
            self.sendSignal?(.answer(sdp: answer.sdp))
          }
        }
      }
    }
  }

  func decline() {
    pendingOffer = nil
    pendingCandidates = []
    state = .idle
  }

  func hangUp() {
    // Closing the data channel is how the expert's page learns the call ended (the contract has no hang-up message).
    control?.close()
    tearDown()
  }

  func toggleMute() {
    isMuted.toggle()
    audioTrack?.isEnabled = !isMuted
  }

  func toggleSpeaker() {
    isSpeakerOn.toggle()
    audioSession.setSpeaker(isSpeakerOn)
  }

  /// In the background the call keeps its voice but sends no camera: ARKit has no camera there anyway, and iOS
  /// refuses GPU work from a backgrounded app. The expert sees the last frame until the user comes back.
  func setBackgrounded(_ value: Bool) {
    backgrounded = value
    updateVideoFlow()
  }

  // MARK: Internals

  /// A video section the expert sends on (not just receives) means their webcam is on, so the face bubble shows.
  private static func offerSendsVideo(_ sdp: String) -> Bool {
    let sections = sdp.components(separatedBy: "m=")
    guard let video = sections.first(where: { $0.hasPrefix("video") }) else { return false }
    return video.contains("a=sendrecv") || video.contains("a=sendonly")
  }

  private func flushCandidates() {
    pendingCandidates.forEach { peer?.add($0) { _ in } }
    pendingCandidates = []
  }

  private func updateVideoFlow() {
    let sending = isSendingVideo && !backgrounded
    videoSource.isEnabled = sending
    videoTrack?.isEnabled = sending
  }

  private func failCall(_ peer: RTCPeerConnection) {
    onMain { [weak self] in
      guard let self, peer === self.peer else { return }
      self.hangUp()
    }
  }

  private func tearDown() {
    peer?.close()
    peer = nil
    control = nil
    audioTrack = nil
    videoTrack = nil
    remoteVideoTrack = nil
    pendingOffer = nil
    pendingCandidates = []
    state = .idle
    audioSession.endCall()
  }

  private func onMain(_ work: @escaping () -> Void) {
    DispatchQueue.main.async(execute: work)
  }
}

extension CallManager: RTCPeerConnectionDelegate {
  func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
  func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

  func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
    onMain { [weak self] in
      guard let self, peerConnection === self.peer else { return }
      switch newState {
      case .connected, .completed: self.state = .live
      case .disconnected: self.state = .reconnecting
      case .failed, .closed: self.tearDown()
      default: break
      }
    }
  }

  func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
    onMain { [weak self] in
      self?.sendSignal?(.candidate(candidate: candidate.sdp, sdpMid: candidate.sdpMid, sdpMLineIndex: Int(candidate.sdpMLineIndex)))
    }
  }

  func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
    dataChannel.delegate = self
    onMain { [weak self] in self?.control = dataChannel }
  }

  func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
    guard expertSendsVideo, let video = rtpReceiver.track as? RTCVideoTrack else { return }
    onMain { [weak self] in self?.remoteVideoTrack = video }
  }
}

extension CallManager: RTCDataChannelDelegate {
  func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
    guard dataChannel.readyState == .closed else { return }
    onMain { [weak self] in
      guard let self, dataChannel === self.control else { return }
      self.tearDown()
    }
  }

  /// Point-and-guide rides the call's own channel, peer to peer, so it needs no relay or contract change:
  /// `ping` → `pong` (for the expert page's latency estimate), `tap` → a pin, then `pinned`, and `clear`.
  func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
    guard !buffer.isBinary,
          let message = try? JSONSerialization.jsonObject(with: buffer.data) as? [String: Any],
          let kind = message["kind"] as? String else { return }
    switch kind {
    case "ping":
      Self.send(["kind": "pong", "t": message["t"] ?? 0], on: dataChannel)
    case "tap":
      guard let id = message["id"] as? String, let x = message["x"] as? Double, let y = message["y"] as? Double,
            (0...1).contains(x), (0...1).contains(y) else { return }
      let tap = ExpertTap(
        id: id, x: x, y: y,
        label: (message["label"] as? String).flatMap { $0.isEmpty ? nil : String($0.prefix(40)) } ?? "here",
        // Clamped: the camera history only goes back about 2.5 s.
        secondsAgo: min(max(message["latency"] as? Double ?? 0.15, 0), 2)
      )
      onMain { [weak self] in
        let ok = self?.onExpertTap?(tap) ?? false
        Self.send(["kind": "pinned", "id": id, "ok": ok], on: dataChannel)
      }
    case "clear":
      onMain { [weak self] in self?.onExpertClear?() }
    default:
      break
    }
  }

  private static func send(_ message: [String: Any], on channel: RTCDataChannel) {
    guard channel.readyState == .open, let data = try? JSONSerialization.data(withJSONObject: message) else { return }
    channel.sendData(RTCDataBuffer(data: data, isBinary: false))
  }
}
