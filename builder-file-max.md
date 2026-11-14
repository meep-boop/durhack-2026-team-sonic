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

**START HERE (2026-11-14, from @ahmed):** the split and the decisions in `PROJECT.md` → NOW were made by Ahmed on
top of Max's round-1 plan. If you disagree with your role or with a decision, say so in a `progress.md` entry
(`📨 To @ahmed`) before building on it. All four of us build at once, each against the fake peers in `fixtures/`,
so nobody waits for anybody. Until `contracts/protocol.ts` lands, use the draft in
`docs/remote-assist/architecture.md` and expect small changes.

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
| `relay/`, `contracts/`, `fixtures/` | @ahmed |
| `dashboard/src/guide/`, `assets/`, `hardware/`, the pitch material | @laura |

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

1. ⬜ **Dashboard shell with a splat on screen, and the scene API**
   - Scaffold `dashboard/`. Scan any desk with a printed test marker on it in Scaniverse, export it, and render it.
     Write `dashboard/src/scene/api.ts`: what @laura's guide builder can call (pick a point, add, move and remove
     an object, preview an action) and what it gets back.
   - *Done when:* the dev server shows an orbitable splat, and @laura has agreed `api.ts` on the board.
   - `[⚠ conflicts with @laura: dashboard/src/scene/api.ts is the seam]`
2. ⬜ **Click to pick a point on the splat**
   - No mesh to hit: take the splat centre nearest the mouse ray (within about 1 cm) that's closest to the camera.
   - *Done when:* clicking a small visible feature drops a dot on it, from three different camera angles.
3. ⬜ **Marker calibration**
   - The expert clicks the marker's four corners. Show the leftover error. Send the calibration message.
   - *Done when:* the fake phone in `fixtures/` logs the calibration, and the residual is on screen in mm.
   - `[⚠ conflicts with @ahmed: the calibration message, and which side solves the transform, in contracts/protocol.ts]`
4. ⬜ **Objects in the scene**
   - Show each step's highlight boxes and built-in glTF models where the guide puts them, and preview the preset
     actions.
   - *Done when:* `fixtures/sample-guide.json` renders in the right places and each action previews.
   - `[⚠ conflicts with @laura: model names, sizes and origins in assets/models/]`
5. ⬜ **Cut-outs**
   - The expert draws a box around a part. The splat points inside become their own object that can be moved and
     highlighted. The expert picks the closest built-in model for the phone to show.
   - *Done when:* a cable or screw is lifted out of the scan and moved, and the guide sent to the fake phone names a
     built-in model for it.
6. ⬜ **Where the user is standing**
   - Draw the phone's camera position inside the scan from `pose` messages.
   - *Done when:* the fake phone's moving pose shows as a moving marker in the scene.
7. ⬜ **Find a part by name** (the Accenture feature) 🟠
   - A search box: type "port 14", the view jumps to it and it can be dropped into a step. Labels come from
     @ahmed's endpoint. First decide with him what the model looks at (renders of the splat, or camera frames).
   - *Done when:* typing a label that exists highlights the right part. Labels are shown as AI-made, with a way to
     fix a wrong one.
   - `[⚠ conflicts with @ahmed: the labelling endpoint and the label shape in contracts/protocol.ts]`
8. ⬜ **The real splat of the demo set**
   - Once @laura's set is built with the marker fixed on it, scan it and swap it in.
   - *Done when:* the set's splat is in the dashboard and a re-calibration gives a residual you'd demo with.
9. ⬜ **Dawn** (upgrade only)
   - Log in and run one small job. If it works, train the set's splat there.
   - *Done when:* either a Dawn-trained splat is in the dashboard, or a board entry says why not.

## 4. Done log (newest first)
- _(empty)_

## 5. Waiting on / owed to others
- 📥 **Waiting on @laura:** the marker image and printed width; the glTF models; the finished demo set to scan.
- 📥 **Waiting on @ahmed:** `contracts/protocol.ts`, the fake phone, the sample guide, the labelling endpoint.
- 📤 **Owed to @laura:** `dashboard/src/scene/api.ts`, first thing: her guide builder builds on it.

## 6. Working-style notes for the agent
- Verbosity: project level (Level 0) unless Max changes it.
- Max wrote the plan and made the round-1 decisions; Ahmed carried them forward as agreed.

## 7. Reference (no secrets, ever)
- The plan: `docs/remote-assist/architecture.md`. Evidence: `research/ledger.md` § 1–4 (yours) and § 5.
- Your two requests from the 19:40 board entry are in `PROJECT.md` → NOW (demo objects → @laura; Mac with Xcode →
  answered yes by @ahmed).

---
── Archived (superseded — do NOT action) ──
- _(empty)_
