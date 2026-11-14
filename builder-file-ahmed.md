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
- The labelling endpoint (the AI feature's server side) and the path the hardware's messages take.
- The team kit (`scripts/`, `kit/`, `team.conf`) and the shared docs on `context`.

**Does NOT touch:**

| Area | Owner |
|---|---|
| `ios/` | @salman |
| `dashboard/src/scene/`, the dashboard shell, the splat files, `docs/remote-assist/` | @max |
| `dashboard/src/guide/`, `assets/`, `hardware/`, the pitch material | @laura |

**Shared** (flag every edit in `progress.md` → `⚠️ Conflicts`): `contracts/protocol.ts` and `fixtures/*` are yours,
but all three teammates build on them, so every change after the first version is flagged to all three.

## 2. Contract and guardrails
**Scope contract.** ahmed is building:
- One agreed protocol file, with fakes good enough that the phone and the dashboard never wait for each other.
- A relay that keeps the latest guide and step, replays them on reconnect, and carries WebRTC signalling.
- The rule for what happens when the phone comes back after being offline.
- An endpoint that labels parts of the scan, and the path for the hardware's "step verified" message.

**Out of scope:** anything drawn on screen, on either side.

**Guardrails:**
- **The guide must never depend on video, the AI labels or the hardware.** The relay treats those as extras.
- Each new package, the LLM provider, and the resync rule are 🟠 decisions for you before any code.
- API keys stay in `.env` on the machine running the relay. Commit `.env.example` only.

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
3. ⬜ **Fake phone and fake expert**
   - Two small scripts in `fixtures/` that speak the protocol, so each side can be built and tested alone.
   - *Done when:* run against each other, they complete the sample guide.
4. ⬜ **The relay** 🟠
   - Node and `ws` over HTTPS, as planned; confirm the packages first. Keeps the latest guide, calibration and
     step, and replays them to whoever reconnects.
   - *Done when:* the two fakes complete a guide through it, and a fake that reconnects gets the current state.
5. ⬜ **WebRTC signalling** 🟠
   - Agree the library with @salman, then carry offer, answer and candidates.
   - *Done when:* @salman's phone and a browser test page connect through the relay.
   - `[⚠ conflicts with @salman and @laura: both ends of the video]`
6. ⬜ **Offline resync** 🟠 (the Neptune North feature)
   - Decide first what happens if the expert edited the guide while the phone was offline. Then accept the phone's
     queued `step.done` on reconnect.
   - *Done when:* the fake phone goes offline mid-guide, finishes, reconnects, and both sides agree on the state.
   - `[⚠ conflicts with @salman: the phone's queue]`
7. ⬜ **Labelling endpoint** 🟠 (the Accenture feature)
   - Decide the provider and what the model looks at with @max. Return labels with positions.
   - *Done when:* @max's search box finds a labelled part from a real response; a canned response is labelled MOCK.
   - `[⚠ conflicts with @max: the label shape]`
8. ⬜ **Hardware message path** (the RS feature, only if @laura gets a kit)
   - Accept `step.verified` from the rig and pass it to both sides.
   - *Done when:* a fake rig message ticks the step on the fake expert and the fake phone.

## 4. Done log (newest first)
- _(empty)_

## 5. Waiting on / owed to others
- 📤 **Owed to @salman @max @laura:** `contracts/protocol.ts`, the sample guide and the fakes.
- 📥 **Waiting on @salman:** his pick of WebRTC library.
- 📥 **Waiting on @laura:** whether we get an UNO Q.

## 6. Working-style notes for the agent
- Verbosity: Level 0.
- Ahmed is the docs owner: run the owner sweep on every prompt (CLAUDE.md §4c).

## 7. Reference (no secrets, ever)
- The plan: `docs/remote-assist/`. Evidence: `research/ledger.md` § 1–4 (Max) and § 5.

---
── Archived (superseded — do NOT action) ──
- _(empty)_
