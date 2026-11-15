// Stands in for the expert dashboard, so the phone app and the UNO Q rig can be built and tested without it: it
// sends a guide (the sample one by default), optionally jumps to a step, and prints everything sent back.
// Run: node fixtures/fake-expert.ts [ws://host:8080] [--guide path/to/guide.json] [--step s4]
import { readFileSync } from "node:fs";
import { parseArgs } from "node:util";
import type { Guide, Message } from "../contracts/protocol.ts";
import { parseMessage } from "../relay/validate.ts";

export type FakeExpert = { received: Message[]; close: () => void };

type FakeExpertOptions = { url: string; guide: Guide; stepId?: string; log?: (line: string) => void };

// Resolves once connected and the guide is sent; `received` keeps filling until `close`.
export function startFakeExpert({ url, guide, stepId, log = console.log }: FakeExpertOptions) {
  return new Promise<FakeExpert>((resolve, reject) => {
    const socket = new WebSocket(url);
    const send = (message: Message) => socket.send(JSON.stringify(message));
    const received: Message[] = [];
    let lastPoseLogged = 0;

    socket.addEventListener("open", () => {
      send({ type: "hello", protocol: 1, role: "expert", client: "fake expert" });
      send({ type: "guide.set", guide });
      log(`sent guide "${guide.title}" rev ${guide.rev}`);
      if (stepId) {
        send({ type: "step.set", guideId: guide.id, stepId });
        log(`jumped to ${stepId}`);
      }
      resolve({ received, close: () => socket.close() });
    });
    socket.addEventListener("error", () => reject(new Error(`couldn't connect to ${url}`)));
    socket.addEventListener("close", () => log("disconnected from the relay"));

    socket.addEventListener("message", (event) => {
      const result = parseMessage(String(event.data));
      if (!result.ok) return log(`! the relay sent a bad message: ${result.error}`);
      const message = result.message;
      received.push(message);
      switch (message.type) {
        case "step.done":
          log(`user finished ${message.stepId}`);
          break;
        case "pose":
          // Poses arrive many times a second; a line a second is enough to see the phone moving.
          if (message.t - lastPoseLogged >= 1000) {
            lastPoseLogged = message.t;
            const at = message.camera.p.map((n) => n.toFixed(2)).join(", ");
            log(`phone camera at [${at}]${message.markerTracked ? "" : " (marker out of view)"}`);
          }
          break;
        case "step.verified":
          log(`rig on ${message.stepId}: ${message.ok ? "correct" : `wrong (${message.detail ?? "no detail"})`}`);
          break;
        case "presence":
          log(`connected: ${message.clients.map(({ role, client }) => `${role} "${client}"`).join(", ")}`);
          break;
        case "error":
          log(`! relay refused ${message.about ?? "a message"}: ${message.message}`);
          break;
      }
    });
  });
}

if (import.meta.main) {
  const { values, positionals } = parseArgs({
    options: { guide: { type: "string" }, step: { type: "string" } },
    allowPositionals: true,
  });
  const guide = JSON.parse(readFileSync(values.guide ?? new URL("./sample-guide.json", import.meta.url), "utf8")) as Guide;
  await startFakeExpert({ url: positionals[0] ?? "ws://localhost:8080", guide, stepId: values.step });
}
