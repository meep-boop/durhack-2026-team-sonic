// The messages the phone, the expert dashboard, the relay and the UNO Q rig exchange over one websocket, as JSON.
// Types only, so the dashboard and relay can `import type` it without a build step or bundler config, and the
// Swift app mirrors it by hand: fixtures/messages.json has one example of every message to test against.
//
// Frames and units (decided 2026-11-14, PROJECT.md → Decision log):
// - Every position, rotation, size and axis is in the MARKER frame, in metres. Origin is the printed marker's
//   centre. The marker lies in the X–Z plane and +Y points out of its printed face, as in ARKit's image anchor.
//   +X runs towards the marker's right edge and +Z towards its bottom edge, reading the print upright.
//   PROVISIONAL: Apple doesn't document the X and Z directions; Salman confirms them on a device.
// - The phone pins objects to the marker's anchor and does no conversion. The dashboard converts from splat
//   coordinates using the four corner clicks, because the splat's scale and axes are arbitrary and change with the
//   file format; splat coordinates never travel except in `calib.set`.
// - Quaternions are [x, y, z, w], the order three.js and simd_quatf(ix:iy:iz:r:) take.

export type Vec3 = [number, number, number];
export type Quat = [number, number, number, number];

export type Role = "expert" | "user" | "rig";

// Must match the file names in assets/models/ (glTF for the dashboard, USDZ for the phone). Adding a model is a
// contract change: flag it to Max, Laura and Salman. Every model is in metres, +Y up, with its working tip (screw
// point, arrow point, fingertip, plug contacts, SSD contact edge) at the origin, so the tip lands exactly on `pos`
// (assets/models/README.md).
export type ModelName = "screw" | "bolt" | "arrow" | "screwdriver" | "hand" | "cable-plug" | "ssd";

// Every action moves or turns the model along `axis` and loops until the user taps Next. `axis` decides the
// direction; the guide builder fills it from the model's own +Y after rotation (pull +Y, push -Y, turns around Y)
// and the expert can change it.
export type Action = "unscrew" | "pull" | "push" | "flip" | "rotate90";

// The phone compares this with the marker it's tracking; a wrong printed size puts everything off by that ratio.
export type Marker = {
  name: string;
  width: number;
  height: number;
};

export type GuideObject = {
  id: string;
  // Always set, even for a cut-out: it's what the phone draws (cut-outs on the phone are still being decided).
  model: ModelName;
  pos: Vec3;
  rot: Quat;
  // Full extents of the highlight box around the real part, along the object's own axes. The box shows where,
  // the model's animation shows how; both are always drawn.
  size: Vec3;
  action: Action | null;
  // Unit vector in the marker frame: the direction a pull or push moves, or the axis a turn spins around.
  axis: Vec3;
  label?: string;
  // A part lifted out of the scan on the dashboard. The phone may ignore it and draw `model`.
  cutoutId?: string;
  // What the UNO Q rig should see once the step is done: the stickered part (the SSD in the demo) present in a region
  // of the Nicla Vision's view, or gone from it. Region names match the Nicla's, e.g. "ssd-bay". Without it, the rig
  // doesn't check this object.
  expect?: { region: string; present: boolean };
};

export type Step = {
  // Steps are referred to by id, never by position in the list, so a done step stays done if the expert inserts
  // or reorders steps while the phone is offline.
  id: string;
  text: string;
  objects: GuideObject[];
};

export type Guide = {
  id: string;
  // Goes up by one on every edit. On reconnect the latest guide wins: the phone switches to it and keeps its place
  // and its done steps by step id, and its taps made on an older rev are still accepted.
  rev: number;
  title: string;
  marker: Marker;
  steps: Step[];
};

export type Pose = { p: Vec3; q: Quat };

// Any client → relay, first thing after connecting.
export type Hello = {
  type: "hello";
  // Bumped when a message changes shape; the relay refuses a client on another version.
  protocol: 1;
  role: Role;
  // Free text for logs and the presence list, e.g. "Salman's iPhone".
  client: string;
};

// Expert → user. Always the whole guide: guides are a few KB, and a full replace can't leave the phone with half
// an edit.
export type GuideSet = { type: "guide.set"; guide: Guide };

// Expert → user: jump to a step. On connect the relay replays the current step to dashboards and the rig, never to
// phones: the phone owns its position, so one that worked offline isn't sent backwards before its queued taps land.
export type StepSet = { type: "step.set"; guideId: string; stepId: string };

// Expert → relay, replayed to experts only and never sent to the phone. Kept so a reloaded dashboard doesn't lose
// its calibration. Corners are in splat coordinates, in the order top-left, top-right, bottom-right, bottom-left as
// the marker reads upright.
export type CalibSet = {
  type: "calib.set";
  splatId: string;
  corners: [Vec3, Vec3, Vec3, Vec3];
  // Root-mean-square distance between the clicked corners and where the solved fit puts them, in metres.
  residual: number;
};

// User → expert, when the user taps Next.
export type StepDone = {
  type: "step.done";
  guideId: string;
  rev: number;
  stepId: string;
  // Unique per tap, so the relay can drop duplicates when the phone resends its offline queue.
  doneId: string;
  // Phone clock, ms since the epoch: when the tap happened, which can be long before it arrives.
  at: number;
};

// User → expert: where the phone's camera is, so the dashboard can draw the user inside the scan.
export type PoseUpdate = {
  type: "pose";
  t: number;
  camera: Pose;
  // False while the marker is out of view; the pose then comes from world tracking alone and may drift.
  markerTracked: boolean;
};

// Rig → expert and user: what the UNO Q's camera saw after a step.
export type StepVerified = {
  type: "step.verified";
  guideId: string;
  stepId: string;
  ok: boolean;
  // What the rig saw, e.g. "seen in slot-2, expected in ssd-bay". Shown to both sides when `ok` is false.
  detail?: string;
};

// User ↔ expert. WebRTC signalling rides this websocket; the relay passes it to the other side without reading or
// storing it. The expert calls: the dashboard sends the offer and the phone answers.
export type RtcSignal = {
  type: "rtc.signal";
  signal:
    | { kind: "offer" | "answer"; sdp: string }
    | { kind: "candidate"; candidate: string; sdpMid: string | null; sdpMLineIndex: number | null };
};

// Expert → relay, answered only to that expert, never stored. A snapshot of the dashboard's current 3D view for Claude
// to label. Keep it at most 1280 px on the long side: a bigger image may be scaled down before Claude sees it, and the
// positions it returns would no longer match. The relay labels one snapshot at a time, since each one costs money.
export type LabelsRequest = {
  type: "labels.request";
  requestId: string;
  image: { mediaType: "image/jpeg" | "image/png"; data: string };
  width: number;
  height: number;
};

// A part Claude read in the snapshot, at pixel (x, y) from the image's top-left. The dashboard turns the pixel into a
// 3D point with its click-pick. Made by AI: show it as such and let the expert fix or delete it.
export type Label = { text: string; x: number; y: number };

// Relay → the expert that asked. `model` is the Claude model that answered, for the "made by AI" note.
export type LabelsResult = { type: "labels.result"; requestId: string; model: string; labels: Label[] };

// Relay → every client, on every connect and disconnect, so the dashboard can show "phone offline" during the
// link-down demo.
export type Presence = {
  type: "presence";
  clients: { role: Role; client: string }[];
};

// Relay → the client whose message it refused.
export type ErrorMessage = {
  type: "error";
  message: string;
  // The `type` of the message that was refused, when the relay could read it.
  about?: string;
};

export type Message =
  | Hello
  | GuideSet
  | StepSet
  | CalibSet
  | StepDone
  | PoseUpdate
  | StepVerified
  | RtcSignal
  | LabelsRequest
  | LabelsResult
  | Presence
  | ErrorMessage;

export type MessageType = Message["type"];
