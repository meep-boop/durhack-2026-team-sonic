import SwiftUI

struct ContentView: View {
  @State var player: GuidePlayer
  @State private var ar = ARSessionController()
  @State private var relay = RelayClient()
  @State private var call = CallManager()
  @State private var laptop = LaptopGuide()
  @State private var voice = VoiceGuide()
  @State private var showingConnection = false
  @State private var showingLaptop = false
  @State private var showingTranscript = false
  @State private var pinMessage: String?
  @State private var verified: [String: StepVerified] = [:]
  @State private var reportURL: URL?
  @State private var syncedToast: String?
  @State private var screwMemory = ScrewMemory()
  @State private var pinTicks = 0
  @State private var spotlight = SpotlightTracker()
  @State private var commands = VoiceCommands()
  @State private var appSpeaking = false
  @AppStorage("ghostToolOn") private var ghostToolOn = true
  @AppStorage("onboarded") private var onboarded = false
  @AppStorage("voiceOn") private var voiceOn = true
  @Environment(\.scenePhase) private var scenePhase

  private var isLaptopGuide: Bool { player.guide.id == LaptopGuide.guideId }

  var body: some View {
    ZStack {
      ARViewContainer(controller: ar)
        .ignoresSafeArea()

      SpotlightOverlay(tracker: spotlight)

      if !ar.markerSeen && !isLaptopGuide {
        FindMarkerHint { showingLaptop = true }.transition(.opacity)
      }

      if ar.markerLostForAWhile && !isLaptopGuide && player.currentStep != nil {
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
          InCallBar(call: call) { showingTranscript = true }
            .transition(.move(edge: .top).combined(with: .opacity))
          CaptionStrip(call: call)
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

        if isLaptopGuide, currentPhase == "refit", let group = screwMemory.group(for: currentLookFor) {
          ScrewMapCard(entries: screwMemory.entries(in: group), photo: screwMemory.photos[group], captive: laptop.captiveScrews)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        StepCard(
          player: player,
          canAdvance: ar.markerSeen || isLaptopGuide,
          outboxCount: relay.outboxCount,
          voiceOn: $voiceOn,
          tools: isLaptopGuide && player.currentStep != nil ? AnyView(LaptopStepTools(laptop: laptop, ghostToolOn: $ghostToolOn)) : nil,
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
      ConnectionSheet(relay: relay, voice: voice, pauseAR: ar.pause, resumeAR: ar.resume)
        .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $showingLaptop) {
      LaptopGuideSheet(laptop: laptop) { guide in
        screwMemory.reset()
        player.replace(with: guide)
        player.restart()
      }
      .presentationDetents([.large])
    }
    .sheet(isPresented: $showingTranscript) {
      TranscriptSheet(call: call).presentationDetents([.medium, .large])
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
    .onChange(of: player.startedAt) {
      // A new guide or a restart: verdicts belong to the run they were given in.
      verified = [:]
    }
    .onChange(of: player.isFinished) { _, finished in
      reportURL = nil
      if finished { makeReport() }
    }
    .sensoryFeedback(.success, trigger: pinTicks)
    .sensoryFeedback(.selection, trigger: spotlight.arrivals)
    .onChange(of: voiceOn) { voiceOn ? speakCurrentStep() : voice.stop() }
    .onChange(of: call.state) { updateListening() }
    .onChange(of: call.state) { old, new in
      if new == .idle, !isLaptopGuide { ar.clearPins(kinds: [.expert]) }
    }
    .onChange(of: relay.state) {
      // A call can't survive losing its signalling path for long; end it rather than leave it hanging.
      if relay.state == .off, call.state != .idle { call.hangUp() }
    }
  }

  private var topBar: some View {
    HStack(spacing: 10) {
      StatusCapsule(ar: ar, relay: relay, call: call) { showingConnection = true }
      Button { showingLaptop = true } label: {
        Image(systemName: "laptopcomputer").font(.headline).frame(width: 44, height: 44)
      }
      .glassBackground(in: Circle())
      .accessibilityLabel("Laptop guide")
    }
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
    call.onExpertClear = { ar.clearPins(kinds: [.expert]) }
    voice.onSpeakingChanged = { speaking in
      appSpeaking = speaking
      updateListening()
    }
    commands.onCommand = { command in run(command) }
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
    // The laptop guide lives only on this phone; the relay has no copy, so it would refuse the tap.
    if !isLaptopGuide { relay.sendStepDone(guide: player.guide, stepId: step.id) }
    player.next()
  }

  private func makeReport() {
    let input = RepairReport.Input(
      title: player.guide.title,
      device: isLaptopGuide ? laptop.device : nil,
      startedAt: player.startedAt,
      finishedAt: Date(),
      steps: player.guide.steps.enumerated().map { index, step in
        RepairReport.StepLine(
          number: index + 1,
          text: step.text,
          doneAt: player.doneAt[step.id].map { Date(timeIntervalSince1970: Double($0) / 1000) },
          rig: verified[step.id]
        )
      },
      safety: isLaptopGuide ? LaptopGuide.safetyItems.map { ($0.text, laptop.safetyChecked.contains($0.id)) } : nil,
      safetyOverridden: laptop.safetyOverridden,
      photo: ar.snapshotJPEG(maxSide: 1200).flatMap(UIImage.init(data:)),
      stepSource: isLaptopGuide ? laptop.stepSource : nil,
      transcript: call.transcript
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
      if ar.markerSeen || isLaptopGuide { next() }
    case .back:
      player.back()
    case .showMe:
      spotlight.enabled = true
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

  /// Pins still to tick on this step, for "3 of 8 done" on the step card. On the laptop guide the expert's pins are
  /// the parts to work on; on a marker guide they're just pointers.
  private var pinProgress: StepCard.PinProgress? {
    let relevant = isLaptopGuide ? ar.pins : ar.pins.filter { $0.kind != .expert }
    guard !relevant.isEmpty else { return nil }
    let refit = relevant.contains { $0.kind == .refit }
    return StepCard.PinProgress(done: relevant.filter(\.done).count, total: relevant.count, verb: refit ? "put back" : "done")
  }

  private var currentPhase: String? {
    isLaptopGuide ? player.currentIndex.flatMap { laptop.phase(stepIndex: $0) } : nil
  }

  private var currentLookFor: String? {
    isLaptopGuide ? player.currentIndex.flatMap { laptop.lookFor(stepIndex: $0) } : nil
  }

  private func stepChanged() {
    // On the laptop guide pins belong to the step they were placed for; on a marker guide expert pins stay up.
    ar.clearPins(kinds: isLaptopGuide ? [.expert, .refit] : [.refit])
    pinMessage = nil
    spotlight.enabled = true
    updateGhost()
    guard isLaptopGuide, player.currentStep != nil else { return }

    if currentPhase == "refit", let group = screwMemory.group(for: currentLookFor) {
      // Screw memory: the same holes come back, last out first in, so each screw returns where it came from.
      ar.placeStoredPins(screwMemory.entries(in: group).reversed().map { ($0.number, $0.label, $0.transform) }, kind: .refit)
      pinMessage = laptop.captiveScrews ? "Tighten each screw as you go" : "Put each screw back in its numbered hole"
    } else if currentPhase == "remove", let part = currentLookFor {
      pinMessage = call.state == .live
        ? "Ask the expert to tap \(part) on their screen"
        : "Call the expert to have \(part) pinned, or just follow the step"
    }
  }

  private func updateGhost() {
    guard isLaptopGuide, ghostToolOn else { ar.ghostTurnsAnticlockwise = nil; return }
    switch currentPhase {
    case "remove": ar.ghostTurnsAnticlockwise = true
    case "refit": ar.ghostTurnsAnticlockwise = false
    default: ar.ghostTurnsAnticlockwise = nil
    }
  }

  private func pinToggled(_ pin: ARSessionController.PinInfo) {
    pinTicks += 1
    guard pin.kind == .expert, currentPhase == "remove" else { return }
    if pin.done {
      screwMemory.remember(pin, group: currentLookFor ?? "screws", note: nil, photo: nil)
    } else {
      screwMemory.forget(pin.id)
    }
  }

}
