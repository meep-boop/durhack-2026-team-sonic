# Remote Assist: iPhone app

Native Swift (SwiftUI + ARKit + RealityKit), iOS 18+. It finds the printed marker under world tracking, pins the
guide to it, and plays the steps with **Next**. Owner: @salman.

## Build and run on your iPhone
```bash
brew install xcodegen          # once
cd ios
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
Until @laura's marker lands in `assets/marker/`, the app uses `RemoteAssist/Resources/marker.png`. Show it at
**exactly 16 cm wide** (print it, or put it on a screen and measure with a ruler), because the sample guide
assumes 0.16 m. If yours is a different size, set `MarkerSpec.widthMeters` to what you measured. A wrong width
scales every position.

What you should see: a green outline on the marker's edges and an axis marker at its centre (red +X, green +Y,
blue +Z). The outline stays put when the marker leaves view, and snaps back when you see it again.

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
