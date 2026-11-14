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
   Not in `team.conf` yet? Ask a docs owner (ahmed) to add your key and brief.
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
| **Max** `xaw1` | Dashboard 3D view and the splats | `max-scene` | `dashboard/src/scene/`, the `dashboard/` shell, `splats/`, `pipeline/`, `docs/remote-assist/` | The guide builder calls `dashboard/src/scene/api.ts` |
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
- **Deploy:** The relay runs on the laptop that starts it (Ahmed's for now), on the team hotspot, port 8080. No cloud. State in `relay/state.json` (git-ignored). Ask Ahmed to restart it.

## Latest
- **The volatile facts live here only:** the current commit, test counts, what's merged vs. local-only, and deploy
  status.
- **As of 2026-11-14 18:45:** `main` has the team kit, and the `context` branch is seeded. Kit tests are
  green locally (`test-context-scripts.sh`, `test-git-hooks.sh`). No project code yet. All four of us have repo access.

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


### 2026-11-14 22:10 — iPhone app runs on a phone and talks to the relay; call library picked — @salman
- Shipped (branch `salman-ios`, PR #4, draft): the native app in `ios/` (SwiftUI + ARKit/RealityKit, XcodeGen). Tracks
  Laura's `assets/marker/marker.png` at 0.18 m under world tracking with one tracked image, and draws an outline plus
  an axis marker. Plays the sample guide pinned to the marker frame with Next. Relay client (task 3): `hello` as
  user, `guide.set`/`step.set` in, `step.done` queued and sent in order, marker-frame `pose` about 5 Hz, reconnect.
  Every example in `fixtures/messages.json` decodes in the tests (5 passing). Runs on an iPhone 16, **iOS 26.3.1**,
  built with **Xcode 26.0.1**.
- Touched: `ios/` (all new)
- Decision: by Salman: **accept pure native Swift** and the phone role; Expo PRs #2 and #3 can be closed. **WebRTC
  library: Google's WebRTC framework** (`stasel/WebRTC` Swift package), peer-to-peer on the hotspot, signalling over
  the existing `rtc.signal`. Next: two-way audio plus the phone's AR camera to the expert (task 4).
- Still owed from task 1: the +X/+Z printed edges and the offset in mm, once checked on the printed marker.
- 📨 To @max: I'm building a small standalone expert call page in `ios/expert-call/` (live camera plus two-way voice)
  so task 4 can be tested tonight. Lift its code into your dashboard's video panel whenever you like.
- 📨 To @ahmed @laura @max: **proposal, not decided**: make the demo a nervous person swapping the **SSD in a
  laptop** alone. The phone identifies the laptop (Gemini), builds the steps, points at each screw, checks the work,
  and reads every step aloud (ElevenLabs), with the expert on call. It changes Laura's set and the rig's port check, so
  it needs your OK.
- 📨 To @ahmed: **proposal**: also enter the MLH prizes (Gemini, ElevenLabs, Vultr, Tiger Data). Your area if you
  want them: host the relay on Vultr (works beyond the hotspot) and log `step.done`/`pose` to Tiger Data. Also from a
  security review: plain `ws://` with no auth lets anyone on the network push a guide; a shared team code in `hello`
  would close it (a contract change, your call).
- ⚠️ Conflicts: @ahmed @laura @max — the demo-scope and prize proposals above | @max — the call page overlaps your
  dashboard's future video panel
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
- ⚠️ Conflicts: none (docs in Max's area)
- Conflict status: resolved by @max 2026-11-14

### 2026-11-14 23:25 — iPhone app: live call, models, rig verdict, AR stays when covered — @salman
- Shipped on `salman-ios` (PR #4, still draft; builds for a device, not yet merged): the expert can **call the phone**
  (Google WebRTC: the AR camera and two-way audio, signalling over `rtc.signal`); `ios/expert-call/` is a standalone
  expert page for it. The guide now sits on a **world anchor**, so a hand over the marker no longer hides it; hands are
  drawn in front of the boxes. Laura's six USDZ models load and loop their action along `axis`. The rig's
  `step.verified` shows ✓ or the `detail` on the step card. `expect` is mirrored. Optional Gemini laptop assistant and
  ElevenLabs voice (keys stay in a git-ignored file). Setup: `ios/README.md`.
- Touched: `ios/` only
- 📨 To @max: `ios/expert-call/index.html` is the expert side of the call in plain JS (offer, `rtc.signal`, a data
  channel for hang-up). Lift it into your dashboard's video panel when you're ready.
- 📨 To @laura: your models load in RealityKit as they are; I'll report size and up-direction once seen on the phone.
- ⚠️ Conflicts: @max — the call page overlaps your future video panel
- Conflict status: open
