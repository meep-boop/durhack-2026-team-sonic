import { once } from "node:events";
import { existsSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import type { AddressInfo } from "node:net";
import { WebSocketServer, type WebSocket } from "ws";
import type {
  CalibSet,
  Guide,
  LabelsRequest,
  Message,
  MessageType,
  Role,
  StepDone,
  StepVerified,
} from "../contracts/protocol.ts";
import type { Labeller } from "./labeller.ts";
import { parseMessage } from "./validate.ts";

export type RelayOptions = {
  port: number;
  host?: string;
  // Without a path the relay keeps everything in memory only.
  statePath?: string;
  fresh?: boolean;
  heartbeatMs?: number;
  // Without one, the relay refuses `labels.request`.
  labeller?: Labeller;
  log?: (line: string) => void;
};

export type Relay = { port: number; close: () => Promise<void> };

type State = {
  guide: Guide | null;
  stepId: string | null;
  calib: CalibSet | null;
  done: StepDone[];
  verified: StepVerified[];
};

type Peer = { role: Role; client: string };
type Connection = { peer: Peer | null; alive: boolean };

type RelayOnly = "presence" | "error" | "labels.result";
type ForwardedType = Exclude<MessageType, "hello" | RelayOnly>;
type Forwarded = Extract<Message, { type: ForwardedType }>;

// Guides are a few KB and SDP offers a few more; anything near this size is a bug or an attack.
const MAX_MESSAGE_BYTES = 1 << 20;

const EVERYONE: Role[] = ["expert", "user", "rig"];

// Who may send each message, and which roles it reaches. Experts get each other's edits because two dashboards can
// be open at once.
const ROUTES: Record<ForwardedType, { from: Role[]; to: (sender: Role) => Role[] }> = {
  "guide.set": { from: ["expert"], to: () => EVERYONE },
  "step.set": { from: ["expert"], to: () => EVERYONE },
  "calib.set": { from: ["expert"], to: () => ["expert"] },
  "step.done": { from: ["user"], to: () => ["expert", "rig"] },
  pose: { from: ["user"], to: () => ["expert"] },
  "step.verified": { from: ["rig"], to: () => ["expert", "user"] },
  "rtc.signal": { from: ["user", "expert"], to: (sender) => [sender === "user" ? "expert" : "user"] },
  // Answered by the relay itself, to the asking dashboard only.
  "labels.request": { from: ["expert"], to: () => [] },
};

const reaches = (type: ForwardedType, sender: Role, role: Role) => ROUTES[type].to(sender).includes(role);

const emptyState = (): State => ({ guide: null, stepId: null, calib: null, done: [], verified: [] });

function loadState(path: string | undefined, fresh: boolean): State {
  if (!path || fresh || !existsSync(path)) return emptyState();
  try {
    return JSON.parse(readFileSync(path, "utf8")) as State;
  } catch (error) {
    throw new Error(`${path} can't be read (${(error as Error).message}). Start with --fresh to discard it.`);
  }
}

// Write then rename, so a crash mid-write leaves the previous state instead of half a file.
function writeAtomically(path: string, text: string) {
  writeFileSync(`${path}.tmp`, text);
  renameSync(`${path}.tmp`, path);
}

export async function startRelay(options: RelayOptions): Promise<Relay> {
  const { statePath, heartbeatMs = 5000, labeller, log = console.log } = options;
  const state = loadState(statePath, options.fresh ?? false);
  const save = () => {
    if (statePath) writeAtomically(statePath, JSON.stringify(state));
  };
  if (options.fresh) save();

  const connections = new Map<WebSocket, Connection>();
  const server = new WebSocketServer({ port: options.port, host: options.host, maxPayload: MAX_MESSAGE_BYTES });
  await once(server, "listening");

  // A labelling answer can come back after its dashboard has gone.
  const send = (socket: WebSocket, message: Message) => {
    if (socket.readyState === socket.OPEN) socket.send(JSON.stringify(message));
  };

  const refuse = (socket: WebSocket, error: string, about?: string) => {
    log(`! ${connections.get(socket)?.peer?.client ?? "unnamed client"}: ${error}`);
    send(socket, { type: "error", message: error, about });
  };

  const forward = (message: Message, roles: Role[], sender: WebSocket) => {
    const text = JSON.stringify(message);
    for (const [socket, { peer }] of connections) {
      if (socket !== sender && peer && roles.includes(peer.role)) socket.send(text);
    }
  };

  const broadcastPresence = () => {
    const clients = [...connections.values()].flatMap(({ peer }) => (peer ? [peer] : []));
    for (const [socket, { peer }] of connections) if (peer) send(socket, { type: "presence", clients });
  };

  const replay = (socket: WebSocket, role: Role) => {
    const { guide, stepId, calib } = state;
    if (calib && reaches("calib.set", "expert", role)) send(socket, calib);
    if (guide && reaches("guide.set", "expert", role)) send(socket, { type: "guide.set", guide });
    // The phone owns its own position. Its taps made offline arrive only after this replay, so replaying the
    // relay's step would send a phone that worked offline backwards (decided 2026-11-14, PROJECT.md).
    if (guide && stepId && role !== "user" && reaches("step.set", "expert", role)) {
      send(socket, { type: "step.set", guideId: guide.id, stepId });
    }
    if (reaches("step.done", "user", role)) state.done.forEach((done) => send(socket, done));
    if (reaches("step.verified", "rig", role)) state.verified.forEach((verified) => send(socket, verified));
  };

  let labelling = false;
  const answerLabels = async (socket: WebSocket, request: LabelsRequest) => {
    if (!labeller) return refuse(socket, "labelling is off on this relay (start it with --labels)", request.type);
    // Each snapshot is a paid Claude call, so a dashboard stuck in a loop can only run one at a time.
    if (labelling) return refuse(socket, "still labelling the last snapshot", request.type);
    labelling = true;
    try {
      const { model, labels } = await labeller(request);
      send(socket, { type: "labels.result", requestId: request.requestId, model, labels });
      log(`labelled snapshot ${request.requestId}: ${labels.length} labels from ${model}`);
    } catch (error) {
      refuse(socket, `labelling failed: ${(error as Error).message}`, request.type);
    } finally {
      labelling = false;
    }
  };

  const handle = (socket: WebSocket, sender: Peer, message: Forwarded) => {
    const route = ROUTES[message.type];
    if (!route.from.includes(sender.role)) return refuse(socket, `a ${sender.role} can't send ${message.type}`, message.type);
    const { guide } = state;

    switch (message.type) {
      case "guide.set": {
        const next = message.guide;
        const sameGuide = guide?.id === next.id;
        if (!sameGuide) {
          state.done = [];
          state.verified = [];
        }
        if (!sameGuide || !next.steps.some((step) => step.id === state.stepId)) state.stepId = next.steps[0]?.id ?? null;
        state.guide = next;
        break;
      }
      case "step.set":
        if (guide?.id !== message.guideId || !guide.steps.some((step) => step.id === message.stepId)) {
          return refuse(socket, `no step "${message.stepId}" in the current guide`, message.type);
        }
        state.stepId = message.stepId;
        break;
      case "calib.set":
        state.calib = message;
        break;
      case "step.done": {
        if (guide?.id !== message.guideId) return refuse(socket, `the relay has no guide "${message.guideId}"`, message.type);
        // The phone resends its offline queue when it reconnects, so a repeat is expected and dropped quietly.
        if (state.done.some((done) => done.doneId === message.doneId)) return;
        state.done.push(message);
        if (message.stepId === state.stepId) {
          const index = guide.steps.findIndex((step) => step.id === message.stepId);
          state.stepId = guide.steps[index + 1]?.id ?? state.stepId;
        }
        break;
      }
      case "step.verified":
        if (guide?.id !== message.guideId) return refuse(socket, `the relay has no guide "${message.guideId}"`, message.type);
        state.verified = [...state.verified.filter((verified) => verified.stepId !== message.stepId), message];
        break;
      case "pose":
      case "rtc.signal":
        return forward(message, route.to(sender.role), socket);
      case "labels.request":
        return void answerLabels(socket, message);
    }
    save();
    forward(message, route.to(sender.role), socket);
  };

  server.on("connection", (socket) => {
    const connection: Connection = { peer: null, alive: true };
    connections.set(socket, connection);
    socket.on("pong", () => (connection.alive = true));

    socket.on("message", (data, isBinary) => {
      if (isBinary) return refuse(socket, "binary messages aren't part of the protocol");
      const result = parseMessage(data.toString());
      if (!result.ok) return refuse(socket, result.error, result.about);
      const { message } = result;

      if (message.type === "hello") {
        if (connection.peer) return refuse(socket, "already said hello", message.type);
        connection.peer = { role: message.role, client: message.client };
        log(`+ ${message.role} "${message.client}"`);
        replay(socket, message.role);
        return broadcastPresence();
      }
      if (!connection.peer) return refuse(socket, "say hello first", message.type);
      if (message.type === "presence" || message.type === "error" || message.type === "labels.result") {
        return refuse(socket, `only the relay sends ${message.type}`, message.type);
      }
      handle(socket, connection.peer, message);
    });

    socket.on("close", () => {
      connections.delete(socket);
      if (!connection.peer) return;
      log(`- ${connection.peer.role} "${connection.peer.client}"`);
      broadcastPresence();
    });
  });

  // A phone that drops off Wi-Fi often never closes its socket, so without pings it would look connected for
  // minutes and the dashboard couldn't show "phone offline" in the link-down demo.
  const heartbeat = setInterval(() => {
    for (const [socket, connection] of connections) {
      if (!connection.alive) {
        socket.terminate();
        continue;
      }
      connection.alive = false;
      socket.ping();
    }
  }, heartbeatMs);

  return {
    port: (server.address() as AddressInfo).port,
    close: async () => {
      clearInterval(heartbeat);
      for (const socket of connections.keys()) socket.terminate();
      await new Promise<void>((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
    },
  };
}
