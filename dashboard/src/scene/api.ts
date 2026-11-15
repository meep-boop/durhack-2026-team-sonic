// What the guide builder (Laura, dashboard/src/guide/) can ask of the 3D scene (Max, dashboard/src/scene/), and what
// it hears back. scene.ts implements it; App.tsx makes the one scene and hands it to the guide panel. Why it's shaped
// this way: docs/remote-assist/scene-api.md.
//
// The guide builder holds the only copy of the guide. The scene draws whatever step it is handed and reports the
// expert's 3D edits back; it never keeps steps or objects of its own (decided by Max, 2026-11-14).
//
// Positions and rotations here are exactly what goes into a GuideObject (marker frame, metres), so the guide builder
// copies them across and never converts anything. Until the scan on screen is calibrated there is no marker frame,
// so nothing can be placed (decided by Max, 2026-11-15): pickPoint resolves to null and objects aren't drawn.
import type { GuideObject, Quat, Vec3 } from "../../../contracts/protocol.ts";

export type Unsubscribe = () => void;

export type SceneApi = {
  // Draws these objects (highlight box plus model) and removes anything from the previous call that isn't here.
  // Call it again after every edit, with the step's full object list.
  showStep(objects: readonly GuideObject[]): void;

  // Outlines one object, or none. Selection is the guide builder's state; the scene only shows it.
  select(objectId: string | null): void;

  // Moves the camera so the object fills the view: used when a step is opened, and later by "find port 14".
  focus(objectId: string): void;

  // The next click on the scan resolves to that point. Esc, another pickPoint call, a scan switch, or an
  // uncalibrated scan resolves to null.
  pickPoint(): Promise<Vec3 | null>;

  // Whether the scan on screen has its marker calibration. Switching scans can change it either way.
  isCalibrated(): boolean;
  onCalibrated(listener: (calibrated: boolean) => void): Unsubscribe;

  // Loops the object's preset action (unscrew, pull…) until stopPreview or the next previewAction.
  previewAction(objectId: string): void;
  stopPreview(): void;

  // The expert dragged or turned an object in 3D; fired once, when the drag ends. The guide builder applies it to
  // the guide and calls showStep.
  onObjectMoved(listener: (objectId: string, pos: Vec3, rot: Quat) => void): Unsubscribe;

  // The expert clicked an object in 3D, e.g. to select it in the step list.
  onObjectClicked(listener: (objectId: string) => void): Unsubscribe;
};
