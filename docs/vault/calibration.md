---
title: Calibration
tags:
  - concept
  - dashboard
aliases:
  - Calibrate
---

# Calibration

Back to [Home](README.md) · Owner: **Max** · Code: [`dashboard/src/scene/calibration.ts`](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/dashboard/src/scene/calibration.ts) (the maths, by Ahmed) and [`Calibrate.tsx`](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/dashboard/src/scene/Calibrate.tsx) (the screen)

## What it does

It tells the dashboard where the printed [marker](marker-and-frame.md) is inside a [scan](scans.md). After that,
everything the expert places is measured from the marker, the same way the phone measures, so it lands on the real
part.

## How to do it

1. Open the scan on the [dashboard](dashboard.md) and press **Calibrate**.
2. Click the marker's four corners in order: **top-left, top-right, bottom-right, bottom-left**, as the print reads
   upright. A cyan dot marks where each click landed. Esc cancels.
3. The dashboard fits the marker to your clicks and tells you how far off they are, in millimetres.
   - **5 mm or less:** accepted. A cyan outline and red / green / blue axes appear on the marker.
   - **More than 5 mm:** refused, because one click missed its corner. Try again.

The result is sent to the [relay](relay.md) as `calib.set` and saved there, one per scan. Reload the page and the
calibration comes straight back: four clicks once per scan, not once per session.

## The rule: nothing is placed before calibration

Until the scan on screen is calibrated, "Place on scan" does nothing and no guide objects are drawn (decided by Max,
2026-11-15). Without the marker there's nothing to measure from, so any position would land in the wrong place on the
phone.

## What the numbers mean

From the four clicks the dashboard works out three things:

- **Where** the marker's centre is in the scan.
- **Which way** it faces (its +X, +Y, +Z).
- **How big** the scan's units are, from the marker's known 180 mm size. That's why the scan file's own units don't
  matter.

The "off by" number is the average distance between where you clicked and where a perfect 180 mm square would put
the corners. It measures how carefully you clicked, not how well the phone will line up: that number hasn't been
measured yet, and we don't quote one until it has.
