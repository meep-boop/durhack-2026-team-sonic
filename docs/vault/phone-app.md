---
title: Phone app
tags:
  - part
  - phone
aliases:
  - iPhone app
  - iOS
---

# The phone app

Back to [Home](README.md) · Owner: **Salman** · Code: `ios/`, on Salman's branches

> [!NOTE]
> The app isn't on `main` yet: it lives on `salman-ios-polish` and `salman-ios-ar`. Its full README, with build steps,
> is on [`salman-ios-ar`](https://github.com/meep-boop/durhack-2026-team-sonic/blob/salman-ios-ar/ios/README.md).
> Check [progress.md → Latest](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/progress.md#latest)
> for where it stands.

## What it does

The person on site holds an iPhone over the equipment.

1. **Finds the printed [marker](marker-and-frame.md)** through the camera and pins the [guide](guides.md) to it. A
   green outline hugs the print; red, green and blue arrows show the marker's axes.
2. **Draws the current step** over the real equipment: the yellow box round the part and the model doing the action.
   Covering the marker with your hand doesn't move anything; it re-locks when the marker is back in view.
3. **Next** moves on and sends a `step.done` to the [relay](relay.md).
4. **Sends its own position** (`pose`) about ten times a second, so the expert sees where the person is standing in
   the [dashboard](dashboard.md)'s 3D view.
5. **Shows the [rig](rig.md)'s ✓ / ✗** for each step.

## Offline

Turn the Wi-Fi off and it carries on. Taps are queued, survive the app being killed, and go out in order when the
network is back. On `salman-ios-ar`, each one is held until the relay sends it back as a receipt, so none is lost
or counted twice. The person never loses their place.

## The live call

The expert calls the phone from a small web page (`ios/expert-call/`) next to the dashboard. Video and voice go
straight between the two over the hotspot; the relay only introduces them.

## Built with

Native Swift: SwiftUI, ARKit (marker tracking) and RealityKit (drawing), with Google's WebRTC for the call. Salman's
branch also has extras, labelled as AI where they are. His README lists them.
