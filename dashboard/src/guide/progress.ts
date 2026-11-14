// What the expert sees of the user's progress, built from the phone's step.done and the rig's step.verified.
// Kept apart from the guide so editing a step never loses its tick, and keyed by step id because the phone
// refers to steps by id even after the expert reorders them.
import type { Guide, Message } from "../../../contracts/protocol.ts";

export type StepCheck = { ok: boolean; detail?: string };

export type Progress = {
  guideId: string;
  // Phone clock time of the tap, so a step done offline shows when it really happened.
  doneAt: Record<string, number>;
  checks: Record<string, StepCheck>;
};

export type StepStatus = "todo" | "done" | "checked" | "check-failed";

export function emptyProgress(guide: Guide): Progress {
  return { guideId: guide.id, doneAt: {}, checks: {} };
}

// Messages for another guide or a step the expert has since deleted are dropped: a phone that was offline sends
// its queued taps late, and they can refer to a guide that has moved on.
export function applyMessage(progress: Progress, guide: Guide, message: Message): Progress {
  if (message.type !== "step.done" && message.type !== "step.verified") return progress;
  if (message.guideId !== progress.guideId || !guide.steps.some((s) => s.id === message.stepId)) return progress;
  if (message.type === "step.done") {
    // The relay drops repeated taps, but the first tap's time is the one worth showing if one slips through.
    if (message.stepId in progress.doneAt) return progress;
    return { ...progress, doneAt: { ...progress.doneAt, [message.stepId]: message.at } };
  }
  const check: StepCheck = message.detail === undefined ? { ok: message.ok } : { ok: message.ok, detail: message.detail };
  return { ...progress, checks: { ...progress.checks, [message.stepId]: check } };
}

export function stepStatus(progress: Progress, stepId: string): StepStatus {
  const check = progress.checks[stepId];
  if (check) return check.ok ? "checked" : "check-failed";
  return stepId in progress.doneAt ? "done" : "todo";
}

// Where the user most likely is: the first step they haven't finished. The phone owns its real position, so this
// is the dashboard's best guess between taps.
export function currentStepId(guide: Guide, progress: Progress): string | null {
  return guide.steps.find((s) => !(s.id in progress.doneAt))?.id ?? null;
}
