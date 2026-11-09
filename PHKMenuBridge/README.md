# PHK Menu Bridge 3.1 — Developer Phan Anh Khôi

A **separate iOS ARM64 companion dylib** for the specific `ZaloModVIP.dylib` (SHA-256 `564b8539a690c988975b6b80d884c68a5a476482579b24a3eacac459a35a000d`) provided for analysis. This project **does not replace the original implementation of its hooks** or claim access to Zalo's private source code. It draws a new navigation UI and delegates allowlisted controls to methods in the already-loaded binary through Objective-C runtime selectors.

## What is built

- Full-height photographic panel, user-supplied monochrome wallpaper, user-supplied car portrait as administrator avatar, consistent card layout, and horizontally scrolling untruncated category chips.
- Three-finger single tap on a regular application window. No visible floating trigger. On load, the companion hides the legacy orb and disables its `show` selector when available.
- 8 categories: Tin nhắn; Font & Màu; Giao diện; ZBusiness; Media; Nhóm; Bot; Công cụ.
- 13 old toggle actions and 13 independent legacy actions bridged by selector allowlists. Original font/color button objects are reused **with their original tags**, not guessed or regenerated. TTL and bot prefix have C++17 input validation; text entries pass through the original text fields.
- One optional **Legacy fallback** button to expose all originally present functions if a mapping is unavailable. This is deliberately retained because eliminating it would falsely claim parity with a proprietary binary whose complete runtime behavior is untested.
- No cookie reading, exporting, network requests, telemetry, fake latency or fake success messages in the new bridge. The original dylib is still subject to its own limitations and risks.

## New in 2.1

- Objective-C method signature/arity checks for old class getters, toggle actions, and zero-argument actions. Unsupported toggle controls are disabled instead of blindly messaged.
- Group actions validate required fields, length (up to 1024 characters), and successful synchronization before invoking the old action.
- Clearer diagnostics when a method cannot be called. These checks reduce some ABI hazards but cannot make proprietary runtime code or server-side features inherently safe.

## New in 3.0
- C++17 three-finger state machine, duration/movement/cancellation checks and new unit tests.
- UIApplication sendEvent fallback works alongside existing UIWindow gesture recognizers. Native events are forwarded, never suppressed.
- A brief PHK MENU 3.1 banner at startup confirms the plugin was actually loaded.
- Rechecks the old orb suppression after windows and legacy classes initialize.
- A packaged dylib MUST be referenced by the app's Mach-O LC_LOAD_DYLIB entry; simply copying it into Frameworks is insufficient.

## What is NOT built or verified

- This ZIP is **not** reconstructed original Zalo source, is **not** a revised `ZaloModVIP.dylib`, and is **not** a signed or installable IPA.
- Build success verifies compile/link only. Live iPhone runtime compatibility, all hooked functions, server-side effects, third-party code-signing, and multiple concurrent accounts are **unverified**.
- This companion must be loaded alongside the original binary by an authorized iOS application integration. Do not publicly post proprietary third-party app binaries, authentication tokens or cookie exports.

## Build

The workflow `build-bridge.yml` targets `iphoneos`/`arm64`, with UIKit/Foundation/QuartzCore. The output consists of `PHKMenuBridge.dylib` and `PHKMenuResources.bundle`. It is **unsigned**. Adding it to any executable requires a permitted integration and valid iOS code signing. An executable that does not load this companion will not show the new UI.

## Quick verification

```sh
clang++ -std=c++17 -Wall -Wextra -Werror Core/PHKValidation.cpp Tests/validation_test.cpp -o /tmp/phk-check
/tmp/phk-check
python3 Tests/check_inventory.py
```

## Implementation notes

1. The `ZaloModViewController` class is discovered via `NSClassFromString`, and selectors are checked at runtime; missing selectors return a failure instead of a blind call.
2. `UIApplicationDidBecomeActiveNotification` and `UIWindowDidBecomeVisibleNotification` install a three-finger `UITapGestureRecognizer`, with `cancelsTouchesInView=NO`. This must be verified on real iOS 15.1+ hardware and against other gesture recognizers.
3. A small separate overlay `UIWindow` hosts the new controller while preserving the original key window for restoration. UIKit must remain on the main queue.
4. Toggle states are reread via old class-level getters after applying, without claiming server confirmation.
5. Background photography is stored as a separate bundled asset. Absence of the bundle falls back to a dark panel.
6. The original ``actionExportBotConfig`` reads session cookie values into the clipboard; the new bridge intentionally does **not** invoke it. Users should not upload or publish exported session data.
7. `ZaloFloatingButton show` is disabled only for UI presentation; other hooks remain in the legacy binary. This change can be reversed by removing the companion dylib and restoring the original signed app.

See `docs/LEGACY-COVERAGE.md` and `docs/inventory.json` for the static method inventory and coverage gaps.

## v3.1 — Three-finger recognition and packaging safety

- Tap exactly three fingers on the app's normal window; longer, moved and cancelled touches are rejected.
- UIKit recognizer and UIApplication event fallback both require three fingers.
- Verify LC_LOAD_DYLIB for PHKMenuBridge.dylib and check that the IPA is a complete ZIP archive before signing.
- Keep the original ZaloModVIP.dylib: this bridge is not a replacement for its proprietary hooks. Static offsets alone cannot reconstruct the original features.
- The previous v3 IPA was invalid as a ZIP; do not use that file.
