---
title: Glossary
tags:
  - reference
aliases:
  - Words
---

# Glossary

Back to [Home](README.md)

| Word | Meaning |
|---|---|
| **ARKit** | Apple's framework that lets the iPhone understand the space around it and find the printed marker. |
| **Axis** (of an object) | The direction its action goes: which way to pull, or what to turn round. See [Guides](guides.md). |
| **Calibration** | The four clicks that tell the dashboard where the marker is in a scan. See [Calibration](calibration.md). |
| **Contract** | `contracts/protocol.ts`: the agreed shape of every message. See [Messages](messages.md). |
| **Context branch** | A git branch holding only the team's planning docs (PROJECT.md, the briefs). Never merged into `main`. |
| **Expert** | The remote engineer at the dashboard. |
| **Feature freeze** | After it, only fixes, and no message changes. Time: PROJECT.md → Clock. |
| **Fixtures** | Stand-in tools and sample data for testing (`fixtures/`), e.g. a fake phone. Never demo content. |
| **Guide** | The list of steps the expert builds. See [Guides](guides.md). |
| **Marker** | The 180 mm printed picture beside the laptop. See [The marker and its frame](marker-and-frame.md). |
| **Marker frame** | Positions measured from the marker's centre, in metres. Everything in a guide uses it. |
| **Mesh** | A scan made of a solid surface with a photo on it. See [Scans](scans.md). |
| **MOCK / SAMPLE / SIMULATED** | Labels we put on anything not real, wherever it shows. |
| **Nicla Vision** | The tiny camera board on the rig. See [Rig](rig.md). |
| **Pose** | Where the phone is and which way it faces. |
| **Receipt** | The relay sending a tap back to the phone once it's saved, so the phone can stop holding it. |
| **Relay** | The small server everything connects through. See [Relay](relay.md). |
| **Rev** | A guide's version number; every edit adds one. |
| **Rung** | A stage of the plan: 0, the phone plays a prepared guide; 1, the dashboard sends it; 2, a guide built on the scan lines up on the phone; 3, the extras. |
| **Scaniverse** | The free phone app we scan the set with. |
| **Splat** (Gaussian splat) | A scan made of soft coloured blobs; looks photo-real. See [Scans](scans.md). |
| **`state.json`** | The relay's save file. See [Relay](relay.md). |
| **UNO Q** | The Arduino board on the rig that talks to the relay. See [Rig](rig.md). |
| **User** | The person on site, holding the phone. |
| **WebRTC** | The standard behind the live video call between phone and dashboard. |
