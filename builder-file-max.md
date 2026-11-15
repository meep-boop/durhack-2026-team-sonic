# Max: the dashboard's 3D view (splat, picking, calibration, cut-outs) and the splats
**GitHub:** `xaw1` · **Branch:** `max-scene` · **Brief last updated:** 2026-11-15 by max
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

**▶ CHANGE (2026-11-15 08:30, Ahmed's decision): the demo opens with Salman's technician console, then the guide dashboard.**
New order of the 5 minutes: problem → **live call: the expert clicks a screw on the phone's video and it appears on
the real screw (Point, Unscrew, Screw in, Area)** → the guide dashboard: send the prepared guide, taps and ticks →
phone Wi-Fi off, it keeps going, syncs → SSD out, the rig's ✓ → what's real. If the scans aren't calibrated in time,
the guide's positions are typed and we say "prepared guide".
- **For you:** the scan route is now the second beat, not the first. Two new scans are on Ahmed's laptop as
  `dashboard/public/scans/scan-0801.usdz` and `scan-0809.usdz` (not committed yet: Ahmed is trying the calibration).

**▶ YOUR CHECKLIST (from @ahmed, 2026-11-15 07:47). Do these top to bottom; tick each with ✅ and a time. Everything below is
background.** Why: boxes float on the phone because no guide has real positions yet. The fix is a scan with the
marker in it, then clicking each part in that scan.
1. ⬜ **Scan, closed.** Laptop face down in its tape corners, the whole marker visible beside it. Scan in Scaniverse,
   export, and save it as `dashboard/public/scans/closed-<time>.usdz` (a new name, never overwrite).
2. ⬜ **Scan, open.** Take the cover off without moving the laptop. Scan again, save as `open-<time>.usdz`.
3. ⬜ **Load both:** open the dashboard with `?closed=closed-<time>.usdz&open=open-<time>.usdz`.
4. ⬜ **Calibrate each scan:** click the marker's four corners in order (top-left, top-right, bottom-right,
   bottom-left). The chip must show under 5 mm. If it's refused, click again more carefully.
5. ⬜ **Build the guide** in Laura's panel, using her 12 steps (her 02:11 board entry). Closed scan: "Place on scan"
   on each of the 8 cover screws, model `screw`, action `unscrew`. Open scan: the SSD screw (`screw`, `unscrew`), the
   SSD (`ssd`, `pull`, rig check "out"), then again (`ssd`, `push`, rig check "in").
6. ⬜ **Send it**, and check the phone shows the same title.
7. ⬜ **Look at the phone over the real laptop.** Is each box on its screw? If everything is mirrored or turned,
   tell Ahmed: the marker's axes are the other way round (a few lines in `dashboard/src/scene/calibration.ts`).
8. ⬜ **Measure** three screws with a ruler: how far is the box from the real screw? Post the three numbers.
9. ⬜ **Commit both scans** and post a board entry.
10. ⬜ **Make the preview match the phone** (`dashboard/src/scene/preview.ts`): unscrew = two turns rising 15 mm,
    then restart; pull / push = 4 cm one way, then restart.
11. ⬜ Only if 1–9 work: one live AI-labels call (ask Ahmed first, it's paid), and the AI-made prop.
- You're the docs owner while Ahmed's laptop is the prop.

**How to start everything (for the run-through and the demo), in this order:**
1. Max's laptop, terminal 1: `cd relay && npm install && npm start`. Note the `ws://…:8080` line it prints.
2. Max's laptop, terminal 2: `cd dashboard && npm install && npm run dev`. Open the link it prints.
3. Max's laptop, terminal 3: `cd ios/expert-call && python3 -m http.server 8000` (the Call button opens this).
4. Phone: open the app, tap the status pill, enter or scan the relay's `ws://` address.
5. UNO Q: press Run in App Lab. The console must say `connected to ws://…` and `nicla sees the part in: …`.
6. Dashboard header: the Relay, Phone and Rig lights are all green. If one is grey, fix that one before going on.

**▶ Side route (Max's call, 2026-11-15 08:00; `PROJECT.md` → Decision log): scanning inside our own app.** After the
checklist above, never ahead of it.
- D. 🟡 (08:35: phone side, inbox and trainer on `max-ios-scan` at `c6d4014`; inbox 6/6 and trainer 5/5 tests pass;
  `~/scan` set up on the Spark; Swift never compiled) **Scan the room in the phone app** → `pipeline/inbox/` on the
  relay laptop → `pipeline/train_scan.py` on the Spark → a splat already in the marker frame. *Done when:* one real
  phone scan, trained on the Spark, calibrates on the dashboard with the corners landing on the print, and the
  training time is measured. Waits on Salman's yes and Xcode build (his brief, last block).
  `[⚠ conflicts with @salman: three small hooks in his app]`

**▶ What's left (from @ahmed, 2026-11-15 04:12), ahead of the 01:45 block below.** 
1. ⬜ P0 **Rescan both (closed, cover off) with the marker in view**, at Laura's taped table, then calibrate each.
   Nothing built in a scan can line up on the phone until this is done. *Done when:* both calibrate under 5 mm.
2. ⬜ P0 **Rung 2 with the real phone**, once Salman's PR #8 is on `main`: place one object on a screw in the scan,
   send it, and check where it lands on the real laptop. Post the error in mm.
3. ⬜ P1 **Cut-outs**, then anything else on the dashboard: **Ahmed agreed you work on features to 10:00** (the
   Clock now says so). The phone, relay and rig still freeze at 07:00, so no message shape changes after that.
4. ⬜ P1 **One live Claude labelling call** with Ahmed's OK (it's paid): relay with `--labels` and credentials on
   your laptop. Until then the feature is labelled MOCK-tested.
5. ⬜ **Before the demo:** check port 8080 is free after any reboot; serve `ios/expert-call/` on 8000.
- From Ahmed: a `--state <file>` flag for the relay is coming, so a test relay never shares `relay/state.json`.
- Thanks for `docs/vault/`; Ahmed's agent will check `relay.md`, `messages.md` and `rig.md`.

**▶ New (2026-11-15 03:40, Max's call; `PROJECT.md` → Decision log). Do these first.**
- A. ✅ (03:55, `aa6d177`; Laura's panel restyle waits on her yes) **The dashboard as a product screen.** A header (Remote Assist, Closed / Open switch, relay / phone / rig
  lights from `presence`, a **Call** button opening Salman's page in its own window at `http://<host>:8000/?relay=…`,
  `?call=` to change it); a live strip (the person's step, ticks, the rig's ✓ / ✗, amber "phone offline, still
  working on its own" with a timer); plain prompts in place of the debug text (debug behind a key); one calm dark
  look on both halves. *Done when:* a fake phone dropping off and coming back shows the offline moment and the
  catch-up, and the screen reads without the debug text.
  `[⚠ conflicts with @laura: GuidePanel.css restyle, colours and spacing only, once she agrees]`
- B. ⬜ **Cut-outs** (task 5 below), after A.
- C. 🟡 (05:24: Pixal3D runs on the Spark; screwdriver prop made from Max's photo, 164 mm, about 2–4 min per prop; SSD photo next; where props show is Max's call with Laura) **Now Pixal3D, cut-off 07:30** (04:32, Max's call; Hunyuan's licence excludes the UK; ledger § 19; building in `~/pixal3d` on the Spark) (04:05, Max's call; `PROJECT.md` → Decision log) **AI-made props on the DGX Spark.** Hunyuan3D 2.1
  (`dr-vij/Hunyuan3D-2.1-DGX-Docker`) builds over SSH in the background. Then one clean photo each of the SSD and the
  #0 screwdriver → textured GLB → scaled to the real size (SSD 22 × 80 mm) → shown on the dashboard, labelled
  "AI-generated from a photo". Phone (USDZ, § 15) only with Salman, only if there's time. *Done when:* the SSD prop
  shows on the dashboard at its real size with its label. *Drop it if:* not built by about 06:30. Research:
  `research/ledger.md` § 18.

**▶ The plan to the deadline (from @ahmed, 2026-11-15 01:45). Do these first, in this order; the older tasks below keep
their detail.** Why: the phone side is nearly there, but the dashboard is still a viewer with no relay connection,
so we climb a ladder: rung 0 the real phone plays a prepared guide; rung 1 the dashboard connects and sends it;
rung 2 a guide built in the scan lines up on the phone; rung 3 the extras. Decisions: `PROJECT.md` → Decision log.
1. ✅ P0 **Merge PR #6 now** (item B): it's only the shell, it passed the pre-check, and three people build on it.
2. ✅ P0 **App shell** (answers Laura's ask 1): `App.tsx` makes the scene once and renders the viewport beside
   `<GuidePanel scene relay />`. Add `isCalibrated()` and `onCalibrated()` to `SceneApi` (ask 3). Asks 2 and 4 fall
   away: the laptop lies flat beside the marker, so objects stand upright and turn only about Y.
3. 🟡 P0 **Two scans** (decided by Ahmed): closed, then cover off, both with the marker in view and the laptop in
   Laura's corner stops. Load by URL (`?splat=`) from a git-ignored folder, with a Closed / Open switch. A scan's
   id is its file name; the relay will keep one calibration per scan.
   *Status (02:32):* the loading and the switch are built (`?closed=<file>&open=<file>` from
   `dashboard/public/scans/`), for splats and meshes. A first cover-off mesh scan loads well but has **no marker in
   it**, so it can't be calibrated. Left: rescan both with the marker fully in view, then calibrate each.
4. ✅ P0 **`pickPoint()`** (task 2) with three's `Raycaster` on the `SplatMesh`. Show the hit as a dot: Spark can
   hit hidden splats (its issues #497, #498).
5. ✅ P0 **Calibration screen** (task 3): four clicks → `solveCalibration` → one `markerGroup` holding the
   marker→scan transform → `calib.set`. Draw the marker outline and axes on the scan, show the residual, refuse
   above 5 mm. Ahmed recommends no placing until calibrated (your open question; yours and his to settle).
6. ✅ P0 **`showStep()`** (task 4): the yellow box plus the `.glb` under `markerGroup`. `GLTFLoader` is a three
   add-on; Vite needs `server.fs.allow: [".."]` to serve `../assets/models`.
7. ✅ P1 **The user's position** (task 6): a cone under `markerGroup` from `pose`, which is already in the marker frame.
8. ✅ P1 **Labels** (task 7): snapshot → `labels.request` → labels on screen → search box → `focus()`.
9. 🟡 P1 **Dragging** *(dragging ✅ `5412078`; cut-outs not started)* with three's `TransformControls` → `onObjectMoved`; then **cut-outs** (task 5). Both stay in
   scope (Ahmed), after rung 2.
- ✅ (OK given; merged 02:16) 📨 **Ahmed asks your OK** for his agent to build two pieces in `dashboard/`: `src/relay/client.ts` (the relay
  connection: hello as `expert`, reconnect, typed `send` and `on`) and `src/scene/calibration.ts`
  (`solveCalibration(corners, marker)`, pure maths with tests). Everything that needs the 3D view stays yours.
- **You're now a docs owner** (`team.conf`): Ahmed's laptop is the demo prop, so it goes dark for the scans, the
  video and the demo. You can publish any shared doc.
- The call screen is Salman's `ios/expert-call/` page beside the dashboard; no React video panel.

> 🟡 **START HERE (2026-11-15 03:55, @max's session):** task A is on `main` (header, live strip, offline moment,
> debug behind the backquote key). Next: cut-outs (B). Waiting on Laura's yes to restyle `GuidePanel.css`. Max's own
> working limit for features is about 10:00; the team Clock (07:00 freeze) is unchanged until the team agrees.
>
> *Earlier (03:15):* tasks 7, 8 and dragging are on `main`. Waiting on Laura's
> board for the rescans. Open for Max: whether labels persist across a reload (now page-only); PR #1; Anthropic
> credentials on this laptop for `--labels`. Next code: cut-outs (task 5).
>
> *Earlier (02:32):* the dashboard takes mesh scans too (`009153c`). The first
> cover-off scan has no marker in it: **rescan closed and open with the marker in view**, drop them in
> `dashboard/public/scans/`, open `?closed=<file>&open=<file>`, calibrate each.
>
> *Earlier (02:16):* rung-1 dashboard code is on `main` (`0fddd63`): shell,
> scan switch, picking, calibration (blocks placing until done), `showStep`. Next: take the two real scans (item 3),
> calibrate them, then P1 items 7–9. Free port 8080 on this laptop before the demo: a node process already holds it.
> Still open: PR #1 (merge or close).
>
> *Older note (2026-11-14 23:55):* answer Laura's four asks on `dashboard/src/scene/api.ts`
> (her `progress.md` entry at 23:04). **Ask 1 blocks her:** how `dashboard/src/guide/` gets the `SceneApi` instance
> and where her panel mounts (`main.tsx` renders only `<Viewport />` today). Asks 2–4: return the surface normal from
> `pickPoint()`; a calibrated flag plus a change event; `size` in `onObjectMoved` if boxes resize in 3D. Each changes
> the contract, so each is Max's decision; explain them in plain words. Branch `max-scene` (PR #6) is 16 behind
> `main`: merge `origin/main` first. Then: scan Ahmed's laptop on its board in Scaniverse (the demo is now an SSD
> swap) and drop the export on the dashboard for the first real speed test. Open PRs: #6 (dashboard + scene API),
> #1 (research answers and decisions, with sources, on `max-docs`). Research: `research/ledger.md` § 7–15.

**New from @ahmed (2026-11-14 23:40 sweep):**
- A. 🟡 **Run the relay on the dashboard laptop for the demo** (decided 23:20: Ahmed's laptop is opened up in the
  demo, so it can't host it). Node 24, then `cd relay && npm install && npm start`; add `--labels` only for Claude
  labelling, which also needs Anthropic credentials on that laptop. *Done when:* the phone, the dashboard and the rig
  all connect to it on the hotspot. `[with @ahmed]` *Status (02:32):* runs on this laptop on 8080 with the dashboard
  (port 8080 freed from an unrelated background task that may return after a reboot). Left: the phone and the rig on
  the hotspot.
- B. 🟡 **Merge PR #6 with the `ship` skill before the walking skeleton** (`PROJECT.md` → Clock), and merge or close
  PR #1. Pre-check by @ahmed (2026-11-15 00:54, read-only): `max-scene` at `6a6753b` with today's `main` merged in has no
  conflicts; 8 tests, the type-check and `npm run build` all pass. *Status (02:16):* PR #6 merged. PR #1 still open.
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
- 2026-11-15 03:55 — task A: header (scan switch, calibration chip, relay / phone / rig lights, Call the phone) and
  live strip (set up, build, step N of M with dots and the rig's check, amber offline timer, back-online catch-up,
  done); debug behind ` (`aa6d177`). Tried with the fake phone dropping off. Dashboard 54 tests.
- 2026-11-15 — `docs/vault/` (PR #10): 14 plain-language notes, standard links, Obsidian-ready. Owners asked to skim
  their notes.
- 2026-11-15 03:15 — task 9 dragging: handles on the selected object, R turns about +Y, `onObjectMoved` once per
  drag (`5412078`). Task 8: AI labels on the scan, search, rename, delete (`4cd8b7f`; tried with a MOCK labeller
  only). Task 7: the phone's camera in the scan, green / amber / gone (`d91f7ba`). Dashboard 46 tests.
- 2026-11-15 02:39 — PR #9 merged (`d44dd01`): `dashboard/public/scans/` is in git, with the first scan (mesh, cover
  off, no marker: reference only). Notes to Laura, Ahmed and Salman on the board and in their briefs.
- 2026-11-15 02:32 — mesh scans (`.usdz`, `.glb`) load beside splats; pick dots a fixed size on screen; first real
  scan loaded (no marker: rescan needed). `main` `009153c`; 42 tests.
- 2026-11-15 02:16 — PR #6 merged; `ahmed-dashboard` merged; app shell with the GuidePanel slot, `isCalibrated` /
  `onCalibrated`; scan switch; `pickPoint` in marker metres; calibration screen (5 mm limit, `calib.set`, restored on
  reload); `showStep` with select, focus, click-to-select and action previews. `main` `0fddd63`; 22 tests.

## 5. Waiting on / owed to others
- 📥 **Waiting on @laura:** the finished demo set to scan (now Ahmed's laptop on a board). *(02:39: asked her to fix
  the marker flat beside the laptop, corners clear, and post when ready; her task 1.)*
- 📥 **Waiting on @salman:** which printed edges red +X and blue +Z point to (his item 3), and `salman-ios-polish` on
  `main` for rung 1. *(Marker 180 mm and the
  six glTF models are on `main`: a model's tip, not its centre, sits at `pos`.)*
- 📥 **Waiting on @ahmed:** the labelling endpoint. (The contract, sample guide, relay and fake phone are on
  `main`: `node fixtures/fake-phone.ts ws://<relay>:8080`.)
- ✅ ~~Owed to @laura: answers to her four asks on `api.ts`~~ answered in the 02:16 board entry.

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
