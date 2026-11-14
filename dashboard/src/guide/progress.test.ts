import assert from "node:assert/strict";
import { test } from "node:test";
import type { StepDone, StepVerified } from "../../../contracts/protocol.ts";
import { addStep, createGuide, moveStep } from "./guide.ts";
import { applyMessage, currentStepId, emptyProgress, stepStatus } from "./progress.ts";

let guide = createGuide("SAMPLE: replace the SSD");
for (const text of ["Undo the cover screws", "Lift the cover", "Pull out the SSD"]) guide = addStep(guide, text);
const [first, second, third] = guide.steps.map((s) => s.id) as [string, string, string];

const done = (stepId: string, at = 1000, guideId = guide.id): StepDone => ({
  type: "step.done",
  guideId,
  rev: guide.rev,
  stepId,
  doneId: crypto.randomUUID(),
  at,
});

const verified = (stepId: string, ok: boolean, detail?: string): StepVerified =>
  detail === undefined
    ? { type: "step.verified", guideId: guide.id, stepId, ok }
    : { type: "step.verified", guideId: guide.id, stepId, ok, detail };

test("a step.done ticks its step and moves the current step on", () => {
  const progress = applyMessage(emptyProgress(guide), guide, done(first, 1234));
  assert.equal(stepStatus(progress, first), "done");
  assert.equal(stepStatus(progress, second), "todo");
  assert.equal(progress.doneAt[first], 1234);
  assert.equal(currentStepId(guide, progress), second);
});

test("the first tap's time is kept if a repeat slips through", () => {
  let progress = applyMessage(emptyProgress(guide), guide, done(first, 1000));
  progress = applyMessage(progress, guide, done(first, 5000));
  assert.equal(progress.doneAt[first], 1000);
});

test("taps for another guide or a deleted step are ignored", () => {
  const start = emptyProgress(guide);
  assert.equal(applyMessage(start, guide, done(first, 1000, "another-guide")), start);
  assert.equal(applyMessage(start, guide, done("deleted-step")), start);
});

test("other messages leave progress alone", () => {
  const start = emptyProgress(guide);
  assert.equal(applyMessage(start, guide, { type: "presence", clients: [] }), start);
});

test("the rig's check shows as passed or failed, with what it saw", () => {
  let progress = applyMessage(emptyProgress(guide), guide, done(third));
  progress = applyMessage(progress, guide, verified(third, false, "SSD not seated"));
  assert.equal(stepStatus(progress, third), "check-failed");
  assert.deepEqual(progress.checks[third], { ok: false, detail: "SSD not seated" });
  progress = applyMessage(progress, guide, verified(third, true));
  assert.equal(stepStatus(progress, third), "checked");
  assert.deepEqual(progress.checks[third], { ok: true });
});

test("ticks follow the step's id when the expert reorders steps", () => {
  const progress = applyMessage(emptyProgress(guide), guide, done(second));
  const reordered = moveStep(guide, second, 0);
  assert.equal(stepStatus(progress, second), "done");
  assert.equal(currentStepId(reordered, progress), first);
});

test("there's no current step once every step is done", () => {
  let progress = emptyProgress(guide);
  for (const id of [first, second, third]) progress = applyMessage(progress, guide, done(id));
  assert.equal(currentStepId(guide, progress), null);
});
