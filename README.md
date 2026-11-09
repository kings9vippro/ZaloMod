# Developer Phan Anh Khôi — iOS Control Panel (Source)

**Version:** 1.0.0. **Project type:** standalone original SwiftUI/UIKit/C++ UI demo.

This repository is **not the Zalo source code**, **not an altered Zalo client**, and **not an installation-ready signed IPA**. The user's provided 242 MB archive contains an already-compiled third-party application and a compiled tweak library, not an Xcode project. We deliberately do **not** publish third-party proprietary executables, SDK binaries, cookies, session files, or embedded secrets.

## What is implemented

- Original dark translucent settings panel with readable four-tab 2×2 navigation, consistent SF Symbols and clean typography.
- Brand: **Developer Phan Anh Khôi**; no unrelated developer names or misleading app logos in *new UI code*.
- Passive UIKit `UITapGestureRecognizer` with `numberOfTouchesRequired = 4`; tapping four fingers toggles the panel **inside this app**. No persistent floating menu button.
- SwiftUI settings preview, local preference state; no real Zalo message / account modification or API calls.
- Minimal Objective-C++ bridge to a C++17 `normalizeTTL` implementation with overflow checks and a portable unit test.
- GitHub Actions macOS workflow generating an Xcode project with XcodeGen; builds iOS simulator and unsigned iOS device app then packages an **unsigned** IPA artifact.

## Add the two supplied personal photos

The GitHub workflow works with fallback graphics and no external image files. The locally downloadable complete source ZIP includes user-supplied photos under `iOS/Resources/Assets.xcassets/MenuWallpaper.imageset/menu-wallpaper.jpg` and `AdminCar.imageset/admin-car.jpg`. For an identical image-backed build from GitHub, upload both image files and update each imageset `Contents.json` to reference its filename, or use the complete source ZIP as the starting point. **Do not upload other people's private photos or proprietary assets without permission.**

## Build (macOS, Xcode and XcodeGen)

```bash
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild -project PHKControl.xcodeproj -scheme PHKControl -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Run the C++ tests on any machine with C++17:

```bash
clang++ -std=c++17 Core/Settings.cpp Core/tests/settings_test.cpp -o /tmp/phk_settings_test
/tmp/phk_settings_test
```

To install on an actual iPhone, you must use an Apple Development/Distribution certificate and provisioning profile tied to your signing team. An unsigned `.ipa` is a packaging artifact, not an installable build. A signed IPA of a modified third-party Zalo application cannot be produced or verified from this source demo.

## Security and release notes

- No credentials or signing files in Git.
- No session or cookie access in this app.
- TTL normalization uses integer overflow protection in C++.
- Code obfuscation is **not** a substitute for code signing or secrecy; do not put private keys in client binaries.
- Four-finger gestures may conflict with iOS accessibility or system gestures on particular devices; test on device.
- Design prototype/UI only: do not interpret toggle settings as implemented behavior in other apps.

## Rights

The code in this repository is original, released under MIT. Apple, Zalo, and other names and trademarks remain the property of their respective owners. The user-provided photos are excluded from this license and should be distributed only with the owner's authorization.


## PHK Standalone / original first-party UI build

The PHKControl iOS sample uses a three-finger gesture and is a first-party UI demonstrator; it is not Zalo and does not reproduce ZaloModVIP. Version 1.1.0 ships as an unsigned IPA artifact until you export it using a certificate and provisioning profile for your Apple development team. The separate `PHKStandaloneKit/` module builds a single self-contained dylib with two embedded images. Its local UI controls do not provide third-party messenger hooks.

See `docs/IOS-SIGNING-AND-TESTING.md` for the device-testing procedure.
