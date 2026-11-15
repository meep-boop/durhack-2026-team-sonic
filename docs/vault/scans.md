---
title: Scans
tags:
  - concept
  - dashboard
aliases:
  - Splat
  - Mesh
  - Scaniverse
---

# Scans

Back to [Home](README.md) · Owner: **Max** · Files: [`dashboard/public/scans/`](https://github.com/meep-boop/durhack-2026-team-sonic/tree/main/dashboard/public/scans)

## What a scan is

A 3D copy of the real set (the laptop on our table, with the [marker](marker-and-frame.md) beside it), made by walking
round it with a phone running **Scaniverse**. The expert orbits it on the [dashboard](dashboard.md) and places the
guide's objects on it.

Scaniverse can make two kinds, and the dashboard opens both:

| Kind | What it looks like | Files | Good at | Weak at |
|---|---|---|---|---|
| **Splat** (Gaussian splat) | a cloud of soft coloured blobs; photo-real | `.spz`, `.ply` | looking real | a click can land on a faint blob, so picks are a little fuzzy |
| **Mesh** | a solid surface with a photo wrapped on it | `.usdz`, `.glb` | exact clicks: you hit the real surface | looks flatter |

We keep whichever scan of the set comes out better. The pitch has to name the kind honestly: a mesh is not a
"Gaussian splat".

## Where they live

In git, in `dashboard/public/scans/`, so every teammate's dashboard opens the same files. That folder's README lists
each scan, what state the laptop was in, and whether it's usable.

Open them with the page address:

```
http://localhost:5173/?closed=<file>&open=<file>     two scans, with a Closed / Open switch
http://localhost:5173/?splat=<file>                  one scan
```

You can also drop a scan file onto the 3D view to look at it.

> [!CAUTION]
> **Never overwrite a scan file. Give a rescan a new name.** A scan's file name is how its
> [calibration](calibration.md) is saved, so a new scan under an old name would reuse the old scan's corners and put
> every object in the wrong place.

## Making a usable scan

- The **marker must be fully in view**, all four corners clear: without it the scan can't be calibrated.
- Two scans of the demo: laptop **closed**, and with the **cover off**. Both at our table, with the laptop in its tape
  corners.
- Scaniverse doesn't say what units it exports in, so the dashboard never trusts the file's size: it takes the scale
  from the marker's printed size during calibration.
