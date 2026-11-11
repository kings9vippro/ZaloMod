# PHKIndependent v1 — UIKit floating glass dock (ARM64)

This is an **independent** iOS Objective-C++/C++17 dynamic library. It does not link, call or depend on \`ZaloModVIP.dylib\`.

## Confirmed implementation scope

- Conditionally overlays a native **five-tab \`UITabBarController\`**, preserving the host controller's real \`selectedIndex\` and content.
- The compact dock uses a material blur background, a selected capsule, system icons, haptics and horizontal finger-drag navigation. It never swaps host view controllers directly.
- A small **Developer Phan Anh Khôi** label is drawn **inside the app**. This is not a system Dynamic Island/status-bar modification. Apple fires screenshot notifications only *after* capture, so there is no claim to add this label just-in-time.
- A compact local settings overlay supports VN/EN, 7 curated colors, random color without invalid RGB values, and an adjustable 1–60-second delivery delay.
- Local PNG sticker function crops an image to **512×512 with rounded transparent corners**; this is **not** Zalo AI generation, background separation, sticker-pack registration or message reply integration.
- The \`.sticker\`, \`.color random\`, \`.help\` command parser only recognizes text. No network, Zalo chat interception or automatic account access is present.
- Delayed send is opt-in through an **explicit authorized host callback**. At most 10 jobs can be scheduled, each with 1–60 s delay. It will not send when the app is backgrounded.

## Important compatibility constraint

**The compiled library can only be loaded into a host app with the correct Mach-O load command and a valid code signature.** A dylib copied into \`Frameworks\` is not automatically executed.

The automatic dock installer only activates when the host genuinely has a **five-tab \`UITabBarController\`**. If the installed Zalo build uses a custom navigation container, this library will NOT replace its tabs. No proprietary offset is guessed. Any custom navigation implementation requires an authorized integration point or a verified, version-pinned layout adapter.

This implementation does **not** replicate ZaloModVIP's private hooks, remove server-side restrictions, or claim live Zalo bot or AI sticker support.

## Files and build

- \`Core/PHKCore.hpp/.cpp\` — bounds-safe tab navigation, palette, delay guard, command parser.
- \`Sources/PHKIndependent.mm/.h\` — UIKit dock, compact settings, local PNG sticker rendering and opt-in delivery callback.
- \`Tests/core_test.cpp\` — portable C++ tests.
- \`.github/workflows/phk-independent.yml\` — compile \`PHKIndependent.dylib\` for iOS ARM64 and upload unsigned artifact.

Use the compiled dylib only in an app you are authorized to modify. Sign the modified app and dylib appropriately, and verify the runtime log and gestures on a test device.
