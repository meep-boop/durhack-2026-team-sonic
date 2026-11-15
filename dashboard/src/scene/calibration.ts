// Turns the expert's four clicks on the printed marker, in the scan, into the transform from the marker's frame
// (metres; origin at the marker's centre, +X along its top edge, +Z down the print, +Y out of its face:
// contracts/protocol.ts) to scan coordinates. Put it on one three.js group and everything drawn under that group is
// in marker metres, the same numbers the phone uses. No three.js here, so it runs in plain Node tests.
import type { Marker, Vec3 } from "../../../contracts/protocol.ts";

export type Calibration = {
  // Marker frame → scan coordinates, column-major: `new THREE.Matrix4().fromArray(matrix)`.
  matrix: number[];
  // Scan units per metre. Scaniverse doesn't document its units, so this comes from the marker's printed size.
  scale: number;
  // Root-mean-square distance, in metres, between each click and where the fitted marker puts that corner. A few
  // millimetres is a good set of clicks; centimetres means one landed off the marker.
  residual: number;
};

const sub = (a: Vec3, b: Vec3): Vec3 => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const add = (a: Vec3, b: Vec3): Vec3 => [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
const times = (a: Vec3, k: number): Vec3 => [a[0] * k, a[1] * k, a[2] * k];
const dot = (a: Vec3, b: Vec3) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a: Vec3, b: Vec3): Vec3 => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const length = (a: Vec3) => Math.hypot(...a);

// Corners in the contract's order: top-left, top-right, bottom-right, bottom-left, as the marker reads upright.
export function solveCalibration(corners: readonly [Vec3, Vec3, Vec3, Vec3], marker: Pick<Marker, "width" | "height">): Calibration {
  const [topLeft, topRight, bottomRight, bottomLeft] = corners;
  const centre = times(corners.reduce(add), 1 / 4);
  // Each axis is the average of the two edges that run along it, which halves the effect of one shaky click.
  const across = times(add(sub(topRight, topLeft), sub(bottomRight, bottomLeft)), 1 / 2);
  const down = times(add(sub(bottomLeft, topLeft), sub(bottomRight, topRight)), 1 / 2);
  const scale = (length(across) / marker.width + length(down) / marker.height) / 2;
  if (!(scale > 0)) throw new Error("the four corners are on top of each other");

  const x = times(across, 1 / length(across));
  // Clicked edges are never exactly square, so +Z is `down` with its lean along +X taken out.
  const squared = sub(down, times(x, dot(down, x)));
  if (length(squared) < 1e-9) throw new Error("the corners are in a line, not a square");
  const z = times(squared, 1 / length(squared));
  const y = cross(z, x);

  const place = (p: Vec3): Vec3 => add(centre, times(add(add(times(x, p[0]), times(y, p[1])), times(z, p[2])), scale));
  const w = marker.width / 2;
  const h = marker.height / 2;
  const fitted: Vec3[] = [[-w, 0, -h], [w, 0, -h], [w, 0, h], [-w, 0, h]].map((p) => place(p as Vec3));
  const squaredError = fitted.reduce((sum, p, i) => sum + length(sub(p, corners[i]!)) ** 2, 0);

  return {
    matrix: [...times(x, scale), 0, ...times(y, scale), 0, ...times(z, scale), 0, ...centre, 1],
    scale,
    residual: Math.sqrt(squaredError / 4) / scale,
  };
}

// A point in marker metres → scan coordinates, e.g. to check a calibration without three.js.
export function markerToScan({ matrix: m }: Calibration, [px, py, pz]: Vec3): Vec3 {
  return [0, 1, 2].map((row) => m[row]! * px + m[4 + row]! * py + m[8 + row]! * pz + m[12 + row]!) as Vec3;
}
