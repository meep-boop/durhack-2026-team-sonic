---
title: Relay
tags:
  - part
  - relay
aliases:
  - Server
  - state.json
---

# The relay

Back to [Home](README.md) · Owner: **Ahmed** · Code: [`relay/`](https://github.com/meep-boop/durhack-2026-team-sonic/tree/main/relay)

## What it is

A small Node server on one laptop (Max's, in the demo). The [phone](phone-app.md), the [dashboard](dashboard.md) and
the [rig](rig.md) each open a connection to it, and it passes [messages](messages.md) between them. Think of it as a
post office: it knows who's connected, and which kind of device each message is for.

It runs on the team hotspot. No cloud.

## Starting it

```bash
cd relay
npm install          # first time only
npm start            # prints the ws:// addresses to give the phone and the rig
```

| Option | What it does |
|---|---|
| `npm start -- --fresh` | Starts with an empty save file. **Wipes** the saved guide and calibrations. |
| `npm start -- --labels` | Turns on [AI labels](ai-labels.md). Needs `ANTHROPIC_API_KEY` set on this laptop; each label request is billed. |
| `PORT=8090 npm start` | Another port. The default is 8080. |

## Who gets what

When a message arrives, the relay checks who's allowed to send it and passes it on to the right kinds of device:

| Message | Sent by | Passed to |
|---|---|---|
| `guide.set`, `step.set` | dashboard | everyone |
| `calib.set` | dashboard | other dashboards only (never the phone) |
| `step.done` (a tap on Next) | phone | dashboards and the rig, plus back to the phone as its receipt |
| `pose` (where the phone is) | phone | dashboards |
| `step.verified` (✓ / ✗) | rig | dashboards and the phone |
| `rtc.signal` (setting up the video call) | phone or dashboard | the other one |
| `labels.request` | dashboard | nobody: the relay answers it itself, through Claude |

It also tells everyone who's online (`presence`), so the dashboard can show "phone offline". [Messages](messages.md)
explains each one.

## The save file: `relay/state.json`

The relay's **notebook**. Every time something important changes, the relay writes down the latest version of:

- the current guide,
- the step the expert jumped to,
- each [scan's calibration](calibration.md) (one per scan, by file name),
- every `step.done` tap it has accepted,
- every `step.verified` the rig sent.

Why: if the relay restarts, or a dashboard reloads, nothing is lost. When a device connects, the relay reads its
notebook back to it:

| Connecting device | Gets replayed |
|---|---|
| Dashboard | every calibration, the guide, the current step, all taps, all rig checks |
| Phone | the guide and the rig's checks. **Never the current step:** the phone owns its own place, because it may have moved on while offline, and its queued taps arrive just after |
| Rig | the guide, the current step, the taps |

> [!WARNING]
> **One relay per save file.** The file sits at `relay/state.json` beside the code, so two relays started from the
> same folder share it, and a test relay started with `--fresh` blanks the real one's file. (That happened once on
> 2026-11-15; the live relay kept everything in memory and rewrote the file on its next change.) Run test relays
> from a copy of the folder, or ask Ahmed about a flag for the file's location.

Other things worth knowing:

- It's per machine and **not on GitHub** (git-ignored).
- It's written to a temporary file first and then swapped in, so a crash mid-write leaves the previous version, not
  half a file.
- If it can't be read, the relay refuses to start and says so. `--fresh` starts over.

## Offline and receipts

A phone that loses the network keeps a queue of its taps. When a tap reaches the relay, the relay saves it and sends
it straight back to that phone: that echo is the **receipt**, and only then does the phone drop it from its queue.
If the phone resends a tap it already sent (because the receipt got lost), the relay recognises its `doneId`, sends
another receipt, and doesn't pass it on twice.

## Limits and safety

- A message over 1 MB is refused (a guide is a few KB).
- A device that stops answering for a few seconds is dropped, so "online" means online.
- Anyone on the hotspot who knows the address can connect: there is no login. Fine for a hackathon demo, not for a
  real product.

## Testing without the real devices

`fixtures/` has stand-ins that only need Node:

```bash
node fixtures/fake-phone.ts ws://localhost:8080    # SIMULATED phone: walks round the marker, taps Next
node fixtures/fake-expert.ts ws://localhost:8080   # sends the sample guide like a dashboard would
```

They're test tools, never demo content.
