# Zalo PHK — app demo icon and build checklist

The existing branch builds two separate things:

1. **PHKIndependent** is an unsigned ARM64 dylib for an authorized host. It is not official Zalo and does not provide full proprietary chat functions.
2. **Zalo PHK** is the separate first-party UI demonstration app, bundle ID dev.phananhkhoi.control. This app has sample local screens and does not authenticate to Zalo.

## App label and icons
The native demonstration app's home-screen name is now **Zalo PHK**. The icon generator uses the user-provided vehicle image in iOS/Resources/Assets.xcassets/AdminCar.imageset and overlays the distinct PHK monogram. It does not use the official Zalo icon.

The icon source stays in the repository; build assets are recreated deterministically on macOS using:

    swift scripts/generate_phk_icons.swift iOS/Resources/Assets.xcassets/AdminCar.imageset/admin-car.jpg iOS/Resources/Assets.xcassets/AppIcon.appiconset
    python3 scripts/validate_phk_icons.py iOS/Resources/Assets.xcassets/AppIcon.appiconset

The 12 exported RGB PNGs cover device roles and marketing. The validator checks exact dimensions, signatures, absence of alpha and unique file names.

Then:
    
    xcodegen generate --spec project.yml
    xcodebuild -project PHKControl.xcodeproj -scheme PHKControl -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

GitHub Actions generates the icons and exports **an unsigned IPA** after successful Xcode compilation. The IPA is not signed, is not a modification of the App Store Zalo binary, and needs valid Apple signing and on-device verification.
