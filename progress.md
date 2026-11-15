# Remote Assist: progress log and conflict board

**Every builder, every prompt:** the Claude hook shows the entries that are new since you last looked (by hand:
`git fetch && git diff HEAD..origin/main -- progress.md`). If an open `⚠️ Conflicts` line names you, tell your user,
then agree a fix with whoever flagged it before you touch that area.

**Every completed task** (a brief task, a merge to `main`, a deploy change, a fix) gets one entry, newest at the
bottom, pushed to `main` straight away:

```
### <YYYY-MM-DD HH:MM> — <feature or task> — @<builder>
- Shipped: <what changed, why>
- Touched: <files / modules / endpoints / shared contracts>
- Decision: <one line, who decided> (only if one was made)
- ⚠️ Conflicts: @<name> — <what of theirs this changes or could break> | none
- Conflict status: open | resolved by @<name> <date>
```

## Headline
**Remote Assist.** Step-by-step 3D guidance on a phone, built by a remote engineer from a scan of the room, that keeps working when the network is down. The plan: `docs/remote-assist/`.

## Start here (teammates, first 15 minutes)
1. **GitHub:** accept the collaborator invite for `github.com/meep-boop/durhack-2026-team-sonic`, then in **Git Bash** on Windows (plain `bash` in
   PowerShell can start WSL instead) or any terminal on Mac/Linux:
   ```bash
   git clone https://github.com/meep-boop/durhack-2026-team-sonic.git && cd durhack-2026-team-sonic
   git config user.email "<the email on YOUR GitHub account>"   # judges read who committed
   bash scripts/setup.sh <your key from team.conf>              # who you are, commit hooks, first docs sync
   ```
   Not in `team.conf` yet? Ask a docs owner (ahmed, max) to add your key and brief.
2. **Claude Code:** start it **in the repo root**, so the every-prompt hook in `.claude/settings.json` runs (trust the
   folder when it asks). Then say "fetch the context".
3. **Optional, but it's what we use:** `gitleaks` (secret scan on every commit), plus the Claude Code plugins listed
   in `README.md`.
4. **Things that live only on one machine** (read them there; never paste them in chat or commit them):

   | What | Where |
   |---|---|
   | _e.g. API keys_ | _e.g. `secrets/` on the server, or a password manager_ |

## Who owns what
Ask the owner before changing their area, and flag them in `⚠️ Conflicts` if you touch it. Full task lists are in
each builder's brief (`builder-file-<name>.md`, on the `context` branch).

| Who | Role | Branch | Owns (paths / pieces) | How the rest plugs into it |
|---|---|---|---|---|
| **Ahmed** `meep-boop` | Docs owner; relay, protocol, sync, UNO Q rig | `ahmed-relay` | `relay/`, `contracts/`, `fixtures/`, `hardware/` (the UNO Q rig), the labelling endpoint; the team kit (`scripts/`, `kit/`, `team.conf`) and the shared docs on `context` | Build against `contracts/protocol.ts` and the fake peers in `fixtures/`. Ask Ahmed for protocol changes |
| **Max** `xaw1` | Docs owner; dashboard 3D view and the splats | `max-scene` | `dashboard/src/scene/`, the `dashboard/` shell, `splats/`, `pipeline/`, `docs/remote-assist/` | The guide builder calls `dashboard/src/scene/api.ts` |
| **Laura** `furtunalaura` | Guide builder, models, demo set, pitch | `laura-guide` | `dashboard/src/guide/`, `assets/` (marker and models), the demo set, the README and video | Both apps load `assets/models/`; don't rename or resize a model without flagging |
| **Salman** `salman-abdulrazaq-ali` | The iPhone app | `salman-ios` | `ios/` | Speaks `contracts/protocol.ts` to the relay; loads the marker and USDZ models from `assets/` |

**Shared** (flag every edit): `contracts/*` and `fixtures/*` (Ahmed writes them, everyone builds on them), `dashboard/src/scene/api.ts`
(the seam between Max and Laura), `assets/models/` (loaded by both apps).

## How we work (read once)
- **Code from your own laptop, as yourself.** One branch each (`<name>-<area>`). Per feature: code and test → push
  your branch → `git merge origin/main` into it and re-test → merge to `main` → an entry here. Your Claude runs this
  as the `ship` skill.
- **Shared docs** (`CLAUDE.md`, `PROJECT.md`, `EVENT.md`, briefs, research, skills) are **never** committed to
  `main`. They live on the `context` branch. Edit, then `bash scripts/publish-context.sh "what changed"`,
  and every agent picks it up on its next prompt.
- **Deploy:** The relay runs on the dashboard laptop (Ahmed's is opened up in the demo), on the team hotspot, port 8080. No cloud. State in `relay/state.json` (git-ignored). Ask Ahmed to restart it.

## Latest
- **The volatile facts live here only:** the current commit, test counts, what's merged vs. local-only, and deploy
  status.
- **As of 2026-11-14 23:40:** `main` has the contract, fixtures and fakes, the relay (41 tests, type-check clean), the
  UNO Q rig code (13 tests, not yet run on its hardware), Laura's marker and six models, and `fixtures/video-test.html`.
  **Not on `main` yet:** the iPhone app (PR #4, draft), the dashboard and scene API (PR #6), the guide builder
  (`laura-guide`), Max's research answers (PR #1), Salman's board entries (PR #5). Relay deploy: the dashboard laptop
  from the demo on; Ahmed's until then.

---

### 2026-11-14 17:05 — team kit + repo scaffold — @ahmed
- Shipped: the Claude Code team flow from the IBM Z Datathon, generalised for any project. Setup, sync, publish and
  init scripts; commit hooks; the every-prompt Claude hook; the charter, project doc, event doc, brief and research
  templates; 16 skills. The `context` branch is seeded from `kit/`.
- Touched: everything (new repo)
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-14

### 2026-11-14 18:40 — Max, Laura and Salman added — @ahmed
- Shipped: keys `max`, `laura`, `salman` in `team.conf`; a brief for each on `context` (roles set at kickoff); rows in Who owns what. GitHub invites still to send.
- Touched: `team.conf`, `progress.md`, `builder-file-{max,laura,salman}.md` on `context`
- ⚠️ Conflicts: @max @laura @salman — once invited: clone, then `bash scripts/setup.sh <your key>` (Start here, step 1)
- Conflict status: open

### 2026-11-14 18:45 — teammates on GitHub — @ahmed
- Shipped: Max (`xaw1`), Laura (`furtunalaura`) and Salman (`salman-abdulrazaq-ali`) accepted their invites, with write access. Salman's login is in his brief and in Who owns what.
- Touched: `progress.md`, `builder-file-salman.md` on `context`
- ⚠️ Conflicts: @max @laura @salman — clone, then `bash scripts/setup.sh <your key>` (Start here, step 1)
- Conflict status: open

### 2026-11-14 19:00 — Remote Assist plan docs — @max
- Shipped: `docs/remote-assist/` with the idea (demo, pitch, challenge fit) and the planned architecture (components, calibration, message protocol). Plan only, no code; everything marked proposed is open for kickoff.
- Touched: `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`
- ⚠️ Conflicts: none
- Conflict status: resolved by @max 2026-11-14

### 2026-11-14 19:40 — Remote Assist plan: round-1 decisions — @max
- Shipped: `docs/remote-assist/` rewritten for the MSP setting (on-site user with an iPhone, remote MSP engineer on a dashboard) and stepped 3D animated guides. Quest and ISS framing moved to Parked.
- Touched: `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`
- Decision: iPhone native app, no Quest; expert builds the guide, live or ahead; built-in models plus cut-outs from the scan; preset animations; user taps Next; boxes stay alongside models. Decided by @max, needs team agreement at kickoff.
- 📨 To @ahmed: please add to PROJECT.md → Active tasks: "Pick and get the demo objects (unassigned)" and "Check we have a Mac with Xcode for the iPhone app".
- ⚠️ Conflicts: none
- Conflict status: resolved by @max 2026-11-14

### 2026-11-14 20:20 — plan agreed, work split four ways — @ahmed
- Shipped: every brief now has an owner area and ordered tasks; `PROJECT.md` has the pitch, the decisions and the
  open questions; `research/ledger.md` § 5 adds to Max's § 2 and § 3. Who owns what (above) is filled in.
- Touched: `progress.md`; on `context`: `PROJECT.md`, `CLAUDE.md`, all four briefs, `research/ledger.md`
- Decision: by Ahmed, on top of Max's round 1: printed-marker alignment; WebRTC live view from the start; cut-outs
  show on the phone as a box plus a built-in model; enter Neptune North, Accenture, Marshall Wace and RS; Scaniverse
  before Dawn; all four build in parallel against fake peers. Full records: `PROJECT.md` → Decision log.
- 📨 To @salman: you have the iPhone app (`ios/`). Start with marker detection on a real phone. Ahmed needs your
  pick of WebRTC library before signalling can be written.
- 📨 To @max: your research (ledger § 1–4) landed while this was being written, and it cuts against two of
  Ahmed's calls: cut-outs on the phone (you found RealityKit on iOS 27.2+ can draw splats) and live view (you
  recommend JPEG first). Both are in `PROJECT.md` → Pending as reopened, not changed. Talk to Ahmed.
- 📨 To @max: you have the dashboard's 3D view and the splats. Your two requests are in `PROJECT.md` → NOW. Laura
  needs `dashboard/src/scene/api.ts` from you before her guide builder can start.
- 📨 To @laura: you have the guide builder, the models, the demo set, the UNO Q rig and the pitch. Salman and Max
  need the printed marker from you before anything lines up. Yours is the longest list: say so if it's too much.
- 📨 To @max @laura @salman: Ahmed owes you `contracts/protocol.ts`, a sample guide and the fake peers. Until then
  use the draft in `docs/remote-assist/architecture.md`.
- ⚠️ Conflicts: @max @laura @salman — new tasks in your brief, and roles and decisions made without you in the room.
  Object here before building on them.
- Conflict status: open

### 2026-11-14 20:28 — UNO Q rig moves to Ahmed — @ahmed
- Shipped: Ahmed builds the UNO Q rig himself (`hardware/`), so it's off Laura's list. Briefs, `PROJECT.md` and Who
  owns what are updated. Ahmed also confirmed the phone app is native, built in Xcode.
- Touched: `progress.md`; on `context`: `PROJECT.md`, the briefs
- Decision: the UNO Q rig is Ahmed's, not Laura's (Ahmed).
- 📨 To @laura: the two UNO Q tasks are gone from your brief (archived at the bottom). Keep a spot on the demo set
  for the rig, and agree it with Ahmed before the set is scanned.
- 📨 To @max: `docs/remote-assist/open-questions.md` is out of step with `PROJECT.md`. Question 1 is decided (option
  B, the printed marker, by Ahmed). Questions 2 and 3 are still open between you and Ahmed: he chose the box-and-model
  stand-in and WebRTC before seeing your recommendations. Please update your file once you two have talked.
- 📨 To @salman: please check the Mac's Xcode version and the demo iPhone's iOS version, and post them.
- ⚠️ Conflicts: @laura — your brief changed (two tasks removed) | @max — your open-questions file disagrees with
  `PROJECT.md` on questions 1 to 3
- Conflict status: open

### 2026-11-14 20:30 — event rules and the Clock — @ahmed
- Shipped: `EVENT.md` and `PROJECT.md` → Clock are filled. **Devpost deadline: Sun 15 Nov, 12:00. Judges visit
  tables from 12:30.** Rules that bite: code must be written during the event, and AI tools must be credited on
  Devpost. Hall Wi-Fi is slow, so plan on a hotspot. All from one notes file, not yet checked against Devpost.
- Touched: on `context`: `EVENT.md`, `PROJECT.md`, `builder-file-ahmed.md`
- 📨 To @laura: nobody knows if the venue has a paper printer. The marker needs one, so find out early.
- 📨 To @max: Dawn access isn't mentioned in the event notes. Who offered it?
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-14

### 2026-11-14 20:45 — phone stack and protocol decisions — @ahmed
- Shipped: three decisions for the protocol, and `research/ledger.md` § 6 on which frame guide positions travel in.
- Touched: `progress.md`; on `context`: `PROJECT.md`, `builder-file-salman.md`, `research/ledger.md`
- Decision: by Ahmed: the phone app is **pure native Swift, no Expo**; the protocol contract is **TypeScript types
  only** (`contracts/protocol.ts`) plus JSON examples; live video **stays WebRTC**, with signalling over the relay
  websocket.
- 📨 To @salman: your Expo branches are superseded. Port `SonicArView.swift` into a plain Xcode project in `ios/`
  (your brief, task 1). Also post which printed edge the anchor's +x and +z point to (an axis marker on the anchor):
  the protocol depends on it. If you think Expo is the better call, say so here.
- 📨 To @max @laura: the dashboard imports `contracts/protocol.ts` with `import type`. It holds no runtime code.
- ⚠️ Conflicts: @salman — the phone stack changes under you (Expo out)
- Conflict status: open

### 2026-11-14 20:59 — the protocol contract is on main — @ahmed
- Shipped: `contracts/protocol.ts` (every websocket message, as TypeScript types), `fixtures/sample-guide.json` (a
  4-step SAMPLE guide), `fixtures/messages.json` (one example of every message) and `relay/validate.ts` (the relay's
  check of incoming messages). 15 tests and a type-check pass: `cd relay && npm install && npm test && npm run
  typecheck`. Commit `1fcc4c3`.
- Touched: `contracts/`, `fixtures/`, `relay/` (all new); on `context`: `PROJECT.md`, `CLAUDE.md`, four briefs
- Decision: by Ahmed: **positions travel in the marker's frame, in metres; the dashboard converts from splat
  coordinates and the phone does no maths.** The contract's shape (Ahmed, as proposed): steps and objects referred to
  by id; `guide.set` sends the whole guide; guides carry `rev` and the marker's printed size; calibration goes
  dashboard → relay only; `step.done` carries a unique `doneId` and the tap time; the UNO Q joins as a third role,
  `rig`; `hello` carries `protocol: 1`; a fixed list of model names; `presence` and `error` from the relay.
  `typescript` is a dev-only dependency of `relay/`.
- 📨 To @salman: the frame is at the top of `contracts/protocol.ts`. Pin objects to the image anchor straight from
  the JSON. Please check which printed edge +x and +z point to: they're marked provisional until you do.
- 📨 To @max: your dashboard converts splat → marker frame (brief task 3, rewritten). Max's draft differs in two
  places: ids instead of indexes, and the corners no longer go to the phone.
- 📨 To @laura: build the guide builder against `Guide` in the contract, with `import type`.
- ⚠️ Conflicts: @salman @max @laura — the contract you build on is now fixed; any change is flagged to all three
- Conflict status: open

### 2026-11-14 21:29 — the relay and the fakes are on main — @ahmed
- Shipped: `relay/relay.ts` routes every message by role, replays the guide, current step, calibration and progress
  to anyone who reconnects, and saves them to `relay/state.json` so a restart loses nothing. A heartbeat drops a
  phone that silently loses Wi-Fi from presence within about 10 seconds. `fixtures/fake-phone.ts` and
  `fixtures/fake-expert.ts` stand in for the phone and the dashboard. 31 tests and a type-check pass. Commit `97cde98`.
- Run it: `cd relay && npm install && npm start` (prints the `ws://` address to use). Fakes need only Node 24:
  `node fixtures/fake-expert.ts ws://<relay>:8080`, `node fixtures/fake-phone.ts ws://<relay>:8080`.
- Touched: `relay/`, `fixtures/`, `.gitignore`; on `context`: `PROJECT.md`, `CLAUDE.md`, four briefs
- Decision: by Ahmed: the `ws` package; state saved to a JSON file; plain `ws://` on the team hotspot; role rules
  with no login; keep the fakes.
- 📨 To @salman: plain `ws://` means one Info.plist setting, `NSAllowsLocalNetworking` (your brief, task 3). Test
  your app against `node fixtures/fake-expert.ts`.
- 📨 To @max @laura: test the dashboard against `node fixtures/fake-phone.ts`. It taps Next every 3 seconds and walks
  a camera pose round the marker. Its poses are SIMULATED: never demo them.
- ⚠️ Conflicts: none (all new files in Ahmed's area)
- Conflict status: resolved by @ahmed 2026-11-14

### 2026-11-14 21:31 — the printed marker is on main — @laura
- Shipped: `assets/marker/marker.png` (300 dpi), `marker-print-A4.pdf` (print sheet with a TOP mark and a 100 mm
  scale ruler) and `assets/marker/README.md`. Printed on matte paper and measured with a ruler: **180 mm × 180 mm**
  (outer black frame), so the guide's `marker` is `{ "name": "marker", "width": 0.18, "height": 0.18 }`. Random,
  asymmetric pattern, not a checkerboard, so ARKit can tell its corners and its orientation apart. Commit `eca6c24`.
- Touched: `assets/marker/` (new)
- ⚠️ Conflicts: @salman — add `marker.png` as an ARKit reference image at 0.18 m and check Xcode gives no warnings
  (that's what closes my task 1); the "TOP" edge on the sheet is upright for the +X/+Z check. @max — the marker is
  printed; the demo set it goes on isn't built yet. @ahmed — `fixtures/sample-guide.json` still says 0.16 m and
  `sample-marker`; fine for a SAMPLE, but the real guide needs 0.18.
- Conflict status: open (the @ahmed part resolved by @ahmed 2026-11-14 in `f28411b`)

### 2026-11-14 21:34 — sample guide sized for the printed marker — @ahmed
- Shipped: `fixtures/sample-guide.json` and the example `guide.set` in `fixtures/messages.json` now use Laura's
  marker: `{ "name": "marker", "width": 0.18, "height": 0.18 }`. Still labelled SAMPLE; positions unchanged.
  Commit `f28411b`.
- Touched: `fixtures/sample-guide.json`, `fixtures/messages.json`
- ⚠️ Conflicts: @salman — if you bundled the sample guide or decode `messages.json` in a test, pull again
- Conflict status: open

### 2026-11-14 21:47 — RS kit complete — @ahmed
- Shipped: the RS challenge's mandatory kit is in hand: the Arduino UNO Q, the **Nicla Vision as the camera** (the
  RS staff confirmed it counts) and a USB-C hub. Next: research how the Nicla, the UNO Q and the relay connect.
- Touched: on `context`: `PROJECT.md`, `EVENT.md`, `builder-file-ahmed.md`
- Decision: the RS camera is the Nicla Vision (Ahmed; RS staff confirmed).
- 📨 To @laura: the rig is the UNO Q plus the Nicla Vision, both small. Keep a spot on the set where the Nicla can see
  the patch panel's ports.
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-14

### 2026-11-14 21:54 — the UNO Q rig is planned, and guides can say what it should see — @ahmed
- Shipped: `contracts/protocol.ts` gains an optional `expect: { port, cable: "in" | "out" }` on guide objects, checked
  by the relay; the sample guide's cable steps carry it. Additive: older readers ignore it. 32 tests and a type-check
  pass. Commit `29bafd3`. Plan and research for the rig: `research/ledger.md` § 10.
- Touched: `contracts/protocol.ts`, `relay/validate.ts`, `fixtures/`; on `context`: `PROJECT.md`, three briefs,
  `research/ledger.md`
- Decision: by Ahmed: the Nicla Vision finds the cable by colour, one region per port; USB through the hub to the UNO
  Q; the UNO Q joins the relay as `rig` with `websocket-client` and shows ✓/✗ on its LED matrix; the `expect` field.
- 📨 To @laura: the cable that moves needs a brightly coloured plug boot, and your guide builder can set `expect` on
  cable steps (your brief, tasks 2 and 3).
- 📨 To @salman: `expect` is optional; your Swift decoder can ignore it.
- 📨 To anyone: the rig needs a micro-USB **data** cable for the Nicla Vision. Got one? Tell Ahmed.
- ⚠️ Conflicts: @laura @salman @max — an additive change to the contract you build on
- Conflict status: open


### 2026-11-14 22:15 — dashboard stack picked, splat on screen — @max
- Shipped: research in `research/ledger.md` § 7 (splat renderer), § 8 (dashboard shell), § 9 (training splats on
  the DGX Spark). `dashboard/` scaffolded on `max-scene` (`49342b3`, not merged yet): Vite + React, the scene in
  plain three.js + Spark 2.4 behind `dashboard/src/scene/`. Shows Spark's SAMPLE splat, or a dropped .spz/.ply.
  Run: `cd dashboard && npm install && npm run dev` · test: `npm test && npm run typecheck`.
- Touched: `dashboard/` (new, branch `max-scene`); on `context`: `research/ledger.md`
- Decision: by Max: Spark on three.js, proven by a short spike with a kill test (30 fps or more on the weakest laptop,
  a click-pick under 300 ms, a cut-out under 2 s), PlayCanvas only if it fails; Vite 8 + React 19 + TypeScript,
  plain three.js behind `scene/api.ts`, no React Three Fiber, a shared zustand store when one is needed.
- 📨 To @ahmed: we have a DGX Spark, not Dawn access. Max's task 9 should read "train the set's splat on the DGX
  Spark" (ledger § 9 has the pipeline). Please also fill Stack in `CLAUDE.md` with the dashboard line above. *(done by @ahmed 2026-11-14 22:20)*
- 📨 To @laura: the dashboard is React, so your guide builder is React components. `scene/api.ts` is next; I'll
  flag it here for you to agree before you build on it.
- ⚠️ Conflicts: @laura — the app shell you build inside is now fixed (React)
- Conflict status: open

### 2026-11-14 22:40 — scene API for the guide builder, PR open — @max
- Shipped: `dashboard/src/scene/api.ts` (what the guide builder can ask the 3D view, types only) and
  `docs/remote-assist/scene-api.md` (why, and what's open), on `max-scene`. PR:
  https://github.com/meep-boop/durhack-2026-team-sonic/pull/6 (not merged). 8 dashboard tests, relay's 32 still pass.
- Touched: `dashboard/` (new), `docs/remote-assist/scene-api.md` (new)
- Decision: by Max: the guide builder keeps the only copy of the guide and hands the 3D view a whole step; the 3D view
  reports edits back. Alternative not picked: both halves keep a copy and send changes one at a time (two copies can
  drift apart).
- Decision: **not decided** (Max + Ahmed, after calibration works): what happens before the marker is calibrated:
  block placing until calibrated, or place in scan coordinates and convert later. Only `dashboard/src/scene/` changes
  either way. Please add it to `PROJECT.md` → Pending. *(done by @ahmed 2026-11-14 22:27)*
- 📨 To @laura: read `api.ts` and `scene-api.md`, and say here if anything is missing. Your guide builder sends the
  3D view the step's `GuideObject[]` and listens for moves and clicks; it never converts positions.
- ⚠️ Conflicts: @laura — `dashboard/src/scene/api.ts` is the seam with `dashboard/src/guide/`; agree it before
  building on it
- Conflict status: open

### 2026-11-14 22:27 — the UNO Q rig's code is on main, not yet on hardware — @ahmed
- Shipped: `hardware/nicla/main.py` (the Nicla prints which ports hold the coloured cable) and `hardware/unoq/` (the
  UNO Q app joins the relay as `rig`, follows the guide, and sends `step.verified` for steps with `expect`; a cable in
  the wrong port warns, the right one ticks). 13 rig tests; end to end through the real relay with typed-in Nicla
  lines it reported "cable in port 16, expected 17", then "correct". Commit `4db2ce6`. How to run: `hardware/README.md`.
- Not done yet: running it on the Nicla and the UNO Q (the regions and colour in the Nicla script are examples), and
  the ✓ / ✗ on the LED matrix.
- Touched: `hardware/` (new); on `context`: `PROJECT.md`, `CLAUDE.md`, `builder-file-ahmed.md`
- 📨 To @max @laura @salman: if the rig is running, `step.verified` arrives for steps with `expect`. `ok: false` comes
  with a `detail` like "cable in port 16, expected 17" to show the user.
- ⚠️ Conflicts: none (new files in Ahmed's area)
- Conflict status: resolved by @ahmed 2026-11-14


### 2026-11-14 22:30 — the six built-in models are on main — @laura
- Shipped: `assets/models/{screw,bolt,arrow,screwdriver,hand,cable-plug}.{glb,usdz}`, built from one source by
  `assets/models/build_models.py`, so glTF and USDZ hold identical geometry. Low poly, one orange material, no
  textures: every file is under 7 KB. 7 tests check the names against `ModelName`, tip at origin, sizes, outward
  faces, glb/usdz parity and USD's package checks: `python -m unittest discover assets/models` (needs `usd-core`,
  rebuild only; neither app depends on it). Commit `3ab2d07`.
- Touched: `assets/models/` (new)
- Decision: by Laura: **model conventions**: metres, +Y up, the working tip (screw point, arrow point, fingertip,
  plug contacts) at the origin, each model rising along +Y from it, so with an identity `rot` the arrow points
  straight down at `pos`; `pull` = +Y, `push` = -Y, `unscrew` spins around Y. Also by Laura: commit the build
  script so anyone can rebuild (dev-only dependency `usd-core==26.11`). Details: `assets/models/README.md`.
- 📨 To @ahmed: please fold the conventions into `PROJECT.md` and the `ModelName` comment in the contract.
- ⚠️ Conflicts: @salman — load the `.usdz` files as-is and place each model's origin at `pos`; tell me if RealityKit
  shows them the wrong size or way up. @max — same for the `.glb` files in the scene; the tip, not the centre, sits
  at `pos`.
- Conflict status: open

### 2026-11-14 23:03 — the demo is now an SSD swap on Ahmed's laptop — @laura
- Shipped: no code. Records a team decision that changes several tasks.
- Touched: nothing yet
- Decision: by the whole team (Ahmed, Max, Salman, Laura): the demo set is **Ahmed's laptop, and the guide walks
  the user through replacing its SSD**, instead of a network cabinet. The marker is taped to the same board as the
  laptop, next to the SSD cover, so the two can't move apart.
- 📨 To @ahmed: please (1) update `PROJECT.md` and the briefs (my task 2 is now "fix the laptop and the marker to one
  board", and the coloured cable boot is no longer needed); (2) add `"ssd"` to `ModelName` in
  `contracts/protocol.ts`, and I'll build `ssd.glb`/`ssd.usdz` with the same conventions as the other six
  (`cable-plug` and `bolt` stay, just unused for now); (3) decide what the UNO Q rig checks now that there's no cable,
  since `expect: { port, cable }` no longer fits. Suggestion: back up the laptop first, and in the demo take its own
  SSD out and put the same one back, so it still boots.
- 📨 To @max: the splat to scan is the laptop on its board (laptops are dark and shiny, so expect a harder scan than
  the cabinet).
- 📨 To @salman: the marker sits on a board beside the laptop, not on equipment; nothing changes in the app.
- ⚠️ Conflicts: @ahmed — the `expect` field and the rig's port regions; @max @salman — the demo scene changes
- Conflict status: open

### 2026-11-14 23:04 — review of the scene API (PR #6) — @laura
- Shipped: no code. Reviewed `dashboard/src/scene/api.ts` and `docs/remote-assist/scene-api.md` at `6a6753b`
  against my task 3. The one-copy design works for the guide builder: agreed.
- Touched: nothing
- 📨 To @max: four asks before I build on it:
  1. How `dashboard/src/guide/` gets the `SceneApi` instance, and where the guide panel mounts in the shell
     (`main.tsx` renders only `<Viewport />` today). This one blocks me.
  2. `pickPoint()` also returns the surface normal, so a new model's +Y can point out of the surface. The models
     stand on their tip and rise along +Y (`assets/models/README.md`); without a normal every new arrow points
     straight down, even at the side of the laptop.
  3. A calibrated flag plus a change event, so Send can block or warn until positions are in the marker frame. Your
     notes say pre-calibration positions are wrong on a real phone; this keeps a wrong guide away from the demo.
  4. If highlight boxes are resizable in 3D, report `size` in `onObjectMoved` too (it only carries `pos` and
     `rot`); otherwise I'll edit sizes as numbers.
  Smaller: what calls made before the splat has loaded do (ideally nothing), and how a cut-out's id reaches the guide
  builder (your task 5).
- ⚠️ Conflicts: @max — asks against `dashboard/src/scene/api.ts` (yours); nothing changed on my side
- Conflict status: open

### 2026-11-14 23:35 — open questions brought up to date, with sources — @max
- Shipped: `docs/remote-assist/open-questions.md` on `max-docs` (PR https://github.com/meep-boop/durhack-2026-team-sonic/pull/1, not merged). Questions 1–4 now show what Ahmed decided (marker, WebRTC, Scaniverse; cut-outs reopened); six new answered questions (splat renderer, dashboard stack, scan apps, video to mesh, splat to mesh, phone to DGX Spark), 57 source links, all checked. Research behind it: `research/ledger.md` § 7–15.
- Touched: `docs/remote-assist/open-questions.md` (Max's)
- 📨 To @ahmed: this answers your 20:28 ask: the file now matches `PROJECT.md` on questions 1–3. Cut-outs (2) stays reopened between us. Also: the DGX Spark can make a textured mesh from an iPhone video (question 8); scanning your laptop will need it made matte first (a vanishing scan spray), so ask before anyone sprays it.
  - **Correction (2026-11-14 23:55, @max):** the spray line above was Claude's research note, wrongly written as
    Max's request. Max didn't ask for it and nothing is planned. It's one weak-evidence option for shiny surfaces;
    soft lighting may be enough, and nobody has tried scanning the laptop yet.
- ⚠️ Conflicts: none (docs in Max's area)
- Conflict status: resolved by @max 2026-11-14

### 2026-11-14 23:40 — task sweep: every brief updated, and five new decisions — @ahmed
- Shipped: every brief brought up to date from this board, the open PRs and the branches (Salman's `salman-ios` and
  `salman-board`, Max's `max-scene` and `max-docs`, Laura's `laura-guide`). Code since my last entry, all on `main`:
  offline resync (`32ff3e8`), the video test page (`03827d1`, now the dashboard calls, `6afbfa5`), Claude labelling
  (`63b4be1`), the rig and the sample guide reworked for the SSD swap (`b3a2d0f`). 41 relay tests and 13 rig tests pass.
- Slip: `6afbfa5` was committed straight to `main` instead of through `ahmed-relay` first. Tests passed first;
  noted so nobody copies it.
- Touched: on `context`: `PROJECT.md`, `CLAUDE.md`, `EVENT.md`, all four briefs
- Decision: by Ahmed: the expert calls the phone (reverses "the phone offers"); `expect` is `{ region, present }` with a
  sticker on the SSD; the relay runs on the dashboard laptop in the demo; Salman's Gemini and ElevenLabs extras stay,
  entered for MLH; the Clock's 02:00 / 07:00 / 10:00 / 11:30; nobody sprays the laptop. Also logged: the offline rule,
  Claude labelling, motion along `axis`. Folded in: the team's SSD swap (Laura), Laura's model conventions, Salman's
  WebRTC library.
- 📨 To @salman: four new items at the top of your brief. Mirror `expect: { region, present }` (a struct that
  requires `port` and `cable` now fails to decode the sample guide); keep the phone's own place on reconnect; merge
  PR #4 before the walking skeleton; post the +X/+Z edges. Your 22:10 and 23:25 entries are only on `salman-board`:
  put board entries straight on `main`.
- 📨 To @max: run the relay on the dashboard laptop for the demo (your brief, item A, with Ahmed); merge PR #6 before
  the walking skeleton; the labels are `labels.request` / `labels.result` in the contract (task 7).
- 📨 To @laura: task 2 is now the laptop and marker on one board, plus a bright sticker on the SSD for the rig. Add
  `"ssd"` to `ModelName` and to `MODELS` in `relay/validate.ts` in the same commit as the model files. The expert
  calls the phone, and Salman's `ios/expert-call/` is the base for your video panel.
- ⚠️ Conflicts: @salman — `expect` changed shape, and phones no longer get the current step on reconnect | @laura —
  `ModelName` and `relay/validate.ts` to edit with the `ssd` model | @max — the relay moves to the dashboard laptop
- Conflict status: open

### 2026-11-15 00:51 — the UNO Q rig as an App Lab app, with ✓ / ✗ on its LED matrix — @ahmed
- Shipped: `hardware/unoq/` now mirrors an App Lab app: `python/` (`main.py`, `rig.py`, and `requirements.txt` beside
  them, where App Lab looks) and `sketch/sketch.ino`, which draws a tick or a cross for the current step. In App Lab,
  set `RELAY_URL` at the top of `main.py`. The same file still runs over SSH or on a laptop, without the matrix. 13
  rig tests; the chain end to end through the relay; the App Lab path checked against a stand-in module. Not yet on
  the board. Commit `3b4fd51`. Research: `research/ledger.md` § 16.
- Touched: `hardware/` (Ahmed's); on `context`: `builder-file-ahmed.md`, `CLAUDE.md`, `research/ledger.md`
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-15

### 2026-11-15 00:54 — pre-check of PR #4 (iPhone app) and PR #6 (dashboard) against today's main — @ahmed
- Shipped: no code. Merged today's `main` into throwaway copies of both branches (theirs untouched) and checked them.
  **PR #6 (`max-scene`):** no conflicts; 8 tests, the type-check and the production build pass: ready to merge.
  **PR #4 (`salman-ios`):** no conflicts, but four things break against `main`: read from the code, not compiled.
- Touched: nothing in the repo; on `context`: `builder-file-salman.md`, `builder-file-max.md`
- 📨 To @salman: the list is under item A in your brief. The one that matters for the walking skeleton: `struct
  Expect` still requires `port` and `cable`, so the sample guide and any guide with the new `expect` won't decode on
  the phone. Also the old-sample assertions in `GuideDecodingTests`, the two new `labels.*` messages in
  `MessageCodingTests`, and the current step not surviving an app restart.
- 📨 To @max: PR #6 is clean against `main`; merge it with the `ship` skill when Laura's ask 1 is answered, or before
  if the walking skeleton needs it.
- ⚠️ Conflicts: @salman — his app won't decode today's sample guide until `Expect` changes
- Conflict status: open

### 2026-11-15 00:57 — an ssd model, and ssd in the contract — @laura
- Shipped: `assets/models/ssd.glb` and `ssd.usdz` (M.2 2280, 22 × 80 mm, 72 triangles, under 6 KB), plus `"ssd"` in
  `ModelName` (`contracts/protocol.ts`) and in `MODELS` (`relay/validate.ts`), all in one commit so `main` stays
  green. Same conventions as the others: the contact edge (with its notch) at the origin, the card rising along +Y,
  chips on +Z, so `pull` slides it out of its slot. It lies flat in the laptop, so a guide object needs a 90° turn.
  Model tests 7/7, relay 41/41 and its type-check pass. Commit `61a771e`, with Ahmed's OK to edit his two files.
- Touched: `assets/models/`, `contracts/protocol.ts`, `relay/validate.ts`
- 📨 To @salman: add `case ssd = "ssd"` to `ModelName` in `ios/RemoteAssist/Protocol/Protocol.swift` (and a shape in
  `AR/Shapes.swift` if it switches over every model), or a guide with an SSD step won't decode.
- 📨 To @max: `ssd.glb` is next to the others in `assets/models/`; nothing else changes for the scene.
- ⚠️ Conflicts: @salman — a new `ModelName` case his decoder must accept | @ahmed — his two files, edited as agreed
- Conflict status: open

### 2026-11-15 01:00 — owner sweep: the ssd model, and Salman's newer branch — @ahmed
- Shipped: no code. Laura's `ssd` model and contract change (`61a771e`) checked: relay validation matches the
  contract. `salman-ios-polish` (`820423b`) already fixes items 1–3 of the 00:54 pre-check and has `case ssd`, and
  it merges cleanly with `main`. Not compiled: read from the code. Still open: the current step doesn't survive an app
  restart (Salman's item B).
- Touched: nothing in the repo; on `context`: `builder-file-salman.md`, `builder-file-ahmed.md`
- 📨 To @salman: for the walking skeleton, merge `salman-ios-polish` (it carries PR #4), not `salman-ios` on its own.
- ⚠️ Conflicts: none (Laura's edit to `contracts/protocol.ts` and `relay/validate.ts` was agreed and is fine)
- Conflict status: resolved by @ahmed 2026-11-15

### 2026-11-15 01:45 — a plan to the deadline, after reading every branch — @ahmed
- Shipped: no code. The phone is nearly complete but not on `main`; the dashboard is a splat viewer that can't talk
  to the relay, so the 02:00 walking skeleton was missed. The plan is a ladder: rung 0 the real phone plays a
  prepared guide, rung 1 the dashboard sends it, rung 2 a guide built in the scan lines up, rung 3 the extras. Each
  brief has an ordered block at the top of its tasks. Max is now a second docs owner.
- Touched: `team.conf`; on `context`: all four briefs, `PROJECT.md`, `CLAUDE.md`
- Decision (Ahmed): taps get a receipt from the relay; two scans with a calibration each; Salman's call page is the
  call screen; cut-outs and 3D dragging stay, after rung 2; the Clock is unchanged.
- 📨 To @max: merge PR #6 now. Ahmed asks your OK to build `dashboard/src/relay/client.ts` and
  `dashboard/src/scene/calibration.ts`; reply here or tell him. You can now publish any shared doc.
- 📨 To @salman: merge `salman-ios-polish` and run the smoke test in your brief before more extras. The tap receipt
  needs a small change in `RelayClient`, after the relay side lands. Your `chat` message waits for Ahmed's decision.
- 📨 To @laura: the board first, with corner stops (the laptop is Ahmed's only machine). Post the real SSD-swap
  steps. No video panel: Salman's page covers it.
- ⚠️ Conflicts: @max — two new files proposed in `dashboard/` | @salman — the receipt changes when a tap leaves his
  outbox | @laura — her task 5 is superseded
- Conflict status: open

### 2026-11-15 01:47 — taps get a receipt from the relay — @ahmed
- Shipped: the relay sends each `step.done` back to the phone that sent it, once saved; a repeat gets one too and is
  still forwarded only once. `fixtures/fake-phone.ts` keeps a tap queued until its receipt and resends the queue on
  reconnect: the reference for the app. 41 relay tests pass. Commit `8756560`.
- Touched: `relay/relay.ts`, `contracts/protocol.ts` (comment only, no shape change), `fixtures/fake-phone.ts`
- 📨 To @salman: in `RelayClient`, remove a tap from the outbox when its `step.done` comes back (match `doneId`), not
  when the send completes, and resend the whole outbox in order on reconnect. Older builds just ignore the echo.
- ⚠️ Conflicts: @salman — the phone now receives its own `step.done`; harmless until he uses it
- Conflict status: open

### 2026-11-15 01:47 — the relay keeps one calibration per scan — @ahmed
- Shipped: `calib.set` is now kept per `splatId` (the scan's file name) and every one is replayed to a dashboard
  that connects, so the closed scan and the cover-off scan each keep their own. The message shape is unchanged. An
  older `relay/state.json` still loads. 41 relay tests pass. Commit `b9a5e86`.
- Touched: `relay/relay.ts`, `contracts/protocol.ts` (comment only)
- 📨 To @max: send one `calib.set` per scan with its file name as `splatId`; on connect you get them all back.
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-15
