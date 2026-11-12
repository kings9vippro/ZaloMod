# PHK 1.2

Built ARM64 at commit 7a6c05216e3d2f29db58d2eb32c2f29f90c098a7; GitHub Actions run 43161367434 passed C++ tests, Python diagnostics and iOS compilation.

- Dock pill follows the finger; selection commits on release and cancellation restores selection. Host shouldSelect/didSelect callbacks are respected.
- Passive touch rings do not consume touches. Reduce Motion and Low Power disable the effect.
- Editable UITextViews within KBChatInputComponentView, ZAInputView or ZACustomInputView receive typing attributes on Zalo build 260901802. Class names were observed in the supplied executable; actual runtime hierarchy remains unverified. IME marked text is excluded. Existing message content is not rewritten.

No private function offsets have been verified or patched. No claim of recipient-visible rich text, native sticker registration, automated calling or bot-command integration is made.

The packaged IPA includes PHKIndependent.dylib and an explicit load command, without ZaloModVIP. ZIP CRC and load-command structure were checked. Requires signing and device testing. Open the menu with a three-finger tap. The original host bundle identifier is retained.
