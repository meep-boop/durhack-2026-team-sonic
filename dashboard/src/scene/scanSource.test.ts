import assert from "node:assert/strict";
import { test } from "node:test";
import { scanKind, sourceName } from "./scanSource.ts";

test("splat formats from Scaniverse and Spark, in any case", () => {
  for (const name of ["desk.ply", "desk.SPZ", "a.b.splat", "x.ksplat", "room.sog"]) {
    assert.equal(scanKind(name), "splat", name);
  }
});

test("mesh formats: Scaniverse's USDZ and glTF", () => {
  for (const name of ["Scaniverse 2026-11-15 021710.usdz", "set.USDZ", "set.glb", "set.gltf"]) {
    assert.equal(scanKind(name), "mesh", name);
  }
});

test("rejects other files", () => {
  for (const name of ["photo.jpg", "ply", "notes.txt"]) {
    assert.equal(scanKind(name), null, name);
  }
});

test("names a URL source by its last path segment", () => {
  assert.equal(sourceName({ kind: "url", url: "https://example.test/splats/desk.spz" }), "desk.spz");
});
