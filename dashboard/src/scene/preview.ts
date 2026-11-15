// Where a model sits during its action preview, as a slide along `axis` (metres) and a turn around it (radians).
// Pure numbers, so the loop timing is testable without a renderer.
import type { Action } from "../../../contracts/protocol.ts";

export const PREVIEW_LOOP_MS = 1500;
const SLIDE_M = 0.03;

export function previewPose(action: Action, elapsedMs: number): { slide: number; turn: number } {
  // The last fifth of each loop holds the end pose, so the move reads as finished before it restarts.
  const t = Math.min(((elapsedMs % PREVIEW_LOOP_MS) / PREVIEW_LOOP_MS) * 1.25, 1);
  switch (action) {
    case "pull":
    case "push":
      // `axis` already points the way the part moves, push or pull.
      return { slide: SLIDE_M * t, turn: 0 };
    case "unscrew":
      return { slide: 0.005 * t, turn: -4 * Math.PI * t };
    case "rotate90":
      return { slide: 0, turn: (Math.PI / 2) * t };
    case "flip":
      return { slide: 0, turn: Math.PI * t };
  }
}
