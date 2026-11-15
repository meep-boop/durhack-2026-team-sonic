#!/usr/bin/env bash
# Downloads Google's WebRTC for iOS (stasel/WebRTC 156.0.0) into ios/Vendor/, checked against the release's
# published SwiftPM checksum. Run once per clone, before `xcodegen`. Vendor/ is git-ignored (the framework is ~46 MB).
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION=156.0.0
URL="https://github.com/stasel/WebRTC/releases/download/${VERSION}/WebRTC-M156.xcframework.zip"
SHA256=43c2a6f7a650185bbc911d7605a979589671886e8fc0ac283f54fdf3f511dc46

if [ -d Vendor/WebRTC.xcframework ]; then echo "WebRTC already in Vendor/"; exit 0; fi
mkdir -p Vendor
curl -fL --retry 3 -o Vendor/webrtc.zip "$URL"
echo "${SHA256}  Vendor/webrtc.zip" | shasum -a 256 -c -
unzip -q Vendor/webrtc.zip -d Vendor
rm Vendor/webrtc.zip
echo "WebRTC ${VERSION} ready in ios/Vendor/WebRTC.xcframework"
