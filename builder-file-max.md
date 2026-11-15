# Max: the dashboard's 3D view (splat, picking, calibration, cut-outs) and the splats
**GitHub:** `xaw1` · **Branch:** `max-scene` · **Brief last updated:** 2026-11-14 by ahmed
**Spec:** `PROJECT.md` (NOW first); the § numbers below refer to it. **Deadlines:** `PROJECT.md` → NOW → Clock.
**The plan in full:** `docs/remote-assist/README.md` and `architecture.md` (on `main`, written by @max).

## 0. How the agent reads this brief (every task)
1. Read the project `CLAUDE.md` in full, then this brief. Follow both.
2. **Only action `▶ Current tasks`**, top to bottom.
3. The every-prompt hook syncs the docs and shows new `progress.md` entries. Handle any open
   `⚠️ Conflicts: @max` first.
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
- `dashboard/src/scene/`: the 3D view of the scanned room in the expert's dashboard.
- The `dashboard/` app shell (you scaffold it; @laura builds inside it).
- The splat files and how they're made (`splats/`, `pipeline/`): Scaniverse first, Dawn as an upgrade.
- `docs/remote-assist/` (your plan docs).

**Does NOT touch:**

| Area | Owner |
|---|---|
| `ios/` | @salman |
| `relay/`, `contracts/`, `fixtures/`, `hardware/` | @ahmed |
| `dashboard/src/guide/`, `assets/`, the pitch material | @laura |

**Shared** (flag every edit in `progress.md` → `⚠️ Conflicts`): `contracts/protocol.ts` (ask @ahmed for changes),
`fixtures/*`, and the seam between scene and guide (`dashboard/src/scene/api.ts`, agreed with @laura).

## 2. Contract and guardrails
**Scope contract.** max is building:
- A 3D view where the expert orbits the scanned room, clicks a part to place a box or model on it, and draws a box
  to lift a part out of the scan as its own object.
- The one-off calibration: the expert clicks the printed marker's four corners in the splat.
- The user's position shown inside the scan, and a search box that jumps to a labelled part ("port 14").

**Out of scope:** the step timeline and pickers (that's @laura, calling your scene API). Anything on the phone.

**Guardrails:**
- **The guide must never depend on video, the AI labels or the hardware.**
- Three.js, Spark, Vite and any other package are each a 🟠 decision for you before they go in.
- Scaniverse is the main splat route. Don't block on Dawn: nobody has logged in yet. Whether a Scaniverse export
  is in metres is **not documented**, so take scale from the marker's known printed size, never from the file.
- We only say "trained on Dawn" if the splat on screen really was.
- For now a cut-out stays on the dashboard and the phone gets a box plus the name of the closest built-in model.
  That was decided before your research in `research/ledger.md` § 1 and § 4 landed; it's reopened in `PROJECT.md` →
  Pending for you and Ahmed to settle.

---

## 3. ▶ Current tasks (2026-11-14), in order
*Status: ⬜ not started · 🟡 in progress · ⏸ blocked · ✅ done*

> 🟡 **START HERE (2026-11-14 23:55, @max's session):** answer Laura's four asks on `dashboard/src/scene/api.ts`
> (her `progress.md` entry at 23:04). **Ask 1 blocks her:** how `dashboard/src/guide/` gets the `SceneApi` instance
> and where her panel mounts (`main.tsx` renders only `<Viewport />` today). Asks 2–4: return the surface normal from
> `pickPoint()`; a calibrated flag plus a change event; `size` in `onObjectMoved` if boxes resize in 3D. Each changes
> the contract, so each is Max's decision; explain them in plain words. Branch `max-scene` (PR #6) is 16 behind
> `main`: merge `origin/main` first. Then: scan Ahmed's laptop on its board in Scaniverse (the demo is now an SSD
> swap) and drop the export on the dashboard for the first real speed test. Open PRs: #6 (dashboard + scene API),
> #1 (research answers and decisions, with sources, on `max-docs`). Research: `research/ledger.md` § 7–15.

**New from @ahmed (2026-11-14 23:40 sweep):**
- A. ⬜ **Run the relay on the dashboard laptop for the demo** (decided 23:20: Ahmed's laptop is opened up in the
  demo, so it can't host it). Node 24, then `cd relay && npm install && npm start`; add `--labels` only for Claude
  labelling, which also needs Anthropic credentials on that laptop. *Done when:* the phone, the dashboard and the rig
  all connect to it on the hotspot. `[with @ahmed]`
- B. ⬜ **Merge PR #6 with the `ship` skill before the walking skeleton** (`PROJECT.md` → Clock), and merge or close
  PR #1. Pre-check by @ahmed (2026-11-15 00:54, read-only): `max-scene` at `6a6753b` with today's `main` merged in has no
  conflicts; 8 tests, the type-check and `npm run build` all pass.
- C. Scanning the laptop: **nobody sprays it** (Ahmed); your correction that it was never your request is noted.

1. 🟡 **Dashboard shell with a splat on screen, and the scene API**
   - *Status (2026-11-14 23:55, @max):* shell, SAMPLE splat and `api.ts` in PR #6 (`max-scene`). Laura agreed the
     one-copy design (23:04) but asked for four additions first. Left: answer them; scan the real set (now Ahmed's
     laptop) in Scaniverse and load it; merge.
   - Scaffold `dashboard/`. Scan any desk with a printed test marker on it in Scaniverse, export it, and render it.
     Write `dashboard/src/scene/api.ts`: what @laura's guide builder can call (pick a point, add, move and remove
     an object, preview an action) and what it gets back.
   - *Done when:* the dev server shows an orbitable splat, and @laura has agreed `api.ts` on the board.
   - `[⚠ conflicts with @laura: dashboard/src/scene/api.ts is the seam]`
2. ⬜ **Click to pick a point on the splat**
   - No mesh to hit: take the splat centre nearest the mouse ray (within about 1 cm) that's closest to the camera.
   - *Done when:* clicking a small visible feature drops a dot on it, from three different camera angles.
3. ⬜ **Marker calibration**
   - The expert clicks the marker's four corners (top-left, top-right, bottom-right, bottom-left, as the print
     reads upright). **The dashboard does the conversion** (decided by @ahmed): solve scale, rotation and
     translation from splat coordinates to the marker's frame in metres, using the printed size. Show the leftover
     error. Every position, rotation, size and axis in a `guide.set` goes out in the marker frame; splat
     coordinates only travel in `calib.set`, which the relay keeps for you and never sends to the phone.
   - *Done when:* the clicked corners land within a few mm of the printed corners after conversion, the residual
     is on screen in mm, and your `calib.set` passes the relay's check (`relay/validate.ts`).
   - `[⚠ conflicts with @ahmed: the frame and calib.set are in contracts/protocol.ts]` `[⚠ conflicts with @salman: +x
     and +z directions are provisional until his axis check]`
4. ⬜ **Objects in the scene**
   - Show each step's highlight boxes and built-in glTF models where the guide puts them, and preview the preset
     actions.
   - *Done when:* `fixtures/sample-guide.json` renders in the right places and each action previews.
   - `[⚠ conflicts with @laura: model names, sizes and origins in assets/models/]`
5. ⬜ **Cut-outs**
   - The expert draws a box around a part. The splat points inside become their own object that can be moved and
     highlighted. The expert picks the closest built-in model for the phone to show.
   - *Done when:* a screw or the SSD is lifted out of the scan and moved, and the guide sent to the fake phone names a
     built-in model for it.
   - Salman's phone runs iOS 26.3.1, below the iOS 27.2 that RealityKit splats need, so on the phone a cut-out shows
     as its box and a built-in model.
6. ⬜ **Where the user is standing**
   - Draw the phone's camera position inside the scan from `pose` messages. They arrive in the marker frame, so
     apply the inverse of your calibration. Show when `markerTracked` is false: alignment may be drifting.
   - *Done when:* the fake phone's moving pose shows as a moving marker in the scene.
7. ⬜ **Find a part by name** (the Accenture feature)
   - A search box: type "SSD", the view jumps to it and it can be dropped into a step. **Decided by @ahmed:** the
     dashboard sends `labels.request` with a snapshot of its current view (at most 1280 px on the long side) and gets
     `labels.result` back, labels at pixel positions, which your click-pick turns into 3D points. The relay side is on
     `main`; start the relay with `--labels` to turn it on (each snapshot is a paid Claude call).
   - *Done when:* typing a label that exists highlights the right part. Labels are shown as AI-made, with a way to
     fix a wrong one.
   - `[⚠ conflicts with @ahmed: the labelling endpoint and the label shape in contracts/protocol.ts]`
8. ⬜ **The real splat of the demo set**
   - The set is now Ahmed's laptop on a board with the marker (the team, 23:03). Once @laura has fixed them to the
     board, scan it and swap it in. Nobody sprays the laptop (Ahmed): scan it as it is.
   - *Done when:* the set's splat is in the dashboard and a re-calibration gives a residual you'd demo with.
9. ⬜ **Train the set's splat on the DGX Spark** (upgrade only; replaces Dawn 2026-11-14 22:20, at @max's request)
   - The team has a DGX Spark, not Dawn access. Pipeline and risks: `research/ledger.md` § 9. Scaniverse stays the
     baseline; only swap in the Spark-trained splat if it's clearly better.
   - *Done when:* either a DGX-Spark-trained splat of the set is in the dashboard, or a board entry says why not.

## 4. Done log (newest first)
- _(empty)_

## 5. Waiting on / owed to others
- 📥 **Waiting on @laura:** the finished demo set to scan (now Ahmed's laptop on a board). *(Marker 180 mm and the
  six glTF models are on `main`: a model's tip, not its centre, sits at `pos`.)*
- 📥 **Waiting on @ahmed:** the labelling endpoint. (The contract, sample guide, relay and fake phone are on
  `main`: `node fixtures/fake-phone.ts ws://<relay>:8080`.)
- 📤 **Owed to @laura:** answers to her four asks on `api.ts` (23:04 board entry); ask 1 blocks her.

## 6. Working-style notes for the agent
- Verbosity: project level (Level 0) unless Max changes it.
- Max wrote the plan and made the round-1 decisions; Ahmed carried them forward as agreed.

## 7. Reference (no secrets, ever)
- The plan: `docs/remote-assist/architecture.md`. Evidence: `research/ledger.md` § 1–4 (yours) and § 5.
- Your two requests from the 19:40 board entry are in `PROJECT.md` → NOW (demo objects → @laura; Mac with Xcode →
  answered yes by @ahmed).

---
── Archived (superseded 2026-11-14 — do NOT action) ──
- **Task 9 as "Dawn"** (log in to Dawn, train the splat there). Superseded 2026-11-14 22:20: the team has a DGX Spark, not
  Dawn access (@max, board entry 22:15). Would come back only if Dawn access turns up.
