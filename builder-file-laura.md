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

**START HERE (2026-11-14 23:40, from @ahmed's task sweep):** the demo is now an SSD swap on Ahmed's laptop (the whole
team, 23:03). The contract, relay, fakes and sample guide are on `main`; the deadlines are in `PROJECT.md` → Clock,
and the walking skeleton is the next one. Anything new for you is in the block at the top of your tasks.

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

**▶ The plan to the deadline (from @ahmed, 2026-11-15 01:45). Do these first, in this order; the older tasks below keep
their detail.** Why: the phone side is nearly there, but the dashboard is still a viewer with no relay connection,
so we climb a ladder: rung 0 the real phone plays a prepared guide; rung 1 the dashboard connects and sends it;
rung 2 a guide built in the scan lines up on the phone; rung 3 the extras. Decisions: `PROJECT.md` → Decision log.
1. ⬜ P0 **The board** (task 2), first: it blocks both scans and the rig. Add **corner stops** so the laptop lifts
   off and goes back in the same place: it's Ahmed's only machine, so it can't stay fixed down.
2. ✅ P0 **The real SSD-swap steps for Ahmed's laptop** (posted on the board 02:11, checked on the laptop): text, model and action per step, power-off first. Post
   them on the board; Ahmed turns them into `fixtures/ssd-swap-guide.json` with ruler-measured positions (rung 0).
3. ✅ P0 **`GuidePanel.tsx`** (on main `a61405f` at 02:22; tried end to end with the relay and fake phone) (task 3) on your `guide.ts` and `progress.ts`: step list, instruction, add object
   (model, action, "place" → `pickPoint()`, typed position as the fallback), Send with `sendBlockers`, ticks from
   `step.done` and `step.verified`. Max's shell hands you `scene` and `relay` as props (your ask 1).
4. ⬜ P0 **What the judges see** (task 6): README, video, Devpost, AI tools credited. Times: `PROJECT.md` → Clock.
- Task 5 (the live video panel) is superseded: see the note on it below.

1. ✅ **The marker** (printed, measured 180 × 180 mm, on main `eca6c24`; waiting on @salman to confirm Xcode) (sweep
   by @ahmed: Salman's app tracks it at 0.18 m, his 22:10 entry; he didn't mention Xcode warnings) (do this first: @salman and @max are both waiting on it)
   - A high-contrast, detailed, non-repeating image, 15 to 20 cm wide (small ones track badly), printed flat and
     matte. Measure the printed width with a ruler and commit the image to `assets/marker/` with that width in mm
     beside it: ARKit needs the exact size. Print spares.
   - *Done when:* the file and its width are on `main`, and @salman confirms Xcode accepts it with no warnings.
2. ⬜ **Fix the laptop and the marker to one board** (replaces "Pick and get the demo objects" after the team's
   SSD-swap decision, 23:03)
   - Ahmed's laptop and the printed marker on one board, the marker next to the SSD cover, so the two can't move apart.
   - A **bright sticker on the SSD**, in one colour nothing else in view has: the UNO Q rig's camera finds the SSD by it
     (decided 23:24). The coloured cable boot is no longer needed.
   - A fixed spot for the Nicla Vision looking into the SSD bay, agreed with Ahmed before the scan.
   - Nobody sprays the laptop for the scan (Ahmed). Ahmed backs the laptop up before any rehearsal.
   - *Done when:* the board is built, @max has been told it's ready to scan, and the rig's spot is agreed with @ahmed.
   - `[⚠ conflicts with @ahmed: the rig's camera spot]` `[⚠ conflicts with @max: he scans it]`
3. ✅ **The guide builder** (done 02:22: a 3-step guide built in the panel reached the fake phone and its taps ticked the steps; was: step editing and progress tracking on `laura-guide`, not merged; blocked on
   @max's answer to your scene-API ask 1)
   - Build against the fake phone in `fixtures/` and @max's scene API. Step list, instruction text, model and
     action pickers, send the guide, jump to a step, tick steps as `step.done` arrives.
   - The guide's shape is `Guide` in `contracts/protocol.ts` (`import type`). Steps are referred to by `id`, never
     by position, and each edit bumps `rev`. Positions come from @max's scene API already in the marker frame.
   - Objects can carry an optional `expect: { region, present }` (changed 23:24): what the UNO Q rig should see once
     the step is done. Let the expert set it on the SSD steps: `{ region: "ssd-bay", present: false }` to take it out,
     `present: true` to put it back. Region names match the rig's.
   - A model moves along `axis` (decided by Ahmed): fill it from the model's own +Y after rotation (pull +Y, push -Y,
     turns around Y), and let the expert change it.
   - *Done when:* a three-step guide built in the UI appears in the fake phone's log, and its `step.done` ticks the
     step.
   - `[⚠ conflicts with @max: dashboard/src/scene/api.ts]` `[⚠ conflicts with @ahmed: the guide shape in contracts/protocol.ts]`
4. 🟡 **The built-in models** 🟠 (all six on main `3ab2d07`, conventions decided; waiting on @max and @salman to load them)
   - ✅ **New (your 23:03 ask): an `ssd` model** (done 00:58, on main `61a771e`, with `ssd` in the contract and the relay). Build `ssd.glb` and `ssd.usdz`, and in the same commit add `"ssd"` to
     `ModelName` in `contracts/protocol.ts` and to `MODELS` in `relay/validate.ts`: your test and the relay's
     type-check each need all three to agree, so separate commits would turn `main` red. You have Ahmed's OK to edit
     both files. Check with `cd relay && npm install && npm run typecheck && npm test`.
   - Salman reports the six USDZ load and animate in RealityKit (23:25); size and up-direction not reported yet.
   - Screw, bolt, arrow, screwdriver, hand, cable plug, as glTF for the dashboard and USDZ for the phone. Decide
     first: author once and convert, or keep both by hand. Same names, sizes and origins in both.
   - *Done when:* each model loads in the dashboard and in @salman's app, the same size and the same way up.
   - `[⚠ conflicts with @salman and @max: both load these]`
5. ⏸ **The live video panel** (superseded 2026-11-15 01:45 by Ahmed, do NOT action: Salman's `ios/expert-call/` page is
   the call screen, opened beside the dashboard. Would come back only if that page can't be used in the demo.)
   - Show the phone's camera in the dashboard.
   - **The expert calls the phone** (decided 23:30): the dashboard makes the offer, the phone answers. Salman's
     `ios/expert-call/index.html` (on `salman-ios`) is a working expert side to build from: the offer, `rtc.signal`,
     two-way audio, a data channel for hang-up. `fixtures/video-test.html?role=send` stands in for the phone.
   - *Done when:* the stream from the phone (or a fake sender) plays in the panel, and the guide builder still
     works with it switched off.
   - `[⚠ conflicts with @ahmed and @salman: WebRTC signalling]`
6. ⬜ **What the judges see**
   - README, demo video, submission form (`pitch` skill). Start once a guide plays end to end.
   - The demo is the SSD swap. Tick MLH Gemini and ElevenLabs as well as the four sponsor challenges (decided
     23:30), and say on Devpost that AI tools were used (`EVENT.md` §3).
   - *Done when:* `bash scripts/submission-check.sh` passes and the submission is in.

## 4. Done log (newest first)
- 2026-11-15 02:22 · ✅ Guide panel on main (`a61405f`): steps, objects, quarter turns, rig check, Send, ticks, open a guide file. Done-when met against the relay and fake phone. Not yet: 3D dragging, custom axis.
- 2026-11-15 02:11 · ✅ The 12 SSD-swap steps for the Latitude 5530, from Dell's manual (ledger § 17) and checked on the laptop (8 cover screws, no bracket, 1 SSD screw), posted for Ahmed's `ssd-swap-guide.json`.
- 2026-11-15 00:58 · ✅ `ssd` model (glb + usdz) and `"ssd"` in `ModelName` + `relay/validate.ts`, one commit on main `61a771e`; all tests green. Salman's Swift enum still needs the case.
- 2026-11-14 22:30 · 🟡 Six built-in models (glb + usdz, one build script, 7 tests) on main. Decided: metres, +Y up, tip at origin, script committed. Closes when @max and @salman see them the right size and way up.
- 2026-11-14 21:31 · 🟡 Marker printed on matte paper, measured 180 × 180 mm, image + print sheet in `assets/marker/` on main. Closes when @salman confirms Xcode accepts it.

## 5. Waiting on / owed to others
- 📥 **Waiting on @max:** answers to your four scene-API asks (ask 1 blocks the guide builder); PR #6 merged.
- 📥 **Waiting on @ahmed:** nothing right now. The contract, relay and fake phone are on `main`
  (`node fixtures/fake-phone.ts ws://<relay>:8080`), and the deadlines are in `PROJECT.md` → Clock.
- 📤 **Owed to @salman and @max:** the marker image and width are on main (task 1, 180 mm); the six models are on main too (`assets/models/`).
- 📤 **Owed to @max:** the laptop and marker on their board, to scan.
- 📤 **Owed to @ahmed:** a spot where the Nicla Vision sees the SSD bay, and the sticker on the SSD, agreed before
  the scan.

## 6. Working-style notes for the agent
- Verbosity: project level (Level 0) unless Laura changes it.

## 7. Reference (no secrets, ever)
- The demo and the challenge fit: `docs/remote-assist/README.md`. Marker evidence: `research/ledger.md` § 3 and § 5.

---
── Archived (superseded 2026-11-14 — do NOT action) ──
- **Pick and get the demo objects** (task 2 until 23:03): a switch or router, a patch panel, a cover with screws,
  and a cable with a coloured boot. Superseded by the team's SSD-swap decision (Laura's 23:03 entry). Would come
  back only if the demo returns to a network cabinet.
- **Ask about the UNO Q today** and **The hardware check** (the RS feature). Moved to @ahmed on 2026-11-14: he said he'd do the
  rig himself. Now tasks 3 and 9 in his brief. Would come back only if he hands it back.
