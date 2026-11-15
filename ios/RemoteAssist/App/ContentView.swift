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
  @State private var showingChat = false
  @State private var aiBusy = false
  @State private var pinMessage: String?
  @State private var verified: [String: StepVerified] = [:]
  /// The AI's "check my work" verdict per step id, for the report.
  @State private var aiChecks: [String: LaptopAssistant.Check] = [:]
  @State private var reportURL: URL?
  @State private var syncedToast: String?
  @State private var locateTask: Task<Void, Never>?
  /// The last AI locate on this step: the photo (for the screw map) and the notes per part.
  @State private var lastLocate: (snapshot: ARSessionController.Snapshot, located: LaptopAssistant.Located)?
  @State private var screwMemory = ScrewMemory()
  @State private var pinTicks = 0
  @State private var spotlight = SpotlightTracker()
  @State private var commands = VoiceCommands()
  @State private var appSpeaking = false
  @AppStorage("ghostToolOn") private var ghostToolOn = true
  @AppStorage("onboarded") private var onboarded = false
  @AppStorage("voiceOn") private var voiceOn = true
  @Environment(\.scenePhase) private var scenePhase

  private var isAIGuide: Bool { player.guide.id.hasPrefix("ai-") }

  var body: some View {
    ZStack {
      ARViewContainer(controller: ar)
        .ignoresSafeArea()

      SpotlightOverlay(tracker: spotlight)

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
        topBar

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

        if isAIGuide, currentPhase == "refit", !screwMemory.isEmpty {
          ScrewMapCard(memory: screwMemory)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        StepCard(
          player: player,
          canAdvance: ar.markerSeen || isAIGuide,
          outboxCount: relay.outboxCount,
          voiceOn: $voiceOn,
          tools: isAIGuide && player.currentStep != nil ? AnyView(aiTools) : nil,
          pinProgress: pinProgress,
          handsFree: (commands.isOn, commands.heard, commands.problem),
          onToggleHandsFree: commands.toggle,
          reportURL: reportURL,
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
        onStart: { guide in
          screwMemory.reset()
          player.replace(with: guide)
        },
        onAskExpert: { showingAssistant = false; showingConnection = true }
      )
      .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $showingChat) {
      ChatSheet(relay: relay).presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: .constant(!onboarded)) {
      Onboarding { onboarded = true }
    }
    .onAppear(perform: wire)
    .onChange(of: onboarded) { if onboarded { ar.start() } }
    .onChange(of: scenePhase) { _, phase in handle(phase) }
    .task { await Shapes.preloadModels() }
    // Step is compared by value, so a guide.set that edits the current step's objects redraws it too.
    .onChange(of: player.currentStep) { old, new in
      ar.step = new
      speakCurrentStep()
      // Same step, edited by a guide.set: just redraw. A new step clears this step's pins and looks again.
      guard old?.id != new?.id else { return }
      stepChanged()
    }
    .onChange(of: ghostToolOn) { updateGhost() }
    .onChange(of: player.isFinished) { _, finished in
      reportURL = nil
      if finished { makeReport() }
    }
    .sensoryFeedback(.success, trigger: pinTicks)
    .sensoryFeedback(.selection, trigger: spotlight.arrivals)
    .onChange(of: voiceOn) { voiceOn ? speakCurrentStep() : voice.stop() }
    .onChange(of: call.state) { updateListening() }
    .onChange(of: call.state) { old, new in
      // AI pins are for working alone; when the expert joins they point at things themselves.
      if old == .ringing, new == .connecting { ar.clearPins(kinds: [.ai], focus: true); pinMessage = nil }
      if new == .idle { ar.clearPins(kinds: [.expert], focus: false) }
    }
    .onChange(of: relay.state) {
      // A call can't survive losing its signalling path for long; end it rather than leave it hanging.
      if relay.state == .off, call.state != .idle { call.hangUp() }
    }
  }

  private var topBar: some View {
    HStack(spacing: 10) {
      StatusCapsule(ar: ar, relay: relay, call: call) { showingConnection = true }
      ChatButton(unread: relay.unreadChat) { showingChat = true }
      if assistant.isAvailable {
        Button { showingAssistant = true } label: {
          Image(systemName: "laptopcomputer").font(.headline).frame(width: 44, height: 44)
        }
        .glassBackground(in: Circle())
        .accessibilityLabel("Laptop assistant")
      }
    }
  }

  private var aiTools: some View {
    AIStepTools(assistant: assistant, busy: aiBusy, ghostToolOn: $ghostToolOn, onShowWhere: showWhere, onCheck: checkWork)
  }

  private func wire() {
    ar.step = player.currentStep
    ar.onPinToggled = { pin in pinToggled(pin) }
    spotlight.start(ar)
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
    call.onExpertTap = { tap in
      guard ar.placeExpertPin(at: CGPoint(x: tap.x, y: tap.y), label: tap.label, secondsAgo: tap.secondsAgo) else { return false }
      spotlight.enabled = true
      pinTicks += 1
      pinMessage = "The expert marked: \(tap.label)"
      return true
    }
    call.onExpertClear = { ar.clearPins(kinds: [.expert], focus: false) }
    voice.onSpeakingChanged = { speaking in
      appSpeaking = speaking
      updateListening()
    }
    commands.onCommand = { command in run(command) }
    relay.onChat = { message in
      // Hands busy: read the expert's message out, unless the chat is open and they can see it.
      if voiceOn, !showingChat { voice.speak("The expert says: \(message.text)") }
    }
    relay.connectSaved()
    if onboarded { ar.start() }
  }

  /// Background: no AR (iOS takes the camera anyway), no GPU drawing, no reading aloud. A live call keeps its voice
  /// (UIBackgroundModes audio) and stops its video until the user is back.
  private func handle(_ phase: ScenePhase) {
    switch phase {
    case .background:
      commands.setSuspended(true)
      spotlight.stop()
      ar.pause()
      voice.stop()
      call.setBackgrounded(true)
    case .active:
      updateListening()
      spotlight.start(ar)
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

  private func makeReport() {
    let id = assistant.identification
    let input = RepairReport.Input(
      title: player.guide.title,
      device: isAIGuide ? id.map { "\($0.make) \($0.model)" } : nil,
      deviceConfidence: isAIGuide ? id?.confidence : nil,
      startedAt: player.startedAt,
      finishedAt: Date(),
      steps: player.guide.steps.enumerated().map { index, step in
        RepairReport.StepLine(
          number: index + 1,
          text: step.text,
          doneAt: player.doneAt[step.id].map { Date(timeIntervalSince1970: Double($0) / 1000) },
          rig: verified[step.id],
          aiCheck: aiChecks[step.id]
        )
      },
      safety: isAIGuide ? assistant.safety : nil,
      safetyOverridden: assistant.safetyOverridden,
      aiGenerated: isAIGuide,
      photo: ar.snapshotJPEG(maxSide: 1200).flatMap(UIImage.init(data:))
    )
    reportURL = try? RepairReport.render(input)
  }

  /// The mic listens for commands only when nothing else is using the audio: not while the app talks, not in a call.
  private func updateListening() {
    commands.setSuspended(appSpeaking || call.state != .idle || scenePhase == .background)
  }

  private func run(_ command: VoiceCommands.Command) {
    switch command {
    case .next:
      if ar.markerSeen || isAIGuide { next() }
    case .back:
      player.back()
    case .rescan:
      if isAIGuide { showWhere() } else { spotlight.enabled = true }
    case .check:
      if isAIGuide { checkWork() }
    case .repeatStep:
      if let step = player.currentStep { voice.speak(step.text) }
    case .callExpert:
      showingConnection = true
    }
  }

  private func speakCurrentStep() {
    guard voiceOn, let step = player.currentStep else { return }
    voice.speak(step.text)
  }

  /// Pins still to do on this step (AI or refit), for "3 of 8 removed" on the step card.
  private var pinProgress: StepCard.PinProgress? {
    let relevant = ar.pins.filter { $0.kind != .expert }
    guard !relevant.isEmpty else { return nil }
    let refit = relevant.contains { $0.kind == .refit }
    return StepCard.PinProgress(done: relevant.filter(\.done).count, total: relevant.count, verb: refit ? "put back" : "done")
  }

  private var currentPhase: String? {
    player.currentIndex.flatMap { assistant.phase(stepIndex: $0) }
  }

  private func stepChanged() {
    locateTask?.cancel()
    locateTask = nil
    aiBusy = false
    ar.clearPins(kinds: [.ai, .refit], focus: true)
    lastLocate = nil
    pinMessage = nil
    spotlight.enabled = true
    updateGhost()
    guard isAIGuide, player.currentStep != nil else { return }

    if currentPhase == "refit", !screwMemory.isEmpty {
      // Screw memory: the same holes come back, last out first in, so each screw returns where it came from.
      ar.placeStoredPins(screwMemory.entries.reversed().map { ($0.number, $0.label, $0.transform) }, kind: .refit)
      pinMessage = "Put each screw back in its numbered hole"
    } else {
      showWhere()
    }
  }

  private func updateGhost() {
    guard isAIGuide, ghostToolOn else { ar.ghostTurnsAnticlockwise = nil; return }
    switch currentPhase {
    case "remove": ar.ghostTurnsAnticlockwise = true
    case "refit": ar.ghostTurnsAnticlockwise = false
    default: ar.ghostTurnsAnticlockwise = nil
    }
  }

  private func pinToggled(_ pin: ARSessionController.PinInfo) {
    pinTicks += 1
    guard pin.kind == .ai, currentPhase == "remove" else { return }
    if pin.done {
      let note = lastLocate?.located.items.first { $0.point == pin.photoPoint }?.note
      screwMemory.remember(pin, note: note, photo: lastLocate?.snapshot.image)
    } else {
      screwMemory.forget(pin.id)
    }
  }

  /// Finds the step's parts on the real laptop and pins them there. Runs by itself when an AI step opens.
  private func showWhere() {
    guard let index = player.currentIndex, let step = player.currentStep, let target = assistant.lookFor(stepIndex: index) else { return }
    locateTask?.cancel()
    let stepId = step.id
    aiBusy = true
    locateTask = Task {
      defer { if player.currentStepId == stepId { aiBusy = false } }
      // Pins land on surfaces ARKit has found; without one they'd float or fall to the floor.
      var waited = 0.0
      while !ar.hasHorizontalSurface, waited < 8 {
        pinMessage = "Move the phone slowly around the laptop so I can see its surface"
        try? await Task.sleep(for: .milliseconds(400))
        if Task.isCancelled { return }
        waited += 0.4
      }
      pinMessage = "Hold still: looking for \(target)…"
      guard let snapshot = ar.captureSnapshot() else {
        pinMessage = "The camera isn't ready yet. Try Re-scan."
        return
      }
      do {
        let located = try await assistant.locate(target, step: step.text, snapshot: snapshot)
        guard !Task.isCancelled, player.currentStepId == stepId else { return }
        ar.clearPins(kinds: [.ai], focus: true)
        let placed = ar.placePins(
          located.items.map { ($0.point, $0.label) },
          focus: located.focus,
          focusLabel: located.focusLabel,
          camera: snapshot.camera
        )
        lastLocate = (snapshot, located)
        if placed > 0, currentPhase == "remove" {
          pinMessage = "Found \(placed). Tap each as it comes out, and lay the screws down in order 1 to \(placed)."
        } else if placed > 0 {
          pinMessage = "Found \(placed) × \(target). Tap each one as you go."
        } else if located.focus != nil {
          pinMessage = "Work in the highlighted area"
        } else {
          pinMessage = "Couldn't spot \(target). Move closer and tap Re-scan."
        }
      } catch {
        guard !Task.isCancelled else { return }
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
      if let result = assistant.lastCheck { aiChecks[step.id] = result }
      if voiceOn, let feedback = assistant.lastCheck?.feedback { voice.speak(feedback) }
    }
  }
}
