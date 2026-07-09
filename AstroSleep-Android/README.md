# AstroSleep Android

Native Android port of AstroSleep (Kotlin + Jetpack Compose).  
iOS source of truth: `../AstroSleep-iOS/` · plan: `../documentation/ANDROID_PORT_PLAN.md`

## Status

**Phases A–C in progress** — engines ported with iOS parity tests (20/20 unit tests green), Room storage, AppViewModel core loop, multi-track AudioService, Auth/Network/RevenueCat shells, Compose onboarding + Tonight/Sounds/Library/Settings UI.

| Area | Status |
|------|--------|
| TagEngine + lookup tables | ✅ full port |
| AstrologicalEngine | ✅ full port |
| ElementVector presets | ✅ full port |
| Room + StorageRepository | ✅ |
| SoundLibrary (manifest) | ✅ |
| AppViewModel (score, combo, session) | ✅ |
| AudioService (ExoPlayer layers, LFO, fade, TTS) | ✅ |
| RevenueCat / Network / Auth shells | ✅ |
| Compose UI shell | ✅ functional |
| Background MediaSession polish | ⏳ |
| Geocoder / full paywall purchase flow | ⏳ |

## Open in Android Studio

1. Install [Android Studio](https://developer.android.com/studio) + SDK 35
2. **File → Open** → `AstroSleep-Android/`
3. Let Gradle sync (Studio will offer to install the Gradle wrapper if missing)
4. Create `local.properties` (Studio usually auto-writes `sdk.dir`):

```properties
sdk.dir=C\:\\Users\\YOU\\AppData\\Local\\Android\\Sdk
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=
REVENUECAT_API_KEY=
# optional overrides:
# PROXY_BASE_URL=https://api.astrosleep.app/api
# SOUND_MANIFEST_URL=https://cdn.astrosleep.app/sounds_manifest.json
```

5. Run on emulator or device (`app` configuration)

## First build without Studio

Once `sdk.dir` is set and the Gradle wrapper exists:

```bash
./gradlew :app:assembleDebug
./gradlew :app:testDebugUnitTest
```

If the wrapper is missing, open the project once in Android Studio or run `gradle wrapper` with a local Gradle 8.9+ install.

## Package map

| Path | Role |
|------|------|
| `core/model` | ElementVector, Sound, UserProfile, Combo |
| `core/engine` | TagEngine, AstrologicalEngine (port in progress) |
| `core/config` | AppConfig / BuildConfig secrets |
| `service/` | Audio, Auth, Network, RC, … |
| `ui/` | Compose screens |
| `data/` | Room (next) |
| `assets/sounds/` | Manifest (+ optional m4a) |

## Security

- Birth data stays on device (Room only) — never upload
- Secrets via `local.properties` / CI → `BuildConfig`, not source
- HTTPS only (`usesCleartextTraffic=false`)
