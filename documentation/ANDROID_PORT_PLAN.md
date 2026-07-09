# AstroSleep Android Port Plan

**Source:** `AstroSleep-iOS/` (v3.2.0, SwiftUI + MVVM + Combine)  
**Target:** `AstroSleep-Android/` (Kotlin + Jetpack Compose + MVVM + StateFlow)  
**Repo:** https://github.com/nuroctane/ASTROSleep.git · branch `main`  
**Last audited:** 2026-07-08

---

## 1. Product snapshot (what we're porting)

Native sleep app with:

- Sidereal 13-sign natal chart + nightly transit scoring (Sharatan ayanamsha)
- 12-dimensional tag engine → Fire/Earth/Air/Water matching
- Multi-layer ambient audio (EQ, LFO, per-layer speed) + TTS affirmations
- AI affirmations via Cloudflare proxy
- Supabase Auth (+ platform sign-in)
- RevenueCat Free / Basic / Pro
- Local-only birth data (never uploaded)
- Onboarding → Tonight → Playback → Library → Sounds/Combo → Settings/Paywall

**Scale:** ~28 Swift sources · ~300 KB logic · 23 sounds in `sounds_manifest.json` · shared backend/CDN

---

## 2. Stack mapping (iOS → Android)

| Concern | iOS | Android |
|--------|-----|---------|
| UI | SwiftUI | Jetpack Compose + Material 3 |
| State | `ObservableObject` + Combine | `ViewModel` + `StateFlow` / `SharedFlow` |
| Nav | Custom `AppScreen` / tabs | Navigation Compose |
| Audio | AVAudioEngine multi-node | Media3 (ExoPlayer) + custom mixer / Oboe if LFO/EQ fidelity needs it |
| TTS | `AVSpeechSynthesizer` | `android.speech.tts.TextToSpeech` |
| DB | Core Data | Room |
| Secrets / tokens | Keychain | EncryptedSharedPreferences / Keystore |
| Auth | Supabase + Sign in with Apple | Supabase Kotlin + Credential Manager / Google Sign-In |
| Subs | RevenueCat iOS | RevenueCat Android (`purchases-android`) |
| HTTP | URLSession | OkHttp / Ktor |
| Geocode | CoreLocation geocoder | Android Geocoder / Play Services |
| Location permission | CLLocationManager | Activity Result + fine/coarse location |
| Push / bedtime | UserNotifications | NotificationCompat + AlarmManager / WorkManager |
| Analytics / crash | PostHog + Sentry (planned) | PostHog Android + Sentry Android |
| Config | `AppConfig` + xcconfig | `BuildConfig` / `local.properties` (never commit keys) |
| Sounds | Bundle → cache → CDN | `assets/` / filesDir → CDN |
| Min OS | iOS 26 SDK target | minSdk 26 · targetSdk 35 · compileSdk 35 |

**Not using KMP for v1 Android** — pure native mirror of iOS keeps the week unblocked. Shared Kotlin Multiplatform engines can be extracted later if dual-platform maintenance becomes painful.

---

## 3. Package layout (mirrors iOS)

```
AstroSleep-Android/
├── app/
│   ├── build.gradle.kts
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── assets/sounds/          # sounds_manifest.json (+ optional .m4a)
│       ├── java/com/astrosleep/app/
│       │   ├── AstroSleepApp.kt
│       │   ├── MainActivity.kt
│       │   ├── ui/                 # Compose screens (Views/)
│       │   ├── state/              # AppState / ViewModels
│       │   ├── core/
│       │   │   ├── config/         # AppConfig
│       │   │   ├── engine/         # AstrologicalEngine, TagEngine
│       │   │   └── model/          # types, ElementVector, Sound, User models
│       │   ├── data/               # Room entities + DAOs + repositories
│       │   ├── service/            # Audio, Auth, Network, RC, Notify, Theme, Geo
│       │   └── di/                 # Hilt modules
│       └── res/
├── gradle/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
└── local.properties              # SDK path + secrets (gitignored)
```

---

## 4. Port priority (dependency order)

### Phase A — Foundation (day 1–2)
1. Gradle project, Compose shell, theme, navigation graph
2. Models + JSON: `ElementVector`, `Sound`/`SoundTags`, `UserProfile`, `Combo`, chart types
3. Port `TagEngine` + `AstrologicalEngine` (+ unit tests vs known iOS fixtures)
4. Room schema (profile, saved combos, session logs, affirmation cache)
5. `SoundLibrary` from `assets/sounds/sounds_manifest.json`

### Phase B — Core loop (day 2–4)
6. `AppState` / `TonightViewModel` (nightly score cache-by-day, auto combo)
7. Onboarding (birth data + geocode + chart + base score)
8. Tonight home + Playback UI
9. **AudioService** — multi-track loop, master volume, sleep timer fade, interruption handling
10. Sound library + Combo builder

### Phase C — Platform services (day 4–5)
11. NetworkService (AI proxy + CDN download cache)
12. AuthService (Supabase)
13. RevenueCat + Paywall (restore purchases required)
14. Notifications / bedtime reminder
15. Settings + theme

### Phase D — Polish / store readiness (day 5–7)
16. Background playback (`MediaSession` + foreground service)
17. Privacy / Play Data safety form notes
18. Offline path for bundled sounds
19. Instrumentation + crash reporting
20. Internal testing track

---

## 5. Hard problems (plan time for these)

| Risk | Why | Mitigation |
|------|-----|------------|
| Multi-track ambient + LFO + EQ | AVAudioEngine graph ≠ ExoPlayer out of the box | Start with N ExoPlayers + volume LFO; escalate to Media3 `AudioProcessor` / Oboe only if needed |
| Background audio when screen off | Sleep app rejection / 1-star reviews if audio dies | Foreground `MediaSessionService`, battery exemptions docs, physical device soak tests |
| Astro math parity | Simplified ephemeris must match iOS recommendations | Golden tests: same birth/date → same `ElementVector` + ranked top-N sound IDs |
| Birth data privacy | Product promise: never leaves device | Room only; no analytics properties for lat/lng/birth |
| Secrets | Same as iOS hardening | `local.properties` / CI secrets → `BuildConfig`; empty defaults in repo |
| Sign-in | Apple vs Google platform differences | Email/Supabase first; platform IdP second |

---

## 6. Shared assets / backend (reuse as-is)

- `AstroSleep-iOS/Sounds/sounds_manifest.json` → copy into Android `assets`
- CDN: `https://cdn.astrosleep.app/...`
- Proxy: `https://api.astrosleep.app/api` (from `AppConfig`)
- Supabase project + RevenueCat products (add Play Store product IDs alongside App Store)
- Manifest validation: keep `validate_manifest.py` platform-agnostic

---

## 7. Tooling checklist (this machine)

| Tool | Status (2026-07-08) |
|------|---------------------|
| OpenJDK 21 | ✅ Temurin 21.0.3 |
| Android SDK / `ANDROID_HOME` | ❌ not set |
| Android Studio | ❌ not found |
| Gradle (system) | ❌ (wrapper will ship with project) |
| `adb` | ❌ |
| Kotlin CLI | ❌ (bundled via Gradle plugin) |

**Install before first build:**

1. [Android Studio](https://developer.android.com/studio) (Ladybug/Meerkat or newer)
2. SDK Platform 35 + Build-Tools + Platform-Tools
3. Set `ANDROID_HOME` (or let Studio write `local.properties`)
4. Optional: physical device with USB debugging for background-audio soak tests

---

## 8. Definition of done (Android v1 parity)

- [ ] Onboarding creates local profile + natal chart + base score
- [ ] Tonight shows nightly score + recommended combo
- [ ] Playback runs multi-layer ambient ≥ 30 min with screen off
- [ ] Sleep timer fade-out works
- [ ] Sounds library + combo save/load via Room
- [ ] Affirmation fetch (or cached) + TTS
- [ ] Free/Basic/Pro gates match iOS
- [ ] Restore purchases works
- [ ] Birth data never in network payloads (spot-check Network inspector)
- [ ] Unit tests: TagEngine + AstrologicalEngine golden vectors match iOS fixtures

---

## 9. Working agreements for the week

- Keep iOS sources authoritative for engine math until Android golden tests pass
- Prefer small commits per phase (engines → data → UI → audio → monetization)
- Do not commit `local.properties`, API keys, or keystores
- Document any intentional Android behavior delta in `CHANGELOG.md` under an `[Android]` section
