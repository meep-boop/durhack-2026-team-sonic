# Open questions: things we have to figure out

The hard problems that need real thought before anyone builds on them. Each one has an owner, what's known, the
options, and what "figured out" looks like. When one is settled, move the answer into
[architecture.md](architecture.md) and mark it ✅ here, with the date and who decided. Don't delete it.

| # | Question | Status | Owner |
|---|---|---|---|
| 1 | [Lining up the scan with the real room](#1-lining-up-the-scan-with-the-real-room) | 🟡 Working default set, accuracy not yet measured | Not assigned |
| 2 | [Showing splat cut-outs on the iPhone](#2-showing-splat-cut-outs-on-the-iphone) | 🟢 Working default set | @max |
| 3 | [Getting the live camera to the expert](#3-getting-the-live-camera-to-the-expert) | 🟢 Working default set | @max |
| 4 | [Getting from a scan to a splat, and cutting parts out](#4-getting-from-a-scan-to-a-splat-and-cutting-parts-out) | 🟢 Working default set | Not assigned |

---

## 1. Lining up the scan with the real room

**🟡 Every on-phone feature depends on this. It's researched and has a working default, but nobody has measured the
accuracy yet.**

**The problem:** the guide's objects (a screw at position x, y, z) are placed in the scan's coordinates. The phone
sees the real room in its own AR coordinates. Unless the phone knows how the two line up, the animated screw floats
in the wrong place, and the whole demo fails.

**What makes it hard:**
- Splat coordinates from COLMAP have no real-world scale (1 unit could be 3 cm or 3 m), so the fix needs scale as
  well as rotation and position.
- Small screws on a crowded patch panel need roughly 1–2 cm accuracy, or the animation sits on the wrong screw.
- The phone's AR tracking drifts and can reset, so this may have to be redone during the call.

**Options so far:**
- **A, stickers tapped on screen:** four coloured stickers in the scan. The user taps each in the camera view, and AR
  finds the 3D point under each tap. Solve rotation + position + scale (Umeyama method), show the error in cm.
- **B, a printed marker:** one image stuck on the equipment, tracked by ARKit as an image anchor. One step, no
  tapping. Needs the marker in the scan too, so its pose in splat coordinates is known.
- **C, same phone, same session:** scan with ARKit running, so the scan's camera poses are already in the phone's
  frame. Breaks if the app restarts between scan and guide.
- **D, automatic:** match features between the live camera and the scan. Most impressive, most risky.

**Research (2026-11-14, `research/ledger.md` § 3):** no published measurement shows any of these reaching 1–2 cm on
a non-LiDAR iPhone. We have to measure it ourselves.

| Option | Effort | Expected accuracy | Verdict |
|---|---|---|---|
| **B, printed marker** (ArUco/AprilTag, 15–20 cm, in the scan and tracked live) | 10–14 h | Roughly 1–3 cm (estimate) | **Best bet.** Triangulating the marker in the COLMAP frames also fixes real-world scale, because we know its printed size |
| **C, record ARKit poses during the scan**, then fit COLMAP to them (`colmap model_aligner`) | 6–8 h | Good scale; frame lost after restart unless a saved AR map relocalizes | **Add for scale.** Saved AR maps survive app restarts, but Apple says relocalizing depends heavily on the room and lighting |
| A, tap stickers on screen | About 3 h | Several cm: AR depth from taps is unreliable without LiDAR | Fallback for coarse correction only |
| D, automatic matching (or ARKit object detection) | Too much | Unknown | Skip: research-grade, and object detection suits tabletop objects, not a cupboard |

**Working default (2026-11-14, not confirmed by the team):** B + C.
- **During the scan:** a 15–20 cm marker is fixed to the cupboard, and the phone records its own AR camera poses
  alongside the frames.
- **On Dawn:** fit the COLMAP result to those poses for metric scale, and triangulate the marker to get its pose in
  splat coordinates.
- **On the phone, each session:** detect the marker as an ARKit reference image, average its position over about
  1 second, then freeze it as a world anchor.
- **Tap-to-correct** stays as a fallback. A saved AR map is a stretch goal.

**Gotchas to plan for:**
- **Axis conventions differ.** COLMAP and OpenCV use +y down, +z forward. ARKit and three.js use +y up, −z forward.
  Expect most alignment bugs here.
- **Enter the marker's printed size exactly** in ARKit. Print it flat and matte. Two markers spaced apart, or one big
  one, keep rotation error from growing with distance.
- **Record the scan from ARKit's own frames**, not a separate video, with fixed focus and no stabilisation.
- **Check with a ruler** before the demo: overlay the splat's screw positions on the real screws and measure the gap.

**Figured out when:** we've built B + C, tested it on the real demo set, and measured the error in cm.

---

## 2. Showing splat cut-outs on the iPhone

**The question:** the expert cuts a part (a screw) out of the scan. Can the iPhone draw that cut-out, a piece of the
Gaussian splat, over the real camera view and animate it? Or does the phone need a different stand-in?

**Status:** 🟢 researched 2026-11-14; recommendation below, **not decided**. Sources and verdicts:
`research/ledger.md` § 1.

**Short answer: yes, on iOS 27.** The round-2 claim "RealityKit can't draw splats" was out of date. iOS 27 (WWDC26)
added `GaussianSplatComponent` to RealityKit, available on iPhone, and the iPhone 16's chip qualifies. Catches:
- **We load the file ourselves.** RealityKit doesn't read .ply or .spz; we parse the points and fill its buffers.
  That suits us: we only send the cut-out's points, not the whole room.
- **There's a size limit** on how many splats one object can have (reported as about 200k, but another developer
  ran about 400k, so unconfirmed). A cut-out is a few thousand, so it doesn't matter for us.
- **No lighting and no custom shaders.** The cut-out won't react to the room's light.
- **Moving it should work:** the splats sit on a normal RealityKit object, so unscrew and pull animate that object.
  Inferred from the docs, not tested.
- **Apple's session demoed it on Vision Pro**, not iPhone AR. One developer reports it working in AR on an
  iPhone 16 Pro with iOS 27, after a culling bug fixed in iOS 27.2. Treat iPhone AR use as likely, not proven.

| Option | Effort | Risk | Notes |
|---|---|---|---|
| **A, RealityKit splats (iOS 27)** | About 4–6 h | Medium | The real cut-out on the phone. Needs Xcode 27 on @salman's Mac and the demo iPhone on iOS 27.2+ |
| **B, a stand-in model** (a built-in screw, or a simple shape sized to the cut-out's box) | About 2–4 h | Low | Works on any iOS. Build in parallel as the fallback |
| C, MetalSplatter (open-source renderer) in our own Metal pass | 8 h+ | High | No iPhone AR example exists and docs are thin |
| D, a web view running the browser splat renderer | — | — | Can't get the phone's AR tracking. Don't use |

**Recommendation:** A, with B built alongside as the fallback.

**Check on day one:** the demo iPhone is on iOS 27.2 or later, and @salman's Mac runs Xcode 27. If either fails, use
B only.

**Working default (2026-11-14, not confirmed by the team):** A, with B built alongside as the fallback.

---

## 3. Getting the live camera to the expert

**The question:** what's the best way to stream the iPhone's live camera from the native AR app to the expert's
browser dashboard, with low latency, at a venue with unknown Wi-Fi?

**Status:** 🟢 researched 2026-11-14; recommendation below, **not decided**. Sources and verdicts:
`research/ledger.md` § 2.

**Recommendation:** start with **JPEG frames over our existing WebSocket relay**. Upgrade to **LiveKit Cloud** only if
JPEG is stable and there are spare hours.

| Option | Latency / quality | Effort for us | Main risk |
|---|---|---|---|
| **A, JPEG frames over the `ws` relay** (about 640 px, quality 0.5, 8–12 fps) | Low on the same Wi-Fi, worse on 4G. Blocky but fine for "where's the phone pointing" | **Lowest.** Phone sends the newest frame, browser draws it to a canvas | Bandwidth (roughly 2–5 Mbps, our estimate, not measured) |
| **B, LiveKit Cloud** (hosted video service) | Proper low-latency video that adapts to the connection | Medium. Swift SDK takes our ARKit frames directly; the Node server mints access tokens | New dependency and a free-tier account; needs venue internet |
| C, our own WebRTC through the relay | Best | High: hand-written connection setup, and a TURN server for 4G | Connection failures that are hard to debug at a demo |
| D, H.264 over WebSocket, decoded in the browser | Good, 5–10× less data than JPEG (estimate) | Medium–high, fiddly encoder setup | Browser support and keyframe handling |
| E, HLS / RTMP streaming | Seconds of delay | — | Too laggy. Don't use |

**Things that matter whichever we pick:**
- **Send only the newest frame** and drop the rest while the connection is busy, so delay never builds up.
- **Send the camera pose and lens data with each frame.** The dashboard can then draw the guide's objects over the
  video in three.js itself, instead of the phone burning time capturing its own AR overlay.
- **The relay needs a public address** (a tunnel such as Cloudflare Tunnel or ngrok, or a server) if the phone is on
  4G. A laptop on venue Wi-Fi isn't reachable from 4G.
- **Fallback for bad venue internet:** phone and laptop on one hotspot, local relay, JPEG.
- **Unverified:** the bandwidth numbers, how fast the phone can capture its AR overlay, and the free tiers of Daily,
  Agora and Twilio (not checked).

**Working default (2026-11-14, not confirmed by the team):** A now, B later if there are spare hours. LiveKit and a tunnel are new dependencies (CLAUDE.md §2), so the team can still overturn this at kickoff.

---

## 4. Getting from a scan to a splat, and cutting parts out

**The question:** what's the fastest reliable route from the iPhone scan to a splat on the expert's laptop, and how
do we cut a part out of it and get that part onto the phone?

**Status:** 🟢 researched 2026-11-14 (`research/ledger.md` § 4). Working default set, not confirmed by the team.

**Scan → splat:**

| Route | Time (estimates) | Risk |
|---|---|---|
| **Scaniverse on the iPhone** (free, works without LiDAR, exports .ply and .spz) | About 10–15 min end to end | Low. Scale is probably close to real-world but undocumented, so check it against a ruler in the scan |
| **Dawn:** frames → COLMAP's built-in global mapper (GLOMAP) on CPU → gsplat's Intel GPU fork | First run 3–5 h, then about 1 h | High. The Intel fork is only tested on consumer Arc GPUs, not Dawn's Max 1550, and its own pull request is still open. **We don't know if a hackathon team can get a Dawn account at all** |
| Dawn for COLMAP only, train on a laptop with Brush (a trainer that supports Intel GPUs) | 1–2 h | Medium |

**Working default:** Scaniverse first, so we have a splat within the first hour. Dawn runs alongside as the stretch
goal and the "trained on a supercomputer" pitch line.

**Cutting a part out (dashboard, Spark):**
- Spark's built-in edit shapes only hide or tint splats at draw time. A real cut-out goes through its CPU API: loop
  over the splats, keep the ones inside the expert's box, and build a new splat object from them. That object can
  then be moved and animated on its own.
- Hide the same box in the original scan, so the part doesn't appear twice.
- Export the cut-out as **.ply**. The iPhone side can't read .spz.

**Showing it on the iPhone (RealityKit, iOS 27):**
- Parse the .ply ourselves into RealityKit's splat buffers. Apple's sample code includes a parser. Rotations are
  stored **w, x, y, z**. Raw .ply values need exponential scale and sigmoid opacity. Strip out NaN values, or loading
  fails.
- **Animate the object's position and rotation, not its opacity.** Fading is broken on iOS (Apple confirmed).
  Changing splat buffers at runtime isn't supported either.
- It doesn't run in the iOS Simulator. Test on the real iPhone.

**How this changes alignment ([§ 1](#1-lining-up-the-scan-with-the-real-room)):** with Scaniverse there's no COLMAP
step to triangulate the marker in. Instead, the expert clicks the marker's corners in the splat once. That's accurate,
because the splat doesn't move. The phone still detects the marker live.

**Still unknown, and can't be researched online:** whether DurHack teams can get Dawn access. A task for whoever
talks to the organisers.
