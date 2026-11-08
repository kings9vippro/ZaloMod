# Feature parity audit — 08 Nov 2026

**Baseline:** static Objective-C method list and strings extracted from original `Frameworks/ZaloModVIP.dylib` in user-provided archive. This documents **routing**, not functional success. Each row is either `bridged`, `original-option-buttons`, `original-fallback`, or `not verified`. The original dylib is still required.

## UI sections

| Legacy section | New navigation | Preservation |
|---|---|---|
| Tin nhắn | Tin nhắn | Anti-undo, HD, seen, typing, anti-rain, TTL controls routed to original |
| Font | Font & Màu | Font/color uses live original UIButton objects (their actual tags retained); size via original field |
| ZBusiness | ZBusiness, Media, Giao diện | Client-side business/zStyle/adblock/media/RBT, profile music, chat wallpaper |
| Nhóm | Nhóm | Original send/join/kick/leave actions, text fields synchronized |
| Admin | Công cụ, Nhóm | Original account-lock preview, group controls; remaining options through legacy fallback |
| Bot | Bot | Start, stop, prefix, refresh; command reference/export via original fallback only |

## Toggles bridged (13)

1. `toggleAntiUndo:` / `isAntiUndoEnabled`
2. `toggleBugOriginal:` / `isBugOriginalEnabled`
3. `toggleGhostSeen:` / `isGhostSeenEnabled`
4. `toggleHideTyping:` / `isHideTypingEnabled`
5. `toggleAntiRain:` / `isAntiRainEnabled`
6. `toggleChatBg:` / `isChatBgEnabled`
7. `toggleBugZBusiness:` / `isBugZBusinessEnabled`
8. `toggleBlockZStyle:` / `isBlockZStyleEnabled`
9. `toggleBugZLStyle:` / `isBugZLStyleEnabled`
10. `toggleAdBlock:` / `isAdBlockEnabled`
11. `toggleUnlimitedMedia:` / `isUnlimitedMediaEnabled`
12. `toggleUnlockRBT:` / `isUnlockRBTEnabled`
13. `toggleProfileMusic:` / `isProfileMusicEnabled`

## Actions and other controls

| Capability | Method(s) | Bridge route | Status |
|---|---|---|---|
| TTL apply | `actionApplyTTL`; `ttlSegment`; `txtTTLValue` | guarded value, unit + original action | Bridged; actual TTL behavior unverified |
| Font selection | `fontButtons`; `fontButtonTapped:` | original UIButton instances | Bridged; visual options dependent on original UI loading |
| Color selection | `colorButtons`; `colorButtonClicked:` | original UIButton instances | Bridged; option retrieval unverified |
| Font size | `txtFontSize`; `actionApplyFontSize` | guarded input + original action | Bridged; preset mode dependent on legacy |
| Chat background | `actionPickChatBackground`; `actionRemoveChatBackground` | original picker | Bridged |
| MP3 picker/play | `actionPickProfileMP3`; `actionToggleTestPlay` | original picker/player | Bridged |
| Song/artist metadata | `txtSongName`; `txtArtistName` | original text fields | Bridged; update persistence unverified |
| Send group message | `actionSendMessage` | original text fields + action | Routed; server outcome unverified |
| Join group | `actionJoinGroup` | original text fields + action | Routed; server outcome unverified |
| Kick member | `actionKickMember` | original text fields + action | Routed; server outcome unverified |
| Leave group | `actionLeaveGroup` | original action | Routed; server outcome unverified |
| Bot start/stop | `actionStartBot`; `actionStopBot` | original action | Routed; runtime status needs device validation |
| Bot account refresh | `botRefreshAccountInfo` | original action | Bridged |
| Bot command prefix | `txtBotPrefix`; `actionApplyBotPrefix` | validated prefix + original action | Bridged |
| Bot command list | legacy `setupTabs` | optional full-original-menu fallback | Available only through fallback |
| Export bot config/cookies | `actionExportBotConfig` | **not called by new bridge**; original fallback only | Sensitive: may copy cookies to clipboard |
| Account lock demo | `actionPreviewLockedAccount` | original action | Routed; clearly described as simulation |
| Direct command router `!kick`/`!ping` etc. | `processBotIncomingMessage:...` | original binary unchanged | Not reimplemented; static behavior may use canned responses |
| Hook installation/compatibility | `_initZaloModVIP`, `_hook_*` | original binary unchanged | Cannot verify runtime from symbols |
| Multiple Zalo accounts/tasks | no independent session manager detected | no new network/session logic | **Not implemented** |

### Reliability and accuracy

- No false success labels: new menu says “Đã gọi xử lý gốc” where the server outcome is unknown.
- Missing class/methods result in an explicit message rather than unguarded dynamic message sends.
- Old export-cookie handler has no direct button in the new menu.
- The original legacy panel may still expose old labels and brand names; this bridge does **not** rewrite binary strings.
- Four-finger gesture and resource loading require an on-device integration test before shipping.
