# PHK Standalone Kit 1.0 — Developer Phan Anh Khôi

This is **original, standalone source** for a single ARM64 iOS dynamic library. It provides a dark-glass settings panel, a passive 3-finger tap gesture, persistent local preferences, and diagnostic exported functions. User-provided car avatar and monochrome wallpaper are embedded directly into **one .dylib** using Mach-O data sections.

It does **not** contain Zalo proprietary code, original ZaloModVIP hooks, cookie/session readers, ad bypasses, fake admin functions, or replacements for private messenger APIs. It **cannot** honestly claim compatibility with, or complete feature parity with, ZaloModVIP. No dynamic hooking of unknown private functions is performed.

## Design principles

- One dylib: no companion resource bundle is required.
- Functional local toggles: persisted under \`dev.phananhkhoi.standalone.*\` keys.
- Minimal UIKit surface: photo header, high contrast cyan/graphite, consistent cards, no floating Z orb.
- No telemetry or network requests. No credential or cookie handling.
- \`PHKStandaloneOpen()\`, \`PHKStandaloneVersion()\`, and \`PHKStandaloneLoaded()\` are exported for allowed host integration and runtime diagnosis.
- Only a host that **actually links/loads this dylib** can use it. Putting a file in Frameworks does not cause injection.
- No claim of bypassing iOS code signing or entitlement requirements. The build output is **unsigned**, meant for a first-party test host that you can legitimately sign.

## Build

Run the repository workflow \`Build PHK Independent Dylib\` on a macOS runner. It compiles the C++ core with \`-Wall -Wextra -Werror\`, then compiles the Objective-C++ iOS library with stack protector, exports and Mach-O image section checks.

## Feature coverage status

| Category | Status |
| --- | --- |
| UI, three-finger menu, local settings, embedded photos, diagnostics | Implemented in source; device test pending |
| Original ZaloModVIP hooks: anti-undo, ghost seen, TTL, business, account bot/group actions | **Not implemented** |
| One dylib replacing original third-party binary with feature parity | **Not achieved** |
| Reproducible iOS arm64 compilation | Covered by CI |
| Signed installable IPA | Requires an owned app and valid signing identity/provisioning profile |

Do not replace the old dylib in a working app on the assumption that these private features have been reimplemented. Use a test host and runtime logs before distribution.

## Independent host IPA smoke test

The workflow also builds `PHKStandaloneHost-UNSIGNED.ipa`, a **first-party diagnostic app** with a native UIKit scene lifecycle. Its executable links `@rpath/PHKStandalone.dylib` explicitly and the IPA includes the compiled dylib inside Frameworks. This verifies loader linkage and archive integrity at build time; it is not a Zalo IPA and cannot exercise third-party messenger functionality.

After signing this test host with a legitimate Apple developer profile, run it on an iPhone. The host displays the native dylib version and a button to call `PHKStandaloneOpen()`, allowing the menu rendering to be tested separately from the three-finger gesture.
