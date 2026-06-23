# AstroSleep Location-Aware Astrological Scoring — v3.1

**Date:** 2026-05-11  
**Status:** Integrated into iOS codebase and `ASTROSLEEP_PRODUCT_SPEC_v3.0.md`  
**Scope:** Natal chart birth-location fidelity + optional current-location transit scoring

---

## 1. Problem Statement

Astrological natal charts are highly sensitive to the geographic coordinates of birth. The Ascendant (rising sign), house cusp degrees, and planetary house placements all shift with latitude and longitude. Equally, **live transit scoring** is most accurate when computed against the sky as seen from the user's **current location**, not a generic default (e.g., 0° lat / 0° lng). A user born in New York but currently in Tokyo will experience different house emphasis and angular transits than the natal chart alone would suggest.

Prior to v3.1, the transit engine defaulted to `lat: 0, lng: 0` for current planetary positions, which:
- Produced inaccurate house placements for transiting planets
- Missed angular emphasis (1st / 4th / 7th / 10th house boosts)
- Reduced the precision of nightly sound recommendations

---

## 2. Design Principle: Two Locations, Distinct Roles

| Data Point | Role | Mutable | Stored |
|------------|------|---------|--------|
| **Birth location** (`birthLat`, `birthLng`, `birthCity`) | Computes the natal chart once at onboarding. Determines natal house cusps, Ascendant, and natal planetary houses. | No — permanently tied to the natal chart. | Local Core Data only |
| **Current location** (`currentLat`, `currentLng`, `currentCity`) | Optionally used for each night's transit scoring. Computes current Ascendant, current house cusps, and angular emphasis for transiting planets. | Yes — user can update anytime (travel, relocation). | Local Core Data only |

**Privacy guarantee:** Both birth and current location are stored on-device only. They are never sent to Supabase, the AI proxy, RevenueCat, analytics, or any third party.

---

## 3. Data Model Updates

### 3.1 `UserProfile` (Swift)

```swift
struct UserProfile: Codable, Identifiable {
    // ... existing fields ...
    let birthLat: Double
    let birthLng: Double
    let birthCity: String

    var currentLat: Double
    var currentLng: Double
    var currentCity: String
    var useCurrentLocationForTransits: Bool
    // ...
}
```

### 3.2 Core Data Model (`CDUserProfile`)

Added attributes:
- `currentLat` — Double, default 0.0
- `currentLng` — Double, default 0.0
- `currentCity` — String, optional
- `useCurrentLocationForTransits` — Boolean, default false

---

## 4. Engine Updates

### 4.1 `AstrologicalEngine.calculateNightlyScore(...)`

New signature:
```swift
func calculateNightlyScore(
    baseScore: ElementVector,
    date: Date,
    natalChart: NatalChart,
    currentLat: Double = 0,
    currentLng: Double = 0,
    useCurrentLocation: Bool = false
) -> NightlyScoreResult
```

Logic:
```swift
let transitLat = useCurrentLocation ? currentLat : 0
let transitLng = useCurrentLocation ? currentLng : 0
```

### 4.2 `AstrologicalEngine.calculateTransits(...)`

New signature:
```swift
private func calculateTransits(
    date: Date,
    natalChart: NatalChart,
    currentLat: Double = 0,
    currentLng: Double = 0,
    useCurrentLocation: Bool = false
) -> [Transit]
```

**Angular emphasis boost:** If `useCurrentLocation` is true, the engine computes the current Ascendant at `(currentLat, currentLng)`. Any transiting planet found in an angular house (1st, 4th, 7th, 10th) receives a `1.3x` multiplier on its transit strength via the new `Transit.angularBoost` property.

### 4.3 `AstrologicalEngine.simplifiedCurrentPlacements(...)`

New signature:
```swift
private func simplifiedCurrentPlacements(date: Date, lat: Double = 0, lng: Double = 0) -> [ChartPlacement]
```

When `lat != 0 || lng != 0`, the engine:
1. Computes the current Ascendant at the provided coordinates
2. Recomputes house assignments for each transiting planet using that Ascendant
3. Returns placements with accurate `house` values for the given location

### 4.4 `Transit` Model

Added:
```swift
struct Transit: Codable, Identifiable {
    // ... existing fields ...
    var angularBoost: Double = 1.0
    
    var strength: Double {
        // ... baseStrength * orbFactor * angularBoost
    }
}
```

---

## 5. UI Updates

### 5.1 Settings → Location Section

New section in `SettingsView`:
- **Toggle:** "Use Current Location for Transits"
- **Explanatory text:** Describes that current location is used for transit house placement and angular emphasis.
- **NavigationLink:** "Current Location" (visible only when toggle is on)

### 5.2 `CurrentLocationEditView`

Manual entry form (no GPS/CoreLocation required, though a future iteration may add it):
- `TextField` — City name
- `TextField` — Latitude (decimal pad)
- `TextField` — Longitude (decimal pad)
- **Save button** — persists to `UserProfile` and recomputes nightly score

**Rationale for manual entry:** Avoids runtime location permission friction. Users who want accuracy can enter coordinates once; the app does not require background or foreground location access.

---

## 6. Privacy & Compliance Updates

### 6.1 `PrivacyInfo.xcprivacy`

Added `NSPrivacyCollectedDataTypePreciseLocation` entry:
- Linked: false
- Tracking: false
- Purpose: `NSPrivacyCollectedDataTypePurposeAppFunctionality`

Existing `NSPrivacyCollectedDataTypeCoarseLocation` remains for birth city geocoding.

### 6.2 `Info.plist`

Updated `NSLocationWhenInUseUsageDescription` to explicitly mention both:
- Birth city geocoding for natal chart computation
- Optional current-location transit house placement and angular emphasis

---

## 7. Scoring Impact Summary

| Scenario | Before v3.1 | After v3.1 |
|----------|-------------|------------|
| User at birth location, default mode | `lat: 0, lng: 0` for transits (imprecise houses) | Same as before unless toggle is ON |
| User at birth location, current mode ON | N/A | Accurate current houses at birth coordinates |
| User traveling, current mode ON | N/A | Accurate current houses at travel coordinates; angular boosts apply |
| Transit planet angular at current location | No boost | `1.3x` strength boost via `angularBoost` |
| Transit house assignment | Always generic / equatorial | Location-derived Equal house cusps when coordinates provided |

---

## 8. Onboarding Flow

`OnboardingFlowView` initializes `currentLat`, `currentLng`, `currentCity`, and `useCurrentLocationForTransits` with defaults (`0`, `""`, `false`). After the user enters their **birth** city and it is geocoded, the birth coordinates are stored in `birthLat`/`birthLng`. The current location fields remain empty until the user explicitly fills them in Settings.

**Future enhancement (not in v3.1):** Offer to copy birth location into current location during onboarding for users who still live in their birth city.

---

## 9. Testing Checklist

- [ ] Create profile with birth location; verify natal chart uses birth coordinates
- [ ] Enable "Use Current Location for Transits"; enter different coordinates
- [ ] Verify `calculateNightlyScore` receives `currentLat`/`currentLng`
- [ ] Verify `simplifiedCurrentPlacements` assigns houses based on current Ascendant
- [ ] Verify transiting planet in 1st/4th/7th/10th house gets `angularBoost = 1.3`
- [ ] Disable toggle; verify engine falls back to `lat: 0, lng: 0` and `angularBoost = 1.0`
- [ ] Verify `PrivacyInfo.xcprivacy` includes `PreciseLocation`
- [ ] Verify `Info.plist` location description covers both birth and current use

---

## 10. Changelog

| Version | Change |
|---------|--------|
| v3.0 | Natal chart computed with birth location; transits default to `lat: 0, lng: 0` |
| **v3.1** | Added optional current-location transit scoring with angular emphasis, location-aware house cusps, and privacy-compliant manual coordinate entry |

---

*End of Document*
