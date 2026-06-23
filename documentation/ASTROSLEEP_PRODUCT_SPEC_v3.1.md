# AstroSleep Product Specification v3.1

**Date:** 2026-05-11
**Status:** In Development
**Previous:** [ASTROSLEEP_PRODUCT_SPEC_v3.0.md](ASTROSLEEP_PRODUCT_SPEC_v3.0.md)

---

## Overview

This document specifies the delta changes from v3.0 to v3.1. v3.0 remains the authoritative base specification for core architecture, features, and platform behavior. v3.1 addresses:

1. **Local Sound Integration** — decoupled sound catalog from Swift code via JSON manifest
2. **Performance Optimization** — caching, O(1) lookups, parallelized audio loading
3. **Security Hardening** — build-time key injection, privacy manifest, entitlements
4. **Apple Shipping Compliance** — required manifests, disclosures, and export compliance

---

## 1. Local Sound Integration

### 1.1 Motivation
In v3.0, all 24 sounds were hardcoded in `SoundLibrary` as Swift structs. Adding or editing sounds required recompilation. v3.1 introduces a runtime JSON manifest that enables:
- Adding sounds by dropping files + editing JSON (no Xcode rebuild)
- Bundling audio files inside the app for offline/local testing
- Future web-based admin GUI that outputs the same JSON schema

### 1.2 File Structure
```
Sounds/
  sounds_manifest.json   # Catalog of all sounds + metadata
  validate_manifest.py   # CI validation script
  README.md            # Manifest format documentation
  *.m4a                # Bundled audio files (optional)
```

### 1.3 Manifest Schema (`SoundManifest`)
```json
{
  "version": 1,
  "generatedAt": "2026-05-11",
  "sounds": [
    {
      "id": "heavy_rain",
      "name": "Heavy Rain",
      "tags": { /* all 12 dimensions */ },
      "elementScores": { "fire": 0.45, "earth": 0.82, "air": 0.38, "water": 0.91 },
      "durationSeconds": 60,
      "isNew": false,
      "version": 1,
      "cdnUrl": "https://cdn.astrosleep.app/sounds/heavy_rain.m4a",
      "bundleFilename": "heavy_rain.m4a"
    }
  ]
}
```

**New field:** `bundleFilename` — optional filename of the audio file shipped inside the app bundle. When present and the file exists in the bundle, the app plays locally without downloading.

### 1.4 Runtime Resolution Order
When `AudioService` needs a sound file, it resolves in this priority:
1. **App Bundle** — `Bundle.main.path(forResource: bundleFilename, ofType: nil)`
2. **Documents Cache** — `Documents/sounds/{id}.m4a` (previously downloaded from CDN)
3. **CDN Download** — fetch from `cdnUrl` and cache for next time

### 1.5 `SoundLibrary` Refactor
- Changed from `struct` with static `let sounds` to `final class` with runtime loading
- Loads from bundled `sounds_manifest.json` at init time
- Falls back to embedded default catalog (24 sounds) if manifest is missing or malformed
- New `sound(id: String) -> Sound?` method provides O(1) lookup via internal dictionary

### 1.6 Validation
`validate_manifest.py` checks:
- Required fields present (`id`, `name`, `tags`, `elementScores`, `durationSeconds`, `cdnUrl`)
- All 12 tag dimensions have valid values (against spec lookup tables)
- No duplicate IDs
- Bundle file references exist on disk (warning only)
- Optional: recomputes element scores from tags and flags mismatches

Run before every build:
```bash
python AstroSleep-iOS/Sounds/validate_manifest.py
```

---

## 2. Performance Optimization

### 2.1 Audio Service
- **Parallel file loading**: `loadCombo` now uses `withTaskGroup` to load all layer audio files concurrently instead of sequentially
- **O(1) sound resolution**: `loadCombo` builds a `Dictionary<String, Sound>` lookup instead of iterating `sounds.first(where:)` for every layer
- **Skip already-loaded files**: `loadAudioFile` returns early if `audioFiles[sound.id]` is already populated
- **Persistent `AVSpeechSynthesizer`**: `speakAffirmation` no longer allocates a new synthesizer on every call; reuses a cached instance and stops any ongoing speech before starting new utterance
- **Fade-out timer management**: `fadeTimer` is now a stored property, invalidated before new fades and on `cleanup()` to prevent timer leaks
- **LFO timing**: Uses `CACurrentMediaTime()` instead of `Date().timeIntervalSince1970` for drift-free oscillation

### 2.2 AppState / Combo Generation
- **Nightly score caching**: `computeNightlyScore()` now caches the result for the current calendar day. The astrological score changes meaningfully only once per day, so recalculating on every view appear was wasteful
- **O(n) volume allocation**: `autoGenerateCombo` replaced an O(n²) inner-loop score lookup with direct access to pre-ranked `RankedSound` objects
- **Removed redundant `computeNightlyScore()` calls**: `autoGenerateCombo` still triggers it, but the cache prevents redundant work

### 2.3 AstrologicalEngine
- **Eliminated duplicate `simplifiedCurrentPlacements`**: In `calculateNightlyScore`, current placements were computed twice — once for transit aspects, once for house emphasis. Now computed once and passed to `calculateTransits`
- **Unified transit function signature**: `calculateTransits` now accepts `currentPlacements: [ChartPlacement]` directly instead of recomputing them internally

### 2.4 TagEngine
- **Consistent weight sourcing**: `calculateTagVector` now references the existing `dimensionWeights` dictionary instead of hardcoded magic numbers, ensuring the scoring formula stays in sync with the spec tables

---

## 3. Security Hardening

### 3.1 API Key Management
**v3.0 problem:** `Info.plist` contained plaintext placeholder API keys (`YOUR_SUPABASE_ANON_KEY`, `YOUR_REVENUECAT_IOS_PUBLIC_KEY`). Even as placeholders, this pattern encourages shipping real keys in the bundle.

**v3.1 fix:**
- `Info.plist` keys now reference build settings: `$(SUPABASE_URL)`, `$(SUPABASE_ANON_KEY)`, `$(REVENUECAT_API_KEY)`
- Actual values must be set in `xcconfig` or Xcode User-Defined Build Settings
- The `.gitignore` (recommended) should exclude `*.xcconfig` from version control
- `AuthService.swift` and `RevenueCatService.swift` still contain placeholder string constants for development but are documented as "must be replaced via build config"

### 3.2 Privacy Manifest (`PrivacyInfo.xcprivacy`)
Added as required by Apple starting Spring 2024:
- **Tracking**: `false` (no cross-app tracking)
- **Collected Data Types**: Email (auth), User ID (auth), Purchase History (subscriptions)
- **Accessed APIs**: UserDefaults (`CA92.1`), SystemBootTime (`35F9.1`), FileTimestamp (`C617.1`)
- **Privacy Policy URL**: `https://astrosleep.app/privacy`

### 3.3 Entitlements (`AstroSleep.entitlements`)
Created with production-ready capabilities:
- Push notifications (`aps-environment: production`)
- Associated Domains (`applinks:astrosleep.app`)
- Apple Sign-In (`Default`)
- In-App Purchase
- Keychain access group for secure token storage

### 3.4 App Transport Security
- `NSAllowsArbitraryLoads = false` (HTTPS only)
- Added `NSExceptionDomains` for `localhost` with `NSExceptionAllowsInsecureHTTPLoads = true` to support local dev server testing without breaking production security

### 3.5 Encryption Export Compliance
Added `ITSAppUsesNonExemptEncryption = false` to Info.plist. The app uses standard HTTPS/TLS (exempt) and does not implement custom cryptography.

---

## 4. Apple Shipping Compliance

### 4.0 iOS 26 SDK Mandate (Effective April 28, 2026)
Apple requires all apps uploaded to App Store Connect to be built with **Xcode 26 or later** using an SDK for **iOS 26 or later**.

**Impact on AstroSleep:**
- Deployment target must be set to `iOS 26.0` minimum in project build settings
- SwiftUI 5.0+ features remain valid; no API migration needed
- All deprecated APIs addressed in v3.2 (`.onChange`, `UIWindow()`, `DispatchQueue` sinks, etc.)
- TestFlight builds must also use Xcode 26+ for pre-submission validation

### 4.1 Required Files Checklist
| File | Purpose | Status |
|------|---------|--------|
| `PrivacyInfo.xcprivacy` | Apple privacy manifest (required since Spring 2024) | Added v3.1 |
| `AstroSleep.entitlements` | Capability declarations | Added v3.1 |
| `Info.plist` | Bundle config + required disclosures | Updated v3.1 |
| `NSGenerativeAIDisclosure` | App Store AI usage disclosure | Already present |
| `NSMicrophoneUsageDescription` | Pro voice recording | Already present |
| `NSLocationWhenInUseUsageDescription` | Birth city geocoding | Already present |

### 4.2 Paywall Compliance (Already Compliant)
- "Restore Purchases" button visible
- Auto-renewal terms displayed
- Free trial with clear post-trial pricing

### 4.3 Missing for Production (Not in v3.1 Scope)
The following remain outside the v3.1 scope but are tracked for future releases:
- App icon assets (AppIcon.appiconset)
- Launch screen / LaunchScreen.storyboard
- Core Data model file (`CoreDataModel.xcdatamodeld`) — referenced but not present in repo
- Privacy policy webpage at `https://astrosleep.app/privacy`
- Terms of Service webpage
- App Store screenshots / preview video

---

## 5. Dev Admin Tool (Web GUI) — Future

The eventual React-based admin tool will:
1. Display the same 12 tag dropdowns per sound
2. Live-compute element scores using the same `TagVectorTables` logic
3. Generate `sounds_manifest.json` entries matching the exact schema above
4. Upload audio to R2/Cloudflare and set `cdnUrl`
5. Optionally set `bundleFilename` for sounds that should ship in the app

Because the iOS app now consumes `sounds_manifest.json` at runtime, the web GUI is a pure content-management layer — no Swift code changes required when adding sounds.

---

## 6. Audit Summary

### Codebase Stats
- **Swift files**: 23
- **Total lines of Swift**: ~6,800
- **Sounds**: 24 (all migrated to JSON manifest)
- **Tag dimensions**: 12
- **Subscription tiers**: 3 (Free, Basic, Pro)

### Issues Resolved in v3.1
1. Hardcoded sound catalog → JSON manifest with fallback
2. Sequential audio loading → Parallel task-group loading
3. O(n) sound lookups in views → O(1) dictionary cache
4. Daily redundant natal score computation → Per-day cache
5. O(n²) volume allocation in combo builder → O(n) direct access
6. Duplicate current placement computation → Single computation + pass-through
7. Magic-number tag weights → Centralized `dimensionWeights` dictionary
8. API key placeholders in Info.plist → Build-setting injection
9. Missing privacy manifest → `PrivacyInfo.xcprivacy` added
10. Missing entitlements file → `AstroSleep.entitlements` created
11. Missing encryption export flag → `ITSAppUsesNonExemptEncryption` added
12. New synthesizer per TTS call → Reused `AVSpeechSynthesizer` instance
13. Unmanaged fade timer → Stored + invalidated on cleanup
14. `Date().timeIntervalSince1970` for LFO → `CACurrentMediaTime()`

---

*End of v3.1 Delta Specification*
