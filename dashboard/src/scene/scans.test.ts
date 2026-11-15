import assert from "node:assert/strict";
import { test } from "node:test";
import { SAMPLE_SPLAT, scansFromQuery } from "./scans.ts";

test("closed and open give the two-scan switch, from public/scans/", () => {
  assert.deepEqual(scansFromQuery("?closed=laptop-closed.spz&open=laptop-open.spz"), [
    { label: "Closed", source: { kind: "url", url: "/scans/laptop-closed.spz" } },
    { label: "Open", source: { kind: "url", url: "/scans/laptop-open.spz" } },
  ]);
});

test("a value with a slash is used as given", () => {
  assert.deepEqual(scansFromQuery("?splat=https://example.test/a.spz"), [
    { label: "Scan", source: { kind: "url", url: "https://example.test/a.spz" } },
  ]);
});

test("one scan alone works", () => {
  assert.deepEqual(scansFromQuery("?open=b.ply").map((s) => s.label), ["Open"]);
});

test("no scan named falls back to the labelled sample", () => {
  assert.deepEqual(scansFromQuery(""), [{ label: "SAMPLE", source: { kind: "url", url: SAMPLE_SPLAT } }]);
});
