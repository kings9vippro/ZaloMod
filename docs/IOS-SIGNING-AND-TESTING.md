# iOS device signing and reproducible testing

This repository contains **first-party source** for PHKControl and a self-contained PHKStandalone iOS dylib. It does not contain Zalo proprietary implementation.

## From code to a device-installable IPA

1. On a Mac, obtain Xcode and XcodeGen. Run `xcodegen generate --spec project.yml`.
2. Open `PHKControl.xcodeproj` in Xcode. Choose a unique Bundle Identifier that belongs to your Apple developer team, select your team under Signing & Capabilities and enable Automatic Signing.
3. Connect your iPhone, trust your Mac, select the iPhone as the run destination, and use Product → Run to validate gesture/UI behavior.
4. For a distributable IPA, choose Product → Archive then Distribute App and select the distribution option supported by your Apple team and device profile. Export the IPA using Xcode.
5. On the iPhone, verify opening the PHKControl UI by a three-finger tap, switching settings, closing and reopening the panel, and persistence after app restart.
6. If testing PHKStandaloneKit in a host application you own, explicitly link PHKStandalone.dylib in its Xcode target, embed/sign it, and use its exported `PHKStandaloneOpen()` from the host. A dylib merely copied to Frameworks is not automatically loaded.

## CI coverage and limitations

- GitHub Actions compiles iOS simulator and device targets and verifies the **unsigned IPA** ZIP structure and arm64 executable. A successful CI run does not prove runtime compatibility.
- Signing identities/provisioning profiles are not present in this repository or in GitHub Actions and **must not be committed as files or printed in logs**.
- If using Apple code-signing credentials with an approved CI workflow, store them as GitHub Actions encrypted secrets, restrict the workflow to trusted branches, and avoid pull requests from untrusted forks.
- Do not replace or redistribute another organization's app bundle unless licensed and authorized. There is no safe offset-only shortcut for source-level feature parity with a proprietary dylib.

## Diagnostics for an authorized host

- `PHKStandaloneVersion()` returns the build version.
- `PHKStandaloneLoaded()` verifies the library was initialized in-process.
- `PHKStandaloneOpen()` opens its standalone settings panel without any gesture.
- If the diagnostics are absent, first check the host executable's Mach-O load commands, dynamic loader logs, embedded library path, and signing; do not debug UIKit until load is confirmed.
