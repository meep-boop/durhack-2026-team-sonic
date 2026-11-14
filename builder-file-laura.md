# Laura: the guide builder, the 3D models, the demo set, and the pitch
**GitHub:** `furtunalaura` · **Branch:** `laura-guide` · **Brief last updated:** 2026-11-14 by ahmed
**Spec:** `PROJECT.md` (NOW first); the § numbers below refer to it. **Deadlines:** `PROJECT.md` → NOW → Clock.
**The plan in full:** `docs/remote-assist/README.md` and `architecture.md` (on `main`, written by @max).

## 0. How the agent reads this brief (every task)
1. Read the project `CLAUDE.md` in full, then this brief. Follow both.
2. **Only action `▶ Current tasks`**, top to bottom.
3. The every-prompt hook syncs the docs and shows new `progress.md` entries. Handle any open
   `⚠️ Conflicts: @laura` first.
4. **Each finished feature** goes through the `ship` skill. **Each finished task**, feature or not, gets a
   `progress.md` entry and a ✅ here in the same turn. In this brief you may publish status only (✅/🟡, the Done
   log, Waiting on, a START HERE note); new tasks come from a docs owner.
5. `debug` on every issue. Anything 🟠 is the user's decision (CLAUDE.md §1).

**Conflict tags:** `[⚠ conflicts with @name: what]` marks a task that touches someone else's area or a shared contract.
Agree with them before merging.

**START HERE (2026-11-14, from @ahmed):** the split and the decisions in `PROJECT.md` → NOW were made by Ahmed on
top of Max's round-1 plan. If you disagree with your role or with a decision, say so in a `progress.md` entry
(`📨 To @ahmed`) before building on it. All four of us build at once, each against the fake peers in `fixtures/`,
so nobody waits for anybody. Until `contracts/protocol.ts` lands, use the draft in
`docs/remote-assist/architecture.md` and expect small changes.

---

## 1. Ownership
**Owns:**
- `dashboard/src/guide/`: the step timeline the expert builds the guide in, and the live video panel.
- `assets/`: the printed marker and the built-in 3D models, in both formats.
- The physical demo set. (The UNO Q rig on it is @ahmed's, in `hardware/`.)
- What judges see: the README, the video, the submission (`pitch` skill).

**Does NOT touch:**

| Area | Owner |
|---|---|
| `ios/` | @salman |
| `relay/`, `contracts/`, `fixtures/`, `hardware/` | @ahmed |
| `dashboard/src/scene/`, the dashboard shell, the splat files | @max |

**Shared** (flag every edit in `progress.md` → `⚠️ Conflicts`): `contracts/protocol.ts` (ask @ahmed for changes),
`fixtures/*`, `dashboard/src/scene/api.ts` (the seam with @max), and `assets/models/` (@salman and @max both load
them, so a renamed or resized model breaks two apps).

## 2. Contract and guardrails
**Scope contract.** laura is building:
- The panel where the expert builds a guide: add, reorder and remove steps, write the instruction, pick a model and
  one preset action per object, send it, and watch the user's progress.
- The set of built-in models (screw, bolt, arrow, screwdriver, hand, cable plug) that both apps load.
- The demo set itself: a small "comms cupboard" with the marker fixed next to the ports.
- Everything the judges read and watch.

**Out of scope:** the 3D view itself (call @max's scene API). The phone app. The relay. The UNO Q rig (@ahmed took it on
2026-11-14; leave him room on the set to mount it).

**Guardrails:**
- **The guide must never depend on video, the AI labels or the hardware.**
- If the list is too much, say so early on the board.
- Every new package or downloaded model is a 🟠 decision for you. Record each model's licence and source.
- The marker goes **right next to the ports**: alignment gets worse with distance from it (`research/ledger.md`
  § 3 and § 5).
- Everything simulated or mocked is labelled in the UI, the README and the video. No number nobody measured.

---

## 3. ▶ Current tasks (2026-11-14), in order
*Status: ⬜ not started · 🟡 in progress · ⏸ blocked · ✅ done*

1. ⬜ **The marker** (do this first: @salman and @max are both waiting on it)
   - A high-contrast, detailed, non-repeating image, 15 to 20 cm wide (small ones track badly), printed flat and
     matte. Measure the printed width with a ruler and commit the image to `assets/marker/` with that width in mm
     beside it: ARKit needs the exact size. Print spares.
   - *Done when:* the file and its width are on `main`, and @salman confirms Xcode accepts it with no warnings.
2. ⬜ **Pick and get the demo objects** 🟠 (asked for by @max)
   - What the set is made of (a real switch or router, a patch panel, a cover with screws), who brings or borrows
     it, and whether it can be carried to any table and scanned once.
   - *Done when:* the set is built with the marker fixed on it, and @max has been told it's ready to scan.
   - `[⚠ conflicts with @ahmed: his UNO Q rig mounts on the set; agree where before it's scanned]`
3. ⬜ **The guide builder**
   - Build against the fake phone in `fixtures/` and @max's scene API. Step list, instruction text, model and
     action pickers, send the guide, jump to a step, tick steps as `step.done` arrives.
   - *Done when:* a three-step guide built in the UI appears in the fake phone's log, and its `step.done` ticks the
     step.
   - `[⚠ conflicts with @max: dashboard/src/scene/api.ts]` `[⚠ conflicts with @ahmed: the guide shape in contracts/protocol.ts]`
4. ⬜ **The built-in models** 🟠
   - Screw, bolt, arrow, screwdriver, hand, cable plug, as glTF for the dashboard and USDZ for the phone. Decide
     first: author once and convert, or keep both by hand. Same names, sizes and origins in both.
   - *Done when:* each model loads in the dashboard and in @salman's app, the same size and the same way up.
   - `[⚠ conflicts with @salman and @max: both load these]`
5. ⬜ **The live video panel**
   - Show the phone's camera in the dashboard.
   - *Done when:* the stream from the phone (or a fake sender) plays in the panel, and the guide builder still
     works with it switched off.
   - `[⚠ conflicts with @ahmed and @salman: WebRTC signalling]`
6. ⬜ **What the judges see**
   - README, demo video, submission form (`pitch` skill). Start once a guide plays end to end.
   - *Done when:* `bash scripts/submission-check.sh` passes and the submission is in.

## 4. Done log (newest first)
- _(empty)_

## 5. Waiting on / owed to others
- 📥 **Waiting on @max:** `dashboard/src/scene/api.ts` and the dashboard shell.
- 📥 **Waiting on @ahmed:** `contracts/protocol.ts`, the fake phone, the event's rules and deadlines.
- 📤 **Owed to @salman and @max:** the marker image and printed width (task 1), then the models.
- 📤 **Owed to @max:** the finished demo set, to scan.
- 📤 **Owed to @ahmed:** a spot on the set for his UNO Q rig, agreed before the scan.

## 6. Working-style notes for the agent
- Verbosity: project level (Level 0) unless Laura changes it.

## 7. Reference (no secrets, ever)
- The demo and the challenge fit: `docs/remote-assist/README.md`. Marker evidence: `research/ledger.md` § 3 and § 5.

---
── Archived (superseded 2026-11-14 — do NOT action) ──
- **Ask about the UNO Q today** and **The hardware check** (the RS feature). Moved to @ahmed on 2026-11-14: he said he'd do the
  rig himself. Now tasks 3 and 9 in his brief. Would come back only if he hands it back.
