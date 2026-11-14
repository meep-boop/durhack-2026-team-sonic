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
