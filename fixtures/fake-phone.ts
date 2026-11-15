// Stands in for the iPhone app, so the dashboard can be built and tested without a phone: it plays whatever guide the
// relay sends, taps Next every few seconds and streams a SIMULATED camera pose circling the marker. With --offline-after
// it drops the link mid-guide, keeps tapping into a queue and sends the queue when the link returns, like the real app
// must for Neptune North. A tap stays queued until the relay sends it back as a receipt.
// Run: node fixtures/fake-phone.ts [ws://host:8080] [--every 3000] [--offline-after 2 --offline-for 8000]
import { parseArgs } from "node:util";
import type { Guide, Message, StepDone } from "../contracts/protocol.ts";
import { parseMessage } from "../relay/validate.ts";

export type FakePhoneOptions = {
  url: string;
  tapEveryMs?: number;
  poseEveryMs?: number;
  // Drop the link after this many taps and come back after `forMs`.
  offline?: { afterSteps: number; forMs: number };
  log?: (line: string) => void;
};

// Resolves once every step has been tapped and every tap has reached the relay.
export function runFakePhone({ url, tapEveryMs = 3000, poseEveryMs = 100, offline, log = console.log }: FakePhoneOptions) {
  return new Promise<void>((resolve, reject) => {
    let socket: WebSocket;
    let online = false;
    let droppingOnPurpose = false;
    let guide: Guide | null = null;
    let index = 0;
    let finished = false;
    const queue: StepDone[] = [];
    const timers: ReturnType<typeof setInterval>[] = [];
    const send = (message: Message) => socket.send(JSON.stringify(message));

    const sendPose = () => {
      if (!online) return;
      // Walk round the marker 40 cm out, turning to keep facing it.
      const angle = Date.now() / 2000;
      send({
        type: "pose",
        t: Date.now(),
        camera: { p: [0.4 * Math.sin(angle), 0.4, 0.4 * Math.cos(angle)], q: [0, Math.sin(angle / 2), 0, Math.cos(angle / 2)] },
        markerTracked: true,
      });
    };

    const tapNext = () => {
      const step = guide?.steps[index];
      if (!guide || !step) return;
      const done: StepDone = { type: "step.done", guideId: guide.id, rev: guide.rev, stepId: step.id, doneId: crypto.randomUUID(), at: Date.now() };
      queue.push(done);
      if (online) send(done);
      log(`tapped Next on ${step.id}${online ? "" : " (offline, queued)"}: ${step.text}`);
      index += 1;
      if (index === guide.steps.length) {
        finished = true;
        log("guide finished");
      } else if (offline && index === offline.afterSteps && online) {
        log(`link down for ${offline.forMs} ms`);
        droppingOnPurpose = true;
        socket.close();
        setTimeout(connect, offline.forMs);
      }
    };

    const onMessage = (event: MessageEvent) => {
      const result = parseMessage(String(event.data));
      if (!result.ok) return log(`! the relay sent a bad message: ${result.error}`);
      const message = result.message;
      if (message.type === "guide.set") {
        // The latest guide wins, and the phone keeps its place by step id (PROJECT.md, offline rule).
        const sameGuide = guide?.id === message.guide.id;
        const currentId = guide?.steps[index]?.id;
        guide = message.guide;
        const kept = sameGuide ? guide.steps.findIndex((step) => step.id === currentId) : -1;
        index = kept >= 0 ? kept : sameGuide ? Math.min(index, guide.steps.length) : 0;
        log(`got guide "${guide.title}" rev ${guide.rev}, ${guide.steps.length} steps`);
      } else if (message.type === "step.set" && guide?.id === message.guideId) {
        const target = guide.steps.findIndex((step) => step.id === message.stepId);
        if (target >= 0) index = target;
        log(`expert moved me to ${message.stepId}`);
      } else if (message.type === "step.done") {
        const receipted = queue.findIndex((tap) => tap.doneId === message.doneId);
        if (receipted >= 0) queue.splice(receipted, 1);
        if (finished && !queue.length) socket.close();
      } else if (message.type === "error") {
        log(`! relay refused ${message.about ?? "a message"}: ${message.message}`);
      }
    };

    const connect = () => {
      socket = new WebSocket(url);
      socket.addEventListener("message", onMessage);
      socket.addEventListener("open", () => {
        online = true;
        droppingOnPurpose = false;
        send({ type: "hello", protocol: 1, role: "user", client: "fake phone" });
        if (queue.length) log(`link back: sending ${queue.length} queued taps`);
        queue.forEach(send);
      });
      socket.addEventListener("close", () => {
        online = false;
        if (droppingOnPurpose) return;
        timers.forEach(clearInterval);
        if (finished) resolve();
        else reject(new Error(`lost the connection to ${url} before the guide was finished`));
      });
    };

    connect();
    timers.push(setInterval(sendPose, poseEveryMs), setInterval(tapNext, tapEveryMs));
  });
}

if (import.meta.main) {
  const { values, positionals } = parseArgs({
    options: {
      every: { type: "string" },
      "offline-after": { type: "string" },
      "offline-for": { type: "string" },
    },
    allowPositionals: true,
  });
  const afterSteps = values["offline-after"];
  await runFakePhone({
    url: positionals[0] ?? "ws://localhost:8080",
    tapEveryMs: Number(values.every ?? 3000),
    offline: afterSteps ? { afterSteps: Number(afterSteps), forMs: Number(values["offline-for"] ?? 8000) } : undefined,
  });
}
