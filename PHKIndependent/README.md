# PHKIndependent 1.1 — Independent iOS glass menu

This is an unsigned ARM64 UIKit / Objective-C++ / C++17 dylib, not a replacement for the original ZaloModVIP functions.

## Interface
- Five-tab capsule dock: switches actual UITabBarController tabs through touch-and-drag if such a controller exists in the host app. Custom Zalo navigation is not automatically supported.
- Developer Phan Anh Khôi gradient label is raised by 24 points. Rainbow dock outline and label animate continuously, pausing under Low Power or Reduce Motion.
- Compact scrolling menu with VN/EN, seven curated colors, rainbow toggle, SF/Rounded/Serif and 10–18pt font controls. Color/font settings affect PHK, not all Zalo message bubbles.
- Separate composer screen with chat/group target selector, message editor, keyboard haptics, 1–60 second delay and cancel.

## Messaging contract
A host authorized to send messages must explicitly register PHKIndependentRegisterSender and PHKIndependentSetTargets. The library never extracts cookies or enumerates Zalo accounts; no host callback means no actual outgoing messages. Each send is opt-in to an approved recipient; max 10 pending, 1–60s delay, canceled if the app is backgrounded. No hidden repeated mass tagging or stealth @all.

Commands recognized locally: .menu, .sticker, .color random, .color 1–7, .font 10–18, .delay 1–60, .help. A host MUST forward chat text to PHKIndependentRunLocalCommand; these are not automatically intercepted from Zalo.

## zSticker AI
PHKIndependentStickerPNG makes a 512×512 clipped PNG with transparent rounded corners from a caller-supplied photo. It does not invoke Zalo's private zSticker AI, segment subjects via that service, register sticker packs or send sticker messages automatically. A host can receive the resulting PNG to upload through an approved API.

## Startup crash after removing ZaloModVIP
The Zalo executable in an existing modded IPA may still strongly link @executable_path/Frameworks/ZaloModVIP.dylib. If missing, dyld terminates the app before PHKIndependent loads. Run the read-only diagnostic:

    python3 PHKIndependent/Tools/diagnose_ipa.py "Lưu trữ.zip" --crc

The script identifies missing strong Mach-O imports; it does not change binaries or defeat iOS code signing. Copying a new dylib into Frameworks alone will not make it load. An authorized host build with correct imports, signatures and runtime testing is required.

## Verification
The GitHub Actions workflow runs C++17 unit tests, Python synthetic IPA/Mach-O tests and compiles for iOS ARM64, asserting exported symbols and absence of a direct dependency on ZaloModVIP. An actual iPhone runtime test and permitted app signing are still outstanding.
