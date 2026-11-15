import { useEffect, useState } from "react";
import type { RelayClient } from "../relay/client.ts";
import type { SceneHandle } from "./scene.ts";

// The phone streams about ten poses a second; this long without one means it's offline or stopped tracking.
const STALE_MS = 3000;

export type PhonePose = "none" | "tracked" | "drifting";

// Draws the phone's camera in the scan from its `pose` messages, and says whether to trust where it is.
export function usePhonePose(scene: SceneHandle | null, relay: RelayClient | null): PhonePose {
  const [pose, setPose] = useState<PhonePose>("none");

  useEffect(() => {
    if (!scene || !relay) return;
    let lastPoseAt = 0;
    const off = relay.on("pose", ({ camera, markerTracked }) => {
      lastPoseAt = performance.now();
      scene.showUser(camera, markerTracked);
      // React skips the re-render when the value hasn't changed, so ten poses a second cost nothing here.
      setPose(markerTracked ? "tracked" : "drifting");
    });
    const stale = window.setInterval(() => {
      if (lastPoseAt === 0 || performance.now() - lastPoseAt < STALE_MS) return;
      lastPoseAt = 0;
      scene.showUser(null, false);
      setPose("none");
    }, 500);
    return () => {
      off();
      window.clearInterval(stale);
      scene.showUser(null, false);
    };
  }, [scene, relay]);

  return pose;
}
