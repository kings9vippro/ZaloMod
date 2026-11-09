# PHK Native Navigation 2.0

## Scope
This code builds an **original iOS application**. It does not modify the Zalo App Store binary, sign on Zalo Group's behalf, patch private functions, or replace a third-party IPA. The Zalo App Store listing is a distribution page, not editable source or an input IPA.

## Layout
- Five native pages: Tin nhắn, Danh bạ, Khám phá, Nhật ký, Cá nhân.
- Horizontal swipes use SwiftUI page navigation; bottom buttons and drag gestures use a shared selection state.
- The glass tab bar is native \`glassEffect\` on iOS 26+, with a material fallback on iOS 16–18 (and iOS 19–25 where applicable).
- A spring-based selector uses a matched geometry indicator; Reduce Motion disables decorative animation.
- The menu remains available through the **three-finger tap** and the Profile settings entry, without a dynamic library.
- The provided background and profile images use \`scaledToFill\`, clipped in finite rounded rectangles, and do not stretch to device bounds.

## Architecture
- \`iOS/Sources/NativeShell/PHKNativeShell.swift\`: navigation, presentation, sample content, accessibility.
- \`iOS/Sources/ContentView.swift\`: entry point, legacy settings sheet, native three-finger recognizer.
- \`iOS/Sources/Bridge/PHKBridge.mm\`: minimal Objective-C++ bridge, safe integer conversions.
- \`Core/Settings.cpp\`: C++17 saturating TTL and deterministic tab-drag step logic.
- \`Core/tests/settings_test.cpp\`: edge and overflow tests.

## Runtime honesty
The sample conversation/contact/feed rows are local placeholder data; actions are previews. All previous settings controls remain accessible but third-party message behavior such as anti-undo, seen-state changes, cookie reading, etc., is **not implemented**. Native compilation does not imply compatibility with Zalo proprietary APIs.

## Build and signing
The \`Build iOS UI Demo\` workflow builds the simulator app and unsigned ARM64 iPhone app, packages \`PHKControl-UNSIGNED.ipa\`, verifies the archive and explicitly checks that there is no \`PHKStandalone.dylib\` dependency. A personal Apple provisioning profile and signing certificate are required before installing on an iPhone. No working Zalo replacement is claimed.
