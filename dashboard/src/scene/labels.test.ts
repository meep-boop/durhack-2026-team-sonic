import assert from "node:assert/strict";
import { test } from "node:test";
import { findLabels, placeLabels } from "./labels.ts";

const label = (id: string, text: string) => ({ id, text, point: [0, 0, 0] as [number, number, number] });

test("placeLabels keeps labels over the scan and drops ones over empty space", () => {
  let n = 0;
  const placed = placeLabels(
    [
      { text: "SSD", x: 10, y: 20 },
      { text: "Sky", x: 900, y: 5 },
    ],
    (x, y) => (x < 500 ? [x, y, 0] : null),
    () => `l${++n}`,
  );
  assert.deepEqual(placed, [{ id: "l1", text: "SSD", point: [10, 20, 0] }]);
});

test("findLabels matches any part of the name, ignoring case and spaces round the query", () => {
  const labels = [label("a", "Fan"), label("b", "M.2 SSD slot"), label("c", "SSD")];
  assert.deepEqual(findLabels(labels, "  ssd ").map((l) => l.id), ["c", "b"]);
});

test("findLabels ranks exact, then starts-with, then contains", () => {
  const labels = [label("a", "Fan cable"), label("b", "Case fan"), label("c", "fan")];
  assert.deepEqual(findLabels(labels, "fan").map((l) => l.id), ["c", "a", "b"]);
});

test("an empty query finds nothing", () => {
  assert.deepEqual(findLabels([label("a", "Fan")], "   "), []);
});
