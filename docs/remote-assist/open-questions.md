# Open questions: things we have to figure out

The hard problems that need real thought before anyone builds on them. Each one has an owner, what's known, the
options, and what "figured out" looks like. When one is settled, move the answer into
[architecture.md](architecture.md) and mark it ✅ here, with the date and who decided. Don't delete it.

Each answer below lists its sources inline. The full research, with every source rated KEEP / WEAK / DO NOT USE, is in
`research/ledger.md` on the `context` branch (the § numbers below).

| # | Question | Status | Owner |
|---|---|---|---|
| 1 | [Lining up the scan with the real room](#1-lining-up-the-scan-with-the-real-room) | ✅ Decided: printed marker (Ahmed, 2026-11-14); accuracy not yet measured | @ahmed @max |
| 2 | [Showing splat cut-outs on the iPhone](#2-showing-splat-cut-outs-on-the-iphone) | 🟠 Decided as box + built-in model (Ahmed), **reopened**: this research says real splats may work | @ahmed @max |
| 3 | [Getting the live camera to the expert](#3-getting-the-live-camera-to-the-expert) | ✅ Decided: WebRTC (Ahmed, 2026-11-14), against this page's recommendation | @ahmed @salman |
| 4 | [Getting from a scan to a splat, and cutting parts out](#4-getting-from-a-scan-to-a-splat-and-cutting-parts-out) | ✅ Decided: Scaniverse first; the DGX Spark replaces Dawn (Ahmed, Max) | @max |
| 5 | [Which library draws the splat in the dashboard](#5-which-library-draws-the-splat-in-the-dashboard) | ✅ Decided: Spark on three.js, with a kill test (Max, 2026-11-14) | @max |
| 6 | [What the dashboard app is built with](#6-what-the-dashboard-app-is-built-with) | ✅ Decided: Vite + React, plain three.js (Max, 2026-11-14) | @max |
| 7 | [Is Scaniverse the best scan app for our iPhones](#7-is-scaniverse-the-best-scan-app-for-our-iphones) | 🟢 Answered, recommendation not decided | @max |
| 8 | [Can a video of the room become a solid 3D model (mesh)](#8-can-a-video-of-the-room-become-a-solid-3d-model-mesh) | 🟢 Answered: yes, on the DGX Spark; not decided | @max |
| 9 | [Can a splat become a mesh](#9-can-a-splat-become-a-mesh) | 🟢 Answered: possible, but poor | @max |
| 10 | [Phone → DGX Spark → model back on the phone](#10-phone--dgx-spark--model-back-on-the-phone) | 🟢 Answered: works; not decided or built | @max @salman |

**Since this page was first written (2026-11-14 evening):**
- The demo set is now **Ahmed's laptop, and the guide is an SSD swap** (whole team, logged by Laura at 23:03). "The
  cupboard" and "the patch panel" below mean the old set. A laptop is dark and shiny, which is harder to scan.
- We have an **NVIDIA DGX Spark**, not Dawn access. Read "Dawn" below as history.
- The phones are an **iPhone 13 and an iPhone 15** (no LiDAR).

---

## 1. Lining up the scan with the real room

**✅ Decided (Ahmed, 2026-11-14): B, the printed marker, under ARKit world tracking.** Guide positions travel in the
marker's frame, in metres; the dashboard converts from the splat using the expert's four corner clicks, and the
phone does no maths (`contracts/protocol.ts`). Laura's marker is printed and measured at 180 mm. **Still open:**
nobody has measured the accuracy, and what the dashboard does before calibration (`docs/remote-assist/scene-api.md`).

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

**Status:** 🟠 Ahmed decided **B, a box plus the closest built-in model**, before this research landed; it's
reopened in `PROJECT.md` → Pending for Ahmed and Max. The box-and-model path is being built either way. Our phones
are an iPhone 13 (A15) and iPhone 15 (A16); `GaussianSplatComponent` needs the Apple7 GPU family or newer, which both
are, so A is possible **if** they run iOS 27.2+ (Salman to check). Sources and verdicts: `research/ledger.md` § 1.

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

**Status:** ✅ **Decided by Ahmed (2026-11-14): WebRTC from the start**, with signalling over the relay websocket,
against the recommendation below. The research is kept as the record of the alternative. Sources and verdicts:
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

**Status:** ✅ **Decided (Ahmed): Scaniverse is the main route.** We have no Dawn access; the team's **DGX Spark**
is the upgrade instead ([§ 8](#8-can-a-video-of-the-room-become-a-solid-3d-model-mesh) and `research/ledger.md` § 9,
§ 12). Research: `research/ledger.md` § 4.

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

---

## 5. Which library draws the splat in the dashboard

**✅ Decided (Max, 2026-11-14): Spark 2.4 on three.js, proven by a short spike with a kill test.** The spike has to
hold 30 fps or more on the weakest team laptop, pick a point in under 300 ms, and cut a part out in under 2 s. If the
frame rate fails, PlayCanvas gets the same test. Research: `research/ledger.md` § 7.

**Why Spark:**
- It's the only option with a plain way to cut parts out from code: collect the splats inside a box and build a new
  object from them (`PackedSplats.extractSplats`, in the 2.4.0 type definitions). Clicking works through three.js's
  normal raycaster. Its splats are ordinary three.js objects, so Laura's glTF models sit in the same scene.
  Sources: [Spark SplatMesh docs](https://sparkjs.dev/docs/splat-mesh/),
  [Spark overview](https://sparkjs.dev/docs/overview/),
  [Spark v2.4.0 release](https://github.com/sparkjsdev/spark/releases/tag/v2.4.0).
- Known costs: cut-outs keep only the base colour (no shine that changes with the view); one exact pick costs about
  350 ms on a multi-million-splat file; it's slow in Firefox, so demo in Chrome.
  Sources: [Spark #468](https://github.com/sparkjsdev/spark/issues/468),
  [Spark #190](https://github.com/sparkjsdev/spark/issues/190),
  [Spark #225](https://github.com/sparkjsdev/spark/issues/225).

**Alternatives not picked:**
- **PlayCanvas:** the best offline editor (SuperSplat) and the fastest WebGPU path, but cutting parts out from code
  means rebuilding splat data by hand with thin docs. No independent speed benchmark found either way.
  Sources: [PlayCanvas 2.24.0 release](https://github.com/playcanvas/engine/releases/tag/v2.24.0),
  [PlayCanvas forum, programmatic splat data](https://forum.playcanvas.com/t/programmatic-access-to-splat-data/41492).
- **GaussianSplats3D:** no longer developed; its README points to Spark.
  Source: [GaussianSplats3D README](https://github.com/mkkellogg/GaussianSplats3D).
- **A two-library bake-off:** 2–4 h, and PlayCanvas would likely lose on the hardest task (cut-outs).

---

## 6. What the dashboard app is built with

**✅ Decided (Max, 2026-11-14): Vite 8 + React 19 + TypeScript.** The 3D view is plain three.js + Spark in
`dashboard/src/scene/`, mounted once and kept out of React, behind `dashboard/src/scene/api.ts`. No React Three Fiber.
A zustand store when shared state is needed. Research: `research/ledger.md` § 8.

**Why:**
- Real 3D editors keep the engine separate from the UI: SuperSplat, the three.js editor and the PlayCanvas editor all
  do. Sources: [SuperSplat](https://github.com/playcanvas/supersplat),
  [three.js editor UI](https://github.com/mrdoob/three.js/blob/dev/editor/js/libs/ui.js),
  [PCUI](https://github.com/playcanvas/pcui).
- React has the deepest ecosystem for Laura's editor UI (lists, drag-and-drop, forms).
- Fast-changing 3D data belongs in the render loop, not in React state.
  Source: [R3F performance pitfalls](https://r3f.docs.pmnd.rs/advanced/pitfalls).

**Alternatives not picked:**
- **React Three Fiber:** Spark has open issues there (pointer events on a splat peg the CPU, several canvases break),
  and it would blur the line between Max's and Laura's code.
  Sources: [Spark #75](https://github.com/sparkjsdev/spark/issues/75),
  [Spark #98](https://github.com/sparkjsdev/spark/issues/98).
- **Next.js:** the research reported Spark's WASM breaking under Webpack
  ([Spark #97](https://github.com/sparkjsdev/spark/issues/97)). Spark 2.4 inlines its WASM (checked in the package),
  so that reason may be out of date. It didn't change the pick: we need no server rendering.
- **Svelte 5 or plain TypeScript:** lighter, but a thinner editor-UI ecosystem.

---

## 7. Is Scaniverse the best scan app for our iPhones

**🟢 Answered (2026-11-14), recommendation not decided.** Research: `research/ledger.md` § 11.

**Short answer:** it's the best *quick* option, not the sharpest possible.
- **Scaniverse Classic** trains the splat on the phone, free and unlimited, in about 2 minutes, with nothing uploaded.
  It works without LiDAR and exports .ply and .spz. Since April 2026 a separate cloud mode exists (credits, hours).
  Sources: [Scaniverse on the App Store](https://apps.apple.com/us/app/id1541433223),
  [Niantic Spatial Scaniverse FAQ](https://www.nianticspatial.com/faq/scaniverse),
  [radiancefields.com, April 2026 update](https://radiancefields.com/niantic-releases-major-scaniverse-update).
- **Paid alternatives aren't clearly better:** Polycam needs about $30/month for a splat export; KIRI's splats are
  Pro only (about €18/month). Sources: [Polycam pricing](https://poly.cam/pricing),
  [KIRI Basic vs Pro](https://www.kiriengine.app/blog/kiri-engine-basic-vs-pro).
- **Ruled out:** Luma (moved to AI video; capture app unmaintained), Apple Object Capture on the phone (needs LiDAR),
  Varjo Teleport (room-scale, slow). Sources:
  [Apple: creating 3D objects from photographs](https://developer.apple.com/documentation/realitykit/creating-3d-objects-from-photographs.md),
  [Apple Developer Forums 775564](https://developer.apple.com/forums/thread/775564).
- **Scale is undocumented:** check it against the 180 mm marker whatever the app.
  Source: [SketchUp splat best practices](https://help.sketchup.com/en/gaussian-splats-best-practices).

**Recommendation:** Scaniverse Classic for the first splat; train the same set on the DGX Spark for sharpness
([§ 8](#8-can-a-video-of-the-room-become-a-solid-3d-model-mesh)). Capture: locked exposure and focus, HDR video off,
slow orbits at three heights, close passes over the parts, soft even light.
Source: [PlayCanvas: taking photos](https://developer.playcanvas.com/user-manual/gaussian-splatting/creating/taking-photos/).

---

## 8. Can a video of the room become a solid 3D model (mesh)

**🟢 Answered (2026-11-14): yes, on the DGX Spark. Not decided.** Research: `research/ledger.md` § 12, § 13, § 14.

A **splat** is millions of soft coloured blobs: photo-real, but with no surface. A **mesh** is a solid shell of
triangles with a picture painted on: less real-looking, but phones, game engines and measuring tools understand it.

**Not possible:** making the mesh on the phone itself; Apple's scanner needs LiDAR there
([Apple Developer Forums 775564](https://developer.apple.com/forums/thread/775564)).

**Routes on the DGX Spark, most likely to work tonight first (times are estimates):**
1. **Camera positions (COLMAP) → a mesh-friendly splat (2DGS: flat discs that sit on surfaces) → fuse into a solid
   shell (open3d TSDF) → paint the colours on as a texture (pymeshlab).** About 1–2 h. Every piece is proven or
   installs on the Spark's ARM chip. 2DGS scores about 3× plain splats on geometry benchmarks.
   Sources: [2DGS, SIGGRAPH 2024](https://arxiv.org/html/2403.17888),
   [gsplat 2DGS trainer](https://github.com/nerfstudio-project/gsplat/tree/main/examples),
   [open3d 0.20.0 with aarch64 wheels](https://pypi.org/pypi/open3d/json),
   [PyMeshLab filters](https://pymeshlab.readthedocs.io/en/latest/filter_list.html),
   [Classmethod: splats on a DGX Spark](https://dev.classmethod.jp/en/articles/dgx-spark-3dgs-digital-twin/).
2. **Fast backup, 30–45 min:** an AI model (VGGT, Depth Anything 3, MapAnything) guesses depth per frame, fused the
   same way. Coarse: no 1 cm detail. Sources: [VGGT](https://github.com/facebookresearch/vggt),
   [MapAnything](https://github.com/facebookresearch/map-anything),
   [multi-view stereo comparison, 2026](https://arxiv.org/abs/2604.10246).
3. **Best quality, a stretch:** COLMAP's detailed depth step on the Spark's GPU (fixed for Blackwell in April 2026),
   then OpenMVS for a texture made from the real photos. Avoid COLMAP's own mesher, which crashes on ARM.
   Sources: [COLMAP PR #4213](https://github.com/colmap/colmap/pull/4213),
   [COLMAP #3514](https://github.com/colmap/colmap/issues/3514),
   [COLMAP #4335](https://github.com/colmap/colmap/issues/4335),
   [OpenMVS releases](https://github.com/cdcseacave/openMVS/releases).
- **Off the Spark:** Apple Object Capture on an Apple-silicon Mac, or Epic's RealityScan on a Windows GPU laptop.
  Sources: [WWDC24, area mode for Object Capture](https://developer.apple.com/videos/play/wwdc2024/10107/),
  [RealityScan 2.2](https://digitalproduction.com/2026/06/26/realityscan-2-2-widens-gpu-support/).
- **Not tonight:** nvblox and fVDB (x86 wheels only), Neuralangelo (days), running x86 tools through emulation.
  Sources: [nvblox install](https://nvidia-isaac.github.io/nvblox/v0.0.9/pages/installation.html),
  [fVDB install](https://fvdb-reality-capture.readthedocs.io/latest/installation.html),
  [FEX-2607](https://fex-emu.com/FEX-2607/).

**The catch for the SSD demo:** black shiny plastic and thin parts leave holes in every method. Soft, even light
helps. One option professional scanners use is a temporary matte coating (a "vanishing" scanning spray that
evaporates after an hour or two); the evidence is weak and nothing is planned. Try a plain scan first.
Source: [aniwaa: scanning sprays](https://www.aniwaa.com/insight/3d-scanners/3d-scanning-spray-overview/) (weak).

**What a mesh is for here:** a real textured model of a part on the phone instead of a stand-in, exact clicking on
that part, and measuring. The room itself stays a splat in the dashboard.

---

## 9. Can a splat become a mesh

**🟢 Answered (2026-11-14): technically yes, practically poor.** Research: `research/ledger.md` § 13.
- Converting a finished splat scored about a third as well as training a mesh-friendly model from the photos
  (Tanks & Temples F1 0.09 vs 0.30). Sources: [2DGS paper](https://arxiv.org/html/2403.17888),
  [MILo paper](https://arxiv.org/html/2506.24096v2).
- To come out clean it needs coarse 2 cm blocks, which erase 1 cm parts. Source:
  [NVIDIA forum, fVDB mesh from 3DGS](https://forums.developer.nvidia.com/t/fvdb-reality-capture-poor-mesh-quality-from-3dgs-parameter-tuning-alternatives/369420)
  (one user, weak).
- The better post-hoc method needs the original camera positions, which a Scaniverse file doesn't carry.
  Source: [GS2Mesh, ECCV 2024](https://arxiv.org/abs/2404.01810).

**So:** if we want a mesh, make it from the photos ([§ 8](#8-can-a-video-of-the-room-become-a-solid-3d-model-mesh)),
not from the splat.

---

## 10. Phone → DGX Spark → model back on the phone

**🟢 Answered (2026-11-14): it works. Not decided or built.** Research: `research/ledger.md` § 15.
- **Tonight, no code:** send the video from the iPhone to the Spark with LocalSend (free, open source, iPhone app and
  ARM Linux build). Use the phone hotspot if venue Wi-Fi blocks device-to-device traffic.
  Sources: [LocalSend](https://github.com/localsend/localsend),
  [LocalSend v1.18.2 release](https://github.com/localsend/localsend/releases).
- **In the app:** Salman's ARKit session can save each frame with the phone's own position, then upload them in one
  go. Sources: [ARCamera.transform](https://developer.apple.com/documentation/arkit/arcamera/transform),
  [WWDC22 Discover ARKit 6](https://developer.apple.com/videos/play/wwdc2022/10126),
  [URLSession file upload](https://developer.apple.com/documentation/foundation/urlsession/uploadtask(with:fromfile:)).
- **The phone's positions are only accurate to about a centimetre:** fine for AR, too loose for a sharp model. They
  make the camera-position step faster and more reliable (COLMAP's "known poses" recipe), not unnecessary.
  Sources: [Kim et al., VIO benchmark, 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC9785098),
  [CamP, SIGGRAPH Asia 2023](https://camp-nerf.github.io), [COLMAP FAQ](https://colmap.github.io/faq.html).
- **Back to the phone:** RealityKit needs a UV-textured model, not vertex colours; usd-core 26.11 can write USDZ on
  the Spark's ARM chip. Sources: [Apple Developer Forums 691674](https://developer.apple.com/forums/thread/691674),
  [usd-core on PyPI](https://pypi.org/project/usd-core/),
  [Entity(contentsOf:)](https://developer.apple.com/documentation/realitykit/entity/init(contentsof:withname:)).
- **Time:** about 10–30 min end to end with a fast mesh route (estimate, nothing measured). Only demo "it appears a
  few minutes later" after timing a real run; otherwise label it REPLAY.

**Raw gyroscope and accelerometer alone can't place the phone:** position comes from adding up acceleration twice,
so small errors snowball within seconds. ARKit already fuses the motion sensors with the camera, and the marker
anchors it to the room (§ 1). Source: [Kim et al., 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC9785098)
(ARKit drift about 2 cm/s off-marker, one benchmark).
