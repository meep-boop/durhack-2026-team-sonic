import { type ReactNode, useEffect, useState } from "react";
import type { Guide } from "../../../contracts/protocol.ts";
import { currentStepId, type Progress, stepStatus, type StepStatus } from "../guide/progress.ts";
import { type Calibration, CORNER_NAMES, MAX_RESIDUAL_MM } from "../scene/useCalibration.ts";
import type { Live } from "./live.ts";

type Tone = "accent" | "ok" | "warn" | "danger" | "idle";
type Props = { live: Live | null; calibration: Calibration; scanReady: boolean; relayUrl: string };

// The one line that says what's happening and what to do next: setting up, building, or watching the person work.
export function LiveStrip({ live, calibration, scanReady, relayUrl }: Props) {
  const ticking = live?.phone.state === "offline" || (live?.catchUp?.count ?? 0) > 0;
  const now = useClock(ticking);
  const { progress } = calibration;

  if (progress.step === "clicking") {
    return (
      <Strip tone="accent" phase="Calibrate" aside="Esc cancels">
        Click the marker's <b>{CORNER_NAMES[progress.corners.length]}</b> corner on the scan ({progress.corners.length + 1} of
        4, as the print reads upright).
      </Strip>
    );
  }
  if (progress.step === "refused") {
    return (
      <Strip tone="danger" phase="Calibrate" action={<button type="button" onClick={calibration.start}>Try again</button>}>
        Off by {progress.residualMm.toFixed(1)} mm (the limit is {MAX_RESIDUAL_MM} mm): one click missed its corner.
      </Strip>
    );
  }
  if (!live) return <Strip tone="idle" phase="Starting">Connecting to the relay…</Strip>;
  if (live.relay !== "connected") {
    return (
      <Strip tone="danger" phase="Relay">
        Can't reach the relay at {relayUrl}, retrying. The phone keeps its guide; sending waits until the relay is back.
      </Strip>
    );
  }
  if (live.guide && live.progress) return <Session live={live} guide={live.guide} progress={live.progress} now={now} />;
  if (scanReady && !calibration.calibrated) {
    return (
      <Strip tone="accent" phase="Set up" action={<button type="button" className="primary" onClick={calibration.start}>Calibrate</button>}>
        Click the printed marker's four corners on the scan, so the parts you place line up on the phone.
      </Strip>
    );
  }
  return (
    <Strip tone="idle" phase="Build">
      Write the steps on the right, place each part on the scan, then <b>Send to phone</b>.
    </Strip>
  );
}

function Session({ live, guide, progress, now }: { live: Live; guide: Guide; progress: Progress; now: number }) {
  const total = guide.steps.length;
  const currentId = currentStepId(guide, progress);
  const index = guide.steps.findIndex((s) => s.id === currentId);
  const steps = <StepDots guide={guide} progress={progress} currentId={currentId} />;
  const { phone, catchUp, lastCheck } = live;
  const check = lastCheck && (
    <span className={lastCheck.ok ? "text-ok" : "text-danger"}>
      Rig {lastCheck.ok ? "✓" : "✗"} step {guide.steps.findIndex((s) => s.id === lastCheck.stepId) + 1}
      {lastCheck.detail ? `: ${lastCheck.detail}` : ""}
    </span>
  );

  // A phone that leaves after the last step has finished, not dropped out.
  if (currentId === null) {
    return (
      <Strip tone="ok" phase="Done" aside={<>{check}{steps}</>}>
        All {total} steps done.
      </Strip>
    );
  }
  if (phone.state === "offline" && phone.seen) {
    return (
      <Strip tone="warn" phase={`Offline ${clock(now - phone.since)}`} aside={steps}>
        The phone lost its connection. It has the whole guide and keeps going on its own; its taps show here when it's
        back.
      </Strip>
    );
  }
  if (catchUp && catchUp.count > 0 && now < catchUp.until) {
    return (
      <Strip tone="ok" phase="Back online" aside={steps}>
        Caught up: {catchUp.count === 1 ? "1 step was" : `${catchUp.count} steps were`} done while the phone was offline.
      </Strip>
    );
  }
  if (phone.state === "offline") {
    return (
      <Strip tone="idle" phase="Sent" aside={steps}>
        The guide is on the relay. Waiting for the phone to connect.
      </Strip>
    );
  }
  return (
    <Strip tone="accent" phase={`Step ${index + 1} of ${total}`} aside={<>{check}{steps}</>}>
      <span className="step-text">{guide.steps[index]!.text || "(no instruction yet)"}</span>
    </Strip>
  );
}

function Strip({ tone, phase, children, aside, action }: { tone: Tone; phase: string; children: ReactNode; aside?: ReactNode; action?: ReactNode }) {
  return (
    <section className={`strip strip-${tone}`} role="status" aria-live="polite">
      <span className="strip-phase">{phase}</span>
      <p className="strip-text">{children}</p>
      {action}
      {aside && <div className="strip-aside">{aside}</div>}
    </section>
  );
}

const DOT_LABEL: Record<StepStatus, string> = { todo: "to do", done: "done", checked: "done, rig checked", "check-failed": "rig check failed" };

function StepDots({ guide, progress, currentId }: { guide: Guide; progress: Progress; currentId: string | null }) {
  return (
    <ol className="dots" aria-label="Steps">
      {guide.steps.map((s, i) => {
        const status = stepStatus(progress, s.id);
        return (
          <li key={s.id} className={`dot dot-${status}${s.id === currentId ? " dot-current" : ""}`} title={s.text}>
            <span aria-hidden="true">{status === "checked" ? "✓" : status === "check-failed" ? "✗" : i + 1}</span>
            <span className="sr-only">
              Step {i + 1}, {s.id === currentId ? "current" : DOT_LABEL[status]}
            </span>
          </li>
        );
      })}
    </ol>
  );
}

// Re-renders once a second only while something on screen counts time.
function useClock(ticking: boolean): number {
  const [now, setNow] = useState(Date.now);
  useEffect(() => {
    if (!ticking) return;
    setNow(Date.now());
    const timer = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, [ticking]);
  return now;
}

function clock(ms: number): string {
  const seconds = Math.max(0, Math.floor(ms / 1000));
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
}
