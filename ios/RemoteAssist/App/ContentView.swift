import SwiftUI

struct ContentView: View {
  @State var player: GuidePlayer
  @State private var ar = ARSessionController()
  @State private var relay = RelayClient()
  @State private var call = CallManager()
  @State private var assistant = LaptopAssistant()
  @State private var voice = VoiceGuide()
  @State private var showingConnection = false
  @State private var showingAssistant = false
  @State private var aiBusy = false
  @State private var pinMessage: String?
  @State private var verified: [String: StepVerified] = [:]
  @State private var syncedToast: String?
  @AppStorage("onboarded") private var onboarded = false
  @AppStorage("voiceOn") private var voiceOn = true
  @Environment(\.scenePhase) private var scenePhase

  private var isAIGuide: Bool { player.guide.id.hasPrefix("ai-") }

  var body: some View {
    ZStack {
      ARViewContainer(controller: ar)
        .ignoresSafeArea()

      if !ar.markerSeen && !isAIGuide {
        FindMarkerHint().transition(.opacity)
      }

      if ar.markerLostForAWhile && !isAIGuide && player.currentStep != nil {
        Label("Marker out of view: the guide is holding where it was", systemImage: "pin.fill")
          .font(.footnote.weight(.semibold))
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .glassBackground(in: Capsule())
          .frame(maxHeight: .infinity, alignment: .center)
          .allowsHitTesting(false)
          .transition(.opacity)
      }

      VStack(spacing: 12) {
        HStack(spacing: 10) {
          StatusCapsule(ar: ar, relay: relay, call: call) { showingConnection = true }
          if assistant.isAvailable {
            Button { showingAssistant = true } label: {
              Image(systemName: "laptopcomputer").font(.headline).frame(width: 44, height: 44)
            }
            .glassBackground(in: Circle())
            .accessibilityLabel("Laptop assistant")
          }
        }

        if call.state == .ringing {
          IncomingCallBanner(call: call)
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if call.state != .idle {
          InCallBar(call: call)
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        if let error = ar.errorMessage {
          Label(error, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .padding(10)
            .glassBackground(in: RoundedRectangle(cornerRadius: 14))
        }

        if let syncedToast {
          Label(syncedToast, systemImage: "checkmark.circle.fill")
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassBackground(in: Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        if let pinMessage {
          Text(pinMessage)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassBackground(in: Capsule())
            .transition(.opacity)
        }

        Spacer()

        StepCard(
          player: player,
          canAdvance: ar.markerSeen || isAIGuide,
          outboxCount: relay.outboxCount,
          voiceOn: $voiceOn,
          tools: isAIGuide && player.currentStep != nil ? AnyView(aiTools) : nil,
          verification: player.currentStepId.flatMap { verified[$0] },
          onNext: next,
          onBack: player.back
        )
      }
      .padding(.horizontal)
      .padding(.top, 4)
      .padding(.bottom, 8)

      if let face = call.remoteVideoTrack, call.state == .live {
        RemoteVideoView(track: face, isActive: scenePhase == .active)
          .frame(width: 96, height: 128)
          .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.4), lineWidth: 1))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding(.top, 130)
          .padding(.trailing)
      }
    }
    .animation(.snappy, value: call.state)
    .animation(.easeInOut, value: ar.markerSeen)
    .animation(.easeInOut, value: ar.markerLostForAWhile)
    .animation(.easeInOut, value: pinMessage)
    .animation(.snappy, value: syncedToast)
    .onChange(of: relay.outboxCount) { old, new in
      // The offline queue just drained into the expert's view: say so, as in the explainer video.
      guard new < old, relay.state == .connected else { return }
      syncedToast = "\(old - new) step\(old - new == 1 ? "" : "s") synced to the expert"
      Task {
        try? await Task.sleep(for: .seconds(2.5))
        syncedToast = nil
      }
    }
    .sheet(isPresented: $showingConnection) {
      ConnectionSheet(relay: relay, pauseAR: ar.pause, resumeAR: ar.resume)
        .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $showingAssistant) {
      LaptopAssistantSheet(
        assistant: assistant,
        snapshot: { ar.snapshotJPEG() },
        onStart: { guide in player.replace(with: guide) },
        onAskExpert: { showingAssistant = false; showingConnection = true }
      )
      .presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: .constant(!onboarded)) {
      Onboarding { onboarded = true }
    }
    .onAppear(perform: wire)
    .onChange(of: onboarded) { if onboarded { ar.start() } }
    .onChange(of: scenePhase) { _, phase in handle(phase) }
    .task { await Shapes.preloadModels() }
    // Step is compared by value, so a guide.set that edits the current step's objects redraws it too.
    .onChange(of: player.currentStep) {
      ar.step = player.currentStep
      ar.clearPins()
      pinMessage = nil
      speakCurrentStep()
    }
    .onChange(of: voiceOn) { voiceOn ? speakCurrentStep() : voice.stop() }
    .onChange(of: call.state) { old, new in
      // AI pins are for working alone; when the expert joins they point at things themselves.
      if old == .ringing, new == .connecting { ar.clearPins(); pinMessage = nil }
    }
    .onChange(of: relay.state) {
      // A call can't survive losing its signalling path for long; end it rather than leave it hanging.
      if relay.state == .off, call.state != .idle { call.hangUp() }
    }
  }

  private var aiTools: some View {
    AIStepTools(assistant: assistant, busy: aiBusy, onShowWhere: showWhere, onCheck: checkWork)
  }

  private func wire() {
    ar.step = player.currentStep
    ar.onPose = { [relay] pose in relay.sendPose(pose) }
    // Runs on the AR session queue; the source checks its own thread-safe switch, set by CallManager.
    ar.onCameraFrame = { [videoSource = call.videoSource] buffer, time in
      videoSource.push(buffer, timestamp: time)
    }
    relay.onGuide = { [player] guide in player.replace(with: guide) }
    relay.onStepSet = { [player] message in
      if message.guideId == player.guide.id { player.jump(to: message.stepId) }
    }
    relay.onSignal = { [call] signal in call.receive(signal) }
    relay.onStepVerified = { message in
      if message.guideId == player.guide.id { verified[message.stepId] = message }
    }
    call.sendSignal = { [relay] signal in relay.sendSignal(signal) }
    relay.connectSaved()
    if onboarded { ar.start() }
  }

  /// Background: no AR (iOS takes the camera anyway), no GPU drawing, no reading aloud. A live call keeps its voice
  /// (UIBackgroundModes audio) and stops its video until the user is back.
  private func handle(_ phase: ScenePhase) {
    switch phase {
    case .background:
      ar.pause()
      voice.stop()
      call.setBackgrounded(true)
    case .active:
      call.setBackgrounded(false)
      if onboarded { ar.resume() }
      relay.appBecameActive()
    default:
      break
    }
  }

  private func next() {
    guard let step = player.currentStep else { return }
    relay.sendStepDone(guide: player.guide, stepId: step.id)
    player.next()
  }

  private func speakCurrentStep() {
    guard voiceOn, let step = player.currentStep else { return }
    voice.speak(step.text)
  }

  private func showWhere() {
    guard let index = player.currentIndex, let target = assistant.lookFor(stepIndex: index), let jpeg = ar.snapshotJPEG() else { return }
    aiBusy = true
    Task {
      defer { aiBusy = false }
      do {
        let points = try await assistant.locate(target, jpeg: jpeg)
        let placed = ar.placePins(points.map { ($0.x, $0.y, $0.label) })
        pinMessage = placed > 0 ? "Pinned \(placed) × \(target)" : "Couldn't spot \(target). Move closer and try again."
      } catch {
        pinMessage = "Couldn't look: \(error.localizedDescription)"
      }
    }
  }

  private func checkWork() {
    guard let step = player.currentStep, let jpeg = ar.snapshotJPEG() else { return }
    aiBusy = true
    Task {
      await assistant.check(step: step.text, jpeg: jpeg)
      aiBusy = false
      if voiceOn, let feedback = assistant.lastCheck?.feedback { voice.speak(feedback) }
    }
  }
}
