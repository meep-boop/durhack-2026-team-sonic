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

**START HERE (2026-11-14, from @ahmed):** the split and the decisions in `PROJECT.md` → NOW were made by Ahmed on
top of Max's round-1 plan. If you disagree with your role or with a decision, say so in a `progress.md` entry
(`📨 To @ahmed`) before building on it. All four of us build at once, each against the fake peers in `fixtures/`,
so nobody waits for anybody. Until `contracts/protocol.ts` lands, use the draft in
`docs/remote-assist/architecture.md` and expect small changes.

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

1. ⬜ **App skeleton and marker detection**
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
2. ⬜ **Play the sample guide, lined up by the marker**
   - Load `fixtures/sample-guide.json` from the app bundle. Convert each position into the phone's world using the
     marker's pose. Draw the highlight box and a placeholder shape per object. **Next** moves on.
   - *Done when:* each step's box lands on the spot measured from the marker with a ruler, and Next walks through
     all the steps.
   - `[⚠ conflicts with @ahmed: which side solves the alignment, and the units positions arrive in, is being decided now (`research/ledger.md` § 6) and lands in contracts/protocol.ts.]`
3. ⬜ **Talk to the relay**
   - WebSocket client: `hello`, receive `guide.set` and `step.set`, send `step.done` and `pose`. Reconnect on drop.
   - The contract is TypeScript types only (`contracts/protocol.ts`). Mirror the messages as Swift `Codable`
     structs, using the JSON examples in `fixtures/` as your test data.
   - *Done when:* with the fake expert from `fixtures/` running, its guide shows on the phone and each Next appears
     in its log.
4. ⬜ **Live camera over WebRTC** 🟠
   - ARKit holds the camera, so WebRTC's own camera capturer won't work. Feed `ARFrame.capturedImage` into a custom
     video source (`research/ledger.md` § 2 and § 5). **Settled by @ahmed: WebRTC stays, and signalling rides the
     relay websocket** as a pass-through message. Still yours to pick: the library. Max's research compares the
     plain WebRTC framework with LiveKit Cloud, and flags that 4G may need TURN.
   - *Done when:* a browser test page shows the phone's camera while the AR boxes keep tracking on the phone.
   - `[⚠ conflicts with @ahmed: signalling messages in contracts/protocol.ts]` `[⚠ conflicts with @laura: the dashboard's video panel]`
5. ⬜ **Preset animations**
   - `unscrew`, `pull`, `push`, `flip`, `rotate90` on the built-in USDZ models, along the object's axis, looping
     until Next.
   - *Done when:* each of the five actions loops on a model in the right place and direction.
   - `[⚠ conflicts with @laura: model names, sizes and origins in assets/models/]`
6. ⬜ **Offline play and resync** (the Neptune North feature)
   - Keep the whole guide on the device. Keep playing when the relay is gone. Queue `step.done`, send on reconnect.
   - *Done when:* kill the relay mid-guide, finish the steps, restart it, and the fake expert logs every queued
     `step.done` in order.
   - `[⚠ conflicts with @ahmed: the resync rule if the expert edited the guide meanwhile]`
7. ⬜ **Show the hardware check** (the RS feature, only if the rig exists)
   - On `step.verified`, tick the step or warn about a wrong port.
   - *Done when:* a `step.verified` from the fake expert shows a tick, and a failed one shows the warning.
8. ⬜ **Scan capture in the app** (last; Scaniverse covers it until then)
   - *Done when:* agreed with @max what the app must hand over, and that hand-over works once.

## 4. Done log (newest first)
- _(empty)_

## 5. Waiting on / owed to others
- 📥 **Waiting on @laura:** the marker image and its printed width; the USDZ models.
- 📥 **Waiting on @ahmed:** `contracts/protocol.ts`, the fake expert, the sample guide.
- 📤 **Owed to @ahmed:** your pick of WebRTC library, so signalling can be written.

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
