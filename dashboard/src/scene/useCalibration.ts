import { useEffect, useState } from "react";
import type { Vec3 } from "../../../contracts/protocol.ts";
import type { RelayClient } from "../relay/client.ts";
import { solveCalibration } from "./calibration.ts";
import type { Corners, SceneHandle } from "./scene.ts";

// Above this the fit is too loose to place parts a few mm wide, so the clicks are refused (Ahmed's plan, 01:45).
export const MAX_RESIDUAL_MM = 5;
export const CORNER_NAMES = ["top-left", "top-right", "bottom-right", "bottom-left"] as const;

export type CalibrationStep =
  | { step: "idle" }
  | { step: "clicking"; corners: Vec3[] }
  | { step: "refused"; residualMm: number }
  | { step: "done"; saved: boolean };

export type Calibration = {
  calibrated: boolean;
  // How far the clicks missed the printed corners, for the scan on screen, when this page knows it.
  residualMm: number | null;
  progress: CalibrationStep;
  start(): void;
};

type Marker = { width: number; height: number };

export function useCalibration(scene: SceneHandle | null, relay: RelayClient | null, marker: Marker): Calibration {
  const [progress, setProgress] = useState<CalibrationStep>({ step: "idle" });
  const [calibrated, setCalibrated] = useState(false);
  const [residuals, setResiduals] = useState<ReadonlyMap<string, number>>(new Map());

  useEffect(() => {
    if (!scene) return;
    setCalibrated(scene.isCalibrated());
    return scene.onCalibrated((now) => {
      setCalibrated(now);
      // A finished or refused calibration belonged to the scan that was on screen, not the one switched to.
      setProgress((p) => (p.step === "clicking" ? p : { step: "idle" }));
    });
  }, [scene]);

  // The relay replays each scan's calibration on connect, residual included, so a reload still shows the number.
  useEffect(
    () => relay?.on("calib.set", ({ splatId, residual }) => setResiduals((r) => new Map(r).set(splatId, residual * 1000))),
    [relay],
  );

  const start = async () => {
    const splatId = scene?.splatId();
    if (!scene || !relay || !splatId) return;
    const corners: Vec3[] = [];
    setProgress({ step: "clicking", corners });
    while (corners.length < 4) {
      const point = await scene.pickScanPoint();
      if (!point) {
        scene.showCornerClicks([]);
        setProgress({ step: "idle" });
        return;
      }
      corners.push(point);
      scene.showCornerClicks(corners);
      setProgress({ step: "clicking", corners: [...corners] });
    }

    const four = corners as Corners;
    const { residual } = solveCalibration(four, marker);
    const residualMm = residual * 1000;
    if (residualMm > MAX_RESIDUAL_MM) {
      scene.showCornerClicks([]);
      setProgress({ step: "refused", residualMm });
      return;
    }
    scene.setCalibration(splatId, four);
    setResiduals((r) => new Map(r).set(splatId, residualMm));
    const saved = relay.send({ type: "calib.set", splatId, corners: four, residual });
    setProgress({ step: "done", saved });
  };

  const splatId = scene?.splatId();
  return {
    calibrated,
    residualMm: calibrated && splatId ? (residuals.get(splatId) ?? null) : null,
    progress,
    start: () => void start(),
  };
}
