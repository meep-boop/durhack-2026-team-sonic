import type { Calibration } from "../scene/useCalibration.ts";
import type { PhonePose } from "../scene/usePhonePose.ts";
import type { ScanSwitch } from "../scene/useScan.ts";
import type { Live } from "./live.ts";

type Tone = "ok" | "warn" | "danger" | "idle";
type Props = { scan: ScanSwitch; calibration: Calibration; live: Live | null; pose: PhonePose; callUrl: string };

export function Header({ scan, calibration, live, pose, callUrl }: Props) {
  return (
    <header className="topbar">
      <div className="brand">
        Remote Assist <span>expert</span>
      </div>
      <div className="scan-controls">
        {scan.scans.length > 1 && (
          <div className="segmented" role="group" aria-label="Scan">
            {scan.scans.map((s) => (
              <button type="button" key={s.label} aria-pressed={scan.active === s.label} onClick={() => scan.switchTo(s)}>
                {s.label}
              </button>
            ))}
          </div>
        )}
        <ScanName scan={scan} />
        {scan.status.state === "ready" && (
          // Before a guide exists the live strip asks for calibration with its own button; one is enough.
          <CalibrationChip calibration={calibration} offerStart={live?.relay !== "connected" || live.guide !== null} />
        )}
      </div>
      <ul className="lights" aria-label="Connections">
        <Light {...relayLight(live)} />
        <Light {...phoneLight(live, pose)} />
        <Light {...rigLight(live)} />
      </ul>
      <a className="button call" href={callUrl} target="remote-assist-call">
        Call the phone
      </a>
    </header>
  );
}

function ScanName({ scan: { status } }: { scan: ScanSwitch }) {
  if (status.state === "loading") return <span className="muted">Loading…</span>;
  if (status.state === "failed") return <span className="text-danger">Scan didn't load</span>;
  return (
    <span className="scan-name">
      {status.sample && <span className="badge badge-warn">SAMPLE</span>}
      {status.info.name}
      <span className="muted"> · {status.info.kind} scan</span>
    </span>
  );
}

function CalibrationChip({ calibration, offerStart }: { calibration: Calibration; offerStart: boolean }) {
  const { calibrated, residualMm, progress, start } = calibration;
  if (progress.step === "clicking") return <span className="chip chip-accent">Calibrating: corner {progress.corners.length + 1} of 4</span>;
  if (!calibrated) {
    return (
      <span className={`chip chip-warn${offerStart ? "" : " chip-plain"}`}>
        Not calibrated
        {offerStart && (
          <button type="button" className="chip-action" onClick={start}>
            Calibrate
          </button>
        )}
      </span>
    );
  }
  const unsaved = progress.step === "done" && !progress.saved;
  return (
    <span className={`chip ${unsaved ? "chip-warn" : "chip-ok"}`}>
      ✓ Calibrated
      {residualMm !== null && <span className="muted"> · off by {residualMm.toFixed(1)} mm</span>}
      {unsaved && " · not saved (relay was offline)"}
      <button type="button" className="chip-action" onClick={start}>
        Recalibrate
      </button>
    </span>
  );
}

// The label always says the state in words, so the dot's colour is never the only signal. `title` is the client's
// own name ("Salman's iPhone").
type LightProps = { tone: Tone; label: string; title?: string | undefined };

function Light({ tone, label, title }: LightProps) {
  return (
    <li className={`light light-${tone}`} title={title}>
      <span className="light-dot" aria-hidden="true" />
      {label}
    </li>
  );
}

function relayLight(live: Live | null): LightProps {
  if (live?.relay === "connected") return { tone: "ok", label: "Relay" };
  if (live?.relay === "closed") return { tone: "danger", label: "Relay closed" };
  return { tone: "warn", label: "Relay: reconnecting" };
}

function phoneLight(live: Live | null, pose: PhonePose): LightProps {
  const phone = live?.phone;
  if (!phone || phone.state === "unknown") return { tone: "idle", label: "Phone: unknown" };
  const title = phone.name ?? undefined;
  if (phone.state === "offline") {
    return phone.seen ? { tone: "warn", label: "Phone offline", title } : { tone: "idle", label: "Phone: not connected" };
  }
  if (pose === "drifting") return { tone: "warn", label: "Phone: marker out of view", title };
  return { tone: "ok", label: pose === "tracked" ? "Phone: tracking" : "Phone", title };
}

function rigLight(live: Live | null): LightProps {
  const rig = live?.rig;
  if (rig?.state === "online") return { tone: "ok", label: "Rig", title: rig.name ?? undefined };
  return { tone: "idle", label: "Rig: not connected" };
}
