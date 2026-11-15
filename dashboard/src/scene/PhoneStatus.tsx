import { useEffect, useState } from "react";
import type { RelayClient } from "../relay/client.ts";
import type { SceneHandle } from "./scene.ts";

// The phone streams about ten poses a second; this long without one means it's offline or stopped tracking.
const STALE_MS = 3000;

type Phone = "none" | "tracked" | "drifting";

// Draws the phone's camera in the scan from its `pose` messages, and says in the HUD whether to trust it.
export function PhoneStatus({ scene, relay }: { scene: SceneHandle; relay: RelayClient }) {
  const [phone, setPhone] = useState<Phone>("none");

  useEffect(() => {
    let lastPoseAt = 0;
    const off = relay.on("pose", ({ camera, markerTracked }) => {
      lastPoseAt = performance.now();
      scene.showUser(camera, markerTracked);
      // React skips the re-render when the value hasn't changed, so ten poses a second cost nothing here.
      setPhone(markerTracked ? "tracked" : "drifting");
    });
    const stale = window.setInterval(() => {
      if (lastPoseAt === 0 || performance.now() - lastPoseAt < STALE_MS) return;
      lastPoseAt = 0;
      scene.showUser(null, false);
      setPhone("none");
    }, 500);
    return () => {
      off();
      window.clearInterval(stale);
      scene.showUser(null, false);
    };
  }, [scene, relay]);

  if (phone === "none") return <div className="hint">Phone: no position coming in</div>;
  if (phone === "drifting") return <div className="warn">Phone: marker out of view, its position may drift</div>;
  return <div className="ok">Phone: tracking the marker</div>;
}
