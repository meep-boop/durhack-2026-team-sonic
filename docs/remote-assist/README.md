# Remote Assist: step-by-step 3D guidance on a phone, from a scan of the room

A small business's network has gone down. Someone on site points an iPhone at the comms cupboard in the basement. A
remote engineer at their Managed Service Provider (MSP) sees the live camera, gets a 3D scan of the room, and builds a
step-by-step guide out of animated 3D objects: "Step 1: this screw comes out. Step 2: this one. Step 3: pull this
cable." The person on site sees each step over the real equipment and taps **Next**.

**Status:** plan only, no code yet. Started 2026-11-14 by @max in the planning session; updated the same evening after
a grilling round. Nothing here is a locked decision until the team agrees it at kickoff; items marked **proposed**
are open.

| File | What's in it |
|---|---|
| [architecture.md](architecture.md) | Components, data flow, the guide format, message protocol |
| [open-questions.md](open-questions.md) | The hard problems we still have to figure out, with options and owners |

## Who uses it

**The setting:** a business owns networking equipment on its own premises (a server room or comms cupboard, not a
data centre). An MSP looks after it remotely, along with the business's other servers.

**User** (on site, iPhone):
- Share a live view of their surroundings through the phone camera.
- Scan the surroundings and submit the scan.
- Follow a guide of animated 3D steps over the real equipment, tapping **Next** to move on.

**Tech expert** (MSP remote engineer, laptop):
- See the user's live camera view.
- See a 3D model of the user's room, built from the scan.
- Build a step-by-step guide as a timeline of 3D animations.
- Turn "fake 3D" splat surroundings into real, separate 3D objects: cut the mouse (or screw, or cable) out of the
  scan so it can be highlighted, marked and animated on its own.

## Decisions so far (grilling round 1, 2026-11-14, decided by @max)

Each one still needs the team's agreement at kickoff.

| # | Question | Answer |
|---|---|---|
| 1 | Who places the models, who sees them? | The remote **tech expert** builds the guide. The on-site **user** sees it on their phone |
| 2 | Which device on site? | **iPhone, native app.** No Quest: we don't have one with us |
| 3 | Steps made live or prepared ahead? | **Both.** The expert can build the guide during the call or before it, and the phone plays it either way. Prepared guides first (round 2) |
| 4 | Where do the 3D models come from? | **A built-in set** (screw, bolt, arrow, screwdriver, hand) **plus objects cut out of the scan itself** |
| 5 | How are animations made? | **Preset actions:** unscrew, pull, push, flip, rotate 90°. The expert picks one per object per step |
| 6 | Who presses Next? | **The user**, on the phone |
| 7 | Do models replace highlight boxes? | **No, both.** The box shows *where*, the animation shows *how* |
| 8 | What's the demo object? | **Not decided.** Open task below |

**Round 2 (2026-11-14, @max):**

| # | Question | Answer |
|---|---|---|
| 1 | Do we have a Mac for the iPhone app? | **Yes, @salman's MacBook** |
| 2 | How does the phone line up the scan with the room? | **Needs real thought.** [Open question 1](open-questions.md#1-lining-up-the-scan-with-the-real-room) |
| 3 | What does the phone show for a cut-out from the scan? | **Researched:** iOS 27 RealityKit can draw splats. Awaiting decision. [Open question 2](open-questions.md#2-showing-splat-cut-outs-on-the-iphone) |
| 4 | Live guide-building or prepared guides first? | **Prepared guides first** (what Neptune North needs). Live building reuses the same editor |
| 5 | How does the live camera reach the expert? | **Researched:** JPEG over the relay first, LiveKit later. Awaiting decision. [Open question 3](open-questions.md#3-getting-the-live-camera-to-the-expert) |

## The demo (to redo for the new setting)

The first plan was a race on a foam-board "ISS panel": one judge guided over a video call, one guided by AR. The race
still works, swapped to the new setting:

- **The set:** a small "comms cupboard": a switch or router, a patch panel full of identical ports, a cover held on
  with screws. Exact objects are an open task.
- **The race:** two judges do the same fix ("take the cover off, move the cable from port 14 to port 17"). Judge A is
  helped over a normal video call. Judge B follows the 3D steps on the iPhone. Time both on a big screen.
- **The reveal:** the expert laptop shows the scanned room, and the guide being built from parts lifted out of it.
- **Link down:** the MSP is usually called *because the network is down*. The guide is downloaded to the phone, so
  once it's there it keeps playing with no connection. This is our Neptune North angle.

## Challenge fit (from the opening ceremony slides)

The overall theme is **Composition** (art, music, mixing ideas). Judging for everyone: creativity and innovation,
technical execution, research and learning, polish.

| Challenge | Fit | What we'd need |
|---|---|---|
| **Neptune North: actors that keep working when comms fail** (£1,000 first prize) | **Strong, a priority** | The phone stores the whole guide and plays it offline, queues "step done" and syncs when the link is back. The MSP setting makes this real: the network being down is why you called |
| **Accenture: redesign a frustrating process with AI/LLMs** | Good | **Proposed:** AI labels every port and part in the scan, so the expert types "port 14" instead of hunting |
| **Marshall Wace: "New Worlds"** (creativity, technical complexity, presentation) | Weaker than before | It leaned on the space story. Stepping into a 3D copy of a room still counts |
| **RS: sense, analyse, respond** (Arduino UNO Q + camera mandatory, hardware library) | Medium | **Proposed:** an UNO Q and camera on the set notice the cable actually moved, tick the step and warn on a wrong port |
| Consultancy on slides 25–29: "connect things that usually aren't" (Pi Pico kits) | Loose | Remote engineer ↔ on-site person, scan ↔ real room |
| Overall theme: Composition | Weak | Angle: composing a guide out of pieces of the real room |
| SGX FX, P&G, QRT | None | Skip |

Suggested priority (**not decided**): Neptune North first, then Accenture. Check whether Devpost allows entering
several sponsor challenges.

## Open tasks

- [ ] **Pick and get the demo objects.** What the set is made of (a real switch or router, a patch panel, a cover
  with screws), who brings or borrows it, and whether it's portable enough to scan once and demo at any table.
  Owner: not assigned yet.
- [x] **Find a Mac for the iPhone app:** @salman's MacBook (2026-11-14).
- [ ] **Get @salman's MacBook ready for iPhone builds:** Xcode installed, signed in with an Apple ID, the demo
  iPhone set up for development and a test app running on it.
- [ ] **Figure out how the phone lines up the scan with the real room:**
  [open question 1](open-questions.md#1-lining-up-the-scan-with-the-real-room). Owner: not assigned yet.
- [ ] **Agree the protocol** (architecture.md) before the phone and laptop sides split up.

## Parked (superseded by round 1, kept for the record)

- **Quest 2 headset as the on-site device**, with WebXR passthrough and controller-touch calibration. Dropped because
  we don't have a Quest with us. Would come back if one turns up and the phone version is done.
- **The ISS / Mars framing** (ISS maintenance panel, NASA T2AR and ESA mobiPV as precedent, a 20-second "Mars delay"
  toggle). Replaced by the MSP setting from the requirements. The comms-failure part lives on as the "link down"
  demo. Could come back as a closing line in the pitch ("the same guide works where the link is minutes long").
- **"No video was sent" reveal.** The user now shares live camera video, so this no longer holds.
- **Market notes from the first plan, still true:** existing tools (PTC Chalk, TeamViewer Frontline, Scope AR)
  annotate live 2D video, not a saved 3D model; Microsoft Dynamics 365 Remote Assist stops working on 31 Dec 2026
  with no named successor. Not yet checked in `research/ledger.md`.
