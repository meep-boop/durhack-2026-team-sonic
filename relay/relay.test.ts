import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { setTimeout as sleep } from "node:timers/promises";
import { WebSocket as WsClient } from "ws";
import type { Guide, Message, Role } from "../contracts/protocol.ts";
import { startFakeExpert } from "../fixtures/fake-expert.ts";
import { runFakePhone } from "../fixtures/fake-phone.ts";
import type { Labeller } from "./labeller.ts";
import { startRelay, type RelayOptions } from "./relay.ts";

const sampleGuide: Guide = JSON.parse(readFileSync(new URL("../fixtures/sample-guide.json", import.meta.url), "utf8"));
const quiet = () => {};

async function relay(t: { after: (fn: () => Promise<void>) => void }, options: Partial<RelayOptions> = {}) {
  const started = await startRelay({ port: 0, host: "127.0.0.1", log: quiet, ...options });
  t.after(started.close);
  return started;
}

type Client = { received: Message[]; send: (message: unknown) => void; sendRaw: (text: string) => void; close: () => void };

async function connect(port: number, role?: Role, name: string = role ?? "anonymous"): Promise<Client> {
  const socket = new WebSocket(`ws://127.0.0.1:${port}`);
  const received: Message[] = [];
  socket.addEventListener("message", (event) => received.push(JSON.parse(String(event.data))));
  await new Promise((resolve, reject) => {
    socket.addEventListener("open", resolve);
    socket.addEventListener("error", reject);
  });
  const client: Client = {
    received,
    send: (message) => socket.send(JSON.stringify(message)),
    sendRaw: (text) => socket.send(text),
    close: () => socket.close(),
  };
  if (role) client.send({ type: "hello", protocol: 1, role, client: name });
  return client;
}

async function until(check: () => boolean, what: string) {
  const deadline = Date.now() + 2000;
  while (!check()) {
    if (Date.now() > deadline) assert.fail(`timed out waiting for ${what}`);
    await sleep(5);
  }
}

const ofType = <T extends Message["type"]>(client: Client, type: T) =>
  client.received.filter((message): message is Extract<Message, { type: T }> => message.type === type);

const done = (stepId: string, doneId = `done-${stepId}`, guide = sampleGuide) => ({
  type: "step.done",
  guideId: guide.id,
  rev: guide.rev,
  stepId,
  doneId,
  at: Date.now(),
});
const pose = { type: "pose", t: 1, camera: { p: [0, 0.4, 0.4], q: [0, 0, 0, 1] }, markerTracked: true };

// Messages from one socket are handled in order, so once a later message has arrived somewhere, every earlier one
// from that socket has been handled too. That proves "nothing was forwarded" without sleeping.
async function sendGuide(expert: Client, watcher: Client, guide: Guide = sampleGuide) {
  const before = ofType(watcher, "guide.set").length;
  expert.send({ type: "guide.set", guide });
  await until(() => ofType(watcher, "guide.set").length > before, "the guide to arrive");
}

test("a client that joins later gets the guide; dashboards and the rig also get the current step", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  await sendGuide(expert, await connect(port, "expert", "second dashboard"));

  const rig = await connect(port, "rig");
  await until(() => ofType(rig, "step.set").length === 1, "the replayed step");
  assert.deepEqual(rig.received.slice(0, 2).map((message) => message.type), ["guide.set", "step.set"]);
  assert.equal(ofType(rig, "step.set")[0]!.stepId, "s1");

  const user = await connect(port, "user");
  await until(() => ofType(user, "presence").length > 0, "the phone's replay");
  assert.equal(ofType(user, "guide.set").length, 1);
  assert.equal(ofType(user, "step.set").length, 0, "the phone owns its position, so it isn't told one");
});

test("Next on the phone reaches the dashboard and the rig, and moves the current step on", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const rig = await connect(port, "rig");
  const user = await connect(port, "user");
  await sendGuide(expert, user);

  user.send(done("s1"));
  await until(() => ofType(expert, "step.done").length === 1 && ofType(rig, "step.done").length === 1, "step.done");
  await until(() => ofType(user, "step.done").length === 1, "the phone's receipt");
  assert.equal(ofType(user, "step.done")[0]!.doneId, "done-s1");

  const reloaded = await connect(port, "expert", "reloaded dashboard");
  await until(() => ofType(reloaded, "step.set").length === 1, "the replayed step");
  assert.equal(ofType(reloaded, "step.set")[0]!.stepId, "s2");
});

test("a repeated step.done from an offline queue is forwarded once, and receipted every time", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const user = await connect(port, "user");
  await sendGuide(expert, user);

  user.send(done("s1", "same-tap"));
  user.send(done("s1", "same-tap"));
  user.send(pose);
  await until(() => ofType(expert, "pose").length === 1, "the pose sent after the repeat");
  assert.equal(ofType(expert, "step.done").length, 1);
  assert.equal(ofType(user, "error").length, 0);
  await until(() => ofType(user, "step.done").length === 2, "a receipt for the tap and for its repeat");
});

test("each role can only send its own messages, and only after hello", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const user = await connect(port, "user");
  const stranger = await connect(port);

  stranger.send({ type: "guide.set", guide: sampleGuide });
  await until(() => ofType(stranger, "error").length === 1, "the refusal");
  assert.match(ofType(stranger, "error")[0]!.message, /hello first/);

  user.send({ type: "guide.set", guide: sampleGuide });
  user.send({ type: "presence", clients: [] });
  user.sendRaw("not json");
  user.send(pose);
  await until(() => ofType(expert, "pose").length === 1, "the pose sent after the refused messages");
  assert.equal(ofType(expert, "guide.set").length, 0);
  assert.deepEqual(
    ofType(user, "error").map(({ message }) => message),
    ["a user can't send guide.set", "only the relay sends presence", "not valid JSON"],
  );

  user.send({ type: "hello", protocol: 1, role: "expert", client: "promoted" });
  await until(() => ofType(user, "error").length === 4, "the second hello's refusal");
  assert.match(ofType(user, "error")[3]!.message, /already said hello/);
});

test("calibration stays between dashboards, and each scan's latest comes back after a reload", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const otherExpert = await connect(port, "expert", "second dashboard");
  const user = await connect(port, "user");
  const calib = {
    type: "calib.set",
    splatId: "desk",
    corners: [[0, 1, 0], [1, 1, 0], [1, 0, 0], [0, 0, 0]],
    residual: 0.002,
  };

  expert.send(calib);
  await sendGuide(expert, user);
  assert.equal(ofType(user, "calib.set").length, 0);
  await until(() => ofType(otherExpert, "calib.set").length === 1, "calibration on the second dashboard");

  const redone = { ...calib, residual: 0.001 };
  const openScan = { ...calib, splatId: "desk-open" };
  expert.send(redone);
  expert.send(openScan);
  await until(() => ofType(otherExpert, "calib.set").length === 3, "both later calibrations");

  const reloaded = await connect(port, "expert", "reloaded dashboard");
  await until(() => ofType(reloaded, "presence").length > 0, "the reloaded dashboard's presence");
  assert.deepEqual(ofType(reloaded, "calib.set"), [redone, openScan]);
});

test("an expert's jump reaches the phone, the rig and other dashboards, and is replayed", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const otherExpert = await connect(port, "expert", "second dashboard");
  const rig = await connect(port, "rig");
  const user = await connect(port, "user");
  await sendGuide(expert, user);

  expert.send({ type: "step.set", guideId: sampleGuide.id, stepId: "s3" });
  const jumpedTo = (client: Client) => ofType(client, "step.set").at(-1)?.stepId === "s3";
  await until(() => [user, rig, otherExpert].every(jumpedTo), "the jump everywhere");

  const rejoined = await connect(port, "rig", "rejoined rig");
  await until(() => ofType(rejoined, "step.set").length === 1, "the replayed step");
  assert.equal(ofType(rejoined, "step.set")[0]!.stepId, "s3");
});

test("the rig's verdict reaches both sides, and only the latest per step is replayed", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const rig = await connect(port, "rig");
  const user = await connect(port, "user");
  await sendGuide(expert, user);
  const verdict = (ok: boolean, guideId = sampleGuide.id) => ({ type: "step.verified", guideId, stepId: "s1", ok });

  rig.send(verdict(false));
  rig.send(verdict(true));
  await until(() => ofType(expert, "step.verified").length === 2 && ofType(user, "step.verified").length === 2, "both verdicts");

  const reloaded = await connect(port, "expert", "reloaded dashboard");
  await until(() => ofType(reloaded, "presence").length > 0, "the replay");
  assert.deepEqual(ofType(reloaded, "step.verified").map(({ ok }) => ok), [true]);

  rig.send(verdict(true, "another-guide"));
  await until(() => ofType(rig, "error").length === 1, "the refusal");
  assert.match(ofType(rig, "error")[0]!.message, /no guide "another-guide"/);
});

test("jumps and progress must name a step and guide the relay has", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const user = await connect(port, "user");
  await sendGuide(expert, user);

  expert.send({ type: "step.set", guideId: sampleGuide.id, stepId: "s9" });
  user.send(done("s1", "d1", { ...sampleGuide, id: "another-guide" }));
  await until(() => ofType(expert, "error").length === 1 && ofType(user, "error").length === 1, "both refusals");
  assert.match(ofType(expert, "error")[0]!.message, /no step "s9"/);
  assert.match(ofType(user, "error")[0]!.message, /no guide "another-guide"/);
});

test("video signalling goes to the other side and is never replayed", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const user = await connect(port, "user");

  user.send({ type: "rtc.signal", signal: { kind: "offer", sdp: "v=0 offer" } });
  await until(() => ofType(expert, "rtc.signal").length === 1, "the offer");
  expert.send({ type: "rtc.signal", signal: { kind: "answer", sdp: "v=0 answer" } });
  await until(() => ofType(user, "rtc.signal").length === 1, "the answer");

  const latecomer = await connect(port, "expert", "latecomer");
  await until(() => ofType(latecomer, "presence").length > 0, "the latecomer's presence");
  assert.equal(ofType(latecomer, "rtc.signal").length, 0);
});

test("camera poses go to dashboards only", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const rig = await connect(port, "rig");
  const user = await connect(port, "user");
  await sendGuide(expert, user);

  user.send(pose);
  user.send(done("s1"));
  await until(() => ofType(rig, "step.done").length === 1, "step.done at the rig");
  assert.equal(ofType(rig, "pose").length, 0);
  assert.equal(ofType(expert, "pose").length, 1);
});

test("presence shows who's connected and updates when someone leaves", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert", "dashboard");
  const user = await connect(port, "user", "phone");
  const names = () => ofType(expert, "presence").at(-1)?.clients.map(({ client }) => client).sort();

  await until(() => names()?.length === 2, "both clients in presence");
  assert.deepEqual(names(), ["dashboard", "phone"]);
  user.close();
  await until(() => names()?.length === 1, "the phone to leave presence");
});

test("a phone that stops answering pings is dropped from presence", async (t) => {
  const { port } = await relay(t, { heartbeatMs: 50 });
  const expert = await connect(port, "expert", "dashboard");
  const silent = new WsClient(`ws://127.0.0.1:${port}`, { autoPong: false });
  t.after(() => void silent.terminate());
  silent.on("open", () => silent.send(JSON.stringify({ type: "hello", protocol: 1, role: "user", client: "silent phone" })));
  const count = () => ofType(expert, "presence").at(-1)?.clients.length;

  await until(() => count() === 2, "the silent phone to join");
  await until(() => count() === 1, "the silent phone to be dropped");
});

test("the guide and progress survive a restart, and --fresh discards them", async (t) => {
  const statePath = join(mkdtempSync(join(tmpdir(), "relay-")), "state.json");

  const first = await startRelay({ port: 0, host: "127.0.0.1", log: quiet, statePath });
  const expert = await connect(first.port, "expert");
  const user = await connect(first.port, "user");
  await sendGuide(expert, user);
  user.send(done("s1"));
  await until(() => ofType(expert, "step.done").length === 1, "step.done");
  await first.close();

  const second = await startRelay({ port: 0, host: "127.0.0.1", log: quiet, statePath });
  const reloaded = await connect(second.port, "expert");
  await until(() => ofType(reloaded, "presence").length > 0, "the replay");
  assert.equal(ofType(reloaded, "guide.set")[0]?.guide.id, sampleGuide.id);
  assert.equal(ofType(reloaded, "step.set")[0]?.stepId, "s2");
  assert.equal(ofType(reloaded, "step.done").length, 1);
  await second.close();

  const fresh = await relay(t, { statePath, fresh: true });
  const blank = await connect(fresh.port, "expert");
  await until(() => ofType(blank, "presence").length > 0, "the replay");
  assert.equal(ofType(blank, "guide.set").length, 0);
});

test("an unreadable state file stops the relay and says how to recover", async () => {
  const statePath = join(mkdtempSync(join(tmpdir(), "relay-")), "state.json");
  writeFileSync(statePath, "{ half a file");
  await assert.rejects(startRelay({ port: 0, host: "127.0.0.1", log: quiet, statePath }), /--fresh/);
});

test("a new guide clears progress, an edit of the same guide keeps it", async (t) => {
  const { port } = await relay(t);
  const expert = await connect(port, "expert");
  const user = await connect(port, "user");
  await sendGuide(expert, user);
  user.send(done("s1"));
  await until(() => ofType(expert, "step.done").length === 1, "step.done");

  await sendGuide(expert, user, { ...sampleGuide, rev: 2, title: "SAMPLE, edited" });
  const afterEdit = await connect(port, "expert", "after edit");
  await until(() => ofType(afterEdit, "presence").length > 0, "the replay");
  assert.equal(ofType(afterEdit, "step.done").length, 1);
  assert.equal(ofType(afterEdit, "step.set")[0]?.stepId, "s2");

  await sendGuide(expert, user, { ...sampleGuide, id: "another-guide" });
  const afterSwap = await connect(port, "expert", "after swap");
  await until(() => ofType(afterSwap, "presence").length > 0, "the replay");
  assert.equal(ofType(afterSwap, "step.done").length, 0);
  assert.equal(ofType(afterSwap, "step.set")[0]?.stepId, "s1");
});

test("the fake expert can jump straight to a step, for testing the rig on a checked step", async (t) => {
  const { port } = await relay(t);
  const expert = await startFakeExpert({ url: `ws://127.0.0.1:${port}`, guide: sampleGuide, stepId: "s4", log: quiet });
  t.after(async () => expert.close());

  const rig = await connect(port, "rig");
  await until(() => ofType(rig, "step.set").length === 1, "the replayed step");
  assert.equal(ofType(rig, "step.set")[0]!.stepId, "s4");
});

const snapshot = {
  type: "labels.request",
  requestId: "snap-1",
  image: { mediaType: "image/jpeg", data: "aGVsbG8=" },
  width: 640,
  height: 360,
};

test("a dashboard's snapshot is labelled and answered to that dashboard only", async (t) => {
  const asked: unknown[] = [];
  const labeller: Labeller = async (request) => {
    asked.push(request);
    return { model: "fake-model", labels: [{ text: "SSD", x: 100, y: 200 }] };
  };
  const { port } = await relay(t, { labeller });
  const expert = await connect(port, "expert");
  const otherExpert = await connect(port, "expert", "second dashboard");
  const user = await connect(port, "user");

  expert.send(snapshot);
  await until(() => ofType(expert, "labels.result").length === 1, "the labels");
  assert.deepEqual(ofType(expert, "labels.result")[0], {
    type: "labels.result",
    requestId: "snap-1",
    model: "fake-model",
    labels: [{ text: "SSD", x: 100, y: 200 }],
  });
  assert.equal(asked.length, 1);

  user.send(pose);
  await until(() => ofType(expert, "pose").length === 1 && ofType(otherExpert, "pose").length === 1, "a later message");
  assert.equal(ofType(otherExpert, "labels.result").length, 0);
  assert.equal(ofType(user, "labels.result").length, 0);
});

test("labelling refuses phones, overlapping snapshots, failures and a relay without it", async (t) => {
  let finish: () => void = () => {};
  const slow: Labeller = () =>
    new Promise((resolve) => (finish = () => resolve({ model: "fake-model", labels: [] })));
  const { port } = await relay(t, { labeller: slow });
  const expert = await connect(port, "expert");
  const user = await connect(port, "user");

  user.send(snapshot);
  user.send({ type: "labels.result", requestId: "x", model: "made-up", labels: [] });
  await until(() => ofType(user, "error").length === 2, "both refusals");
  assert.deepEqual(
    ofType(user, "error").map(({ message }) => message),
    ["a user can't send labels.request", "only the relay sends labels.result"],
  );

  expert.send(snapshot);
  expert.send({ ...snapshot, requestId: "snap-2" });
  await until(() => ofType(expert, "error").length === 1, "the second snapshot's refusal");
  assert.match(ofType(expert, "error")[0]!.message, /still labelling/);
  finish();
  await until(() => ofType(expert, "labels.result").length === 1, "the first snapshot's labels");

  const failing = await relay(t, { labeller: async () => { throw new Error("credit exhausted"); } });
  const failingExpert = await connect(failing.port, "expert");
  failingExpert.send(snapshot);
  await until(() => ofType(failingExpert, "error").length === 1, "the failure");
  assert.match(ofType(failingExpert, "error")[0]!.message, /labelling failed: credit exhausted/);

  const off = await relay(t);
  const offExpert = await connect(off.port, "expert");
  offExpert.send(snapshot);
  await until(() => ofType(offExpert, "error").length === 1, "the refusal");
  assert.match(ofType(offExpert, "error")[0]!.message, /labelling is off/);
});

test("a phone that taps Next with the link down catches up when it returns", async (t) => {
  const { port } = await relay(t);
  const url = `ws://127.0.0.1:${port}`;
  const expert = await startFakeExpert({ url, guide: sampleGuide, log: quiet });
  t.after(async () => expert.close());
  const phoneCount = () =>
    expert.received.flatMap((message) => (message.type === "presence" ? [message.clients.filter((c) => c.role === "user").length] : []));

  await runFakePhone({ url, tapEveryMs: 20, poseEveryMs: 10, offline: { afterSteps: 1, forMs: 150 }, log: quiet });
  const stepIds = () => expert.received.flatMap((message) => (message.type === "step.done" ? [message.stepId] : []));
  await until(() => stepIds().length === sampleGuide.steps.length, "every step.done, including the queued ones");

  assert.deepEqual(stepIds(), sampleGuide.steps.map((step) => step.id));
  assert.ok(phoneCount().join(",").includes("1,0,1"), `the dashboard never saw the phone drop and return: ${phoneCount()}`);
  const reloaded = await connect(port, "expert", "reloaded dashboard");
  await until(() => ofType(reloaded, "presence").length > 0, "the replay");
  assert.equal(ofType(reloaded, "step.set")[0]?.stepId, "s4", "the relay's step should end on the last step");
});

test("the fake phone and fake expert complete the sample guide through the relay", async (t) => {
  const { port } = await relay(t);
  const url = `ws://127.0.0.1:${port}`;
  const expert = await startFakeExpert({ url, guide: sampleGuide, log: quiet });
  t.after(async () => expert.close());

  await runFakePhone({ url, tapEveryMs: 20, poseEveryMs: 10, log: quiet });
  const finished = () => expert.received.filter((message) => message.type === "step.done").length;
  await until(() => finished() === sampleGuide.steps.length, "every step.done at the expert");

  const stepIds = expert.received.flatMap((message) => (message.type === "step.done" ? [message.stepId] : []));
  assert.deepEqual(stepIds, sampleGuide.steps.map((step) => step.id));
  assert.ok(expert.received.some((message) => message.type === "pose"), "no pose reached the expert");
});
