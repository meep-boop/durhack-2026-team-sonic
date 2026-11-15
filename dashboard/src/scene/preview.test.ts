import assert from "node:assert/strict";
import { test } from "node:test";
import { PREVIEW_LOOP_MS, previewPose } from "./preview.ts";

test("every action starts from the placed pose", () => {
  for (const action of ["pull", "push", "unscrew", "rotate90", "flip"] as const) {
    const { slide, turn } = previewPose(action, 0);
    assert.equal(Math.abs(slide) + Math.abs(turn), 0, action);
  }
});

test("a pull slides 3 cm along the axis and holds there before looping", () => {
  assert.equal(previewPose("pull", PREVIEW_LOOP_MS * 0.8).slide, 0.03);
  assert.equal(previewPose("pull", PREVIEW_LOOP_MS * 0.95).slide, 0.03);
  assert.equal(previewPose("pull", PREVIEW_LOOP_MS).slide, 0);
});

test("rotate90 and flip end a quarter and a half turn round", () => {
  assert.equal(previewPose("rotate90", PREVIEW_LOOP_MS * 0.9).turn, Math.PI / 2);
  assert.equal(previewPose("flip", PREVIEW_LOOP_MS * 0.9).turn, Math.PI);
});

test("unscrew turns anticlockwise and backs out a little", () => {
  const end = previewPose("unscrew", PREVIEW_LOOP_MS * 0.9);
  assert.ok(end.turn < 0);
  assert.ok(end.slide > 0 && end.slide < 0.01);
});
