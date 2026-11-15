import { useEffect, useRef, useState } from "react";
import { GuidePanel } from "./guide/GuidePanel.tsx";
import { connectRelay } from "./relay/client.ts";
import { createScene, type SceneHandle } from "./scene/scene.ts";
import { useCalibration } from "./scene/useCalibration.ts";
import { usePhonePose } from "./scene/usePhonePose.ts";
import { useScan } from "./scene/useScan.ts";
import { Viewport } from "./scene/Viewport.tsx";
import { Header } from "./shell/Header.tsx";
import { createLiveStore, type LiveStore, useLive } from "./shell/live.ts";
import { LiveStrip } from "./shell/LiveStrip.tsx";

// The printed marker, measured with a ruler (assets/marker/README.md). Calibration takes the scan's scale from it.
const MARKER = { width: 0.18, height: 0.18 };

const params = new URLSearchParams(window.location.search);
// The relay runs on this laptop in the demo, so the page's own host is the default; ?relay=ws://… overrides it.
const RELAY_URL = params.get("relay") ?? `ws://${window.location.hostname || "localhost"}:8080`;
// Salman's call page (ios/expert-call/), served on port 8000 by its README's one-liner; ?call=… overrides it.
const CALL_URL = params.get("call") ?? `http://${window.location.hostname || "localhost"}:8000/?relay=${encodeURIComponent(RELAY_URL)}`;

type Session = { scene: SceneHandle; live: LiveStore };

export function App() {
  const viewportRef = useRef<HTMLDivElement>(null);
  const [session, setSession] = useState<Session | null>(null);

  // One scene and one relay link for the page's life; everything else gets them from here and never makes its own.
  useEffect(() => {
    const scene = createScene(viewportRef.current!, MARKER);
    const relay = connectRelay({ url: RELAY_URL });
    const live = createLiveStore(relay);
    // The relay replays every scan's saved calibration on connect, so a reloaded dashboard needs no new clicks.
    const offCalib = relay.on("calib.set", ({ splatId, corners }) => {
      try {
        scene.setCalibration(splatId, corners);
      } catch (err) {
        console.error(`saved calibration for ${splatId} doesn't solve:`, err);
      }
    });
    setSession({ scene, live });
    return () => {
      offCalib();
      live.dispose();
      relay.close();
      scene.dispose();
    };
  }, []);

  const scene = session?.scene ?? null;
  const relay = session?.live.relay ?? null;
  const scan = useScan(scene);
  const calibration = useCalibration(scene, relay, MARKER);
  const pose = usePhonePose(scene, relay);
  const live = useLive(session?.live ?? null);

  return (
    <div className="app">
      <Header scan={scan} calibration={calibration} live={live} pose={pose} callUrl={CALL_URL} />
      <LiveStrip live={live} calibration={calibration} scanReady={scan.status.state === "ready"} relayUrl={RELAY_URL} />
      <main className="work">
        <Viewport containerRef={viewportRef} scene={scene} relay={relay} scan={scan} />
        <aside className="guide" aria-label="Guide">
          {scene && relay && <GuidePanel scene={scene} relay={relay} />}
        </aside>
      </main>
    </div>
  );
}
