# Massive bug review — AstroSleep

**Date:** 2026-07-09  
**Rev:** `main` @ `20d8e03`  
**Scope:** Android + iOS engines, audio, auth, monetization, affirmation pipeline, UX shells  
**Method:** Dual agent deep-dive + manual verification of P1s  

Severity: **P0** crash/data corruption · **P1** high correctness/security/product · **P2** medium · **P3** polish  

---

## Executive summary

No launch-blocking P0s found. **Core sleep product on Android is incomplete for affirmations**, **audio focus mishandles transient interruptions**, and **nightly sky JD ignores time-of-day** on both platforms. **Production purchases** remain stubbed on iOS and incomplete on Android (restore-only paywall). Prior audio/sprint fixes (fade volume, FGS, 13-sign Pisces, birth-time JD, DEBUG RC) hold.

| Bucket | Count |
|--------|------:|
| P0 | 0 |
| P1 | 7 |
| P2 | 10 |
| P3 | 5+ |

---

## P1 — High

### AS-P1-01 · Android transient audio focus never auto-resumes
| | |
|---|---|
| **Where** | `AudioService.pause` sets `userPaused = true`; focus listener `AUDIOFOCUS_LOSS_TRANSIENT` → `pause()`; on `GAIN` resumes only if `!userPaused` |
| **Impact** | Notification / call / another app steals focus overnight → soundscape stays paused until manual Resume |
| **Fix** | Split `userPaused` vs `pausedByFocus`; transient loss must not set user-pause |

### AS-P1-02 · Android affirmations never generated or spoken
| | |
|---|---|
| **Where** | `AppViewModel.getOrCreateAffirmation` exists; `TonightScreen` / `AstroSleepRoot` never call it. `startSession` only speaks non-empty `affirmationLayer.text` (composer leaves blank) or `cachedAffirmation` (never filled) |
| **Impact** | Product promise (spoken intention under ambient) is a no-op on Android. iOS wires `getOrCreateAffirmation` in `TonightView.beginSession` |
| **Fix** | On Begin: await affirmation then `startSession`; or inject script into `AffirmationLayer` at compose time |

### AS-P1-03 · Affirmation API body key mismatch (`userId` vs `user_id`)
| | |
|---|---|
| **Where** | Android `NetworkService` serializes `userId`; iOS sends `"user_id"` |
| **Impact** | Proxy likely expects snake_case → Android 400s or mis-attributes users when live |
| **Fix** | `@SerialName("user_id")` + shared fixture/test |

### AS-P1-04 · iOS auth refresh leaves user unauthenticated
| | |
|---|---|
| **Where** | `AuthService.checkExistingSession` / `refreshSession` — refresh stores tokens but never re-fetches `/user` or sets `currentUserId` / `isAuthenticated` |
| **Impact** | After access-token expiry + successful refresh, app behaves logged-out; affirmations use guest id |
| **Fix** | After refresh, call `/auth/v1/user` and set identity on MainActor |

### AS-P1-05 · Nightly / transit JD ignores time of day (both platforms)
| | |
|---|---|
| **Where** | Android `simplifiedCurrentPlacements` / `calculateTransits` use date-only `julianDayFor(Y,M,D)` with no hour fraction. Natal path correctly adds `dayFraction` |
| **Impact** | Moon ~13°/day → up to ~±6° error by evening; morning vs night rankings identical for longitudes |
| **Fix** | Full UTC JD from `dateEpochMs` including fractional day |

### AS-P1-06 · iOS production purchases are stubs
| | |
|---|---|
| **Where** | `RevenueCatService.swift` — no configure in release; purchase fails in `#else`; restore is sleep + free tier |
| **Impact** | App Store build cannot unlock paid tiers (DEBUG fake unlock remains DEBUG-only — correct) |
| **Fix** | Wire Purchases SDK + entitlement map like Android |

### AS-P1-07 · Android paywall has no purchase path
| | |
|---|---|
| **Where** | `PaywallDialog` — Not now + Restore only; `RevenueCatService` has no `purchase`/offerings API |
| **Impact** | Monetization dead even with RC API key |
| **Fix** | Offerings + purchase packages; primary CTA on paywall |

---

## P2 — Medium

| ID | Issue | Where | Impact |
|----|--------|-------|--------|
| AS-P2-01 | In-app pause does not update FGS / MediaSession notification | `AudioService.pause` vs `PlaybackService` | Shade still shows “Playing” |
| AS-P2-02 | MediaSession has no `Callback` | `PlaybackService` | Headset/BT media keys dead |
| AS-P2-03 | Notification “Play” while paused still fires `ACTION_PAUSE` and does not refresh to playing after resume-via-toggle | `PlaybackService` | Stale “Paused” UI after resume |
| AS-P2-04 | Composed EQ never applied on Android | `AudioService.loadCombo` | iOS has EQ; Android ignores |
| AS-P2-05 | iOS affirmation pitch not in Core Data | `StorageService` / model | Pitch resets on relaunch |
| AS-P2-06 | Lifetime price string ends in “/year” | iOS `displayPrice` | Misleading copy / compliance risk |
| AS-P2-07 | Birth time UI defaults force time always present | Android `OnboardingScreen` hour/min `"12"`/`"0"` | Ascendant computed when user doesn’t know time |
| AS-P2-08 | Android affirmation request no Bearer auth | `NetworkService` | Fails if proxy requires token |
| AS-P2-09 | GPS-for-transits can use (0,0) | `computeNightlyScore` | Null Island houses if toggle on without fix |
| AS-P2-10 | `enforceTier` never called from UI | `AppViewModel` | Incomplete freemium gates beyond layer caps |
| AS-P2-11 | TagEngine v3 iOS vs v4 Android | Engines | Cross-device combo mismatch |
| AS-P2-12 | Settings “Manage in Play Store” calls restore | `SettingsScreen` | Wrong action for label |

---

## P3 — Polish

| ID | Issue |
|----|--------|
| AS-P3-01 | Android TTS volume parameter ignored |
| AS-P3-02 | Library tab stub (Room ready, no UX) |
| AS-P3-03 | Shared `AVAudioFile` framePosition if same sound id twice (rare) |
| AS-P3-04 | Coarse ASC / house model (document or Swiss Ephemeris) |
| AS-P3-05 | Cosmic WebView / Xcode bundle membership residual (process) |

---

## Prior sprint status (regression check)

| Prior fix | Status |
|-----------|--------|
| Master volume after fade | Still good |
| Empty load error | Still good |
| FGS start | Still good |
| Playback speed / LFO waveforms | Still good |
| 13-sign / Pisces | Still good |
| Natal birth-time JD | Still good |
| Scaffold padding / Begin race | Still good |
| DEBUG RC only | Still good (iOS) |
| Speak affirmation on play | **iOS OK · Android broken / unwired** |
| Transit time-of-day | **Still open** |
| Production purchase | **Still open** |
| TagEngine v4 iOS | **Still open** |

---

## Suggested fix order

1. AS-P1-01 audio focus + AS-P2-01/02 notification/session sync  
2. AS-P1-02 + AS-P1-03 affirmation pipeline  
3. AS-P1-04 iOS auth refresh identity  
4. AS-P1-05 full UTC JD for nightly sky  
5. AS-P1-06/07 real RC purchase both platforms  
6. P2 parity (EQ, pitch, birth-time toggle, TagEngine v4)  
