# Research ledger: TBD (DurHack 2026)
The one research file for this project (`research-ledger` skill). Every source gets a verdict:
**KEEP** (corroborated by ≥2 independent sources) · **WEAK** (thin support; never the only basis for a claim) ·
**DO NOT USE** (refuted; quarantined at the bottom of its section, with its numbers stripped from active use).

## CATEGORY INDEX
*One row per research pass, so a future pass loads only the section it needs.*

| § | Covers | Use it for |
|---|---|---|
| 1 | Gaussian splats on iPhone AR (2026-11-14) | Can the phone draw a splat cut-out; stand-in options |
| 2 | Live iPhone camera to a browser (2026-11-14) | Picking the live video path |
| 3 | Aligning a splat with the real room on a non-LiDAR iPhone (2026-11-14) | Marker vs ARKit poses vs tap points; accuracy |
| 4 | Scan-to-splat pipeline, Spark cut-outs, RealityKit splat format (2026-11-14) | Scaniverse vs Dawn; cutting parts out; loading on iOS |
| 5 | Add-ons to § 2 and § 3: marker under world tracking, ARKit holding the camera (2026-11-14) | Which ARKit configuration to use; why the stock WebRTC capturer fails |
| 6 | Which frame guide positions travel in: the marker's or the splat's (2026-11-14) | The protocol's coordinate rules; what the phone must check on device |
| 7 | Splat renderer for the dashboard: Spark vs PlayCanvas vs the rest (2026-11-14) | Picking the renderer; picking and cut-out APIs; the spike's pass criteria |
| 8 | Dashboard shell: build tool, UI layer, R3F or not, scene-UI state (2026-11-14) | Scaffolding `dashboard/`; the scene/guide seam |
| 9 | Training our own splat on the DGX Spark (2026-11-14) | Whether and how to beat Scaniverse's splat; replaces the Dawn route |
| 10 | The UNO Q rig: Nicla Vision → UNO Q → relay (2026-11-14) | Wiring the RS hardware check; what to test on the board first |
| 11 | Scanning on a non-LiDAR iPhone: Scaniverse vs the other apps (2026-11-14) | Which app captures the set; capture technique |
| 12 | Video to splat on our own hardware, including pose-free models (2026-11-14) | The DGX Spark pipeline step by step; when VGGT helps |
| 13 | Meshes: from video, and from a splat (2026-11-14) | Whether to make meshes; textured parts for the phone |
| 14 | Video to a textured mesh on the DGX Spark (2026-11-14) | Mesh routes ranked for tonight; open3d and COLMAP on ARM |
| 15 | Phone → DGX Spark → mesh back on the phone (2026-11-14) | ARKit camera positions, upload, USDZ/GLB conversion |
| 16 | App Lab app layout and the UNO Q's LED matrix over the Bridge (2026-11-15) | Packaging the rig; drawing ✓ / ✗ |
| 17 | Swapping the SSD on a Dell Latitude 5530 (2026-11-15) | The demo guide's real steps, screw counts and tools |

---

<!-- Copy this block for each pass. -->
<!--
# § <n> <topic> (<YYYY-MM-DD>)
**Question:** <what we needed to know, and why>

## Findings
### <sub-topic>
- <claim> (sources: [1], [2])

## Community consensus
<Reddit / HN / StackExchange: what most people agree on, weighted by agreement and repetition; the contrasting view
and which wins>

## Final call (professional + community)
<the answer we act on, in 2–4 lines>

## Source ledger
### KEEP
- [1] <title>, <venue>, <date>, <url>: <what it supports>
### WEAK
### DO NOT USE
- <source>: <the discredited claim + the refuting sources>. Tombstone, so it isn't re-litigated.
-->


# § 1 Gaussian splats on iPhone AR (2026-11-14)
**Question:** can a native iPhone ARKit app draw a cut-out of a Gaussian splat over the live camera and animate it?
Decides open question 2 in `docs/remote-assist/open-questions.md`.

## Findings
### Native RealityKit support
- iOS 27 adds `GaussianSplatComponent` / `GaussianSplatResource` to RealityKit, on iOS, iPadOS, macOS and visionOS
  27.0+, needing an Apple7-family GPU or newer (iPhone 16 qualifies) (sources: [1], [2]).
- No file loading: the app fills the splat buffers itself; .ply is the standard path "for now" ([3]).
- An internal per-resource splat limit exists; 200k reported ([3], WEAK) vs about 400k running on an iPhone 16 Pro
  ([4], WEAK). Unresolved; irrelevant for a few-thousand-splat cut-out.
- Drawn in the transparency pass, unaffected by scene lighting, no custom shaders ([2]).
- iPhone AR use reported working on iOS 27 betas, culling bug fixed in 27.2 ([4], WEAK, one developer).
### Third-party renderers
- MetalSplatter renders PLY/SPZ/.splat on iOS, macOS, visionOS ([5]); its AR mode is visionOS only ([6], WEAK); no
  iPhone ARKit example found.
### Alternatives
- Mesh conversion (SuGaR, 2DGS) needs retraining or a CUDA GPU: too slow for a hackathon. A primitive stand-in sized
  to the cut-out is the cheap fallback (estimate, unsourced).
- A web view can't get WebXR immersive-ar on iPhone Safari, so it can't track the room.

## Community consensus
Not mined (no Reddit/HN pass in this time box). Apple developer forum threads are the only community sources, and
they disagree on the splat limit.

## Final call (professional + community)
Use RealityKit splats on iOS 27.2+ for the cut-out, with a stand-in model built in parallel as the fallback. Check
the demo iPhone's iOS version and Xcode 27 on the Mac on day one. iPhone AR use rests on one forum report.

## Source ledger
### KEEP
- [1] Explore advances in RealityKit, WWDC26 session 279, Apple, 2026, https://developer.apple.com/videos/play/wwdc2026/279 : introduces the splat API (demoed on Vision Pro).
- [2] GaussianSplatComponent, Apple Developer Documentation, https://developer.apple.com/documentation/realitykit/gaussiansplatcomponent : platforms, GPU family, rendering limits.
- [3] Apple Developer Forums thread 831696, https://developer.apple.com/forums/thread/831696 : Apple engineer on .ply ingestion (the 200k figure in the thread is WEAK).
- [5] MetalSplatter, GitHub, https://github.com/scier/MetalSplatter : iOS/macOS/visionOS Metal splat renderer.
### WEAK
- [4] Apple Developer Forums thread 838974, https://developer.apple.com/forums/thread/838974 : one developer, iPhone 16 Pro AR, about 400k splats, 27.2 culling fix.
- [6] MetalSplatter 1.0 released, radiancefields.com, https://radiancefields.com/metalsplatter-1-0-released : AR only on visionOS.
- iOS 27 release timeline, foxdata.com, https://foxdata.com/en/blogs/ios-27-release-timeline-confirmed-public-beta-midjuly-official-launch-september-14/ : ship date; no primary Apple source found.
### DO NOT USE
- "RealityKit can't draw splats" (our own round-2 claim, 2026-11-14): true before iOS 27, refuted by [1] and [2].

# § 2 Live iPhone camera to a browser (2026-11-14)
**Question:** how should a native iPhone ARKit app stream its live camera to the expert's browser dashboard, with low
latency, at a venue with unknown Wi-Fi? Decides open question 3 in `docs/remote-assist/open-questions.md`.

## Findings
### WebRTC, own setup
- ARKit pixel buffers can be fed to the WebRTC iOS framework as a custom capturer ([1]); NV12 and RGB buffers are
  accepted ([2]). ARKit's capturedImage is bi-planar YCbCr ([7], WEAK).
- Mobile carrier NAT often needs TURN, roughly 10–25% of sessions by one vendor's estimate ([8], WEAK, vendor blog).
  Cloudflare offers free TURN up to 1,000 GB/month ([3]).
### LiveKit Cloud
- Free tier: 5,000 participant minutes, 50 GB downstream, no card ([4]).
- The Swift SDK's BufferCapturer takes CVPixelBuffer/CMSampleBuffer, with AR named as a use case ([5]; mirror [9]
  WEAK).
### JPEG over WebSocket, H.264 + WebCodecs
- WebCodecs: Chrome/Edge 94+, Firefox 130+, Safari full only from 26.0 ([6]).
- JPEG bandwidth (2–5 Mbps at 640 px, 8–12 fps) and H.264's 5–10× saving are estimates, not sourced or measured.
- HLS/RTMP add seconds of latency (unsourced, general knowledge).

## Community consensus
Not mined in this time box.

## Final call (professional + community)
JPEG frames over the existing `ws` relay first (lowest effort, no NAT trouble since the phone dials out). LiveKit
Cloud as the upgrade if there's time. Put the relay on a public address for 4G, and keep a single-hotspot fallback.

## Source ledger
### KEEP
- [1] ARDExternalSampleCapturer.m, WebRTC source, https://webrtc.googlesource.com/src/+/lkgr/examples/objc/AppRTCMobile/ARDExternalSampleCapturer.m : custom frame capturer on iOS.
- [2] WebRTC commit f3ee3b74, https://webrtc.googlesource.com/src.git/+/f3ee3b7478713a723e886d7a5aa3d4d41a0ca4bf : NV12/RGB pixel buffers.
- [3] Cloudflare Realtime TURN FAQ, https://developers.cloudflare.com/realtime/turn/faq/ : free TURN quota.
- [4] LiveKit pricing, https://livekit.com/pricing : free tier.
- [5] livekit/client-sdk-swift PR 611, https://github.com/livekit/client-sdk-swift/pull/611/files : BufferCapturer (a PR diff; confirm on main).
- [6] Can I use: WebCodecs, https://caniuse.com/webcodecs : browser support.
### WEAK
- [7] Apple Developer Forums thread 681302, https://developer.apple.com/forums/thread/681302 : capturedImage format.
- [8] expressturn.com blog, https://blog.expressturn.com/webrtc-calls-fail-on-mobile-networks : TURN need on mobile (vendor).
- [9] LiveKit custom capturer docs mirror, mintlify.com, https://www.mintlify.com/livekit/client-sdk-swift/api/capturers/custom-capturer : third-party mirror.
- Daily, Agora, Twilio free tiers: not checked.
### DO NOT USE


# § 3 Aligning a splat with the real room on a non-LiDAR iPhone (2026-11-14)
**Question:** how can an iPhone 16 (no LiDAR) line up a pre-made splat with the real cupboard to about 1–2 cm?
Feeds open question 1 in `docs/remote-assist/open-questions.md`.

## Findings
- No published measurement shows any method reaching 1–2 cm on a non-LiDAR iPhone. Must be measured on the set.
- Image anchors need the exact printed size, or position and stability suffer ([1]; corroborated on forums). Tiny
  markers (26 mm) track badly ([7], WEAK). Use 15–20 cm.
- ArUco markers seen in COLMAP frames can be triangulated, which also gives metric scale (`aruco-estimator`, needs
  2+ images, one marker, work in progress) ([2], [3]). A tool released 30 Oct 2026 bakes AprilTag alignment into the
  COLMAP model and splat ([8], WEAK).
- `colmap model_aligner` fits rotation, translation and scale to reference camera centres, needing 3+ images ([4]).
  Flag names differ between versions; a "successful" fit has gone badly wrong for one user ([9], WEAK).
- ARWorldMap survives app relaunch, but relocalizing "strongly depends" on the environment and suffers with lighting
  changes ([5]; failures reported in [10], WEAK).
- nerfstudio imports ARKit-posed captures from Polycam/Record3D (LiDAR modes) ([6]); NeRFCapture exports ARKit-posed
  frames ([11]).
- Taps on non-LiDAR feature points and estimated planes are unreliable for small targets ([12], [13], both WEAK but
  agreeing).
- ARKit object detection suits rigid tabletop objects, no accuracy figures ([14]).
- General AR placement error around 1.5 cm in one study, not image-anchor specific ([15], WEAK).

## Community consensus
Apple developer forums and the COLMAP group agree: non-LiDAR taps are imprecise, image anchors need the exact size,
and world-map relocalization is fragile with lighting changes. No Reddit/HN pass.

## Final call (professional + community)
A 15–20 cm printed marker in the scan and detected live, with ARKit poses recorded during the scan for metric scale.
Tap-to-correct as a fallback; ARWorldMap a stretch. Measure the error with a ruler before the demo.

## Source ledger
### KEEP
- [1] Detecting images in an AR experience, Apple, https://developer.apple.com/tutorials/data/documentation/arkit/detecting-images-in-an-ar-experience.md : exact physical size needed.
- [2] aruco-estimator 1.1.5, PyPI, https://pypi.org/project/aruco-estimator/1.1.5/ : ArUco triangulation in COLMAP.
- [3] arXiv 2604.18205, https://arxiv.org/pdf/2604.18205 : marker-based scale and alignment.
- [4] COLMAP FAQ, https://colmap.readthedocs.io/en/stable/faq.html : model_aligner.
- [5] Managing session life cycle and tracking quality, Apple, https://developer.apple.com/documentation/arkit/managing-session-life-cycle-and-tracking-quality.md : ARWorldMap relocalization.
- [6] nerfstudio custom data, https://docs.nerf.studio/quickstart/custom_dataset.html : ARKit-posed imports.
- [11] NeRFCapture, App Store, https://apps.apple.com/us/app/-/id6446518379 : ARKit-posed frame export.
- [14] Scanning and detecting 3D objects, Apple, https://developer.apple.com/documentation/arkit/scanning-and-detecting-3d-objects.md : object detection scope.
### WEAK
- [7] Apple Developer Forums 101872, https://developer.apple.com/forums/thread/101872 : small marker unreliable.
- [8] Spirula Studio AprilTag alignment, radiancefields.com, https://radiancefields.com/spirula-studio-v2026.10.30-adds-apriltag-alignment
- [9] COLMAP Google group, https://groups.google.com/g/colmap/c/6qYieMyK4XI : model_aligner pitfalls.
- [10] Apple Developer Forums 690668, https://developer.apple.com/forums/thread/690668 : world map failures.
- [12] Apple forums (CurvSurf replies), https://origin-devforums.apple.com/forums/profile/CurvSurf/replies?page=2 : feature points inaccurate.
- [13] Apple Developer Forums 711139, https://developer.apple.com/forums/thread/711139 : estimated-plane raycasts inconsistent.
- [15] NSF PAR 10339780, https://par.nsf.gov/servlets/purl/10339780 : general AR placement error.
- ARKit drift about 0.02 m/s on iPhone 12 Pro Max, PMC9785098, https://pmc.ncbi.nlm.nih.gov/articles/PMC9785098 : single benchmark.
### DO NOT USE

# § 4 Scan-to-splat pipeline, Spark cut-outs, RealityKit splat format (2026-11-14)
**Question:** fastest reliable route from an iPhone scan to a splat; whether Dawn can train it; how to cut a part
out in Spark and load it in RealityKit. Feeds open questions 2 and 4.

## Findings
### Dawn and gsplat on Intel GPUs
- isl-org/gsplat (branch `sycl_code_integration`) adds a SYCL backend with install steps and a prebuilt wheel for
  torch 2.10+xpu; tested on Arc iGPUs, A770, B580 only; no 3DGUT or compression; 30k-step runs ran out of memory on a
  B580; 7k steps took 519–919 s on a B580 ([1]). Its initial-backend PR is still open ([10], WEAK, mirror).
- Dawn nodes have 4× Intel Max 1550 ([2]). Access is through UKRI/DSIT allocations; a 2024 hackfest gave teams nodes
  ([3]). Dawn's ML docs use an IPEX conda env, likely stale ([4]).
- Brush trains splats with WebGPU on Intel GPUs and reads COLMAP ([5]); headless use on a GPU node unverified.
### COLMAP vs GLOMAP
- GLOMAP's mapping is far faster at similar accuracy, e.g. 133 s vs 1115 s on one ETH3D sequence ([6]); it's in
  recent COLMAP as `global_mapper`, which needs good focal priors; without CUDA everything except dense works ([7]).
### Scaniverse
- Free, on-device splats, exports PLY and SPZ, iOS 16.6+, works without LiDAR ([8]). Metric scale undocumented.
### Spark
- Loads .ply, .spz, .splat, .ksplat, .sog, .rad ([9]). SplatEdit/SplatEditSdf act at render time only ([11]).
  A true cut-out uses `PackedSplats.forEachSplat` + `pushSplat` into a new SplatMesh ([12]).
### RealityKit GaussianSplatComponent (iOS 27)
- iOS/macOS/visionOS 27, Apple7 GPU family, not in Simulator ([13]). Buffers filled by the app: position and scale
  float3, rotation float4 in w,x,y,z, opacity float, SH degree 0–3; raw PLY needs exponential scale and sigmoid
  opacity; NaN/Inf rejected ([13], [14]). No native SPZ ([15], WEAK).
- A per-resource splat limit exists, number unpublished (200k reported [16], 400k ran [17], both WEAK).
- OpacityComponent fades are broken on iOS, Apple-confirmed ([18]). Runtime buffer mutation "not supported" per an
  Apple engineer ([16]).

## Community consensus
GitHub issues and Apple forums: the Intel gsplat fork works on consumer Arc cards, with no reports on PVC; Apple's
splat API works but has a limit and young bugs. No Reddit/HN pass.

## Final call (professional + community)
Scaniverse first (about 15 min, low risk), Dawn as a stretch goal. Cut-outs via Spark's CPU API, exported as PLY,
parsed into RealityKit buffers on the phone; animate transforms, not opacity. Ask organisers about Dawn access.

## Source ledger
### KEEP
- [1] isl-org/gsplat Intel_XPU.md, https://raw.githubusercontent.com/isl-org/gsplat/sycl_code_integration/docs/Intel_XPU.md
- [2] Dawn PVC user guide, https://docs.hpc.cam.ac.uk/hpc/user-guide/pvc.html
- [3] Intel oneAPI Hackfest at DiRAC, https://community.intel.com/t5/Blogs/Tech-Innovation/Tools/Intel-Hosted-oneAPI-Hackfest-at-DiRAC-HPC-Research-Facility/post/1630543
- [4] Dawn ML jobs, https://docs.hpc.cam.ac.uk/user-guide/pvc-jobs-ML.html (likely stale)
- [5] Brush, https://github.com/ArthurBrussee/brush
- [6] GLOMAP, arXiv 2407.20219, https://arxiv.org/abs/2407.20219
- [7] COLMAP FAQ, https://colmap.github.io/faq.html
- [8] Scaniverse, App Store, https://apps.apple.com/us/app/-/id1541433223
- [9] Spark SplatMesh docs, https://sparkjs.dev/docs/splat-mesh/
- [11] Spark splat editing docs, https://sparkjs.dev/docs/splat-editing/
- [12] Spark PackedSplats docs, https://sparkjs.dev/docs/packed-splats/
- [13] GaussianSplatComponent, Apple, https://developer.apple.com/documentation/realitykit/gaussiansplatcomponent.md
- [14] Rendering Gaussian splats with RealityKit, Apple, https://developer.apple.com/documentation/visionos/rendering-gaussian-splats-with-realitykit.md
- [18] Apple Developer Forums 842819, https://developer.apple.com/forums/thread/842819 : opacity fade bug, Apple-confirmed.
### WEAK
- [10] isl-org/gsplat PR 1 (mirror), https://gh.r-mj.com/isl-org/gsplat/pull/1
- [15] Apple Developer Forums 842737 : no native SPZ.
- [16] Apple Developer Forums 831663, https://developer.apple.com/forums/thread/831663 : ~200k limit, no runtime buffer mutation.
- [17] Apple Developer Forums 838974, https://developer.apple.com/forums/thread/838974 : 400k on iPhone 16 Pro, AR mode.
- GLOMAP matching bottleneck on CPU, arXiv 2603.20428, https://arxiv.org/pdf/2603.20428
- Scaniverse paid tiers, polyvia3d.pages.dev, https://polyvia3d.pages.dev/guides/gaussian-splatting-mobile-capture
- Spark v2.3.0 writeSpz, radiancefields.com, https://radiancefields.com/spark-v2.3.0-fixes-on-demand-rendering-for-paged-lod
### DO NOT USE
- Dawn's IPEX conda env as the gsplat base ([4]): superseded by upstream PyTorch XPU wheels per [1]. Tombstone.

# § 5 Add-ons to § 2 and § 3: marker under world tracking, ARKit holding the camera (2026-11-14)
**Question:** the same two as § 2 and § 3, asked separately by Ahmed's agent in the same hour. Only the points those
sections don't already make are kept here. Read § 2 and § 3 first.

**How this pass was done:** about 15 minutes, web search only. Sources were read through search summaries, **not
opened page by page**. Treat each line as a pointer to check on a real phone.

## Findings
### Alignment (adds to § 3)
- Use world tracking with `detectionImages`, not image-only tracking. Image-only tracking has no world tracking and
  needs the image fully visible; under world tracking, content stays anchored when the image leaves the frame
  (sources: [1], [2], [3]).
- A detected image keeps getting pose updates under world tracking, described as infrequent (source: [4]).
- One image anchor is precise near itself and pose error grows with distance from it (source: [5]). So the marker
  goes right next to the parts being worked on.
- An unconfirmed report says world tracking drifts on LiDAR iPhones on iOS 26.4 and later (source: [6]). Our demo
  phone is said to be non-LiDAR; check its iOS version if drift shows up.
### Live camera (adds to § 2)
- Why a custom capturer is needed at all: ARKit starts and holds the camera's capture session, so WebRTC's standard
  `RTCCameraVideoCapturer` stops working while AR runs (sources: [7], [8]).
- One write-up of the full chain, `CVPixelBuffer` to `RTCCVPixelBuffer` to `RTCVideoFrame` (source: [9]).

## Community consensus
Apple Developer Forums and the discuss-webrtc list only, each a thread with few replies. No Reddit or Hacker News
pass.

## Final call (professional + community)
Agrees with § 3: a printed marker, as a detection image **under world tracking**, placed next to the ports. Agrees
with § 2 that WebRTC needs a custom source and that snapshots over the websocket are the low-effort path. The team's
standing decision is still WebRTC from the start (`PROJECT.md` → Decision log); § 2 and this section are the case
for reopening it.

## Source ledger
### KEEP
- [1] ARImageTrackingConfiguration, Apple Developer Documentation,
  https://developer.apple.com/documentation/arkit/arimagetrackingconfiguration : image-only tracking has no world tracking.
- [2] ARWorldTrackingConfiguration, Apple Developer Documentation,
  https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration : world tracking can detect images.
- [3] "How can I increase the image tracking accuracy?", Apple Developer Forums,
  https://developer.apple.com/forums/thread/685469 : content stays anchored when the image leaves view.
- [7] discuss-webrtc thread, https://groups.google.com/g/discuss-webrtc/c/WpVhJ1lRrRE : ARKit holds the capture session.
- [8] rn-webrtc-arkit-integration (open source),
  https://awesome.ecosyste.ms/projects/github.com%2Fjhen0409%2Frn-webrtc-arkit-integration : built to work round [7].
### WEAK
- [4] "Do detected images track motion by default in iOS 12?", Apple Developer Forums,
  https://developer.apple.com/forums/thread/110844 : one thread, about iOS 12.
- [5] "Real world anchors", Apple Developer Forums, https://origin-devforums.apple.com/forums/thread/820424 : one
  reply; the only basis for "error grows with distance".
- [6] "ARKit World Tracking Drift Regression on LiDAR-Equipped Devices - iOS 26.4+", Apple Developer Forums,
  https://developer.apple.com/forums/thread/827240 : one developer's report, not confirmed by Apple.
- [9] "iOS ARKit推流到WebRTC", CSDN blog (2018), https://blog.csdn.net/sonysuqin/article/details/82788424 : a
  blog, and old.
### DO NOT USE
- _(none)_

# § 6 Which frame guide positions travel in: the marker's or the splat's (2026-11-14)
**Question:** should a guide's positions travel in the printed marker's own frame (metres, the dashboard converts
from the splat), or in splat coordinates plus the marker's corners (the phone converts)? Shapes
`contracts/protocol.ts`.

**How this pass was done:** about 10 minutes by Ahmed's agent. The three Apple pages were **opened and read in
full**. The rest were read through search summaries only.

## Findings
### What ARKit gives the phone
- An image anchor sits at the image's centre, and ARKit treats the image as **horizontal in the anchor's local
  space**: it lies in the X–Z plane, with Y as its normal. Apple's sample rotates a vertical plane by -90° about X to
  match (source: [1]). Salman's overlay code already assumes the same.
- Which way +X and +Z point across the printed image is **not stated** by Apple, and one developer reports the axes
  weren't what they expected (sources: [1], [7]). Check on the device with an axis marker.
- With `maximumNumberOfTrackedImages` above zero, ARKit checks the image every frame and updates the anchor if it
  moves. At zero, updates come only "once every couple of seconds" (source: [2]).
- Distance and scale come from the printed size you give ARKit: "Entering an incorrect physical size will result in
  an ARImageAnchor that's the wrong distance from the camera" (sources: [1], [3]).
### Authoring content in the marker's frame is the normal pattern
- Apple: "Use detected images to set a frame of reference for the AR scene", and `setWorldOrigin(relativeTransform:)`
  can make the detected image the world origin (source: [1]).
- Vuforia's default pose "places content in the center of the target with X to the right, Y to the top, and Z coming
  out of the target": content is placed relative to the target (source: [4]). Its axes differ from ARKit's, so the
  axis convention has to be written down, never assumed.
- RealityKit developers parent content to the image's anchor entity and position it relative to it (source: [8]).
### Converting splat coordinates to the marker's frame
- Matching points between two frames with scale, rotation and translation is Umeyama's least-squares method, which
  also avoids returning a mirror image instead of a rotation (sources: [5], [6]).
- **Our own reasoning, not from a source:** with four corners of a rectangle of known size, the frame can also be
  built directly: origin at their centre, two edge directions as axes, scale from the edge lengths. Either way it's a
  few dozen lines, and **the maths is identical wherever it runs**. The real question is which side runs it.
- Splat files don't share one axis convention: SPZ is reported as right-up-back and PLY as right-down-forward
  (source: [9]). In both designs the dashboard must load the splat consistently.

## Community consensus
Apple Developer Forums and Stack Overflow only. They agree on parenting content to the image anchor, and that the
axes need checking on a device. No Reddit or Hacker News pass.

## Final call (professional + community)
Placing content relative to the detected image is the platform pattern (Apple, Vuforia). Research doesn't pick which
side converts from splat coordinates: that's an engineering choice for Ahmed (`PROJECT.md` → Pending). Both designs
need two things checked on the phone: which way the anchor's axes point across the printed image, and the exact
printed width.

## Source ledger
### KEEP
- [1] "Detecting Images in an AR Experience", Apple Developer Documentation (sample code article),
  https://developer.apple.com/documentation/arkit/detecting-images-in-an-ar-experience : image horizontal in the
  anchor's space; use detected images as a frame of reference; `setWorldOrigin`; exact physical size.
- [2] `maximumNumberOfTrackedImages`, Apple Developer Documentation,
  https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration/maximumnumberoftrackedimages : nonzero
  means per-frame updates; zero means every couple of seconds.
- [3] `ARImageAnchor`, Apple Developer Documentation, https://developer.apple.com/documentation/arkit/arimageanchor :
  the extent comes from `transform` plus `physicalSize`.
- [4] "Working with Vuforia Engine and OpenGL ES", Vuforia library,
  https://library-archive.vuforia.com/articles/Solution/Working-with-Vuforia-and-OpenGL-ES.html : content placed at
  the target's centre, in the target's frame.
- [5] S. Umeyama, "Least-squares estimation of transformation parameters between two point patterns", IEEE TPAMI
  13(4), 376–380, 1991, DOI 10.1109/34.88573 : similarity transform, reflection-safe.
- [6] Eigen `Umeyama.h`, https://git.mfoi.dev/ocean-simulation.git/tree/Eigen/src/Geometry/Umeyama.h : an
  implementation of [5], with scaling optional.
### WEAK
- [7] "About AR Anchor's Orientation", Apple Developer Forums, https://developer.apple.com/forums/thread/718223 :
  one developer surprised by the axes.
- [8] "How do I specify a child node location relative to ARImageAnchor", Stack Overflow (mirror),
  https://kaweah.freedombox.rocks/kiwix/stackoverflow.com_en_all_2023-11/questions/71241779/how-do-i-specify-a-child-node-location-relative-to-arimageanchor
  : the parent and child pattern.
- [9] SPZ format notes, https://polyvia3d.pages.dev/formats/spz and PlayCanvas,
  https://developer.playcanvas.com/user-manual/gaussian-splatting/formats/spz/ : SPZ and PLY axis conventions differ.
  Third-party, not Scaniverse's own docs.
### DO NOT USE
- "Image anchors are not tracked after initial detection" and "ARKit doesn't track changes to the position or
  orientation of each detected image", from the iOS 11.3-era sample [1]. Refuted for iOS 12 and later by Apple's own
  [2] when `maximumNumberOfTrackedImages` is above zero. Tombstone, so it isn't re-litigated.

# § 7 Splat renderer for the dashboard: Spark vs PlayCanvas vs the rest (2026-11-14)
**Question:** which library should draw the Scaniverse splat in the expert dashboard, given what Max's tasks need:
orbit, click-picking, glTF models in the same scene, and cut-outs (lifting a box of splats out as its own object)?
Builds on § 4. Asked by Max because "PlayCanvas has the best splat tooling" was said without a source.

**How this pass was done:** about 20 minutes by Max's agent. Versions are from the npm registry and GitHub on
2026-11-14. Spark 2.4.0's and playcanvas 2.24.1's type definitions were read from their npm tarballs. Reddit and HN
had no head-to-head thread.

## Findings
### Versions and upkeep
- Spark (`@sparkjsdev/spark`) 2.4.0, 2026-10-20, MIT, releases every few weeks (sources: [1], [2]).
- PlayCanvas engine 2.24.1, 2026-11-12, MIT, releases every week or two, mostly splat work lately. SuperSplat
  3.8.1. `@playcanvas/react` is still 0.x (sources: [1], [12], [19]).
- GaussianSplats3D is **no longer developed**; its README points to Spark. Last release 0.4.7, Jan 2025 (sources:
  [21], [1]).
- three.js r186 merged its own splat renderer (TSL, WebGPU/WebGL) with raycasting in Aug 2026. Three months old, in
  `examples/jsm`, no CPU editing API found (sources: [23], [22]).
- Babylon.js 9.36 loads .ply/.splat/.spz/.sog and has `GaussianSplattingMesh.intersects` (sources: [24], [25]).
### Formats
- Both Scaniverse exports (.ply, .spz) load in Spark and PlayCanvas. Spark reads SPZ v4 since 2.4.0; PlayCanvas
  needs a hand-registered SPZ parser (sources: [2], [3], [13]).
### Speed
- Spark: WebGL2 only (WebGPU support is an open issue). GPU distances, CPU radix sort in a worker; all splat
  objects sorted together, so several blend correctly. In-browser level-of-detail (sources: [4], [6], [10]).
- Against Spark: one user found it slower than GaussianSplats3D on a 19M-splat file, with sort lag on fast orbits
  [8]. Firefox at 0.3 fps vs Chrome at 40–50 fps, likely the integrated GPU [9]. **Demo in Chrome.**
- PlayCanvas: CPU sort on WebGL2, GPU sort on WebGPU (sources: [12], [13]). "3–4× faster" is one forum anecdote
  [18]. No independent benchmark either way.
### Cut-outs
- Spark 2.4.0: `forEachSplat` to collect indices, `PackedSplats.extractSplats(indices)` (in the types, undocumented)
  into a new `SplatMesh`; hide the source region with a SplatEdit (sources: [5], [3], § 4 [11]). The cut-out loses
  view-dependent colour (no spherical harmonics copied) [5]. Editing packed data re-uploads the whole buffer: fine
  once, not per frame [3].
- PlayCanvas: `GSplatData.getProp` / `getCenters` / `calcAabb`; a subset means building new `GSplatData` and a
  `GSplatResource`. Docs thin (sources: [13], [16], [17]).
- Offline fallback for either: SuperSplat's "Separate selection" plus export [19].
### Picking
- Spark: `SplatMesh` works with three's `Raycaster` (WASM ray–ellipsoid test per splat, opacity cut-off 0.2).
  About 350 ms per pick on a multi-million-splat file with level-of-detail off; about 7 ms with it on but imprecise
  (sources: [3], [5], [7]). Open bugs: rays still hit splats a SplatEdit hid or moved [11].
- PlayCanvas: `Picker.getWorldPointAsync` via GPU depth, since Nov 2025; gives a point, not a splat index
  (sources: [14], [15]).
### Mixing with glTF
- `SplatMesh` is a `THREE.Object3D`, drawn in the normal render call, so GLTFLoader, TransformControls and helpers
  work as usual (sources: [3], [4]). PlayCanvas loads glb natively [15].

## Community consensus
No head-to-head thread found. Where sources agree: Spark is the three.js default (even GaussianSplats3D's author
says so); PlayCanvas/SuperSplat leads on WebGPU speed and the offline editor. "PlayCanvas has the best splat
tooling" holds for the SuperSplat editor, not for cutting parts out from code, where Spark's API is plainer.

## Final call (professional + community)
Spark 2.4.0 on three.js covers every dashboard task with documented or typed APIs. Pick on click only,
level-of-detail off for the room splat, demo in Chrome; cut-outs lose view-dependent colour. A full two-library
bake-off isn't worth it: run a 60–90 min Spark spike with a kill criterion (orbit at 30 fps or more on the weakest
laptop, a pick under 300 ms, a cut-out under 2 s that looks right), and give PlayCanvas the same test only if the
frame rate fails.

## Source ledger
### KEEP
- [1] npm registry entries for each package, fetched 2026-11-14, https://www.npmjs.com/package/@sparkjsdev/spark
- [2] Spark v2.4.0 release notes, GitHub, 2026-10-20, https://github.com/sparkjsdev/spark/releases/tag/v2.4.0
- [3] Spark SplatMesh docs, https://sparkjs.dev/docs/splat-mesh/
- [4] Spark overview, https://sparkjs.dev/docs/overview/
- [5] Spark 2.4.0 type definitions (`PackedSplats.extractSplats`, `raycast`), npm tarball
- [6] "Spark 2.0", World Labs blog, 2026-04-14, https://www.worldlabs.ai/blog/spark-2.0
- [7] Spark issue #468, raycast precision, 2026-10, https://github.com/sparkjsdev/spark/issues/468
- [8] Spark issue #225, slower than GaussianSplats3D, 2025-11, https://github.com/sparkjsdev/spark/issues/225
- [9] Spark issue #190, Firefox performance, 2025-10, https://github.com/sparkjsdev/spark/issues/190
- [11] Spark issues #497 / #498, raycast hits hidden splats, 2026-11-12, https://github.com/sparkjsdev/spark/issues/497
- [12] PlayCanvas engine v2.24.0 release notes, 2026-11-09, https://github.com/playcanvas/engine/releases/tag/v2.24.0
- [13] playcanvas 2.24.1 type definitions (GSplatData, Picker, renderers), npm tarball
- [14] PlayCanvas PR #8154, splat world-point picking, 2025-11-21, https://github.com/playcanvas/engine/pull/8154
- [15] PlayCanvas splat examples, https://github.com/playcanvas/engine/tree/main/examples/src/examples/gaussian-splatting
- [19] SuperSplat repo and v3.8.x releases, https://github.com/playcanvas/supersplat
- [21] GaussianSplats3D README, https://github.com/mkkellogg/GaussianSplats3D
- [23] three.js PRs #33950 and #34284, Aug 2026, https://github.com/mrdoob/three.js/pull/33950
- [24] @babylonjs/core 9.36.0 type definitions, https://www.npmjs.com/package/@babylonjs/core
### WEAK
- [10] Spark issue #394, WebGPURenderer support (title only), https://github.com/sparkjsdev/spark/issues/394
- [16] PlayCanvas unified splat rendering guide (search summary only), https://developer.playcanvas.com/user-manual/gaussian-splatting/building/unified-rendering
- [17] PlayCanvas forum, programmatic splat data, https://forum.playcanvas.com/t/programmatic-access-to-splat-data/41492
- [18] PlayCanvas forum, "3–4× FPS" (one user), https://forum.playcanvas.com/t/gaussian-splatting-playcanvas/33503?page=4
- [20] radiancefields.com, SuperSplat 3.0 WebGPU-only, 2026-09, https://radiancefields.com/playcanvas-releases-supersplat-3.0
- [22] radiancefields.com, three.js r186 splats, https://radiancefields.com/three.js-ships-its-native-gaussian-splat-renderer-and-splat-raycasting-in-r186
- [25] radiancefields.com, Babylon.js 9 splats, https://radiancefields.com/babylon.js-v9.0-3dgs-gets-shadows-sogs-and-triangle-splatting-support-announced
- [26] gsplat.js, last release July 2025, https://github.com/huggingface/gsplat.js
- [28] SplatBus, arXiv 2601.15431 (not opened), https://arxiv.org/abs/2601.15431
### DO NOT USE
- PlayCanvas forum "How to raycast on a Gaussian splat mesh?" saying it can't be done: superseded by [14].
  https://forum.playcanvas.com/t/how-to-raycast-on-gaussian-splat-mesh/40637
- "Spark's latest is v2.3.0" (stale search result): 2.4.0 shipped [1], [2].
- "AMD to acquire World Labs": one unverified site. Don't cite.

# § 8 Dashboard shell: build tool, UI layer, R3F or not, scene-UI state (2026-11-14)
**Question:** what should `dashboard/` be built with? It's a big 3D viewport (Max) plus a lot of editor UI (Laura:
timeline, pickers, forms, sortable steps, search, live status), split by `dashboard/src/scene/api.ts`. Max asked
for the best fit, not the easiest.

**How this pass was done:** about 20 minutes by Max's agent. Versions from the npm registry on 2026-11-14. Reddit
read through a mirror only.

## Findings
### Build tool
- Vite 8 (stable since 2026-03-12, Rolldown bundler, Node 20.19+ / 22.12+) (sources: [1], [2]).
- Spark loads its WASM via `new URL(..., import.meta.url)`, which breaks under Webpack/Next.js: issue #97 is open
  and Spark's own R3F example warns about it (sources: [3], [4]). Rules out Next.js.
- Rsbuild's own table has Vite faster on build and HMR, Rsbuild faster on cold start only [5].
### UI layer
- Real 3D editors keep the engine imperative and the UI in a separate layer: SuperSplat (plain TS + PCUI), the
  three.js editor (vanilla DOM), the PlayCanvas editor (PCUI, now React-based) (sources: [6], [7], [8]).
- React has the deepest editor-UI ecosystem (drag-and-drop, headless components); Svelte 5 and Solid are thinner
  (sources: [1], [9]).
- Hot-path updates go through refs and mutation in the frame loop, never component state (sources: [10], [11]).
### R3F or plain three.js
- Spark supports R3F officially (on-demand rendering docs, a StrictMode fix in Oct 2026) (sources: [12], [13]).
- But: R3F pointer events on a `SplatMesh` raycast every splat on every move, about 100% CPU (#75, open); multiple
  canvases break (#98, #107); a maintainer isn't familiar with R3F (#173) [13]. The standalone R3F example repo is
  stale (Spark 0.1.x) [4].
- An editor-tool write-up moved its hot path to vanilla three.js and kept React for panels [11].
### State between scene and UI
- A framework-agnostic store both sides import, e.g. zustand's vanilla `createStore`: React reads it with
  `useStore`, the scene with `subscribe`/`getState()` [10]. Keep camera pose and per-frame data out of React state.

## Community consensus
Vite is the default for a client-only app; nobody credible says otherwise. R3F vs vanilla is split, leaning R3F for
React teams ([14], [15]), but people building editors end up hybrid with imperative hot paths [11]. Spark's open R3F
issues tip this app toward vanilla behind an API.

## Final call (professional + community)
Vite 8 + React 19 + TypeScript. Plain three.js and Spark live in `dashboard/src/scene/`, mounted once by one
component, behind `scene/api.ts`; no R3F. A zustand vanilla store for shared state. No Next.js (Spark's WASM breaks
under Webpack).

## Source ledger
### KEEP
- [1] npm registry metadata, fetched 2026-11-14, https://registry.npmjs.org/
- [2] "Vite 8.0 is out", vite.dev, 2026-03-12, https://vite.dev/blog/announcing-vite8
- [3] Spark issue #97, Next.js/Webpack, open, https://github.com/sparkjsdev/spark/issues/97
- [4] spark-react-r3f README, https://github.com/sparkjsdev/spark-react-r3f (Webpack caveat; stale as a version reference)
- [5] Rsbuild quick start and comparison, https://rsbuild.rs/guide/start/
- [6] SuperSplat package.json, https://github.com/playcanvas/supersplat
- [7] three.js editor `ui.js`, https://github.com/mrdoob/three.js/blob/dev/editor/js/libs/ui.js
- [8] PlayCanvas editor and PCUI, https://github.com/playcanvas/editor, https://github.com/playcanvas/pcui
- [10] R3F performance pitfalls, https://r3f.docs.pmnd.rs/advanced/pitfalls
- [12] Spark on-demand rendering (R3F section), https://sparkjs.dev/docs/on-demand-rendering/
- [13] Spark issues #75, #98, #107, #173 and PR #478, https://github.com/sparkjsdev/spark/issues/75
### WEAK
- [9] State of JS 2025, front-end frameworks (qualitative only), https://2025.stateofjs.com/en-US/libraries/front-end-frameworks/
- [11] "Building a browser-based 3D modeling tool with Three.js", dev.to, about 2026, https://dev.to/ericwoooo_kr/building-a-browser-based-3d-modeling-tool-with-threejs-what-the-docs-dont-tell-you-320h
- [14] "ThreeJS or R3F", three.js forum, 2023, https://discourse.threejs.org/t/threejs-or-r3f-technology-pick/57973
- [15] r/threejs "Using React with vanilla three.js" (mirror), https://lr.eu.psf.lt/r/threejs/comments/1frhrp5/using_react_with_vanilla_threejs
### DO NOT USE
- "Theatre.js studio is React": from memory, not verified.
- "React gets the best AI-written code": no source found.

# § 9 Training our own splat on the DGX Spark (2026-11-14)
**Question:** the team has an NVIDIA DGX Spark (GB10, ARM64, 128 GB unified memory), not Dawn. Can we train a
better splat than Scaniverse's on it within a few hours of setup, and how? Builds on § 4. Not to be confused with
Spark the splat library (§ 7).

**How this pass was done:** about 15 minutes by Max's agent. Reddit was unreachable; community view from GitHub
issues and blogs only.

## Findings
### Trainers that run on GB10
- gsplat + nerfstudio splatfacto: one full phone-video-to-splat run on a DGX Spark (CUDA 13.0, torch 2.9.0 cu130,
  gsplat 1.5.3 compiled on first use with `TORCH_CUDA_ARCH_LIST="12.0"`, nerfstudio installed `--no-deps`,
  `numpy<2`, open3d imports stubbed) [1]. Packaging matches: no aarch64 gsplat wheels, aarch64 cu130 torch wheels
  exist (sources: [2], [3], [4]). A torch/CUDA mismatch on aarch64 fails silently [5].
- LichtFeld Studio (C++/CUDA, GPLv3) starts on GB10 (SM 12.1) [6]; headless CLI, exports PLY/SPZ/SOG
  (sources: [7], [8]). Build time on ARM unknown.
- Brush, OpenSplat: no GB10 reports (sources: [9], [11]). Postshot is Windows-only [12]. NVIDIA's DGX Spark
  playbooks don't cover splats [14].
### Camera poses
- apt COLMAP works on CPU only; GPU SIFT crashed headless [1]. Distro packages have no CUDA [15]. pycolmap has no
  aarch64 wheel [16].
- Record one continuous slow video; two clips split COLMAP into separate models [1].
- nerfstudio's ARKit-pose importers need a LiDAR iPhone [17].
### Capture and training time
- 200–500+ images for a room; 70–80% overlap; locked exposure and white balance; fast shutter [18].
- On the Spark: 115 of 232 frames registered; full 1080p 30k steps about 45 min; half resolution 15k steps about
  5 min [1]. For 200–300 frames, expect roughly 45–90 min at 1080p (our extrapolation, not measured).
- splatfacto holds images back for evaluation by default; train on all with
  `--eval-mode fraction --train-split-fraction 1` [20].
### Into the dashboard
- `ns-export gaussian-splat` for the full PLY, then PlayCanvas `splat-transform` to `.spz` (crop, floater removal)
  (sources: [1], [21]). SPZ is about 10× smaller than PLY [22].
### Better than Scaniverse?
- No head-to-head found. Desktop training is generally sharper given more images and time (sources: [13], [20]).
  Pose quality, not the trainer, is the usual limit [20].

## Community consensus
Scaniverse is the fast, easy route; desktop training is the quality route, and only wins with a clean capture.
Only one first-hand DGX Spark splat report exists [1]; [6] corroborates that GB10 runs splat training in general.

## Final call (professional + community)
Keep Scaniverse as the baseline. As an upgrade: one slow 4K video, 200–300 sharp frames, apt COLMAP on CPU,
gsplat/splatfacto on the Spark at half resolution first, `ns-export`, then `splat-transform` to `.spz`. Budget
1–2 h setup plus 15–60 min training. Risks: dependency friction, COLMAP registering half the frames, one source.
Never claim "trained on our DGX Spark" unless the splat on screen was.

## Source ledger
### KEEP
- [1] "I tried making a 3D digital twin of DGX Spark from smartphone videos", Classmethod, 2026-03-28, https://dev.classmethod.jp/en/articles/dgx-spark-3dgs-digital-twin/
- [2] gsplat on PyPI (1.5.3, pure-Python wheel), https://pypi.org/pypi/gsplat/json
- [3] gsplat wheel index (no aarch64), https://docs.gsplat.studio/whl/gsplat/
- [4] PyTorch cu130 wheel index (aarch64 torch 2.9.0–2.14.1), https://download.pytorch.org/whl/cu130/torch/
- [5] gsplat issue #595, missing `gsplat_cuda.so` on aarch64, 2025-03, https://github.com/nerfstudio-project/gsplat/issues/595
- [6] LichtFeld Studio issue #1054 (GB10 log), 2026-03-29, https://github.com/MrNeRF/LichtFeld-Studio/issues/1054
- [7] LichtFeld build docs, https://github.com/MrNeRF/LichtFeld-Studio/blob/master/docs/building_and_distribution.md
- [8] LichtFeld Studio README, https://github.com/MrNeRF/LichtFeld-Studio
- [14] DGX Spark playbooks index, https://build.nvidia.com/spark
- [15] COLMAP install docs, https://colmap.github.io/install.html
- [16] pycolmap 4.2.1 on PyPI (no aarch64 wheel), https://pypi.org/pypi/pycolmap/json
- [17] nerfstudio "Using custom data", https://docs.nerf.studio/quickstart/custom_dataset.html
- [18] PlayCanvas "Taking photos", https://developer.playcanvas.com/user-manual/gaussian-splatting/creating/taking-photos/
- [19] gsplat evaluation page, https://docs.gsplat.studio/main/tests/eval.html
- [21] playcanvas/splat-transform README, https://github.com/playcanvas/splat-transform
- [22] Niantic SPZ 4 blog, 2026, https://www.nianticspatial.com/blog/spz4
### WEAK
- [9] Brush README, https://github.com/ArthurBrussee/brush
- [10] radiancefields.com, SculptForge (Brush has no Linux ARM binaries), https://radiancefields.com/sculptforge-trains-gaussian-splats-from-phone-video
- [11] OpenSplat README, https://github.com/pierotofy/OpenSplat/blob/main/README.md
- [12] Postshot release notes (search snippet), https://www.jawset.com/docs/d/Postshot+User+Guide/Release+Notes/v0.1.24
- [13] realhorizons.ai, 17 splat tools compared (no measurements), https://realhorizons.ai/blog/gaussian-splatting-software/
- [20] nerfstudio issue #3421, Postshot vs splatfacto, about 2024, https://github.com/nerfstudio-project/nerfstudio/issues/3421
- [23] Scaniverse App Store listing (marketing), https://apps.apple.com/us/app/scaniverse-lidar-3d-scanner/id1541433223
### DO NOT USE
- [24] polyvia3d guides: unsourced PSNR figures (Scaniverse 25.2 dB, photo vs video 28.4 vs 26.8 dB). Keep these
  numbers out of the pitch. https://polyvia3d.pages.dev/guides/gaussian-splatting-tools-comparison

# § 10 The UNO Q rig: Nicla Vision → UNO Q → relay (2026-11-14)
**Question:** for the RS hardware check, where should "which port is the cable in" be worked out, how does the
Nicla Vision talk to the UNO Q, and how does the UNO Q's verdict reach our relay?

**How this pass was done:** about 15 minutes by Ahmed's agent. One forum thread and one blog post were opened and
read in full ([6], [2]); the rest were read through search summaries. Arduino's official UNO Q user manual didn't
load, so UNO Q facts come from third-party guides that agree with each other.

## Findings
### The UNO Q
- One USB-C port. It switches to host mode for a hub, but **the hub needs its own Power Delivery supply**: the UNO Q
  doesn't power the hub. If the board is powered through VIN or 5V the port may not switch to host mode (sources:
  [1], [11]).
- Dual-band Wi-Fi 5 and Bluetooth 5.1; Debian 13 on the Linux side (sources: [1], [11]).
- Python apps in App Lab run in a container; extra packages go in a `requirements.txt` beside `main.py`, and
  packages installed by hand over SSH aren't seen by the app (sources: [7], [8]).
- Python talks to the sketch through the Bridge: `Bridge.call`, `Bridge.notify` and `Bridge.provide`, both ways
  (source: [2]). Header pins are 3.3 V maximum (source: [2]).
- **Can an App Lab app open a USB serial device on the hub? Reports conflict.** Two users found the container
  couldn't see it; one confirmed reading a Teensy on the hub from App Lab Python with plain PySerial (July 2026);
  plain Python run over SSH, outside App Lab, can open it (sources: [6], [9]). No Arduino staff answer. **Test on
  our board before building on it.**
### The Nicla Vision
- OpenMV finds coloured blobs with `find_blobs`, limited to a region of interest (`roi`); Arduino's Nicla tutorial
  uses the Threshold Editor to pick the colour (sources: [3], [4]).
- An OpenMV script's printed output can be read over USB serial by a host with pyserial, with DTR disabled or the
  camera suppresses its output (source: [5]). OpenMV's maintainer calls the RPC library "a little finicky" over USB
  (source: [10]), so plain printed lines are the safer protocol.
- Its UART pins differ by firmware version, and no source confirms their logic level; its analog pins A0–A2 are
  1.8 V only and 3.3 V damages them (source: [12]). Wiring a UART to the UNO Q is the riskiest link.
### Reaching the relay
- `websocket-client` 1.9.2 on PyPI has no runtime dependencies and needs Python 3.10 or later (source: [13]).

## Community consensus
Arduino forum and OpenMV forum only. Agreement: the UNO Q is a good USB host; App Lab's container is the friction
point for USB serial and for packages; the Nicla's UART is confusing across firmware. Contrasting view: one user
reads USB serial from App Lab fine. Nobody has published our exact chain. No Reddit or Hacker News pass.

## Final call (professional + community)
Do the vision on the Nicla (colour blobs, one region per port) and send one short line per change over USB through
the hub. The UNO Q reads it, decides right or wrong for the current step, reports `step.verified` to the relay over
Wi-Fi with `websocket-client`, and can show the result on its LED matrix through the Bridge. **First, a 5-minute
test:** can an App Lab app open the Nicla's serial port? If not, run the same Python outside App Lab over SSH.

## Source ledger
### KEEP
- [1] Arduino UNO Q, Waveshare docs, https://docs.waveshare.com/Arduino-UNO-Q-02016 : one USB-C port, host mode,
  hub power, Wi-Fi 5.
- [3] "Blob Detection with OpenMV", Arduino docs, https://docs.arduino.cc/tutorials/nicla-vision/blob-detection :
  `find_blobs` and the Threshold Editor on the Nicla Vision.
- [4] "Finding blobs", OpenMV docs, https://docs.openmv.io/openmvcam/tutorial/image/finding/blobs.html : `find_blobs`
  thresholds and `roi`.
- [11] "Arduino UNO Q: high-resolution pinout, datasheet, schema, and specifications", mischianti.org,
  https://mischianti.org/arduino-uno-q-high-resolution-pinout-datasheet-schema-and-specifications/ : agrees with [1].
- [13] websocket-client on PyPI, https://pypi.org/project/websocket-client/ : 1.9.2, no runtime dependencies.
### WEAK
- [2] "Arduino UNO Q Bridge: how Python and the STM32 sketch talk", mischianti.org, https://mischianti.org/?p=36047 :
  the Bridge API and 3.3 V headers. One third-party source; App Lab's own examples will confirm it on the board.
- [5] OpenMV firmware README, https://github.com/openmv/openmv : printed output over USB serial, DTR disabled.
  Vendor source, not cross-checked.
- [6] "Arduino Uno Q (App Lab) as a USB Host … Python environment sees 0 devices", Arduino forum,
  https://forum.arduino.cc/t/arduino-uno-q-app-lab-as-a-usb-host-to-an-uno-r3-python-environment-sees-0-devices/1433482
  : conflicting user reports on container access to USB serial; no staff answer.
- [7] "How to install Python Packages", Arduino forum, https://forum.arduino.cc/t/how-to-install-python-packages/1411276
  : `requirements.txt` beside `main.py`.
- [8] Answer Overflow thread, https://www.answeroverflow.com/m/1470236402661982278 : packages installed over SSH
  aren't seen by App Lab apps.
- [9] "UNO Q: Possible to connect Python (not containerized) with Arduino?", Arduino forum,
  https://forum.arduino.cc/t/uno-q-possible-to-connect-python-not-containerized-with-arduino/1436102 : Python outside
  App Lab can open `/dev/ttyACM0`; the bridge package comes as a wheel from Arduino's GitHub.
- [10] "Nicla vision stream video over USB", OpenMV forum, https://forums.openmv.io/t/nicla-vision-stream-video-over-usb/10334
  : RPC over USB is "a little finicky".
- [12] Arduino Nicla Vision quick reference, OpenMV docs,
  https://docs.openmv.io/openmvcam/quickref/arduino-nicla-vision.html, and UART threads on the Arduino and OpenMV
  forums : UART pins vary by firmware; A0–A2 are 1.8 V only.
### DO NOT USE
- Cirkit Designer's Nicla Vision pinout (TX and RX on pins 5 and 6 of a 16-pin connector): contradicts Arduino's own
  pinout and the OpenMV forum. Tombstone.


# § 11 Scanning on a non-LiDAR iPhone: Scaniverse vs the other apps (2026-11-14)
**Question:** is Scaniverse the best way to get a splat of the demo set on an iPhone 13 or 15 (no LiDAR), and what are
the alternatives? Builds on § 4 and § 9. Asked by Max.

**How this pass was done:** about 20 minutes by Max's agent. Reddit and Polycam's help centre refused automated
fetches; the community view is from radiancefields.com, trade press and PlayCanvas.

## Findings
### Scaniverse split in two (April 2026)
- **Scaniverse Classic:** trains the splat on the phone, free, unlimited, nothing uploaded, about 2 minutes (sources:
  [1], [2], [3], [4], [10]). **New Scaniverse:** cloud processing (map + mesh + splat) on monthly credits; free is
  about 10 minutes of scanning a month; results take "a few hours" (sources: [3], [5], [6]).
- Works without LiDAR since 2022; iOS 16.6+ and A12 or newer, so both our phones qualify; Niantic recommends iPhone 13
  or newer and says LiDAR gives the best results (sources: [1], [5], [8]).
- Exports SPZ and PLY splats; meshes (GLB, USDZ, FBX) come from mesh mode or the cloud, not from the splat (sources:
  [1], [7], [9]). Classic can also export the raw images [10].
- Whether exports are in metres is **not documented**; take scale from the 18 cm marker ([12], and § 4).
### The alternatives
- **Polycam:** cloud, minutes to an hour. A splat PLY needs the Basic plan, about $30/month (sources: [13], [15]).
- **KIRI Engine:** cloud, 7–20 min; splats are Pro only (€18/month); can also export a mesh (sources: [20], [21],
  [22]).
- **Luma AI:** capture app effectively unmaintained; the company moved to video generation (sources: [11], [17],
  [18]). Not a dependency for a 24-hour event.
- **Varjo Teleport:** room-scale, 30 min to 24 h in the cloud (sources: [25], [27]).
- **Apple Object Capture on the phone:** needs LiDAR. On a Mac it works from any photos, mesh only (sources: [31],
  [32]).
- **New in 2026, one source each:** Scantic (on-phone splats, paid full-quality export) [33]; SpAItial Echo-3 (cloud,
  claims metric scale without LiDAR) [34]; SplatKing (a capture app with manual camera controls) [35].
### Capture practice for small detail
- Photos beat video for sharpness; with video use 4K, 60 fps, locked exposure, ISO, white balance and focus, and
  shutter 1/125 s or faster (sources: [36], [38]).
- 3–4 rings at different heights, 70–80% overlap, extra close shots of fine detail, soft even light, one continuous
  take ([36], § 9 [1]). Glossy plastic and chrome cause false features [36].

## Community consensus
Scaniverse is the free, fast default; Polycam is picked for formats, KIRI for objects, both paid; desktop training is
the quality route with a clean capture. Capture technique matters more than which app. Contrasting: vendors claim
better cloud results (Echo-3, KIRI), with no measurements.

## Final call (professional + community)
Scaniverse Classic for the first splat (free, on-phone, about 2 min). For the sharpness needed to click 1 cm parts,
train the same capture on the DGX Spark (§ 12). Paid cloud apps only as a second opinion. Check scale against the
marker whatever the app.

## Source ledger
### KEEP
- [1] Scaniverse App Store listing, v5.2.9, Oct 2026, https://apps.apple.com/us/app/id1541433223
- [2] Niantic Spatial Scaniverse FAQ, 2026, https://www.nianticspatial.com/faq/scaniverse
- [3] "Niantic Spatial releases major Scaniverse update", radiancefields.com, 2026-04-07, https://radiancefields.com/niantic-releases-major-scaniverse-update
- [4] PlayCanvas "Recommended tools", https://developer.playcanvas.com/user-manual/gaussian-splatting/creating/recommended-tools/ (also [15])
- [5] Scaniverse FAQ (credits, devices), 2026, https://www.nianticspatial.com/faq/scaniverse
- [6] Scaniverse getting started, 2026, https://www.nianticspatial.com/capture/scaniverse-getting-started
- [8] Scaniverse release notes, https://www.nianticspatial.com/capture/scaniverse-release-notes
- [9] Niantic Spatial Capture product page, 2026, https://www.nianticspatial.com/products/capture
- [13] Polycam pricing, Nov 2026, https://poly.cam/pricing
- [20] "KIRI Engine Basic vs Pro", kiriengine.app, 2026-06-04, https://www.kiriengine.app/blog/kiri-engine-basic-vs-pro
- [22] KIRI 3DGS feature page, https://www.kiriengine.app/features/3d-gaussian-splatting
- [25] Teleport help (plans, PLY export), https://teleport.varjo.com/help/authors/1931641
- [27] Teleport uploading and processing, https://teleport.varjo.com/help/en_US/-uploading-processing-
- [31] Apple "Creating 3D objects from photographs", https://developer.apple.com/documentation/realitykit/creating-3d-objects-from-photographs.md
- [32] Apple Developer Forums 732317 / 775564, https://developer.apple.com/forums/thread/732317
- [36] PlayCanvas "Taking photos" (§ 9 [18]), https://developer.playcanvas.com/user-manual/gaussian-splatting/creating/taking-photos/
### WEAK
- [7] Same story as [3], cloud export formats
- [10] "Scaniverse introduces Gaussian splatting", radiancefields.com, 2024-03-22, https://radiancefields.com/scaniverse-introduces-gaussian-splatting
- [11] "Luma AI alternatives", radiancefields.com, 2026-07, https://radiancefields.com/luma-ai-alternatives
- [12] SketchUp splat best practices (arbitrary scale), https://help.sketchup.com/en/gaussian-splats-best-practices
- [16] Polycam "Create splats from images and video" (snippet only), https://learn.poly.cam/hc/en-us/articles/30549121659412
- [17] Luma capture app listing, v1.3.14, Jan 2026 (search summary), https://apps.apple.com/FR/app/id1615849914
- [18] "Luma AI review 2026", fast.io (snippet), https://fast.io/resources/luma-ai-review-2026/
- [21] KIRI Engine 4.0, digitalproduction.com, 2025-09-13 (snippet), https://digitalproduction.com/2025/09/13/faster-wider-cleaner-kiri-engine-4-0-drops-mobile-scan-limits/
- [33] Scantic, CG Channel, 2026-08-19, https://www.cgchannel.com/2026/08/scantic-trains-gaussian-splats-entirely-on-your-phone/
- [34] SpAItial Echo-3, radiancefields.com, 2026-10-27 (vendor claims), https://radiancefields.com/spaitial-echo-3-turns-iphone-scans-into-3d-worlds
- [35] SplatKing 1.0.2, radiancefields.com (its maker), 2026-06-06, https://radiancefields.com/splatking-1.0.2-native-colmap-export-from-lidar-a-redesigned-capture-interface-and-expanded-manual-controls
- [38] MacRumors iPhone video tips (AE/AF lock, lock camera), https://www.macrumors.com/guide/better-video-with-your-iphone/
### DO NOT USE
- polyvia3d guides: "all four apps process in the cloud" is refuted by [2], [4], [9] (already DO NOT USE in § 9).
- Teleport FAQ "we do not support export": superseded by [25].
- Older third-party Polycam prices: superseded by [13].

# § 12 Video to splat on our own hardware, including the new pose-free models (2026-11-14)
**Question:** how do we turn an iPhone video of the set into a splat sharp enough to click 1 cm parts, on the DGX
Spark or a laptop? Do the new "pose-free" models (VGGT and friends) make it faster or better? Builds on § 9.

**How this pass was done:** about 20 minutes by Max's agent. Reddit blocked; community view from Hacker News, the
PlayCanvas forum, GitHub and radiancefields.com.

## Findings
### Capture and frames
- Turn HDR video off: iPhone 4K is Dolby Vision HLG and plain ffmpeg frames come out washed out [39]. Lock exposure
  and focus; 4K at 60 fps for less blur (§ 9 [18]).
- Pull frames at 3–4 fps, keep the sharpest with `sharp-frames-python` (MIT) (sources: [26], [28]). RealityScan's
  video import doesn't reject blurry frames [36]. About 250–350 frames (our estimate).
- 1080p training is enough for 1 cm screws at 25 cm (our arithmetic: about 0.2 mm per pixel); blur and pose accuracy
  limit sharpness, not pixels.
### Camera positions (poses)
- COLMAP 4.x has GLOMAP built in (`global_mapper`) and newer features (sources: [1], [2]). CPU COLMAP is the known-good
  route on the Spark (§ 9).
### Trainers
- gsplat MCMC uses far fewer Gaussians for about the same quality on benchmarks [19]; defaults to override:
  `data_factor`, `save_ply`, `test_every` [17].
- Against "MCMC is sharper": a 2026 drone study had Postshot's trainer best and MCMC behind [20]; a forum user found
  Postshot better on fine detail [21]. Both weak for our case; compare on our set.
- Postshot's free plan can't export (sources: [24], [25]). Brush runs on any GPU but has no ARM build [23].
### Pose-free / feed-forward models
- VGGT, VGGT-X, MapAnything, Depth Anything 3 and π3 all have code and weights, several with COLMAP export (sources:
  [3]–[9]). They work at low resolution (518 px for VGGT) [3].
- They don't beat COLMAP on quality yet: VGGT-X's own numbers show a gap (26.4 vs 27.4–27.9 PSNR) [5]; Hacker News users
  report "decent" to "mediocre" on phone video [13]. AnySplat's "beats 3DGS" used VGGT poses as the baseline [12].
- No report of any of them on GB10.

## Community consensus
COLMAP plus sharp-frame filtering is still the quality route; learned methods are faster and more robust on hard
captures. Pose accuracy and blur limit sharpness more than the trainer. Contrasting: the methods' own authors claim
parity, on benchmark data rather than phone video.

## Final call (professional + community)
SDR 4K video → about 300 sharp frames → CPU COLMAP 4.x → gsplat at 1080p, 30k steps, on the Spark (about 1.5–2 h after
setup) → splat-transform to .spz/.sog. If COLMAP registers too few frames, VGGT or MapAnything poses into the same
step. If the Spark setup fails, Brush on a laptop. Last resort: the Scaniverse splat. Never say "pose-free" or
"trained on the Spark" unless the splat on screen was.

## Source ledger
### KEEP
- [1] COLMAP 4.1.0, radiancefields.com, 2026, https://radiancefields.com/colmap-4.1.0-ships-caspar-gpu-bundle-adjustment-and-native-360-reconstruction
- [3] facebookresearch/vggt README, May 2026, https://github.com/facebookresearch/vggt
- [4] VGGT, CVPR 2025, arXiv 2503.11651, https://arxiv.org/html/2503.11651v1
- [5] VGGT-X, arXiv 2509.25191, https://arxiv.org/abs/2509.25191
- [6] VGGT-X repo, https://github.com/Linketic/VGGT-X
- [7] MapAnything, Meta, 3DV 2026, https://github.com/facebookresearch/map-anything
- [8] Depth Anything 3, Nov 2025, https://github.com/ByteDance-Seed/Depth-Anything-3
- [9] Pi3 / Pi3X, https://github.com/yyfz/Pi3
- [10] naver/mast3r, https://github.com/naver/mast3r
- [12] AnySplat, arXiv 2505.23716, https://huggingface.co/papers/2505.23716
- [16] gsplat README, https://github.com/nerfstudio-project/gsplat
- [17] gsplat `simple_trainer.py` defaults, https://raw.githubusercontent.com/nerfstudio-project/gsplat/main/examples/simple_trainer.py
- [18] gsplat COLMAP example, https://docs.gsplat.studio/main/examples/colmap.html
- [20] Fadilah et al., 3DGS for UAV heritage, ISPRS Archives, 2026-02-12, https://isprs-archives.copernicus.org/articles/XLVIII-2-W12-2026/143/2026/
- [22] LichtFeld Studio README, https://github.com/MrNeRF/LichtFeld-Studio
- [24] "Postshot launches v1.0", radiancefields.com, Aug 2025, https://radiancefields.com/postshot-launches-v1-0-out-of-beta
- [25] Postshot pricing, https://activation.jawset.com/shop/pricing
- [26] Sharp Frames Python, https://github.com/reflct/sharp-frames-python
- [28] nerfstudio "Using custom data", https://docs.nerf.studio/quickstart/custom_dataset.html
- [36] RealityScan video import, https://rshelp.capturingreality.com/en-US/tools/videoimport.htm
- [38] fVDB Reality Capture 0.6.0, NVIDIA, 2026-09-18, https://fvdb-reality-capture.readthedocs.io/latest/release_notes.html
### WEAK
- [2] Debian COLMAP 4.0.2 docs (snippet), https://sources.debian.org/src/colmap/4.0.2-1/doc/features.rst
- [11] InstantSplat (sparse views only), https://github.com/NVlabs/InstantSplat
- [13] Hacker News VGGT thread (mirror), https://hn.nuxt.dev/item/43470651
- [15] Stanford CS231n poster, iPhone reconstruction benchmark (snippet only), https://sflynn7.github.io/3d-reconstruction-benchmark/poster.pdf
- [19] gsplat paper, arXiv 2409.06765 (snippet), https://arxiv.org/pdf/2409.06765
- [21] PlayCanvas forum, MCMC method, Oct 2025, https://forum.playcanvas.com/t/gaussian-splatting-mcmc-method/40962
- [23] Brush v0.3, https://radiancefields.com/brush-releases-v0-3
- [39] HDR to SDR with ffmpeg, dev.to, 2026, https://dev.to/masonwritescode/ffmpeg-hdr-to-sdr-tone-mapping-that-doesnt-look-washed-out-2026-24ie
### DO NOT USE
- "AnySplat beats 3DGS": its baseline used VGGT poses, not COLMAP [12].
- "VGGT 21.88 vs COLMAP 29.24 PSNR" (GASE, arXiv 2606.17520): from a snippet, not in the paper we could read.
- MILo on the GB10 tonight: tested only on CUDA 11.8, non-commercial licence (https://github.com/Anttwo/MILo).

# § 13 Meshes: from video, and from a splat (2026-11-14)
**Question:** can we turn a video of the room into a solid 3D model (a mesh)? Can we turn a splat into one? What would
a mesh be good for in this project? Asked by Max.

**How this pass was done:** about 20 minutes by Max's agent. Papers, Apple docs and repos opened; community view from
forums.

## Findings
### Photos or video → mesh
- **Apple Object Capture:** not on non-LiDAR iPhones, but works on an Apple-silicon Mac from any photos; "area mode"
  handles scenes, not just objects; output is a textured USDZ that RealityKit loads directly; no true scale without
  depth (sources: [M1], [M3], [M4]).
- **RealityScan (Epic):** free, Windows only, needs an NVIDIA or AMD GPU for good meshes; exports GLB, USD, OBJ, FBX
  (sources: [M5], [M6]).
- **Meshroom:** no ARM build [M7]. Not viable on the Spark.
- **Neural surface methods** (2DGS, RaDe-GS, GOF, MILo) beat plain splats for geometry on benchmarks (Tanks & Temples
  F1: 3DGS 0.09, 2DGS 0.30, MILo 0.47–0.49) and take 10–110 min on a 4090 (sources: [M9], [M11]). gsplat ships a 2DGS
  trainer [M16]; the others pin old CUDA stacks [M12]. Their meshes carry vertex colours, which RealityKit doesn't
  render without a custom material or a texture bake [M25].
- Black glossy plastic, specular highlights and thin cables are weak spots for every method (sources: [M9], [M33]).
### Splat → mesh
- **Possible, but documented as poor:** converting a plain splat gives F1 0.09 against 0.30 for 2DGS trained from the
  images (sources: [M9], [M11]). Clean results need coarse voxels (2 cm in one report), which erase 1 cm parts [M15].
- The better post-hoc method needs the original camera positions, which a bare Scaniverse file doesn't have [M14].
- Retraining with a surface-aware method from the original images beats converting.
### What a mesh is for here
- **Phone cut-outs:** a textured USDZ of a part would beat the stand-in model on the phone (sources: [M1], [M27]).
- **Clicking in the browser:** exact only for parts captured up close; the room's splat raycast already exists (§ 7).
- **Measuring:** better defined on a mesh; scale still comes from the marker either way.
- The splat stays better for looking at the room: photoreal, forgiving of shiny black plastic and thin cables.
### Formats
- glTF for three.js (`gltf-transform optimize`) [M29]; USDZ for RealityKit, made directly by Object Capture or via
  Blender [M28]. Keep each part under about 50k triangles with a 1–2K texture (our estimate from [M1], [M27]).

## Community consensus
Train surface-aware from images rather than converting a finished splat; photogrammetry gives the most usable
textured meshes; splats look better. Contrasting: GS2Mesh says post-hoc can work well, but it needs the camera poses.

## Final call (professional + community)
Room: keep the splat for the dashboard; don't mesh it. Parts: if a phone needs to show a real part, photograph it up
close (80–150 photos, marker in frame) and run Object Capture on a Mac (or RealityScan on a Windows GPU laptop); crop,
scale from the marker, ship USDZ to the phone and GLB to the dashboard. Label meshes "photogrammetry mesh" and sizes
"estimated from the marker". Before starting: check whether the team has a Mac, and which iOS the demo phones run
(iOS 27.2+ may draw splats on the phone, § 1).

## Source ledger
### KEEP
- [M1] PhotogrammetrySession detail levels, Apple docs, https://developer.apple.com/documentation/realitykit/photogrammetrysession/request/detail.md
- [M2] PhotogrammetrySession, Apple docs, https://developer.apple.com/documentation/realitykit/photogrammetrysession.md
- [M3] "Discover area mode for Object Capture", WWDC24, https://developer.apple.com/videos/play/wwdc2024/10107/
- [M4] Apple Developer Forums 775564 (LiDAR needed on iPhone), 2025, https://developer.apple.com/forums/thread/775564
- [M5] RealityScan 2.2, Digital Production, 2026-06-26, https://digitalproduction.com/2026/06/26/realityscan-2-2-widens-gpu-support/
- [M9] 2D Gaussian Splatting, SIGGRAPH 2024, arXiv 2403.17888, https://arxiv.org/html/2403.17888
- [M10] 2DGS repo, https://github.com/hbb1/2d-gaussian-splatting
- [M11] MILo, SIGGRAPH Asia 2025, arXiv 2506.24096, https://arxiv.org/html/2506.24096v2
- [M12] MILo repo, https://github.com/Anttwo/MILo
- [M14] GS2Mesh, ECCV 2024, arXiv 2404.01810, https://arxiv.org/abs/2404.01810
- [M16] gsplat examples (2DGS trainer), https://github.com/nerfstudio-project/gsplat/tree/main/examples
- [M25] Apple Developer Forums 691674, vertex colour unsupported, 2021, https://developer.apple.com/forums/thread/691674
- [M27] Apple Developer Forums 693867, USDZ size guidance, 2021, https://developer.apple.com/forums/thread/693867
- [M28] AOUSD forum, usdzconvert discontinued, 2024, https://forum.aousd.org/t/obj-gltf-to-usdz-usdzconvert-discontinued/1648
- [M29] gltf-transform CLI, https://gltf-transform.dev/cli
- [M30] open3d 0.19.0 on PyPI (no aarch64), https://pypi.org/pypi/open3d/0.19.0/json *(superseded 2026-11-14: open3d 0.20.0 has aarch64 wheels, § 14 [1])*
### WEAK
- [M6] RealityScan hardware requirements (snippet), https://dev.epicgames.com/documentation/realityscan/hardware-and-software-requirements
- [M7] Meshroom 2025.1.0 (snippet), https://github.com/alicevision/Meshroom/releases/tag/v2025.1.0
- [M15] NVIDIA forum, fVDB mesh from 3DGS, May 2026, one user, https://forums.developer.nvidia.com/t/fvdb-reality-capture-poor-mesh-quality-from-3dgs-parameter-tuning-alternatives/369420
- [M18] PGSR, arXiv 2406.06521, https://arxiv.org/abs/2406.06521
- [M22] KIRI 4.2 "3DGS to Mesh 3.0", radiancefields.com, Apr 2026 (vendor claims), https://radiancefields.com/kiri-engine-4.2-ships-3dgs-to-mesh-3.0
- [M26] Apple Developer Forums 759449, vertex colours via ShaderGraph, https://developer.apple.com/forums/thread/759449
- [M33] Black/shiny object scanning: Formlabs forum, https://forum.formlabs.com/t/3d-scanning-black-plastic-or-metal-utilitarian-objects/21376
### DO NOT USE
- The bransantiago/MILo mirror: downloads point to an unrelated zip. Use Anttwo/MILo only.
- polyvia3d splat-to-mesh page: unsourced.
- "Post-hoc conversion gives a usable mesh of 1 cm parts from our Scaniverse splat": refuted by [M9], [M11], [M15].

# § 14 Video to a textured mesh on the DGX Spark (2026-11-14)
**Question:** every way to turn an iPhone video of the set into a textured mesh, computed on the DGX Spark (GB10,
ARM64, CUDA 13), ranked by how likely each is to work tonight. Asked by Max, who wants a mesh route that works.
Updates § 9 and § 13.

**How this pass was done:** about 25 minutes by Max's agent. PyPI file lists, GitHub issues and release notes opened.

## Findings
### Two corrections to earlier sections
- **open3d 0.20.0 (2026-09-16) ships Linux aarch64 wheels** (CPU only). § 9's stubbed open3d imports and § 13 [M30]
  are out of date: TSDF fusion, Poisson and marching cubes all run on the Spark (sources: [1], [2]).
- **COLMAP's CUDA dense step works on Blackwell since PR #4213 (April 2026)**, confirmed by a GB10 user; it needs the
  CUDA toolkit no newer than the driver (sources: [3], [4]). `colmap poisson_mesher` still crashes on aarch64 (open
  issue) [5].
### The routes, most likely to work tonight first (times are estimates)
1. **CPU COLMAP poses → gsplat 2DGS → open3d TSDF on rendered depth → pymeshlab texture bake.** Every piece is
   already proven or pip-installable on the Spark (§ 9, [1], [16], [19]); no C++ builds. gsplat's 2DGS trainer has no
   mesh export, so a ~60-line script renders depth per camera and fuses it [16]. About 1–2 h. 2DGS scores about 3×
   plain splats on geometry benchmarks (§ 13 [M9]). Risks: dents on the glossy switch, cables under 2 voxels vanish,
   blurry per-vertex texture unless the mesh is dense. No report of the 2DGS trainer itself on GB10.
2. **VGGT / Depth Anything 3 / MapAnything depth and poses → open3d TSDF.** Fast (30–45 min); VGGT's and MapAnything's
   dependencies all install on aarch64; DA3 needs `--no-deps` (sources: [12], [13], [14]). Coarse: low-resolution
   depth, no 1 cm screws [21].
3. **COLMAP 4.2.1 built with CUDA → dense PatchMatch → mesh in open3d or pymeshlab** (not COLMAP's crashing Poisson).
   Highest detail on matte textured parts; holes on black gloss and cables. Build 30–60 min, run 45–90 min
   (sources: [3], [4], [5], [7]).
4. **OpenMVS TextureMesh on top of route 3:** the best real photo texture; ARM builds plausible, CUDA off; untested
   on GB10 (sources: [17], [18]).
5. **DN-Splatter** (nerfstudio, uses AI normal and depth hints, made for glossy indoor surfaces): fits our problem but
   last updated 2024; 1–2 h setup, untested [WEAK].
- **Not tonight:** nvblox (pip wheels x86 only) [10]; fVDB (x86 wheels only) [8], [9]; Neuralangelo and other neural
  SDFs (day-scale); research surface repos (old CUDA) [WEAK]; running x86 tools like RealityScan on the Spark through
  emulation (sources: [20], [22]).
### Black glossy plastic and thin cables
- Make the switch matte for the scan (vanishing scanning spray or dry shampoo), use soft even light, lock exposure
  and focus [WEAK, forum consensus]. AI normal/depth hints help splat-based routes, not classic PatchMatch.
- Anything under about 2–3 voxels (thin cables) is lost by TSDF and Poisson.

## Community consensus
COLMAP + OpenMVS is the standard open textured-mesh pipeline and has the best texture; 2DGS-family meshes are more
complete and smoother than converting a splat; feed-forward models are fast but coarse; black gloss needs coating or
diffuse light.

## Final call (professional + community)
Primary: route 1 (2DGS + open3d TSDF + pymeshlab bake), because it reuses the stack already proven on the Spark.
Backup: route 2 (VGGT into the same TSDF script), a coarse mesh in under an hour. Stretch, in parallel: COLMAP with
CUDA + OpenMVS texturing for the sharpest result. Before capture, matte the switch. Label meshes "made on the DGX
Spark" only if they were; sizes are estimates from the marker.

## Source ledger
### KEEP
- [1] open3d 0.20.0 on PyPI (aarch64 wheels), 2026-09-16, https://pypi.org/pypi/open3d/json
- [2] Open3D v0.20.0 release notes, 2026-09-16, https://github.com/isl-org/Open3D/releases
- [3] COLMAP issue #3514, PatchMatch on Blackwell (GB10 reports, fix, driver caveat), https://github.com/colmap/colmap/issues/3514
- [4] COLMAP PR #4213, Blackwell PatchMatch fix, 2026-04-02, https://github.com/colmap/colmap/pull/4213
- [5] COLMAP issue #4335, `poisson_mesher` crash on DGX Spark, open, https://github.com/colmap/colmap/issues/4335
- [6] COLMAP issue #5004, no pycolmap aarch64 wheels, 2026-11-09, https://github.com/colmap/colmap/issues/5004
- [7] COLMAP issue #4105, ONNX Runtime x86 on arm64, closed 2026-02, https://github.com/colmap/colmap/issues/4105
- [8] fVDB Reality Capture installation, https://fvdb-reality-capture.readthedocs.io/latest/installation.html
- [9] fVDB wheel index (x86 only), https://d36m13axqqhiit.cloudfront.net/simple/fvdb-core/
- [10] nvblox installation (pip x86 only), https://nvidia-isaac.github.io/nvblox/v0.0.9/pages/installation.html
- [11] NuRec stereo workflow (stereo, x86), https://docs.nvidia.com/nurec/robotics/neural_reconstruction_stereo.html
- [12] Depth Anything 3 README and pyproject, https://github.com/ByteDance-Seed/Depth-Anything-3
- [13] MapAnything pyproject v1.1.4, https://github.com/facebookresearch/map-anything
- [14] VGGT requirements, https://github.com/facebookresearch/vggt
- [16] gsplat examples, `simple_trainer_2dgs.py`, https://github.com/nerfstudio-project/gsplat/tree/main/examples
- [17] OpenMVS PR #1324, CPU fallback, 2026-11-03, https://github.com/cdcseacave/openMVS/pull/1324
- [18] OpenMVS v2.4.0 release and CI, 2026-01-20, https://github.com/cdcseacave/openMVS/releases
- [19] PyMeshLab filter list, https://pymeshlab.readthedocs.io/en/latest/filter_list.html
- [20] FEX-2607 (partial CUDA thunking on DGX Spark), 2026-07, https://fex-emu.com/FEX-2607/
- [21] Li, Vosselman, Nex, multi-view stereo comparison, arXiv 2604.10246, 2026-04-11, https://arxiv.org/abs/2604.10246
- [22] RealityScan for Linux (Wine, experimental), Epic, https://dev.epicgames.com/documentation/en-us/realityscan/realityscan-for-linux
### WEAK
- Isaac ROS nvblox page (DGX Spark listed; search summary), https://nvidia-isaac-ros.github.io/repositories_and_packages/isaac_ros_nvblox
- NVIDIA forum, fVDB mesh from 3DGS (one user), May 2026, https://forums.developer.nvidia.com/t/fvdb-reality-capture-poor-mesh-quality-from-3dgs-parameter-tuning-alternatives/369420
- DN-Splatter README (last update Nov 2024), https://github.com/maturk/dn-splatter
- OpenMVS on nixpkgs aarch64 (snippet), https://mynixos.com/nixpkgs/package/openmvs
- mvs-texturing issue #78, 2017, https://github.com/nmoehrle/mvs-texturing/issues/78
- MILo issues #20 / #21, 2025-10, https://github.com/Anttwo/MILo/issues/20
- 2DGS issue #250, 2026-01, https://github.com/hbb1/2d-gaussian-splatting/issues/250
- aniwaa scanning-spray overview, https://www.aniwaa.com/insight/3d-scanners/3d-scanning-spray-overview/
- Revopoint forum, dark and shiny objects, https://forum.revopoint3d.com/t/scan-dark-and-shiny-object/22214
### DO NOT USE
- "open3d has no aarch64 wheel" (§ 9, § 13 [M30]): superseded by [1].
- "COLMAP CUDA dense doesn't work on Blackwell": fixed by [4]; only `poisson_mesher` on aarch64 is still broken [5].
- Running RealityScan or any x86 CUDA tool on the Spark through emulation: not viable [20], [22].
- "DA3 is under 5% slower without xformers": community claim, unmeasured.

# § 15 Phone → DGX Spark → mesh back on the phone (2026-11-14)
**Question:** can the iPhone record a scan, send it to the Spark, and get a mesh back for the phone (USDZ) and the
dashboard (GLB)? Can the phone's own ARKit camera positions skip the slow camera-position step? Asked by Max.

**How this pass was done:** about 20 minutes by Max's agent. Apple docs read through their JSON endpoints; the usd-core
aarch64 wheel downloaded and inspected.

## Findings
### ARKit camera positions
- A non-LiDAR iPhone can save each frame with its camera position and lens data; LiDAR only adds depth (sources: [P5],
  [P8], [P9]). No ready-made app exports this for non-LiDAR phones in a usable way (NeRFCapture is stale since 2023;
  Scan4D's non-LiDAR mode is debug-only; nerfstudio's phone paths need LiDAR) (sources: [P1], [P3], [P4]). Our own app
  can write it: about 100 lines of Swift (estimate).
- Frames: 1920×1440 at up to 60 fps, or 4K at 30 fps; 12 MP stills with pose via `captureHighResolutionFrame`, but
  not at video rate (sources: [P5], [P6], [P7]).
- **Accurate to about a centimetre, not a millimetre:** ARKit was the most accurate phone tracking in one benchmark,
  about 0.02 m/s drift [P13]; that's good for AR but too loose for a sharp model without refinement [P14]. The
  standard fix: COLMAP's "known poses" recipe (triangulate, then optionally bundle-adjust), which skips the fragile
  mapping step and keeps ARKit's real-world scale [P18].
- ARKit and nerfstudio use the same axes; COLMAP needs Y and Z flipped and the transform inverted (sources: [P9],
  [P10]). Check one frame visually; double conversion is the classic bug [WEAK].
### Sending it to the Spark
- **No code, tonight:** LocalSend (free, open source; iPhone app and an ARM Linux build) over the phone hotspot if venue
  Wi-Fi isolates devices (sources: [P19], [P20]). Backup: the Files app to a Samba share [WEAK].
- **In the app:** zip frames + `transforms.json`, one background `URLSession` file upload to a small server on the Spark
  (sources: [P22], [P23]). About 100–200 MB for 300 frames (estimate).
### Getting the mesh back
- usd-core 26.11 (2026-10-21) is the first with aarch64 wheels and includes the USDZ packager, but no glTF reader; a
  small trimesh → USD script bridges it [P25]. guc has no ARM build [P26].
- RealityKit doesn't render vertex colours; the mesh needs a UV texture [P29]. pymeshlab (aarch64 wheels) bakes one,
  best from the original photos when poses are known (sources: [P31], [P32]). Keep it under about 100k triangles and
  a 2K texture [P30].
- Phone: download to a file, then `Entity(contentsOf:)` (async) (sources: [P33], [P34]). Dashboard: GLTFLoader;
  shrink with `gltf-transform optimize` (sources: [P35], [P36]).
### How long it takes (estimates, nothing measured)
- Capture 1–2 min, upload 0.5–2 min, known-poses COLMAP 3–10 min, reconstruction dominant (5–15 min for a fast mesh
  route, over an hour for splat training), conversion under 1 min. About 10–30 min end to end with a fast route.

## Community consensus
ARKit positions are good enough for AR but need refining for reconstruction; contrasting view: ARKit is more robust
than COLMAP on textureless scenes [WEAK]. LocalSend is the standard AirDrop substitute; its usual failure is Wi-Fi
client isolation.

## Final call (professional + community)
Tonight with no code: LocalSend from the iPhone to the Spark. In the app: frames + ARKit positions → one upload → the
Spark refines the positions with COLMAP, reconstructs, bakes a texture, and returns USDZ + GLB. "The mesh appears a
few minutes later" is only honest if a full run has been timed on the Spark first; otherwise show it as REPLAY.

## Source ledger
### KEEP
- [P1] NeRFCapture, GitHub (stale since 2023-12), https://github.com/jc211/NeRFCapture
- [P3] Scan4D iOS README, GitHub, 2026-11-13, https://github.com/WiseLabCMU/scan4d-ios
- [P4] nerfstudio "Using custom data", https://docs.nerf.studio/quickstart/custom_dataset.html
- [P5] WWDC22 "Discover ARKit 6", Apple, https://developer.apple.com/videos/play/wwdc2022/10126
- [P6] `recommendedVideoFormatFor4KResolution`, Apple docs, https://developer.apple.com/documentation/arkit/arconfiguration/recommendedvideoformatfor4kresolution
- [P7] `captureHighResolutionFrame`, Apple docs, https://developer.apple.com/documentation/arkit/arsession/capturehighresolutionframe(completion:)
- [P8] `ARFrame.capturedImage`, Apple docs, https://developer.apple.com/documentation/arkit/arframe/capturedimage
- [P9] `ARCamera.transform`, Apple docs, https://developer.apple.com/documentation/arkit/arcamera/transform
- [P10] nerfstudio data conventions, https://docs.nerf.studio/quickstart/data_conventions.html
- [P13] Kim et al., VIO benchmark, Sensors, Dec 2022, https://pmc.ncbi.nlm.nih.gov/articles/PMC9785098
- [P14] CamP, SIGGRAPH Asia 2023, https://camp-nerf.github.io
- [P18] COLMAP FAQ, known camera poses, https://colmap.github.io/faq.html
- [P19] LocalSend README, https://github.com/localsend/localsend
- [P20] LocalSend v1.18.2 release (linux-arm-64), 2026-08-21, https://github.com/localsend/localsend/releases
- [P22] `URLSession.uploadTask(with:fromFile:)`, Apple docs, https://developer.apple.com/documentation/foundation/urlsession/uploadtask(with:fromfile:)
- [P23] `URLSessionConfiguration.background`, Apple docs, https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background(withidentifier:)
- [P25] usd-core 26.11 on PyPI (aarch64 wheels, inspected), 2026-10-21, https://pypi.org/project/usd-core/
- [P26] guc releases (no Linux ARM), https://github.com/pablode/guc/releases
- [P29] Apple Developer Forums 691674, vertex colours unsupported, https://developer.apple.com/forums/thread/691674
- [P31] PyPI file lists for pymeshlab, open3d, xatlas, trimesh, checked 2026-11-14, https://pypi.org/pypi/open3d/json
- [P32] PyMeshLab filter list, https://pymeshlab.readthedocs.io/en/latest/filter_list.html
- [P33] `Entity.init(contentsOf:withName:)`, Apple docs, https://developer.apple.com/documentation/realitykit/entity/init(contentsof:withname:)
- [P34] `Entity.load(contentsOf:withName:)`, Apple docs, https://developer.apple.com/documentation/realitykit/entity/load(contentsof:withname:)
- [P35] three.js GLTFLoader, https://threejs.org/docs/pages/GLTFLoader.html
- [P36] glTF Transform CLI, https://gltf-transform.dev/cli
### WEAK
- [P2] instant-ngp dataset tips (old mirror), https://huggingface.co/camenduru/instant-ngp/raw/main/docs/nerf_dataset_tips.md
- [P11] nerfstudio issue #3101 (summary only), https://github.com/nerfstudio-project/nerfstudio/issues/3101
- [P12] nerfstudio discussion #3748 (summary only), https://github.com/nerfstudio-project/nerfstudio/discussions/3748
- [P15] Tampere thesis, ARKit accuracy (summary only), https://trepo.tuni.fi/handle/10024/159133
- [P16] Record3D/instant-ngp "more robust than COLMAP" (same doc as [P2])
- [P17] Polycam/Polyform notes (vendor claim), https://www.gitlink.org.cn/dnrops/polyform
- [P21] Files app SMB guides, https://www.techrepublic.com/article/how-to-use-the-files-app-to-connect-to-a-network-server-from-your-iphone-or-ipad/
- [P24] MacRumors, iPhone 12 hotspot 5 GHz, 2020, https://www.macrumors.com/2020/10/26/iphone-12-personal-hotspot-over-5ghz-wifi/
- [P27] BlenderKit on ARM64 Linux, 2024, https://www.blenderkit.com/articles/blenderkit-on-arm64-linux/
- [P28] Debian blender `debian/rules`, https://sources.debian.org/src/blender/
- [P30] Apple Developer Forums 693867, 2021, https://developer.apple.com/forums/thread/693867
### DO NOT USE
- "ARKit relative pose error under 5 cm" (MobileEgo, arXiv 2605.05945): snippet only.
- Record3D or Polycam nerfstudio paths on our non-LiDAR phones: refuted by [P4].
- "Official Blender ARM64 builds since 4.3" (Linaro): no release listing found.

# § 16 App Lab app layout and the UNO Q's LED matrix over the Bridge (2026-11-15)
**Question:** how should the rig be packaged so it runs as an App Lab app, and how does Python get a tick or a cross
onto the UNO Q's own LED matrix?

**How this pass was done:** about 10 minutes by Ahmed's agent. The library header [1] and three files of Arduino's
LED Matrix Painter example [2] were opened; the rest came through search summaries.

## Findings
- The matrix is 13 × 8. `Arduino_LED_Matrix` has `begin()`, `setGrayscaleBits(bits)`, `clear()` and
  `draw(const uint8_t *buf)`, one byte per pixel (source: [1]).
- Arduino's Painter example: the sketch includes `Arduino_RouterBridge.h` and `Arduino_LED_Matrix.h`, calls
  `matrix.begin()`, `setGrayscaleBits(8)`, `clear()`, `Bridge.begin()`, and `Bridge.provide("draw", ...)`, which calls
  `matrix.draw(...)`; Python imports `App, Bridge` from `arduino.app_utils`, calls `Bridge.call("draw", ...)` and ends
  with `App.run()` (source: [2]).
- An app is a folder with `app.yaml`, `python/main.py` and `sketch/` (`sketch.ino`, `sketch.yaml`); App Lab keeps
  `app.yaml` itself (sources: [2], [3]). `requirements.txt` beside `main.py` matches § 10's [7] and the failed first
  access test, where App Lab installed nothing.
- `App.run(user_loop=...)` calls a function over and over (source: [4], community only).
- Don't call `Bridge.call()` inside a function the sketch provides: starting one exchange while answering another can
  deadlock (seen in a search summary of an Arduino forum thread; the thread wasn't pinned down).
- **Not found:** whether `draw()` lays pixels out row by row or column by column. Check on the board.

## Final call
The rig ships as `hardware/unoq/python/` plus `hardware/unoq/sketch/sketch.ino`, following the Painter example;
`main.py` falls back to running without the matrix when `arduino.app_utils` isn't there.

## Source ledger
### KEEP
- [1] `Arduino_LED_Matrix.h`, ArduinoCore-zephyr,
  https://github.com/arduino/ArduinoCore-zephyr/blob/main/libraries/Arduino_LED_Matrix/src/Arduino_LED_Matrix.h
- [2] LED Matrix Painter example, arduino/app-bricks-examples PR #5, https://github.com/arduino/app-bricks-examples/pull/5
  (files read at `beanrepo/app-bricks-examples@800db05`)
### WEAK
- [3] "Arduino App Lab", DroneBot Workshop, https://dronebotworkshop.com/arduino-app-lab/ : the app folder layout.
- [4] "Arduino UNO Q App Lab Bridge RPC guide", esp32.co.uk, https://esp32.co.uk/arduino-uno-q-app-lab-bridge-rpc-guide/ :
  `App.run(user_loop=...)`.
### DO NOT USE
- _(none)_


# § 17 Swapping the SSD on a Dell Latitude 5530 (2026-11-15)
**Question:** the demo guide walks the user through taking the SSD out of Ahmed's laptop (a Dell Latitude 5530) and
putting the same one back. What are the real steps, screw counts and tools, so the guide doesn't teach anything wrong?

## Findings
### Before opening it
- Save work, shut down, unplug the charger and everything else (source: [1]).
- **Service Mode** cuts power without unplugging the battery: hold **B** and press the power button for 3 s or until
  the Dell logo; it beeps three times and shuts down. If the laptop can't enter it, disconnect the battery cable
  instead ([1]). Connecting the charger again leaves Service Mode ([2]).
### Base cover
- **Eight captive screws** (they stay in the cover), a **#0 Phillips** screwdriver, then a **plastic scribe** in the
  U-shaped indents at the top edge; lift the cover off by its left and right sides ([3], [4]).
- Refit: align the holes, snap it into place, tighten the eight captive screws ([3]).
### The M.2 2280 SSD
- Prerequisites listed: SIM card, microSD card, base cover. The battery is **not** listed ([5]).
- **Without a bracket:** one **M2x4** screw, then slide the SSD out of its slot at an angle ([5]).
- **With a bracket:** two **M2x3** screws hold the bracket; lift it off (re-stick the thermal pad to it if it comes
  loose), then slide the SSD out at an angle ([5]).
- Which one Ahmed's laptop has, and which of the two M.2 slots the SSD sits in, has to be checked on the laptop.

## Community consensus
Not searched: the vendor's own service manual is the authority on its own hardware, and the step list only has to be
true for this one laptop. A check on the real laptop (screw count, bracket or not) replaces it.

## Final call (professional + community)
Use Dell's steps as written: Service Mode first, eight captive screws, pry from the top-edge indents, then one M2x4
screw (or the two-screw bracket) and slide the SSD out at an angle. Count the screws on Ahmed's laptop before the
guide is final.

## Source ledger
### KEEP
- [1] Dell, "Latitude 5530 Service Manual: Before working inside your computer", dell.com, read 2026-11-15,
  https://www.dell.com/support/manuals/en-us/latitude-15-5530-laptop/latitude_5530_sm/before-working-inside-your-computer?guid=guid-2ae8811c-4aa6-4751-9134-1af4bb41f0f1&lang=en-us : shutdown, Service Mode.
- [2] Dell, "Latitude 5530 Service Manual: After working inside your computer", dell.com,
  https://www.dell.com/support/manuals/en-us/latitude-15-5530-laptop/latitude_5530_sm/after-working-inside-your-computer?guid=guid-0844719b-51d7-4082-827f-162cbfb365d0&lang=en-us : leaving Service Mode.
- [3] Dell, "Latitude 5530 Service Manual: Removing the base cover", dell.com,
  https://www.dell.com/support/manuals/en-us/latitude-15-5530-laptop/latitude_5530_sm/removing-the-base-cover?guid=guid-52bff0d1-4382-421b-8d35-e3e5905f29e4&lang=en-us : eight captive screws, scribe, refit.
- [4] Dell, "Latitude 5530 Service Manual: Screw list", dell.com,
  https://www.dell.com/support/manuals/en-us/latitude-15-5530-laptop/latitude_5530_sm/screw-list?guid=guid-cc648b28-fbf9-4a6f-bb11-4c6c2fa3d08a&lang=en-us : screw counts, #0 Phillips.
- [5] Dell, "Latitude 5530 Service Manual: Removing the M.2 2280 solid-state drive", dell.com, read 2026-11-15,
  https://www.dell.com/support/manuals/en-us/latitude-15-5530-laptop/latitude_5530_sm/removing-the-m2-2280-solid-state-drive?guid=guid-be0c8101-86eb-492e-beef-7a326dd7e2df&lang=en-us : prerequisites, both screw variants, slide out at an angle.
### WEAK
- ManualsLib's copy of the same manual, https://www.manualslib.com/manual/3123970/Dell-Latitude-5530.html : agrees,
  but it is a mirror of [3]–[5], not an independent source.
### DO NOT USE
- _(none)_
