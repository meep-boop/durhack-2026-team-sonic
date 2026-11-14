import type { Action, GuideObject, Hello, Message, MessageType, ModelName, Role } from "../contracts/protocol.ts";

type Obj = Record<string, unknown>;
type Problem = string | null;

export type ParseResult = { ok: true; message: Message } | { ok: false; error: string; about?: string };

const PROTOCOL: Hello["protocol"] = 1;

// Loose enough for float32 rounding on the phone, tight enough to catch a quaternion nobody normalised, which
// RealityKit would apply as a scale.
const UNIT_TOLERANCE = 1e-3;

// Written as Record<…, true> so the type-checker fails if a name is added to the contract and not here.
const ROLES = { expert: true, user: true, rig: true } satisfies Record<Role, true>;
const MODELS = {
  screw: true,
  bolt: true,
  arrow: true,
  screwdriver: true,
  hand: true,
  "cable-plug": true,
} satisfies Record<ModelName, true>;
const ACTIONS = { unscrew: true, pull: true, push: true, flip: true, rotate90: true } satisfies Record<Action, true>;
const CABLE_STATES = { in: true, out: true } satisfies Record<NonNullable<GuideObject["expect"]>["cable"], true>;

const isObj = (x: unknown): x is Obj => typeof x === "object" && x !== null && !Array.isArray(x);
const isNum = (x: unknown): x is number => typeof x === "number" && Number.isFinite(x);

const text = (x: unknown, path: string): Problem =>
  typeof x === "string" && x.length > 0 ? null : `${path}: expected a non-empty string`;
const optionalText = (x: unknown, path: string): Problem => (x === undefined ? null : text(x, path));
const flag = (x: unknown, path: string): Problem => (typeof x === "boolean" ? null : `${path}: expected true or false`);
const positive = (x: unknown, path: string): Problem => (isNum(x) && x > 0 ? null : `${path}: expected a positive number`);
const wholeNumber = (x: unknown, path: string): Problem =>
  Number.isInteger(x) && (x as number) >= 0 ? null : `${path}: expected a whole number ≥ 0`;
const isIn = (table: Obj, x: unknown) => typeof x === "string" && Object.hasOwn(table, x);
const oneOf = (table: Obj, x: unknown, path: string): Problem =>
  isIn(table, x) ? null : `${path}: expected one of ${Object.keys(table).join(", ")}`;

const numbers = (x: unknown, count: number, path: string): Problem =>
  Array.isArray(x) && x.length === count && x.every(isNum) ? null : `${path}: expected ${count} finite numbers`;

const unit = (x: unknown, count: number, noun: string, path: string): Problem => {
  const problem = numbers(x, count, path);
  if (problem) return problem;
  const length = Math.hypot(...(x as number[]));
  return Math.abs(length - 1) <= UNIT_TOLERANCE ? null : `${path}: expected a unit ${noun}, length is ${length.toFixed(4)}`;
};

const positiveSize = (x: unknown, path: string): Problem =>
  numbers(x, 3, path) === null && (x as number[]).every((n) => n > 0) ? null : `${path}: expected 3 positive numbers`;

const firstProblem = (items: unknown, check: (item: unknown, path: string) => Problem, path: string): Problem => {
  if (!Array.isArray(items)) return `${path}: expected a list`;
  for (const [i, item] of items.entries()) {
    const problem = check(item, `${path}[${i}]`);
    if (problem) return problem;
  }
  return null;
};

const checkPose = (x: unknown, path: string): Problem =>
  isObj(x) ? numbers(x.p, 3, `${path}.p`) ?? unit(x.q, 4, "quaternion", `${path}.q`) : `${path}: expected an object`;

const checkMarker = (x: unknown, path: string): Problem =>
  isObj(x)
    ? text(x.name, `${path}.name`) ?? positive(x.width, `${path}.width`) ?? positive(x.height, `${path}.height`)
    : `${path}: expected an object`;

const checkExpect = (x: unknown, path: string): Problem => {
  if (x === undefined) return null;
  if (!isObj(x)) return `${path}: expected an object`;
  return text(x.port, `${path}.port`) ?? oneOf(CABLE_STATES, x.cable, `${path}.cable`);
};

const checkObject = (x: unknown, path: string): Problem => {
  if (!isObj(x)) return `${path}: expected an object`;
  return (
    text(x.id, `${path}.id`) ??
    oneOf(MODELS, x.model, `${path}.model`) ??
    numbers(x.pos, 3, `${path}.pos`) ??
    unit(x.rot, 4, "quaternion", `${path}.rot`) ??
    positiveSize(x.size, `${path}.size`) ??
    (x.action === null || isIn(ACTIONS, x.action)
      ? null
      : `${path}.action: expected null or one of ${Object.keys(ACTIONS).join(", ")}`) ??
    unit(x.axis, 3, "vector", `${path}.axis`) ??
    optionalText(x.label, `${path}.label`) ??
    optionalText(x.cutoutId, `${path}.cutoutId`) ??
    checkExpect(x.expect, `${path}.expect`)
  );
};

export function checkGuide(guide: unknown, path = "guide"): Problem {
  if (!isObj(guide)) return `${path}: expected an object`;
  const header =
    text(guide.id, `${path}.id`) ??
    wholeNumber(guide.rev, `${path}.rev`) ??
    text(guide.title, `${path}.title`) ??
    checkMarker(guide.marker, `${path}.marker`);
  if (header) return header;
  if (!Array.isArray(guide.steps)) return `${path}.steps: expected a list`;

  // Ids are what step.done and the resync refer to, so a repeat would tick the wrong step.
  const stepIds = new Set<unknown>();
  const objectIds = new Set<unknown>();
  for (const [i, step] of guide.steps.entries()) {
    const stepPath = `${path}.steps[${i}]`;
    if (!isObj(step)) return `${stepPath}: expected an object`;
    const problem =
      text(step.id, `${stepPath}.id`) ??
      text(step.text, `${stepPath}.text`) ??
      firstProblem(step.objects, checkObject, `${stepPath}.objects`);
    if (problem) return problem;
    if (stepIds.has(step.id)) return `${stepPath}.id: duplicate step id "${step.id}"`;
    stepIds.add(step.id);
    for (const [j, object] of (step.objects as Obj[]).entries()) {
      if (objectIds.has(object.id)) return `${stepPath}.objects[${j}].id: duplicate object id "${object.id}"`;
      objectIds.add(object.id);
    }
  }
  return null;
}

const checkSignal = (x: unknown): Problem => {
  if (!isObj(x)) return "signal: expected an object";
  switch (x.kind) {
    case "offer":
    case "answer":
      return text(x.sdp, "signal.sdp");
    case "candidate":
      // An empty candidate string is how WebRTC says "no more candidates", so it's allowed here.
      return (
        (typeof x.candidate === "string" ? null : "signal.candidate: expected a string") ??
        (x.sdpMid === null || typeof x.sdpMid === "string" ? null : "signal.sdpMid: expected a string or null") ??
        (x.sdpMLineIndex === null || Number.isInteger(x.sdpMLineIndex)
          ? null
          : "signal.sdpMLineIndex: expected a whole number or null")
      );
    default:
      return "signal.kind: expected offer, answer or candidate";
  }
};

const checks = {
  hello: (m) =>
    (m.protocol === PROTOCOL ? null : `protocol: expected ${PROTOCOL}, got ${JSON.stringify(m.protocol)}`) ??
    oneOf(ROLES, m.role, "role") ??
    text(m.client, "client"),
  "guide.set": (m) => checkGuide(m.guide),
  "step.set": (m) => text(m.guideId, "guideId") ?? text(m.stepId, "stepId"),
  "calib.set": (m) =>
    text(m.splatId, "splatId") ??
    (Array.isArray(m.corners) && m.corners.length === 4 ? null : "corners: expected 4 points") ??
    firstProblem(m.corners, (corner, path) => numbers(corner, 3, path), "corners") ??
    (isNum(m.residual) && m.residual >= 0 ? null : "residual: expected a number ≥ 0"),
  "step.done": (m) =>
    text(m.guideId, "guideId") ??
    wholeNumber(m.rev, "rev") ??
    text(m.stepId, "stepId") ??
    text(m.doneId, "doneId") ??
    (isNum(m.at) ? null : "at: expected a time in ms"),
  pose: (m) =>
    (isNum(m.t) ? null : "t: expected a time in ms") ?? checkPose(m.camera, "camera") ?? flag(m.markerTracked, "markerTracked"),
  "step.verified": (m) =>
    text(m.guideId, "guideId") ?? text(m.stepId, "stepId") ?? flag(m.ok, "ok") ?? optionalText(m.detail, "detail"),
  "rtc.signal": (m) => checkSignal(m.signal),
  presence: (m) =>
    firstProblem(
      m.clients,
      (client, path) =>
        isObj(client) ? oneOf(ROLES, client.role, `${path}.role`) ?? text(client.client, `${path}.client`) : `${path}: expected an object`,
      "clients",
    ),
  error: (m) => text(m.message, "message") ?? optionalText(m.about, "about"),
} satisfies Record<MessageType, (m: Obj) => Problem>;

export const MESSAGE_TYPES = Object.keys(checks) as MessageType[];

export function parseMessage(raw: string): ParseResult {
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    return { ok: false, error: "not valid JSON" };
  }
  if (!isObj(value)) return { ok: false, error: "expected a JSON object" };
  const { type } = value;
  if (typeof type !== "string") return { ok: false, error: "type: expected a string" };
  if (!Object.hasOwn(checks, type)) return { ok: false, error: "unknown message type", about: type };
  const problem = checks[type as MessageType](value);
  return problem ? { ok: false, error: problem, about: type } : { ok: true, message: value as Message };
}
