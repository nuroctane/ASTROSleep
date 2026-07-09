# Bugfix sprint + completion notes

Dates: 2026-07-08 → 2026-07-09

## Android (completion pass)

- **AudioService**: per-layer **system Equalizer** from `EQProfile` (bass/mid/treble); suspend `loadCombo` (no race with play); CDN **SoundCacheService** (bundle → filesDir → download); volume restore after fade; FGS lifecycle; LFO waveforms; audio focus
- **LibraryScreen**: save / play / delete combos via Room
- **GeocodingService**: city → lat/lng; onboarding lookup + empty-coords geocode on submit
- **NotificationService**: bedtime schedule, session-complete, **BootReceiver** reschedule
- **AppViewModel**: guest affirmation `user_id` fallback; library + bedtime + transit toggle; sound prefetch
- **Tests**: fingerprint determinism + tier maxLayers golden cases (all unit tests green)

## iOS

- **TagEngine v4** + ComboComposer (parity with Android)
- **TonightView**: mono fingerprint; auto-generate on appear
- **GeocodingService**: empty query, trim, lookup-failed mapping
- **AudioService**: existing EQ + CDN download path verified

## Still open (you)

- Real audio binaries / live CDN
- Production RevenueCat + store accounts
- Full Supabase OAuth / magic link keys
- Swiss Ephemeris
- Cosmic product modes beyond systems WebView
- Device / TestFlight / Play testing

## Resolved historical

- ~~TagEngine v4 iOS port~~
- ~~Android EQ apply~~
- ~~Library stub~~
- ~~Guest affirmation early return~~
- ~~Transit JD time-of-day~~ (prior sprint)
