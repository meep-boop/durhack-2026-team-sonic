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

**START HERE (2026-11-14, from @ahmed):** the split and the decisions in `PROJECT.md` → NOW were made by Ahmed on
top of Max's round-1 plan. If you disagree with your role or with a decision, say so in a `progress.md` entry
(`📨 To @ahmed`) before building on it. All four of us build at once, each against the fake peers in `fixtures/`,
so nobody waits for anybody. Until `contracts/protocol.ts` lands, use the draft in
`docs/remote-assist/architecture.md` and expect small changes.

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

1. ⬜ **The event's rules and deadlines**
   - Paste the schedule, rules and judging criteria; fill `EVENT.md` and `PROJECT.md` → NOW → Clock. Check whether
     one project may enter four sponsor challenges.
   - *Done when:* the Clock has a submission deadline and `EVENT.md` §1–§4 are filled.
2. ⬜ **`contracts/protocol.ts` and the sample guide** 🟠 (everyone is waiting on this)
   - Start from the draft in `docs/remote-assist/architecture.md`. Add what it lacks: marker calibration, WebRTC
     signalling, `step.verified`, labels. Decide first: which side solves the alignment and what units positions
     travel in; whether signalling rides this websocket.
   - *Done when:* the file and `fixtures/sample-guide.json` are on `main` and a board entry flags all three teammates.
   - `[⚠ conflicts with @salman @max @laura: they all build on it]`
3. ⬜ **Ask about the UNO Q today** 🟠 (moved from @laura 2026-11-14: Ahmed took the rig)
   - The RS challenge needs an Arduino UNO Q and a camera. Find out now whether we can borrow them.
   - *Done when:* a board entry says we have the kit, or that we don't and the RS feature is parked.
4. ⬜ **Fake phone and fake expert**
   - Two small scripts in `fixtures/` that speak the protocol, so each side can be built and tested alone.
   - *Done when:* run against each other, they complete the sample guide.
5. ⬜ **The relay** 🟠
   - Node and `ws` over HTTPS, as planned; confirm the packages first. Keeps the latest guide, calibration and
     step, and replays them to whoever reconnects.
   - *Done when:* the two fakes complete a guide through it, and a fake that reconnects gets the current state.
6. ⬜ **WebRTC signalling** 🟠
   - Agree the library with @salman, then carry offer, answer and candidates.
   - *Done when:* @salman's phone and a browser test page connect through the relay.
   - `[⚠ conflicts with @salman and @laura: both ends of the video]`
7. ⬜ **Offline resync** 🟠 (the Neptune North feature)
   - Decide first what happens if the expert edited the guide while the phone was offline. Then accept the phone's
     queued `step.done` on reconnect.
   - *Done when:* the fake phone goes offline mid-guide, finishes, reconnects, and both sides agree on the state.
   - `[⚠ conflicts with @salman: the phone's queue]`
8. ⬜ **Labelling endpoint** 🟠 (the Accenture feature)
   - Decide the provider and what the model looks at with @max. Return labels with positions.
   - *Done when:* @max's search box finds a labelled part from a real response; a canned response is labelled MOCK.
   - `[⚠ conflicts with @max: the label shape]`
9. ⬜ **The hardware check** 🟠 (the RS feature, only if task 3 found a kit; moved from @laura 2026-11-14)
   - The UNO Q and camera notice which port the cable is in and send `step.verified` through the relay to both
     sides. Decide the detection method first.
   - *Done when:* moving the cable to the right port ticks the step on the dashboard and the phone, and a wrong port
     warns. Before the kit arrives: a fake rig message does the same on the two fakes.
   - `[⚠ conflicts with @laura: the rig mounts on her demo set, before it's scanned]`

## 4. Done log (newest first)
- _(empty)_

## 5. Waiting on / owed to others
- 📤 **Owed to @salman @max @laura:** `contracts/protocol.ts`, the sample guide and the fakes.
- 📥 **Waiting on @salman:** his pick of WebRTC library.
- 📥 **Waiting on @laura:** a spot on the demo set for the UNO Q rig.

## 6. Working-style notes for the agent
- Verbosity: Level 0.
- Ahmed is the docs owner: run the owner sweep on every prompt (CLAUDE.md §4c).

## 7. Reference (no secrets, ever)
- The plan: `docs/remote-assist/`. Evidence: `research/ledger.md` § 1–4 (Max) and § 5.

---
── Archived (superseded — do NOT action) ──
- _(empty)_
