# Stability research

191 controller methods and 63 hook symbol offsets are indexed from the original user-supplied dylib. Offsets are static symbols, NOT safe live addresses under ASLR. The enhanced adapter checks main-thread access, argument arity, return type, and input before a call. The runtime compatibility function only checks ABI presence, not whether features operate correctly. The original private hook code remains unavailable and is not rebuilt. No login cookie or account token is exported.
