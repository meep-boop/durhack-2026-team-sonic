# Team Sonic mobile

The Expo app (SDK 58, Expo Router). It's a placeholder shell with Home, Explore and Profile tabs until we pick the
idea. It runs in **Expo Go**, so there's no Xcode or Android Studio to set up and no app store.

## Run it and share it
```bash
cd mobile
npm install
npm run share      # expo start --tunnel: works on any network, not just your Wi-Fi
```
Then, on any phone, anywhere:
1. Install **Expo Go** ([iPhone](https://apps.apple.com/app/expo-go/id982107779) ·
   [Android](https://play.google.com/store/apps/details?id=host.exp.exponent)).
2. Scan the QR code from the terminal. On iPhone, use the **Camera** app. On Android, scan it **inside Expo Go**.

To send it to a friend, screenshot the QR code or copy the `exp://…` link the terminal prints. **Your laptop has to
stay on with `npm run share` running** while they use it. Every file you save reloads live on their phone.

**iPhone error "signed in to Expo CLI as X and to Expo Go as Y":** on iPhones, Expo Go must be signed in to the same
Expo account as the laptop running `npm run share`. Either sign in to Expo Go with that account, or run
`npm run share` from your own laptop with `npx expo login` as yourself. Android phones don't have this rule.

## AR (needs the dev build, iPhone only)
The **AR** tab uses ARKit through our own native module (`modules/sonic-ar`, Swift + RealityKit). It has three modes:
**Place** (tap a surface to drop a cube), **Image** (track `assets/ar/marker.png`, shown on a screen or printed
15 cm wide) and **Measure** (tap two points; uses LiDAR on Pro iPhones). Expo Go can't run native code, so in Expo
Go the AR tab only shows a notice. Everything else still works there.

To put the AR build on your own iPhone (free Apple ID, no paid account):
1. Plug the iPhone into the Mac. On the phone, turn on Settings → Privacy & Security → **Developer Mode** and restart.
2. `npx expo prebuild --platform ios`, then open `ios/TeamSonic.xcworkspace` in Xcode → TeamSonic target →
   Signing & Capabilities → Team: **your Apple ID (Personal Team)**. If the bundle ID is taken, change it there
   to something unique like `com.<yourname>.teamsonic`.
3. `npm run ios:device` and pick your iPhone. On the phone: Settings → General → VPN & Device Management → trust
   your developer profile.
4. After that, `npm run dev` starts the server for the installed dev build. JS changes reload live; Swift changes
   need step 3 again.

With a free Apple ID the app stops opening after **7 days** (rebuild to renew), and you can only install it on
phones plugged into your Mac. Sending friends an install link needs the paid Apple Developer account ($99/yr).

## If it breaks
- **"502 Bad Gateway / No server is connected"**: that link's server is gone (Expo Go's "Recently opened" keeps
  dead links). Tap **Clear**, then scan the QR from the server that's running now.
- **Opening a tunnel link by hand** (no QR): use `exps://<tunnel-host>`, not `exp://`. Tunnels only answer over
  https. Paste it in Safari or tap it in a message → Open in Expo Go.
- **"Cannot find native module …"** or a red screen on first open: update Expo Go from the store (it must support
  SDK 58), then shake the phone → **Reload**.
- **"Could not connect to development server"**: the first tunnel load sometimes times out. Reload once. If it
  keeps happening, stop the server and run `npm run share` again.

## Checks
```bash
npm run typecheck
npx @expo/agent-cli doctor
```
Add packages with `npx @expo/agent-cli install <pkg>` (not `npm install <pkg>`), so versions match SDK 58.
