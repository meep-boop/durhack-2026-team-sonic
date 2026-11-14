import assert from "node:assert/strict";
import { test } from "node:test";
import { isSplatFileName, sourceName } from "./splatSource.ts";

test("accepts the formats Scaniverse and Spark use, in any case", () => {
  for (const name of ["desk.ply", "desk.SPZ", "a.b.splat", "x.ksplat", "room.sog"]) {
    assert.ok(isSplatFileName(name), name);
  }
});

test("rejects other files", () => {
  for (const name of ["photo.jpg", "model.glb", "ply", "notes.txt"]) {
    assert.equal(isSplatFileName(name), false, name);
  }
});

test("names a URL source by its last path segment", () => {
  assert.equal(sourceName({ kind: "url", url: "https://example.test/splats/desk.spz" }), "desk.spz");
});
