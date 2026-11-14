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
