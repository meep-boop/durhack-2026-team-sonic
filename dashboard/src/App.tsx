import { useEffect, useRef, useState } from "react";
import { GuidePanel } from "./guide/GuidePanel.tsx";
import { connectRelay, type RelayClient, type RelayStatus } from "./relay/client.ts";
import { createScene, type SceneHandle } from "./scene/scene.ts";
import { Viewport } from "./scene/Viewport.tsx";

// The printed marker, measured with a ruler (assets/marker/README.md). Calibration takes the scan's scale from it.
const MARKER = { width: 0.18, height: 0.18 };

// The relay runs on this laptop in the demo, so the page's own host is the default; ?relay=ws://… overrides it.
function relayUrl(): string {
  return new URLSearchParams(window.location.search).get("relay") ?? `ws://${window.location.hostname || "localhost"}:8080`;
}

export function App() {
  const viewportRef = useRef<HTMLDivElement>(null);
  const [scene, setScene] = useState<SceneHandle | null>(null);
  const [relay, setRelay] = useState<RelayClient | null>(null);
  const [relayStatus, setRelayStatus] = useState<RelayStatus>("connecting");

  // One scene and one relay link for the page's life; the guide panel gets both and never makes its own.
  useEffect(() => {
    const madeScene = createScene(viewportRef.current!, MARKER);
    const madeRelay = connectRelay({ url: relayUrl() });
    // The relay replays every scan's saved calibration on connect, so a reloaded dashboard needs no new clicks.
    const offCalib = madeRelay.on("calib.set", ({ splatId, corners }) => {
      try {
        madeScene.setCalibration(splatId, corners);
      } catch (err) {
        console.error(`saved calibration for ${splatId} doesn't solve:`, err);
      }
    });
    const offStatus = madeRelay.onStatus(setRelayStatus);
    setScene(madeScene);
    setRelay(madeRelay);
    return () => {
      offCalib();
      offStatus();
      madeRelay.close();
      madeScene.dispose();
    };
  }, []);

  return (
    <div className="app">
      <Viewport containerRef={viewportRef} scene={scene} relay={relay} marker={MARKER} />
      <aside className="guide">
        <div className={`relay relay-${relayStatus}`}>Relay: {relayStatus}</div>
        {scene && relay && <GuidePanel scene={scene} relay={relay} />}
      </aside>
    </div>
  );
}
