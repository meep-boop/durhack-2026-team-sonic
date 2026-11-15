---
title: Dashboard
tags:
  - part
  - dashboard
aliases:
  - Expert screen
---

# The dashboard

Back to [Home](README.md) · Owners: **Max** (3D view, [`dashboard/src/scene/`](https://github.com/meep-boop/durhack-2026-team-sonic/tree/main/dashboard/src/scene)), **Laura** (guide panel, [`dashboard/src/guide/`](https://github.com/meep-boop/durhack-2026-team-sonic/tree/main/dashboard/src/guide))

The remote expert's screen, in a web browser. A header and a live strip across the top, the 3D [scan](scans.md) on
the left, the [guide](guides.md) builder on the right.

## Running it

```bash
cd dashboard
npm install        # first time only
npm run dev        # then open http://localhost:5173
```

It connects to the [relay](relay.md) at `ws://<this page's host>:8080`. Add `?relay=ws://<address>:<port>` to the
address to use another one, and `?closed=<file>&open=<file>` to open the demo [scans](scans.md).

**The call:** **Call the phone** opens Salman's call page (`ios/expert-call/`) in its own window, at
`http://<this page's host>:8000/?relay=<the same relay>`. Serve it first with
`cd ios/expert-call && python3 -m http.server 8000`; `?call=<url>` points the button somewhere else.

**For the team:** press **`** (backquote), or add `?debug`, to show the frame rate, the scan's size and load time.

## The header and the live strip (top)

| On screen | What it is |
|---|---|
| **Closed / Open** | which [scan](scans.md) is on screen, then its file name and kind (mesh or splat); **SAMPLE** if it isn't ours |
| Calibration chip | ✓ Calibrated, with how many mm the corner clicks missed by, or **Not calibrated**; **Recalibrate** redoes it |
| Relay · Phone · Rig | who is connected right now, from the relay's `presence` [message](messages.md). Phone also says *tracking* or *marker out of view* |
| The live strip | the one line that says what's happening and what to do next (below) |

The live strip changes colour with the session:

| Strip | When |
|---|---|
| Cyan **Set up** | the scan isn't [calibrated](calibration.md): click the marker's four corners |
| Grey **Build** | calibrated, no guide sent yet |
| Cyan **Step 2 of 4** | the person is working: the step's instruction, a dot per step (filled when done, ✓ / ✗ once the [rig](rig.md) checked it) and the rig's last check |
| Amber **Offline 0:42** | the phone dropped off the relay. It has the whole guide and carries on; its taps arrive when it's back |
| Green **Back online** | for a few seconds after it returns: how many steps were done while it was offline |
| Green **Done** | every step is done |
| Red **Relay** | the dashboard can't reach the relay; it keeps retrying |

"Step 2 of 4" is the first step without a tap: the phone doesn't report its position in the guide between taps.

## The 3D view (left)

| On screen | What it is |
|---|---|
| Cyan outline and red / green / blue axes | the printed marker, once [calibrated](calibration.md) |
| Yellow boxes | the parts the current step is about (white when selected) |
| Orange models | screws, hands, the SSD… animating the step's action |
| Small camera shape | where the person's phone is: green while it can see the marker, amber when it can't (its position may drift), gone if it stops sending |
| Bottom-left panel | [AI labels](ai-labels.md) and the part search |

**Mouse:** drag to orbit, scroll to zoom, right-drag to pan (the bottom-right corner reminds you). Click an object
to select it in the guide panel.

**Moving an object:** select it, then drag its arrows. Press **R** to turn it (only round the vertical axis, since
everything stands upright on the flat laptop) and **T** to move again. The guide updates when you let go.

## The guide panel (right)

Laura's builder. Each step has an instruction and its objects; each object has a model, an action, a position and a
box size. **Place on scan** puts an object where you click on the scan (only once it's calibrated); **Add at
marker** puts it at the marker's centre to type a position in. **Open a guide file…** loads a prepared guide.
**Send to phone** stays greyed out, with the reasons listed, until the guide is complete.

As the person works, each step gets a tick when they tap Next, and ✓ / ✗ when the [rig](rig.md) checks it.

## How the two halves talk

The guide panel holds the only copy of the guide. It tells the 3D view what to draw ("show these objects", "select
this one") and the 3D view reports back what the expert did ("they clicked this", "they moved that here"). That
agreement lives in [`dashboard/src/scene/api.ts`](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/dashboard/src/scene/api.ts),
and it's why Laura and Max can work on their halves without stepping on each other.

## Under the hood

Vite + React + TypeScript. The 3D view is plain three.js, with Spark for drawing splats. Meshes load through three's
own USD and glTF loaders.
