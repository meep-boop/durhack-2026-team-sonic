import { type RefObject, useEffect, useState } from "react";
import type { RelayClient } from "../relay/client.ts";
import { Calibrate } from "./Calibrate.tsx";
import { PhoneStatus } from "./PhoneStatus.tsx";
import type { ScanInfo, SceneHandle } from "./scene.ts";
import { type Scan, SAMPLE_SPLAT, scansFromQuery } from "./scans.ts";
import { type ScanSource, scanKind, sourceName } from "./scanSource.ts";

type Status =
  | { state: "loading"; name: string }
  | { state: "ready"; info: ScanInfo; sample: boolean }
  | { state: "failed"; name: string; error: string };

type Props = {
  containerRef: RefObject<HTMLDivElement | null>;
  scene: SceneHandle | null;
  relay: RelayClient | null;
  marker: { width: number; height: number };
};

const scans = scansFromQuery(window.location.search);

export function Viewport({ containerRef, scene, relay, marker }: Props) {
  const [status, setStatus] = useState<Status>({ state: "loading", name: "" });
  const [active, setActive] = useState(scans[0]!.label);
  const [fps, setFps] = useState(0);

  const load = async (source: ScanSource) => {
    if (!scene) return;
    const name = sourceName(source);
    setStatus({ state: "loading", name });
    try {
      const info = await scene.loadScan(source);
      if (!info) return;
      setStatus({ state: "ready", info, sample: source.kind === "url" && source.url === SAMPLE_SPLAT });
    } catch (err) {
      setStatus({ state: "failed", name, error: err instanceof Error ? err.message : String(err) });
    }
  };

  useEffect(() => {
    if (!scene) return;
    load(scans[0]!.source);
    // The meter averages a second of frames; reading it 4× a second keeps React out of the render loop.
    const timer = window.setInterval(() => setFps(scene.fps()), 250);
    return () => window.clearInterval(timer);
  }, [scene]);

  const switchTo = (scan: Scan) => {
    setActive(scan.label);
    load(scan.source);
  };

  const onDrop = (event: React.DragEvent) => {
    event.preventDefault();
    const file = [...event.dataTransfer.files].find((f) => scanKind(f.name) !== null);
    if (file) {
      setActive("");
      load({ kind: "file", file });
    }
  };

  return (
    <div className="viewport" ref={containerRef} onDragOver={(e) => e.preventDefault()} onDrop={onDrop}>
      <div className="hud">
        <div>{fps.toFixed(0)} fps</div>
        {status.state === "loading" && <div>Loading {status.name}…</div>}
        {status.state === "ready" && (
          <div>
            {status.sample && <span className="tag">SAMPLE</span>} {status.info.name} ·{" "}
            {status.info.count.toLocaleString()} {status.info.kind === "splat" ? "splats" : "triangles"} · loaded in {(status.info.loadMs / 1000).toFixed(1)} s
          </div>
        )}
        {status.state === "failed" && (
          <div className="error">
            Couldn't load {status.name}: {status.error}
          </div>
        )}
        {scans.length > 1 && (
          <div className="switch">
            {scans.map((scan) => (
              <button type="button" key={scan.label} aria-pressed={active === scan.label} onClick={() => switchTo(scan)}>
                {scan.label}
              </button>
            ))}
          </div>
        )}
        {scene && relay && status.state === "ready" && <Calibrate scene={scene} relay={relay} marker={marker} />}
        {scene && relay && <PhoneStatus scene={scene} relay={relay} />}
        <div className="hint">Scans go in dashboard/public/scans/: ?closed=&lt;file&gt;&amp;open=&lt;file&gt;, or drop one here</div>
      </div>
    </div>
  );
}
