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
  /// The laptop's frame on the table, once its two corners are tapped. Lives for this AR session only.
  @State private var laptopFrame: LaptopFrame?
  /// Non-nil while the setup coach is showing.
  @State private var setup: LaptopSetupStage?
  @State private var setupProblem: String?
  @State private var layout = LaptopLayout.load()
  /// Teach mode: taps on the laptop record where this step's parts are, instead of ticking pins.
  @State private var teaching = false
  /// The layout as a JSON file to share, rewritten only when the layout changes.
  @State private var layoutFile: URL?
  @State private var confirmingLeave = false
  /// The start screen: what are you fixing? Shown at launch and after leaving a guide.
  @State private var showingHome = true
  /// The last guide the relay sent, to go back to when leaving the laptop guide.
  @State private var relayGuide: Guide?
  /// The expert's last spoken command the phone acted on ("Next step"), shown for a few seconds.
  @State private var expertHeard: String?
  /// A big "Look left" arrow, from the expert's voice, for a few seconds.
  @State private var lookCue: ExpertSpeech.Direction?
  /// Why the relay just refused a finished step, for a few seconds on the step card.
  @State private var refusalNote: String?
  @AppStorage("ghostToolOn") private var ghostToolOn = true
  @AppStorage("onboarded") private var onboarded = false
  @AppStorage("voiceOn") private var voiceOn = true
  @Environment(\.scenePhase) private var scenePhase

  private var isLaptopGuide: Bool { player.guide.id == LaptopGuide.guideId }
  private var inCall: Bool { call.state == .connecting || call.state == .live || call.state == .reconnecting }

  var body: some View {
    lifecycle(relayFeedback(presentations(layers)))
  }

  private var layers: some View {
    ZStack {
      ARViewContainer(controller: ar)
        .ignoresSafeArea()

      if showingHome && inCall {
        liveAssistScreen.transition(.opacity)
      } else if showingHome && showingLaptop {
        LaptopChecklistCard(laptop: laptop, onStart: startLaptopGuide, onCancel: { showingLaptop = false })
          .transition(.opacity)
      } else if showingHome {
        HomeView(
          relayConnected: relay.state == .connected,
          onLaptop: { showingLaptop = true },
          onMarker: { enterGuide() },
          onSettings: { showingConnection = true }
        )
        .transition(.opacity)
      } else {
        guideScreen
      }

      if let lookCue, inCall {
        let cue = ExpertSpeech.cue(for: lookCue)
        VStack(spacing: 10) {
          Image(systemName: cue.symbol).font(.system(size: 64, weight: .bold))
          Text(cue.words).font(.title2.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(28)
        .glassBackground(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .allowsHitTesting(false)
        .transition(.scale.combined(with: .opacity))
      }

      if call.state == .ringing {
        IncomingCallBanner(call: call)
          .padding(.horizontal)
          .frame(maxHeight: .infinity, alignment: .top)
          .transition(.move(edge: .top).combined(with: .opacity))
      }

      // Out of the view tree entirely when the app isn't on screen, so its Metal layer can't ask for drawables.
      if let face = call.remoteVideoTrack, call.state == .live, scenePhase == .active {
        RemoteVideoView(track: face)
          .frame(width: 96, height: 128)
          .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.4), lineWidth: 1))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding(.top, 70)
          .padding(.trailing)
      }
    }
  }

  /// A call answered from the start screen: the camera, undimmed, with the call bar and captions at the top, the
  /// spotlight on whatever the expert marks, and one line saying what just happened. No step card: the expert leads.
  /// When the call ends the start screen comes back by itself.
  private var liveAssistScreen: some View {
    ZStack {
      SpotlightOverlay(tracker: spotlight)
      VStack(spacing: 10) {
        InCallBar(call: call) { showingTranscript = true }
        CaptionStrip(call: call)
        Spacer()
        // The steps are one tap away: the guide screen keeps the call bar, so the call carries on.
        Button(action: enterGuide) {
          Label("Open the guide", systemImage: "list.number")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        Label(expertHeard.map { "Heard “\($0)”" } ?? pinMessage ?? "The expert can see your camera and is guiding you",
              systemImage: expertHeard != nil ? "ear.fill" : "hand.point.up.left.fill")
          .font(.subheadline.weight(.semibold))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .glassBackground(in: Capsule())
      }
      .padding(.horizontal)
      .padding(.top, 4)
      .padding(.bottom, 12)
    }
  }

  /// The camera with one status pill and one menu at the top, and either the setup coach or the step card at the
  /// bottom: never both, and at most one line of extra information.
  private var guideScreen: some View {
    ZStack {
      SpotlightOverlay(tracker: spotlight)

      if !ar.markerSeen && !isLaptopGuide && player.currentStep != nil {
        FindMarkerHint().transition(.opacity)
      }

      VStack(spacing: 10) {
        HStack(spacing: 10) {
          StatusCapsule(ar: ar, relay: relay, call: call, laptopLocked: isLaptopGuide ? laptopFrame != nil : nil) { showingConnection = true }
          Spacer(minLength: 0)
          guideMenu
        }

        if call.state != .idle && call.state != .ringing {
          InCallBar(call: call) { showingTranscript = true }
            .transition(.move(edge: .top).combined(with: .opacity))
          CaptionStrip(call: call)
        }

        if ar.cameraStalled {
          HStack(spacing: 10) {
            Label("The camera stopped updating.", systemImage: "camera.badge.exclamationmark")
              .font(.footnote.weight(.semibold))
            Spacer(minLength: 0)
            Button("Restart camera") { ar.restartCamera() }
              .font(.footnote.weight(.bold))
              .buttonStyle(.borderedProminent)
          }
          .padding(10)
          .glassBackground(in: RoundedRectangle(cornerRadius: 14))
        } else if let error = ar.errorMessage {
          Label(error, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .padding(10)
            .glassBackground(in: RoundedRectangle(cornerRadius: 14))
        }

        Spacer()

        if let setup {
          LaptopSetupCoach(stage: setup, problem: setupProblem, onCancel: cancelSetup)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
          if isLaptopGuide, currentPhase == "refit", let group = screwMemory.group(for: currentLookFor) {
            ScrewMapCard(entries: screwMemory.entries(in: group), photo: screwMemory.photos[group], captive: laptop.captiveScrews)
              .transition(.move(edge: .bottom).combined(with: .opacity))
          }
          stepCard
        }
      }
      .padding(.horizontal)
      .padding(.top, 4)
      .padding(.bottom, 8)
    }
  }

  private var guideMenu: some View {
    GuideMenu(
      isLaptopGuide: isLaptopGuide,
      frameLocked: laptopFrame != nil,
      teaching: teaching,
      inCall: call.state != .idle && call.state != .ringing,
      layoutFile: layoutFile,
      voiceOn: $voiceOn,
      ghostToolOn: $ghostToolOn,
      handsFreeOn: commands.isOn,
      onConnect: { showingConnection = true },
      onTranscript: { showingTranscript = true },
      onSetup: startSetup,
      onTeach: { setTeaching(!teaching) },
      onUndoTeach: undoTeach,
      onHandsFree: commands.toggle,
      onLeave: { confirmingLeave = true }
    )
  }

  /// The single line under the step: the most useful thing to know right now, if anything.
  private var stepNote: StepCard.Note? {
    if teaching {
      let count = layout.part(for: currentLookFor)?.points.count ?? 0
      return .init(text: "Teaching: tap each part on the laptop · \(count) marked", symbol: "hand.point.up.left.fill")
    }
    if let problem = commands.problem { return .init(text: problem, symbol: "mic.badge.xmark", tint: .orange) }
    if let refusalNote { return .init(text: "The relay refused that step: \(refusalNote)", symbol: "exclamationmark.triangle.fill", tint: .orange) }
    if let expertHeard { return .init(text: "Expert: “\(expertHeard)”", symbol: "ear.fill") }
    if let heard = commands.heard { return .init(text: "Heard “\(heard)”", symbol: "mic.fill") }
    if let pinMessage { return .init(text: pinMessage, symbol: "info.circle.fill") }
    if let syncedToast { return .init(text: syncedToast, symbol: "checkmark.circle.fill", tint: .green) }
    if let progress = pinProgress {
      return progress.done == progress.total
        ? .init(text: "All \(progress.total) \(progress.verb). Tap Done.", symbol: "checkmark.circle.fill", tint: .green)
        : .init(text: "\(progress.done) of \(progress.total) \(progress.verb) · tap each pin as you go", symbol: "hand.tap.fill")
    }
    if !isLaptopGuide && !ar.markerSeen { return .init(text: "Point the camera at the printed marker to start", symbol: "qrcode.viewfinder", tint: .secondary) }
    if !isLaptopGuide && ar.markerLostForAWhile { return .init(text: "Marker out of view: the guide is holding where it was", symbol: "pin.fill", tint: .secondary) }
    if relay.outboxCount > 0 {
      return .init(text: "\(relay.outboxCount) finished step\(relay.outboxCount == 1 ? "" : "s") will sync when you're back online", symbol: "icloud.slash", tint: .orange)
    }
    return nil
  }

  /// Sheets and alerts, apart from the layers so the type checker can cope with the screen.
  private func presentations(_ content: some View) -> some View {
    content
    .sheet(isPresented: $showingConnection) {
      ConnectionSheet(relay: relay, voice: voice, onHandsInFront: ar.setHandsInFront, pauseAR: ar.pause, resumeAR: ar.resume)
        .presentationDetents([.medium, .large])
    }
    .alert("Leave this guide?", isPresented: $confirmingLeave) {
      Button("Leave", role: .destructive, action: leaveGuide)
      Button("Stay", role: .cancel) {}
    } message: {
      Text("You'll go back to the start. Your place in the guide is kept.")
    }
    .sheet(isPresented: $showingTranscript) {
      TranscriptSheet(call: call).presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: .constant(!onboarded)) {
      Onboarding { onboarded = true }
    }
  }

  /// What the relay and the expert's voice say back: receipts, refusals, heard commands. Apart from `lifecycle` so
  /// the type checker can cope with the screen.
  private func relayFeedback(_ content: some View) -> some View {
    content
    .animation(.snappy, value: lookCue)
    .animation(.easeInOut, value: expertHeard)
    .animation(.easeInOut, value: refusalNote)
    .onChange(of: relay.receipts) { old, new in
      // Only real receipts: a tap the relay refused also leaves the queue, and must never read as synced.
      guard new > old else { return }
      syncedToast = "\(new - old) step\(new - old == 1 ? "" : "s") synced to the expert"
      Task {
        try? await Task.sleep(for: .seconds(2.5))
        syncedToast = nil
      }
    }
    .onChange(of: relay.refusals) {
      let reason = relay.lastRefusal
      refusalNote = reason
      Task {
        try? await Task.sleep(for: .seconds(4))
        if refusalNote == reason { refusalNote = nil }
      }
    }
  }

  private func lifecycle(_ content: some View) -> some View {
    content
    .animation(.snappy, value: call.state)
    .animation(.snappy, value: setup)
    .task(id: setup) {
      // Step 1 of the setup finishes by itself once ARKit has found a horizontal surface.
      while setup == .surface, !Task.isCancelled {
        if ar.hasHorizontalSurface { setup = .cornerA; break }
        try? await Task.sleep(for: .milliseconds(400))
      }
    }
    .animation(.easeInOut, value: ar.markerSeen)
    .animation(.easeInOut, value: ar.markerLostForAWhile)
    .animation(.easeInOut, value: pinMessage)
    .animation(.snappy, value: syncedToast)
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
    .onChange(of: voiceOn) { voiceOn ? speakCurrentStep() : voice.stop() }
    .onChange(of: call.state) { updateListening() }
    .onChange(of: call.state) { old, new in
      guard new == .idle else { return }
      ar.clearExpertArea()
      lookCue = nil
      expertHeard = nil
      if !isLaptopGuide { ar.clearPins(kinds: [.expert]) }
    }
    .onChange(of: relay.state) {
      // A call can't survive losing its signalling path for long; end it rather than leave it hanging.
      if relay.state == .off, call.state != .idle { call.hangUp() }
    }
  }

  private var stepCard: some View {
    StepCard(
      player: player,
      canAdvance: ar.markerSeen || isLaptopGuide,
      note: stepNote,
      reportURL: reportURL,
      verification: player.currentStepId.flatMap { verified[$0] },
      onNext: next,
      onBack: player.back,
      onLeave: { confirmingLeave = true }
    )
  }

  private func wire() {
    ar.step = player.currentStep
    ar.onPinToggled = { pin in pinToggled(pin) }
    ar.onSurfaceTap = { position, normal in surfaceTapped(position, normal) }
    spotlight.start(ar)
    ar.onPose = { [relay] pose in relay.sendPose(pose) }
    // Runs on the AR session queue; the source checks its own thread-safe switch, set by CallManager.
    ar.onCameraFrame = { [videoSource = call.videoSource] buffer, time in
      videoSource.push(buffer, timestamp: time)
    }
    relay.onGuide = { [player] guide in
      relayGuide = guide
      // The relay replays its guide on every reconnect. The laptop guide lives only on this phone, so that must not
      // pull the user out of it; leaving the laptop guide goes back to this one.
      guard player.guide.id != LaptopGuide.guideId else { return }
      player.replace(with: guide)
    }
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
    call.onExpertArea = { area in
      guard ar.placeExpertArea(corners: area.corners, label: area.label, secondsAgo: area.secondsAgo) else { return false }
      spotlight.enabled = true
      pinTicks += 1
      pinMessage = "The expert marked: \(area.label)"
      return true
    }
    call.onExpertClear = {
      ar.clearPins(kinds: [.expert])
      ar.clearExpertArea()
    }
    call.onExpertLine = { line in heardFromExpert(line.text) }
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
    ARSessionController.log.notice("Scene phase: \(String(describing: phase), privacy: .public)")
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

  /// The expert's finished lines drive the screen when they're a clear command (`ExpertSpeech`), so the user can
  /// keep both hands on the laptop. Each one says what it did, so a wrong guess is visible at once.
  private func heardFromExpert(_ text: String) {
    guard let command = ExpertSpeech.command(in: text) else { return }
    let note: String
    switch command {
    case .next:
      guard !showingHome else { note = "Next step: tap Open the guide first"; break }
      guard player.currentStep != nil else { return }
      guard ar.markerSeen || isLaptopGuide else { note = "Next step: point the camera at the printed marker first"; break }
      next()
      note = "Next step"
    case .back:
      guard !showingHome else { note = "Go back: tap Open the guide first"; break }
      player.back()
      note = "Go back"
    case .look(let direction):
      lookCue = direction
      note = ExpertSpeech.cue(for: direction).words
      Task {
        try? await Task.sleep(for: .seconds(3))
        if lookCue == direction { lookCue = nil }
      }
    case .clear:
      ar.clearPins(kinds: [.expert])
      ar.clearExpertArea()
      note = "Clear the marks"
    }
    pinTicks += 1
    expertHeard = note
    Task {
      try? await Task.sleep(for: .seconds(3))
      if expertHeard == note { expertHeard = nil }
    }
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
    ar.clearPins(kinds: isLaptopGuide ? [.guide, .expert, .refit] : [.refit])
    ar.clearFocus()
    setTeaching(false)
    pinMessage = nil
    spotlight.enabled = true
    updateGhost()
    guard isLaptopGuide, player.currentStep != nil else { return }

    if currentPhase == "refit", let group = screwMemory.group(for: currentLookFor) {
      // Screw memory: the same holes come back, last out first in, so each screw returns where it came from.
      ar.placeStoredPins(screwMemory.entries(in: group).reversed().map { ($0.number, $0.label, $0.transform) }, kind: .refit)
      renderLayout(points: false)
      pinMessage = laptop.captiveScrews ? "Tighten each screw as you go" : "Put each screw back in its numbered hole"
    } else {
      renderLayout(points: true)
      pinMessage = layoutHint
    }
  }

  // MARK: Laptop setup and layout

  /// What the step card says about lighting up this step's parts.
  private var layoutHint: String? {
    guard isLaptopGuide, let part = currentLookFor else { return nil }
    guard laptopFrame != nil else { return "Set up the laptop (tap 2 corners) to light up \(part)" }
    if layout.isTaught(part) { return currentPhase == "remove" ? "Work on each lit pin and tap it when done" : nil }
    guard currentPhase == "remove" || currentPhase == "refit" else { return nil }
    return "Not measured yet: tap Teach and tap \(part) once, or ask the expert to tap them"
  }

  private func startLaptopGuide(_ guide: Guide) {
    showingLaptop = false
    screwMemory.reset()
    player.replace(with: guide)
    player.restart()
    enterGuide()
    if laptopFrame == nil { startSetup() }
  }

  private func enterGuide() {
    showingHome = false
    spotlight.enabled = true
  }

  /// Back to the start screen. Leaving the laptop guide also clears its setup and returns the player to the marker
  /// guide (the relay's latest, or the bundled sample), so "Follow the expert's guide" picks up from there.
  private func leaveGuide() {
    defer {
      showingHome = true
      spotlight.enabled = false
    }
    guard isLaptopGuide else { return }
    cancelSetup()
    setTeaching(false)
    laptopFrame = nil
    ar.showLaptopOutline(nil)
    ar.clearPins()
    ar.clearFocus()
    screwMemory.reset()
    laptop.resetSafety()
    if let guide = relayGuide ?? (try? GuidePlayer.loadBundled()) {
      player.replace(with: guide)
    }
  }

  private func startSetup() {
    setTeaching(false)
    laptopFrame = nil
    ar.showLaptopOutline(nil)
    ar.clearPins(kinds: [.guide])
    ar.clearFocus()
    ar.showCornerMarker(at: nil)
    setupProblem = nil
    // Not .horizontalPlane: that goal waits for plane anchors, and plane detection is off for good.
    ar.setCoachingGoal(.tracking)
    ar.tapMode = .surface
    setup = ar.hasHorizontalSurface ? .cornerA : .surface
    spotlight.enabled = false
  }

  private func cancelSetup() {
    setup = nil
    setupProblem = nil
    ar.showCornerMarker(at: nil)
    ar.setCoachingGoal(.tracking)
    ar.tapMode = teaching ? .surface : .pins
    spotlight.enabled = true
  }

  private func surfaceTapped(_ position: SIMD3<Float>, _ normal: SIMD3<Float>) {
    switch setup {
    case .cornerA:
      setupProblem = nil
      ar.showCornerMarker(at: position)
      setup = .cornerB(position, normal)
    case .cornerB(let a, let firstNormal):
      switch LaptopFrame.make(a: a, c: position, normal: firstNormal, footprint: layout.footprintMetres, screenRight: ar.screenRightInWorld ?? [1, 0, 0]) {
      case .success(let frame):
        laptopFrame = frame
        ar.showLaptopOutline(frame)
        cancelSetup()
        pinTicks += 1
        stepChanged()
      case .failure(let problem):
        ar.showCornerMarker(at: nil)
        setup = .cornerA
        switch problem {
        case .tooClose: setupProblem = "Those corners are too close together for this laptop. Start again from the top-left corner."
        case .tooFar: setupProblem = "Those corners are too far apart for this laptop. Start again from the top-left corner."
        case .sameSpot: setupProblem = "That's the same spot. Tap the top-left corner, then the opposite one."
        }
      }
    default:
      // Teach mode: where this step's part really is, in millimetres from the top-left corner.
      guard teaching, let frame = laptopFrame, let part = currentLookFor else { return }
      layout.teach(frame.mm(of: position), for: part)
      layoutChanged()
      pinTicks += 1
      renderLayout(points: true)
    }
  }

  /// Lights up this step's zone and, when `points`, its parts as numbered pins, from the layout.
  private func renderLayout(points: Bool) {
    ar.clearPins(kinds: [.guide])
    ar.clearFocus()
    guard isLaptopGuide, let frame = laptopFrame, let part = layout.part(for: currentLookFor) else { return }
    if let zone = part.zone {
      ar.showFocus(corners: zone.corners.map { frame.world(mm: $0) }, normal: frame.normal, label: player.currentStep?.text.components(separatedBy: "\n").first ?? "Work here")
    }
    guard points else { return }
    let label = (currentLookFor ?? "").contains("screw") ? "screw" : "here"
    ar.placeStoredPins(part.points.enumerated().map { ($0.offset + 1, label, frame.transform(mm: $0.element)) }, kind: .guide)
    spotlight.enabled = true
  }

  private func layoutChanged() {
    layout.save()
    layoutFile = layout.exportFile()
  }

  private func setTeaching(_ on: Bool) {
    if on, layoutFile == nil { layoutFile = layout.exportFile() }
    teaching = on
    ar.tapMode = on || setup != nil ? .surface : .pins
  }

  private func undoTeach() {
    guard let part = currentLookFor else { return }
    layout.undoLast(for: part)
    layoutChanged()
    renderLayout(points: true)
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
    guard pin.kind == .expert || pin.kind == .guide, currentPhase == "remove" else { return }
    if pin.done {
      screwMemory.remember(pin, group: currentLookFor ?? "screws", note: nil, photo: nil)
    } else {
      screwMemory.forget(pin.id)
    }
  }

}
