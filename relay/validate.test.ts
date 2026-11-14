import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { MESSAGE_TYPES, checkGuide, parseMessage } from "./validate.ts";

const fixture = (name: string) =>
  JSON.parse(readFileSync(new URL(`../fixtures/${name}`, import.meta.url), "utf8"));

const examples: { type: string }[] = fixture("messages.json");
const sampleGuide = fixture("sample-guide.json");

const refusal = (message: unknown) => {
  const result = parseMessage(JSON.stringify(message));
  assert.equal(result.ok, false, `expected a refusal for ${JSON.stringify(message)}`);
  return result.ok ? "" : result.error;
};

const guideMessage = (edit: (guide: any) => void) => {
  const guide = structuredClone(sampleGuide);
  edit(guide);
  return { type: "guide.set", guide };
};

test("every example message is accepted", () => {
  for (const example of examples) {
    const result = parseMessage(JSON.stringify(example));
    assert.ok(result.ok, `${example.type}: ${result.ok ? "" : result.error}`);
  }
});

test("the examples cover every message type exactly once", () => {
  assert.deepEqual(examples.map((m) => m.type).sort(), [...MESSAGE_TYPES].sort());
});

test("the sample guide is valid", () => {
  assert.equal(checkGuide(sampleGuide), null);
  assert.ok(parseMessage(JSON.stringify({ type: "guide.set", guide: sampleGuide })).ok);
});

test("text that isn't a JSON object is refused", () => {
  for (const text of ["not json", "[]", "null", "42"]) {
    const result = parseMessage(text);
    assert.equal(result.ok, false, text);
  }
});

test("an unknown or missing type is refused and named", () => {
  const result = parseMessage(JSON.stringify({ type: "guide.patch" }));
  assert.deepEqual(result, { ok: false, error: "unknown message type", about: "guide.patch" });
  assert.match(refusal({ guide: sampleGuide }), /type/);
});

test("a client on another protocol version is refused", () => {
  assert.match(refusal({ type: "hello", protocol: 2, role: "user", client: "old phone" }), /protocol/);
  assert.match(refusal({ type: "hello", protocol: 1, role: "admin", client: "x" }), /role/);
});

test("broken positions, rotations, sizes and axes are refused with their path", () => {
  assert.match(
    refusal(guideMessage((g) => (g.steps[1].objects[0].pos = [0.1, 0.2]))),
    /guide\.steps\[1\]\.objects\[0\]\.pos/,
  );
  assert.match(refusal(guideMessage((g) => (g.steps[0].objects[0].pos = [0, "1", 0]))), /pos/);
  assert.match(refusal(guideMessage((g) => (g.steps[0].objects[0].rot = [0, 0, 0, 2]))), /rot.*unit/);
  assert.match(refusal(guideMessage((g) => (g.steps[0].objects[0].axis = [0, 0, 0]))), /axis.*unit/);
  assert.match(refusal(guideMessage((g) => (g.steps[0].objects[0].size = [0.01, 0, 0.01]))), /size/);
});

test("unknown models and actions are refused", () => {
  assert.match(refusal(guideMessage((g) => (g.steps[0].objects[0].model = "spanner"))), /model/);
  assert.match(refusal(guideMessage((g) => (g.steps[0].objects[0].action = "twist"))), /action/);
  assert.ok(parseMessage(JSON.stringify(guideMessage((g) => (g.steps[0].objects[0].action = null)))).ok);
});

test("duplicate step or object ids are refused", () => {
  assert.match(refusal(guideMessage((g) => (g.steps[1].id = g.steps[0].id))), /duplicate step id/);
  assert.match(
    refusal(guideMessage((g) => (g.steps[1].objects[0].id = g.steps[0].objects[0].id))),
    /duplicate object id/,
  );
});

test("a marker without a real printed size is refused", () => {
  assert.match(refusal(guideMessage((g) => (g.marker.width = 0))), /marker\.width/);
  assert.match(refusal(guideMessage((g) => delete g.marker.height)), /marker\.height/);
});

test("step.done needs a whole-number rev and a doneId", () => {
  const done = examples.find((m) => m.type === "step.done")!;
  assert.match(refusal({ ...done, rev: 1.5 }), /rev/);
  assert.match(refusal({ ...done, doneId: "" }), /doneId/);
});

test("an ICE candidate must say which media line it's for, even if null", () => {
  const signal = { kind: "candidate", candidate: "candidate:1 1 udp 1 10.0.0.1 9 typ host", sdpMLineIndex: 0 };
  assert.match(refusal({ type: "rtc.signal", signal }), /sdpMid/);
  assert.ok(parseMessage(JSON.stringify({ type: "rtc.signal", signal: { ...signal, sdpMid: null } })).ok);
  assert.match(refusal({ type: "rtc.signal", signal: { kind: "offer" } }), /sdp/);
});

test("signals of an unknown kind or with a fractional line index are refused", () => {
  assert.match(refusal({ type: "rtc.signal", signal: { kind: "bye" } }), /signal\.kind/);
  assert.match(refusal({ type: "rtc.signal", signal: "offer" }), /signal: expected an object/);
  const candidate = { kind: "candidate", candidate: "", sdpMid: "0", sdpMLineIndex: 0.5 };
  assert.match(refusal({ type: "rtc.signal", signal: candidate }), /sdpMLineIndex/);
});

test("pose, verification, presence and error messages are checked field by field", () => {
  const pose = examples.find((m) => m.type === "pose") as any;
  assert.match(refusal({ ...pose, markerTracked: "yes" }), /markerTracked/);
  assert.match(refusal({ ...pose, camera: { ...pose.camera, q: [0, 0, 0, 0.5] } }), /camera\.q.*unit/);
  assert.match(refusal({ type: "step.verified", guideId: "g", stepId: "s1" }), /ok/);
  assert.match(refusal({ type: "presence", clients: [{ role: "boss", client: "x" }] }), /clients\[0\]\.role/);
  assert.match(refusal({ type: "presence", clients: "everyone" }), /clients: expected a list/);
  assert.match(refusal({ type: "error", about: "hello" }), /message/);
});

test("calibration needs exactly four corners", () => {
  const calib = examples.find((m) => m.type === "calib.set") as any;
  assert.match(refusal({ ...calib, corners: calib.corners.slice(0, 3) }), /corners/);
  assert.match(refusal({ ...calib, residual: -1 }), /residual/);
});
