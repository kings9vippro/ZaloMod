# Repack a permitted original Zalo IPA in GitHub Actions

This workflow packages a real app archive supplied by the user; it does **not** compile the unrelated SwiftUI demo.

1. Use a **private repository** to avoid distributing third-party application binaries.
2. Open Actions > Repack Real Zalo IPA (Private Repo Only) > Run workflow.
3. Paste a direct HTTPS URL to an app archive you have permission to modify. An App Store page is NOT an IPA download.
4. Optionally provide its SHA-256 and select independent_only=true only when the source no longer strongly links ZaloModVIP.
5. Download the artifact, inspect the build/dependency reports, and sign the unsigned IPA using legitimate Apple signing.

The workflow stops rather than guessing native function offsets or removing a mandatory library. The new dylib does not re-create proprietary ZaloModVIP hooks.

Local alternative: PHKIndependent/Tools/repack_zalo_ipa.py.