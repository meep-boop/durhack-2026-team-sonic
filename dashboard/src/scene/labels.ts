import type { Label, Vec3 } from "../../../contracts/protocol.ts";
import type { SceneLabel } from "./scene.ts";

// Claude reads labels at pixels of the snapshot; each becomes a point on the scan under that pixel. A pixel over
// empty space has no point and is dropped, since a label floating off the scan can't be focused or trusted.
export function placeLabels(labels: readonly Label[], pointAt: (x: number, y: number) => Vec3 | null, newId: () => string): SceneLabel[] {
  return labels.flatMap((label) => {
    const point = pointAt(label.x, label.y);
    return point ? [{ id: newId(), text: label.text, point }] : [];
  });
}

// Typing "ssd" finds "SSD" and "M.2 SSD slot"; best first: exact name, then names that start with it, then the rest.
export function findLabels(labels: readonly SceneLabel[], query: string): SceneLabel[] {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  const rank = (text: string) => (text === q ? 0 : text.startsWith(q) ? 1 : 2);
  return labels
    .filter((label) => label.text.toLowerCase().includes(q))
    .sort((a, b) => rank(a.text.toLowerCase()) - rank(b.text.toLowerCase()));
}
