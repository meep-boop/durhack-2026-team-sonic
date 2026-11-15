---
title: The marker and its frame
tags:
  - concept
aliases:
  - Marker
  - Marker frame
---

# The marker and its frame

Back to [Home](README.md) · Owner of the print: **Laura** · Files: [`assets/marker/`](https://github.com/meep-boop/durhack-2026-team-sonic/tree/main/assets/marker)

## Why we need it

The phone and the dashboard each have their own idea of where things are. The phone measures from wherever it
started; the [scan](scans.md) measures from wherever Scaniverse put its middle. Neither can tell the other "the screw
is at (12, 3, 40)" and be understood.

So we agreed a shared starting point both can see: a **printed picture**, taped flat beside the laptop. Every position
in a [guide](guides.md) is measured from it.

- **The phone** finds the picture through its camera (ARKit image tracking).
- **The dashboard** finds it in the scan when the expert clicks its four corners ([calibration](calibration.md)).

## The picture

A busy black-and-white collage, **180 mm × 180 mm** when printed at 100% (measured with a ruler). Busy and
non-repeating on purpose: phones track that kind of image far better than a plain logo. If it's reprinted at another
size, everything lands off by the same ratio, so measure again and update the size.

On our table it's taped flat beside the laptop's fan side, with "TOP" away from the expert, and it must stay put:
the scan and the demo both depend on it not moving.

## The marker frame

"Marker frame" just means "measured from the marker", in metres:

| | Where |
|---|---|
| **Origin** (0, 0, 0) | the centre of the printed picture |
| **+X** (red) | along the picture's top edge, to the right as you read it |
| **+Z** (blue) | down the picture, from its top edge towards its bottom edge |
| **+Y** (green) | straight up out of the paper |

So `[0.10, 0.02, -0.05]` means 10 cm to the right, 2 cm above the paper, 5 cm towards the picture's top edge.

> [!WARNING]
> Which printed edge +X and +Z really follow is **provisional** until Salman confirms it on the phone (the phone
> draws red, green and blue axes on the marker). The dashboard assumes the table above.
