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
