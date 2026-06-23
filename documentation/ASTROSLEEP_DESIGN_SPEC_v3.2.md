# AstroSleep Design Specification v3.2

**Date:** 2026-05-12
**Status:** In Development
**Previous:** [ASTROSLEEP_PRODUCT_SPEC_v3.1.md](ASTROSLEEP_PRODUCT_SPEC_v3.1.md)

---

## Overview

This document specifies the delta design changes from v3.1 to v3.2. v3.1 remains the authoritative base for core architecture. v3.2 addresses front-end GUI/UX concerns across four areas:

1. **Custom Theming System** — paywalled cosmetic customization (accent color, background color, background image)
2. **Sound Filter Visibility** — all 12 tag dimensions and element scores surfaced in the Sounds tab
3. **Smooth Text Entry** — polished intention input on the Tonight screen
4. **Onboarding Date/Time UX** — native iOS wheel pickers, required birth time with midnight default

---

## 1. Custom Theming System

### 1.1 Motivation
Free users receive the standard iOS dark/light mode with a static `.indigo` accent. Pro subscribers can personalize the app's visual identity to make it feel more intimate and "theirs." This increases perceived value of the Pro tier and user emotional attachment.

### 1.2 Tier Gating

| Feature | Free | Basic | Pro |
|---------|------|-------|-----|
| Dark / Light mode | Yes | Yes | Yes |
| Static accent (`.indigo`) | Yes | Yes | Yes |
| Custom accent color | No | No | Yes |
| Custom background color | No | No | Yes |
| Custom background image (Photo Library) | No | No | Yes |

### 1.3 ThemeConfig Model

```swift
struct ThemeConfig: Codable, Equatable {
    var accentColorHex: String        // e.g., "5856D6" for indigo
    var backgroundColorHex: String?   // nil = system background
    var backgroundImagePath: String?  // local file path in Documents/themes/
    var useSystemAppearance: Bool       // true = follow iOS dark/light toggle
}
```

Stored inside `UserProfile.themeConfig`. Defaults to `ThemeConfig()` (indigo accent, system bg, no image, system appearance).

### 1.4 ThemeService

A `@MainActor final class ThemeService: ObservableObject` that:
- Publishes `@Published var currentAccent: Color`
- Publishes `@Published var currentBackground: Color`
- Publishes `@Published var backgroundImage: UIImage?`
- Converts hex strings to `Color` / `UIColor`
- Applies `UIAppearance` proxy overrides for `UINavigationBar`, `UITabBar`, `UISwitch` tint
- Watches `RevenueCatService.shared.currentTier` — if tier drops below Pro, resets to default theme
- Loads/saves via `StorageService`

### 1.5 Settings: Appearance Section

New section in `SettingsView`:
- **Row 1**: "Appearance Mode" → sheet with segmented control: "System" / "Light" / "Dark"
- **Row 2**: "Accent Color" → color picker grid (8 presets + custom). Locked for Free/Basic with "Upgrade to Pro" chevron.
- **Row 3**: "Background Color" → color picker grid. Locked for Free/Basic.
- **Row 4**: "Background Image" → "Choose from Library" button. Uses `PHPickerViewController`. Locked for Free/Basic.
- **Row 5**: "Reset to Default" — visible only when theme is non-default.

### 1.6 View Integration

All views replace hardcoded `.indigo` with `.accentColor` (SwiftUI automatically respects the environment) or explicitly read `ThemeService.shared.currentAccent`.
- `ContentView` background: `currentBackground` or system
- `TonightView` background: `currentBackground` or system
- `PlaybackView` background: `currentBackground` or system
- Tab bar tint: `currentAccent`
- Buttons, sliders, toggles: `currentAccent`

Background image is rendered as a full-screen `Image` with `.opacity(0.15)` behind all content, or as a `ZStack` layer in each root view.

---

## 2. Sound Tab Filter Visibility

### 2.1 Motivation
The current Sounds tab only shows element filter chips and a "Show New Only" toggle. The 12-dimensional tag system is invisible to users. Surfacing tags and scores empowers users to curate their own sonic palettes and understand *why* a sound is recommended.

### 2.2 Sound Card Redesign

Each `SoundCard` now displays:
- **Top-left**: "NEW" badge (unchanged)
- **Top-right**: Element score mini-bars (4 colored bars, 0–100% width) OR a colored dot for dominant element
- **Center**: SF Symbol icon (unchanged)
- **Bottom row 1**: Sound name (unchanged)
- **Bottom row 2**: Tag pills — horizontally scrollable chips showing the most distinctive tags (top 3 by tag weight). Examples: "nature", "mid", "flowing", "cool"
- **Bottom row 3**: Domain label + download status (unchanged)

### 2.3 Enhanced Filter Sheet

Tapping a "Filters" button in the `SoundLibraryView` navigation bar opens a sheet with:
- **Element filter**: Horizontal scroll of 4 element chips (Fire, Earth, Air, Water) — already exists, moved here
- **Tag dimension accordions**: Expandable sections for each of the 12 dimensions. Each section shows all valid values as selectable chips.
  - Domain: water, air, fire, earth, mechanical, organic, electrical, cosmic
  - Rhythm: steady, pulse, irregular, chaotic, rhythmic, arrhythmic
  - Register: sub, deep, mid, bright, full, ultrasonic
  - Context: nature, domestic, abstract, urban, industrial, spiritual
  - Weight: ethereal, light, medium, heavy, massive
  - Texture: smooth, rough, crystalline, diffuse, granular, glassy, metallic
  - Motion: static, flowing, surging, swirling, oscillating, drifting, pulsing
  - Density: vacuum, sparse, moderate, dense, saturated
  - Temperature: cold, cool, neutral, warm, hot
  - Polarity: active, receptive, balanced, neutral
  - Celestial: solar, lunar, stellar, planetary, void
  - Archetype: maiden, mother, crone, hero, mentor, shadow, trickster
- **Active filter bar**: Horizontal scroll of "pill + X" chips showing currently applied filters, with a "Clear All" button
- **Result count**: "Showing 8 of 24 sounds"

Filter logic: sounds must match ALL active filters (AND logic across dimensions, OR within a dimension if multiple values selected).

### 2.4 Score Visibility on Sound Detail

Tapping a sound card opens a detail sheet (new):
- Full element score breakdown with mini bar charts
- All 12 tags listed with their values
- "Add to Combo" button
- "Play Preview" button
- Element affinity explanation: "This sound is 91% Water, 82% Earth — ideal for grounding and emotional release."

---

## 3. Smooth Intention Text Entry (Tonight Screen)

### 3.1 Motivation
The current `TextEditor` is a bare iOS component with no placeholder, no keyboard dismissal gesture, and no scroll-into-view behavior. Users on smaller devices lose the text field under the keyboard.

### 3.2 Design

Replace the raw `TextEditor` with a custom `SmoothTextEditor` component:
- **Placeholder**: "Tonight I intend to..." in `.secondary` color, disappears on focus
- **Background**: `.secondarySystemBackground` with 12pt corner radius
- **Border**: 1pt stroke in `.separator`, turns `.indigo` (accent) on focus
- **Min height**: 80pt, expands up to 200pt as text grows
- **Max length**: 280 characters (unchanged), with live counter below
- **Keyboard dismissal**: Tap outside dismisses keyboard; "Done" button on keyboard toolbar
- **Scroll-to-visible**: When keyboard appears, `ScrollView` automatically insets so the text editor and "Begin" button remain visible
- **Return key**: Soft return creates newlines; no auto-capitalization restriction

### 3.3 Accessibility
- `accessibilityLabel`: "Intention text field"
- `accessibilityHint`: "Enter your sleep intention for tonight's affirmation. Up to 280 characters."
- Dynamic Type support via `.font(.body)`

---

## 4. Onboarding Date/Time UX

### 4.1 Motivation
The current onboarding uses a `Toggle("I know my birth time")` which makes birth time optional. Astrological accuracy depends heavily on birth time for ascendant and house placement. The design now makes birth time required, defaulting to midnight when unknown, and uses native iOS wheel pickers for a more familiar, scrollable experience.

### 4.2 Birth Date Picker

- Use `DatePicker("", selection: $birthDate, displayedComponents: .date)`
- Style: `.wheel` — users can independently scroll day, month, and year wheels
- Default value: 25 years before current date (unchanged)
- No inline calendar — wheel style is more tactile and consistent with the app's "intentional" feel

### 4.3 Birth Time Picker

- **Remove the toggle**. Birth time is always collected.
- Use `DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)`
- Style: `.wheel` — 24-hour wheel format
- Default value: 12:00 noon (not midnight, so users who don't know their time are more likely to change it)
- **Helper text below picker**: "If you're unsure of your birth time, midnight will be used for chart calculation."
- On submit: if user leaves it at default (12:00) and has not explicitly interacted with the time wheel, store `nil` and use midnight for computation. If user interacts with the wheel, store the selected time.

### 4.4 Validation

- Name: required, non-empty
- Birth city: required, non-empty
- Birth date: any valid date in the past
- Birth time: optional in UI but always stored (nil = midnight default)
- All fields must be filled before "Compute My Chart" button enables

---

## 5. Implementation Order

1. Data models: `ThemeConfig`, update `UserProfile`, `SubscriptionTier`
2. `ThemeService` + `StorageService` persistence
3. `SettingsView` — new Appearance section
4. Onboarding — remove toggle, update pickers, enforce time
5. `TonightView` — replace `TextEditor` with `SmoothTextEditor`
6. `SoundLibraryView` — enhanced cards + filter sheet
7. Global color sweep — replace `.indigo` with theme-aware accessors
8. Web preview update

---

*End of v3.2 Design Specification*
