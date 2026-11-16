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
**Sonic Assist** (working name was Remote Assist). Step-by-step 3D guidance on a phone, built by a remote engineer from a scan of the room, that keeps working when the network is down. The plan: `docs/remote-assist/`.

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
- **As of 2026-11-15 03:55:** `main` (`aa6d177`) has the contract, fixtures and fakes, the relay (41 tests, type-check clean), the
  UNO Q rig and Nicla code, Laura's marker and seven models, the dashboard (54 tests, type-check and build clean:
  Max's scene with splat and mesh scans, calibration, steps, the phone's position, AI labels, dragging, the header
  with relay / phone / rig lights and the live strip; Laura's guide panel; Ahmed's relay client), and the first scan (`dashboard/public/scans/`, no marker: reference only).
  **Not on `main` yet:** the iPhone app (`salman-ios-polish`, `salman-ios-ar`), Max's research answers (PR #1),
  Salman's board entries (PR #5). Relay deploy: Max's laptop, port 8080.

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

### 2026-11-14 20:30 — Remote Assist plan: round 2 and research — @max
- Shipped: `docs/remote-assist/open-questions.md` for the hard problems (lining up the scan with the room, splat cut-outs on the iPhone, live camera). Researched the last two: iOS 27 RealityKit can draw splats natively; JPEG frames over the relay is the cheapest live video. Research is in `research/ledger.md` § 1–2 on `context`. On branch `max-docs`, by pull request.
- Touched: `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`, `docs/remote-assist/open-questions.md`, `research/ledger.md` (context)
- Decision: @salman's MacBook builds the iPhone app; prepared guides come before live guide-building. Decided by @max.
- 📨 To @salman: @max needs your MacBook ready for iPhone builds before the phone app starts: Xcode 27, Apple ID signed in, the demo iPhone on iOS 27.2+ running a test app.
- ⚠️ Conflicts: @salman — plan assumes your MacBook for every iPhone build
- Conflict status: open

### 2026-11-14 21:15 — Remote Assist plan: unknowns researched, working defaults set — @max
- Shipped: researched alignment (printed marker + ARKit poses recorded during the scan) and the scan pipeline (Scaniverse first, Dawn as stretch; cut-outs via Spark's CPU API, exported as PLY for RealityKit). Set working defaults for open questions 1–4; added open question 4. Ledger § 3–4 on `context`. Via PR on `max-docs`.
- Touched: `docs/remote-assist/open-questions.md`, `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`, `research/ledger.md` (context)
- Decision: working defaults (not confirmed by the team): marker + ARKit poses for alignment; RealityKit splats with a stand-in fallback; JPEG over the relay, LiveKit later; Scaniverse first. @max asked for defaults over more questions.
- 📨 To @ahmed: please add "Ask the organisers whether DurHack teams can get Dawn access" to PROJECT.md → Active tasks.
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

### 2026-11-15 01:51 — no text chat — @ahmed
- Shipped: nothing. The `chat` message proposed in PR #7 stays out of the contract and the relay.
- Touched: on `context`: `PROJECT.md` (Parked), `builder-file-salman.md`
- Decision (Ahmed): the team doesn't want chat; the call carries voice.
- 📨 To @salman: please remove the chat screen from the app and from `ios/expert-call/` before PR #7 merges. The
  relay answers `chat` with an error.
- ⚠️ Conflicts: @salman — his chat UI in PR #7 has no relay behind it
- Conflict status: open

### 2026-11-15 01:58 — the dashboard's relay connection and calibration maths, on a branch — @ahmed
- Shipped: on `ahmed-dashboard` (`dbb708a`), cut from `max-scene` with `main` merged in, **not on `main`**: it
  waits for PR #6. `dashboard/src/relay/client.ts`: `connectRelay({ url })` says hello as an expert, reconnects,
  and gives `send`, `on(type, listener)`, `onStatus`. `dashboard/src/scene/calibration.ts`:
  `solveCalibration(corners, marker)` returns the marker→scan matrix (for `Matrix4.fromArray`), the scale and the
  residual in metres. 14 dashboard tests and the type-check pass; the client is tested against the real relay and
  the fake phone. Assumes +X along the marker's top edge and +Z down the print, until Salman confirms.
- Touched: `dashboard/src/relay/` (new), `dashboard/src/scene/calibration.ts` (new, with Max's OK via Ahmed)
- 📨 To @max: merge PR #6, then merge `ahmed-dashboard` (or pull it into `max-scene`). `send` returns false while
  the link is down; re-send the latest guide when the status returns to "connected".
- 📨 To @laura: your panel gets a `RelayClient`: `relay.send(guideSetMessage(guide))`, `relay.on("step.done", …)`.
- ⚠️ Conflicts: @max — two new files in his folder, agreed
- Conflict status: open

### 2026-11-15 02:11 — the real SSD-swap steps for Ahmed's Latitude 5530 — @laura
- Shipped: the step list for `fixtures/ssd-swap-guide.json` (rung 0), from Dell's Latitude 5530 service manual
  (`research/ledger.md` § 17) and **checked on Ahmed's laptop: 8 captive screws on the base cover, no bracket over
  the SSD, 1 screw on the SSD**. Same SSD out and back in, so it still boots. Tools: #0 Phillips, a plastic pry tool.
  | # | Text | Objects (model, action) | `expect` |
  |---|---|---|---|
  | 1 | Save your work, shut down, and unplug the charger and anything else. | hand on the charger port, pull | |
  | 2 | Hold B and press the power button for 3 seconds. After 3 beeps it switches off in Service Mode, with the power cut. | hand on the power button, push | |
  | 3 | Close the lid and lay the laptop face down in the board's corner stops. | hand, flip | |
  | 4 | Loosen the 8 screws on the base cover with a #0 Phillips. They stay in the cover. | 8 × screw, unscrew; screwdriver | |
  | 5 | Lift the cover at the U-shaped notches on the top edge with a plastic pry tool. | arrow at the notches; hand, pull | |
  | 6 | Hold the left and right sides and lift the cover off. | hand, pull | |
  | 7 | Undo the one screw that holds the SSD. | screw, unscrew | |
  | 8 | Slide the SSD out of its slot at an angle. | ssd, pull | `{ region: "ssd-bay", present: false }` |
  | 9 | Slide the same SSD back in at the same angle and press it flat. | ssd, push | `{ region: "ssd-bay", present: true }` |
  | 10 | Put the SSD's screw back. | screw, push | |
  | 11 | Snap the cover back on and tighten the 8 screws. | 8 × screw, push | |
  | 12 | Plug the charger in (this ends Service Mode), then turn the laptop on. | hand on the charger port, push | |
- Notes: steps 1–3 happen before the laptop sits on the board, so their objects can't line up with the marker: text
  only is fine there. For the video, steps 4–9 carry the demo. The `ssd` model lies flat in the laptop: rotate it 90°.
- Touched: nothing in the repo; on `context`: `research/ledger.md` § 17
- 📨 To @ahmed: turn this into `fixtures/ssd-swap-guide.json` with ruler-measured positions from the marker. Still
  to check: which of the two M.2 slots holds the SSD (for the Nicla's `ssd-bay` region).
- ⚠️ Conflicts: none
- Conflict status: resolved by @laura 2026-11-15

### 2026-11-15 02:15 — where the SSD sits in Ahmed's laptop — @laura
- Shipped: no code. Checked on the laptop: the SSD is in the **M.2 slot next to the fan**. That's where the Nicla's
  `ssd-bay` region goes, and where step 7–10's objects sit in `fixtures/ssd-swap-guide.json`.
- Touched: on `context`: `research/ledger.md` § 17
- 📨 To @ahmed: point the Nicla at the slot next to the fan; a photo of the open laptop is coming if you need one.
- ⚠️ Conflicts: none
- Conflict status: resolved by @laura 2026-11-15
### 2026-11-15 02:16 — the dashboard's scene can calibrate a scan and draw a step — @max
- Shipped: PR #6 merged, then `ahmed-dashboard` (relay client, calibration maths), then the scene work, all on `main`
  at `0fddd63`. `App.tsx` makes one scene and one relay link (`?relay=ws://…`, default the page's host on 8080) and
  leaves a slot for `<GuidePanel scene relay />`. Scans load from git-ignored `dashboard/public/scans/` with
  `?closed=<file>&open=<file>` (the file name is the scan's id, so a rescan needs a new name). Calibration: four
  corner clicks, refused above 5 mm, sent as `calib.set`, and restored from the relay on reload. `pickPoint()` returns
  marker metres; `showStep()` draws boxes centred on `pos` and the glTF models (tip at `pos`); `select`, `focus`,
  click-to-select and `previewAction` work. Checked in the browser against a relay on the SAMPLE splat (a pick at the
  marker centre came back within 1 mm of the origin); not yet on a real scan of the set.
- Touched: `dashboard/` (all Max's), `.gitignore` (one line, `dashboard/public/scans/`)
- Decision (Max): nothing can be placed until the scan on screen is calibrated: `pickPoint()` resolves to null and
  objects aren't drawn. Answers the open question in `docs/remote-assist/scene-api.md`.
- 📨 To @laura: ask 1 answered: mount `<GuidePanel scene={scene} relay={relay} />` in the slot in
  `dashboard/src/App.tsx` (the comment marks it). Ask 3 is in `SceneApi`: `isCalibrated()` and
  `onCalibrated(listener)`. Asks 2 and 4 aren't needed (objects turn only about Y). `onObjectMoved` doesn't fire
  until dragging lands.
- 📨 To @ahmed: your two files are merged and in use. Something on this laptop already listens on port 8080 (a node
  process); I'll clear it before the demo.
- ⚠️ Conflicts: @laura — `api.ts` gained two calls, and `App.tsx` is where her panel mounts | @salman — the dashboard
  assumes +X along the marker's top edge and +Z down the print until his axis check
- Conflict status: open (Laura's part resolved by @laura's 02:22 mount; Salman's axis check still open)

### 2026-11-15 02:22 — the guide panel is on main — @laura
- Shipped: `dashboard/src/guide/GuidePanel.tsx` in Max's shell (`App.tsx`, where his placeholder was). Title; steps
  (add, type, reorder, delete, jump); per step, objects: model, action, position and box in cm, quarter turns about
  the marker's X/Y/Z (`axis` follows the model's +Y, Ahmed's rule), the rig check (`ssd-bay` gone / back), and an
  action preview; "Place on scan" (`pickPoint`, off until calibrated) or "Add at marker" with typed positions;
  Send blocked with reasons until complete; ticks from `step.done` and ✓/✗ from `step.verified`; relay errors shown.
  **"Open a guide file…" loads a prepared guide JSON**, e.g. Ahmed's `fixtures/ssd-swap-guide.json`, for rung 1.
  A fresh page adopts the relay's saved guide and ticks; the last sent guide is re-sent when the link returns.
  Commit `a61405f`. Dashboard 43/43, type-check and build pass; relay 41/41.
- Tried end to end on this laptop: relay `--fresh`, `npm run dev`, `node fixtures/fake-phone.ts`. A three-step
  guide built in the panel reached the fake phone ("got guide … 3 steps") and its three taps ticked the steps; a
  reload restored both. That's my task 3's done-when. Scene objects untested on a calibrated scan (SAMPLE splat only).
- Also on main with it: `docs/README.judges.draft.md`, the judges' README draft (labelled draft; swaps in at submit).
- Touched: `dashboard/src/guide/` (mine), `dashboard/src/App.tsx` (Max's: the mount line only), `docs/`
- Not yet: 3D dragging (`onObjectMoved` is wired but the scene doesn't fire it yet), a custom `axis` other than the
  model's +Y.
- ⚠️ Conflicts: @max — one line in `App.tsx` swaps your placeholder for `<GuidePanel scene relay />`
- Conflict status: resolved by @max 2026-11-15 (agreed; that's the slot it was left for)

### 2026-11-15 02:32 — the dashboard loads mesh scans too; first real scan of the open laptop — @max
- Shipped: the dashboard takes a Scaniverse textured mesh (`.usdz`, `.glb`) as well as a splat, through three's own
  `USDLoader` and `GLTFLoader` (no new package), drawn unlit because the scan's lighting is in its texture. Pick dots
  are now a fixed size on screen. `splatSource.ts` is now `scanSource.ts`, `loadSplat` is `loadScan`. Commit
  `009153c`; dashboard 42/42, type-check and build pass.
- First real scan, cover off, as a mesh: 186,092 triangles, loads in 0.2–0.4 s at 60 fps, and the fan, RAM, the M.2
  slot by the fan and the battery are all sharp. **But the marker isn't in it**, so it can't be calibrated and can't
  be used. Rescanning both (closed and open) with the marker in view.
- Port 8080 on the dashboard laptop was held by an unrelated background task of mine; stopped, and the relay now
  starts on 8080. It may come back after a reboot: check before the demo.
- Touched: `dashboard/src/scene/` (mine)
- Decision (Max): the dashboard supports both splat and mesh scans; we keep whichever scan of the set comes out
  better. Picks on a mesh hit the exact surface, which helps the corner clicks.
- 📨 To @laura: if the demo ends up on a mesh scan, the README and pitch can't say "Gaussian splat" for it. I'll say
  which one we use once both rescans are in.
- 📨 To @ahmed: item A: the relay runs on this laptop on 8080 (tested with the dashboard).
- ⚠️ Conflicts: @laura — pitch wording depends on which scan kind we demo
- Conflict status: open

### 2026-11-15 02:39 — the first scan is on GitHub (PR #9); where each of us stands with the dashboard — @max
- Shipped: PR #9 merged (`d44dd01`). `dashboard/public/scans/` is now in git (it was git-ignored), so every
  teammate's dashboard loads the same scans: `cd dashboard && npm run dev`, then `?open=open-mesh-0217.usdz`. The
  first scan is a Scaniverse mesh of the laptop, cover off. **The marker isn't in it, so it can't be calibrated**; the
  folder's README marks it reference only. A scan's file name is its calibration id: never overwrite one, add a new
  name.
- Dashboard state (on `main`): Laura's panel in Max's shell; the relay link; splat and mesh scans; calibration (no
  placing until done); `showStep`, select, focus, previews. It can send a guide over the relay today; it hasn't yet
  reached the real phone, because the phone app isn't on `main`.
- Touched: `.gitignore` (one line removed), `dashboard/public/scans/` (mine)
- Decision (Max): scans are kept in git, not per machine (reverses the git-ignored folder in Ahmed's 01:45 plan), so
  the whole team and the judges see the same files. 6.6 MB per scan is fine for GitHub.
- 📨 To @laura: the rescan waits on your task 1, the board. Please fix the **marker flat beside the laptop**, all four
  corners clear, with the corner stops, and post on the board when it's ready: I scan straight after. Your
  `App.tsx` mount is marked resolved. Pitch wording still depends on splat vs mesh; I'll post which.
- 📨 To @ahmed: your item 2 / task 10: the relay runs on my laptop on port 8080 and the dashboard connects. Left: the
  phone and the rig on the hotspot, and your run sheet. Port 8080 was taken by an unrelated background task of mine
  that may come back after a reboot; I check it before the demo. Scans are now in git: shout if that's a problem.
- 📨 To @salman: the dashboard side of rung 1 is ready (Laura's panel sends `guide.set`). It waits on your item 1,
  `salman-ios-polish` on `main` (13 commits ahead). The dashboard assumes red +X along the marker's top edge and blue
  +Z down the print; your item 3 settles it, so please post which edges they really are and I'll adjust if needed.
- ⚠️ Conflicts: @ahmed — reverses his "git-ignored scans folder" | @laura — pitch wording depends on the scan kind
- Conflict status: open

### 2026-11-15 02:52 — the Nicla script runs on the Nicla Vision's sensor — @ahmed
- Shipped: first run on the real Nicla. The camera works in the OpenMV IDE, but `set_auto_gain(False)` raised
  "operation is not supported by the sensor" and stopped the script. It now skips a lock the sensor refuses and says
  so. Auto white balance therefore stays on: the set needs steady light. Commit `e690ebd`. Not yet seen: a
  `seen=ssd-bay` line, or the UNO Q reading it.
- Touched: `hardware/nicla/main.py`, `hardware/unoq/python/main.py` (a comment)
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-15

### 2026-11-15 02:59 — the dashboard shows where the phone user is standing — @max
- Shipped: task 7, on `main` (`d91f7ba`). A small camera wireframe follows the phone's `pose` messages inside the
  calibrated scan: green while `markerTracked`, amber when the marker is out of view (may drift), gone after 3 s
  without a pose. The HUD says which. Tried with `fixtures/fake-phone.ts` (SIMULATED poses) on a relay of its own:
  it circles the marker, turns amber on a marker-lost pose, and clears when the phone stops. Dashboard 42/42.
- Slip, fixed: one test relay of mine started in `relay/` with `--fresh` while the real relay on 8080 was running.
  Both write `relay/state.json`, so for a moment the file was emptied (the running relay's memory was untouched and
  it rewrites the file on its next change). My tests now run a relay with its own save file, outside the repo.
- Touched: `dashboard/src/scene/` (mine)
- 📨 To @salman: the dashboard draws your `pose` with the camera looking along its own -Z (ARKit's convention,
  `marker.inverse * cameraTransform` in `ARSessionController.swift`). If the phone sends anything else, say so.
- 📨 To @ahmed: could the relay take its save file from an env var or flag (e.g. `STATE=…`), so a test relay never
  shares `relay/state.json` with the live one? Your file, your call; I'm working around it meanwhile.
- 📨 To @laura: nothing new for your panel; the phone's position shows in the 3D view beside it.
- ⚠️ Conflicts: none (the `state.json` slip touched no code)
- Conflict status: resolved by @max 2026-11-15

### 2026-11-15 03:00 — the set is taped to our table, not built on a board — @laura
- Shipped: no code. Instead of a cardboard board with glued corner stops, the marker is **taped flat to our own
  table** beside the laptop's fan side (where the SSD is), "TOP" away from the expert, and the laptop's four corners
  are marked with masking-tape L-shapes so it lifts out and goes back in the same place.
- Decision: by Laura: tape on the table (faster, no glue). Cost: the scan only matches while the table, the tape and
  the marker stay put, so **the scan and the demo both happen at our table**, and anyone who moves it says so here.
- Touched: nothing in the repo
- 📨 To @max: scan at our table with the laptop in its tape corners and the marker fully in view; two scans (closed,
  cover off), splat or mesh as you decided at 02:32. This answers your 02:39 ask for the board: tell me when you're
  free and I'll set it up with you.
- 📨 To @ahmed: the rig's spot is beside the marker on the fan side; tell me if you want it elsewhere before Max scans.
- ⚠️ Conflicts: @max — where and when he scans | @ahmed — the rig's camera spot
- Conflict status: open

### 2026-11-15 03:05 — find a part by name: AI labels on the scan, with a search box — @max
- Shipped: task 8, on `main` (`4cd8b7f`). "Label this view (AI, paid)" sends a snapshot of the scan alone (no boxes
  or dots, at most 1280 px) as `labels.request`; each label's pixel becomes a point on the scan, using the camera the
  snapshot came from, so moving the view while Claude reads doesn't shift them. Labels show as tags on the scan and
  in a list marked **AI** with the model's name; the expert can rename or delete each. Typing in the search box
  highlights the best match and flies the camera to it. A label over empty space is dropped. Dashboard 46/46.
- Tested with a **MOCK** labeller (fixed labels, no Claude call) on a relay of my own, on the mesh scan: three labels
  placed, the off-scan one dropped, search, rename and delete work. **Not yet tried with Claude itself**, and not with
  a relay started without `--labels` (the panel shows the relay's refusal).
- Touched: `dashboard/src/scene/` (mine)
- Pending (Max's call, not decided): labels live only in the page, so a reload means asking Claude again (paid).
  Keeping them in the browser or on the relay would avoid that; the relay option is a contract change.
- 📨 To @ahmed: the dashboard side of `labels.request` / `labels.result` is in. For the demo the relay needs
  `--labels` and Anthropic credentials on my laptop; I'll set them up there (never in the repo). Your `refuse` text
  shows in the panel as-is.
- 📨 To @laura: labels never go to the phone and aren't part of the guide; they help the expert find a part, then
  "Place on scan" in your panel puts the object there. The **AI** tag and model name are on screen for the pitch's
  "what's real" answer.
- 📨 To @salman: nothing for the phone; labels stay on the dashboard.
- ⚠️ Conflicts: none
- Conflict status: resolved by @max 2026-11-15

### 2026-11-15 03:07 — drag and turn guide objects in the 3D view — @max
- Shipped: task 9's dragging, on `main` (`5412078`, comment fix `9a600a0`). The selected object gets drag handles:
  move along its own axes, or press **R** to turn it about +Y only (**T** to move again; the keys are ignored while
  typing in a box). When a drag ends, `onObjectMoved` fires once with position and rotation in marker metres.
  Tried with Laura's panel on a calibrated sample: dragging the red arrow set Position X to 22.6 cm (Y, Z unchanged)
  and turning bumped the guide's rev. Dashboard 46/46.
- Built before rung 2, against the 01:45 order, because rung 2 waits on the rescans and the phone app.
- Touched: `dashboard/src/scene/` (mine)
- 📨 To @laura: `onObjectMoved` now fires (once per drag, not per frame); your panel picked it up with no change.
  Selecting an object in your list attaches the handles.
- 📨 To @salman: a dragged object only ever turns about +Y, so `rot` stays an upright turn; nothing changes in the
  message.
- 📨 To @ahmed: nothing new for the relay.
- ⚠️ Conflicts: none
- Conflict status: resolved by @max 2026-11-15

### 2026-11-15 03:23 — docs/vault: plain-language notes on how everything works (PR #10) — @max
- Shipped: PR #10 merged (`4124e30`). `docs/vault/` is 14 linked notes for teammates and judges: how it works (with
  diagrams), the relay and its save file, messages, the marker frame, scans, calibration, guides, AI labels, the
  dashboard, the phone app, the rig, a demo runbook and a glossary. Read it on GitHub from `docs/vault/README.md`,
  or open the folder as an Obsidian vault. Standard markdown links, so they work in both. It copies no volatile facts:
  it links to this file's Latest block and to PROJECT.md instead.
- Touched: `docs/vault/` (new, mine)
- 📨 To @ahmed: please skim `relay.md`, `messages.md` and `rig.md`, written from your code and README, and correct
  anything wrong. `running-the-demo.md` is a first runbook; it's yours to own if you'd rather.
- 📨 To @salman: please skim `phone-app.md`. It describes `salman-ios-ar` (receipts, rig ✓/✗, the call page, QR
  connect) and says the app isn't on `main` yet. Correct anything wrong.
- 📨 To @laura: please skim `guides.md`, `dashboard.md` (your panel's half) and `marker-and-frame.md`, which
  describes your taped table. The vault might feed the judges' README. Your 03:00 entry: seen, Max sets the scan
  time with you directly.
- ⚠️ Conflicts: none (docs only; each owner checks their part's note)
- Conflict status: open (waiting on the three skims)

### 2026-11-15 03:25 — the rig runs on its hardware — @ahmed
- Shipped: first real run of the whole rig. The App Lab app starts on the UNO Q, connects to the relay on Max's
  laptop as `rig`, and reads the Nicla Vision's lines over the hub ("nicla sees the part in: no region"). Fixes on
  the way, all on `main` (last `d502f4e`): the Nicla's sensor can't lock gain or white balance; the app waits for the
  Nicla instead of stopping, survives it being unplugged, and accepts an address without `ws://`; **the Nicla only
  sends with DTR set** (our measurement; the ledger's source said the opposite, § 10 corrected). App Lab's own
  board update had failed on corrupt package lists: cleared with `sudo rm -rf /var/lib/apt/lists/*` and
  `sudo apt-get update`.
- Not yet: the sticker colour and the `ssd-bay` region tuned on the real SSD; a tick on the LED matrix; a
  `step.verified` seen on the dashboard or phone.
- Touched: `hardware/`; on `context`: `research/ledger.md` § 10, `builder-file-ahmed.md`
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-15

### 2026-11-15 03:30 — DurHack's official rules (from the organisers) — @laura
- Shipped: no code. The organisers' stated rules, which settle three open questions in `EVENT.md` and `PROJECT.md`:
  - Teams of up to **4**; solo is allowed; teams can't be bigger.
  - **No crossposting** to another hackathon the same weekend, including a digital one.
  - Code isn't required, but a **GitHub link is preferred**.
  - Public frameworks are fine, and **must be listed in the README**.
  - **AI / LLM use must be credited explicitly.**
  - Multiple projects: not recommended. **Multiple challenges: yes**, so our four sponsors plus MLH are allowed.
  - **No work before the event.**
  - **Judging is in person.**
  - **The whole presentation must be under 5 minutes** (added by Laura after asking). Still not stated: a separate
    video length limit, and whether the repo must be public.
- Touched: `docs/README.judges.draft.md` on `laura-guide`: every framework per part, and Claude Code, Claude,
  Gemini and ElevenLabs credited.
- 📨 To @ahmed @max (docs owners): please fold these into `EVENT.md` §1–3 and close "May one project enter four
  sponsor challenges…" in `PROJECT.md` → Pending (yes). "No work before the event" still leaves the team-kit
  question in `EVENT.md` §3 (it's tooling adapted from the datathon): worth one question to an organiser.
- 📨 To @salman: are Gemini and ElevenLabs in the demo build? The README credits them; tell me if they're cut.
- ⚠️ Conflicts: none
- Conflict status: resolved by @laura 2026-11-15

### 2026-11-15 03:40 — the expert's dashboard becomes a product screen (decision) — @max
- Shipped: no code yet. Max's call on what the dashboard work is now: **a finished product screen first, then
  cut-outs.** A header (Closed / Open switch, relay / phone / rig lights from `presence`, a **Call** button that opens
  Salman's call page in its own window), a live strip (the person's step, ticks, the rig's ✓ / ✗, an amber "phone
  offline, still working on its own" state with a timer), plain prompts in place of the debug text (kept behind a key
  for us), one calm dark look. Why: judges watch this screen for the whole demo, the presentation is under 5 minutes,
  and the offline moment is the pitch's main claim but showed nowhere.
- Touched: on `context`: `PROJECT.md` (Decision log, Decisions in force, Active tasks), the four briefs
- Decision: dashboard as a product screen before cut-outs; Max's agent restyles Laura's panel with her OK; the call
  stays Salman's page in its own window, opened by a Call button; a calm dark look, no new package (Max, 03:40)
- 📨 To @laura: **may Max's agent restyle `dashboard/src/guide/GuidePanel.css`?** Colours, fonts and spacing only;
  no change to `GuidePanel.tsx` or how the panel works. Reply here ("yes" / "no" / "I'll do it"). Until then only
  Max's half changes.
- 📨 To @salman: the Call button opens `http://<dashboard host>:8000/?relay=<relay>` (your README's
  `python3 -m http.server 8000` in `ios/expert-call/`). Please keep `?relay=` working and bring the page to `main`
  with the app.
- 📨 To @ahmed: cut-outs are still in scope, straight after this. The lights and the rig's ✓ / ✗ use `presence` and
  `step.verified` as they are, no contract change. Max is working to about 10:00 for features, past the Clock's
  07:00 freeze that you set; the Clock is unchanged until you two agree.
- ⚠️ Conflicts: @laura — `GuidePanel.css` restyle waits on her yes
- Conflict status: open

### 2026-11-15 03:55 — the dashboard's header and live strip — @max
- Shipped: `aa6d177` on `main`. The expert's screen now has a **header** (Closed / Open switch, scan name and kind,
  a calibration chip with the residual in mm, relay / phone / rig lights from `presence`, **Call the phone**) and a
  **live strip** under it that says what's happening: Set up (calibrate) → Build → "Step 2 of 4" with a dot per step
  and the rig's last ✓ / ✗ → amber **Offline 0:42** when the phone drops off the relay → green **Back online**, with
  how many steps were done offline → **Done**. The debug text (fps, scan size) is behind the backquote key or
  `?debug`. One calm dark look on Max's half. Tried end to end with a memory-only relay, the fake expert and the fake
  phone dropping off for 5 and 15 s (the phone and rig parts are SIMULATED until the real ones connect). Dashboard
  54 tests (8 new for the live logic), type-check and build clean. Vault: `dashboard.md`, `running-the-demo.md`.
- Touched: `dashboard/src/App.tsx`, `styles.css`, `index.html`; `dashboard/src/shell/` (new); `dashboard/src/scene/`
  (`useScan`, `useCalibration`, `usePhonePose` replace the corner panel's `Calibrate` and `PhoneStatus`;
  `Viewport`); `docs/vault/`
- 📨 To @laura: your panel and `GuidePanel.css` are unchanged; it now sits on the new dark surface and keeps its own
  13 px text. Your ticks and the strip's dots come from the same `progress.ts` functions (imported, not edited).
  The restyle ask (03:40) still stands: reply "yes" / "no" / "I'll do it".
- 📨 To @salman: **Call the phone** opens `http://<dashboard host>:8000/?relay=<relay>`: serve `ios/expert-call/` on
  8000 before the demo. The Phone light shows your app's `client` name from `hello` as a tooltip, and says
  "tracking" / "marker out of view" from `pose.markerTracked`.
- 📨 To @ahmed: the Rig light turns green when the UNO Q says hello as `rig`, and the strip shows its last
  `step.verified` (✓ / ✗ with `detail`). Nothing in the relay or contract changed. The offline timer starts when
  `presence` drops the phone, so it lags a real drop by up to your 5 s heartbeat.
- ⚠️ Conflicts: @laura — her panel's container (`.guide` in `styles.css`) changed background and padding; her
  panel itself is untouched | none for @salman, @ahmed
- Fix 03:58 (`7053035`): the controls hint wraps instead of running under the labels panel on a narrow window.
- Conflict status: open (Laura's restyle answer)

### 2026-11-15 04:10 — AI-made props on the DGX Spark (decision; build starting) — @max
- Shipped: no code yet. Max's call: the team's DGX Spark runs **Hunyuan3D 2.1**, which turns one photo of a part
  into a textured 3D model in about 3 min (forum users' timing, not ours yet). First props: the SSD and the #0
  screwdriver, scaled by hand to their real size (SSD 22 × 80 mm), shown on the **dashboard first**. It's a guess
  from one photo, so it never replaces the scan we calibrate against. Max's agent builds it over SSH in the
  background (the Docker build compiles Python and Blender, so it's mostly waiting). **Dropped if it isn't built by
  about 06:30**; nothing else depends on it.
- Touched: on `context`: `research/ledger.md` § 18 (new), `PROJECT.md` (Decision log, Decisions in force, Active
  tasks), `builder-file-max.md` (task C). On the Spark: a Docker image, nothing in this repo yet.
- Decision: AI-made props with Hunyuan3D 2.1 on the DGX Spark, dashboard first, labelled "AI-generated from a
  photo", dropped by about 06:30 if not built (Max, 04:05)
- 📨 To @laura: for the README, video and Devpost: if a prop makes the demo, it says **"AI-generated from a photo"**,
  and "made on our DGX Spark" only once it really was. Nothing to do now.
- 📨 To @salman: nothing for you yet. If the SSD prop works, Max will ask whether the phone can load a USDZ file
  (`Entity(contentsOf:)`, ledger § 15) next to the guide; only if you have time.
- 📨 To @ahmed: nothing for you. No relay or contract change; the Spark isn't part of the live demo path.
- ⚠️ Conflicts: none
- Conflict status: n/a

### 2026-11-15 04:12 — what's left, and the phone's camera — @ahmed
- Shipped: no code. A read of `salman-ios-ar` at `fa51e72`: the camera freeze has had five fixes and no confirmed
  cause, and the phone app is still the one piece not on `main`. Each brief has a new "What's left" block on top.
  `EVENT.md` has the organisers' rules from Laura's 03:30 entry.
- Touched: on `context`: all four briefs, `PROJECT.md` (Clock, decisions, pending, F14), `EVENT.md`
- Decision (Ahmed): the plain build first. PR #8 (`salman-ios-polish`) goes to `main` and is the demo build; the
  freeze is found by halving the commits between it and `fa51e72`; extras come across one at a time.
- Decision (Ahmed): Max may build dashboard features until 10:00. The phone, relay, rig and every message shape
  still freeze at 07:00.
- 📨 To @salman: merge PR #8 now and smoke-test it on the phone. Then `git bisect` for the freeze (about 5 builds)
  before any new fix; three suspects from the code are in your brief. Tell Laura whether ElevenLabs is in the demo.
- 📨 To @max: the rescans with the marker in view are the next blocker; then one object placed in the scan and
  measured on the real laptop. Features to 10:00 agreed. A `--state` flag for the relay is coming.
- 📨 To @laura: scan with Max; a timed 5-minute beat sheet in `PROJECT.md` §9; answer Max's restyle ask.
- ⚠️ Conflicts: @salman — changes which of his branches is the demo build
- Conflict status: open

### 2026-11-15 04:21 — relay `--state`, and the prepared SSD-swap guide (draft positions) — @ahmed
- Shipped, on `main` at `edb39c9`: `npm start -- --state <file>` gives a relay its own save file (it prints which
  one it uses), so a test relay can't empty the live one's. `fixtures/ssd-swap-guide.json`: Laura's 12 steps for the
  Latitude 5530 with models, actions and the rig's check on steps 8 and 9. **Its positions are placeholders**, not
  measured: the title starts "DRAFT POSITIONS" until they're taken from the marker's centre with a ruler. 42 relay
  tests pass, one of them checking this guide.
- Touched: `relay/server.ts`, `fixtures/ssd-swap-guide.json` (new), `relay/validate.test.ts`
- 📨 To @max: start test relays with `--state` and a file outside the repo.
- 📨 To @laura: "Open a guide file…" loads it for rung 1; steps 1–3 and 12 are text only, as you suggested.
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-15

### 2026-11-15 04:30 — AI-made props on hold: Hunyuan's licence excludes the UK — @max
- Shipped: no code, nothing installed on the Spark. **Hunyuan3D 2.1 is out**: its licence "does not apply in the
  European Union, United Kingdom and South Korea", and we're in Durham. A new model is being picked: Pixal3D (MIT,
  SIGGRAPH 2026, the only one with a timed DGX Spark run) is the front-runner (`research/ledger.md` § 19). Also
  found: the Spark is shared (eaby's vLLM holds 41 GB of GPU memory, about 61 GB free) and Max's account has no
  Docker or sudo, so any install goes in his home folder.
- Touched: on `context`: `research/ledger.md` § 19 (new) and a note on § 18, `PROJECT.md` (the 04:05 decision marked
  on hold), `builder-file-max.md` (task C ⏸)
- 📨 To @laura: if anyone mentions Hunyuan in the README, video or Devpost, take it out; we can't use it here.
- 📨 To @salman: nothing for you.
- 📨 To @ahmed: nothing for you.
- ⚠️ Conflicts: none
- Conflict status: n/a

### 2026-11-15 04:40 — AI-made props: Pixal3D replaces Hunyuan, building on the Spark — @max
- Shipped: no repo code yet. Max's call: the props use **Pixal3D** (MIT, SIGGRAPH 2026), the only image-to-3D model
  with a timed DGX Spark run (3–6 min per model). Only ungated parts: a copy of DINOv3 under Meta's DINOv3 licence and
  BiRefNet (MIT) for background removal. Building now in `~/pixal3d` on the Spark (Max's home folder, no Docker or
  sudo); weights are about 24 GB. First target: the SSD as a textured GLB on the dashboard, labelled "AI-generated
  from a photo". **Cut-off 07:30.**
- Touched: on `context`: `PROJECT.md` (Decision log, Decisions in force, Active tasks), `builder-file-max.md` (task C);
  `research/ledger.md` § 19. On the Spark: `~/pixal3d` only.
- Decision: Pixal3D, not Hunyuan3D 2.1 (licence excludes the UK); ungated DINOv3 copy and BiRefNet; cut-off 07:30
  (Max, 04:32)
- 📨 To @laura: if a prop makes the demo, it's "AI-generated from a photo (Pixal3D, on our DGX Spark)", and only once
  it really ran there. No "better than Hunyuan" claims; that's the authors' own numbers.
- 📨 To @salman: nothing yet. If the SSD prop works, the ask is whether the phone can load one USDZ (ledger § 15).
- 📨 To @ahmed: nothing for you. The Spark isn't in the live demo path, and no contract changes.
- ⚠️ Conflicts: none
- Conflict status: n/a

### 2026-11-15 05:07 — the rig checks the SSD on real hardware — @ahmed
- Shipped: no code change. Ahmed at the board: with the sticker on the SSD, the Nicla Vision reports `ssd-bay`, the
  UNO Q app shows it, and the take-out and put-back checks work through the relay on Max's laptop (driven by
  `fixtures/fake-expert.ts --step`, a test tool). The script's example colour (bright green) and region fitted
  unchanged, so `hardware/nicla/main.py` on `main` is what's on the board. Not yet done with the real phone and the
  real guide. The Nicla can't lock white balance: if the table's light changes, re-run the Threshold Editor.
- Touched: on `context`: `builder-file-ahmed.md`, `PROJECT.md` (F12)
- 📨 To @max: the Rig light and the strip's ✓ / ✗ now have a real rig behind them; say if they misbehave.
- 📨 To @laura: the Nicla's view must stay as it is now; tell Ahmed before moving the table, the laptop or the lamp.
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-15

### 2026-11-15 05:24 — Pixal3D runs on the Spark; first prop: the screwdriver — @max
- Shipped: no repo code. Pixal3D built in `~/pixal3d` on the Spark in 22 min (three fixes; ledger § 19 "Measured on
  our Spark"). From one phone photo of our #0 screwdriver it made a textured 3D model in 136–247 s, scaled to the
  real 164 mm, bit at the origin, handle up +Y (Laura's model conventions), about 99k faces, 2048² texture, 3.8 MB.
  It shows correctly in the dashboard. The back of the handle is the AI's guess. A second seed removed a stray fin
  the first one had. SSD photo next.
- Touched: on `context`: `research/ledger.md` § 19 (measured results), `builder-file-max.md` (task C status). On the
  Spark: `~/pixal3d` only. Nothing in the repo; test files were kept out of git.
- 📨 To @laura: your `assets/models/screwdriver` is untouched. Max will ask you whether an AI-made one should show
  anywhere next to or instead of yours; it's far heavier (3.8 MB, textured) than your under-7 KB orange models.
- 📨 To @salman: nothing yet; the phone keeps Laura's models.
- 📨 To @ahmed: nothing for you.
- ⚠️ Conflicts: @laura — a possible future change to how the `screwdriver` model looks; nothing changed yet
- Conflict status: open

### 2026-11-15 07:37 — the last stretch: why boxes hover, and the demo's shape — @ahmed
- Shipped: no code. Ahmed reports the phone works and a guide sent from the dashboard reaches it. **Boxes hover
  above the laptop because no guide has real positions:** the only scan on `main` has no marker, so nothing can be
  calibrated or placed in it, and `fixtures/ssd-swap-guide.json` has placeholders. Each brief has a "last stretch"
  block on top.
- Touched: on `context`: the four briefs, `PROJECT.md` (Decisions in force)
- Decision (Ahmed): rescan twice with the marker in view and place parts by clicking in the scan, with a top-down
  ruler photo as the fallback; bigger animations (pull / push 4 cm, unscrew two turns rising 15 mm), no message
  change; the demo is "expert builds, user follows"; #11 on `main` is the demo build.
- Beat sheet draft (under 5 min): problem 0:30 · expert clicks a screw, picks unscrew, sends 0:45 · it lands on the
  real screw 0:30 · taps and ticks 0:30 · phone Wi-Fi off, keeps going, syncs 0:45 · SSD out, the rig's ✓ 0:30 · call
  with tap-to-point 0:30 · extras 0:30 · what's real 0:30.
- 📨 To @max @laura: rescan now, closed then cover off, marker fully in view; ruler photos at the same time. Then
  build the guide in the scan. Ahmed's laptop is the prop from then on, so Max is the docs owner on duty.
- 📨 To @salman: bigger animations in `Shapes.animate`, check and merge PR #12, and be at the table for the first
  real run with the expert's guide.
- ⚠️ Conflicts: @salman — one post-freeze change asked of the phone | @max — the preview must match it
- Conflict status: open

### 2026-11-15 07:38 — correction: what the animations really do on main — @ahmed
- Shipped: no code. My 07:37 entry gave the phone's current animation sizes from an old branch. Read from `main`
  (`ios/RemoteAssist/AR/Shapes.swift`, `dashboard/src/scene/preview.ts`): `unscrew` on the phone only spins the
  screw in place, which a round screw barely shows; `pull` / `push` slide 2 cm and come back, so they read as a
  wobble; the dashboard preview moves differently (3 cm, two turns rising 5 mm). The corrected spec is in Salman's
  and Max's briefs: unscrew rises 15 mm over two turns, pull / push go 4 cm one way, loops restart, objects start
  0.15 s apart, and on the phone a pulsing ring, thicker box lines and a bigger label.
- Touched: on `context`: `builder-file-salman.md`, `builder-file-max.md`
- ⚠️ Conflicts: @salman @max — the spec in their briefs changed
- Conflict status: open

### 2026-11-15 07:40 — a check of main from the code itself — @ahmed
- Shipped: no code. Run on `main` on Ahmed's laptop: relay 42/42 and type-check; dashboard 54/54, type-check and
  build; rig 13/13. The model tests didn't run here (`usd-core` isn't installed on this laptop). Swift not compiled.
- Found by reading the code:
  - **The phone starts on the bundled SAMPLE guide** (`RemoteAssistApp.swift:18`, `fixtures/sample-guide.json`),
    whose positions are invented, so its boxes float wherever they fall. Only a guide sent by the dashboard
    replaces it (`ContentView.swift:343`).
  - **"Add at marker" puts a new object at the marker's centre** (`GuidePanel.tsx:225`) until a position is typed,
    and "Place on scan" can't work yet: `dashboard/public/scans/` still has only the scan with no marker.
  - The phone scales the guide by ARKit's size estimate of the marker (`ARSessionController.swift:200`, `889`).
  - The root `README.md` is still the team-kit README; the judges' version is a draft in `docs/`.
  - The dashboard's Call button expects Salman's page on port 8000 of the dashboard laptop (`App.tsx:20`).
- 📨 To @laura: swap the judges' README in before submitting. 📨 To @max: the rescans are what unblock placing.
- ⚠️ Conflicts: none
- Conflict status: n/a

### 2026-11-15 07:47 — a simple checklist at the top of every brief — @ahmed
- Shipped: no code. Each brief now opens with "YOUR CHECKLIST": numbered steps to do top to bottom, with the exact
  commands and what to look for, plus the same six-step "how to start everything" in all four. It replaces the 07:37
  "last stretch" block (same decisions, plainer steps). Ahmed's laptop is backed up and is the prop from now on, so
  **Max is the docs owner on duty**.
- Touched: on `context`: the four briefs
- 📨 To @max @laura @salman: start at step 1 of your checklist. The scan with the marker in it comes first.
- ⚠️ Conflicts: none
- Conflict status: n/a

### 2026-11-15 08:30 — the demo opens with Salman's console, then the guide dashboard — @ahmed
- Shipped: no code. Two expert tools exist. Salman's technician console (`ios/expert-call/`) marks the real laptop
  from clicks on the phone's live video, with no scan or calibration, which is why its marks stick. Max and Laura's
  dashboard builds a guide in a scan and shows ticks, offline and the rig, but nothing is calibrated yet. Two new
  scans from Ahmed (08:01, 08:09) are on his laptop, not committed.
- Touched: on `context`: the four briefs (a change note above each checklist), `PROJECT.md`
- Decision (Ahmed): live console first, guide dashboard second; typed positions and "prepared guide" if the scans
  aren't calibrated in time.
- 📨 To @salman: merge **PR #12 only**. `salman-latest` bundles the dropped Expo app (`mobile/`, a 7,600-line
  lockfile) and old board entries: please don't merge it to `main`.
- 📨 To @laura: the script's order changed (in your brief). 📨 To @max: the scan route is the second beat now.
- ⚠️ Conflicts: @laura — the beat sheet order | @salman — which of his branches merges
- Conflict status: open

### 2026-11-15 08:36 — Scanning inside our own app: built on a branch, trainer proven on the Spark — @max
- Shipped: on branch `max-ios-scan` (`1576570`), not `main`: a "Scan the room" mode in the phone app that keeps
  a photo each time the phone moves 4 cm or turns 8°, with ARKit's camera pose already in the marker's frame, and posts
  the scan as one zip to `pipeline/scan-inbox.ts` on the relay laptop (port 8090). `pipeline/train_scan.py` trains a
  splat from it on the Spark with gsplat, with no COLMAP step, so the splat comes out lined up with the marker. Tests:
  inbox 6/6, trainer 5/5. On the Spark (`~/scan`), a made-up scan of 60 photos trained in 168 s for 3,000 steps
  (error 0.45 → 0.0035), and the splat opens in our dashboard. **The Swift has never been compiled** (no Xcode on
  Max's laptop), and no real phone scan exists yet, so nothing about real scans is measured. Scaniverse stays the
  demo's scan.
- Touched: on `max-ios-scan`: `ios/RemoteAssist/Scan/` (new), `ARSessionController.swift` (a `scanRecorder`
  that sees each frame), `ContentView.swift`, `HomeView.swift` (a third start-screen choice),
  `ios/RemoteAssistTests/ScanKeyframePolicyTests.swift`, `pipeline/` (new), `.gitignore`. On the Spark: `~/scan`
  only. On `context`: `PROJECT.md` (Decision log, Decisions in force, Pending, Active tasks), Max's and Salman's briefs.
- Decision (Max, 08:00): scanning inside our own app as a side route; its own branch until Salman agrees and builds
  it; our own gsplat trainer; an upload server on the relay laptop (`PROJECT.md` → Decision log).
- 📨 To @salman: optional and last, after your checklist and the run-through: yes or no on the board to Max's scan
  code in your app. If yes, build `max-ios-scan` in Xcode (the last block in your brief). Nothing merges without you.
- 📨 To @ahmed: nothing in `relay/` changed; scan tests add port 8090 on the relay laptop while they run.
- 📨 To @laura: keep it out of the pitch and README until a real scan has worked.
- ⚠️ Conflicts: @salman — Max's code in `ios/` on a branch (a new folder plus three small hooks in his files), not merged
- Conflict status: open

### 2026-11-15 09:00 — guide marks land across the room on the phone: the dashboard's data is right — @ahmed
- Shipped: no code. Ahmed calibrated both new scans on Max's dashboard and placed a guide; on the phone the marks
  appear on the other side of the room. Read from the relay on Max's laptop (a read-only expert connection):
  - both calibrations are good: `scan-0801.usdz` residual 0.3 mm, `scan-0809.usdz` 0.8 mm, marker edges 0.178–0.182
    in scan units, so the scans are in metres;
  - the guide (`sample-ssd-swap`, rev 31) has every object within 0.5 m of the marker and about 2 cm above its
    plane, on the marker's −X side: where the laptop is. One stray screw sits at 0, 0, 0 ("Add at marker"), and step
    4's object is 3 cm below the marker's plane;
  - the iPhone is connected and all four steps were tapped.
  So the positions leaving the dashboard are right, and the fault is where the phone puts its marker anchor.
- Not proven, the leading suspect from the code: the phone anchors the guide to the **first** marker image it sees
  (`ARSessionController.attach`, only on a new image anchor) and scales it by ARKit's size estimate
  (`markerRoot.scale`). A second copy of the marker in view (a spare print, or the marker inside the scan on the
  dashboard's screen) would anchor the whole guide there.
- Touched: nothing
- 📨 To @salman: on the phone, is the green outline on the taped marker, or somewhere else? Suggested fix in
  `receive`: ignore an image anchor whose `estimatedScaleFactor` is outside about 0.8–1.2 (not our 180 mm print),
  and consider turning scale estimation off. Yours to decide and test.
- ⚠️ Conflicts: @salman — a suspected fault in how the phone anchors the guide
- Conflict status: resolved by @salman 2026-11-15 (fixed on `salman-ios-scan`, see 11:05)

### 2026-11-15 10:04 — Devpost "About the project" draft — @max
- Shipped: `docs/devpost-about.md` on `max-scene` (`00d7ba4`), not `main`: all seven Devpost sections (inspiration,
  what it does, how we built it, challenges, proud of, learned, what's next), checked against this board. It credits
  AI use (Claude Code, Claude labels, ElevenLabs, Pixal3D), as the rules require. Left out on purpose: the 0.3 mm
  calibration residual (it isn't alignment accuracy), Gemini (removed), in-app scanning as working, and "trained on
  the Spark" for the demo scan.
- Still open (Max): two TODOs, the end of Max's MSP story and whether the marker bug is fixed by submission. The
  name isn't settled either: Devpost says "Sonic Assist", while the app, repo and README say "Remote Assist".
- Touched: `docs/devpost-about.md` (new, on `max-scene`)
- 📨 To @laura: the Devpost text is drafted. Read it on GitHub at `max-scene:docs/devpost-about.md`. Don't paste
  it until Max fills the two TODOs. The "Claude suggests part labels" line goes if no real Claude call has run.
- 📨 To @salman: the Challenges section describes the wrong-side-of-the-room bug as not fixed yet. Post on the board
  if you fix it, so the line gets updated.
- 📨 To @ahmed: nothing to do. Your relay read-out is told as the "prove which side is wrong" story.
- ⚠️ Conflicts: @laura — Devpost is hers; this is a draft for her to use or change
- Conflict status: open

### 2026-11-15 10:18 — the project is called Sonic Assist — @ahmed
- Shipped: no code. Settles the name Max flagged at 10:04: Devpost, the README and the pitch say **Sonic Assist**.
  "Remote Assist" stays in code, folder names and the app's display name unless Salman has time to change the latter.
- Touched: `team.conf`, this file's Headline; on `context`: `CLAUDE.md` (Registry), `PROJECT.md`
- Decision (Ahmed): Sonic Assist.
- 📨 To @laura @max: use Sonic Assist in the README, the video and `docs/devpost-about.md`.
- 📨 To @salman: only if it's a one-line change, the app's display name (`INFOPLIST_KEY_CFBundleDisplayName`).
- ⚠️ Conflicts: none
- Conflict status: n/a

### 2026-11-15 10:53 — the judges' README draft is up to date on main — @laura
- Shipped: `docs/README.judges.draft.md` on `main`: every framework listed per part (DurHack's rule), AI credited
  explicitly (Claude Code, Claude labels; ElevenLabs only if it's in the demo), Gemini removed. Still a draft: it
  replaces the root `README.md` just before submitting.
- Touched: `docs/README.judges.draft.md`
- ⚠️ Conflicts: none
- Conflict status: resolved by @laura 2026-11-15

### 2026-11-15 11:05 — the phone's guide fixes, saved on `salman-ios-scan` (not main) — @salman
- Shipped: `salman-ios-scan` has main merged in and is pushed. It holds PR #12 (`salman-ios-guide`) plus Max's room
  scan (`max-ios-scan`). Not on `main`: that's Salman's call.
- Answers Ahmed's 09:00 entry (marks across the room). Fixed on the phone:
  - the guide was scaled by ARKit's size estimate of the marker; now only the green outline is, so positions stay in
    true metres;
  - "Lock the guide to the laptop" (guide menu, two corner taps) moves the guide onto the real laptop, and the phone
    saves that lock relative to the marker, so it's done once;
  - the expert's points, areas and boxes are pinned to the marker, so they no longer drift as the phone moves.
  - Seen in the phone's log: areas land, Done for s1–s4 reaches the relay, Clear hides the guide's part too.
    Not yet checked by eye: no drift, the saved lock coming back after a restart, the Box tool.
- Also on the branch: the console toolbar (Point, Unscrew, Screw in, Area, Box), a rig status pill, and a 3D panel
  beside the live video that shows only the scan (`dashboard/viewer.html`, with the three Scaniverse scans in
  `dashboard/public/scans/`).
- Open: ElevenLabs is out of credits (0 of 10,000 at 10:41). Steps speak with the iOS voice; the call transcript and
  spoken commands won't work until it's topped up or the key is swapped. The rig is off, not connected yet.
- Touched: `ios/RemoteAssist/**`, `ios/expert-call/index.html`, `dashboard/viewer.html`, `dashboard/src/viewer.tsx`,
  `dashboard/public/scans/`, `pipeline/` (Max's scan)
- 📨 To @max: for Devpost Challenges, the wrong-side-of-the-room bug is fixed on the phone (above), on this branch,
  not on main yet. Your dashboard gained one page (`viewer.html` + `src/viewer.tsx`); none of your files changed.
- 📨 To @laura: ElevenLabs has no credits left, so check before the README credits it for the demo.
- ⚠️ Conflicts: @max — a new page beside his dashboard (nothing of his edited)
- Conflict status: open

### 2026-11-15 11:20 — the phone app and console are called Sonic Assist — @salman
- Shipped: on `salman-ios-scan`, everything a person sees says **Sonic Assist**: the name under the app icon and in
  Settings, the start screen, onboarding, the permission prompts, Settings hints, the report footer, the console's
  tab and heading, and the 3D scan page. Code, folders, the bundle id and the scheme stay `RemoteAssist`.
- Answers Ahmed's 10:18 📨 (the display name).
- Touched: `ios/project.yml`, `ios/RemoteAssist/Info.plist`, string-only edits in `ios/RemoteAssist/**`,
  `ios/expert-call/index.html`, `dashboard/viewer.html`
- 📨 To @max: your dashboard still says "Remote Assist" (`dashboard/index.html` title, `src/shell/Header.tsx`).
- ⚠️ Conflicts: none
- Conflict status: n/a

### 2026-11-15 11:40 — Scan the room says why it can't start yet — @salman
- Shipped: on `salman-ios-scan`. Before the marker has been seen, Scan the room's greyed-out Start was close to
  invisible on the glass card, so Salman couldn't find it. It now shows "Point at the marker to start" in plain view,
  and becomes the purple Start once the marker is seen. Same rule as before, only clearer.
- Rig: it joined the relay twice and dropped both times. No code change: the relay's guide already has the rig's
  checks on s3 (SSD out of the bay) and s4 (SSD in), and the console shows them as pop-ups.
- Touched: `ios/RemoteAssist/Scan/ScanView.swift`
- 📨 To @max: a small look change on your scan screen's ready state; the flow is unchanged.
- ⚠️ Conflicts: @max — `ScanView.swift` is from his `max-ios-scan`
- Conflict status: open
### 2026-11-15 11:04 — a full test run on Laura's laptop: what works, and two things to fix — @laura
- Shipped: README draft now titled **Sonic Assist**. Tested everything else on `main` (`b327dea`) with a relay on its
  own `--state` file, the dashboard, `fixtures/fake-phone.ts` and the rig's `main.py` fed Nicla lines on stdin.
- All green: relay 42/42 + type-check · dashboard 54/54 + type-check + build · models 7/7 · rig 13/13. No console
  errors in the dashboard at any point.
- Works end to end: the scan loads; calibration refuses bad clicks ("off by 17.6 mm, the limit is 5 mm"); "Open a guide
  file…" loads `fixtures/ssd-swap-guide.json`; Send reaches the phone; the phone drops offline mid-guide, queues 2
  taps, reconnects and every step ticks; Jump + the rig give **✓ checked** on "Slide the SSD out" live.
- **Problem 1 (rig):** a rig that connects *after* steps were already tapped gets every past `step.done` replayed,
  counts past the end of the guide, and never verifies a step the expert jumps back to (`Rig.on_relay`, step.done
  branch). Reproduced: rig started after a full run → no verdict on s8. Started first, it works. Restarting the
  UNO Q mid-demo would hit this.
- **Problem 2 (name):** the project is Sonic Assist (`team.conf`), but judges see **"Remote Assist"** in the dashboard
  header and tab (`dashboard/src/shell/Header.tsx`, `dashboard/index.html`) and on the iPhone app's screens
  (`HomeView.swift`, `Onboarding.swift`, `SystemCheck.swift`, `Info.plist`, …).
- Not tested here: the real iPhone, the video call, AI labels (costs money), and calibration on a scan with the
  marker (the two new scans aren't on `main`).
- Touched: `docs/README.judges.draft.md`
- 📨 To @ahmed: problem 1 is in `hardware/unoq/python/rig.py`; simplest guard is to start the rig before the run, or
  have it ignore replayed `step.done` until the relay's current `step.set` arrives.
- 📨 To @max: rename the dashboard header and tab. 📨 To @salman: rename the app's visible text, if there's time.
- ⚠️ Conflicts: @ahmed @max @salman — reported in their files; I changed none of them
- Conflict status: open

### 2026-11-15 11:28 — the rig no longer counts replayed taps (Laura's problem 1) — @ahmed
- Shipped: `e8c8a9d` on `main`. A rig that connects, or reconnects, after steps were tapped now ignores the
  `step.done` messages the relay replays, and stays on the relay's current step. 14 rig tests pass, one new for
  exactly Laura's case. **The UNO Q runs the old file until `rig.py` is copied into App Lab again.**
- Touched: `hardware/unoq/python/rig.py`, `test_rig.py`
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-15

### 2026-11-16 16:40 — the judges' README is the repo's README, with pictures and a quick start — @salman
- Shipped: on `salman-ios-scan` (PR #13). `README.md` is now Laura's judges' draft, filled in and dressed up: a
  DurHack banner, badges, a GIF from the day-one explainer (labelled as the concept, network cupboard and all), fresh
  shots of the console, the dashboard and the 3D scan, a 7-step quick start, and "What's real" updated to what was
  checked on the hardware. Licences read from the installed packages and PyPI (`usd-core` 26.11 is TOST-1.0, not
  Apache). The team-kit README moved to `docs/team-kit.md`; the draft points to the new README.
- Touched: `README.md`, `docs/team-kit.md` (moved), `docs/README.judges.draft.md` (one pointer line), `docs/media/`
- 📨 To @laura: your draft is now `README.md`, built on your text. Change anything you disagree with there.
- ⚠️ Conflicts: @laura — the judges' README was her task
- Conflict status: open

### 2026-11-16 17:15 — the README shows the app live and the rig, without AI credits — @salman
- Shipped: on `salman-ios-scan` (PR #13). A "See it live" section with real screenshots from 15 and 16 Nov (the
  incoming call, a live call, an expert Area and Points on the phone, the console mid-call), and a "The rig checks
  the work" section with a drawing of the UNO Q + Nicla rig (no photo of it yet) and the console showing "Rig, step
  s4: ✓ correct". Browser bars and a tab showing an email address were cropped or blurred out of every shot.
- Decision (Salman): the README carries no AI credits or Claude mentions (the AI use section, the AI labels row, the
  Anthropic SDK line and "AI labelling" are gone). DurHack's AI credit rule is for Devpost.
- Touched: `README.md`, `docs/media/`
- 📨 To @laura @ahmed: the README no longer credits AI tools; keep the credits on Devpost, where the rules ask for them.
- ⚠️ Conflicts: @laura — her README draft's AI use section was dropped, on Salman's call
- Conflict status: open
