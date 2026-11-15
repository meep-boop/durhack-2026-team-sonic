import assert from "node:assert/strict";
import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { setTimeout as sleep } from "node:timers/promises";
import type { Guide, Message } from "../../../contracts/protocol.ts";
import { runFakePhone } from "../../../fixtures/fake-phone.ts";
import { startRelay } from "../../../relay/relay.ts";
import { connectRelay } from "./client.ts";

const guide: Guide = JSON.parse(readFileSync(new URL("../../../fixtures/sample-guide.json", import.meta.url), "utf8"));
const quiet = () => {};

async function until(check: () => boolean, what: string) {
  const deadline = Date.now() + 3000;
  while (!check()) {
    if (Date.now() > deadline) assert.fail(`timed out waiting for ${what}`);
    await sleep(5);
  }
}

test("a guide sent from the dashboard is played by the phone, and its taps come back", async (t) => {
  const relay = await startRelay({ port: 0, host: "127.0.0.1", log: quiet });
  t.after(relay.close);
  const url = `ws://127.0.0.1:${relay.port}`;
  const dashboard = connectRelay({ url });
  t.after(dashboard.close);
  const done: string[] = [];
  dashboard.on("step.done", (message) => done.push(message.stepId));

  assert.equal(dashboard.send({ type: "guide.set", guide }), false, "nothing is sent before the link is up");
  await until(() => dashboard.status() === "connected", "the connection");
  assert.equal(dashboard.send({ type: "guide.set", guide }), true);

  await runFakePhone({ url, tapEveryMs: 10, poseEveryMs: 5, log: quiet });
  await until(() => done.length === guide.steps.length, "every tap");
  assert.deepEqual(done, guide.steps.map((step) => step.id));
});

test("it reconnects when the relay comes back, and is replayed what the relay saved", async (t) => {
  const first = await startRelay({ port: 0, host: "127.0.0.1", log: quiet });
  const { port } = first;
  const statePath = new URL(`./client-test-state-${port}.json`, import.meta.url);
  const dashboard = connectRelay({ url: `ws://127.0.0.1:${port}`, maxRetryMs: 50 });
  t.after(dashboard.close);
  const statuses: string[] = [];
  const received: Message[] = [];
  dashboard.onStatus((status) => statuses.push(status));
  dashboard.on("guide.set", (message) => received.push(message));
  dashboard.on("calib.set", (message) => received.push(message));
  await until(() => dashboard.status() === "connected", "the connection");
  await first.close();
  await until(() => dashboard.status() === "connecting", "the drop to be noticed");

  // A second dashboard filled the relay while this one was away.
  const calib = { type: "calib.set", splatId: "closed.spz", corners: [[0, 0, 0], [1, 0, 0], [1, 0, 1], [0, 0, 1]], residual: 0 };
  writeFileSync(statePath, JSON.stringify({ guide, stepId: "s1", calibs: { "closed.spz": calib }, done: [], verified: [] }));
  t.after(() => rmSync(statePath, { force: true }));
  const second = await startRelay({ port, host: "127.0.0.1", log: quiet, statePath: fileURLToPath(statePath) });
  t.after(second.close);

  await until(() => received.length === 2, "the replay");
  assert.deepEqual(received.map((message) => message.type), ["calib.set", "guide.set"]);
  assert.deepEqual(statuses, ["connected", "connecting", "connected"]);
});
