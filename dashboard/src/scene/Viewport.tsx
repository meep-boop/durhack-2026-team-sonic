import { type RefObject, useEffect, useState } from "react";
import type { RelayClient } from "../relay/client.ts";
import { Labels } from "./Labels.tsx";
import type { SceneHandle } from "./scene.ts";
import type { ScanSwitch } from "./useScan.ts";

type Props = {
  containerRef: RefObject<HTMLDivElement | null>;
  scene: SceneHandle | null;
  relay: RelayClient | null;
  scan: ScanSwitch;
};

export function Viewport({ containerRef, scene, relay, scan }: Props) {
  const debug = useDebugToggle();
  const { status } = scan;

  return (
    <div className="stage" onDragOver={(e) => e.preventDefault()} onDrop={(e) => {
      e.preventDefault();
      scan.open([...e.dataTransfer.files]);
    }}>
      <div className="viewport" ref={containerRef} />
      {status.state === "loading" && <div className="stage-note" role="status">Loading the scan {status.name}…</div>}
      {status.state === "failed" && (
        <div className="stage-note error" role="alert">
          Couldn't load {status.name}: {status.error}
        </div>
      )}
      {scene && relay && status.state === "ready" && <Labels scene={scene} relay={relay} scanId={status.info.name} />}
      <p className="controls-hint">
        Drag to orbit · right-drag to pan · scroll to zoom · on a selected part, drag its arrows, <kbd>R</kbd> turns,{" "}
        <kbd>T</kbd> moves
      </p>
      {debug && scene && <DebugPanel scene={scene} scan={scan} />}
    </div>
  );
}

// For the team, not the expert: ` (backquote) or ?debug shows it.
function useDebugToggle(): boolean {
  const [on, setOn] = useState(() => new URLSearchParams(window.location.search).has("debug"));
  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key !== "`") return;
      if (event.target instanceof HTMLElement && event.target.closest("input, textarea, select")) return;
      setOn((v) => !v);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  return on;
}

function DebugPanel({ scene, scan }: { scene: SceneHandle; scan: ScanSwitch }) {
  const [fps, setFps] = useState(0);
  useEffect(() => {
    // The meter averages a second of frames; reading it 4× a second keeps React out of the render loop.
    const timer = window.setInterval(() => setFps(scene.fps()), 250);
    return () => window.clearInterval(timer);
  }, [scene]);
  const { status } = scan;

  return (
    <div className="debug">
      <div>{fps.toFixed(0)} fps</div>
      {status.state === "ready" && (
        <div>
          {status.info.name} · {status.info.count.toLocaleString()} {status.info.kind === "splat" ? "splats" : "triangles"} ·
          loaded in {(status.info.loadMs / 1000).toFixed(1)} s
        </div>
      )}
      <div>Scans: dashboard/public/scans/, opened with ?closed=&lt;file&gt;&amp;open=&lt;file&gt;, or drop one here</div>
      <div>` hides this</div>
    </div>
  );
}
