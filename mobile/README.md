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

## If it breaks
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
