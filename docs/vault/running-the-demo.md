---
title: Running the demo
tags:
  - runbook
aliases:
  - Runbook
  - Demo checklist
---

# Running the demo

Back to [Home](README.md) · Times and deadlines: PROJECT.md → NOW → Clock (on the `context` branch)

Everything runs on the team hotspot. The relay and the dashboard run on Max's laptop; Ahmed's laptop is the thing
being repaired, so it's opened up and can't host anything.

## 1. Before anything: is port 8080 free?

The phone and the rig expect the relay on port 8080. On Max's laptop, in PowerShell:

```powershell
Get-NetTCPConnection -LocalPort 8080 -State Listen
```

Nothing printed means it's free. If something holds it, find out what before stopping it: it may be a relay
someone already started.

## 2. Start the relay

```bash
cd relay
npm start                 # add -- --labels for AI labels (needs ANTHROPIC_API_KEY on this laptop)
```

Note the `ws://10.…:8080` address it prints: the phone and the rig need it. Don't use `--fresh` unless you mean to
wipe the saved guide and calibrations ([Relay](relay.md)).

## 3. Start the dashboard

```bash
cd dashboard
npm run dev
```

Open `http://localhost:5173/?closed=<closed scan>&open=<open scan>` (file names from
`dashboard/public/scans/README.md`). Check the top-left panel: the scan loads, and it says **Calibrated** (the
relay remembers calibrations; if not, [calibrate](calibration.md) again).

## 4. Connect the phone

On Salman's call page, type the relay's `ws://` address and press Connect: it shows a QR code. On the phone, tap
the status capsule, then **Scan QR**. On the dashboard, the phone's camera shape should appear in the 3D view, green
when it sees the marker. See [Phone app](phone-app.md) and Salman's README.

## 5. Connect the rig

Set `RELAY_URL` in the UNO Q's `main.py` to the relay's address and press Run in App Lab. See [Rig](rig.md).

## 6. Start the call

On the same call page, press **Call the phone**, then **Accept** on the phone ([Phone app](phone-app.md) → The live
call). The page is served with `cd ios/expert-call && python3 -m http.server 8000`, at `http://localhost:8000`.

## The set

- Marker taped flat beside the laptop's fan side, "TOP" away from the expert. **Don't move it, or the table.**
- Laptop in its tape corners.
- Steady light for the rig.

## Before judges arrive

- [ ] Relay running on 8080; phone, dashboard and rig all show as connected.
- [ ] Scan calibrated and the phone's camera shape is green.
- [ ] Send a guide and tap through one step on the phone: the dashboard ticks it.
- [ ] Wi-Fi off on the phone, tap a step, Wi-Fi on: it arrives once.
- [ ] Anything SAMPLE, MOCK or SIMULATED is labelled on screen, or not shown.
