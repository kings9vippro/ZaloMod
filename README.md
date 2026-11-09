# PHK Control — Native Liquid Glass iOS Prototype

An original **SwiftUI + UIKit + Objective-C++ + C++17** first-party iOS application. Navigation and interface code are built directly into the app executable; **no dylib injection** is needed for this app.

This is **not Zalo's source code**, not a signed/modified Zalo IPA, and it does not interact with Zalo accounts or sessions. The App Store link for Zalo is a public distribution page, not an Xcode project.

## Native version 2.0
- Five pages: Tin nhắn, Danh bạ, Khám phá, Nhật ký, Cá nhân; real native page swipe gestures and a draggable bottom selector.
- Liquid Glass tab bar for iOS 26+, translucent material fallback from iOS 16; accessibility Reduce Motion support.
- Consistent SF Symbols and human-scale font sizes. User-supplied wallpaper is clipped within Journal/Profile content cards rather than distorting the entire screen.
- Previous 4-section settings panel still opens from Profile or a three-finger screen tap.
- C++17 settings core now contains checked TTL conversion and deterministic tab-drag step calculation with portable unit tests.
- Build runs through XcodeGen on GitHub Actions. A successful unsigned IPA is an output artifact, **not** an installed or signed Zalo release.

## Build from source
\`\`\`sh
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild -project PHKControl.xcodeproj -scheme PHKControl -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
\`\`\`
The GitHub Actions job uploads \`PHKControl-unsigned-ipa\` after building and validating the iPhone target.

## Key paths
- \`iOS/Sources/NativeShell/PHKNativeShell.swift\` — main interface and 5 tabs.
- \`iOS/Sources/ContentView.swift\` — existing menu, retained 3-finger shortcut.
- \`Core/Settings.cpp\` — native C++ state helpers.
- \`docs/NATIVE-LIQUID-GLASS.md\` — design and compatibility.
- \`PHKStandaloneKit/\` — **legacy experimental separate dylib**, not needed by \`PHKControl\`.

All sample conversations are local demonstration data. Sending Zalo messages, changing server-side status, or reproducing third-party tweaks is outside the implemented feature set. Signing requires an Apple developer certificate and provisioning profile. User photos require appropriate authorization for redistribution.
