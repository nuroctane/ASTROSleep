# AstroSleep Product Specification v3.2

**Date:** 2026-05-12
**Status:** In Development
**Previous:** [ASTROSLEEP_PRODUCT_SPEC_v3.1.md](ASTROSLEEP_PRODUCT_SPEC_v3.1.md)

---

## Overview

This document specifies the delta changes from v3.1 to v3.2. v3.1 remains the authoritative base for core architecture, features, and platform behavior. v3.2 addresses:

1. **Compile-Time Error Resolution** — fixes for Swift strict concurrency, deprecated APIs, immutable property decoding, and type ambiguity
2. **Codebase Hygiene** — elimination of redundant functions, force unwraps, and legacy GCD patterns
3. **Security Hardening** — centralized secret management via build-time injection, removal of hardcoded API keys and URLs
4. **Platform Modernization** — adoption of current SwiftUI `onChange` signatures, `Task`/`MainActor` patterns, and updated Core Location / AVFoundation APIs

---

## 1. Compile-Time Error Resolution

### 1.1 SwiftUI `onChange` Deprecation
**Problem:** Xcode 15+ deprecates the single-parameter `.onChange(of:perform:)` closure in favor of the two-parameter `.onChange(of:)` form.

**Fix:** Updated all call sites across the project:
- `TonightView.swift` — `SmoothTextEditor` text and focus handlers
- `SettingsView.swift` — notification toggle, reminder time, appearance mode
- `ContentView.swift` — tab selection sync
- `OnboardingFlowView.swift` — birth time interaction flag

### 1.2 Immutable Property Decoding (Codable)
**Problem:** Structs with `let id = UUID()` default values generate warnings: "immutable property will not be decoded because it is declared with an initial value."

**Fix:** Changed `let` to `var` for auto-generated ID properties in:
- `AmbientLayer.id`, `AmbientLayer.layerType`
- `AffirmationLayer.id`, `AffirmationLayer.layerType`
- `Transit.id`
- `AspectarianEntry.id`
- `Stellium.id`

### 1.3 `AppScreen` Hashable Synthesis
**Problem:** `AppScreen` enum with associated values (`playback(Combo)`, `comboBuilder(Combo?)`) failed automatic `Hashable` synthesis because `Combo` did not conform to `Hashable`.

**Fix:** Added `Hashable` conformance to `Combo` with an explicit `hash(into:)` implementation that combines only `id`.

### 1.4 Ambiguous `SoundManifest` Type
**Problem:** `SoundManifest` was declared in both `Sound.swift` and `UserModels.swift`, causing "ambiguous type" errors in `NetworkService` and `StorageService`.

**Fix:** Removed the duplicate from `UserModels.swift`; the canonical declaration in `Sound.swift` is the single source of truth.

### 1.5 Missing `bundleFilename` Default
**Problem:** `Sound.bundleFilename` was a `let` optional with no default, causing "missing argument" errors when constructing default `Sound` values in the fallback catalog.

**Fix:** Changed to `let bundleFilename: String? = nil` so Codable decoding still works while default construction succeeds.

### 1.6 `ElementVector.normalize` Parameter Shadowing
**Problem:** `func normalize(to max: Double)` shadowed the global `max()` function, producing "Cannot call value of non-function type 'Double'".

**Fix:** Renamed parameter to `target`, preserving the public API behavior.

### 1.7 AstrologicalEngine Member Resolution
**Problem:** Three categories of resolution errors in `AstrologicalEngine`:
- `transit.orbFactor` — no such computed property on `Transit`
- `asc.index` — no such property on `Sign`
- Naked enum literals (e.g., `.moon`) in arrays were inferred as contextual members incorrectly

**Fix:**
- Replaced `transit.orbFactor` with inline computation: `max(0, 1.0 - (transit.orb / transit.aspectType.orb))`
- Added `Sign.index` computed property returning `Sign.allCases.firstIndex(of: self) ?? 0`
- Prefixed array literals with explicit `Planet.` type (e.g., `Planet.moon`, `Planet.venus`)

### 1.8 Core Data Entity Scope
**Problem:** `StorageService.swift` referenced `CDUserProfile`, `CDSavedCombo`, `CDSessionLog`, and `CDAffirmationCache` but the generated `NSManagedObject` subclasses were not in the compile scope.

**Fix:** Created `CoreDataEntities.swift` with manual `NSManagedObject` subclasses and `fetchRequest()` extensions for all four entities.

---

## 2. Codebase Hygiene

### 2.1 Centralized Element Styling
**Problem:** `elementColor(_:)` and `elementIcon(_:)` were duplicated across **7 view files** (`TonightView`, `SoundLibraryView`, `ComboBuilderView`, `PlaybackView`, `PlaylistLibraryView`, and nested subviews).

**Fix:** Added computed properties to the `Element` enum in `AstrologicalTypes.swift`:
- `var color: Color` — canonical SwiftUI color
- `var icon: String` — canonical SF Symbol name

All call sites updated to `element.color` and `element.icon`. The redundant private helper functions were deleted.

### 2.2 Legacy GCD Patterns
**Problem:** Four files used `DispatchQueue.main.async` or `DispatchQueue.main.asyncAfter` for work that should run on the main actor:
- `AstroSleepApp.swift:114` — notification tap navigation
- `SoundLibraryView.swift:191` — 30-second preview timer
- `ComboBuilderView.swift:168` — 30-second preview timer
- `RevenueCatService.swift:47` — development loading-spinner fallback

**Fix:** Replaced with `Task { @MainActor in ... }` / `Task.sleep(nanoseconds:)` for modern structured concurrency.

### 2.3 Redundant Combine Scheduler
**Problem:** `ThemeService` and `AppState` both added `.receive(on: DispatchQueue.main)` to Combine sinks, but both classes are already annotated `@MainActor`. This is redundant and can introduce unnecessary thread hops.

**Fix:** Removed `.receive(on: DispatchQueue.main)` from both sinks.

### 2.4 Force Unwraps in ThemeService
**Problem:** `ThemeService.saveBackgroundImage`, `loadImage`, and `deleteBackgroundImage` used `dir!` force unwrap after optional chaining from `FileManager.default.urls(...).first?`.

**Fix:** Refactored all three methods to use `guard let docs = ...` early returns, eliminating every force unwrap.

---

## 3. Security Hardening

### 3.1 Centralized Configuration (`AppConfig`)
**Problem:** API keys, Supabase URLs, CDN URLs, and proxy endpoints were hardcoded as string literals in:
- `AuthService.swift` — `supabaseURL`, `supabaseAnonKey`
- `NetworkService.swift` — `proxyURL`, sound manifest URL
- `RevenueCatService.swift` — `revenueCatAPIKey`

**Fix:** Created `Core/Config/AppConfig.swift` with an `enum AppConfig` that reads from `Bundle.main.infoDictionary` (build settings) and falls back to `ProcessInfo.processInfo.environment`. This aligns with the v3.1 spec's recommendation for `xcconfig` injection.

```swift
enum AppConfig {
    static var supabaseURL: URL { ... }
    static var supabaseAnonKey: String { ... }
    static var revenueCatAPIKey: String { ... }
    static var proxyBaseURL: URL { ... }
    static var soundManifestURL: URL { ... }
}
```

All three services now reference `AppConfig.*` instead of literals.

### 3.2 AuthService Apple Sign-In Delegate
**Problem:** `SignInWithAppleDelegate` was annotated `@MainActor`, which conflicted with its `NSObject` inheritance and `init(continuation:)` usage.

**Fix:** Removed `@MainActor` from the private delegate class. The delegate methods are UIKit callbacks and already run on the main thread.

---

## 4. Platform Modernization

### 4.1 `CLGeocoder` Overload
**Problem:** Forward geocoding used the bare `geocodeAddressString(_:)` overload.

**Fix:** Adopted the iOS 15+ `geocodeAddressString(_:in:preferredLocale:)` overload, passing `Locale.current` for region-aware matching. Added `@unchecked Sendable` to `GeocodingService` to suppress strict-concurrency warnings on the `CLGeocoder` singleton.

### 4.2 AVAudioSession Bluetooth Options
**Problem:** `.allowBluetooth` was deprecated in iOS 10.

**Fix:** Replaced with `.allowBluetoothA2DP` and `.allowBluetoothHFP` in `AudioService.setupAudioSession()`.

### 4.3 `UIWindow()` Deprecated Init
**Problem:** `SignInWithAppleDelegate.presentationAnchor` fell back to `UIWindow()`, which is deprecated.

**Fix:** Replaced with `UIWindow(windowScene:)` when a scene is available, falling back to `UIWindow(frame: UIScreen.main.bounds)`.

### 4.4 AudioService Layer Volume Mutation
**Problem:** `setLayerVolume` used `guard let layerNode` (immutable copy) then mutated `layerNode.volume`, which would not persist because `AudioLayerNode` is a struct.

**Fix:** Changed to `guard var layerNode`, mutated `volume`, and wrote the copy back into `playerNodes[layerId]`.

---

## 5. Audit Summary

### Codebase Stats (post-v3.2)
- **Swift files**: 24 (+1 `AppConfig.swift`, +1 `CoreDataEntities.swift`)
- **Total lines of Swift**: ~7,100
- **Redundant `elementColor` functions removed**: 7
- **Deprecated `DispatchQueue.main` calls removed**: 4
- **Force unwraps eliminated**: 6
- **Hardcoded strings/URLs extracted**: 5

### Issues Resolved in v3.2
1. Deprecated `.onChange(of:perform:)` → modern two-parameter closure (4 call sites)
2. Immutable `let id = UUID()` decoding warnings → `var` on 6 structs
3. `AppScreen` Hashable synthesis failure → `Combo` now conforms to `Hashable`
4. Duplicate `SoundManifest` declaration → single canonical in `Sound.swift`
5. Missing `bundleFilename` default → added `= nil`
6. `ElementVector.normalize` shadowing `max()` → renamed parameter to `target`
7. `Transit.orbFactor` missing → inline computation
8. `Sign.index` missing → added computed property
9. Ambiguous planet contextual types → explicit `Planet.` prefix
10. Core Data entities out of scope → created `CoreDataEntities.swift`
11. 7 duplicated `elementColor` helpers → centralized on `Element`
12. 4 legacy `DispatchQueue.main` blocks → `Task { @MainActor }`
13. Redundant `.receive(on: DispatchQueue.main)` → removed from `@MainActor` sinks
14. 6 force unwraps in `ThemeService` → safe optional unwrapping
15. 5 hardcoded secrets/URLs → `AppConfig` build-setting abstraction
16. `@MainActor` on Apple Sign-In delegate → removed, fixed `UIWindow` fallback
17. `CLGeocoder` bare overload → locale-aware modern overload
18. Deprecated `.allowBluetooth` → `.allowBluetoothA2DP` + `.allowBluetoothHFP`
19. `AudioLayerNode` struct mutation bug → `guard var` + write-back
20. Unused `cached` immutable value in `AppState` → `currentNightlyScore != nil` check

---

*End of v3.2 Delta Specification*
