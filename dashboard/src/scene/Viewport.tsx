import { useEffect, useRef, useState } from "react";
import { createScene, type SceneHandle, type SplatInfo } from "./scene.ts";
import { isSplatFileName, sourceName, type SplatSource } from "./splatSource.ts";

// SAMPLE, not our scan: Spark's demo splat, so the viewport works before anyone has exported a Scaniverse file.
const SAMPLE_SPLAT = "https://sparkjs.dev/assets/splats/butterfly.spz";

function initialSource(): SplatSource {
  const url = new URLSearchParams(window.location.search).get("splat");
  return { kind: "url", url: url ?? SAMPLE_SPLAT };
}

type Status =
  | { state: "loading"; name: string }
  | { state: "ready"; info: SplatInfo; sample: boolean }
  | { state: "failed"; name: string; error: string };

export function Viewport() {
  const containerRef = useRef<HTMLDivElement>(null);
  const sceneRef = useRef<SceneHandle | null>(null);
  const [status, setStatus] = useState<Status>({ state: "loading", name: "" });
  const [fps, setFps] = useState(0);

  const load = async (source: SplatSource) => {
    const scene = sceneRef.current;
    if (!scene) return;
    const name = sourceName(source);
    setStatus({ state: "loading", name });
    try {
      const info = await scene.loadSplat(source);
      if (!info) return;
      setStatus({ state: "ready", info, sample: source.kind === "url" && source.url === SAMPLE_SPLAT });
    } catch (err) {
      setStatus({ state: "failed", name, error: err instanceof Error ? err.message : String(err) });
    }
  };

  useEffect(() => {
    const scene = createScene(containerRef.current!);
    sceneRef.current = scene;
    load(initialSource());
    // The meter averages a second of frames; reading it 4× a second keeps React out of the render loop.
    const timer = window.setInterval(() => setFps(scene.fps()), 250);
    return () => {
      window.clearInterval(timer);
      scene.dispose();
      sceneRef.current = null;
    };
  }, []);

  const onDrop = (event: React.DragEvent) => {
    event.preventDefault();
    const file = [...event.dataTransfer.files].find((f) => isSplatFileName(f.name));
    if (file) load({ kind: "file", file });
  };

  return (
    <div className="viewport" ref={containerRef} onDragOver={(e) => e.preventDefault()} onDrop={onDrop}>
      <div className="hud">
        <div>{fps.toFixed(0)} fps</div>
        {status.state === "loading" && <div>Loading {status.name}…</div>}
        {status.state === "ready" && (
          <div>
            {status.sample && <span className="tag">SAMPLE</span>} {status.info.name} ·{" "}
            {status.info.splatCount.toLocaleString()} splats · loaded in {(status.info.loadMs / 1000).toFixed(1)} s
          </div>
        )}
        {status.state === "failed" && (
          <div className="error">
            Couldn't load {status.name}: {status.error}
          </div>
        )}
        <div className="hint">Drop a .spz or .ply here, or add ?splat=&lt;url&gt;</div>
      </div>
    </div>
  );
}
