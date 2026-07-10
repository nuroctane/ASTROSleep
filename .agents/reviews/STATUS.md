# Review resolution ledger

**Convention:** review documents in this directory are immutable snapshots of
the tree at their pinned rev. They are never edited after the fact. Every
item's *current* status lives here instead. Agents: consult this ledger before
acting on any review; re-fixing landed items wastes cycles and risks
regressions.

Format: one section per review, one row per item, status verified against
source at the rev noted.

---

## BUG_REVIEW_2026-07-09_massive.md

Review pinned at `20d8e03`. Statuses below verified against source at
`e65f771` (fix commits: `892c47c`, `55d88a6`).

| Item | Status | Where verified |
|------|--------|----------------|
| AS-P1-01 transient focus never auto-resumes | ✅ fixed | `AudioService.kt`: `userPaused` / `pausedByFocus` split, `pause(fromUser:)` |
| AS-P1-02 Android affirmations never spoken | ✅ fixed | `AppViewModel.startSession`: `ensureAffirmation` awaited, script injected into `affirmationLayer` |
| AS-P1-03 `userId` vs `user_id` body key | ✅ fixed | `NetworkService.kt`: `@SerialName("user_id")` |
| AS-P1-04 iOS refresh leaves user logged out | ✅ fixed | `AuthService.swift`: post-refresh `GET /auth/v1/user` sets identity on MainActor |
| AS-P1-05 nightly/transit JD date-only | ✅ fixed both platforms | `julianDayFromEpochMs` (Kotlin) / `julianDayFromDate` (Swift) with day fraction |
| AS-P1-06 iOS production purchases stubbed | 🔴 **open** | `RevenueCatService.swift`: SDK call commented, release path errors. Blocked on RC keys + SPM on a Mac |
| AS-P1-07 Android paywall no purchase path | ✅ fixed | `PaywallDialog` CTA + `RevenueCatService.purchaseSubscription` |
| AS-P2-01 pause does not update notification | ✅ fixed (sprint) | `PlaybackService` / MediaSession sync per BUGFIX_SPRINT_NOTES |
| AS-P2-02 MediaSession no Callback | ✅ fixed (sprint) | MediaSessionCompat shell + callbacks |
| AS-P2-04 composed EQ never applied | ✅ fixed | `AudioService.loadCombo`: per-layer system Equalizer |
| AS-P2-06 lifetime price "/year" suffix | ✅ fixed | `RevenueCatService.swift` `displayPrice` |
| AS-P2-07 forced birth time defaults | ✅ fixed | Onboarding "I know my birth time" toggle |
| AS-P2-11 TagEngine v3 on iOS | ✅ fixed | iOS `TagEngine.swift` v4 + Android-identical fingerprint jitter |
| AS-P2-12 "Manage in Play Store" calls restore | ✅ fixed | `SettingsScreen`: separate `onRestore` / `onManageSubscription` |
| AS-P3-02 Library tab stub | ✅ fixed | `LibraryScreen` save/play/delete via Room |
| Remaining P2/P3 not listed | see review | unchanged unless noted above |

## IMPROVEMENT_SPEC_2026-07-09.md (external spec, this ledger's origin)

| Item | Status |
|------|--------|
| IMP-01 privacy manifest consolidation | ✅ this patch series |
| IMP-02 entitlements consolidation | ✅ this patch series |
| IMP-03 iOS production purchases | 🔴 open (= AS-P1-06; needs Mac + RC keys) |
| IMP-04 parity guard | ✅ this patch series (`tools/check_parity.py`) |
| IMP-05 shared-asset sync | ✅ this patch series (`tools/sync_shared.py`) |
| IMP-06 GitHub Actions CI | ✅ this patch series (`.github/workflows/ci.yml`) |
| IMP-07 cross-platform engine goldens | 🔴 open (generate fixture from Android engine; needs Gradle) |
| IMP-08 XcodeGen project definition | 🔴 open (needs Mac) |
| IMP-09 AstroSleepCore SwiftPM + Linux `swift test` | 🔴 open (after IMP-08) |
| IMP-10 resolution ledger convention | ✅ this file |
| IMP-11 root LICENSE | ✅ this patch series |
| IMP-12 Three.js pin | ✅ this patch series (r160 + sha256 in cosmic README) |
| IMP-13 tags + unified versioning | 🔴 open (repo action, not a diff) |
| IMP-14 `.agents/README` docs/ row drift | ✅ this patch series |
