import SwiftUI

/// Text chat with the expert, for when talking isn't practical (a noisy room, or no call). Messages typed offline
/// wait and send when the link is back, like finished steps.
struct ChatSheet: View {
  let relay: RelayClient
  @State private var draft = ""
  @FocusState private var typing: Bool
  @Environment(\.dismiss) private var dismiss

  private let quickReplies = ["I'm stuck", "Done", "Can you show me?", "Which screw?", "Hang on"]

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if relay.chatUnsupported {
          banner("This relay doesn't carry chat yet. Talk on a call instead, or ask for the relay update.", "exclamationmark.bubble.fill", .orange)
        } else if relay.state != .connected {
          banner("Offline: messages send when you're back online.", "icloud.slash", .secondary)
        }

        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack(spacing: 8) {
              if relay.chat.isEmpty {
                ContentUnavailableView("No messages yet", systemImage: "bubble.left.and.bubble.right", description: Text("Ask the expert anything. They see your camera when you're on a call."))
                  .padding(.top, 40)
              }
              ForEach(relay.chat) { message in
                bubble(message).id(message.id)
              }
            }
            .padding()
          }
          .onAppear { proxy.scrollTo(relay.chat.last?.id, anchor: .bottom) }
          .onChange(of: relay.chat.count) {
            withAnimation { proxy.scrollTo(relay.chat.last?.id, anchor: .bottom) }
            relay.markChatRead()
          }
        }

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(quickReplies, id: \.self) { reply in
              Button(reply) { relay.sendChat(reply) }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }
          }
          .padding(.horizontal)
        }
        .padding(.vertical, 8)

        HStack(spacing: 10) {
          TextField("Message the expert", text: $draft, axis: .vertical)
            .lineLimit(1...4)
            .focused($typing)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onSubmit(send)
          Button(action: send) {
            Image(systemName: "arrow.up.circle.fill").font(.system(size: 34))
          }
          .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
          .accessibilityLabel("Send")
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
      }
      .navigationTitle("Chat with the expert")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
    .onAppear { relay.markChatRead() }
  }

  private func send() {
    relay.sendChat(draft)
    draft = ""
  }

  private func banner(_ text: String, _ symbol: String, _ color: Color) -> some View {
    Label(text, systemImage: symbol)
      .font(.footnote)
      .foregroundStyle(color)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)
      .padding(.vertical, 8)
      .background(color.opacity(0.12))
  }

  private func bubble(_ message: ChatMessage) -> some View {
    let mine = relay.isMine(message)
    let pending = relay.pendingChatIds.contains(message.id)
    return HStack {
      if mine { Spacer(minLength: 48) }
      VStack(alignment: mine ? .trailing : .leading, spacing: 3) {
        Text(message.text)
          .padding(.horizontal, 14)
          .padding(.vertical, 9)
          .background(mine ? Color.accentColor : Color.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
          .overlay(alignment: .topLeading) {
            // Another phone on the relay (or anyone claiming to be one) is labelled, never shown as "you".
            if !mine, message.from != .expert {
              Text(message.from == .user ? "Another phone" : "Rig").font(.caption2).offset(y: -14)
            }
          }
          .foregroundStyle(mine ? .black : .primary)
        Text(pending ? "Waiting to send" : Date(timeIntervalSince1970: Double(message.at) / 1000).formatted(date: .omitted, time: .shortened))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      if !mine { Spacer(minLength: 48) }
    }
  }
}

/// The chat button next to the status capsule, with an unread count.
struct ChatButton: View {
  let unread: Int
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "bubble.left.and.text.bubble.right.fill").font(.headline).frame(width: 44, height: 44)
    }
    .glassBackground(in: Circle())
    .overlay(alignment: .topTrailing) {
      if unread > 0 {
        Text("\(min(unread, 9))")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.white)
          .frame(width: 18, height: 18)
          .background(.red, in: Circle())
          .offset(x: 2, y: -2)
      }
    }
    .accessibilityLabel(unread > 0 ? "Chat, \(unread) unread" : "Chat with the expert")
  }
}
