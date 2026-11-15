// The dashboard's one connection to the relay. It says hello as an expert, and the relay answers with what it has
// saved (the guide, each scan's calibration, the user's ticks), so a reloaded dashboard restores itself from here.
import type { Message } from "../../../contracts/protocol.ts";

export type RelayStatus = "connecting" | "connected" | "closed";
type Sendable = Exclude<Message, { type: "hello" | "presence" | "error" | "labels.result" }>;
type Of<T extends Message["type"]> = Extract<Message, { type: T }>;
type Listener = (message: Message) => void;

export type RelayClient = {
  // False when the link is down: nothing is queued, because a guide or jump sent late could undo a newer one. The
  // caller re-sends its latest guide when the status returns to "connected".
  send(message: Sendable): boolean;
  on<T extends Message["type"]>(type: T, listener: (message: Of<T>) => void): () => void;
  onStatus(listener: (status: RelayStatus) => void): () => void;
  status(): RelayStatus;
  close(): void;
};

export type RelayClientOptions = {
  url: string;
  // Shown to the others in presence.
  client?: string;
  // The longest wait between reconnect attempts; they start at 500 ms and double.
  maxRetryMs?: number;
};

export function connectRelay({ url, client = "dashboard", maxRetryMs = 5000 }: RelayClientOptions): RelayClient {
  const listeners = new Map<string, Set<Listener>>();
  const statusListeners = new Set<(status: RelayStatus) => void>();
  let socket: WebSocket | null = null;
  let status: RelayStatus = "connecting";
  let attempt = 0;
  let retry: ReturnType<typeof setTimeout> | undefined;

  const setStatus = (next: RelayStatus) => {
    if (status === next) return;
    status = next;
    statusListeners.forEach((listener) => listener(next));
  };

  const open = () => {
    const current = new WebSocket(url);
    socket = current;
    current.addEventListener("open", () => {
      attempt = 0;
      current.send(JSON.stringify({ type: "hello", protocol: 1, role: "expert", client } satisfies Message));
      setStatus("connected");
    });
    current.addEventListener("message", (event) => {
      const message = JSON.parse(String(event.data)) as Message;
      listeners.get(message.type)?.forEach((listener) => listener(message));
    });
    current.addEventListener("close", () => {
      if (status === "closed" || socket !== current) return;
      setStatus("connecting");
      retry = setTimeout(open, Math.min(500 * 2 ** attempt++, maxRetryMs));
    });
  };
  open();

  return {
    send(message) {
      if (status !== "connected" || !socket) return false;
      socket.send(JSON.stringify(message));
      return true;
    },
    on(type, listener) {
      const set = listeners.get(type) ?? new Set();
      listeners.set(type, set);
      set.add(listener as Listener);
      return () => set.delete(listener as Listener);
    },
    onStatus(listener) {
      statusListeners.add(listener);
      return () => statusListeners.delete(listener);
    },
    status: () => status,
    close() {
      setStatus("closed");
      clearTimeout(retry);
      socket?.close();
    },
  };
}
