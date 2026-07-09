# Bugfix sprint (post thorough review)

Date: 2026-07-08

## Android
- **AudioService**: restore master volume after fade; empty-load error; start/stop `PlaybackService` FGS; apply playback speed; LFO respects waveform; safer audio focus; TTS init queue
- **PlaybackService**: START/STOP actions for foreground lifecycle
- **AstrologicalEngine**: equal 13-sign sectors (Pisces reachable); birth-time fractional JD; houses when time known; real new-moon epoch (2000-01-06); UTC for transit JD
- **AppViewModel**: birth lat/lng for transits; surface load errors; speak affirmation cache on play
- **Room**: no silent destructive migrate on upgrade (fail loud unless downgrade)
- **Onboarding**: optional null birth time

## iOS
- **AudioService**: `@MainActor`; ambient **looping** via reschedule; format from file; common run-loop timers; timer ≤0 cancels; volume restore after fade; female/male voice fix; interruption on main; stop→play path
- **PlaybackView**: speak cached affirmation; stop uses play not resume; session log intention no longer = script
- **AstrologicalEngine**: birth-time JD fraction; 13 equal signs; houses; new-moon epoch; deterministic rulers (no random)
- **AppState**: guest affirmation path; local TZ cache key; transit coords from birth when GPS off
- **Auth**: restore `currentUserId` on session; Keychain delete without value match
- **Storage**: affirmation upsert; batch delete merges into context
- **RevenueCat**: simulated purchase **DEBUG only**
- **Sound**: decode `bundleFilename`; safe dict for duplicate ids

## Still open (next)
- Ship real audio assets / CDN cache pipeline
- iOS Core Data columns for pitch/theme
- Full StoreKit/RevenueCat production wiring
- Exact-alarm + notification receiver for bedtime
- Port TagEngine v4 personalization to iOS
