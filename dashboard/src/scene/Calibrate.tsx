import { useEffect, useState } from "react";
import type { Vec3 } from "../../../contracts/protocol.ts";
import type { RelayClient } from "../relay/client.ts";
import { solveCalibration } from "./calibration.ts";
import type { Corners, SceneHandle } from "./scene.ts";

// Above this the fit is too loose to place parts a few mm wide, so the clicks are refused (Ahmed's plan, 01:45).
const MAX_RESIDUAL_M = 0.005;
const CORNER_NAMES = ["top-left", "top-right", "bottom-right", "bottom-left"] as const;

type State =
  | { step: "idle" }
  | { step: "clicking"; corners: Vec3[] }
  | { step: "refused"; residualMm: number }
  | { step: "done"; residualMm: number; saved: boolean };

type Props = { scene: SceneHandle; relay: RelayClient; marker: { width: number; height: number } };

export function Calibrate({ scene, relay, marker }: Props) {
  const [state, setState] = useState<State>({ step: "idle" });
  const [calibrated, setCalibrated] = useState(scene.isCalibrated());

  useEffect(() => scene.onCalibrated(setCalibrated), [scene]);

  const start = async () => {
    const splatId = scene.splatId();
    if (!splatId) return;
    const corners: Vec3[] = [];
    setState({ step: "clicking", corners });
    while (corners.length < 4) {
      const point = await scene.pickScanPoint();
      if (!point) {
        scene.showCornerClicks([]);
        setState({ step: "idle" });
        return;
      }
      corners.push(point);
      scene.showCornerClicks(corners);
      setState({ step: "clicking", corners: [...corners] });
    }

    const four = corners as Corners;
    const { residual } = solveCalibration(four, marker);
    const residualMm = residual * 1000;
    if (residual > MAX_RESIDUAL_M) {
      scene.showCornerClicks([]);
      setState({ step: "refused", residualMm });
      return;
    }
    scene.setCalibration(splatId, four);
    const saved = relay.send({ type: "calib.set", splatId, corners: four, residual });
    setState({ step: "done", residualMm, saved });
  };

  return (
    <div className="calibrate">
      {state.step === "clicking" ? (
        <div>
          Click the marker's <b>{CORNER_NAMES[state.corners.length]}</b> corner ({state.corners.length + 1}/4, as the
          print reads upright). Esc cancels.
        </div>
      ) : (
        <button type="button" onClick={start}>
          {calibrated ? "Recalibrate" : "Calibrate: click the marker's 4 corners"}
        </button>
      )}
      {!calibrated && state.step !== "clicking" && <div className="warn">Not calibrated: placing is off for this scan.</div>}
      {state.step === "refused" && (
        <div className="error">
          Off by {state.residualMm.toFixed(1)} mm (limit {MAX_RESIDUAL_M * 1000} mm): one click missed its corner. Try
          again.
        </div>
      )}
      {state.step === "done" && (
        <div>
          Calibrated, off by {state.residualMm.toFixed(1)} mm.
          {!state.saved && <span className="error"> Relay offline: not saved, redo it once it's back.</span>}
        </div>
      )}
    </div>
  );
}
