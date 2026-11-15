import assert from "node:assert/strict";
import { test } from "node:test";
import { createFrameMeter } from "./frameMeter.ts";

test("reports zero before two frames", () => {
  const meter = createFrameMeter();
  assert.equal(meter.fps(), 0);
  meter.tick(0);
  assert.equal(meter.fps(), 0);
});

test("averages steady frames", () => {
  const meter = createFrameMeter();
  for (let i = 0; i <= 10; i++) meter.tick(i * 20);
  assert.equal(meter.fps(), 50);
});

test("forgets frames older than the window", () => {
  const meter = createFrameMeter(4);
  for (let i = 0; i <= 10; i++) meter.tick(i * 100);
  for (let t = 1000 + 25; t <= 1100; t += 25) meter.tick(t);
  assert.equal(meter.fps(), 40);
});
