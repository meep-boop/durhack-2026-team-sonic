// Stands in for the iPhone app, so the dashboard can be built and tested without a phone: it plays whatever guide the
// relay sends, taps Next every few seconds and streams a camera pose circling the marker.
// Run: node fixtures/fake-phone.ts [ws://host:8080]
import type { Guide, Message } from "../contracts/protocol.ts";
import { parseMessage } from "../relay/validate.ts";

export type FakePhoneOptions = {
  url: string;
  tapEveryMs?: number;
  poseEveryMs?: number;
  log?: (line: string) => void;
};

// Resolves once every step has been tapped.
export function runFakePhone({ url, tapEveryMs = 3000, poseEveryMs = 100, log = console.log }: FakePhoneOptions) {
  return new Promise<void>((resolve, reject) => {
    const socket = new WebSocket(url);
    const send = (message: Message) => socket.send(JSON.stringify(message));
    let guide: Guide | null = null;
    let index = 0;
    let finished = false;
    const timers: ReturnType<typeof setInterval>[] = [];

    const sendPose = () => {
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
      send({ type: "step.done", guideId: guide.id, rev: guide.rev, stepId: step.id, doneId: crypto.randomUUID(), at: Date.now() });
      log(`tapped Next on ${step.id}: ${step.text}`);
      index += 1;
      if (index === guide.steps.length) {
        finished = true;
        log("guide finished");
        socket.close();
      }
    };

    socket.addEventListener("open", () => {
      send({ type: "hello", protocol: 1, role: "user", client: "fake phone" });
      timers.push(setInterval(sendPose, poseEveryMs), setInterval(tapNext, tapEveryMs));
    });

    socket.addEventListener("message", (event) => {
      const result = parseMessage(String(event.data));
      if (!result.ok) return log(`! the relay sent a bad message: ${result.error}`);
      const message = result.message;
      if (message.type === "guide.set") {
        if (guide?.id !== message.guide.id) index = 0;
        guide = message.guide;
        log(`got guide "${guide.title}" rev ${guide.rev}, ${guide.steps.length} steps`);
      } else if (message.type === "step.set" && guide?.id === message.guideId) {
        const target = guide.steps.findIndex((step) => step.id === message.stepId);
        if (target >= 0) index = target;
        log(`now on ${message.stepId}`);
      } else if (message.type === "error") {
        log(`! relay refused ${message.about ?? "a message"}: ${message.message}`);
      }
    });

    socket.addEventListener("close", () => {
      timers.forEach(clearInterval);
      if (finished) resolve();
      else reject(new Error(`lost the connection to ${url} before the guide was finished`));
    });
  });
}

if (import.meta.main) await runFakePhone({ url: process.argv[2] ?? "ws://localhost:8080" });
