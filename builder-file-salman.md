# Salman: the iPhone app (marker alignment, step player, offline play, live camera)
**GitHub:** `salman-abdulrazaq-ali` · **Branch:** `salman-ios` · **Brief last updated:** 2026-11-14 by ahmed
**Spec:** `PROJECT.md` (NOW first); the § numbers below refer to it. **Deadlines:** `PROJECT.md` → NOW → Clock.
**The plan in full:** `docs/remote-assist/README.md` and `architecture.md` (on `main`, written by @max).

## 0. How the agent reads this brief (every task)
1. Read the project `CLAUDE.md` in full, then this brief. Follow both.
2. **Only action `▶ Current tasks`**, top to bottom.
3. The every-prompt hook syncs the docs and shows new `progress.md` entries. Handle any open
   `⚠️ Conflicts: @salman` first.
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
- `ios/`: the native Swift app (ARKit + RealityKit) the on-site user holds.

**Does NOT touch:**

| Area | Owner |
|---|---|
| `relay/`, `contracts/`, `fixtures/`, `hardware/` | @ahmed |
| `dashboard/src/scene/`, the dashboard shell, the splat files, `docs/remote-assist/` | @max |
| `dashboard/src/guide/`, `assets/`, the pitch material | @laura |

**Shared** (flag every edit in `progress.md` → `⚠️ Conflicts`): `contracts/protocol.ts` (ask @ahmed for changes),
`fixtures/*`, and `assets/` (you consume the marker image and the USDZ models that @laura makes).

## 2. Contract and guardrails
**Scope contract.** salman is building:
- An iPhone app that finds the printed marker, lines the guide up with the real equipment, and plays each step
  (a highlight box plus an animated built-in model) over the camera view, with a **Next** button.
- It keeps playing with no network, queues what the user did, and sends it when the link is back.
- It streams the camera to the expert's dashboard over WebRTC while AR keeps running.

**Out of scope:** the Quest (parked). Drawing splat cut-outs on the phone is **on hold, not ruled out**: Ahmed chose
"box plus a built-in model" before seeing Max's research (`research/ledger.md` § 1), which says RealityKit on iOS
27.2+ can draw splats. It's reopened in `PROJECT.md` → Pending. Build the box-and-model path; don't start on phone
splats until that's settled. Training splats in the app (the scan is taken in Scaniverse for now).

**Guardrails:**
- **The guide must never depend on video, the AI labels or the hardware.** If WebRTC is broken, the steps still play.
- Alignment uses `ARWorldTrackingConfiguration` with `detectionImages`, not image-only tracking, so content stays
  put when the marker leaves the frame (`research/ledger.md` § 3 and § 5). Give ARKit the marker's **exact**
  printed width, or position and stability suffer.
- Every new package (a WebRTC library above all) is a 🟠 decision for you before it goes in.
- No signing identities, team IDs or keys in the repo.
- Report the measured alignment error honestly. Nobody quotes an accuracy number that wasn't measured on our set.

---

## 3. ▶ Current tasks (2026-11-14), in order
*Status: ⬜ not started · 🟡 in progress · ⏸ blocked · ✅ done*

**▶ The last stretch (from @ahmed, 2026-11-15 07:37), ahead of everything below.** Why boxes hover on the phone: no guide has real
positions yet (the only scan has no marker; the prepared guide has placeholders). Decided by Ahmed: rescan and place
in the scan, with a ruler photo as the fallback; bigger animations; the demo is "expert builds, user follows".
1. ⬜ P0 **Bigger animations on the phone** (Ahmed allows this one change after the freeze; no message change):
   see the spec below (corrected 2026-11-15 07:38 after reading the code on `main`).
   **What's actually there, and why it looks flat:** `unscrew` only spins the screw in place (`Shapes.spin`, quarter
   turns, no rise), and a round 1.6 cm screw spinning on its own axis looks still. `pull` / `push` slide 2 cm and
   come back (`autoReverse`), so they read as a wobble with no direction. The box is 1.2 mm lines with an 18% fill;
   the label is 12 mm text; every object in a step moves in step with the others. The dashboard preview is different
   again (3 cm slide, two turns rising 5 mm, `scene/preview.ts`).
   **Spec, same on both sides, no message change:**
   - `unscrew`: two turns anticlockwise while rising 15 mm along the axis over 1.6 s, hold 0.4 s, restart from the
     hole (repeat, not reverse).
   - `pull` / `push`: 4 cm one way over 1.0 s, hold 0.4 s, restart (repeat, not reverse), so the direction is clear.
   - Each object's loop starts 0.15 s after the one before it, so 8 screws ripple instead of moving as one.
   - Phone only: a pulsing ring on the surface under each object (`Shapes.pulse` already does this for pins), box
     lines 2.5 mm, label 18 mm. Optional: the ghost screwdriver (`Shapes.ghostTool`) over the current screw. `Shapes.animate` in `ios/RemoteAssist/AR/Shapes.swift`. Max matches the dashboard preview.
2. ⬜ P0 **PR #12**: run its phone check (45 s camera, Done → receipt) and merge it.
3. ⬜ P0 **Be at the table for the first real run** once Max's guide is built in the scan: the expert's guide, not
   the laptop guide, is the demo's spine. Post which printed edges red +X and blue +Z point to.
4. ⬜ P0 **The call beat:** `ios/expert-call/` served on port 8000 on Max's laptop, tap-to-point tried against Max's
   relay (your § 20 says that's untested).
5. ⏸ Done in the laptop guide reaching the relay needs a contract change: not before the demo (Ahmed).
- Accepted by Ahmed: #11 on `main` as the demo build. Thanks for measuring the freeze (§ 20).

**▶ What's left (from @ahmed, 2026-11-15 04:12), ahead of the 01:45 block below.** The phone is the one piece not on `main`, and the
camera freeze on `salman-ios-ar` has no confirmed cause after five fixes. Ahmed's decision: **the plain build first.**
1. ✅ P0 *(05:18: #11 merged instead of #8, the newer build; waits on Ahmed's OK)* **Merge PR #8 (`salman-ios-polish`) to `main` now** and run the six-point smoke test (item 2 in the block
   below) on the real phone against the relay on Max's laptop. That's the demo build until the camera is proven.
   *Done when:* `ios/` is on `main` and a board entry says which of the six passed, and whether the camera ever froze.
2. ✅ P0 *(found by on-phone A/B instead of a bisect: research § 20)* **Find the freeze by halving, not by another fix** (`debug` skill): PR #8 is the last known-good end,
   `fa51e72` the bad end, about 30 commits apart, so about 5 builds. `git bisect start fa51e72 origin/salman-ios-polish`,
   and for each build: open the app, start a guide, wait 60 s, open and close a sheet. Post the first bad commit.
   Suspects from reading `ARSessionController.swift` at `fa51e72`, for after the bisect, not instead of it:
   - the `renderCallbacks.postProcess` blit added as a "did it draw" probe (line 234) changes RealityKit's render
     path on every frame, so the probe may be feeding the fault it watches for;
   - the session is still re-run while live from the watchdog (328), `resume()` (404), `setHandsInFront` (420) and
     the thermal and memory observers (212, 222), which `386367d` says must never happen;
   - `replaceView` moves anchors between two `ARView`s sharing one session (262-288).
3. ✅ P0 *(in #11)* **Bring across only what the demo needs, one at a time, each tested on the phone:** the tap receipt
   (`Outbox.swift`) and place-survives-an-app-kill (`Persistence.swift`) first. They don't touch the camera.
4. ⬜ P0 **Post the marker axes** (red +X, blue +Z: which printed edges). Max's calibration assumes top edge and
   down the print.
5. ✅ P0 *(in #11; auto-connects for local relays)* **`ios/expert-call/` on `main` with `?relay=` working**, served on port 8000: Max's Call button opens it.
6. 🟡 P1 *(in #11, call-tested by Salman; guide Done fix on `salman-ios-guide`)* Extras (pins, spotlight, voice commands, transcript, report) only after 1–5, and only if the camera holds.
7. ⬜ **Answer Laura:** Gemini is removed on your branch (`a9a884c`); is ElevenLabs in the demo build? The README
   and the MLH entries follow your answer.
- No chat (decided 01:55): the chat screen comes out before any merge.

> 📨 **From @max (2026-11-15 03:40, board entry):** the dashboard is getting a **Call** button that opens your
> `ios/expert-call/` page in its own window, at `http://<dashboard host>:8000/?relay=<the dashboard's relay>` (your
> README's `python3 -m http.server 8000`). Please keep the `?relay=` parameter working, and get the page onto
> `main` with the app. Your page and the app don't change otherwise. *(03:55: on `main`. The Phone light shows
> your `hello` `client` name as a tooltip and says "tracking" / "marker out of view" from `pose.markerTracked`.)*

> 📨 **From @max (2026-11-15 02:39, board entry):** the dashboard side of rung 1 is ready on `main` (Laura's panel
> sends `guide.set` over the relay). It waits on your item 1, `salman-ios-polish` on `main`. The dashboard's
> calibration assumes red +X along the marker's top edge and blue +Z down the print: your item 3 settles it, so post
> which edges they really are.

> 📨 **From @max (2026-11-15 03:15):** on `main` now: the phone's position shows in the 3D view (from `pose`),
> AI labels with a part search (dashboard only), and drag handles on the selected object that fire
> `onObjectMoved` once per drag. The dashboard draws your pose with the camera looking along its own -Z (ARKit's
> convention): say if the phone sends anything else. A dragged object only turns about +Y.

> 📨 **From @max (2026-11-15, PR #10):** `docs/vault/` on `main` explains the project in plain words for people
> and judges. Please skim the note about your part and correct anything wrong: `phone-app.md` (written from
> `salman-ios-ar`).

**▶ The plan to the deadline (from @ahmed, 2026-11-15 01:45). Do these first, in this order; the older tasks below keep
their detail.** Why: the phone side is nearly there, but the dashboard is still a viewer with no relay connection,
so we climb a ladder: rung 0 the real phone plays a prepared guide; rung 1 the dashboard connects and sends it;
rung 2 a guide built in the scan lines up on the phone; rung 3 the extras. Decisions: `PROJECT.md` → Decision log.
1. ⬜ P0 **Merge `salman-ios-polish` to `main`** with `ship` (it carries PR #4). PR #7 (`salman-ios-ar`) follows
   after its own device test; it merges cleanly with `main` today. *Done when:* `ios/` is on `main`.
2. ⬜ P0 **Smoke test on the real phone** with the relay and `node fixtures/fake-expert.ts ws://<relay>:8080`: the
   green outline hugs the print; the sample guide appears; four taps arrive in order; Wi-Fi off, tap on, Wi-Fi on,
   each tap arrives once; `--step s3` jumps the phone; a call from `ios/expert-call/` shows video while AR keeps
   tracking. *Done when:* a board entry says which of the six passed.
3. ⬜ P0 **Post which printed edge red (+X) and blue (+Z) point to** (item D). Calibration is provisional until then.
4. ⬜ P0 **The tap receipt** (decided by Ahmed): the relay will send each `step.done` it accepts, and each repeat,
   back to the phone that sent it. Remove a tap from the outbox only on its receipt (today it goes when the socket
   write succeeds, `RelayClient.swift:210`), and resend the queue in order on reconnect. Wait for the board entry
   saying the relay side is on `main`; `fixtures/fake-phone.ts` will be the reference.
   `[⚠ conflicts with @ahmed: the relay side]`
5. ⬜ P0 **With rung 2: measure the alignment error** with a ruler on three parts. It's the only number we quote.
6. P1 Saving the guide, place and queue across an app kill is already on `salman-ios-ar` (your call, noted). P2: the
   guide is scaled by ARKit's size estimate (`ARSessionController.swift:295`); measure alignment with and without.
- **Your `chat` message** (PR #7): decided 01:55 by Ahmed, **no chat**. It stays out of the contract and the relay;
  please take the chat screen out of the app and `ios/expert-call/` before PR #7 merges. Your tap-to-pin and hang-up
  ride the call's `control` data channel, which Ahmed will document in the contract comment.
- **Scope:** Ahmed's ask is the core path first (1–5) before more extras; the feature freeze is in the Clock.

**New from @ahmed (2026-11-14 23:40 sweep), before the tasks below:**
- A. ⬜ **Mirror the new `expect`.** It changed at 23:24 to `{ region, present }` (the SSD swap has no cable). If your
  Swift struct requires `port` and `cable`, any guide carrying the new `expect` fails to decode, the sample guide
  included. *Done when:* after `git merge origin/main`, every example in `fixtures/messages.json` and
  `fixtures/sample-guide.json` decodes in your tests.
  **Pre-check by @ahmed (2026-11-15 00:54, read-only, `salman-ios` at `73ea7cf` with today's `main` merged in a throwaway copy):
  no merge conflicts, but four things break. Not compiled: Swift can't build on Windows, so this is from reading.**
  1. `struct Expect` requires `port` and `cable` (`Protocol/Protocol.swift`). The sample guide's steps 3 and 4 and
     the `guide.set` example now carry `{ region, present }`, so the whole guide fails to decode: on the phone that's
     a blank screen. Make it `region: String`, `present: Bool`.
  2. `GuideDecodingTests` asserts the old sample: id `sample-cable-move`, a `cablePlug` last object at
     (0.075, 0.012, 0.11). The sample is now `sample-ssd-swap`; its last object is a `hand` doing `push` at
     (0.28, 0.01, 0.03).
  3. `fixtures/messages.json` now has `labels.request` and `labels.result`; your decoder throws "unknown message
     type", so `MessageCodingTests` fails. The phone never receives either, so only the test needs to skip or decode them.
  4. Only the relay URL is saved (`UserDefaults`), not the current step. A reconnect keeps the place (`GuidePlayer`
     keeps the step on a same-id `guide.set`), but an app restart mid-guide goes back to step 1 (item B).
  Coming next: once Laura adds the `ssd` model, `enum ModelName` needs `case ssd` or a guide using it won't decode.
  **Update by @ahmed (2026-11-15 01:00):** `salman-ios-polish` (`820423b`) already fixes 1, 2 and 3 and has `case ssd`
  (Laura's model landed on `main` at 00:57, `61a771e`), and it merges cleanly with `main`. Item 4 is still open (B).
  So merge `salman-ios-polish` for item C, not `salman-ios` on its own.
- B. ⬜ **The phone owns its place.** Since 23:09 the relay no longer replays the current step to phones on reconnect:
  keep your position and your queued taps across reconnects and app restarts. *Done when:* kill the relay mid-guide,
  tap on, restart it, and the fake expert logs every tap in order while the phone stays on its step.
- C. ⬜ **Merge PR #4 to `main` with the `ship` skill before the walking skeleton** (`PROJECT.md` → Clock). *Done
  when:* `ios/` is on `main` with a board entry.
- D. ⬜ **Post the +X/+Z printed edges and the offset in mm** (still owed from task 1); the contract marks the axes
  provisional until you do.
- E. Housekeeping: close PRs #2 and #3 (the Expo app), as you said. Put board entries straight on `main`: your 22:10
  and 23:25 entries sit only on `salman-board` (PR #5), so the team's agents can't see them.
- Kept by @ahmed (23:30): your Gemini assistant and ElevenLabs voice, as optional AI-labelled extras, entered for MLH.
  Not Vultr or Tiger Data. Your team-code idea for `hello` is in `PROJECT.md` → Pending.


1. 🟡 **App skeleton and marker detection** (sweep: done on `salman-ios`, PR #4, on an iPhone 16; left: item D)
   - **2026-11-14 20:45, decided by @ahmed: pure native Swift, not Expo.** Your `salman-mobile` and `salman-ar` branches
     are superseded: keep them, don't merge them to `main`. Port the ARKit code from
     `mobile/modules/sonic-ar/ios/SonicArView.swift`. It already does what Apple's docs ask for: world tracking,
     the exact printed width, and `maximumNumberOfTrackedImages = 1`, which keeps the anchor updating every frame
     (`research/ledger.md` § 6).
   - A new Xcode project in `ios/`. World tracking with the marker from `assets/marker/` as a detection image
     (use any printed test image until @laura's lands). Draw an outline on the detected marker.
   - *Done when:* on a real iPhone the outline sits on the printed marker's edges, stays in place when the marker
     leaves the frame, and snaps back when it returns. In the `progress.md` entry, note the offset you see in mm,
     the phone's iOS version and the Mac's Xcode version (both matter for `research/ledger.md` § 1 and § 5).
     Also put a small axis marker (red x, green y, blue z) on the image anchor and post which printed edge +x and
     +z point to. Apple's docs say the image lies in the anchor's X–Z plane but not which way each axis points,
     and the protocol depends on it (`research/ledger.md` § 6).
2. 🟡 **Play the sample guide, lined up by the marker** (sweep: plays on `salman-ios`, now on a world anchor so a
   hand over the marker doesn't hide it; the ruler check isn't reported. The sample guide is now an SSD swap, same
   step ids)
   - Load `fixtures/sample-guide.json` from the app bundle. **Positions arrive in the marker's own frame, in metres**
     (decided by @ahmed): make each object a child of the image anchor and set its position, rotation and size
     straight from the JSON. No conversion on the phone. Draw the highlight box and a placeholder shape per
     object. **Next** moves on.
   - *Done when:* each step's box lands on the spot measured from the marker with a ruler, and Next walks through
     all the steps.
   - `[⚠ conflicts with @ahmed: the frame is defined at the top of contracts/protocol.ts. The +x and +z directions are
     provisional until your axis check in task 1.]`
3. ✅ **Talk to the relay** (done on `salman-ios`, not merged: hello, guide and step in, queued taps in order, pose
   at about 5 Hz, reconnect; every fixture decodes. Follow-ups: items A and B)
   - WebSocket client: `hello`, receive `guide.set` and `step.set`, send `step.done` and `pose`. Reconnect on drop.
   - The contract is TypeScript types only (`contracts/protocol.ts`). Mirror the messages as Swift `Codable`
     structs. `fixtures/messages.json` has one example of every message: decode them all in a unit test.
   - Guide objects may carry an optional `expect` (for the UNO Q rig, added 2026-11-14). Make it optional in your
     struct, or leave it out: Swift's decoder ignores keys it doesn't know.
   - The relay is on `main`: `cd relay && npm install && npm start` prints the `ws://` address to use. Then run
     `node fixtures/fake-expert.ts ws://<that address>` to send the sample guide. The connection is plain
     `ws://` on the team hotspot, so add `NSAllowsLocalNetworking` under App Transport Security in Info.plist.
   - *Done when:* with the fake expert from `fixtures/` running, its guide shows on the phone and each Next appears
     in its log.
4. 🟡 **Live camera over WebRTC** (on `salman-ios`: Google's WebRTC framework, the AR camera plus two-way audio.
   **Decided by @ahmed 23:30: the expert calls the phone**, as you built it. Left: merge, and a run through the
   relay on the hotspot)
   - ARKit holds the camera, so WebRTC's own camera capturer won't work. Feed `ARFrame.capturedImage` into a custom
     video source (`research/ledger.md` § 2 and § 5). **Settled by @ahmed: WebRTC stays, and signalling rides the
     relay websocket** as a pass-through message. Still yours to pick: the library. Max's research compares the
     plain WebRTC framework with LiveKit Cloud, and flags that 4G may need TURN.
   - *Done when:* a browser test page shows the phone's camera while the AR boxes keep tracking on the phone.
   - `[⚠ conflicts with @ahmed: signalling messages in contracts/protocol.ts]` `[⚠ conflicts with @laura: the dashboard's video panel]`
5. 🟡 **Preset animations** (on `salman-ios`: Laura's six models load and loop along `axis`; left: tell Laura if any
   looks the wrong size or way up)
   - `unscrew`, `pull`, `push`, `flip`, `rotate90` on the built-in USDZ models, along the object's axis, looping
     until Next.
   - *Done when:* each of the five actions loops on a model in the right place and direction.
   - `[⚠ conflicts with @laura: model names, sizes and origins in assets/models/]`
6. 🟡 **Offline play and resync** (the Neptune North feature) (taps queue and send in order; left: item B and the
   kill-the-relay check)
   - Keep the whole guide on the device. Keep playing when the relay is gone. Queue `step.done`, send on reconnect.
   - *Done when:* kill the relay mid-guide, finish the steps, restart it, and the fake expert logs every queued
     `step.done` in order.
   - `[⚠ conflicts with @ahmed: the resync rule if the expert edited the guide meanwhile]`
7. ✅ **Show the hardware check** (the RS feature) (done on `salman-ios`: ✓ or the `detail` on the step card)
   - On `step.verified`, tick the step or show the `detail`, e.g. "seen in slot-2, expected in ssd-bay".
   - *Done when:* a `step.verified` from the fake expert shows a tick, and a failed one shows the warning.
8. ⬜ **Scan capture in the app** (last; Scaniverse covers it until then)
   - *Done when:* agreed with @max what the app must hand over, and that hand-over works once.

## 4. Done log (newest first)
- 2026-11-15 05:50 (Salman's agent): **#11 merged to `main` at 05:18** (`salman-ios-ar`).
  - The camera freeze cause was measured and fixed; 0 drawable failures and 60 fps on the phone (research § 20).
  - The technician console and live call: point, area and spoken commands, tested by Salman on his Mac relay.
  - A guide's Done failed in that test, for three reasons: no guide screen during a call, no printed marker, and an
    invisible relay refusal. Fixes on `salman-ios-guide` (PR to follow).
  - Not yet tried with Max's relay or dashboard.
- 2026-11-14 23:25 (logged by @ahmed from your `salman-board` entry): on `salman-ios`, PR #4: the live call (the expert
  calls; AR camera and two-way audio) with `ios/expert-call/`, the guide on a world anchor, the six USDZ models with
  their actions, the rig's verdict on the step card, `expect` mirrored, the optional Gemini assistant and ElevenLabs
  voice.
- 2026-11-14 22:10 (logged by @ahmed from your `salman-board` entry): on `salman-ios`: the native app tracking Laura's
  marker at 0.18 m, the sample guide with Next, the relay client; iPhone 16, iOS 26.3.1, Xcode 26.0.1; WebRTC library
  picked.

## 5. Waiting on / owed to others
- 📥 **Waiting on:** @ahmed's OK that #11 (merged) replaces #8 as the demo build. Before that, nothing. The marker and models are on `main` (Laura); the contract, relay, fakes and sample guide
  are on `main` (Ahmed).
- 📤 **Owed to @ahmed:** the +X/+Z printed edges and the offset in mm (item D).
- 📤 **Owed to @laura:** the models' size and up-direction as the phone shows them; `ios/expert-call/` as the base for
  her dashboard video panel (her task 5).

## 6. Working-style notes for the agent
- Verbosity: project level (Level 0) unless Salman changes it.
- Salman is confident in Swift. Only the Mac can build and deploy, so keep the build green.

## 7. Reference (no secrets, ever)
- Apple: `ARWorldTrackingConfiguration.detectionImages`, `ARImageAnchor`, `ARFrame.capturedImage`.
- Evidence and sources: `research/ledger.md` § 1 (splats on iPhone), § 2 and § 5 (live video), § 3 and § 5 (alignment).

---
── Archived (superseded 2026-11-14 — do NOT action) ──
- **The Expo app with a Swift ARKit module** (`salman-mobile`, `salman-ar`). Superseded 2026-11-14 20:45 by Ahmed's call
  for pure native Swift. Would come back only if you make the case on the board and Ahmed agrees.
