import { StrictMode, useEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { createScene, type SceneHandle } from "./scene/scene.ts";
import { useScan } from "./scene/useScan.ts";
import { Viewport } from "./scene/Viewport.tsx";
import "./styles.css";

// Just the 3D scan, for the technician console's side panel (ios/expert-call/): the same scene and scan loading as the
// dashboard, with orbit, pan and zoom, but no relay, calibration or guide panel, so nothing repeats the console.
// Pick the scan with ?splat=<file in public/scans/>, as in the dashboard.
const MARKER = { width: 0.18, height: 0.18 };

function Viewer() {
  const viewportRef = useRef<HTMLDivElement>(null);
  const [scene, setScene] = useState<SceneHandle | null>(null);

  useEffect(() => {
    const made = createScene(viewportRef.current!, MARKER);
    setScene(made);
    return () => made.dispose();
  }, []);

  const scan = useScan(scene);
  return (
    <div className="viewer-only">
      <Viewport containerRef={viewportRef} scene={scene} relay={null} scan={scan} />
    </div>
  );
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Viewer />
  </StrictMode>,
);
