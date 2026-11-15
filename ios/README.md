# Remote Assist: iPhone app

Native Swift (SwiftUI + ARKit + RealityKit), iOS 18+. It finds the printed marker under world tracking, pins the
guide to it, and plays the steps with **Next**. Owner: @salman.

## Build and run on your iPhone
```bash
brew install xcodegen          # once
cd ios
./scripts/fetch-webrtc.sh      # once: Google's WebRTC (46 MB, checksum-checked) into ios/Vendor/
cp Secrets.xcconfig.example Secrets.xcconfig   # once; add Gemini / ElevenLabs keys to turn those features on
xcodegen                       # makes RemoteAssist.xcodeproj from project.yml (git-ignored, never commit it)
open RemoteAssist.xcodeproj
```
First time on your machine (free Apple ID is fine):
1. Xcode → Settings → Accounts → add your Apple ID.
2. Copy `Local.xcconfig.example` to `Local.xcconfig` and put your Team ID in it, so `xcodegen` keeps your signing.
   You can also pick your Personal Team in Signing & Capabilities, but you'll redo that after every `xcodegen`.
3. iPhone: plug it in, then turn on Settings → Privacy & Security → **Developer Mode** and restart.
4. Pick the iPhone in Xcode's device menu and press Run. On the phone, go to Settings → General → VPN & Device
   Management and trust your developer profile.

If the bundle ID `com.teamsonic.remoteassist` is taken on your Apple ID, change `PRODUCT_BUNDLE_IDENTIFIER` in
`project.yml` locally. Free signing lasts 7 days, then Run again.

## The marker
The app tracks @laura's `assets/marker/marker.png`, bundled straight from `assets/`. Print
`marker-print-A4.pdf` at 100% and check it measures **180 mm** (`MarkerSpec.widthMeters = 0.18`). Shown on a
screen at another size it still lines up, because ARKit estimates the real size.

What you should see: a green outline on the marker's edges and an axis marker at its centre (red +X, green +Y,
blue +Z). Cover the marker with your hand and everything stays where it was, with your hand drawn in front; it
re-locks when the marker is visible again.

## Live call with the expert
```bash
cd relay && npm install && npm start          # prints ws://<laptop-ip>:8080
cd ios/expert-call && python3 -m http.server 8000   # open http://localhost:8000 on the expert's laptop
```
Type the relay's `ws://` address into the page and press Connect: it shows a QR. On the phone, tap the status
capsule, then **Scan QR**. Press **Call the phone** on the page, then **Accept** on the phone: the page sees the AR camera live and
both sides can talk. Phone and laptop must be on the same Wi-Fi or hotspot (peer-to-peer, STUN only).
Lock the phone or switch apps mid-call and the voice keeps going while the camera pauses; it picks up again when you
come back.

## Offline, then back online (the resync demo)
1. Connect the phone to the relay; the expert page shows it online.
2. Turn the phone's Wi-Fi off. Tap Done on three steps: the card says they'll sync later.
3. Kill the app (swipe it away). Open it again: you're on the same step, and the three are still waiting.
4. Turn Wi-Fi back on. The phone reconnects by itself, the toast says "3 steps synced to the expert", and the expert
   page logs the three `step.done` with the times you tapped them, not the time they arrived.

## Laptop assistant and voice (optional)
With `GEMINI_API_KEY` set, the laptop button identifies the laptop from the camera, writes the SSD-swap steps, pins
parts ("Show me where") and checks each step ("Check my work"). Everything it says is labelled AI-generated, and it
refuses to guide when the storage is soldered. With `ELEVENLABS_API_KEY` set, steps are read aloud by ElevenLabs;
without it (or offline) the built-in iOS voice reads them.

## Checks
```bash
xcodegen && xcodebuild -project RemoteAssist.xcodeproj -scheme RemoteAssist \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build      # compiles for a device
xcodebuild -project RemoteAssist.xcodeproj -scheme RemoteAssist \
  -destination 'platform=iOS Simulator,name=<any iPhone sim>' test       # decodes the sample guide
```

## Layout
- `RemoteAssist/Protocol/Protocol.swift`: a hand mirror of `contracts/protocol.ts`. Change both together.
- `RemoteAssist/AR/`: the AR session, marker anchor and drawing.
- `RemoteAssist/Guide/GuidePlayer.swift`: steps by id, Next.
- `../fixtures/sample-guide.json` is bundled straight from Ahmed's fixtures.
