# AstroSleep Changelog

## [Unreleased] — 2026-07-09/10 (repo hygiene · parity · CI)

### Added
- **`tools/check_parity.py`** — executable lockstep guard: cosmic-systems copies, dual sound manifests, 12 tag-dimension weights (Swift/Kotlin/Python), exactly one iOS privacy manifest + entitlements
- **`tools/sync_shared.py`** — one-way sync from `shared/cosmic-systems/` and iOS sound manifest into platform copies
- **GitHub Actions CI** (`.github/workflows/ci.yml`) — Android unit tests, manifest validation, parity guard on every push/PR to `main`
- **Root `LICENSE`** — proprietary all-rights-reserved; vendored Three.js keeps its own license
- **`.agents/reviews/STATUS.md`** — review resolution ledger (reviews are immutable snapshots)

### Fixed / hardened
- **iOS privacy manifest consolidation** — single canonical `Resources/PrivacyInfo.xcprivacy`; removed divergent root duplicate; `NSPrivacyTrackingDomains` emptied (functional `api.`/`cdn.` endpoints must never be listed while not tracking); declares EmailAddress, UserID, PurchaseHistory only
- **iOS entitlements consolidation** — single canonical `Supporting Files/AstroSleep.entitlements`; deferred app-groups + iCloud until features exist; dropped invalid in-app-purchase entitlement key
- **Three.js pin** — r160 + sha256 recorded in `shared/cosmic-systems/README.md`

### Docs
- Root README: CI badge, tools, privacy singletons, roadmap ledger items
- Platform READMEs + go-live checklist §3.12–3.14
- Obsidian product spec bumped to **5.3**

## [v3.2.0] — 2026-05-12

### Changed
- **iOS 26 SDK Compliance**
  - Updated all platform documentation to reflect Apple iOS 26 SDK mandate (effective April 28, 2026)
  - Deployment target specification updated from iOS 16.0 to iOS 26.0 in product specs and README
  - All deprecated API removals in v3.2 align with iOS 26 SDK cleanliness requirements

### Fixed
- **SwiftUI Deprecations**
  - Updated all `.onChange(of:perform:)` to modern two-parameter `.onChange(of:)` (TonightView, SettingsView, ContentView, OnboardingFlowView)
  - Removed deprecated `.receive(on: DispatchQueue.main)` from `@MainActor` Combine sinks (AppState, ThemeService)
- **Codable / Protocol Conformance**
  - Changed `let id = UUID()` to `var` on `AmbientLayer`, `AffirmationLayer`, `Transit`, `AspectarianEntry`, `Stellium` to resolve immutable-property decoding warnings
  - Added `Hashable` conformance to `Combo` with `hash(into:)` so `AppScreen` synthesizes `Hashable` correctly
  - Removed duplicate `SoundManifest` declaration from `UserModels.swift`; canonical is in `Sound.swift`
  - Added `= nil` default to `Sound.bundleFilename` for default-constructor compatibility
- **AstrologicalEngine**
  - Replaced invalid `transit.orbFactor` with inline `max(0, 1.0 - (orb / aspect.orb))` computation
  - Added `Sign.index` computed property; fixed `asc.index` usage
  - Added explicit `Planet.` prefixes to array literals to resolve contextual member ambiguity
- **ElementVector**
  - Renamed `normalize(to max:)` parameter to `target` to avoid shadowing global `max()` function
- **Core Data**
  - Created `CoreDataEntities.swift` with manual `NSManagedObject` subclasses (`CDUserProfile`, `CDSavedCombo`, `CDSessionLog`, `CDAffirmationCache`) and `fetchRequest()` extensions
- **AudioService**
  - Fixed `setLayerVolume` struct mutation bug by using `guard var` and writing the modified copy back to `playerNodes`
  - Replaced deprecated `.allowBluetooth` with `.allowBluetoothA2DP` and `.allowBluetoothHFP`
- **GeocodingService**
  - Adopted modern `geocodeAddressString(_:in:preferredLocale:)` overload with `Locale.current`
  - Added `@unchecked Sendable` for strict concurrency compliance
- **AuthService**
  - Removed `@MainActor` from `SignInWithAppleDelegate` to fix main-actor initializer isolation
  - Replaced deprecated `UIWindow()` init with `UIWindow(windowScene:)` / `UIWindow(frame:)` fallback
  - Renamed second `request` variable to `tokenRequest` to resolve redeclaration

### Changed
- **Redundancy Elimination**
  - Added `Element.color` and `Element.icon` computed properties to `AstrologicalTypes.swift`
  - Removed 7 duplicated `elementColor` helper functions across view files
- **Legacy GCD → Modern Concurrency**
  - Replaced `DispatchQueue.main.async` in `AppDelegate` with `Task { @MainActor in }`
  - Replaced `DispatchQueue.main.asyncAfter` preview timers in `SoundLibraryView` and `ComboBuilderView` with `Task.sleep(nanoseconds:)`
  - Replaced `DispatchQueue.main.asyncAfter` in `RevenueCatService` with `Task { @MainActor }` + `Task.sleep`
- **Crash Prevention**
  - Eliminated 6 force unwraps (`dir!`) in `ThemeService` image save/load/delete helpers
- **Security Hardening**
  - Created `Core/Config/AppConfig.swift` to centralize secrets via `Info.plist` build settings + environment fallback
  - Extracted hardcoded URLs/keys from `AuthService`, `NetworkService`, and `RevenueCatService`

## [v3.1.0] — 2026-05-11

### Added
- **Local Sound Integration**
  - Created `Sounds/` folder with `sounds_manifest.json` containing all 24 existing sounds
  - Added `bundleFilename` field to `Sound` struct for bundled audio file references
  - `SoundLibrary` now loads from JSON manifest at runtime with embedded fallback catalog
  - Added `validate_manifest.py` script for CI validation of manifest integrity
  - Added `Sounds/README.md` documenting manifest format, tag dimensions, and workflow
  - Audio resolution now checks app bundle → Documents cache → CDN in that order
- **Apple Shipping Compliance**
  - Added `PrivacyInfo.xcprivacy` (Apple privacy manifest) with tracking, collected data, and accessed API declarations
  - Created `AstroSleep.entitlements` with production capabilities (Push, Apple Sign-In, IAP, Associated Domains, Keychain)
  - Added `ITSAppUsesNonExemptEncryption = false` to Info.plist for export compliance
  - Added localhost ATS exception for development (`NSExceptionAllowsInsecureHTTPLoads`)
- **Sound Lookup Cache**
  - `SoundLibrary` now maintains internal `soundById: [String: Sound]` dictionary
  - New `sound(id:) -> Sound?` method provides O(1) lookup
- **Nightly Score Caching**
  - `AppState.computeNightlyScore()` caches results per calendar day, eliminating redundant recomputation

### Changed
- **AudioService Performance**
  - `loadCombo` now uses `withTaskGroup` to load audio files in parallel instead of sequentially
  - Builds O(1) `soundMap` dictionary at load time instead of iterating `sounds.first(where:)` repeatedly
  - `loadAudioFile` skips already-loaded files to prevent redundant I/O
  - `speakAffirmation` reuses a persistent `AVSpeechSynthesizer` instance and stops prior speech
  - `fadeOut` now stores its timer in `fadeTimer` and invalidates it on new fades and cleanup
  - LFO oscillation uses `CACurrentMediaTime()` instead of `Date().timeIntervalSince1970` for drift-free timing
- **AppState Optimization**
  - `autoGenerateCombo` replaced O(n²) score summation with O(n) direct `RankedSound` access
  - Volume allocation now reads directly from ranked results without inner-loop lookup
- **AstrologicalEngine Efficiency**
  - `calculateNightlyScore` computes current placements once and passes them to `calculateTransits`
  - Eliminated duplicate `simplifiedCurrentPlacements` call (was computed twice per score)
  - `calculateTransits` signature updated to accept precomputed `currentPlacements` array
- **TagEngine Consistency**
  - `calculateTagVector` now references the existing `dimensionWeights` dictionary instead of hardcoded magic numbers, keeping scoring in sync with the spec
- **Security Hardening**
  - Info.plist API key placeholders converted to build-setting references (`$(SUPABASE_URL)`, `$(SUPABASE_ANON_KEY)`, `$(REVENUECAT_API_KEY)`)
  - Actual keys must now be injected via `xcconfig` or Xcode User-Defined Build Settings
  - Added `NSAllowsArbitraryLoads = false` with structured `NSExceptionDomains`
- **AudioService File Path Handling**
  - `loadAudioFile` now uses `URL(fileURLWithPath:)` for local paths instead of `URL(string:)`

### Fixed
- AudioService `loadCombo` orphaned code from refactor removed
- `SoundLibrary` class structure now properly closed with balanced braces
- TagEngine dimension weight lookup no longer uses complex `KeyPath` + `tableForDimension` indirection; uses direct `dimensionWeights` access
- Duplicate section numbering in README corrected (5, 6, 7, 8, 9)

### Documentation
- Updated `AstroSleep-iOS/README.md`
  - Added `Sounds/` folder to project structure
  - Added Local Sound Setup instructions
  - Updated configuration section to recommend xcconfig injection
  - Updated Security Checklist with 12 verified items
  - Renumbered setup sections to accommodate new sound setup step
- Created `ASTROSLEEP_PRODUCT_SPEC_v3.1.md` documenting all v3.0→v3.1 delta changes

---

## [v3.0.0] — Baseline

- Initial iOS implementation
- SwiftUI + MVVM + Combine architecture
- 24 hardcoded sounds in `SoundLibrary`
- 12-dimensional tag engine with archetypal scoring
- Astrological engine with sidereal 13-sign zodiac, Sharatan ayanamsha
- AVFoundation multi-track audio with EQ, LFO, per-layer speed
- AI affirmation generation via Cloudflare proxy
- Supabase Auth + Apple Sign-In
- RevenueCat subscription tiers (Free / Basic / Pro)
- Core Data local persistence
- Background audio support
- App Store Generative AI disclosure

---

*Changelog format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).*
