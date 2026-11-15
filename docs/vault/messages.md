---
title: Messages
tags:
  - contract
aliases:
  - Protocol
  - Contract
---

# Messages

Back to [Home](README.md) · Owner: **Ahmed** · The exact shapes: [`contracts/protocol.ts`](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/contracts/protocol.ts) (the one source of truth; the phone mirrors it in Swift)

Every part talks to the [relay](relay.md) in small JSON messages. Each has a `type`. Positions are always in metres,
measured from the printed marker ([the marker frame](marker-and-frame.md)).

| Message | Who sends it | What it says |
|---|---|---|
| `hello` | everyone, first thing | "I'm a dashboard / phone / rig, called …". The relay refuses a different protocol version. |
| `guide.set` | dashboard | The whole [guide](guides.md), every time it changes. A full copy, never a patch, so a phone can't end up with half an edit. |
| `step.set` | dashboard | "Jump to this step." |
| `calib.set` | dashboard | Where the marker's four corners are in one [scan](scans.md). Kept by the relay for the dashboards; never sent to the phone. [Calibration](calibration.md). |
| `step.done` | phone | "The person tapped Next on this step", with the time they tapped and a unique `doneId`. Echoed back to the phone as its receipt. |
| `pose` | phone | Where the phone's camera is, about ten times a second, and whether it can currently see the marker. Draws the phone in the [dashboard](dashboard.md)'s 3D view. |
| `step.verified` | rig | ✓ or ✗: did the stickered part end up where the step expects? [Rig](rig.md). |
| `rtc.signal` | phone, dashboard | Setting up the live video call. The relay passes it on without reading it. |
| `labels.request` | dashboard | A picture of the 3D view, for Claude to name the parts in. [AI labels](ai-labels.md). |
| `labels.result` | relay | Claude's answer: names at pixel positions in that picture. |
| `presence` | relay | Who's connected right now. |
| `error` | relay | "I refused your message, because …". |

> [!NOTE]
> **Changing a message is a team decision.** The phone (Swift), the dashboard and the relay (TypeScript) and the rig
> (Python) all read these shapes. After the feature freeze no shape changes at all (PROJECT.md → NOW → Clock).

The full example of every message: [`fixtures/messages.json`](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/fixtures/messages.json).
