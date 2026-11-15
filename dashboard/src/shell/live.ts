// What the expert needs to see of the session at a glance: who is connected, which guide the phone has, and how far
// the person has got. Built only from relay messages plus the guides this dashboard sends, so it works the same after
// a reload (the relay replays the guide and the ticks on connect).
import { useSyncExternalStore } from "react";
import type { Guide, Message } from "../../../contracts/protocol.ts";
import { applyMessage, emptyProgress, type Progress, type StepCheck } from "../guide/progress.ts";
import type { RelayClient, RelayStatus } from "../relay/client.ts";

// After the phone reconnects, its queued taps arrive within a second or two; the "caught up" note stays this long.
export const CATCH_UP_MS = 8000;
// Phone and laptop clocks on one hotspot agree to about a second, so a tap made just before the reconnect still
// counts as made offline.
const CLOCK_SLACK_MS = 2000;

type PeerState = "unknown" | "online" | "offline";
// `since` is this laptop's clock. `seen` is whether it has connected since the page opened, which separates
// "dropped off" from "never joined".
export type Peer = { state: PeerState; name: string | null; since: number; seen: boolean };

export type Live = {
  relay: RelayStatus;
  phone: Peer;
  rig: Peer;
  guide: Guide | null;
  progress: Progress | null;
  lastCheck: (StepCheck & { stepId: string }) | null;
  // Taps the phone made while offline, counted as they arrive after it comes back.
  catchUp: { count: number; from: number; until: number } | null;
};

export type LiveEvent =
  | { kind: "status"; status: RelayStatus }
  | { kind: "message"; message: Message }
  | { kind: "sent"; guide: Guide };

export function initialLive(relay: RelayStatus, now: number): Live {
  const unknown: Peer = { state: "unknown", name: null, since: now, seen: false };
  return { relay, phone: unknown, rig: unknown, guide: null, progress: null, lastCheck: null, catchUp: null };
}

export function reduceLive(live: Live, event: LiveEvent, now: number): Live {
  switch (event.kind) {
    case "status":
      if (event.status === "connected") return { ...live, relay: event.status };
      // Without the relay there's no news of the phone or the rig, which isn't the same as them being offline.
      return { ...live, relay: event.status, phone: forget(live.phone, now), rig: forget(live.rig, now), catchUp: null };
    case "sent":
      return adopt(live, event.guide);
    case "message":
      return onMessage(live, event.message, now);
  }
}

function onMessage(live: Live, message: Message, now: number): Live {
  switch (message.type) {
    case "presence": {
      const phone = see(live.phone, message.clients.find((c) => c.role === "user")?.client, now);
      const rig = see(live.rig, message.clients.find((c) => c.role === "rig")?.client, now);
      const back = live.phone.state === "offline" && live.phone.seen && phone.state === "online";
      return { ...live, phone, rig, catchUp: back ? { count: 0, from: now, until: now + CATCH_UP_MS } : live.catchUp };
    }
    case "guide.set":
      return adopt(live, message.guide);
    case "step.done":
    case "step.verified": {
      if (!live.guide || !live.progress) return live;
      const progress = applyMessage(live.progress, live.guide, message);
      if (progress === live.progress) return live;
      if (message.type === "step.verified") {
        return { ...live, progress, lastCheck: { stepId: message.stepId, ...progress.checks[message.stepId]! } };
      }
      const { catchUp } = live;
      const madeOffline = catchUp && now <= catchUp.until && message.at <= catchUp.from + CLOCK_SLACK_MS;
      return { ...live, progress, catchUp: madeOffline ? { ...catchUp, count: catchUp.count + 1 } : catchUp };
    }
    default:
      return live;
  }
}

// The same guide id keeps its ticks through edits, as in the guide panel; a new guide starts clean.
function adopt(live: Live, guide: Guide): Live {
  const same = live.progress?.guideId === guide.id;
  return { ...live, guide, progress: same ? live.progress : emptyProgress(guide), lastCheck: same ? live.lastCheck : null };
}

function see(peer: Peer, client: string | undefined, now: number): Peer {
  const state = client === undefined ? "offline" : "online";
  if (state === peer.state && (client ?? peer.name) === peer.name) return peer;
  return { state, name: client ?? peer.name, since: state === peer.state ? peer.since : now, seen: peer.seen || state === "online" };
}

function forget(peer: Peer, now: number): Peer {
  return peer.state === "unknown" ? peer : { ...peer, state: "unknown", since: now };
}

export type LiveStore = {
  // Hand this to everything that sends, so the store sees each guide that actually went out.
  relay: RelayClient;
  subscribe(listener: () => void): () => void;
  get(): Live;
  dispose(): void;
};

// The relay never echoes a client's own messages, so the store wraps `send` to learn which guide the phone now has.
export function createLiveStore(relay: RelayClient, clock: () => number = Date.now): LiveStore {
  let live = initialLive(relay.status(), clock());
  const listeners = new Set<() => void>();
  const dispatch = (event: LiveEvent) => {
    const next = reduceLive(live, event, clock());
    if (next === live) return;
    live = next;
    listeners.forEach((listener) => listener());
  };
  const onMessage = (message: Message) => dispatch({ kind: "message", message });
  const offs = [
    relay.onStatus((status) => dispatch({ kind: "status", status })),
    relay.on("presence", onMessage),
    relay.on("guide.set", onMessage),
    relay.on("step.done", onMessage),
    relay.on("step.verified", onMessage),
  ];
  return {
    relay: {
      ...relay,
      send(message) {
        const sent = relay.send(message);
        if (sent && message.type === "guide.set") dispatch({ kind: "sent", guide: message.guide });
        return sent;
      },
    },
    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    get: () => live,
    dispose: () => offs.forEach((off) => off()),
  };
}

const noStore = () => () => {};
const noLive = () => null;

export function useLive(store: LiveStore | null): Live | null {
  return useSyncExternalStore(store?.subscribe ?? noStore, store?.get ?? noLive);
}
