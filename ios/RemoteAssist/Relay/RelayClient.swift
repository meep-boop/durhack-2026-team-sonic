import Foundation
import Observation
import UIKit

/// The phone's websocket to Ahmed's relay. The guide never depends on it: when it's down the app keeps playing what
/// it has, and finished steps wait in the outbox until the link is back.
@Observable
final class RelayClient {
  enum State: Equatable {
    case off, connecting, connected
  }

  private(set) var state: State = .off
  private(set) var expertOnline = false
  private(set) var lastError: String?
  private(set) var outboxCount = 0
  private(set) var url: URL?
  /// The conversation with the expert, oldest first, including messages still waiting to send.
  private(set) var chat: [ChatMessage] = [] {
    didSet { Persistence.save(Array(chat.suffix(100)), as: Self.chatFile) }
  }
  private(set) var unreadChat = 0
  /// Ids of messages typed here that haven't reached the relay yet.
  private(set) var pendingChatIds: Set<String> = []
  /// Ids of every message typed on this phone. "Mine" is decided by this, never by the `from` a message claims:
  /// anyone on the relay can send `from: "user"`.
  private(set) var sentChatIds: Set<String> = [] {
    didSet { Persistence.save(sentChatIds, as: Self.chatSentFile) }
  }
  /// The relay refused a chat message: it's an older relay without the (proposed) chat message.
  private(set) var chatUnsupported = false

  @ObservationIgnored var onGuide: ((Guide) -> Void)?
  @ObservationIgnored var onStepSet: ((StepSet) -> Void)?
  @ObservationIgnored var onSignal: ((RtcSignal) -> Void)?
  @ObservationIgnored var onStepVerified: ((StepVerified) -> Void)?
  @ObservationIgnored var onChat: ((ChatMessage) -> Void)?

  @ObservationIgnored private let session = URLSession(configuration: .default)
  @ObservationIgnored private var task: URLSessionWebSocketTask?
  // Bumped on every new socket, so callbacks from a dead socket can't touch the current one.
  @ObservationIgnored private var generation = 0
  @ObservationIgnored private var attempt = 0
  /// Saved on every change, so steps finished offline still reach the expert after the app is killed.
  @ObservationIgnored private var outbox: [StepDone] = [] {
    didSet {
      outboxCount = outbox.count
      Persistence.save(outbox, as: Self.outboxFile)
    }
  }
  @ObservationIgnored private var flushing = false
  /// Chat typed offline waits here, like finished steps, and survives an app kill.
  @ObservationIgnored private var chatOutbox: [ChatMessage] = [] {
    didSet {
      pendingChatIds = Set(chatOutbox.map(\.id))
      Persistence.save(chatOutbox, as: Self.chatOutboxFile)
    }
  }
  @ObservationIgnored private var flushingChat = false
  @ObservationIgnored private var pingTimer: Timer?
  /// False after the user taps Disconnect, so coming back from the background doesn't reconnect behind their back.
  @ObservationIgnored private var wantsConnection = false

  private static let urlKey = "relayURL"
  private static let outboxFile = "outbox"
  private static let chatFile = "chat"
  private static let chatOutboxFile = "chat-outbox"
  private static let chatSentFile = "chat-sent"
  private static let chatLimit = 100
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init() {
    if let saved = UserDefaults.standard.string(forKey: Self.urlKey), let url = URL(string: saved) {
      self.url = url
    }
    outbox = Persistence.load([StepDone].self, from: Self.outboxFile) ?? []
    chat = Persistence.load([ChatMessage].self, from: Self.chatFile) ?? []
    chatOutbox = Persistence.load([ChatMessage].self, from: Self.chatOutboxFile) ?? []
    sentChatIds = Persistence.load(Set<String>.self, from: Self.chatSentFile) ?? []
  }

  // MARK: Connection

  func connect(to url: URL) {
    // A different relay is a different session: its expert mustn't see (or receive) chat meant for the last one.
    if let old = self.url, old != url { clearChat() }
    UserDefaults.standard.set(url.absoluteString, forKey: Self.urlKey)
    self.url = url
    attempt = 0
    open()
  }

  func connectSaved() {
    if url != nil { open() }
  }

  /// Back from the background: iOS has usually killed the socket while we were suspended, and the backoff timer may
  /// be up to 10 s away, so reconnect now rather than show "Reconnecting" for no reason.
  func appBecameActive() {
    guard wantsConnection, url != nil, state != .connected else { return }
    attempt = 0
    open()
  }

  deinit {
    pingTimer?.invalidate()
    task?.cancel(with: .goingAway, reason: nil)
  }

  func disconnect() {
    wantsConnection = false
    generation += 1
    task?.cancel(with: .goingAway, reason: nil)
    task = nil
    pingTimer?.invalidate()
    state = .off
    expertOnline = false
  }

  private func open() {
    guard let url else { return }
    wantsConnection = true
    generation += 1
    let gen = generation
    task?.cancel(with: .goingAway, reason: nil)

    let socket = session.webSocketTask(with: url)
    task = socket
    state = .connecting
    socket.resume()
    // Sent frames queue until the handshake completes, so hello can go straight away.
    send(.hello(Hello(role: .user, client: "\(UIDevice.current.name) (Remote Assist)")), on: socket)
    receive(on: socket, gen: gen)
    startPinging(socket, gen: gen)
  }

  private func receive(on socket: URLSessionWebSocketTask, gen: Int) {
    socket.receive { [weak self] result in
      DispatchQueue.main.async {
        guard let self, gen == self.generation else { return }
        switch result {
        case .success(let frame):
          self.markConnected()
          self.handle(frame)
          self.receive(on: socket, gen: gen)
        case .failure(let error):
          self.dropped(error)
        }
      }
    }
  }

  // A phone that silently loses Wi-Fi never gets a close frame; a failed ping is how we notice.
  private func startPinging(_ socket: URLSessionWebSocketTask, gen: Int) {
    pingTimer?.invalidate()
    pingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
      socket.sendPing { error in
        guard let error else { return }
        DispatchQueue.main.async {
          guard let self, gen == self.generation else { return }
          self.dropped(error)
        }
      }
    }
  }

  private func markConnected() {
    guard state != .connected else { return }
    state = .connected
    attempt = 0
    lastError = nil
    flush()
    flushChat()
  }

  private func dropped(_ error: Error) {
    generation += 1
    task?.cancel(with: .abnormalClosure, reason: nil)
    task = nil
    pingTimer?.invalidate()
    expertOnline = false
    flushing = false
    flushingChat = false
    lastError = error.localizedDescription
    state = .connecting

    let delay = min(pow(2, Double(attempt)), 10)
    attempt += 1
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self, self.state == .connecting, self.task == nil else { return }
      self.open()
    }
  }

  // MARK: Messages

  private func handle(_ frame: URLSessionWebSocketTask.Message) {
    let data: Data
    switch frame {
    case .string(let text): data = Data(text.utf8)
    case .data(let bytes): data = bytes
    @unknown default: return
    }

    guard let message = try? decoder.decode(Message.self, from: data) else {
      lastError = "Couldn't read a message from the relay"
      return
    }
    switch message {
    case .guideSet(let m): onGuide?(m.guide)
    case .stepSet(let m): onStepSet?(m)
    case .rtcSignal(let m): onSignal?(m.signal)
    case .stepVerified(let m): onStepVerified?(m)
    case .presence(let m): expertOnline = m.clients.contains { $0.role == .expert }
    case .chat(let m): receiveChat(m)
    case .error(let m) where m.about == "chat":
      chatUnsupported = true
    case .error(let m): lastError = "Relay refused \(m.about ?? "a message"): \(m.message)"
    default: break
    }
  }

  /// Queued, then sent in tap order; a step stays queued until the relay has taken it.
  func sendStepDone(guide: Guide, stepId: String) {
    let done = StepDone(
      guideId: guide.id,
      rev: guide.rev,
      stepId: stepId,
      doneId: UUID().uuidString.lowercased(),
      at: Int64(Date().timeIntervalSince1970 * 1000)
    )
    outbox.append(done)
    flush()
  }

  // MARK: Chat

  func sendChat(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let message = ChatMessage(id: UUID().uuidString.lowercased(), from: .user, text: String(trimmed.prefix(500)), at: Int64(Date().timeIntervalSince1970 * 1000))
    sentChatIds.insert(message.id)
    appendChat(message)
    chatOutbox.append(message)
    flushChat()
  }

  func isMine(_ message: ChatMessage) -> Bool {
    sentChatIds.contains(message.id)
  }

  private func clearChat() {
    chat = []
    chatOutbox = []
    sentChatIds = []
    unreadChat = 0
  }

  /// Arrival order, not the sender's clock (which anyone can set), and a bounded history.
  private func appendChat(_ message: ChatMessage) {
    chat.append(message)
    if chat.count > Self.chatLimit { chat.removeFirst(chat.count - Self.chatLimit) }
  }

  func markChatRead() {
    unreadChat = 0
  }

  private func receiveChat(_ message: ChatMessage) {
    // The relay replays recent chat on every connect, and may echo ours back: ids make that harmless.
    guard !chat.contains(where: { $0.id == message.id }) else { return }
    var message = message
    message.text = String(message.text.prefix(500))
    appendChat(message)
    guard !isMine(message) else { return }
    unreadChat += 1
    onChat?(message)
  }

  private func flushChat() {
    guard state == .connected, !flushingChat, let socket = task, let next = chatOutbox.first else { return }
    flushingChat = true
    let gen = generation
    send(.chat(next), on: socket) { [weak self] error in
      DispatchQueue.main.async {
        guard let self, gen == self.generation else { return }
        self.flushingChat = false
        if error == nil, self.chatOutbox.first?.id == next.id {
          self.chatOutbox.removeFirst()
          self.flushChat()
        }
      }
    }
  }

  /// Live only: a stale pose is useless, so poses are dropped rather than queued while offline.
  func sendPose(_ pose: PoseUpdate) {
    guard state == .connected, let task else { return }
    send(.pose(pose), on: task)
  }

  /// Signalling is only useful live; a stale offer or candidate can't be replayed later.
  func sendSignal(_ signal: RtcSignal) {
    guard state == .connected, let task else { return }
    send(.rtcSignal(RtcSignalMessage(signal: signal)), on: task)
  }

  private func flush() {
    guard state == .connected, !flushing, let socket = task, let next = outbox.first else { return }
    flushing = true
    let gen = generation
    send(.stepDone(next), on: socket) { [weak self] error in
      DispatchQueue.main.async {
        guard let self, gen == self.generation else { return }
        self.flushing = false
        if error == nil, self.outbox.first?.doneId == next.doneId {
          self.outbox.removeFirst()
          self.flush()
        }
      }
    }
  }

  private func send(_ message: Message, on socket: URLSessionWebSocketTask, completion: ((Error?) -> Void)? = nil) {
    guard let data = try? encoder.encode(message), let text = String(data: data, encoding: .utf8) else { return }
    socket.send(.string(text)) { error in completion?(error) }
  }
}
