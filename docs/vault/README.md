---
title: Remote Assist vault
tags:
  - home
aliases:
  - Home
  - Start here
---

# Remote Assist: how it all works

Plain-language notes on what we're building at DurHack 2026 (Team Sonic), how the pieces fit, and how to run them.
Written for people, not agents: if you've just woken up, or you're a judge, start here.

> [!TIP]
> **Reading it in Obsidian:** File → Open folder as vault → pick `docs/vault/`. The graph view shows how the notes
> link. On GitHub every link works too: links to code open the file on GitHub.

## The one-line version

**A remote engineer builds step-by-step 3D guidance from a scan of the room; the person on site sees each step over
the real equipment on their phone, and it keeps working when the network drops.** Our demo: swapping the SSD in
Ahmed's laptop.

## Start with these

1. [How it works](how-it-works.md): the big picture, and one repair from start to finish.
2. [Glossary](glossary.md): every word we use that you might not know (splat, marker frame, rung…).
3. [Running the demo](running-the-demo.md): the commands, the ports, and the checks before judges arrive.

## The parts

| Note | What it is | Owner |
|---|---|---|
| [Relay](relay.md) | The small server everything talks through, and its save file | Ahmed |
| [Messages](messages.md) | Every message the parts send each other, in plain words | Ahmed |
| [Dashboard](dashboard.md) | The expert's screen: the 3D scan and the guide builder | Max (3D view), Laura (guide panel) |
| [Phone app](phone-app.md) | The iPhone the person on site holds | Salman |
| [Rig](rig.md) | The camera box that checks a step was really done | Ahmed |

## The ideas underneath

| Note | Why it matters |
|---|---|
| [The marker and its frame](marker-and-frame.md) | The printed picture every position is measured from |
| [Scans](scans.md) | The 3D copy of the set, splat or mesh, and where the files live |
| [Calibration](calibration.md) | Four clicks that line the scan up with the marker |
| [Guides](guides.md) | Steps, objects, actions: what the expert builds |
| [AI labels](ai-labels.md) | Asking Claude to name the parts in the scan |

## What these notes don't hold

Things that change by the hour live in one place each, and these notes link there instead of copying them:

- **What's on `main`, test counts, what's merged:** [progress.md → Latest](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/progress.md#latest).
- **Deadlines, decisions, who's doing what:** [PROJECT.md → NOW](https://github.com/meep-boop/durhack-2026-team-sonic/blob/context/PROJECT.md) (on the `context` branch).
- **Who owns which folder:** [progress.md → Who owns what](https://github.com/meep-boop/durhack-2026-team-sonic/blob/main/progress.md#who-owns-what).
- **The original plan:** [docs/remote-assist/](../remote-assist/README.md) (Max's plan from the start of the event).
