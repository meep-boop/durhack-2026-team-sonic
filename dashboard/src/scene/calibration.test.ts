import assert from "node:assert/strict";
import { test } from "node:test";
import type { Vec3 } from "../../../contracts/protocol.ts";
import { markerToScan, solveCalibration } from "./calibration.ts";

const marker = { width: 0.18, height: 0.18 };
const square: [Vec3, Vec3, Vec3, Vec3] = [[-0.09, 0, -0.09], [0.09, 0, -0.09], [0.09, 0, 0.09], [-0.09, 0, 0.09]];
const close = (actual: readonly number[], expected: readonly number[], tolerance = 1e-9) =>
  actual.forEach((value, i) => assert.ok(Math.abs(value - expected[i]!) < tolerance, `${actual} is not ${expected}`));

// The scan's own frame: twice as big, turned 90° about Y, lifted and shifted.
const toScan = ([x, y, z]: Vec3): Vec3 => [2 * z + 5, 2 * y + 1, -2 * x - 3];

test("a scan already in the marker's frame gives the identity", () => {
  const calibration = solveCalibration(square, marker);
  close(calibration.matrix, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
  close([calibration.scale, calibration.residual], [1, 0]);
});

test("a scaled, turned and shifted scan is recovered, with +Y out of the marker's face", () => {
  const calibration = solveCalibration(square.map(toScan) as typeof square, marker);
  close([calibration.scale, calibration.residual], [2, 0]);
  for (const point of [[0, 0, 0], [0.28, 0.01, 0.03], [0, 0.05, 0]] as Vec3[]) {
    close(markerToScan(calibration, point), toScan(point));
  }
});

test("a click that misses its corner shows up in the residual, in metres", () => {
  const clicks = square.map(toScan) as typeof square;
  // 3 cm off in the marker's plane, which is 6 cm in this scan's units.
  clicks[2] = [clicks[2][0] + 0.06, clicks[2][1], clicks[2][2]];
  const { residual } = solveCalibration(clicks, marker);
  assert.ok(residual > 0.005 && residual < 0.03, `residual ${residual}`);
});

test("corners that don't span a square are refused", () => {
  const point: Vec3 = [1, 1, 1];
  assert.throws(() => solveCalibration([point, point, point, point], marker), /on top of each other/);
  assert.throws(() => solveCalibration([[0, 0, 0], [1, 0, 0], [3, 0, 0], [2, 0, 0]], marker), /in a line/);
});
