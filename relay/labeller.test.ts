import { test } from "node:test";
import assert from "node:assert/strict";
import type Anthropic from "@anthropic-ai/sdk";
import type { LabelsRequest } from "../contracts/protocol.ts";
import { claudeLabeller } from "./labeller.ts";

const request: LabelsRequest = {
  type: "labels.request",
  requestId: "r1",
  image: { mediaType: "image/jpeg", data: "aGVsbG8=" },
  width: 640,
  height: 360,
};

// Stands in for the API: records the request and answers with a canned response, so no test spends money.
function fakeClient(response: object) {
  const sent: any[] = [];
  const client = { beta: { messages: { create: async (params: unknown) => (sent.push(params), response) } } };
  return { client: client as unknown as Anthropic, sent };
}

const answer = (labels: object[], extra: object = {}) => ({
  model: "claude-opus-5-5",
  stop_reason: "end_turn",
  content: [{ type: "text", text: JSON.stringify({ labels }) }],
  ...extra,
});

test("asks Claude with the snapshot, a fixed answer shape and refusal fallback", async () => {
  const { client, sent } = fakeClient(answer([]));
  await claudeLabeller(client)(request);
  const [params] = sent;
  assert.equal(params.model, "claude-opus-5-5");
  assert.deepEqual(params.betas, ["server-side-fallback-2026-07-01"]);
  assert.equal(params.fallbacks, "default");
  assert.equal(params.output_config.format.type, "json_schema");
  assert.deepEqual(params.messages[0].content[0].source, { type: "base64", media_type: "image/jpeg", data: "aGVsbG8=" });
  assert.match(params.messages[0].content[1].text, /640 x 360/);
});

test("keeps labels inside the picture and drops blank or outside ones", async () => {
  const { client } = fakeClient(
    answer([
      { text: "SSD", x: 100, y: 200 },
      { text: "  ", x: 10, y: 10 },
      { text: "Port 99", x: 640, y: 10 },
      { text: "Screw", x: -1, y: 5 },
    ]),
  );
  assert.deepEqual(await claudeLabeller(client)(request), {
    model: "claude-opus-5-5",
    labels: [{ text: "SSD", x: 100, y: 200 }],
  });
});

test("reports which model answered, which differs when a fallback ran", async () => {
  const { client } = fakeClient(answer([], { model: "claude-opus-5" }));
  assert.equal((await claudeLabeller(client)(request)).model, "claude-opus-5");
});

test("a refusal or a cut-off answer is an error, not an empty label list", async () => {
  await assert.rejects(claudeLabeller(fakeClient(answer([], { stop_reason: "refusal" })).client)(request), /declined/);
  await assert.rejects(claudeLabeller(fakeClient(answer([], { stop_reason: "max_tokens" })).client)(request), /cut off/);
  await assert.rejects(claudeLabeller(fakeClient({ ...answer([]), content: [] }).client)(request), /no labels/);
});
