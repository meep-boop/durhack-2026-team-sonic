import assert from "node:assert/strict";
import { test } from "node:test";
import type { Message, Presence, StepDone } from "../../../contracts/protocol.ts";
import { addStep, createGuide, guideSetMessage } from "../guide/guide.ts";
import { stepStatus } from "../guide/progress.ts";
import type { RelayClient, RelayStatus } from "../relay/client.ts";
import { CATCH_UP_MS, createLiveStore, initialLive, type Live, type LiveEvent, reduceLive } from "./live.ts";

let guide = createGuide("SAMPLE: replace the SSD");
for (const text of ["Undo the cover screws", "Lift the cover", "Pull out the SSD"]) guide = addStep(guide, text);
const [first, second] = guide.steps.map((s) => s.id) as [string, string, string];

const presence = (...roles: ("user" | "rig")[]): Presence => ({
  type: "presence",
  clients: [{ role: "expert", client: "dashboard" }, ...roles.map((role) => ({ role, client: `${role} 1` }))],
});
const done = (stepId: string, at: number): StepDone => ({
  type: "step.done",
  guideId: guide.id,
  rev: guide.rev,
  stepId,
  doneId: crypto.randomUUID(),
  at,
});
const message = (m: Message): LiveEvent => ({ kind: "message", message: m });

function play(events: [number, LiveEvent][], start: Live = initialLive("connected", 0)): Live {
  return events.reduce((live, [now, event]) => reduceLive(live, event, now), start);
}

test("presence tells the phone and the rig apart, and when each changed", () => {
  const live = play([
    [0, message(presence("user"))],
    [5000, message(presence("user", "rig"))],
  ]);
  assert.deepEqual(live.phone, { state: "online", name: "user 1", since: 0, seen: true });
  assert.equal(live.rig.state, "online");
  assert.equal(live.rig.since, 5000);
});

test("a phone that drops off is offline from that moment, and keeps its name", () => {
  const live = play([
    [0, message(presence("user"))],
    [42_000, message(presence())],
  ]);
  assert.deepEqual(live.phone, { state: "offline", name: "user 1", since: 42_000, seen: true });
});

test("losing the relay makes the phone unknown, not offline", () => {
  const live = play([
    [0, message(presence("user"))],
    [1000, { kind: "status", status: "connecting" }],
  ]);
  assert.equal(live.phone.state, "unknown");
  assert.equal(live.relay, "connecting");
});

test("a guide sent or replayed starts its progress; the same guide id keeps its ticks", () => {
  let live = play([[0, { kind: "sent", guide }], [1, message(done(first, 1))]]);
  assert.equal(stepStatus(live.progress!, first), "done");
  live = reduceLive(live, message(guideSetMessage({ ...guide, rev: guide.rev + 1 })), 2);
  assert.equal(stepStatus(live.progress!, first), "done");
  live = reduceLive(live, message(guideSetMessage(createGuide("another"))), 3);
  assert.deepEqual(live.progress!.doneAt, {});
});

test("taps made offline are counted when the phone comes back; a fresh tap after it isn't", () => {
  const live = play([
    [0, { kind: "sent", guide }],
    [0, message(presence("user"))],
    [10_000, message(presence())],
    [20_000, message(presence("user"))],
    [20_500, message(done(first, 12_000))],
    [20_600, message(done(second, 15_000))],
    [26_000, message(done(guide.steps[2]!.id, 26_000))],
  ]);
  assert.equal(live.catchUp?.count, 2);
  assert.equal(live.catchUp?.until, 20_000 + CATCH_UP_MS);
});

test("a phone joining for the first time, or after the relay came back, isn't a catch-up", () => {
  const firstJoin = play([[0, message(presence())], [1000, message(presence("user"))]]);
  assert.equal(firstJoin.catchUp, null);
  const relayBack = play([
    [0, message(presence("user"))],
    [1000, { kind: "status", status: "connecting" }],
    [2000, { kind: "status", status: "connected" }],
    [2000, message(presence("user"))],
  ]);
  assert.equal(relayBack.catchUp, null);
});

test("the rig's latest check is kept with its step", () => {
  const live = play([
    [0, { kind: "sent", guide }],
    [1, message({ type: "step.verified", guideId: guide.id, stepId: second, ok: false, detail: "seen in ssd-bay" })],
  ]);
  assert.deepEqual(live.lastCheck, { stepId: second, ok: false, detail: "seen in ssd-bay" });
});

test("the store learns the sent guide from send, and only when the relay took it", () => {
  const listeners = new Map<string, (m: Message) => void>();
  let status: RelayStatus = "connected";
  const relay: RelayClient = {
    send: () => status === "connected",
    on: (type, listener) => {
      listeners.set(type, listener as (m: Message) => void);
      return () => listeners.delete(type);
    },
    onStatus: () => () => {},
    status: () => status,
    close: () => {},
  };
  const store = createLiveStore(relay, () => 0);
  let changes = 0;
  store.subscribe(() => changes++);

  status = "closed";
  store.relay.send(guideSetMessage(guide));
  assert.equal(store.get().guide, null);

  status = "connected";
  store.relay.send(guideSetMessage(guide));
  assert.equal(store.get().guide?.id, guide.id);
  listeners.get("step.done")!(done(first, 0));
  assert.equal(stepStatus(store.get().progress!, first), "done");
  assert.equal(changes, 2);
});
