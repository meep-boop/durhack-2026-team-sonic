import assert from "node:assert/strict";
import { test } from "node:test";
import { checkGuide, parseMessage } from "../../../relay/validate.ts";
import {
  addObject,
  addStep,
  createGuide,
  guideSetMessage,
  moveStep,
  PRINTED_MARKER,
  removeObject,
  removeStep,
  renameGuide,
  sendBlockers,
  setStepText,
  stepSetMessage,
  updateObject,
} from "./guide.ts";

const ids = (guide: { steps: { id: string }[] }) => guide.steps.map((s) => s.id);

function threeStepGuide() {
  let guide = createGuide("SAMPLE: replace the SSD");
  for (const text of ["Undo the cover screws", "Lift the cover", "Pull out the SSD"]) guide = addStep(guide, text);
  return guide;
}

test("a new guide carries the printed marker and no steps", () => {
  const guide = createGuide("Swap the SSD");
  assert.deepEqual(guide.marker, { name: "marker", width: 0.18, height: 0.18 });
  assert.equal(guide.marker, PRINTED_MARKER);
  assert.deepEqual(guide.steps, []);
  assert.equal(guide.rev, 0);
});

test("every edit bumps rev and leaves the old guide untouched", () => {
  const before = threeStepGuide();
  const after = setStepText(before, before.steps[0]!.id, "Undo the four cover screws");
  assert.equal(after.rev, before.rev + 1);
  assert.equal(before.steps[0]!.text, "Undo the cover screws");
  assert.equal(after.steps[0]!.text, "Undo the four cover screws");
  assert.equal(renameGuide(after, "New title").rev, after.rev + 1);
});

test("step and object ids are unique", () => {
  let guide = threeStepGuide();
  const step = guide.steps[0]!.id;
  guide = addObject(guide, step, "screw", [0, 0, 0]);
  guide = addObject(guide, step, "screw", [0.01, 0, 0]);
  const all = [...ids(guide), ...guide.steps.flatMap((s) => s.objects.map((o) => o.id))];
  assert.equal(new Set(all).size, all.length);
});

test("moving a step keeps its id and clamps to the ends of the list", () => {
  const guide = threeStepGuide();
  const [a, b, c] = ids(guide);
  assert.deepEqual(ids(moveStep(guide, c!, 0)), [c, a, b]);
  assert.deepEqual(ids(moveStep(guide, a!, 99)), [b, c, a]);
  assert.deepEqual(ids(moveStep(guide, b!, -5)), [b, a, c]);
});

test("removing a step keeps the others in order", () => {
  const guide = threeStepGuide();
  const [a, b, c] = ids(guide);
  assert.deepEqual(ids(removeStep(guide, b!)), [a, c]);
});

test("a new object stands upright at the picked point with no action", () => {
  const guide = threeStepGuide();
  const step = guide.steps[0]!.id;
  const object = addObject(guide, step, "screwdriver", [0.05, 0, -0.02]).steps[0]!.objects[0]!;
  assert.deepEqual(object.pos, [0.05, 0, -0.02]);
  assert.deepEqual(object.rot, [0, 0, 0, 1]);
  assert.deepEqual(object.axis, [0, 1, 0]);
  assert.equal(object.action, null);
  assert.equal(object.model, "screwdriver");
});

test("a 3D move or a picker change updates only that object", () => {
  let guide = threeStepGuide();
  const step = guide.steps[0]!.id;
  guide = addObject(guide, step, "screw", [0, 0, 0]);
  guide = addObject(guide, step, "arrow", [0.1, 0, 0]);
  const [screw, arrow] = guide.steps[0]!.objects;
  guide = updateObject(guide, step, screw!.id, { pos: [0.02, 0, 0.01], rot: [0, 0.7071068, 0, 0.7071068] });
  guide = updateObject(guide, step, screw!.id, { action: "unscrew" });
  const [movedScrew, sameArrow] = guide.steps[0]!.objects;
  assert.deepEqual(movedScrew!.pos, [0.02, 0, 0.01]);
  assert.equal(movedScrew!.action, "unscrew");
  assert.equal(movedScrew!.id, screw!.id);
  assert.deepEqual(sameArrow, arrow);
});

test("removing an object leaves the step's other objects", () => {
  let guide = threeStepGuide();
  const step = guide.steps[0]!.id;
  guide = addObject(guide, step, "screw", [0, 0, 0]);
  guide = addObject(guide, step, "hand", [0, 0.1, 0]);
  const [screw, hand] = guide.steps[0]!.objects;
  assert.deepEqual(removeObject(guide, step, screw!.id).steps[0]!.objects, [hand]);
});

test("editing a step or object that isn't there is a bug and throws", () => {
  const guide = threeStepGuide();
  const step = guide.steps[0]!.id;
  assert.throws(() => setStepText(guide, "nope", "x"), /no step "nope"/);
  assert.throws(() => removeStep(guide, "nope"), /no step/);
  assert.throws(() => moveStep(guide, "nope", 0), /no step/);
  assert.throws(() => addObject(guide, "nope", "screw", [0, 0, 0]), /no step/);
  assert.throws(() => updateObject(guide, step, "nope", { action: "pull" }), /no object "nope"/);
  assert.throws(() => removeObject(guide, step, "nope"), /no object/);
  assert.throws(() => stepSetMessage(guide, "nope"), /no step/);
});

test("send is blocked, with reasons, until the guide is complete", () => {
  assert.deepEqual(sendBlockers(createGuide(" ")), ["Give the guide a title.", "Add at least one step."]);
  let guide = addStep(addStep(createGuide("Swap the SSD"), "Undo the screws"), "   ");
  assert.deepEqual(sendBlockers(guide), ["Step 2 needs an instruction."]);
  guide = setStepText(guide, guide.steps[1]!.id, "Lift the cover");
  assert.deepEqual(sendBlockers(guide), []);
});

test("a guide with no blockers passes the relay's own check", () => {
  let guide = threeStepGuide();
  for (const step of guide.steps) guide = addObject(guide, step.id, "arrow", [0.03, 0, 0.04]);
  const step = guide.steps[0]!.id;
  const objectId = guide.steps[0]!.objects[0]!.id;
  guide = updateObject(guide, step, objectId, { model: "screw", action: "unscrew" });
  assert.deepEqual(sendBlockers(guide), []);
  assert.equal(checkGuide(guide), null);
  assert.ok(parseMessage(JSON.stringify(guideSetMessage(guide))).ok);
});

test("jumping to a step names the guide and the step", () => {
  const guide = threeStepGuide();
  const message = stepSetMessage(guide, guide.steps[1]!.id);
  assert.deepEqual(message, { type: "step.set", guideId: guide.id, stepId: guide.steps[1]!.id });
  assert.ok(parseMessage(JSON.stringify(message)).ok);
});
