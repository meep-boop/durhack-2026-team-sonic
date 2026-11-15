# Remote Assist: the project doc
*Team Sonic · DurHack 2026 · repo `github.com/meep-boop/durhack-2026-team-sonic` · started 2026-11-14.*

**How to read this:** **NOW** is what's true and in progress today, so start there. **Part A** is the spec. **Part B**
is the design, one section per feature. **Parked** holds what was doable but not chosen. The **Decision log** says why
the system is shaped this way, and **History** says how we got here.
- Event rules and judging: `EVENT.md`. Evidence: `research/ledger.md`. Your tasks: `builder-file-<name>.md`.
- Live status and conflicts: `progress.md` on `main`.

*Italic lines are prompts. Replace them as you fill each section, and leave a section empty rather than invent it.*

---

## NOW (updated 2026-11-15 01:45)

### Headline
**Step-by-step 3D guidance on a phone, built by a remote engineer from a scan of the room, that keeps working when the network is down.**

The idea is Max's (`docs/remote-assist/` on `main` has the full plan). It was taken forward by Max and Ahmed on
2026-11-14 without an `idea-forge` scoring round. The whole team agreed the SSD-swap demo at 23:03.

**Never pitch:**
- "Trained on the Dawn supercomputer": we have no Dawn access. Nor "trained on our DGX Spark" unless the splat on
  screen really was (`research/ledger.md` § 9).
- Any accuracy or speed number we haven't measured on our own set (alignment error, "x times faster than a call").
- That the rig checks the SSD is seated properly: it only sees whether the stickered SSD is in the bay.
- The Gemini assistant's steps as if the expert wrote them: they're AI-generated and labelled so on the phone.
- The market notes in `docs/remote-assist/README.md` → Parked (Dynamics 365 Remote Assist ending, what rival tools
  do). They aren't in `research/ledger.md` yet.

### Clock
*The single home for every deadline. Briefs and chat point here and never copy the times.*

| When | What |
|---|---|
| Sat 14 Nov, 12:00 | Hacking started |
| **Sun 15 Nov, 02:00** | Walking skeleton: the real phone, the real dashboard and the relay play one guide end to end. **Missed** (01:45: the dashboard can't talk to the relay yet; the order to get there is in each brief) |
| **Sun 15 Nov, 07:00** | Feature freeze: after it, only fixes, and no message shape changes |
| **Sun 15 Nov, 10:00** | Demo video recorded |
| Sun 15 Nov, 11:30 | Submit on Devpost (half an hour before the deadline) |
| **Sun 15 Nov, 12:00** | **Submission deadline** on Devpost (use the earliest time any source gives) |
| Sun 15 Nov, from 12:30 | Judging: judges visit tables, so the demo is live |

Source: `EVENT.md` §1 (one notes file, not yet checked against Devpost). The 02:00, 07:00, 10:00 and 11:30 rows were set by Ahmed at 23:30.

### Decisions in force
*One line each, newest first: what, who decided, when. The full record is in the Decision log below.*

| Date | Decision |
|---|---|
| 2026-11-15 | AI-made props: Hunyuan3D 2.1 runs on the team's DGX Spark (Docker fork), building in the background; one photo of a part (the SSD, the screwdriver) becomes a textured 3D model, scaled by hand to its real size, shown on the dashboard first, the phone only if there's time; labelled "AI-generated from a photo" wherever it shows; dropped if it hasn't built by about 06:30 (Max, 04:05; `research/ledger.md` § 18) |
| 2026-11-15 | The expert's dashboard becomes a finished product screen before cut-outs: a header with relay / phone / rig lights and a Call button that opens Salman's call page in its own window, a live strip that shows the person's step and the offline moment, plain prompts with the debug text behind a key, one calm dark look on both halves (Laura's panel restyled by Max's agent once she agrees, colours and spacing only); cut-outs follow it (Max, 03:40) |
| 2026-11-15 | Scans are kept in git (`dashboard/public/scans/`), not per machine, so the team and the judges see the same files; a scan's file name is its calibration id, so never overwrite one (Max, 02:39; reverses the git-ignored folder in Ahmed's 01:45 plan) |
| 2026-11-15 | The dashboard loads both splat and mesh scans from Scaniverse; we demo whichever scan of the set comes out better, and the pitch names the kind honestly (Max, 02:32) |
| 2026-11-15 | No placing before calibration: the dashboard's `pickPoint()` resolves to null and objects aren't drawn until the scan on screen is calibrated (Max, 02:16; Ahmed recommended it) |
| 2026-11-15 | No text chat: Salman's `chat` message stays out of the contract and the relay (Ahmed, 01:55) |
| 2026-11-15 | A plan to the deadline as a four-rung ladder: prepared guide on the phone, dashboard sends it, a guide built in the scan lines up, then extras (Ahmed, 01:45; `.omc/plans/remote-assist-to-deadline.md` on his machine, tasks in the briefs) |
| 2026-11-15 | Taps get a receipt: the relay sends each `step.done` it accepts, and each repeat, back to its sender; the phone drops a tap only on its receipt (Ahmed) |
| 2026-11-15 | Two scans, closed and cover off, sharing the marker; the relay keeps one calibration per scan; a manual switch on the dashboard (Ahmed) |
| 2026-11-15 | Salman's `ios/expert-call/` page is the call screen; no React video panel (Ahmed) |
| 2026-11-15 | Ahmed's agent builds the dashboard's relay connection and the calibration maths, once Max agrees; cut-outs and 3D dragging stay in scope, after rung 2 (Ahmed) |
| 2026-11-15 | Max is a second docs owner; the 02:00 walking-skeleton row stays in the Clock, marked missed (Ahmed) |
| 2026-11-14 | Nobody sprays Ahmed's laptop for the scan; it's scanned as it is (Ahmed) |
| 2026-11-14 | Internal deadlines: walking skeleton 02:00, feature freeze 07:00, demo video 10:00, submit 11:30 (Ahmed) |
| 2026-11-14 | Salman's Gemini assistant and ElevenLabs voice stay as optional, AI-labelled extras, entered for MLH Gemini and ElevenLabs; not Vultr or Tiger Data (Ahmed) |
| 2026-11-14 | The expert calls the phone: the dashboard makes the WebRTC offer and the phone answers (Ahmed, matching Salman's build; reverses "the phone offers") |
| 2026-11-14 | The relay runs on the dashboard laptop in the demo, because Ahmed's laptop is opened up (Ahmed) |
| 2026-11-14 | The rig checks `expect: { region, present }`: a bright sticker on the SSD, seen in or gone from the SSD bay (Ahmed) |
| 2026-11-14 | The demo is an SSD swap on Ahmed's laptop: take its own SSD out and put the same one back (the whole team) |
| 2026-11-14 | Labelling: the dashboard sends a snapshot and the relay asks Claude (`claude-opus-5-5`) for labels at pixel positions; off unless the relay starts with `--labels` (Ahmed) |
| 2026-11-14 | Offline: the latest guide wins and the phone keeps its place by step id; the relay never replays the current step to phones (Ahmed) |
| 2026-11-14 | A model moves along the guide's `axis`; the builder fills it from the model's own +Y (Ahmed) |
| 2026-11-14 | Model conventions: metres, +Y up, the working tip at the origin; one build script makes both formats (Laura) |
| 2026-11-14 | WebRTC on the phone: Google's WebRTC framework (`stasel/WebRTC`), peer to peer on the hotspot (Salman) |
| 2026-11-14 | Scene API: the guide builder keeps the only copy of the guide and hands the 3D view a whole step; the 3D view reports edits back (Max) |
| 2026-11-14 | The splat upgrade route is the team's DGX Spark, not Dawn: we have no Dawn access (Max) |
| 2026-11-14 | Dashboard: Vite 8 + React 19 + TypeScript, plain three.js + Spark 2.4 behind `scene/api.ts`, no React Three Fiber, zustand when needed; proven by a spike with a kill test (Max) |
| 2026-11-14 | Superseded 23:24: `expect: { port, cable }`, now `{ region, present }` (Ahmed) |
| 2026-11-14 | The rig: colour blobs on the Nicla Vision, USB through the hub to the UNO Q, `websocket-client` to the relay, ✓/✗ on the LED matrix (Ahmed) |
| 2026-11-14 | The RS camera is the Nicla Vision; the RS staff confirmed it counts (Ahmed) |
| 2026-11-14 | Anyone on the hotspot can connect; the relay enforces who may send what, by role (Ahmed) |
| 2026-11-14 | Phone and dashboard reach the relay over plain `ws://` on the team hotspot (Ahmed) |
| 2026-11-14 | The relay saves guide, step, calibration and progress to `relay/state.json` on each change (Ahmed) |
| 2026-11-14 | The relay uses the `ws` package; `@types/ws` and `@types/node` are dev-only (Ahmed) |
| 2026-11-14 | Keep the fake phone and fake expert, built with the relay (Ahmed) |
| 2026-11-14 | The protocol contract is on `main`: `contracts/protocol.ts`, `fixtures/`, `relay/validate.ts` (Ahmed) |
| 2026-11-14 | `typescript` is a dev-only dependency of `relay/`, for type-checking the contract (Ahmed) |
| 2026-11-14 | Guide positions travel in the marker's frame, in metres; the dashboard converts from splat coordinates (Ahmed) |
| 2026-11-14 | Live view stays WebRTC, re-confirmed after reading Max's research; signalling rides the relay websocket (Ahmed) |
| 2026-11-14 | The protocol contract is TypeScript types only, plus JSON examples; the Swift app mirrors them by hand (Ahmed) |
| 2026-11-14 | The phone app is pure native Swift; Salman's Expo app is dropped (Ahmed) |
| 2026-11-14 | Ahmed builds the UNO Q rig, not Laura (Ahmed) |
| 2026-11-14 | All four build in parallel from the first hour, each against fake peers (Ahmed) |
| 2026-11-14 | Enter Neptune North, Accenture, Marshall Wace and RS (Ahmed) |
| 2026-11-14 | Scaniverse is the main splat route; Dawn is an upgrade once someone has logged in (Ahmed) |
| 2026-11-14 | A cut-out shows on the phone as a highlight box plus the closest built-in model (Ahmed) |
| 2026-11-14 | Live view is WebRTC from the start (Ahmed, against the recommendation) |
| 2026-11-14 | The scan is lined up with the room by a printed marker under world tracking (Ahmed) |
| 2026-11-14 | The split: Salman phone app, Max dashboard 3D view and splats, Laura guide builder, assets, set and pitch, Ahmed relay, protocol, sync and the UNO Q rig (Ahmed) |
| 2026-11-14 | The phone app is native Swift, built in Xcode, ARKit + RealityKit (Max round 1; confirmed twice by Ahmed) |
| 2026-11-14 | Round 1: the expert builds the guide and the user follows it; guides can be live or prepared; built-in models plus cut-outs; preset actions; the user taps Next; boxes stay alongside models (Max; agreed by Ahmed) |

**Agreement so far:** all four. Salman accepted native Swift and the phone role (22:10); the whole team agreed the
SSD-swap demo (23:03).

### Pending decisions
*Open questions, each with an owner and what it's waiting on. Unconfirmed leanings go here too, marked **not decided**.*
- **Reopen: cut-outs on the phone.** Ahmed chose "box plus a built-in model" on the premise that RealityKit can't
  draw splats. Max's research (`research/ledger.md` § 1, § 4), published the same hour, says RealityKit on iOS 27.2+
  can, and recommends real splat cut-outs with the model as the fallback. Owner: Ahmed + Max. **Not decided** whether
  to change it; the box-and-model path is being built either way. **New fact:** Salman's phone is on iOS 26.3.1
  (22:10), below the iOS 27.2 that RealityKit splats need, so real cut-outs can't run on it without an OS update.
- **Settled 20:45: live view stays WebRTC** (Ahmed, after reading § 2; see the Decision log). The original note:
  Ahmed chose WebRTC from the start. Max's research (`research/ledger.md` § 2) recommends
  JPEG frames over the websocket first and LiveKit Cloud as the upgrade, and warns that 4G may need a TURN server.
  Owner: Ahmed + Max + Salman. The decision stands until Ahmed changes it.
- **Settled 22:10 by Salman: WebRTC library on iOS.** Google's WebRTC framework (`stasel/WebRTC`). (Signalling settled: it rides the relay websocket as a
  pass-through message.)
- **Settled 20:59: which side solves the alignment.** The dashboard, and positions travel in the marker's frame in
  metres (Ahmed; Decision log). The original question: which side solves the alignment, and what units positions
  travel in. Researched in `research/ledger.md` § 6.
- **Which way the marker frame's +x and +z point across the print.** Owner: Salman, with an axis marker on the
  phone. Provisional in `contracts/protocol.ts` until then.
- **Settled 02:16 by Max: no placing before calibration.** Until the scan on screen is calibrated, `pickPoint()`
  resolves to null and no objects are drawn, so no position measured from nothing can reach the phone. Built on
  `main` (`0fddd63`).
- **Settled 22:55 by Ahmed: offline conflict rule.** The latest guide wins and the phone keeps its place and done
  steps by step id; the relay no longer replays the current step to phones, which closes the gap below. The
  original note: what happens if the expert edits the guide while the phone is offline.
  A concrete case the relay shows today: a phone that taps Next offline, then reconnects, is first sent the
  relay's last known step (older than where the phone is) and only then sends its queued taps. The phone or the
  rule must handle that order.
- **Settled 22:55 by Ahmed: LLM provider for labelling, and what it looks at.** Claude (`claude-opus-5-5`) on a
  snapshot of the dashboard's 3D view; the relay side is on `main`. The original note: renders of the splat, or
  camera frames.
- **Settled 22:20: dashboard and relay libraries.** Relay: `ws` (Ahmed). Dashboard: Vite + React + three.js + Spark
  (Max). The original note: proposed in the plan; each is its builder's call.
- **Settled 22:30 by Laura: model formats.** One build script makes glTF and USDZ from the same geometry.
- **Settled 23:03 by the whole team: the demo set.** Ahmed's laptop on a board with the marker; the guide takes
  its own SSD out and puts it back.
- **Settled: UNO Q detection method.** The kit is in hand (21:47); the Nicla Vision finds a bright sticker in
  named regions (Ahmed, 21:54, reworked for the SSD at 23:24).
- **Resolved 23:35 by Max (PR #1, not merged): `docs/remote-assist/open-questions.md` was out of step with this page.** Its question 1 (alignment) is
  marked "needs thought, not assigned", but Ahmed decided option B, the printed marker. Its questions 2 and 3 are
  framed as decisions for Max, and Max recommends the opposite of what Ahmed chose (the two "Reopen" items above).
  Owner: Ahmed + Max, to settle together. Max's file is his to update.
- **Does the relay need a public address?** A phone on 4G can't reach a laptop on venue Wi-Fi (open-questions § 3).
  A tunnel is a new dependency. Owner: Ahmed. **Not decided.**
- **May one project enter four sponsor challenges, plus the MLH Gemini and ElevenLabs prizes?** Owner: Ahmed. The opening slides don't say. **Ask an organiser.**
- **Settled 23:30 by Ahmed: the internal deadlines.** See the Clock.
- **Neptune North wants no central hub; our relay is one.** How the pitch shows the phone acting on its own (`EVENT.md` §4).
  Owner: Ahmed + Laura. **Not decided.**
- **Live or prepared guides first?** (Max's open question.) Overtaken by "all in parallel": the phone plays a
  prepared sample guide from its first task, and live building arrives with the guide builder.
- **A shared team code in `hello`** (Salman's security note): with plain `ws://` and no login, anyone on the hotspot
  can push a guide. A code would be a contract change. Owner: Ahmed. **Not decided**; it matters more if the relay is
  ever reachable off the hotspot.
- **Laura's four asks on the scene API** (her 23:04 entry). Owner: Max. Ask 1 (how the guide panel gets the scene API
  and where it mounts) blocks the guide builder.
- **Claude labelling has never made a live call.** One paid test, with Ahmed's OK, once Max's dashboard can send a
  snapshot. Owner: Ahmed.

- **Salman's `chat` message** (PR #7): `{ id, from, text, at }`, the relay keeping the last 50 and replaying
  them. A contract change and new stored data. Owner: Ahmed. **Settled 01:55: no chat** (Ahmed); see Parked.
- **Should a step remember its scan?** An optional field on `Step`; only if the manual switch annoys. Owner:
  Ahmed. **Not decided.**
- **The phone scales the guide by ARKit's size estimate.** Measure alignment with and without. Owner: Salman.
  **Not decided.**

### Active tasks (details in each brief)
| Who | Now |
|---|---|
| Ahmed | The tap receipt and a calibration per scan in the relay; the dashboard's relay connection and calibration maths; the rung-0 guide file; the rig on its hardware |
| Salman | Merge `salman-ios-polish`; the smoke test on the real phone; post the +X/+Z edges; the tap receipt; measure alignment |
| Max | The dashboard as a product screen (header and lights, live strip, one look) ✅ 03:55; then cut-outs; AI-made props building on the DGX Spark in the background (§ 18); the two rescans once Laura's board is ready |
| Laura | The board with corner stops; the real SSD-swap steps; the guide panel; README, video, Devpost |

Asked for by Max (19:40 board entry): "Pick and get the demo objects" is Laura's task 3. "Check we have a Mac with
Xcode" is answered: yes, per Ahmed.

### Blockers only humans can clear
*Accounts, API keys, access, team registration, hardware, asking the organisers.*
- **Cleared 22:20: Dawn login.** We have no Dawn access; the team has a DGX Spark instead (Max).
- **Back up Ahmed's laptop before any rehearsal.** The demo opens it and takes the SSD out. Ahmed. It's his only
  machine: push before every opening, and have the BitLocker recovery key on a phone first.
- **Keys and credit:** Salman's Gemini and ElevenLabs keys (his git-ignored `Secrets.xcconfig`); Anthropic
  credentials on the laptop that runs the relay, if labelling is on. Neither has been tested live.
- **For the rig: a micro-USB data cable** for the Nicla Vision (not charge-only) and **a charger for the hub's power
  input**. The Nicla is on the hub; the access test shows whether the cable carries data. Ahmed.
- **Cleared 2026-11-14 21:47: a camera and a USB hub** for the RS challenge. The Nicla Vision is the camera (RS staff
  confirmed) and Ahmed has a USB-C hub.
- **Cleared 2026-11-14 21:31: a paper printer** for the marker. Laura printed it, matte, 180 mm (`assets/marker/`).
- **Hall Wi-Fi is slow.** Plan on a phone hotspot for the demo.
- **Answered 22:10 by Salman: Xcode and iOS versions.** An iPhone 16 on iOS 26.3.1, built with Xcode 26.0.1. The
  original note: the Mac needs Xcode to build at all. If cut-outs are ever drawn as real splats on the
  phone, it needs Xcode 27 and the demo iPhone on iOS 27.2 or later (`research/ledger.md` § 1). Salman to check both.
- **Cleared 23:03: the demo objects.** The set is Ahmed's laptop on a board (the whole team).
- **Cleared 21:31: printing the marker** (Laura). Spares: not confirmed.

---

# Part A: Spec

## 0. One page
- **One-liner:** Step-by-step 3D guidance on a phone, built by a remote engineer from a scan of the room, that keeps working when the network is down.
- **The person it's for, and the harm or pain:** _a named persona and a sourced number_
- **What it does:** _3–5 bullets_
- **What's real in the demo vs. simulated:** _a list: be exact, because judges ask_
- **Novelty line:** _what exists today, and the one thing none of it does that we do_
- **Track / challenges entered:** Neptune North, Accenture, Marshall Wace, RS (decided by Ahmed; the fit for each is in
  `docs/remote-assist/README.md`). Whether one project may enter all four is not checked yet.

## 1. Problem and evidence
*Cite `research/ledger.md` by section. Only KEEP sources carry a load-bearing number.*

## 2. Goals, non-goals, success metrics
| Goal | Metric | Target | How we measure it |
|---|---|---|---|

**Non-goals:** _what we deliberately won't do this weekend_

## 3. Users, journeys and outputs
*Who uses it, the 2–3 journeys the demo shows, and what each output is: a decision, not just a label.*

## 4. Features
| # | Feature | Owner | Priority | Status |
|---|---|---|---|---|
| F1 | Marker alignment: the guide sits on the real equipment | Salman, Max | P0 | 🟡 phone side on `salman-ios`; dashboard calibration not started |
| F2 | Step player on the phone: box, animated model, Next | Salman | P0 | 🟡 on `salman-ios` (PR #4) |
| F3 | Protocol, fake peers and relay | Ahmed | P0 | ✅ on `main` |
| F4 | Dashboard 3D view: splat, click to place | Max | P0 | 🟡 shell and splat on `max-scene` (PR #6); click-pick not started |
| F5 | Guide builder: step timeline, model and action pickers | Laura | P0 | 🟡 on `laura-guide`; blocked on Max's ask 1 |
| F6 | Built-in models in glTF and USDZ | Laura | P0 | ✅ six on `main`; `ssd` to add |
| F7 | The demo set (the laptop on a board), scanned | Laura, Max | P0 | ⬜ |
| F8 | Offline play and resync (Neptune North) | Salman, Ahmed | P0 | 🟡 relay and fake phone ✅; phone side partial |
| F9 | Live camera over WebRTC | Salman, Ahmed | P1 | 🟡 phone and expert page on `salman-ios-polish`; that page is the call screen, no dashboard panel |
| F10 | Cut-outs from the scan | Max | P1 | ⬜ |
| F11 | Find a part by name, AI labels (Accenture) | Max, Ahmed | P1 | 🟡 relay side on `main`; search box not started; no live call yet |
| F12 | Hardware check with the UNO Q (RS) | Ahmed | P1 | 🟡 code on `main`, reworked for the SSD; access test in progress |
| F14 | Gemini laptop assistant and ElevenLabs voice (MLH), optional | Salman | P1 | 🟡 on `salman-ios` |
| F13 | The user's position shown in the scan | Max | P1 | ⬜ |
| F15 | The dashboard's relay connection and calibration maths | Ahmed | P0 | ⬜ once Max agrees |

**The rule across all of them:** the guide (F1–F8) must never depend on video, the AI labels or the hardware.

*P0 = the demo fails without it. P1 = it makes the demo better. Parked = doable, decided against (see Parked).*

## 5. Architecture
The diagram, components, alignment maths and draft protocol are in `docs/remote-assist/architecture.md` on `main`
(owner: Max). It isn't copied here, so there's one version. Changed since it was written: alignment is decided
(printed marker), live video is decided (WebRTC), and Scaniverse comes before Dawn. The agreed protocol will live in
`contracts/protocol.ts`.

## 6. Tech stack
| Layer | Choice | Why | Checked on the platform? |
|---|---|---|---|
| Phone app | Pure native Swift, ARKit + RealityKit, no Expo (**decided**) | iPhone Safari has no WebXR AR; Salman is confident in Swift | Yes: iPhone 16, iOS 26.3.1, Xcode 26.0.1 |
| Alignment | Printed marker, 15 to 20 cm, as an ARKit detection image under world tracking (**decided**) | `research/ledger.md` § 3, § 5 | No: error to be measured on our set |
| Live video | WebRTC with a custom source fed from AR frames, signalling over the relay websocket; the expert calls, the phone answers; Google's WebRTC framework on the phone (**decided**) | Ahmed; library Salman | On `salman-ios`, not merged; the browser side checked in headless Chrome |
| Splat | Scaniverse export (**decided** as main route); the DGX Spark as the upgrade (**decided**, Max) | No Dawn access; pipeline in `research/ledger.md` § 9 | No |
| Dashboard | Vite 8 + React 19 + TypeScript; plain three.js + Spark 2.4 behind `dashboard/src/scene/`; no React Three Fiber (**decided**, Max) | `research/ledger.md` § 7, § 8 | Yes: Spark's sample splat runs (`max-scene`, not merged yet) |
| Relay | Node 24 + `ws` 8.23, plain `ws://` on the hotspot, state in a JSON file (**decided**) | No build step; HTTPS needs certificates iPhones won't trust | Yes: runs and tested on Ahmed's laptop |
| AI labelling | Claude `claude-opus-5-5` through `@anthropic-ai/sdk` on the relay: snapshot in, labels at pixels out; off unless `--labels` (**decided**) | Ahmed | No live call yet |
| Hardware check | UNO Q + Nicla Vision + powered USB-C hub; a colour sticker in named regions; Python with `websocket-client` (**decided**) | `research/ledger.md` § 10 | Kit in hand; access test in progress |

## 7. Data
| Source | What | Licence | Where it lives | Real / simulated |
|---|---|---|---|---|

## 8. Security and privacy
*Secrets handling, personal data (ideally none), auth, what's public.*

## 9. Demo plan
*The beat sheet, to the second (the `pitch` skill has the skeleton). What's on screen at each beat, and who speaks.*

## 10. Team, timeline, cut order
- **Who owns what:** `progress.md` → Who owns what.
- **Timeline:** NOW → Clock.
- **Build order after the guide lines up (decided by Ahmed, 2026-11-15 01:45; last is first to go):** the user's position
  (F13), the call page (F9), the rig (F12), AI labels (F11), 3D dragging, cut-outs (F10). The earlier proposal
  (never decided) cut F12 first.
- **Never cut:** proposed, **not decided**: F1–F8, a guide that lines up, plays, and survives the link going down.

## 11. Risks and judge questions
| Question a judge will ask | Our answer |
|---|---|
| What's actually real here? | |
| Why not just use <the obvious existing tool>? | |
| Does it work beyond the demo data? | |

---

# Part B: Design per feature

## How to use this
- **Building?** Read the summary table, then only your feature's section. Each section ends with a **Spec**: build
  from that.
- **🟠 marks an open team decision.** It has a recommendation, but nothing marked 🟠 is decided until the user picks.
- **Facts that shape everything:** _platform limits, verified versions, API quotas, each with its evidence._

## Summary: feature → choice → why
| # | Feature | Choice | One-line why |
|---|---|---|---|

## B1. _feature name_
**Options**
- **A.** _what · upside · cost_
- **B.** _what · upside · cost_

**Choice:** _the option, and who decided_

**Spec:** _the finished state, constraints, acceptance ("done when …")_

---

## Parked
*Doable, decided against. Each item says why, and what would bring it back.*
- **Text chat between phone and expert** (parked 2026-11-15 01:55, Ahmed): Salman's PR #7 proposed a `chat`
  message with the relay keeping the last 50. The team doesn't want chat; the call carries voice. Would come back
  after the event, as a new contract message.
- **Training the splat on Dawn** (parked 2026-11-14): we have no Dawn access; the DGX Spark replaces it. Would come
  back if Dawn access turns up.

## Decision log
*Full records, newest first. NOW → Decisions in force holds the one-line versions.*

## 2026-11-15 04:05 — AI-made props on the DGX Spark
- Context: the team's DGX Spark was idle. Max asked whether it could turn pictures of a thing into 3D models.
  There are two jobs. A scan (100s of photos → a measured splat or mesh, § 9, § 12, § 14) takes hours and has no proof
  it beats Scaniverse. A generative model (one photo → a guessed, textured 3D model, § 18) takes minutes per object
  but invents the hidden sides and has no real size.
- Chose (Max): **the generative route, with Hunyuan3D 2.1**, for props only (the M.2 2280 SSD, the #0 screwdriver),
  never for the set we calibrate against. Hunyuan3D 2.1 is the only such model with a timed run on a Spark (about
  3 min per textured model, forum users; § 18).
- How: the `dr-vij/Hunyuan3D-2.1-DGX-Docker` fork, built over SSH by Max's agent while Max works on the dashboard. The
  build compiles Python and Blender's `bpy` from source, so it's mostly waiting. Each prop is scaled by hand to the
  part's real size (SSD 22 × 80 mm) and shown on the dashboard first; the phone needs USDZ (§ 15) and Salman's time,
  so it comes only if there's time.
- Honesty: a prop says "AI-generated from a photo" wherever it shows. "Made on our DGX Spark" only if it was.
- Rejected: rescanning the set on the Spark (hours, unproven against Scaniverse, needs a rescan); TRELLIS.2 (no
  timed Spark run, and its setup compiles FlashAttention); SAM 3D Objects (no ARM report); not tonight (the Spark
  stays unused).
- Revisit if: the build hasn't finished by about 06:30, or the first SSD model looks wrong. Then drop it; nothing
  else depends on it.

## 2026-11-15 03:40 — The expert's dashboard as a product screen
- Context: the dashboard did nearly everything the plan asked, but read as a test screen: debug text in the corner,
  no title, the person's progress only as small ticks, and no phone online / offline anywhere, although the relay
  already sends `presence`. Judges watch this screen for the whole demo, and the whole presentation must be under 5
  minutes (Laura, 03:30), so it has to read at a glance.
- Chose (Max): **a finished product screen first, then cut-outs.** A header with relay, phone and rig lights from
  `presence`, the Closed / Open switch and a **Call** button; a live strip with the person's current step, ticks,
  the rig's ✓ / ✗, and an amber "phone offline, still working on its own" state with a timer; plain prompts in place
  of the debug text, which stays behind a key for the team.
- Chose (Max): **Max's agent restyles Laura's panel** (`GuidePanel.css`, colours and spacing only, no behaviour) once
  she agrees on the board, so both halves share one look while she works on the board and the judges' material.
- Chose (Max): **the call stays Salman's page in its own window**, opened by the Call button
  (`http://<host>:8000/?relay=<relay>` by default, `?call=` to change it). Keeps Ahmed's 01:45 decision.
- Chose (Max): **a calm control room look**: dark, quiet, one strong element (the live strip, amber when the phone is
  offline). No new font or package.
- Rejected: cut-outs first (the screen would stay a test screen, and the phone can't draw cut-outs on iOS 26.3.1);
  a quick tidy then cut-outs (both thinner); Laura restyling her own panel (two looks if she runs out of time);
  embedding the call page (reopens Ahmed's decision, and camera / mic permission in an embedded page can fail);
  an ops-screen look (busier for judges); copying the call page's purple (the most common AI-app look).
- Revisit if: Laura says no to the restyle (then her panel keeps its look, or she takes the colours herself).

## 2026-11-15 01:45 — The plan to the deadline
- Context: a read of every branch found the phone nearly complete (`salman-ios-polish`, not on `main`) and the
  dashboard still a splat viewer: no relay connection (nobody owned it), no calibration, picking, object drawing or
  guide screen. The 02:00 walking skeleton couldn't happen.
- Chose (Ahmed): a ladder so one rung always works. Rung 0 the real phone plays a prepared, ruler-measured guide;
  rung 1 the dashboard connects and sends it; rung 2 a guide built in the scan lines up; rung 3 the extras, in the
  order user's position, call page, rig, AI labels, 3D dragging, cut-outs.
- Chose (Ahmed): **a tap receipt.** The phone dropped a tap when the socket write succeeded, so a silently dead
  hotspot could lose one. The relay echoes each accepted or repeated `step.done` to its sender. No new shape.
  Rejected: leaving it, and not claiming "no tap is lost".
- Chose (Ahmed): **two scans** sharing the marker, one calibration per scan in the relay, a manual Closed / Open
  switch. Rejected: one scan cover off; one scan cover on with typed SSD positions; deciding later.
- Chose (Ahmed): Salman's call page instead of a React video panel; cut-outs and 3D dragging stay, after rung 2
  (Ahmed's agent had recommended parking both); Ahmed's agent builds `dashboard/src/relay/` and
  `dashboard/src/scene/calibration.ts` once Max agrees; Max becomes a docs owner because Ahmed's laptop, his only
  machine, is the demo prop; the Clock is left alone with 02:00 marked missed.
- Not decided: Salman's `chat` message; how the pitch
  answers "no central hub"; scaling by ARKit's size estimate on the phone (Salman, after measuring).

## 2026-11-14 23:30 — Call direction, Salman's extras, deadlines, the laptop scan
- Chose (Ahmed): the expert calls the phone, matching Salman's working build, which reverses "the phone offers" from
  22:55 (`fixtures/video-test.html` changed to match); Salman's Gemini assistant and ElevenLabs voice stay as
  optional, AI-labelled extras, entered for MLH Gemini and ElevenLabs; the Clock's internal deadlines; nobody sprays
  the laptop for the scan
- Because: Salman's build already works; his extras need no new work; the walking skeleton has to come early
- Rejected: Salman reworking his call; hosting the relay on Vultr and logging to Tiger Data (hours of new relay work,
  and a public relay would need a join key); taking the extras out; spraying the laptop (Max's correction: it was a
  research idea, never his request)

## 2026-11-14 23:24 — What the rig checks in the SSD swap
- Chose: `expect: { region, present }`. A bright sticker on the SSD; the Nicla watches the SSD bay; "take it out"
  expects it gone, "put it back" expects it there (Ahmed)
- Because: same detection code with renamed fields, and it still fits cables or covers
- Rejected: checking the bottom cover instead (the SSD itself would go unchecked); dropping the rig and RS
- Known limit: a hand resting over the sticker looks like the SSD being gone

## 2026-11-14 23:20 — Where the relay runs in the demo
- Chose: on the dashboard laptop (Ahmed)
- Because: Ahmed's laptop is switched off and opened up in the demo
- Rejected: simulating the SSD step; a spare laptop just for the relay

## 2026-11-14 23:03 — The demo is an SSD swap (folded in from Laura's entry)
- Chose: Ahmed's laptop on a board with the marker; the guide takes its own SSD out and puts the same one back
  (the whole team: Ahmed, Max, Salman, Laura; proposed by Salman at 22:10)
- Replaces: a network cabinet with a patch panel and a cable to move

## 2026-11-14 22:55 — Offline rule, video test page, labelling, model motion
- Chose (Ahmed): the latest guide wins and the phone keeps its place by step id, and the relay stops replaying the
  current step to phones; a browser test page for video (who calls: superseded at 23:30); Claude labels a dashboard
  snapshot, answered to that dashboard only; a model's motion follows `axis`, defaulted from its own +Y
- Rejected: the relay replaying the step and the phone ignoring it; finishing the cached guide first; refusing taps
  on an older rev; labelling from the phone's camera; dropping Accenture; dropping `axis`

## 2026-11-14 22:30 — Model conventions (folded in from Laura's entry)
- Chose (Laura): metres, +Y up, the working tip at the origin, each model rising along +Y; one build script makes the
  glTF and the USDZ from the same geometry

## 2026-11-14 22:10 — The phone's stack (folded in from Salman's entry)
- Chose (Salman): accept pure native Swift and the phone role; Google's WebRTC framework (`stasel/WebRTC`), peer to
  peer on the hotspot

## 2026-11-14 22:15 — The dashboard stack (folded in by Ahmed's agent at 22:20)
- Chose: Spark 2.4 on three.js, proven by a short spike with a kill test (30 fps or more on the weakest laptop, a
  click-pick under 300 ms, a cut-out under 2 s), PlayCanvas only if it fails; Vite 8 + React 19 + TypeScript; plain
  three.js behind `scene/api.ts`; no React Three Fiber; a shared zustand store when one is needed (Max)
- Because: `research/ledger.md` § 7 and § 8
- Also: the splat upgrade route is the team's DGX Spark, not Dawn, which we have no access to (Max, § 9)

## 2026-11-14 21:54 — The UNO Q rig
- Chose (Ahmed, each as recommended): the Nicla Vision works out which port holds the cable, with OpenMV colour blobs
  in one region per port; it sends one line per change over USB through the powered hub; a Python app on the UNO Q
  joins the relay as `rig` with `websocket-client` (a new dependency, pure Python), compares with the step's
  `expect`, sends `step.verified` and shows ✓ or ✗ on its LED matrix; guide objects gain an optional
  `expect: { port, cable: "in" | "out" }`
- Because: colour blobs have an official Nicla tutorial and need no training; the hub is mandatory for RS anyway;
  the UNO Q visibly makes the decision, which is what RS judges; an explicit field beats parsing display labels
  (`research/ledger.md` § 10)
- Rejected: a trained model on the Nicla; detecting on the UNO Q; serial wires (pins vary by firmware, voltage
  unconfirmed); the Nicla's Wi-Fi; parsing "Port 17" from labels; a rig-only config file; forwarding through the
  laptop
- Known risk: reports conflict on whether an App Lab app can open a USB serial device. Test first; the fallback is
  running the same Python outside App Lab
- `expect` says in or out (a detail inside the approved field, proposed by Ahmed's agent): a "pull out of port 14"
  step needs "port 14 is now empty"

## 2026-11-14 21:29 — The relay
- Chose (Ahmed, each as recommended): the `ws` package (with `@types/ws` and `@types/node` dev-only); state kept in
  memory and in `relay/state.json`, written on every change except poses; plain `ws://` on the team hotspot; role
  rules with no login. Also kept the fake phone and fake expert (Ahmed asked why they're needed, then kept them)
- Because: `ws` is the standard Node server with no sub-dependencies; the file survives a relay crash mid-demo;
  iPhones refuse self-signed certificates and a tunnel needs the slow hall internet; role rules keep the fakes and
  real apps identical
- Rejected: a hand-written websocket server; memory only; a self-signed `wss://`; a public tunnel; a join key
- Revisit if: the relay must be reachable from 4G (tunnel, and then a join key)
- Built in, not separately decided: a 5-second heartbeat, so a phone that silently drops off Wi-Fi leaves presence
  within about 10 seconds; a 1 MB cap per message

## 2026-11-14 20:59 — The protocol contract's shape
- Chose: 13 shape choices proposed by Ahmed's agent and approved by Ahmed, listed in the `progress.md` entry of
  2026-11-14 20:59. The main ones: steps and objects are referred to by id; `guide.set` always sends the whole guide; guides
  carry `rev` and the marker's printed size; calibration goes dashboard → relay only; `step.done` carries a
  unique `doneId` and the tap time; the rig connects as a third role; `hello` carries a protocol version
- Because: each choice is explained in a comment beside it in `contracts/protocol.ts`
- Rejected: Max's draft in `docs/remote-assist/architecture.md` where it differs (indexes, `calib.points` to the
  phone)
- Revisit if: a builder hits a message that doesn't fit. Any change after this is flagged to all three consumers.

## 2026-11-14 20:59 — A type-checker for the contract
- Chose: `typescript` (7.0.x) as a dev-only dependency in `relay/` (Ahmed)
- Because: Node 24 runs TypeScript without checking it, so a typo in the contract would only surface in Max's build.
  The relay's check is written so the type-checker fails if the contract gains a model, role, action or message
  type the check doesn't know (tested by breaking it on purpose)
- Rejected: runtime tests only

## 2026-11-14 20:59 — The frame guide positions travel in
- Chose: the marker's own frame, in metres; the dashboard converts from splat coordinates using the four corner
  clicks and the printed size; the phone pins objects to the image anchor and does no maths (Ahmed)
- Because: the conversion is the same few dozen lines either way, and on the dashboard it's testable on a laptop and
  its error is visible to the expert right after clicking. The phone's list is already long, and a guide stored for
  offline play is complete on its own (`research/ledger.md` § 6)
- Rejected: splat coordinates plus the four corners, with the phone converting (Max's original draft)
- Cost: if the expert re-clicks the corners, the dashboard resends the whole guide
- Revisit if: experts need to recalibrate often during a call

## 2026-11-14 20:45 — Live view, second look
- Chose: keep WebRTC; signalling rides the relay websocket as a pass-through message (Ahmed)
- Because: Ahmed wants real video. With the phone back to pure Swift, the custom capturer is the standard route
  (`research/ledger.md` § 2, § 5)
- Rejected: JPEG frames over the websocket first, with WebRTC or LiveKit later (the recommendation, and Max's in
  `docs/remote-assist/open-questions.md` § 3)
- Revisit if: video isn't streaming by the feature freeze. JPEG frames are the fallback.

## 2026-11-14 20:45 — How the apps share the protocol
- Chose: `contracts/protocol.ts` holds TypeScript types only, no runtime code, plus JSON examples in `fixtures/`
  (Ahmed)
- Because: one file and no new dependency. The dashboard imports it as types; the relay runs it directly on Node 24
  (tested); Salman mirrors it as Swift `Codable` structs from the JSON examples
- Rejected: zod schemas (a new dependency in every app)
- Known cost: nothing checks messages at runtime, so the relay gets a small hand-written check

## 2026-11-14 20:45 — The phone app is pure native Swift
- Chose: a plain Xcode project in `ios/`, no Expo or React Native (Ahmed)
- Because: Ahmed's call, confirming the earlier decision after Salman built an Expo app with a Swift ARKit module
  (`salman-mobile`, `salman-ar`, not flagged on the board)
- Rejected: keeping Expo plus the Swift module (the recommendation: his marker detection already worked, and its
  TypeScript layer could have imported the protocol)
- Cost: Salman ports his ARKit code to a new project and hand-writes the protocol types in Swift
- Revisit if: Salman makes a case on the board

## 2026-11-14 — Build order
- Chose: all four build in parallel from the first hour, each against fake peers (Ahmed)
- Because: four people each have their own Claude running, and nobody should wait
- Rejected: prepared guide first as a walking skeleton (the recommendation: it proves alignment, the riskiest part,
  before anything else is built on it); live editing first; video first
- Revisit if: alignment isn't working on a real phone a few hours in. Then everyone helps there first.
- Made safe by: `contracts/protocol.ts`, a sample guide and fake peers landing in the first hour

## 2026-11-14 — Sponsor challenges
- Chose: Neptune North, Accenture, Marshall Wace and RS (Ahmed)
- Because: enter everything the idea can reach
- Rejected: Neptune North and Accenture only (Max's suggested priority); skipping RS (the recommendation: it needs
  borrowed hardware and several hours of one person)
- Revisit if: no UNO Q can be borrowed, the rules cap how many challenges one project enters, or Laura's list is
  too long

## 2026-11-14 — Splat route
- Chose: Scaniverse on the phone as the main route; Dawn as an upgrade (Ahmed)
- Because: Dawn access is promised but nobody has logged in
- Rejected: Dawn first (a failed login would leave us with no splat)
- Revisit if: Max logs in and one job runs

## 2026-11-14 — Cut-outs on the phone
- Chose: highlight box plus the closest built-in model; the cut-out itself stays on the dashboard (Ahmed)
- Because: at the time, the plan said RealityKit can't draw splats, and this needs no new format work
- **Premise now in doubt:** `research/ledger.md` § 1 (Max, published the same hour) says RealityKit on iOS 27.2+
  can draw splats. Reopened in NOW → Pending.
- Rejected: box and arrow only (weakest visual); a rough mesh or point cloud of the cut-out (a new pipeline stage,
  the riskiest piece for the time left)
- Revisit if: everything else is done before the freeze

## 2026-11-14 — Live view
- Chose: WebRTC from the start (Ahmed, against the recommendation)
- Because: Ahmed wants real live video, a stated requirement in Max's plan
- Rejected: JPEG snapshots over the existing websocket (the recommendation: no new dependency, about an hour);
  snapshots first with WebRTC as a stretch; cutting live view
- Known cost: ARKit holds the camera, so the phone needs a custom video source fed from AR frames, plus signalling
  on the relay and a panel on the dashboard (`research/ledger.md` § 2, § 5). No official end-to-end sample was
  found. Max's research, published the same hour, also recommends snapshots first. Flagged in NOW → Pending.
- Revisit if: it isn't streaming by the feature freeze. Snapshots are the fallback.

## 2026-11-14 — Lining up the scan with the room
- Chose: one printed marker, detected as an ARKit image under world tracking; the expert clicks its four corners in
  the splat (Ahmed)
- Because: content stays put when the marker leaves the frame, the marker keeps re-locking drift, and its known
  printed size gives the scale (`research/ledger.md` § 3, § 5). Max's research reached the same answer on its own,
  and adds: 15 to 20 cm wide, exact printed size given to ARKit
- Rejected: four stickers tapped on screen (four fiddly taps, raycast error, no re-lock); the same ARKit session for
  scan and guide (breaks on restart, and can't use a splat made ahead of time); marker plus a sticker fallback
  (about two more hours)
- Revisit if: the measured error on our set is too big to tell neighbouring ports apart

## 2026-11-14 — The split
- Chose: Salman the phone app; Max the dashboard 3D view and the splats; Laura the guide builder, assets, set and
  pitch; Ahmed the relay, protocol, sync, labelling endpoint, the UNO Q rig and docs (Ahmed)
- Changed the same evening: the UNO Q rig was first given to Laura (proposed by Ahmed's agent); Ahmed then took it
  himself. Risk: he also owns the protocol, fakes and relay that three people wait on, so the rig is his first cut.
- Because: Salman is the confident Swift person, Max wrote the plan and knows the splat side, and the relay sits
  between the two apps, which suits the integrator
- Rejected: Expo with an AR library (thin AR support); an Expo shell with a Swift AR view (bridge glue)
- Note: assigning the AI labelling to Max and Ahmed, and the UNO Q rig to Laura, was proposed by Ahmed's agent and
  approved by Ahmed with the plan.
- Revisit if: Laura or Salman object to their role

## 2026-11-14 — Round 1 (the shape of the product)
- Chose: the remote expert builds the guide and the on-site user follows it on an iPhone; guides can be made live or
  ahead; built-in models plus cut-outs from the scan; preset actions; the user taps Next; boxes stay alongside
  models (Max; agreed by Ahmed)
- Because: see `docs/remote-assist/README.md` → Decisions so far
- Rejected: the Quest 2 as the on-site device (we don't have one with us); the ISS and Mars framing
- Revisit if: a Quest turns up and the phone version is done

```
## <date> — <decision name>
- Chose: <option> (<who>)
- Because: <one line>
- Rejected: <alternatives + why not>
- Revisit if: <the condition that would change this>
```

## History
*How the idea and the plan changed, and why. Superseded plans move here, never deleted.*
- **2026-11-14 23:03:** the demo moved from a network cabinet to an SSD swap on Ahmed's laptop (the whole team).
- **2026-11-14, before the event:** Max's first plan: a technician in a Quest 2, guided on a foam-board "ISS panel"
  by an expert clicking in a splat. Superseded the same evening; kept in `docs/remote-assist/README.md` → Parked.
- **2026-11-14 19:40:** Max's round 1: an on-site user with an iPhone, a remote MSP engineer, stepped 3D guides.
- **2026-11-14, later:** Ahmed's planning session settled alignment, live view, cut-outs, challenges, the build
  order and the four-way split (Decision log above).
