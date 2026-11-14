# Remote Assist: the project doc
*Team Sonic · DurHack 2026 · repo `github.com/meep-boop/durhack-2026-team-sonic` · started 2026-11-14.*

**How to read this:** **NOW** is what's true and in progress today, so start there. **Part A** is the spec. **Part B**
is the design, one section per feature. **Parked** holds what was doable but not chosen. The **Decision log** says why
the system is shaped this way, and **History** says how we got here.
- Event rules and judging: `EVENT.md`. Evidence: `research/ledger.md`. Your tasks: `builder-file-<name>.md`.
- Live status and conflicts: `progress.md` on `main`.

*Italic lines are prompts. Replace them as you fill each section, and leave a section empty rather than invent it.*

---

## NOW (updated 2026-11-14)

### Headline
**Step-by-step 3D guidance on a phone, built by a remote engineer from a scan of the room, that keeps working when the network is down.**

The idea is Max's (`docs/remote-assist/` on `main` has the full plan). It was taken forward by Max and Ahmed on
2026-11-14 without an `idea-forge` scoring round; Laura and Salman haven't weighed in yet.

**Never pitch:**
- "Trained on the Dawn supercomputer", unless the splat on screen really was. Nobody has logged in to Dawn yet.
- Any accuracy or speed number we haven't measured on our own set (alignment error, "x times faster than a call").
- The market notes in `docs/remote-assist/README.md` → Parked (Dynamics 365 Remote Assist ending, what rival tools
  do). They aren't in `research/ledger.md` yet.

### Clock
*The single home for every deadline. Briefs and chat point here and never copy the times.*

| When | What |
|---|---|
| Sat 14 Nov, 12:00 | Hacking started |
| _blank_ | Walking skeleton end to end (the first thing that must work) |
| _blank_ | Feature freeze: after it, only fixes, and no API shape changes |
| _blank_ | Demo recorded / deck done |
| **Sun 15 Nov, 12:00** | **Submission deadline** on Devpost (use the earliest time any source gives) |
| Sun 15 Nov, from 12:30 | Judging: judges visit tables, so the demo is live |

Source: `EVENT.md` §1 (one notes file, not yet checked against Devpost). The three blank rows are the team's to set.

### Decisions in force
*One line each, newest first: what, who decided, when. The full record is in the Decision log below.*

| Date | Decision |
|---|---|
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

**Agreement so far:** Max and Ahmed. Laura and Salman haven't confirmed their roles or these decisions; their
briefs ask them to object on the board before building.

### Pending decisions
*Open questions, each with an owner and what it's waiting on. Unconfirmed leanings go here too, marked **not decided**.*
- **Reopen: cut-outs on the phone.** Ahmed chose "box plus a built-in model" on the premise that RealityKit can't
  draw splats. Max's research (`research/ledger.md` § 1, § 4), published the same hour, says RealityKit on iOS 27.2+
  can, and recommends real splat cut-outs with the model as the fallback. Owner: Ahmed + Max. **Not decided** whether
  to change it; the box-and-model path is being built either way.
- **Settled 20:45: live view stays WebRTC** (Ahmed, after reading § 2; see the Decision log). The original note:
  Ahmed chose WebRTC from the start. Max's research (`research/ledger.md` § 2) recommends
  JPEG frames over the websocket first and LiveKit Cloud as the upgrade, and warns that 4G may need a TURN server.
  Owner: Ahmed + Max + Salman. The decision stands until Ahmed changes it.
- **WebRTC library on iOS.** Owner: Salman. **Not decided.** (Signalling settled: it rides the relay websocket as a
  pass-through message.)
- **Which side solves the alignment, and what units positions travel in.** Owner: Ahmed, in `contracts/protocol.ts`.
  **Not decided.** Researched: `research/ledger.md` § 6.
- **Offline conflict rule:** what happens if the expert edits the guide while the phone is offline. Owner: Ahmed.
  **Not decided.**
- **LLM provider for labelling, and what it looks at** (renders of the splat, or camera frames). Owner: Ahmed + Max.
  **Not decided.**
- **Dashboard and relay libraries** (three.js, Spark, Vite, Node `ws`). Proposed in the plan; each is its builder's
  call. **Not decided.**
- **Model formats:** author once and convert, or keep glTF and USDZ by hand. Owner: Laura. **Not decided.**
- **Demo objects for the set.** Owner: Laura, with the team. **Not decided.**
- **UNO Q detection method,** and whether we can borrow a kit at all. Owner: Ahmed (took it from Laura). **Not
  decided.** No kit means the RS feature is parked.
- **`docs/remote-assist/open-questions.md` (Max) is out of step with this page.** Its question 1 (alignment) is
  marked "needs thought, not assigned", but Ahmed decided option B, the printed marker. Its questions 2 and 3 are
  framed as decisions for Max, and Max recommends the opposite of what Ahmed chose (the two "Reopen" items above).
  Owner: Ahmed + Max, to settle together. Max's file is his to update.
- **Does the relay need a public address?** A phone on 4G can't reach a laptop on venue Wi-Fi (open-questions § 3).
  A tunnel is a new dependency. Owner: Ahmed. **Not decided.**
- **May one project enter four sponsor challenges?** Owner: Ahmed. The opening slides don't say. **Ask an organiser.**
- **The three internal deadlines** (walking skeleton, feature freeze, demo recorded). Owner: Ahmed, with the team.
  **Not decided.**
- **Neptune North wants no central hub; our relay is one.** How the pitch shows the phone acting on its own (`EVENT.md` §4).
  Owner: Ahmed + Laura. **Not decided.**
- **Live or prepared guides first?** (Max's open question.) Overtaken by "all in parallel": the phone plays a
  prepared sample guide from its first task, and live building arrives with the guide builder.

### Active tasks (details in each brief)
| Who | Now |
|---|---|
| Ahmed | The event's rules and Clock; then `contracts/protocol.ts`, the sample guide and the fake peers; ask about the UNO Q |
| Salman | App skeleton and marker detection on a real iPhone |
| Max | Dashboard shell with a splat on screen, and the scene API for Laura |
| Laura | The printed marker (Salman and Max are waiting on it); pick and get the demo objects |

Asked for by Max (19:40 board entry): "Pick and get the demo objects" is Laura's task 3. "Check we have a Mac with
Xcode" is answered: yes, per Ahmed.

### Blockers only humans can clear
*Accounts, API keys, access, team registration, hardware, asking the organisers.*
- **Dawn login.** Promised by the event, untested by us. Max to try.
- **A camera and a USB hub** for the RS challenge. The team has an UNO Q and a Nicla Vision (`EVENT.md` §6); a USB
  webcam and hub would come from the Product Loan Library. Ahmed to sort out.
- **A paper printer** for the marker. Availability at the venue is unknown. Laura to find one.
- **Hall Wi-Fi is slow.** Plan on a phone hotspot for the demo.
- **Xcode and iOS versions.** The Mac needs Xcode to build at all. If cut-outs are ever drawn as real splats on the
  phone, it needs Xcode 27 and the demo iPhone on iOS 27.2 or later (`research/ledger.md` § 1). Salman to check both.
- **The demo objects.** A switch or router, a patch panel, a cover with screws: someone has to bring or borrow them.
- **Printing the marker,** flat and matte, with spares.

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
| F1 | Marker alignment: the guide sits on the real equipment | Salman, Max | P0 | ⬜ |
| F2 | Step player on the phone: box, animated model, Next | Salman | P0 | ⬜ |
| F3 | Protocol, fake peers and relay | Ahmed | P0 | ⬜ |
| F4 | Dashboard 3D view: splat, click to place | Max | P0 | ⬜ |
| F5 | Guide builder: step timeline, model and action pickers | Laura | P0 | ⬜ |
| F6 | Built-in models in glTF and USDZ | Laura | P0 | ⬜ |
| F7 | The demo set, scanned | Laura, Max | P0 | ⬜ |
| F8 | Offline play and resync (Neptune North) | Salman, Ahmed | P0 | ⬜ |
| F9 | Live camera over WebRTC | Salman, Ahmed, Laura | P1 | ⬜ |
| F10 | Cut-outs from the scan | Max | P1 | ⬜ |
| F11 | Find a part by name, AI labels (Accenture) | Max, Ahmed | P1 | ⬜ |
| F12 | Hardware check with the UNO Q (RS) | Ahmed | P1 | ⬜ |
| F13 | The user's position shown in the scan | Max | P1 | ⬜ |

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
| Phone app | Pure native Swift, ARKit + RealityKit, no Expo (**decided**) | iPhone Safari has no WebXR AR; Salman is confident in Swift | No: first build pending |
| Alignment | Printed marker, 15 to 20 cm, as an ARKit detection image under world tracking (**decided**) | `research/ledger.md` § 3, § 5 | No: error to be measured on our set |
| Live video | WebRTC with a custom source fed from AR frames, signalling over the relay websocket (**decided**); library **not decided** | Ahmed's call | No |
| Splat | Scaniverse export (**decided** as main route); Dawn + gsplat as an upgrade | Dawn untested | No |
| Dashboard | Browser app; three.js + Spark + Vite **proposed, not decided** | Max's planning session | No |
| Relay | Node + `ws` over HTTPS **proposed, not decided** | Max's planning session | No |
| AI labelling | Provider **not decided** | | No |
| Hardware check | Arduino UNO Q + camera (the RS challenge requires them); method **not decided** | | No kit yet |

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
- **Cut order (first to go → last):** proposed by Ahmed's agent, **not decided**: hardware check (F12), cut-outs (F10),
  AI labels (F11), the user's position (F13), live video (F9).
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

## Decision log
*Full records, newest first. NOW → Decisions in force holds the one-line versions.*

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
- **2026-11-14, before the event:** Max's first plan: a technician in a Quest 2, guided on a foam-board "ISS panel"
  by an expert clicking in a splat. Superseded the same evening; kept in `docs/remote-assist/README.md` → Parked.
- **2026-11-14 19:40:** Max's round 1: an on-site user with an iPhone, a remote MSP engineer, stepped 3D guides.
- **2026-11-14, later:** Ahmed's planning session settled alignment, live view, cut-outs, challenges, the build
  order and the four-way split (Decision log above).
