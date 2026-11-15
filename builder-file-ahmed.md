# Ahmed: docs owner; the relay, the protocol contract, sync and integration
**GitHub:** `meep-boop` · **Branch:** `ahmed-relay` · **Brief last updated:** 2026-11-14 by ahmed
**Spec:** `PROJECT.md` (NOW first); the § numbers below refer to it. **Deadlines:** `PROJECT.md` → NOW → Clock.
**The plan in full:** `docs/remote-assist/README.md` and `architecture.md` (on `main`, written by @max).

## 0. How the agent reads this brief (every task)
1. Read the project `CLAUDE.md` in full, then this brief. Follow both.
2. **Only action `▶ Current tasks`**, top to bottom.
3. The every-prompt hook syncs the docs and shows new `progress.md` entries. Handle any open
   `⚠️ Conflicts: @ahmed` first.
4. **Each finished feature** goes through the `ship` skill. **Each finished task**, feature or not, gets a
   `progress.md` entry and a ✅ here in the same turn. In this brief you may publish status only (✅/🟡, the Done
   log, Waiting on, a START HERE note); new tasks come from a docs owner.
5. `debug` on every issue. Anything 🟠 is the user's decision (CLAUDE.md §1).

**Conflict tags:** `[⚠ conflicts with @name: what]` marks a task that touches someone else's area or a shared contract.
Agree with them before merging.

**START HERE (2026-11-14 23:40, from @ahmed's task sweep):** the demo is now an SSD swap on Ahmed's laptop (the whole
team, 23:03). The contract, relay, fakes and sample guide are on `main`; the deadlines are in `PROJECT.md` → Clock,
and the walking skeleton is the next one. Your open items are tasks 8 to 13.

---

## 1. Ownership
**Owns:**
- `relay/`: the Node server every message goes through.
- `contracts/` and `fixtures/`: the protocol, the sample guide, the fake phone and the fake expert.
- The labelling endpoint (the AI feature's server side).
- `hardware/`: the UNO Q rig on the demo set (the RS feature), and the path its messages take.
- The team kit (`scripts/`, `kit/`, `team.conf`) and the shared docs on `context`.

**Does NOT touch:**

| Area | Owner |
|---|---|
| `ios/` | @salman |
| `dashboard/src/scene/`, the dashboard shell, the splat files, `docs/remote-assist/` | @max |
| `dashboard/src/guide/`, `assets/`, the pitch material, the demo set itself | @laura |

**Shared** (flag every edit in `progress.md` → `⚠️ Conflicts`): `contracts/protocol.ts` and `fixtures/*` are yours,
but all three teammates build on them, so every change after the first version is flagged to all three.

## 2. Contract and guardrails
**Scope contract.** ahmed is building:
- One agreed protocol file, with fakes good enough that the phone and the dashboard never wait for each other.
- A relay that keeps the latest guide and step, replays them on reconnect, and carries WebRTC signalling.
- The rule for what happens when the phone comes back after being offline.
- An endpoint that labels parts of the scan.
- The UNO Q and camera on the set that notice the cable really moved, tick the step and warn on a wrong port.

**Out of scope:** anything drawn on screen, on either side.

**Guardrails:**
- **The guide must never depend on video, the AI labels or the hardware.** The relay treats those as extras.
- Each new package, the LLM provider, and the resync rule are 🟠 decisions for you before any code.
- API keys stay in `.env` on the machine running the relay. Commit `.env.example` only.
- From Max's `docs/remote-assist/open-questions.md` § 3: a laptop on venue Wi-Fi can't be reached from a phone on 4G, so the
  relay may need a public address (a tunnel is a new dependency, so 🟠); keep a one-hotspot fallback. He also suggests
  sending the camera pose and lens data with each video frame.
- The rig is the first thing to drop if the relay, protocol or resync fall behind: three people wait on those.

---

## 3. ▶ Current tasks (2026-11-14), in order
*Status: ⬜ not started · 🟡 in progress · ⏸ blocked · ✅ done*

> 📨 **From @max (2026-11-15 02:39, board entry):** the relay runs on Max's laptop on port 8080 and the dashboard
> connects (your item 2 / task 10: left are the phone and rig on the hotspot, and the run sheet). Scans are now kept
> in git (`dashboard/public/scans/`, PR #9), reversing the git-ignored folder in your 01:45 plan: say if that's a
> problem. Your relay client and calibration maths are merged and in use.

> 📨 **From @max (2026-11-15 03:15):** on `main` now: the phone's position shows in the 3D view (from `pose`),
> AI labels with a part search (dashboard only), and drag handles on the selected object that fire
> `onObjectMoved` once per drag. For the demo, `--labels` needs Anthropic credentials on Max's laptop (Max sets
> them, never in the repo). Ask on the board: could the relay take its save file from an env var or flag, so a
> test relay never shares `relay/state.json` with the live one?

> 📨 **From @max (2026-11-15, PR #10):** `docs/vault/` on `main` explains the project in plain words for people
> and judges. Please skim the note about your part and correct anything wrong: `relay.md`, `messages.md`, `rig.md`, and the
> first runbook `running-the-demo.md` (yours to own if you'd rather).

**▶ The plan to the deadline (from @ahmed, 2026-11-15 01:45). Do these first, in this order; the older tasks below keep
their detail.** Why: the phone side is nearly there, but the dashboard is still a viewer with no relay connection,
so we climb a ladder: rung 0 the real phone plays a prepared guide; rung 1 the dashboard connects and sends it;
rung 2 a guide built in the scan lines up on the phone; rung 3 the extras. Decisions: `PROJECT.md` → Decision log.
1. ✅ (01:47, `8756560` and `b9a5e86`, both on `main`) P0 **Relay: the tap receipt**, then **one calibration per scan**. Each ships alone with tests; contract
   comments updated; `fixtures/fake-phone.ts` waits for receipts, as Salman's reference.
2. ⬜ P0 **Relay on Max's laptop** and the run sheet (task 10).
3. 🟡 (01:58: written and tested on `ahmed-dashboard` `dbb708a`; waits for PR #6 to reach `main`) P0 **`dashboard/src/relay/client.ts`**, once Max agrees: hello as `expert`, reconnect, typed `send` and `on`;
   tested with `node --test` against `startRelay`. On `main` once PR #6 is in, else on a branch cut from `max-scene`.
4. 🟡 (01:58: same branch, same wait) P0 **`dashboard/src/scene/calibration.ts`**, once Max agrees: `solveCalibration(corners, marker)` with tests.
5. ⬜ P0 **`fixtures/ssd-swap-guide.json`**: Laura's steps, positions by ruler, checked by `checkGuide` (rung 0).
6. ⬜ **Before the SSD is first pulled:** back up (task 13) and have the BitLocker recovery key on your phone. An
   M.2 slot is rated for only tens of insertions, so keep rehearsals few. Push before every opening.
7. ⬜ P1 **The rig on its hardware** (task 9). If the UNO Q can't read the Nicla after an hour on the board, use
   the SSH route in `hardware/README.md`. If it isn't working by the freeze, drop the RS claim rather than fake it.
8. ⬜ P1 **One paid labelling call** once Max's snapshot exists (task 8).
- Decided 01:55: no chat (Salman's PR #7). Yours to decide: a per-step scan field on `Step`, only if the manual switch annoys.

1. ✅ **The event's rules and deadlines** (done 2026-11-14 20:30; still unknown: criterion weights, the cap on challenges,
   licence and public-repo rules, all marked _not stated_ in `EVENT.md`)
   - Paste the schedule, rules and judging criteria; fill `EVENT.md` and `PROJECT.md` → NOW → Clock. Check whether
     one project may enter four sponsor challenges.
   - *Done when:* the Clock has a submission deadline and `EVENT.md` §1–§4 are filled.
2. ✅ **`contracts/protocol.ts` and the sample guide** (done 2026-11-14 20:59, `1fcc4c3`. Labels left out on purpose: they
   arrive with task 8's endpoint, whose provider isn't decided)
   - Start from the draft in `docs/remote-assist/architecture.md`. Add what it lacks: marker calibration, WebRTC
     signalling, `step.verified`, labels. Decide first: which side solves the alignment and what units positions
     travel in; whether signalling rides this websocket.
   - *Done when:* the file and `fixtures/sample-guide.json` are on `main` and a board entry flags all three teammates.
   - `[⚠ conflicts with @salman @max @laura: they all build on it]`
3. ✅ **Get the rest of the RS kit** (done 2026-11-14 21:47: the camera is the Nicla Vision, confirmed by the RS staff;
   a USB-C hub is in hand. Moved from @laura 2026-11-14)
   - The RS challenge makes an UNO Q, a camera and USB hubs mandatory. The team has an UNO Q and a Nicla Vision
     (`EVENT.md` §6). Still needed: a USB hub, and a USB webcam if the Nicla doesn't count as the camera. Try the
     Product Loan Library (student ID and table number).
   - *Done when:* a board entry says we have the full kit, or that we don't and the RS feature is parked.
4. ✅ **Fake phone and fake expert** (done 2026-11-14 21:29, `97cde98`)
   - Two small scripts in `fixtures/` that speak the protocol, so each side can be built and tested alone.
   - *Done when:* run against each other, they complete the sample guide.
5. ✅ **The relay** (done 2026-11-14 21:29, `97cde98`: `ws` over plain `ws://` on the hotspot, not HTTPS; see the Decision
   log)
   - Node and `ws` over HTTPS, as planned; confirm the packages first. Keeps the latest guide, calibration and
     step, and replays them to whoever reconnects.
   - *Done when:* the two fakes complete a guide through it, and a fake that reconnects gets the current state.
6. ✅ **WebRTC signalling** (done: the relay has carried `rtc.signal` since 21:29; Salman's call goes through it, his
   23:25 entry; `fixtures/video-test.html` checked in headless Chrome. Decided 23:30: the expert calls the phone)
   - Agree the library with @salman, then carry offer, answer and candidates.
   - *Done when:* @salman's phone and a browser test page connect through the relay.
   - `[⚠ conflicts with @salman and @laura: both ends of the video]`
7. ✅ **Offline resync** (the Neptune North feature) (done 23:09, `32ff3e8`: the latest guide wins, the phone keeps
   its place, the relay stops replaying the current step to phones; the fake phone's `--offline-after` mode)
   - Decide first what happens if the expert edited the guide while the phone was offline. Then accept the phone's
     queued `step.done` on reconnect.
   - *Done when:* the fake phone goes offline mid-guide, finishes, reconnects, and both sides agree on the state.
   - `[⚠ conflicts with @salman: the phone's queue]`
8. 🟡 **Labelling endpoint** (the Accenture feature) (relay side done 23:15, `63b4be1`: Claude on a snapshot, off
   unless `--labels`. Left: one paid live call with your OK, once Max's dashboard sends a snapshot)
   - Decide the provider and what the model looks at with @max. Return labels with positions.
   - *Done when:* @max's search box finds a labelled part from a real response; a canned response is labelled MOCK.
   - `[⚠ conflicts with @max: the label shape]`
9. ⬜ **The hardware check** (the RS feature; plan decided 2026-11-14 21:54, see `PROJECT.md` → Decision log; moved from
   @laura 2026-11-14)
   - The chain (reworked 23:24 for the SSD swap): the Nicla Vision finds a bright sticker on the SSD in named
     regions → prints one line per change
     over USB → the powered hub → a Python app on the UNO Q, joined to the relay as `rig` with `websocket-client` →
     it compares what the Nicla sees with the current step's `expect` and sends `step.verified`, and shows ✓ or ✗ on
     the UNO Q's LED matrix through the Bridge (`research/ledger.md` § 10).
   - Needs first: a **micro-USB data cable** for the Nicla (charge-only cables fail silently), a **charger in the hub's
     power input** (the UNO Q doesn't power the hub), and a **bright sticker on the SSD** (Laura's task 2).
   - 9a 🟡 (23:30: the first run stopped before reaching the Nicla, because `pyserial` didn't install:
     `requirements.txt` must sit in the app's `python` folder beside `main.py`) **5-minute access test before
     anything else:** Nicla on the hub; can an App Lab Python app see and open
     `/dev/ttyACM*`? Reports conflict. If it can't, run the same Python over SSH, outside App Lab.
   - 9b 🟡 (22:27: written as `hardware/nicla/main.py`, not yet run on a Nicla; regions and colour are examples)
     The Nicla script: one region per place (the SSD bay), the colour threshold from OpenMV's Threshold Editor, one
     printed line per change, e.g. `seen=ssd-bay`.
   - 9c 🟡 (22:27: `hardware/unoq/`, tested end to end against the relay with typed-in Nicla lines. 2026-11-15 00:51: packaged as
     an App Lab app, `python/` and `sketch/`, `3b4fd51`; the relay address is a setting at the top of `main.py`. Not yet
     on the board)
     The UNO Q app: read the lines, follow the guide and step from the relay, compare with `expect`, send
     `step.verified`, light the LED matrix.
   - 9d 🟡 (2026-11-15 00:51: written, `hardware/unoq/sketch/sketch.ino` and `show()` in `main.py`, following Arduino's LED
     Matrix Painter example; checked against a stand-in for App Lab's module, not yet on the board) The ✓ / ✗ on
     the UNO Q's LED matrix through the Bridge.
   - *Done when:* taking the SSD out ticks "take it out" and putting it back ticks "put it back", on the dashboard and
     the phone.
   - `[⚠ conflicts with @laura: the rig mounts on her demo set, before it's scanned]`
10. ⬜ **Move the relay to the dashboard laptop** (decided 23:20: your laptop is opened up in the demo)
    - With @max: Node 24, the repo, `cd relay && npm install && npm start`; Anthropic credentials there too if
      labelling is on. Give the phone and the rig the new address.
    - *Done when:* the phone, the dashboard and the rig all connect to it on the hotspot.
11. ⬜ **The walking skeleton** (`PROJECT.md` → Clock)
    - The real phone (PR #4), the real dashboard (PR #6) and the relay play one guide end to end. Chase the two merges,
      run the relay, and be the first to try it.
    - *Done when:* a guide sent from the dashboard plays on the phone and its taps tick on the dashboard.
12. ⬜ **Settle what's left in `PROJECT.md` → Pending**
    - With @max: cut-outs on the phone (his iOS 26.3.1 phone can't draw splats) and what the dashboard does before
      calibration. With @laura: how the pitch answers Neptune North's "no central hub". Ask an organiser whether one
      project may enter all its challenges. Salman's team-code idea for `hello`.
    - *Done when:* each item says decided or parked.
13. ⬜ **Back up your laptop before any rehearsal.** The demo opens it and takes the SSD out.
    - *Done when:* a backup exists and you've checked it opens.

## 4. Done log (newest first)
- 2026-11-15 03:24: the rig ran on its hardware for the first time: App Lab app up, relay connected, Nicla lines read on the UNO Q (task 9a ✅, 9b/9c running; left: tune the sticker colour and region on the real SSD, see a tick, 9d the LED matrix).
- 2026-11-15 01:47: the tap receipt (`8756560`) and one calibration per scan (`b9a5e86`); 41 relay tests. Before that, the plan to the deadline in every brief.
- 2026-11-15 00:51: 9c packaged as an App Lab app and 9d written (`3b4fd51`); 13 rig tests, the chain end to end.
- 2026-11-14 23:40: the task sweep (every brief, five decisions). Code since 22:27, all on `main`: offline resync (`32ff3e8`),
  the video test page (`03827d1`, then the dashboard calls, `6afbfa5`), Claude labelling (`63b4be1`), the rig and the
  sample guide reworked for the SSD swap (`b3a2d0f`). 41 relay tests, 13 rig tests.
- 2026-11-14 22:27: task 9b and 9c written, not yet on hardware: `hardware/` on `main` (`4db2ce6`). 13 rig tests; the UNO Q
  app reported wrong then right through the real relay.
- 2026-11-14 21:47: task 3, the RS kit. UNO Q + Nicla Vision as the camera (RS staff confirmed it counts) + a USB-C hub.
- 2026-11-14 21:29: tasks 4 and 5, the relay and both fakes. `relay/relay.ts`, `relay/server.ts`,
  `fixtures/fake-phone.ts`, `fixtures/fake-expert.ts` on `main` (`97cde98`); 31 tests, type-check clean.
- 2026-11-14 20:59: task 2, the protocol contract. `contracts/protocol.ts`, `fixtures/sample-guide.json`,
  `fixtures/messages.json` and `relay/validate.ts` on `main` (`1fcc4c3`); 15 tests, type-check clean.
- 2026-11-14 20:30: task 1, the event's rules and deadlines. `EVENT.md` §1–§6 and the Clock filled from the notes file.

## 5. Waiting on / owed to others
- 📤 **Owed to @salman @max @laura:** nothing right now.
- 📥 **Waiting on @salman:** the +X/+Z printed edges; PR #4 merged.
- 📥 **Waiting on @max:** PR #6 merged; the relay running on his laptop (task 10). *(@max 02:39: PR #6 ✅ merged; the relay runs on his laptop on 8080, tested with the dashboard; phone and rig not yet tried.)*
- 📥 **Waiting on @laura:** the board, the SSD sticker and the Nicla's spot (her task 2). (`ssd` in the contract: ✅
  00:57, `61a771e`.)

## 6. Working-style notes for the agent
- Verbosity: Level 0.
- Ahmed is the docs owner: run the owner sweep on every prompt (CLAUDE.md §4c).

## 7. Reference (no secrets, ever)
- The plan: `docs/remote-assist/`. Evidence: `research/ledger.md` § 1–4 and 7–9 (Max), § 5, 6 and 10 (the rig).

---
── Archived (superseded — do NOT action) ──
- _(empty)_
