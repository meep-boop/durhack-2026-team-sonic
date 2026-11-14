// Editing a guide, as plain functions over the contract's `Guide`. The guide builder holds the only copy (scene
// API, decided by Max), so every edit returns a new guide and the React panel just keeps the latest one. Each edit
// bumps `rev`, which the phone uses to accept taps made on an older version while it was offline.
import type { Guide, GuideObject, GuideSet, Marker, ModelName, Step, StepSet, Vec3 } from "../../../contracts/protocol.ts";

// Measured on the printed sheet with a ruler: assets/marker/README.md. A reprint at another size changes this.
export const PRINTED_MARKER: Marker = { name: "marker", width: 0.18, height: 0.18 };

// A small box until the expert sizes it to the real part: 2 cm fits a screw head and is easy to grab in 3D.
const DEFAULT_BOX: Vec3 = [0.02, 0.02, 0.02];
// The models rise along +Y from their tip (assets/models/README.md), so with no rotation +Y is "away from the part".
const UP: Vec3 = [0, 1, 0];

const newId = () => crypto.randomUUID();

export function createGuide(title: string): Guide {
  return { id: newId(), rev: 0, title, marker: PRINTED_MARKER, steps: [] };
}

function edited(guide: Guide, steps: Step[], changes: Partial<Pick<Guide, "title">> = {}): Guide {
  return { ...guide, ...changes, steps, rev: guide.rev + 1 };
}

function stepIndex(guide: Guide, stepId: string): number {
  const index = guide.steps.findIndex((s) => s.id === stepId);
  // The panel only edits steps it is showing, so a missing id is a bug in the panel, not something to skip.
  if (index === -1) throw new Error(`no step "${stepId}" in guide "${guide.id}"`);
  return index;
}

function withStep(guide: Guide, stepId: string, change: (step: Step) => Step): Guide {
  const index = stepIndex(guide, stepId);
  return edited(guide, guide.steps.map((s, i) => (i === index ? change(s) : s)));
}

function requireObject(objects: GuideObject[], stepId: string, objectId: string) {
  if (!objects.some((o) => o.id === objectId)) throw new Error(`no object "${objectId}" in step "${stepId}"`);
}

function withObjects(guide: Guide, stepId: string, change: (objects: GuideObject[]) => GuideObject[]): Guide {
  return withStep(guide, stepId, (step) => ({ ...step, objects: change(step.objects) }));
}

export function renameGuide(guide: Guide, title: string): Guide {
  return edited(guide, guide.steps, { title });
}

export function addStep(guide: Guide, text = ""): Guide {
  return edited(guide, [...guide.steps, { id: newId(), text, objects: [] }]);
}

export function removeStep(guide: Guide, stepId: string): Guide {
  stepIndex(guide, stepId);
  return edited(guide, guide.steps.filter((s) => s.id !== stepId));
}

export function moveStep(guide: Guide, stepId: string, toIndex: number): Guide {
  const from = stepIndex(guide, stepId);
  const to = Math.max(0, Math.min(toIndex, guide.steps.length - 1));
  const steps = [...guide.steps];
  const [step] = steps.splice(from, 1);
  steps.splice(to, 0, step!);
  return edited(guide, steps);
}

export function setStepText(guide: Guide, stepId: string, text: string): Guide {
  return withStep(guide, stepId, (step) => ({ ...step, text }));
}

export function addObject(guide: Guide, stepId: string, model: ModelName, pos: Vec3): Guide {
  const object: GuideObject = { id: newId(), model, pos, rot: [0, 0, 0, 1], size: DEFAULT_BOX, action: null, axis: UP };
  return withObjects(guide, stepId, (objects) => [...objects, object]);
}

// Also how a 3D drag lands: the scene reports { pos, rot } and the panel passes it straight in.
export function updateObject(
  guide: Guide,
  stepId: string,
  objectId: string,
  changes: Partial<Omit<GuideObject, "id">>,
): Guide {
  return withObjects(guide, stepId, (objects) => {
    requireObject(objects, stepId, objectId);
    return objects.map((o) => (o.id === objectId ? { ...o, ...changes } : o));
  });
}

export function removeObject(guide: Guide, stepId: string, objectId: string): Guide {
  return withObjects(guide, stepId, (objects) => {
    requireObject(objects, stepId, objectId);
    return objects.filter((o) => o.id !== objectId);
  });
}

// What stops Send, in words the expert can act on. The relay refuses an empty title or step text anyway; this
// says why before the expert presses the button.
export function sendBlockers(guide: Guide): string[] {
  const blockers: string[] = [];
  if (guide.title.trim() === "") blockers.push("Give the guide a title.");
  if (guide.steps.length === 0) blockers.push("Add at least one step.");
  guide.steps.forEach((step, i) => {
    if (step.text.trim() === "") blockers.push(`Step ${i + 1} needs an instruction.`);
  });
  return blockers;
}

export function guideSetMessage(guide: Guide): GuideSet {
  return { type: "guide.set", guide };
}

export function stepSetMessage(guide: Guide, stepId: string): StepSet {
  stepIndex(guide, stepId);
  return { type: "step.set", guideId: guide.id, stepId };
}
