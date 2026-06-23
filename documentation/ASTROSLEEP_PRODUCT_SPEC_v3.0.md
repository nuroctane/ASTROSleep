# AstroSleep — Complete Product Specification v3.0

> **Agent-Optimized Build Brief** — Paste this file into any AI agent terminal as a self-contained construction manual.
> 
> **Version:** 3.0 | **Tag Engine:** 12-dimensional with decimal precision | **Platform Strategy:** Separate iOS/Android native UI builds from shared core logic

---

## Document Purpose & Agent Usage Rules

This document is the **single source of truth** for AstroSleep. When building with an AI agent:

- **DO NOT invent features not listed here**
- **DO NOT remove or merge features without explicit instruction**
- **DO NOT hardcode scores** — the Tag Engine (Section 6) governs all sound scoring
- **DO NOT place API keys in app binaries** — the backend proxy (Section 17) must be built before any AI API calls are wired up
- **DO NOT trust locally stored tier strings** — entitlement checks always call RevenueCat at runtime
- **DO NOT commingle platform-specific code** — iOS and Android UIs are separate implementations (Section 3.4)
- **ALWAYS follow cross-references** — when a section says "see Section X", follow the reference exactly

---

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [Core Differentiators](#2-core-differentiators)
3. [Tech Stack — Dual Native UI Strategy](#3-tech-stack--dual-native-ui-strategy)
4. [Platform-Specific UI Specifications](#4-platform-specific-ui-specifications)
5. [User Flows](#5-user-flows)
6. [Astrological Engine](#6-astrological-engine)
7. [Tag Engine v3.0 — 12-Dimensional Archetypal Scoring](#7-tag-engine-v30--12-dimensional-archetypal-scoring)
8. [Sound Library](#8-sound-library)
9. [Combo System](#9-combo-system)
10. [Subliminal Audio System](#10-subliminal-audio-system)
11. [Subscription Tiers](#11-subscription-tiers)
12. [Screen-by-Screen UI Spec](#12-screen-by-screen-ui-spec)
13. [Backend Architecture](#13-backend-architecture)
14. [Local Data Model](#14-local-data-model)
15. [Audio Asset Spec & Delivery](#15-audio-asset-spec--delivery)
16. [Dev Admin Tool (Web GUI)](#16-dev-admin-tool-web-gui)
17. [Payment & Subscription Infrastructure](#17-payment--subscription-infrastructure)
18. [Security Architecture](#18-security-architecture)
19. [Backend Services (Cloudflare Workers)](#19-backend-services-cloudflare-workers)
20. [Error States & Offline Behavior](#20-error-states--offline-behavior)
21. [Analytics & Observability](#21-analytics--observability)
22. [App Store & Play Store Submission](#22-app-store--play-store-submission)
23. [Implementation Phases](#23-implementation-phases)
24. [Key Design Decisions](#24-key-design-decisions)

---

## 1. Product Vision

AstroSleep is a cross-platform (iOS + Android) sleep app that helps users direct their subconscious mind toward specific problems or intentions during rest. It combines:

- **Astrological personalization** — natal chart + live transits drive sound recommendations
- **AI-generated subliminal affirmations** — user intent → first-person audio script
- **Tag-based ambient sound engine** — formula-driven scoring with decimal precision, no manual hardcoding
- **Layered combo system** — multi-track ambient mixes with volume, EQ, and LFO oscillation
- **Comprehensive chart coverage** — every astrological variable (planets, signs, houses, aspects, stelliums, nodes, asteroids) contributes to scoring

The core insight: people solve problems in their sleep. AstroSleep curates the sonic environment to match the user's energetic state each night, then layers in subliminal affirmation audio tuned to their specific intention.

---

## 2. Core Differentiators

| Feature | Rain Rain | Calm | Insight Timer | AstroSleep |
|---------|-----------|------|---------------|------------|
| Astrological personalization | ✗ | ✗ | ✗ | ✓ |
| Transit-aware nightly scoring | ✗ | ✗ | ✗ | ✓ |
| 12-dimensional archetypal tag engine | ✗ | ✗ | ✗ | ✓ |
| Complete natal chart variable coverage | ✗ | ✗ | ✗ | ✓ |
| Decimal-precision scoring | ✗ | ✗ | ✗ | ✓ |
| AI subliminal affirmation audio | ✗ | ✗ | ✗ | ✓ |
| Multi-layer combo with LFO | ✓ | ✗ | ✗ | ✓ |
| Zero AI tokens for nightly scoring | n/a | n/a | n/a | ✓ |
| Platform-native UI feel | ✗ | ✗ | ✗ | ✓ |
| Web-based dev admin tool | ✗ | ✗ | ✗ | ✓ |
| iOS + Android | ✓ | ✓ | ✓ | ✓ |

---

## 3. Tech Stack — Dual Native UI Strategy

### 3.1 Framework Decision: Separate Native UI Layers with Shared Core

AstroSleep targets both iOS (App Store) and Android (Google Play) with **platform-native UI implementations** that share a common business logic core.

**Architecture Overview:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ASTROSLEEP ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────┤
│  iOS Layer (SwiftUI)      │  Android Layer (Jetpack Compose)           │
│  ─────────────────────    │  ───────────────────────────────            │
│  • SwiftUI 5.0+           │  • Jetpack Compose 2024.02+                  │
│  • UIKit integration      │  • Material3 design system                 │
│  • iOS native navigation  │  • Android navigation patterns             │
│  • Haptic feedback        │  • Vibrator haptics                         │
│  • iOS system fonts       │  • Roboto / system fonts                    │
│  • iOS-style transitions  │  • Android motion patterns                  │
├─────────────────────────────────────────────────────────────────────────┤
│                    SHARED CORE MODULE (Kotlin Multiplatform)             │
│  ───────────────────────────────────────────────────────────            │
│  • Business logic (pure Kotlin)                                         │
│  • Astrological calculations (WASM ephemeris wrapper)                   │
│  • Tag engine algorithms                                                │
│  • Data models & repositories                                           │
│  • Network layer interfaces                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                    PLATFORM ABSTRACTION LAYER                              │
│  ───────────────────────────────────────────────────────────            │
│  • Audio playback (expect/actual)                                       │
│  • Local storage (expect/actual)                                        │
│  • Platform-specific implementations                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

**Rationale for Dual Native Approach:**

- **iOS users expect iOS patterns** — bottom sheets, navigation bars, haptics, SF Symbols
- **Android users expect Material3** — floating action buttons, navigation drawers, dynamic theming
- **Shared core prevents logic divergence** — Kotlin Multiplatform compiles to native iOS (via Objective-C headers) and Android
- **Platform stores favor native apps** — better performance ratings, native feature access
- **Future-proofing** — easier to adopt platform-specific innovations (iOS widgets, Android dynamic features)

**Platform minimums:**
- iOS 26+ SDK (SwiftUI 5.0+; Apple mandates iOS 26 SDK for App Store submissions since April 28, 2026)
- Android 10+ (API level 29+)

### 3.2 iOS Tech Stack Specification

| Layer | Technology | Notes |
|-------|------------|-------|
| Language | Swift 5.9+ | Strict concurrency checking enabled |
| UI Framework | SwiftUI 5.0+ | Requires iOS 26 SDK minimum for App Store submission |
| Minimum OS | iOS 26.0 | Deployment target must match iOS 26 SDK per Apple mandate |
| Navigation | SwiftUI NavigationStack | Programmatic with path binding |
| Architecture | MVVM + Combine | ObservableObject for state management |
| Core Integration | Kotlin Multiplatform iOS framework | Via Objective-C headers generated by KMP |
| Audio engine | AVFoundation + AudioKit | Native iOS audio pipeline |
| Audio looping | AVAudioPlayer (buffered) or AudioKit Node | Per-layer player instances |
| Pitch/speed | AVAudioUnitTimePitch | Per-layer playback speed with pitch lock |
| TTS | AVSpeechSynthesizer | Native iOS text-to-speech |
| Astrology | Shared KMP module | WASM ephemeris wrapped in Kotlin |
| Local persistence | SwiftData (iOS 17+) or Core Data with CloudKit | Charts, combos, playlists, session logs |
| Auth | Supabase Auth + Apple Sign-In | Shared KMP networking layer |
| Remote DB | Supabase (Postgres) | User accounts, entitlement audit log only |
| AI API proxy | Cloudflare Worker (via KMP) | Anthropic API key server-side |
| Subscriptions | RevenueCat SDK (`PurchasesSwift`) | StoreKit 2 abstraction |
| Payments backend | RevenueCat + Stripe | Receipt validation, webhook handling |
| Push notifications | UserNotifications framework | Bedtime reminders |
| Analytics | PostHog iOS SDK | Event tracking, funnels |
| Crash reporting | Sentry (`sentry-cocoa`) | Error monitoring |
| CDN (sounds) | URLSession + local cache | Sound asset delivery |
| Icons | SF Symbols 5.0+ | System icons for native feel |
| Haptics | UIImpactFeedbackGenerator | Platform-appropriate feedback |

### 3.3 Android Tech Stack Specification

| Layer | Technology | Notes |
|-------|------------|-------|
| Language | Kotlin 1.9+ | Coroutines for async, Flow for reactive |
| UI Framework | Jetpack Compose 2024.02+ | Material3 design system |
| Navigation | Compose Navigation | Type-safe navigation with Kotlin DSL |
| Architecture | MVVM + StateFlow | ViewModel with StateFlow exposure |
| Core | Kotlin Multiplatform (shared with iOS) | Same business logic module |
| Audio engine | ExoPlayer + Oboe | Native Android audio pipeline |
| Audio looping | ExoPlayer LoopingMediaSource | Per-layer player instances |
| Pitch/speed | SonicAudioProcessor | Per-layer playback speed |
| TTS | Android TextToSpeech | Platform TTS with voice selection |
| Astrology | Shared KMP module | WASM ephemeris via Kotlin |
| Local persistence | Room (SQLite) | Charts, combos, playlists, session logs |
| Auth | Supabase Auth + Google Sign-In | Shared KMP layer |
| Remote DB | Supabase (Postgres) | User accounts only |
| AI API proxy | Cloudflare Worker (via KMP) | Server-side API key |
| Subscriptions | RevenueCat SDK (`purchases-android`) | Google Play Billing abstraction |
| Push notifications | Firebase Cloud Messaging | Bedtime reminders |
| Analytics | PostHog Android SDK | Event tracking |
| Crash reporting | Sentry (`sentry-android`) | Error monitoring |
| CDN (sounds) | OkHttp + local cache | Sound asset delivery |
| Icons | Material Icons Extended | Material Design icons |
| Haptics | Android Vibrator + HapticFeedback | Platform-appropriate feedback |

### 3.4 Platform Abstraction Layer (KMP Expect/Actual)

The shared Kotlin Multiplatform module defines interfaces (`expect`) that each platform implements (`actual`):

```kotlin
// Shared: commonMain
expect class AudioEngine {
    fun createLayer(soundId: String): AudioLayer
    fun setVolume(layer: AudioLayer, volume: Float)
    fun setPlaybackSpeed(layer: AudioLayer, speed: Float)
    fun applyEQ(layer: AudioLayer, eq: EQProfile)
    fun startOscillation(layer: AudioLayer, config: OscillationConfig)
    fun stopOscillation(layer: AudioLayer)
}

// iOS: iosMain
actual class AudioEngine {
    private val avEngine = AVAudioEngine()
    // AVFoundation implementation
}

// Android: androidMain  
actual class AudioEngine {
    private val exoPlayer = ExoPlayer.Builder(context).build()
    // ExoPlayer implementation
}
```

**Platform abstraction interfaces:**

| Interface | iOS Implementation | Android Implementation |
|-----------|-------------------|------------------------|
| `AudioEngine` | AVAudioEngine + AudioKit | ExoPlayer + Oboe |
| `LocalStorage` | SwiftData / Core Data | Room Database |
| `TTSEngine` | AVSpeechSynthesizer | TextToSpeech |
| `SecureStorage` | Keychain | Android Keystore + EncryptedSharedPreferences |
| `NetworkClient` | URLSession | OkHttp |
| `Haptics` | UIImpactFeedbackGenerator | Vibrator |
| `PlatformInfo` | UIDevice | Build.VERSION |

### 3.5 Shared Core Module (Kotlin Multiplatform)

**Module name:** `astrosleep-core`

**Contained in shared core:**
- All business logic (scoring algorithms, transit calculations)
- Data models (data classes for charts, combos, sounds)
- Repository interfaces and implementations (except storage-specific)
- Tag engine (12-dimensional scoring with decimal precision)
- Astrological calculations (ephemeris WASM wrapper)
- Network layer interfaces (AI proxy calls)
- Subscription tier logic (entitlement checking)

**Platform-specific implementations:**
- Audio playback (native engines)
- Local database (SwiftData vs Room)
- Secure storage (Keychain vs Keystore)
- TTS engines (AVSpeech vs Android TTS)

### 3.6 Audio Engine Comparison

| Feature | iOS (AVFoundation) | Android (ExoPlayer) |
|---------|-------------------|-------------------|
| Multi-track mixing | AVAudioMixerNode | ExoPlayer MixingAudioProcessor |
| Per-track EQ | AVAudioUnitEQ | SonicAudioProcessor |
| Pitch/speed with correction | AVAudioUnitTimePitch | SonicAudioProcessor |
| LFO volume control | CADisplayLink callback | Handler/Looper at 60ms |
| Background audio | Audio session category | AudioAttributes + Service |
| Looping | isLooping property | LoopingMediaSource |

---

## 4. Platform-Specific UI Specifications

### 4.1 iOS Native UI Standards

**Navigation Patterns:**
- **Primary navigation:** Bottom tab bar with 4 tabs (Tonight, Sounds, Library, Settings)
- **Modal presentations:** Use `.sheet()` for Combo Builder, Sound Picker, EQ controls
- **Navigation bars:** Large titles with inline search where appropriate
- **Back buttons:** Automatic chevron with "Back" text per iOS standard

**Visual Design:**
- **Color scheme:** Dark mode primary (sleep app context)
  - Background: `UIColor.systemBackground` (adapts to dark mode)
  - Card surfaces: `UIColor.secondarySystemBackground`
  - Accent: `UIColor.systemIndigo` or custom deep purple `#4A148C`
  - Fire element: `UIColor.systemOrange`
  - Earth element: `UIColor.systemBrown`
  - Air element: `UIColor.systemYellow`
  - Water element: `UIColor.systemBlue`
- **Typography:** SF Pro Text/Display, Dynamic Type support
  - Headlines: `.largeTitle`, `.title1`, `.title2`
  - Body: `.body`, `.callout`
  - Captions: `.caption1`, `.caption2`
- **Icons:** SF Symbols 5.0, filled variants for active states

**Interaction Patterns:**
- **Pull to refresh:** Standard iOS spinner in list views
- **Swipe actions:** Leading/trailing actions on playlist rows
- **Context menus:** Long press for sound preview options
- **Haptics:** Light impact for button presses, success haptic for saves
- **Animated transitions:** Default SwiftUI navigation transitions

**iOS-Specific Features:**
- **Home Screen Widget:** Sleep timer display, tonight's recommendation
- **Siri Shortcuts:** "Start my sleep session" voice command (Pro)
- **Control Center:** Audio controls integration
- **Dynamic Island/Live Activities:** Session progress (iOS 16.1+)
- **Apple Watch companion:** Simple playback controls

### 4.2 Android Native UI Standards

**Navigation Patterns:**
- **Primary navigation:** Bottom navigation bar with 4 items (Tonight, Sounds, Library, Settings)
- **Modal presentations:** Full-screen destinations with shared element transitions
- **Top app bar:** Centered title with navigation icon where needed
- **Navigation drawer:** Not used (bottom nav preferred for 4 items)

**Visual Design:**
- **Color scheme:** Material3 dynamic theming with sleep-appropriate baseline
  - Background: `MaterialTheme.colorScheme.background` (dark)
  - Surface: `MaterialTheme.colorScheme.surface`
  - Primary: Deep purple `#4A148C`
  - Secondary: Soft indigo
  - Element colors mapped to Material3 palette
- **Typography:** Roboto/Roboto Flex, responsive to system font scale
  - Headlines: `headlineLarge`, `headlineMedium`
  - Body: `bodyLarge`, `bodyMedium`
  - Labels: `labelLarge`, `labelMedium`
- **Icons:** Material Icons Extended, filled variants for selected states

**Interaction Patterns:**
- **Pull to refresh:** Material circular progress indicator
- **Swipe actions:** Swipe-to-delete with undo on playlist rows
- **Contextual actions:** Bottom sheets for sound options
- **Haptics:** `HapticFeedbackConstants` for key actions
- **Animated transitions:** Material motion patterns (fade, slide)

**Android-Specific Features:**
- **App shortcuts:** Long-press app icon for "Start Sleep Session"
- **Media notification:** Rich media controls in notification shade
- **Android Wear:** Playback controls on Wear OS
- **Dynamic color:** Monet theming on Android 12+ (optional, can force dark theme)

### 4.3 Platform-Specific Component Mapping

| UI Element | iOS (SwiftUI) | Android (Compose) |
|------------|---------------|-------------------|
| Button | `Button` | `Button` (Filled, Outlined, Text) |
| Card | `Card` + `VStack` | `Card` (Elevated, Filled, Outlined) |
| Slider | `Slider` | `Slider` |
| Switch | `Toggle` | `Switch` |
| Bottom sheet | `.sheet()` | `ModalBottomSheet` |
| Alert dialog | `.alert()` | `AlertDialog` |
| List | `List` / `Form` | `LazyColumn` |
| Tab bar | `TabView` | `NavigationBar` |
| Navigation | `NavigationStack` | `NavHost` |
| Text field | `TextField` | `TextField` (Outlined, Filled) |
| Progress | `ProgressView` | `CircularProgressIndicator` |
| Pull refresh | `refreshable` | `PullRefreshIndicator` |

---

## 5. User Flows

### 5.1 Onboarding (First Launch — One Time)

```
Splash screen
  → "What is AstroSleep?" intro card (3 swipe steps, skip button)
    → iOS: Vertical page tab view with pagination dots
    → Android: Horizontal pager with indicator
  → Birth Data Entry screen
      fields: birth date, birth time (optional), birth city/location
      → geocode city to lat/lng (device GPS or manual search)
      → compute natal chart locally via WASM ephemeris
          using Sidereal zodiac + Sharatan ayanamsha (see Section 6)
      → store BaseScore vector locally (see Section 6.2)
      → birth data NEVER leaves the device
  → Name / account creation
      → email + password  OR  Sign in with Apple (iOS)  OR  Sign in with Google (Android)
      → email verification sent (email/password path)
      → on success: Supabase session token stored securely
  → Subscription prompt (dismissible, shows tier comparison)
    → iOS: Present as sheet with close button
    → Android: Full-screen with system back navigation
  → Tonight's Screen (first session)
```

### 5.2 Nightly Session (Every Night)

```
Open app
  → Check RevenueCat entitlement (CustomerInfo) — determines active tier
  → Tonight's Screen
      shows: "Good evening, [Name]" + current Moon phase icon + phase name
      shows: top recommended combo for tonight
      → iOS: Moon phase as SF Symbol animation
      → Android: Moon phase as Material icon with subtle animation
  → "What would you like to work on tonight?" text field (required)
      placeholder: "What problem would you like your subconscious to address while you rest?"
      max 280 characters
  → [Begin Tonight's Session] button
      → Check for cached affirmation (same calendar day) → use if exists
      → If no cache: POST to AI proxy (see Section 19.2)
          → on success: store affirmation + timestamp locally
          → on failure (no network / API error): show offline fallback (see Section 20.1)
      → Transit scoring pass — local, zero tokens (see Section 6.3)
      → Playback Screen opens
```

### 5.3 Sound Library Browser

```
Sounds tab
  → Grid of sound cards (icon, name, element badges)
    → iOS: LazyVGrid with 2 columns
    → Android: LazyVerticalGrid with adaptive columns
  → Filter by element (Fire / Earth / Air / Water / Ophiuchus)
  → Filter by NEW
  → Tap sound → preview plays (30-sec loop); streams from CDN if not cached locally
    → iOS: Context menu on long press
    → Android: Bottom sheet on long press
  → "Add to current combo" action
  → Sounds cached locally after first play (see Section 15.2)
```

### 5.4 Combo Builder

```
Combo Builder screen
  → iOS: Presented as sheet with drag indicator
  → Android: Full-screen destination with slide transition
  → Layer list (up to 5 layers on Pro, 2 on Basic)
  → Each ambient layer row:
      [Sound name] [Volume slider] [EQ button] [Speed button (Basic+Pro)]
      [Oscillation toggle (Pro)] [Delete button] [Drag handle]
  → Affirmation Voice row (pinned at bottom, non-reorderable):
      [Voice label] [Volume slider] [Speed button (Basic+Pro)]
  → [+ Add Sound] button → opens Sound Library picker
  → [Preview] button → plays current combo (30s)
  → [Save as Playlist] button → names combo, saves locally
  → [Auto-Generate] button (Basic+Pro) → replaces layers with AI-scored version
      → tier check before running; shows paywall if Free
```

### 5.5 Playlist Library

```
Library tab
  → List of saved combos, sorted by last played (recency)
    → iOS: List with swipe actions
    → Android: LazyColumn with dismissible items
  → Each row: combo name, layer count, element badges, last played date
  → Swipe left → delete (with confirmation)
  → Tap → opens in Combo Builder
  → Save limit enforced by tier at save time (see Section 11)
  → If user downgrades: combos over limit become read-only (not deleted)
    → banner: "Upgrade to edit or add more playlists"
```

### 5.6 Settings

```
Settings tab (iOS: Form style, Android: Preference-style list)
  → Profile: name, birth data (re-enter to recompute chart)
  → Subscription: current tier label, [Manage Subscription] → RevenueCat paywall,
                  [Restore Purchases] button
  → Audio: background audio toggle, sleep timer default
  → Affirmation: voice selection (male/female free; more on Basic+Pro),
                 global speed (0.5×–1.0×), volume offset,
                 custom voice recording (Pro — see Section 10.3)
  → Notifications: bedtime reminder toggle + time picker
  → Privacy: "Your birth data is stored only on this device and never uploaded."
             [Delete All My Data] → confirmation → wipes local DB + Supabase account
  → About: version, credits, privacy policy link, terms of service link
```

### 5.7 Account Recovery

```
Login screen → [Forgot Password?]
  → Enter email → Supabase sends reset link
  → User taps link → opens app deep link → password reset screen
    → iOS: Universal Link handling
    → Android: App Link handling
  → New password entered → Supabase updates credential
  → User redirected to Tonight's Screen
  → Local data (combos, chart) is device-only and is NOT restored on new device
    unless iCloud / Google Drive backup is enabled (see Section 14.4)
```

---

## 6. Astrological Engine

### 6.0 Astrological System Standard

All chart computation throughout AstroSleep uses the following system settings universally. These are not user-configurable; they are the app's fixed standard.

| Setting | Value |
|---------|-------|
| Zodiac type | **Sidereal** |
| Ayanamsha | **Sharatan (Beta Arietis) = 02° Aries 15'** |
| House system | **Equal (Ascendant = cusp of 1st house)** |
| Coordinate system | **Topocentric** |
| Lunar nodes | **True Nodes** |
| Planet rulership scheme | **Modern** |
| Zodiac division | **13 signs** (Ophiuchus included between Scorpio and Sagittarius) |
| Aspect display | **Aspectarian table** included in chart snapshot |
| Asteroids included | **Chiron, Lilith (Mean)** for archetypal completeness |

**13-sign sidereal boundaries (approximate sidereal ingress dates):**
- Aries: Apr 19 – May 13
- Taurus: May 14 – Jun 19
- Gemini: Jun 20 – Jul 20
- Cancer: Jul 21 – Aug 9
- Leo: Aug 10 – Sep 15
- Virgo: Sep 16 – Oct 30
- Libra: Oct 31 – Nov 22
- Scorpio: Nov 23 – Nov 29
- **Ophiuchus: Nov 30 – Dec 17**
- Sagittarius: Dec 18 – Jan 18
- Capricorn: Jan 19 – Feb 15
- Aquarius: Feb 16 – Mar 11
- Pisces: Mar 12 – Apr 18

Exact ingress dates shift slightly year to year. Compute via ephemeris WASM with Sharatan ayanamsha applied; do not hardcode.

**Elemental assignments:**
| Sign | Element | Modality |
|------|---------|----------|
| Aries | Fire | Cardinal |
| Taurus | Earth | Fixed |
| Gemini | Air | Mutable |
| Cancer | Water | Cardinal |
| Leo | Fire | Fixed |
| Virgo | Earth | Mutable |
| Libra | Air | Cardinal |
| Scorpio | Water | Fixed |
| Ophiuchus | Water | Fixed |
| Sagittarius | Fire | Mutable |
| Capricorn | Earth | Cardinal |
| Aquarius | Air | Fixed |
| Pisces | Water | Mutable |

**Ophiuchus rulership:** Chiron (Modern scheme)

### 6.1 Complete Natal Chart Computation

Run once at account creation. Uses WASM ephemeris (local, offline) with **birth date, birth time, and birth location (topocentric coordinates)**. Apply Sharatan ayanamsha to convert ecliptic longitude to sidereal positions. Use True Nodes for lunar node positions. Compute Equal house cusps from the sidereal Ascendant computed at the **birth location**.

**Important distinction:** The natal chart is permanently tied to the birth location. Transit scoring (Section 6.3) optionally uses the **user's current location** (if different from birth location) to compute current house placements and angular emphasis for that night's transits.

**Compute and store locally only:**

| Variable | Type | Weight in Scoring |
|----------|------|-------------------|
| Sun sign | Element + Modality | Weight 2.0 |
| Moon sign | Element + Modality | Weight 4.0 (highest) |
| Ascendant / Rising sign | Element + Modality | Weight 1.5 |
| Mercury sign | Element + Modality | Weight 1.0 |
| Venus sign | Element + Modality | Weight 1.5 |
| Mars sign | Element + Modality | Weight 1.0 |
| Jupiter sign | Element + Modality | Weight 0.8 |
| Saturn sign | Element + Modality | Weight 0.7 |
| Uranus sign | Element + Modality | Weight 0.5 |
| Neptune sign | Element + Modality | Weight 0.8 |
| Pluto sign | Element + Modality | Weight 0.6 |
| Chiron sign | Element + Modality | Weight 0.5 |
| Lilith (Mean) sign | Element + Modality | Weight 0.4 |
| North Node | Element only | Weight 0.6 |
| South Node | Element only | Weight 0.4 |
| Dominant element | Plurality | Bonus +2.0 |
| Dominant modality | Cardinal/Fixed/Mutable | Modifier (see 6.2) |
| Natal Moon house | 1-12 | House tag in scoring |
| Natal Sun house | 1-12 | House tag in scoring |
| Natal chart aspectarian | Conjunctions, sextiles, squares, trines, oppositions | Stored for display |
| Stelliums | 3+ planets in same sign | Stellium tag in scoring |
| House rulers | Each house cusp ruler | Ruler tag in scoring |

**Birth data privacy:** Raw birth date, time, and location are stored in local database on-device only. They are never sent to Supabase, the AI proxy, RevenueCat, or any analytics service. The only data that leaves the device are: the anonymized user ID (for auth), the nightly intention text (sent to AI proxy for affirmation generation), and RevenueCat purchase events.

### 6.2 Base Score Derivation (Computed Once, Stored)

The BaseScore is a [Fire, Earth, Air, Water] vector stored as the user's natal profile with decimal precision (Float/Double).

```kotlin
fun deriveBaseScore(natalChart: NatalChart): ElementVector {
    val score = ElementVector(0.0, 0.0, 0.0, 0.0)  // [Fire, Earth, Air, Water]

    // Moon sign — weight 4.0 (strongest influence on sleep)
    score += ELEMENT_VECTOR[natalChart.moonSign] * 4.0

    // Sun sign — weight 2.0
    score += ELEMENT_VECTOR[natalChart.sunSign] * 2.0

    // Ascendant — weight 1.5 (if available)
    natalChart.ascendant?.let {
        score += ELEMENT_VECTOR[it] * 1.5
    }

    // Personal planets
    score += ELEMENT_VECTOR[natalChart.mercury] * 1.0
    score += ELEMENT_VECTOR[natalChart.venus] * 1.5
    score += ELEMENT_VECTOR[natalChart.mars] * 1.0

    // Social planets
    score += ELEMENT_VECTOR[natalChart.jupiter] * 0.8
    score += ELEMENT_VECTOR[natalChart.saturn] * 0.7

    // Transpersonal planets
    score += ELEMENT_VECTOR[natalChart.uranus] * 0.5
    score += ELEMENT_VECTOR[natalChart.neptune] * 0.8
    score += ELEMENT_VECTOR[natalChart.pluto] * 0.6

    // Asteroids
    score += ELEMENT_VECTOR[natalChart.chiron] * 0.5
    score += ELEMENT_VECTOR[natalChart.lilith] * 0.4

    // Lunar nodes (element only)
    score[natalChart.northNode.element] += 0.6
    score[natalChart.southNode.element] += 0.4

    // Dominant element bonus
    val dominantElement = score.dominant()
    score[dominantElement] += 2.0

    // Modality modifier
    val dominantModality = natalChart.dominantModality()
    when (dominantModality) {
        Modality.FIXED -> score[Element.EARTH] += 1.0  // stability preference
        Modality.CARDINAL -> score[Element.FIRE] += 1.0  // initiation preference
        Modality.MUTABLE -> score[Element.AIR] += 1.0  // adaptability preference
    }

    // Stellium bonus (3+ planets in same sign)
    natalChart.stelliums().forEach { stelliumSign ->
        score += ELEMENT_VECTOR[stelliumSign] * 1.2
    }

    // House placements (if birth time known)
    if (natalChart.hasBirthTime) {
        // Moon house weight 1.0
        score += HOUSE_ELEMENT_BIAS[natalChart.moonHouse] * 1.0
        // Sun house weight 0.5
        score += HOUSE_ELEMENT_BIAS[natalChart.sunHouse] * 0.5
        // House rulers
        for (house in 1..12) {
            val ruler = natalChart.houseRuler(house)
            score += ELEMENT_VECTOR[ruler] * 0.3
        }
    }

    return score.normalize(10.0)  // scale to 0–10 with decimal precision
}

// Element vectors (archetypal signatures)
val ELEMENT_VECTOR = mapOf(
    Sign.ARIES to ElementVector(4.0, 0.0, 1.0, 0.0),
    Sign.TAURUS to ElementVector(0.0, 4.0, 0.0, 1.0),
    Sign.GEMINI to ElementVector(1.0, 0.0, 4.0, 0.0),
    Sign.CANCER to ElementVector(0.0, 1.0, 0.0, 4.0),
    Sign.LEO to ElementVector(4.0, 0.0, 1.0, 0.0),
    Sign.VIRGO to ElementVector(0.0, 4.0, 0.0, 1.0),
    Sign.LIBRA to ElementVector(1.0, 0.0, 4.0, 0.0),
    Sign.SCORPIO to ElementVector(0.0, 1.0, 0.0, 4.0),
    Sign.OPHIUCHUS to ElementVector(1.0, 1.0, 2.0, 5.0),  // deep Water with Air
    Sign.SAGITTARIUS to ElementVector(4.0, 0.0, 1.0, 0.0),
    Sign.CAPRICORN to ElementVector(0.0, 4.0, 0.0, 1.0),
    Sign.AQUARIUS to ElementVector(1.0, 0.0, 4.0, 0.0),
    Sign.PISCES to ElementVector(0.0, 1.0, 0.0, 4.0),
)

// House elemental biases (Equal house system)
val HOUSE_ELEMENT_BIAS = mapOf(
    1 to ElementVector(3.0, 0.0, 1.0, 0.0),   // Fire house (identity)
    2 to ElementVector(0.0, 4.0, 0.0, 1.0),   // Earth house (resources)
    3 to ElementVector(1.0, 0.0, 4.0, 0.0),   // Air house (communication)
    4 to ElementVector(0.0, 1.0, 0.0, 4.0),   // Water house (home/roots)
    5 to ElementVector(4.0, 0.0, 1.0, 0.0),   // Fire house (creativity)
    6 to ElementVector(0.0, 4.0, 0.0, 1.0),   // Earth house (service)
    7 to ElementVector(1.0, 0.0, 4.0, 0.0),   // Air house (relationships)
    8 to ElementVector(0.0, 1.0, 0.0, 4.0),   // Water house (transformation)
    9 to ElementVector(4.0, 0.0, 1.0, 0.0),   // Fire house (philosophy)
    10 to ElementVector(0.0, 4.0, 0.0, 1.0),  // Earth house (career)
    11 to ElementVector(1.0, 0.0, 4.0, 0.0),  // Air house (community)
    12 to ElementVector(0.0, 1.0, 0.0, 4.0),  // Water house (spirituality)
)
```

### 6.3 Nightly Transit Scoring (Zero Tokens, Run Each Session)

All transit positions computed in sidereal (Sharatan ayanamsha), topocentric, True Nodes.

**Location-aware transit scoring:** If the user has enabled "Use Current Location for Transits" and provided current coordinates, the engine computes current planetary positions and house cusps using the **current location** rather than defaulting to the equator (0, 0). This affects:
- Current house placements for transiting planets
- Angular emphasis boost (1.3x) when a transiting planet is in an angular house (1st, 4th, 7th, 10th) at the current location
- Accurate ascendant-derived house cusps for tonight's sky at the user's actual location

```kotlin
fun calculateNightlyScore(
    baseScore: ElementVector,
    currentDate: DateTime,
    natalChart: NatalChart,
    currentLat: Double = 0.0,
    currentLng: Double = 0.0,
    useCurrentLocation: Boolean = false
): NightlyScoreResult {
    val score = baseScore.copy()

    // Moon phase influence
    val moonPhase = calculateMoonPhase(currentDate)
    score += PHASE_DELTAS[moonPhase] ?: ElementVector.ZERO

    // Use current location for transits if available; fall back to generic (lat=0, lng=0)
    val transitLat = if (useCurrentLocation) currentLat else 0.0
    val transitLng = if (useCurrentLocation) currentLng else 0.0

    // Active transits — computed with current location for house placement & angular emphasis
    val transits = calculateTransits(currentDate, natalChart, transitLat, transitLng, useCurrentLocation)
    for (transit in transits) {
        val delta = TRANSIT_DELTAS[transit.planet]?.get(transit.aspectType)
        if (delta != null) {
            score += delta * transit.orbFactor * transit.angularBoost
        }
    }

    // Current house emphasis (if birth time known)
    if (natalChart.hasBirthTime) {
        val currentHouses = calculateCurrentHousePlacements(currentDate, natalChart, transitLat, transitLng)
        for (placement in currentHouses) {
            score += HOUSE_ELEMENT_BIAS[placement.house]!! * 0.5 * placement.planetWeight
        }
    }

    // Stellium detection in current transits
    val currentStelliums = detectStelliums(transits.map { it.transitingPlanet })
    for (stellium in currentStelliums) {
        score += ELEMENT_VECTOR[stellium.sign]!! * 0.8
    }

    // Return enhanced score with metadata
    return NightlyScoreResult(
        elementScore = score.normalize(10.0),
        moonPhase = moonPhase,
        activeTransits = transits,
        dominantElement = score.dominant(),
        topTransit = transits.maxByOrNull { it.strength },
        stelliums = currentStelliums
    )
}
```

### 6.4 Phase and Transit Deltas

```kotlin
val PHASE_DELTAS = mapOf(
    MoonPhase.NEW_MOON to ElementVector(1.0, 0.0, 0.0, 2.0),
    MoonPhase.WAXING_CRESCENT to ElementVector(1.0, 0.0, 1.0, 1.0),
    MoonPhase.FIRST_QUARTER to ElementVector(2.0, 0.0, 1.0, 0.0),
    MoonPhase.WAXING_GIBBOUS to ElementVector(1.0, 1.0, 0.0, 1.0),
    MoonPhase.FULL_MOON to ElementVector(0.0, 0.0, 2.0, 2.0),
    MoonPhase.WANING_GIBBOUS to ElementVector(0.0, 1.0, 1.0, 1.0),
    MoonPhase.LAST_QUARTER to ElementVector(0.0, 2.0, 0.0, 1.0),
    MoonPhase.WANING_CRESCENT to ElementVector(0.0, 1.0, 0.0, 3.0),
)

val TRANSIT_DELTAS = mapOf(
    Planet.MOON to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 0.0, 3.0),
        Aspect.TRINE to ElementVector(0.0, 0.0, 1.0, 2.0),
        Aspect.SQUARE to ElementVector(2.0, 0.0, 0.0, 1.0),
        Aspect.SEXTILE to ElementVector(0.0, 0.0, 1.0, 1.5)
    ),
    Planet.VENUS to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.0, 1.0, 1.0, 2.0),
        Aspect.TRINE to ElementVector(0.0, 1.0, 0.0, 1.0),
        Aspect.SEXTILE to ElementVector(0.5, 0.5, 0.5, 1.0)
    ),
    Planet.MARS to mapOf(
        Aspect.CONJUNCTION to ElementVector(3.0, 0.0, 1.0, 0.0),
        Aspect.SQUARE to ElementVector(3.0, 0.0, 0.0, -1.0),
        Aspect.TRINE to ElementVector(2.0, 0.0, 0.5, 0.0)
    ),
    Planet.JUPITER to mapOf(
        Aspect.CONJUNCTION to ElementVector(2.0, 1.0, 1.0, 1.0),
        Aspect.TRINE to ElementVector(1.0, 1.0, 1.0, 1.0),
        Aspect.SEXTILE to ElementVector(1.5, 0.5, 1.0, 0.5)
    ),
    Planet.SATURN to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.0, 3.0, 0.0, 0.0),
        Aspect.TRINE to ElementVector(0.0, 2.0, 0.0, 0.0),
        Aspect.SQUARE to ElementVector(-1.0, 2.0, 0.0, 0.0)
    ),
    Planet.URANUS to mapOf(
        Aspect.CONJUNCTION to ElementVector(1.0, 0.0, 3.0, 0.0),
        Aspect.TRINE to ElementVector(0.5, 0.0, 2.0, 0.0)
    ),
    Planet.NEPTUNE to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 1.0, 3.0),
        Aspect.TRINE to ElementVector(0.0, 0.0, 1.0, 2.0),
        Aspect.SEXTILE to ElementVector(0.0, 0.0, 0.5, 1.5)
    ),
    Planet.PLUTO to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 0.0, 4.0),
        Aspect.TRINE to ElementVector(0.0, 0.0, 0.0, 2.5),
        Aspect.SQUARE to ElementVector(0.0, 0.0, 0.0, 2.0)
    ),
    Planet.CHIRON to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.5, 0.0, 1.0, 2.0),
        Aspect.TRINE to ElementVector(0.0, 0.0, 0.5, 1.5)
    ),
    Planet.LILITH to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 0.0, 1.5),
        Aspect.SQUARE to ElementVector(0.0, 0.0, 0.0, 1.0)
    ),
    Planet.NORTH_NODE to mapOf(
        Aspect.CONJUNCTION to ElementVector(0.5, 0.5, 0.5, 1.0)
    )
)
```

### 6.5 Sound Ranking Formula

```kotlin
fun rankSounds(
    nightlyScore: NightlyScoreResult,
    sounds: List<Sound>,
    tagEngine: TagEngine
): List<RankedSound> {
    val nightlyElementScore = nightlyScore.elementScore

    return sounds.map { sound ->
        // Get sound's archetypal tag vector
        val tagVector = tagEngine.calculateTagVector(sound)
        
        // Calculate weighted dot product with decimal precision
        val rankScore = (
            nightlyElementScore.fire * tagVector.fire +
            nightlyElementScore.earth * tagVector.earth +
            nightlyElementScore.air * tagVector.air +
            nightlyElementScore.water * tagVector.water
        ) / 4.0  // normalize to 0-10 scale

        RankedSound(
            sound = sound,
            score = rankScore.roundTo(2),  // 2 decimal places
            matchPercentage = (rankScore * 10).roundTo(1)  // percentage
        )
    }.sortedByDescending { it.score }
}
```

---

## 7. Tag Engine v3.0 — 12-Dimensional Archetypal Scoring

### 7.1 Tag Dimensions (12 total)

| Dimension | Options | Archetypal Significance |
|-----------|---------|------------------------|
| `domain` | water, air, fire, earth, mechanical, organic, electrical, cosmic | Elemental identity (weight 9) |
| `rhythm` | steady, pulse, irregular, chaotic, rhythmic, arrhythmic | Modality / temporal pattern |
| `register` | deep, mid, bright, full, sub, ultrasonic | Frequency-element correspondence |
| `context` | nature, domestic, abstract, urban, industrial, spiritual | Environmental / house association |
| `weight` | light, medium, heavy, massive, ethereal | Density / planetary affinity |
| `texture` | smooth, rough, crystalline, diffuse, granular, glassy, metallic | Tactile quality |
| `motion` | static, flowing, surging, swirling, oscillating, drifting, pulsing | Movement archetype |
| `density` | sparse, moderate, dense, saturated, vacuum | Signal saturation |
| `temperature` | cool, warm, hot, cold, neutral | Thermal quality |
| `polarity` | active, receptive, balanced, neutral | Yang/Yin / modality |
| `celestial` | solar, lunar, stellar, planetary, void | Astronomical correspondence |
| `archetype` | maiden, mother, crone, hero, mentor, shadow, trickster | Jungian / mythic mapping |

### 7.2 Vector Tables (decimal precision — [Fire, Earth, Air, Water])

```kotlin
object TagVectors {
    val domain = mapOf(
        "water" to ElementVector(0.5, 1.5, 1.0, 9.0),
        "air" to ElementVector(1.5, 0.5, 9.0, 1.0),
        "fire" to ElementVector(9.0, 0.5, 1.5, 0.5),
        "earth" to ElementVector(0.5, 9.0, 0.5, 1.5),
        "mechanical" to ElementVector(1.5, 6.0, 2.0, 1.0),
        "organic" to ElementVector(1.0, 5.0, 1.5, 4.0),
        "electrical" to ElementVector(3.0, 1.0, 7.0, 0.5),
        "cosmic" to ElementVector(4.0, 1.0, 6.0, 2.0),
    )

    val rhythm = mapOf(
        "steady" to ElementVector(0.0, 3.0, 0.5, 1.5),
        "pulse" to ElementVector(1.0, 2.0, 1.0, 1.5),
        "irregular" to ElementVector(2.0, 0.0, 2.0, 1.5),
        "chaotic" to ElementVector(3.0, 0.0, 2.5, 0.5),
        "rhythmic" to ElementVector(1.5, 2.0, 1.0, 2.0),
        "arrhythmic" to ElementVector(1.0, 0.0, 2.0, 2.0),
    )

    val register = mapOf(
        "sub" to ElementVector(0.0, 3.0, 0.0, 2.0),
        "deep" to ElementVector(0.0, 2.5, 0.0, 1.5),
        "mid" to ElementVector(1.0, 1.5, 1.0, 1.0),
        "bright" to ElementVector(1.5, 0.5, 2.5, 0.0),
        "full" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "ultrasonic" to ElementVector(0.5, 0.0, 3.0, 0.0),
    )

    val context = mapOf(
        "nature" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "domestic" to ElementVector(0.0, 2.0, 0.5, 1.5),
        "abstract" to ElementVector(0.5, 0.0, 2.0, 1.0),
        "urban" to ElementVector(1.5, 1.0, 2.0, 0.5),
        "industrial" to ElementVector(1.0, 3.0, 1.5, 0.0),
        "spiritual" to ElementVector(1.0, 0.5, 2.0, 2.5),
    )

    val weight = mapOf(
        "ethereal" to ElementVector(0.0, 0.0, 2.0, 1.0),
        "light" to ElementVector(0.0, 0.0, 1.5, 1.5),
        "medium" to ElementVector(1.0, 1.5, 0.5, 0.5),
        "heavy" to ElementVector(2.5, 1.0, 1.0, 0.5),
        "massive" to ElementVector(2.0, 3.0, 0.0, 0.0),
    )

    val texture = mapOf(
        "smooth" to ElementVector(1.0, 2.5, 1.0, 3.0),
        "rough" to ElementVector(3.5, 3.5, 0.5, 1.0),
        "crystalline" to ElementVector(2.5, 1.0, 4.0, 1.5),
        "diffuse" to ElementVector(1.0, 1.0, 2.5, 3.0),
        "granular" to ElementVector(2.0, 2.0, 1.0, 1.0),
        "glassy" to ElementVector(1.5, 1.0, 3.5, 1.0),
        "metallic" to ElementVector(2.0, 3.0, 2.0, 0.0),
    )

    val motion = mapOf(
        "static" to ElementVector(0.0, 4.0, 0.0, 1.0),
        "flowing" to ElementVector(1.0, 0.0, 1.0, 4.0),
        "surging" to ElementVector(4.5, 0.0, 2.0, 1.0),
        "swirling" to ElementVector(2.5, 0.0, 4.0, 1.0),
        "oscillating" to ElementVector(2.0, 1.0, 3.0, 1.0),
        "drifting" to ElementVector(1.0, 0.5, 3.0, 2.5),
        "pulsing" to ElementVector(2.5, 0.5, 1.5, 2.0),
    )

    val density = mapOf(
        "vacuum" to ElementVector(3.0, 0.0, 2.5, 1.0),
        "sparse" to ElementVector(2.5, 0.0, 2.0, 1.0),
        "moderate" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "dense" to ElementVector(1.0, 3.0, 1.0, 2.0),
        "saturated" to ElementVector(1.5, 2.5, 2.0, 2.5),
    )

    val temperature = mapOf(
        "cold" to ElementVector(0.0, 3.0, 1.0, 2.0),
        "cool" to ElementVector(0.5, 2.0, 1.5, 2.0),
        "neutral" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "warm" to ElementVector(2.5, 1.0, 1.5, 1.0),
        "hot" to ElementVector(4.0, 0.5, 1.0, 0.0),
    )

    val polarity = mapOf(
        "active" to ElementVector(3.0, 1.0, 2.0, 0.5),
        "receptive" to ElementVector(0.5, 2.0, 1.0, 3.0),
        "balanced" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "neutral" to ElementVector(1.0, 1.0, 1.0, 1.0),
    )

    val celestial = mapOf(
        "solar" to ElementVector(4.0, 0.5, 1.0, 0.0),
        "lunar" to ElementVector(0.0, 1.0, 0.0, 4.0),
        "stellar" to ElementVector(1.0, 0.5, 3.0, 1.0),
        "planetary" to ElementVector(1.5, 1.5, 1.5, 1.5),
        "void" to ElementVector(0.5, 0.5, 0.5, 0.5),
    )

    val archetype = mapOf(
        "maiden" to ElementVector(1.0, 0.5, 3.0, 1.0),
        "mother" to ElementVector(0.5, 2.0, 0.5, 3.0),
        "crone" to ElementVector(1.0, 3.0, 2.0, 2.0),
        "hero" to ElementVector(4.0, 1.0, 2.0, 0.5),
        "mentor" to ElementVector(1.5, 3.0, 2.0, 1.0),
        "shadow" to ElementVector(0.5, 0.5, 1.0, 4.0),
        "trickster" to ElementVector(2.0, 0.5, 4.0, 1.0),
    )
}
```

### 7.3 Scoring Algorithm (Decimal Precision)

```kotlin
class TagEngine {
    private val dimensions = listOf(
        "domain", "rhythm", "register", "context", "weight",
        "texture", "motion", "density", "temperature", 
        "polarity", "celestial", "archetype"
    )

    fun calculateTagVector(sound: Sound): ElementVector {
        val raw = ElementVector.ZERO

        dimensions.forEach { dim ->
            val tagValue = sound.tags[dim]
            val vectorTable = getVectorTable(dim)
            val vector = vectorTable[tagValue]
            
            if (vector != null) {
                // Apply dimension weight (domain has highest weight)
                val weight = when (dim) {
                    "domain" -> 9.0
                    "celestial", "archetype" -> 4.0
                    "rhythm", "motion" -> 3.0
                    else -> 2.0
                }
                raw += vector * weight
            }
        }

        return raw
    }

    fun normalizeSoundVectors(sounds: List<Sound>): List<SoundScore> {
        val rawScores = sounds.map { calculateTagVector(it) }
        
        // Find max per element for normalization
        val maxValues = ElementVector(
            fire = rawScores.maxOf { it.fire },
            earth = rawScores.maxOf { it.earth },
            air = rawScores.maxOf { it.air },
            water = rawScores.maxOf { it.water }
        )

        return rawScores.map { raw ->
            SoundScore(
                fire = if (maxValues.fire > 0) (raw.fire / maxValues.fire * 10.0).roundTo(2) else 0.0,
                earth = if (maxValues.earth > 0) (raw.earth / maxValues.earth * 10.0).roundTo(2) else 0.0,
                air = if (maxValues.air > 0) (raw.air / maxValues.air * 10.0).roundTo(2) else 0.0,
                water = if (maxValues.water > 0) (raw.water / maxValues.water * 10.0).roundTo(2) else 0.0
            )
        }
    }

    private fun Double.roundTo(decimals: Int): Double {
        val factor = 10.0.pow(decimals)
        return (this * factor).roundToInt() / factor
    }
}
```

### 7.4 Adding a New Sound — 5-Step Checklist

1. **Record or license audio file.** Export as `.m4a`, 44.1kHz, 16-bit, loop-trimmed to zero crossings.
2. **In the dev admin tool:** Add entry with unique `id`, `name`, and all **12 tags**. Use the Upload tab to push the file to Cloudflare R2 (see Section 16).
3. **Run normalization** and verify scores in the admin tool preview (decimal precision visible).
4. **Click "Publish"** in the admin tool — this writes the updated `sounds_manifest.json` to R2 and invalidates the CDN cache. The app fetches the manifest on next launch.
5. **No app update required.** No other code changes needed.

---

## 8. Sound Library

### 8.1 Sound Data Model with 12-Dimensional Tags

```kotlin
data class Sound(
    val id: String,                    // Unique identifier (snake_case)
    val name: String,                  // Display name
    val tags: SoundTags,               // 12-dimensional tag set
    val elementScores: ElementVector,  // Computed [Fire, Earth, Air, Water]
    val durationSeconds: Int,          // Loop length (30-120s)
    val isNew: Boolean = false,        // New release badge
    val version: Int = 1               // For cache invalidation
)

data class SoundTags(
    val domain: String,      // water, air, fire, earth, mechanical, organic, electrical, cosmic
    val rhythm: String,      // steady, pulse, irregular, chaotic, rhythmic, arrhythmic
    val register: String,    // sub, deep, mid, bright, full, ultrasonic
    val context: String,     // nature, domestic, abstract, urban, industrial, spiritual
    val weight: String,      // ethereal, light, medium, heavy, massive
    val texture: String,     // smooth, rough, crystalline, diffuse, granular, glassy, metallic
    val motion: String,      // static, flowing, surging, swirling, oscillating, drifting, pulsing
    val density: String,     // vacuum, sparse, moderate, dense, saturated
    val temperature: String, // cold, cool, neutral, warm, hot
    val polarity: String,    // active, receptive, balanced, neutral
    val celestial: String,   // solar, lunar, stellar, planetary, void
    val archetype: String    // maiden, mother, crone, hero, mentor, shadow, trickster
)
```

### 8.2 Sample Sound Library (23 Sounds — All 12 Tags)

```kotlin
val SOUNDS = listOf(
    Sound(
        id = "heavy_rain",
        name = "Heavy Rain",
        tags = SoundTags(
            domain = "water", rhythm = "irregular", register = "mid",
            context = "nature", weight = "heavy", texture = "rough",
            motion = "flowing", density = "dense", temperature = "cool",
            polarity = "receptive", celestial = "lunar", archetype = "mother"
        ),
        elementScores = ElementVector(0.45, 0.82, 0.38, 0.91),
        durationSeconds = 60
    ),
    Sound(
        id = "light_rain",
        name = "Light Rain",
        tags = SoundTags(
            domain = "water", rhythm = "irregular", register = "bright",
            context = "nature", weight = "light", texture = "crystalline",
            motion = "flowing", density = "sparse", temperature = "cool",
            polarity = "receptive", celestial = "lunar", archetype = "maiden"
        ),
        elementScores = ElementVector(0.32, 0.45, 0.55, 0.78),
        durationSeconds = 45
    ),
    Sound(
        id = "thunder",
        name = "Thunderstorm",
        tags = SoundTags(
            domain = "electrical", rhythm = "chaotic", register = "full",
            context = "nature", weight = "massive", texture = "rough",
            motion = "surging", density = "saturated", temperature = "cool",
            polarity = "active", celestial = "planetary", archetype = "shadow"
        ),
        elementScores = ElementVector(0.88, 0.65, 0.72, 0.41),
        durationSeconds = 90
    ),
    Sound(
        id = "ocean",
        name = "Ocean Waves",
        tags = SoundTags(
            domain = "water", rhythm = "pulse", register = "deep",
            context = "nature", weight = "medium", texture = "smooth",
            motion = "flowing", density = "dense", temperature = "cool",
            polarity = "receptive", celestial = "lunar", archetype = "mother"
        ),
        elementScores = ElementVector(0.28, 0.48, 0.35, 0.89),
        durationSeconds = 60
    ),
    Sound(
        id = "river",
        name = "River / Stream",
        tags = SoundTags(
            domain = "water", rhythm = "rhythmic", register = "mid",
            context = "nature", weight = "medium", texture = "rough",
            motion = "flowing", density = "moderate", temperature = "cool",
            polarity = "receptive", celestial = "planetary", archetype = "mentor"
        ),
        elementScores = ElementVector(0.35, 0.62, 0.42, 0.81),
        durationSeconds = 60
    ),
    Sound(
        id = "forest",
        name = "Forest / Birds",
        tags = SoundTags(
            domain = "organic", rhythm = "arrhythmic", register = "full",
            context = "nature", weight = "light", texture = "diffuse",
            motion = "drifting", density = "moderate", temperature = "neutral",
            polarity = "balanced", celestial = "stellar", archetype = "trickster"
        ),
        elementScores = ElementVector(0.42, 0.58, 0.48, 0.52),
        durationSeconds = 90
    ),
    Sound(
        id = "wind",
        name = "Wind",
        tags = SoundTags(
            domain = "air", rhythm = "irregular", register = "bright",
            context = "nature", weight = "medium", texture = "diffuse",
            motion = "swirling", density = "sparse", temperature = "cool",
            polarity = "active", celestial = "planetary", archetype = "trickster"
        ),
        elementScores = ElementVector(0.55, 0.25, 0.88, 0.32),
        durationSeconds = 60
    ),
    Sound(
        id = "fire",
        name = "Fire / Crackling",
        tags = SoundTags(
            domain = "fire", rhythm = "irregular", register = "mid",
            context = "nature", weight = "medium", texture = "rough",
            motion = "surging", density = "moderate", temperature = "hot",
            polarity = "active", celestial = "solar", archetype = "hero"
        ),
        elementScores = ElementVector(0.92, 0.35, 0.48, 0.25),
        durationSeconds = 60
    ),
    Sound(
        id = "white_noise",
        name = "White Noise",
        tags = SoundTags(
            domain = "electrical", rhythm = "steady", register = "full",
            context = "abstract", weight = "medium", texture = "smooth",
            motion = "static", density = "saturated", temperature = "neutral",
            polarity = "neutral", celestial = "void", archetype = "crone"
        ),
        elementScores = ElementVector(0.48, 0.52, 0.51, 0.49),
        durationSeconds = 30
    ),
    Sound(
        id = "brown_noise",
        name = "Brown Noise",
        tags = SoundTags(
            domain = "earth", rhythm = "steady", register = "sub",
            context = "abstract", weight = "medium", texture = "smooth",
            motion = "static", density = "dense", temperature = "cool",
            polarity = "receptive", celestial = "planetary", archetype = "mother"
        ),
        elementScores = ElementVector(0.25, 0.88, 0.22, 0.65),
        durationSeconds = 30
    ),
    Sound(
        id = "pink_noise",
        name = "Pink Noise",
        tags = SoundTags(
            domain = "electrical", rhythm = "steady", register = "full",
            context = "abstract", weight = "light", texture = "smooth",
            motion = "static", density = "moderate", temperature = "neutral",
            polarity = "balanced", celestial = "stellar", archetype = "mentor"
        ),
        elementScores = ElementVector(0.42, 0.48, 0.55, 0.45),
        durationSeconds = 30
    ),
    Sound(
        id = "binaural",
        name = "Tibetan / Binaural",
        tags = SoundTags(
            domain = "cosmic", rhythm = "pulse", register = "sub",
            context = "spiritual", weight = "ethereal", texture = "crystalline",
            motion = "oscillating", density = "sparse", temperature = "cool",
            polarity = "receptive", celestial = "stellar", archetype = "crone"
        ),
        elementScores = ElementVector(0.35, 0.72, 0.68, 0.45),
        durationSeconds = 120
    ),
    Sound(
        id = "sprinklers",
        name = "Sprinklers",
        tags = SoundTags(
            domain = "mechanical", rhythm = "pulse", register = "bright",
            context = "domestic", weight = "light", texture = "crystalline",
            motion = "pulsing", density = "sparse", temperature = "cool",
            polarity = "active", celestial = "planetary", archetype = "maiden"
        ),
        elementScores = ElementVector(0.48, 0.58, 0.62, 0.32),
        durationSeconds = 45
    ),
    Sound(
        id = "fan_low",
        name = "Box Fan (Low)",
        tags = SoundTags(
            domain = "mechanical", rhythm = "steady", register = "deep",
            context = "domestic", weight = "light", texture = "smooth",
            motion = "static", density = "moderate", temperature = "cool",
            polarity = "neutral", celestial = "planetary", archetype = "mentor"
        ),
        elementScores = ElementVector(0.32, 0.68, 0.45, 0.35),
        durationSeconds = 60
    ),
    Sound(
        id = "fan_med",
        name = "Box Fan (Med)",
        tags = SoundTags(
            domain = "mechanical", rhythm = "steady", register = "mid",
            context = "domestic", weight = "medium", texture = "smooth",
            motion = "static", density = "moderate", temperature = "cool",
            polarity = "neutral", celestial = "planetary", archetype = "mentor"
        ),
        elementScores = ElementVector(0.35, 0.65, 0.48, 0.32),
        durationSeconds = 60
    ),
    Sound(
        id = "fan_high",
        name = "Box Fan (High)",
        tags = SoundTags(
            domain = "air", rhythm = "steady", register = "bright",
            context = "domestic", weight = "medium", texture = "diffuse",
            motion = "swirling", density = "moderate", temperature = "cool",
            polarity = "active", celestial = "planetary", archetype = "hero"
        ),
        elementScores = ElementVector(0.55, 0.35, 0.82, 0.28),
        durationSeconds = 60
    ),
    Sound(
        id = "wtfl_sm",
        name = "Small Waterfall",
        tags = SoundTags(
            domain = "water", rhythm = "steady", register = "bright",
            context = "nature", weight = "medium", texture = "crystalline",
            motion = "flowing", density = "moderate", temperature = "cool",
            polarity = "receptive", celestial = "lunar", archetype = "maiden"
        ),
        elementScores = ElementVector(0.38, 0.52, 0.48, 0.72),
        durationSeconds = 60
    ),
    Sound(
        id = "wtfl_lg",
        name = "Large Waterfall",
        tags = SoundTags(
            domain = "water", rhythm = "steady", register = "sub",
            context = "nature", weight = "heavy", texture = "rough",
            motion = "surging", density = "dense", temperature = "cool",
            polarity = "active", celestial = "lunar", archetype = "mother"
        ),
        elementScores = ElementVector(0.42, 0.65, 0.35, 0.88),
        durationSeconds = 90
    ),
    Sound(
        id = "car_rain",
        name = "Car in Rain",
        tags = SoundTags(
            domain = "mechanical", rhythm = "rhythmic", register = "mid",
            context = "urban", weight = "medium", texture = "smooth",
            motion = "flowing", density = "dense", temperature = "cool",
            polarity = "receptive", celestial = "planetary", archetype = "shadow"
        ),
        elementScores = ElementVector(0.35, 0.62, 0.48, 0.55),
        durationSeconds = 60
    ),
    Sound(
        id = "dryer",
        name = "Clothes Dryer",
        tags = SoundTags(
            domain = "mechanical", rhythm = "pulse", register = "deep",
            context = "domestic", weight = "medium", texture = "smooth",
            motion = "swirling", density = "moderate", temperature = "warm",
            polarity = "receptive", celestial = "planetary", archetype = "mother"
        ),
        elementScores = ElementVector(0.42, 0.72, 0.38, 0.48),
        durationSeconds = 60
    ),
    Sound(
        id = "lawn_mower",
        name = "Lawn Mower (Distant)",
        tags = SoundTags(
            domain = "mechanical", rhythm = "steady", register = "deep",
            context = "urban", weight = "heavy", texture = "rough",
            motion = "static", density = "dense", temperature = "neutral",
            polarity = "active", celestial = "planetary", archetype = "hero"
        ),
        elementScores = ElementVector(0.52, 0.78, 0.42, 0.28),
        durationSeconds = 60
    ),
    Sound(
        id = "clock_tick",
        name = "Clock Ticking",
        tags = SoundTags(
            domain = "mechanical", rhythm = "pulse", register = "bright",
            context = "domestic", weight = "light", texture = "crystalline",
            motion = "pulsing", density = "sparse", temperature = "neutral",
            polarity = "balanced", celestial = "planetary", archetype = "crone"
        ),
        elementScores = ElementVector(0.42, 0.55, 0.62, 0.41),
        durationSeconds = 30
    ),
    Sound(
        id = "sink_faucet",
        name = "Sink Faucet",
        tags = SoundTags(
            domain = "water", rhythm = "steady", register = "bright",
            context = "domestic", weight = "light", texture = "smooth",
            motion = "flowing", density = "sparse", temperature = "cool",
            polarity = "receptive", celestial = "lunar", archetype = "maiden"
        ),
        elementScores = ElementVector(0.32, 0.45, 0.52, 0.71),
        durationSeconds = 45
    )
)
```

---

## 9. Combo System

### 9.1 Data Model (Complete JSON Schema)

```kotlin
data class Combo(
    val id: String,                    // UUID v4
    val name: String,                  // User-defined name
    val createdAt: Instant,            // ISO-8601 timestamp
    val lastPlayedAt: Instant?,         // ISO-8601 timestamp
    val source: ComboSource,          // AUTO or USER
    val chartSnapshot: ChartSnapshot,   // Nightly chart state
    val layers: List<AmbientLayer>,     // 1-5 ambient layers
    val affirmationLayer: AffirmationLayer,  // Always present
    val isReadOnly: Boolean = false     // Tier downgrade protection
)

enum class ComboSource { AUTO, USER }

data class AmbientLayer(
    val soundId: String,
    val layerType: LayerType = LayerType.AMBIENT,
    val volume: Double,               // 0.0 - 1.0 (decimal precision)
    val playbackSpeed: Double,        // 0.5 - 2.0 (decimal precision)
    val eq: EQProfile,
    val oscillation: OscillationConfig?
)

enum class LayerType { AMBIENT, AFFIRMATION }

data class EQProfile(
    val bass: Double,     // 0.0 - 1.0
    val mid: Double,      // 0.0 - 1.0
    val treble: Double    // 0.0 - 1.0
)

data class OscillationConfig(
    val enabled: Boolean,
    val waveform: Waveform,
    val periodSeconds: Double,      // Full LFO cycle
    val minVolume: Double,          // 0.0 - 1.0
    val maxVolume: Double,          // 0.0 - 1.0
    val phaseOffset: Double         // 0.0 - 1.0 (stagger multiplier)
)

enum class Waveform { SINE, PERLIN, STEP, TRIANGLE }

data class AffirmationLayer(
    val layerType: LayerType = LayerType.AFFIRMATION,
    val voiceId: String,              // "female" | "male" | "custom" | platform-specific
    val volume: Double,               // 0.0 - 1.0 (typically 0.08-0.12)
    val playbackSpeed: Double         // 0.5 - 2.0
)

data class ChartSnapshot(
    val moonPhase: MoonPhase,
    val dominantElement: Element,
    val topTransit: Transit?,
    val aspectarian: List<Aspect>,
    val stelliums: List<Sign>,
    val computedAt: Instant
)
```

### 9.2 Auto-Generation Algorithm

```kotlin
fun autoGenerateCombo(
    nightlyScores: NightlyScoreResult,
    sounds: List<Sound>,
    userSettings: UserSettings,
    tier: SubscriptionTier
): Combo {
    val maxLayers = when (tier) {
        SubscriptionTier.FREE -> 1
        SubscriptionTier.BASIC -> 2
        SubscriptionTier.PRO -> 5
    }

    // Rank sounds by dot product with nightly element score
    val rankedSounds = sounds.map { sound ->
        val score = (
            nightlyScores.elementScore.fire * sound.elementScores.fire +
            nightlyScores.elementScore.earth * sound.elementScores.earth +
            nightlyScores.elementScore.air * sound.elementScores.air +
            nightlyScores.elementScore.water * sound.elementScores.water
        ) / 4.0
        sound to score
    }.sortedByDescending { it.second }

    val selectedSounds = rankedSounds.take(maxLayers)
    val totalScore = selectedSounds.sumOf { it.second }

    val ambientLayers = selectedSounds.mapIndexed { index, (sound, score) ->
        AmbientLayer(
            soundId = sound.id,
            volume = ((score / totalScore) * 0.75).roundTo(2),
            playbackSpeed = 1.0,
            eq = EQ_PROFILES[sound.tags.register] ?: EQ_PROFILES["mid"]!!,
            oscillation = buildOscillation(sound, index, nightlyScores.dominantElement, tier)
        )
    }

    return Combo(
        id = generateUUID(),
        name = "${nightlyScores.moonPhase.displayName} Session",
        source = ComboSource.AUTO,
        chartSnapshot = nightlyScores.toSnapshot(),
        layers = ambientLayers,
        affirmationLayer = AffirmationLayer(
            voiceId = userSettings.selectedVoiceId,
            volume = 0.10,
            playbackSpeed = userSettings.globalAffirmationSpeed
        )
    )
}

val EQ_PROFILES = mapOf(
    "sub" to EQProfile(bass = 0.95, mid = 0.40, treble = 0.15),
    "deep" to EQProfile(bass = 0.85, mid = 0.50, treble = 0.20),
    "mid" to EQProfile(bass = 0.55, mid = 0.80, treble = 0.45),
    "bright" to EQProfile(bass = 0.30, mid = 0.60, treble = 0.85),
    "full" to EQProfile(bass = 0.65, mid = 0.70, treble = 0.55),
    "ultrasonic" to EQProfile(bass = 0.20, mid = 0.45, treble = 0.95)
)

fun buildOscillation(
    sound: Sound,
    layerIndex: Int,
    dominantElement: Element,
    tier: SubscriptionTier
): OscillationConfig? {
    if (tier != SubscriptionTier.PRO) return null

    val rules = when (dominantElement) {
        Element.WATER -> OscillationRule(
            enabled = layerIndex == 0,
            waveform = Waveform.SINE,
            periodSeconds = 45.0,
            range = 0.45 to 0.85
        )
        Element.AIR -> OscillationRule(
            enabled = layerIndex <= 1,
            waveform = Waveform.PERLIN,
            periodSeconds = 18.0,
            range = 0.40 to 0.80
        )
        Element.FIRE -> OscillationRule(
            enabled = layerIndex == 0,
            waveform = Waveform.PERLIN,
            periodSeconds = 12.0,
            range = 0.35 to 0.75
        )
        Element.EARTH -> OscillationRule(enabled = false)
    }

    return if (rules.enabled) {
        OscillationConfig(
            enabled = true,
            waveform = rules.waveform,
            periodSeconds = rules.periodSeconds,
            minVolume = rules.range.first,
            maxVolume = rules.range.second,
            phaseOffset = layerIndex * 0.33
        )
    } else null
}
```

### 9.3 Oscillation Parameters

| Parameter | Type | Notes |
|-----------|------|-------|
| `waveform` | `SINE \| PERLIN \| STEP \| TRIANGLE` | Sine = smooth breathing. Perlin = organic. Step = rhythmic. |
| `periodSeconds` | Double | Full LFO cycle. Water: 30–60s. Air: 15–25s. Fire: 8–18s. |
| `minVolume / maxVolume` | Double 0.0–1.0 | Narrow range (0.6–0.8) = subtle. Wide (0.2–0.9) = dramatic. |
| `phaseOffset` | Double 0.0–1.0 | Stagger layers by 0.33 to prevent simultaneous peaks. |

**LFO Implementation:**
- iOS: `CADisplayLink` callback at 60fps, calling `setVolume` on `AVAudioPlayerNode`
- Android: `Handler` with 60ms delay (≈16fps) targeting `ExoPlayer` volume

### 9.4 Per-Layer Playback Speed

| Parameter | Value | Notes |
|-----------|-------|-------|
| Range | 0.5× – 2.0× | 0.5 = half speed; 1.0 = normal; 2.0 = double |
| Default | 1.0× | Applied on new layer creation and auto-generation |
| Step | 0.05× increments | Slider with fine control |
| Affirmation override | Per-playlist | Basic+Pro: saved combo speed overrides global Settings |

**Tier gating:**

| Tier | Ambient layer speed | Affirmation voice speed |
|------|-------------------|------------------------|
| Free | ✗ fixed 1.0× | ✗ global Settings rate only |
| Basic | ✓ per layer, saved per playlist | ✓ per saved playlist |
| Pro | ✓ per layer, saved per playlist | ✓ per saved playlist |

**Implementation:**
- iOS: `AVAudioUnitTimePitch.rate` with `enableTimePitchStretching`
- Android: `SonicAudioProcessor.setSpeed()` with pitch correction
- TTS: Platform-specific rate parameters scaled to utterance

---

## 10. Subliminal Audio System

### 10.1 AI Affirmation Generation (Proxied, 1 Call per Calendar Day)

The app posts to the AI proxy (Section 19.2) which forwards to the Anthropic API. Response cached locally by calendar date.

**System Prompt (sent by proxy, never in app):**
```
You are a subliminal sleep affirmation writer. Transform the user's input into
a 60–90 second first-person present-tense affirmation script. Rules:
- First person singular ("I am", "I have", "I know")
- Present tense only (no "I will" — use "I am" / "I do")
- Positive framing (no negations)
- 8–12 sentences
- Short sentences (max 12 words each)
- End with a grounding statement about rest and receiving
- Return ONLY the script, no headers, no numbering
```

**Rate limiting (enforced at proxy level):**
- Max 1 successful affirmation call per user ID per calendar day (UTC)
- Max 3 failed-retry attempts before 24-hour block
- Proxy returns HTTP 429 with `{ error: "limit_reached", retryAfter: "<ISO timestamp>" }` on breach
- App handles 429 by showing offline fallback (see Section 20.1)

### 10.2 Audio Mixing Architecture

**Playback Graph (per session):**

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PLAYBACK GRAPH                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌──────────────┐    ┌──────────┐    ┌─────────────┐            │
│   │ Sound: Layer 1 │───▶│ EQ (3-b) │───▶│ Vol (LFO)   │──┐        │
│   └──────────────┘    └──────────┘    └─────────────┘  │        │
│                                                        │        │
│   ┌──────────────┐    ┌──────────┐    ┌─────────────┐  │        │
│   │ Sound: Layer 2 │───▶│ EQ (3-b) │───▶│ Vol (LFO)   │──┤        │
│   └──────────────┘    └──────────┘    └─────────────┘  │        │
│                                                        │        │
│   ┌──────────────┐    ┌──────────┐    ┌─────────────┐  │        │
│   │ Sound: Layer 3 │───▶│ EQ (3-b) │───▶│ Vol (LFO)   │──┼──▶    │
│   └──────────────┘    └──────────┘    └─────────────┘  │  │     │
│                                                        │  │     │
│   ... (up to 5 layers)                               │  │     │
│                                                        │  │     │
│   ┌────────────────────────────────────────────────┐   │  │     │
│   │ Affirmation TTS / Custom Voice                 │───┘  │     │
│   │ Volume: fixed 0.08–0.12                        │      │     │
│   └────────────────────────────────────────────────┘      │     │
│                                                             │     │
│                                                             ▼     │
│                                                      ┌──────────┐│
│                                                      │ MASTER   ││
│                                                      │ MIXER    ││
│                                                      └────┬─────┘│
│                                                           │      │
│                                                           ▼      │
│                                                      ┌──────────┐│
│                                                      │ OUTPUT   ││
│                                                      └──────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

**Audio Session Configuration:**
- iOS: `AVAudioSession.Category.playback`, `.mixWithOthers` option. Set before first sound loads.
- Android: `AudioAttributes.Builder().setUsage(USAGE_MEDIA).setContentType(CONTENT_TYPE_MUSIC)`. Request audio focus with `AUDIOFOCUS_GAIN`.
- Background audio: Enabled. App continues playing when screen locks.

**Audio Interruption Handling:**

| Event | Behavior |
|-------|----------|
| Incoming phone call | Pause all layers; resume when call ends |
| Siri / Assistant activation | Duck volume to 20%; restore after |
| Another app takes audio focus | Pause; show "Paused — tap to resume" banner |
| AirPods disconnect / headphones unplug | Pause immediately (prevent speaker bleed) |
| Screen lock | Continue playing (background audio enabled) |
| App backgrounded | Continue playing |
| Sleep timer fires | Fade all layers to 0 over 60 seconds, then stop. Complete current affirmation loop first. Log session end. |

### 10.3 Affirmation Audio — Voice Options

| Feature | Tier | Details |
|---------|------|---------|
| Default TTS — male + female | **Free** | On-device TTS; user selects at onboarding or Settings |
| Additional TTS voice selection | Basic + Pro | 3 voices (Basic), all available platform voices (Pro) |
| Custom voice recording | **Pro** | User records their own voice; stored locally as affirmation track |

**Free Tier Default Voices:**

| Voice | iOS | Android | Character |
|-------|-----|---------|-----------|
| Female (default) | `AVSpeechSynthesisVoice` — best available English female | `TextToSpeech` — `en-US` female | Soft, neutral |
| Male | `AVSpeechSynthesisVoice` — best available English male | `TextToSpeech` — `en-US` male | Calm, neutral |

> Query platform TTS at runtime for best available voice; do not hardcode bundle identifiers.

**Default TTS Parameters:**

| Parameter | Value |
|-----------|-------|
| Rate | 0.35–0.45 of platform max (slow, subliminal) |
| Volume | 0.08–0.12 relative to ambient mix |
| Loop | Repeat for full session duration |

**Advanced Style Options (Pro affirmation):**

| Option | Values | Notes |
|--------|--------|-------|
| Tone | Neutral / Warm / Commanding / Whisper | Prepended to system prompt |
| Script length | Short (5–7 sentences) / Standard (8–12) / Extended (13–18) | Overrides length instruction |
| Ending style | Grounding (default) / Sleep induction / Gratitude | Overrides final sentence |

**Custom Voice Recording (Pro):**
- Access: Settings → Affirmation → "Record My Voice"
- Flow: Display generated script → 3-second countdown → record → playback preview → Confirm or Re-record
- Storage: `.m4a`, 44.1kHz, 16-bit, local device only
- Normalization: Volume normalized to -14 LUFS on save
- Speed control: Same rate mechanism as ambient sounds; pitch correction on
- Privacy: Never uploaded; stored in app sandbox

### 10.4 Sleep Timer

| Setting | Values |
|---------|--------|
| Options | Off / 30 min / 60 min / 90 min / 120 min |
| Default | 60 min (user can change in Settings) |
| Fade behavior | Linear fade of all layers over 60 seconds before stop |
| Affirmation behavior | Complete current loop, then begin fade |
| Session log | Written at timer fire (not on manual stop) — records actual elapsed duration |
| Manual stop | Immediate stop; session log written with actual elapsed time |

---

## 11. Subscription Tiers

| Feature | Free | Basic $3.99/mo | Pro $7.99/mo |
|---------|------|----------------|--------------|
| Sound recommendations | Top 1 | Top 3 | Top 5 |
| Auto-combo generation | ✗ | 2 layers | 5 layers |
| Custom combo builder | ✗ | ✓ (no oscillation) | ✓ Full |
| Volume + EQ per layer | ✗ | ✓ | ✓ |
| Per-layer playback speed (ambient + voice) | ✗ | ✓ | ✓ |
| Oscillation per layer | ✗ | ✗ | ✓ |
| Transit-aware scoring | ✗ | ✓ | ✓ |
| AI transit narrative | ✗ | ✗ | ✓ |
| Saved playlists | 3 | 15 | Unlimited |
| Subliminal affirmation | ✓ | ✓ | ✓ + Advanced style options |
| Affirmation voice — male + female TTS (default) | ✓ | ✓ | ✓ |
| Affirmation voice — additional TTS voices | ✗ | 3 voices | All voices |
| Affirmation voice — custom voice recording | ✗ | ✗ | ✓ |
| Session history | Last 7 days | Last 30 days | Unlimited |
| iCloud / Google Drive backup | ✗ | ✗ | ✓ |

**Tier Enforcement Rules:**
- Entitlement checked via `Purchases.shared.getCustomerInfo()` (iOS) or `Purchases.sharedInstance.getCustomerInfo()` (Android) on every app open and before any gated action.
- Never derive entitlement from local storage. Locally cached `subscriptionTier` string is display-only; always reconciled with RevenueCat on next network access.
- If subscription lapses: user drops to Free tier. Combos above Free limit become read-only (not deleted). Banner: "Your plan has changed. Upgrade to edit these playlists."
- Grace period: RevenueCat handles Apple's 16-day and Google's 3-day billing grace periods automatically. App treats grace-period users as active paid subscribers.
- Free trial: 7-day free trial on Basic and Pro. Configured in RevenueCat dashboard and App Store Connect / Google Play Console.

---

## 12. Screen-by-Screen UI Spec

### 12.1 Splash / Launch

- Full-bleed dark background with animated star field or subtle particle effect
- App wordmark centered
- Check Supabase session validity; check RevenueCat entitlement
- Auto-advances to Onboarding (new user) or Tonight's Screen (returning user)

**Platform-specific:**
- iOS: Use `LaunchScreen.storyboard` with SwiftUI transition
- Android: Use `SplashScreen` API (Android 12+) with animated vector drawable

### 12.2 Birth Data Entry

- Fields: Full name, Date of birth (date picker), Time of birth (optional — time picker with "Unknown" toggle), City of birth (search autocomplete → lat/lng)
- Privacy notice: "Your birth data is stored only on this device and is never uploaded."
- CTA: "Compute My Chart" → loading state (ephemeris computation) → completion → next step

**Platform-specific:**
- iOS: Use `DatePicker` in `.wheel` style, `MapKit` for location search
- Android: Use `DatePickerDialog`, `Places SDK` or `Geocoder` for location

### 12.3 Tonight's Screen (Home)

- Header: "Good [evening/night], [Name]" + Moon phase icon + phase name
- Section: "Tonight's Recommendation" → auto-combo card (element badges, layer preview)
- Section: "Your Intention" → text field (required, max 280 chars)
- CTA: "Begin Tonight's Session" → fires AI proxy call (or uses cache) → opens Playback
- Offline state: if no network and no cached affirmation, CTA becomes "Begin Without Affirmation"
- Footer tabs: Tonight / Sounds / Library / Settings

**Platform-specific:**
- iOS: Moon phase as animated SF Symbol (`moon.fill`, `moon.zzz.fill`, etc.)
- Android: Moon phase as `Icon` with `AnimatedVisibility` for phase transitions

### 12.4 Playback Screen

- Full screen dark ambient UI
- Large element symbol for dominant element
- Layer visual: 1–5 stacked waveform lines, pulsing per their LFO
- Controls: Play/Pause, Stop, Sleep Timer picker
- Swipe up: layer detail panel — per-layer volume sliders, speed indicators
- "Save This Combo" button → name input → saves locally
- If interrupted (phone call): auto-pause; show "Paused" overlay with resume button

**Platform-specific:**
- iOS: Use `Slider` with custom track, `Button` with `.borderedProminent` style
- Android: Use `Slider` with `Track` customization, `FloatingActionButton` for primary actions

### 12.5 Combo Builder

**iOS Implementation:**
- Presented as `.sheet()` with drag indicator
- Navigation: Back arrow + "Combo Builder" title in toolbar
- Layer list: `List` with `onMove` for reordering
- Each row: `HStack` with icon, name, volume `Slider`, buttons for EQ/Speed/Oscillation
- Affirmation Voice: Pinned at bottom in `Section` footer
- Sheets: EQ Sheet (3 sliders), Speed Sheet (slider 0.5×–2.0×), Oscillation Sheet (Pro only)

**Android Implementation:**
- Full-screen destination with `slideInHorizontally` transition
- Top app bar with navigation icon and title
- Layer list: `LazyColumn` with `dragAndDrop` support (or reorder handles)
- Each row: `Card` with icon, name, `Slider`, icon buttons
- Bottom sheets: `ModalBottomSheet` for EQ, Speed, Oscillation controls

### 12.6 Playlist Library

**iOS:**
- `List` with `refreshable` for pull-to-refresh
- Each row: `Label` with combo name, badges (Fire/Earth/Air/Water dots), date
- Swipe actions: `.swipeActions` with delete on trailing edge
- Read-only badge: `Badge` view on row

**Android:**
- `LazyColumn` with `PullRefreshIndicator`
- Each row: `ListItem` with leading icon, headline, supporting text, trailing badges
- Swipe: `Dismissible` with undo snackbar
- Read-only badge: `Badge` composable

### 12.7 Settings

**iOS (SwiftUI `Form`):**
```swift
NavigationStack {
    Form {
        Section("Profile") {
            NavigationLink("Name & Birth Data") { ProfileEditor() }
        }
        Section("Subscription") {
            SubscriptionStatusView()
            Button("Manage Subscription") { showPaywall() }
        }
        // ... additional sections
    }
}
```

**Android (Compose):**
```kotlin
LazyColumn {
    item { PreferenceCategory("Profile") }
    item { PreferenceItem(
        title = "Name & Birth Data",
        onClick = { navigateToProfile() }
    )}
    item { PreferenceCategory("Subscription") }
    item { SubscriptionStatusItem() }
    item { ButtonPreference("Manage Subscription") { showPaywall() }}
    // ... additional items
}
```

### 12.8 Paywall

- Shown when user hits a gated feature
- Two cards: Basic and Pro, with feature lists
- "Most Popular" badge on Pro
- CTA: "Start 7-Day Free Trial"
- [Restore Purchases] text button below cards
- Legal footer: "Subscription auto-renews. Cancel anytime in your [App Store / Play Store] account settings."

**Platform-specific:**
- iOS: Present as sheet with close button, use `StoreKit` product loading
- Android: Full-screen with back navigation, use `BillingFlowParams` for purchase

---

## 13. Backend Architecture

### 13.1 What Runs Locally (Zero Tokens, Zero Network)

- Natal chart computation (WASM ephemeris — sidereal, Sharatan ayanamsha, topocentric, True Nodes)
- BaseScore derivation (formula with decimal precision, see Section 6.2)
- Transit scoring (formula, see Section 6.3)
- Sound ranking (12-dimensional tag engine, see Section 7)
- Combo auto-generation (algorithm, see Section 9.2)
- Oscillation LFO (platform-specific callbacks)
- TTS affirmation audio (on-device, male + female free)
- Custom voice recording and playback (local .m4a)
- All user personal data (local database, on-device)

### 13.2 What Hits External Services

| Service | What is sent | Why |
|---------|--------------|-----|
| AI Proxy (Cloudflare Worker) | User's nightly intention text (≤280 chars), user ID | Affirmation generation |
| Anthropic API (via proxy only) | Intention text + system prompt | Claude generates affirmation script |
| Supabase Auth | Email, hashed password (handled by SDK) | Account creation, login, token refresh |
| RevenueCat | Device ID, purchase receipt, platform | Subscription validation + entitlement |
| PostHog | Anonymous event data (no PII, no birth data) | Analytics |
| Sentry | Crash stack traces, device info, app version | Error monitoring |
| Cloudflare R2 | Read-only: sound files + manifest | Sound asset delivery |

**What is NEVER sent anywhere:** birth date, birth time, birth location, natal chart data, BaseScore vector, saved combo contents, affirmation scripts, custom voice recordings, session logs.

---

## 14. Local Data Model

### 14.1 iOS Data Model (SwiftData / Core Data)

```swift
import SwiftData

@Model
class UserProfile {
    @Attribute(.unique) var id: String  // Supabase user UUID
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthLat: Double
    var birthLng: Double
    var birthCity: String
    var baseScoreFire: Double
    var baseScoreEarth: Double
    var baseScoreAir: Double
    var baseScoreWater: Double
    var cachedTierDisplayOnly: String  // DISPLAY ONLY
    var selectedVoiceId: String
    var globalAffirmationSpeed: Double
    var sleepTimerDefault: Int
    
    init(/* ... */) {}
}

@Model
class SavedCombo {
    @Attribute(.unique) var id: String  // UUID v4
    var name: String
    var createdAt: Date
    var lastPlayedAt: Date?
    var source: String  // "auto" | "user"
    var chartSnapshotJson: String  // JSON string
    var layersJson: String  // JSON array
    var affirmationLayerJson: String  // JSON
    var isReadOnly: Bool
    
    init(/* ... */) {}
}

@Model
class SessionLog {
    @Attribute(.unique) var id: String
    var date: Date
    var intention: String
    var affirmationScript: String
    var customVoicePath: String?
    var comboId: String?
    var durationMinutes: Int
    var timerFired: Bool
    
    init(/* ... */) {}
}

@Model
class AffirmationCache {
    @Attribute(.unique) var calendarDate: String  // "YYYY-MM-DD" UTC
    var script: String
    var generatedAt: Date
    
    init(/* ... */) {}
}
```

### 14.2 Android Data Model (Room)

```kotlin
@Entity(tableName = "user_profile")
data class UserProfile(
    @PrimaryKey val id: String,  // Supabase user UUID
    val name: String,
    val birthDate: String,  // ISO date
    val birthTime: String?, // ISO time or null
    val birthLat: Double,
    val birthLng: Double,
    val birthCity: String,
    val baseScoreFire: Double,
    val baseScoreEarth: Double,
    val baseScoreAir: Double,
    val baseScoreWater: Double,
    val cachedTierDisplayOnly: String = "free",
    val selectedVoiceId: String = "female",
    val globalAffirmationSpeed: Double = 1.0,
    val sleepTimerDefault: Int = 60
)

@Entity(tableName = "saved_combo")
data class SavedCombo(
    @PrimaryKey val id: String,  // UUID v4
    val name: String,
    val createdAt: String,  // ISO-8601
    val lastPlayedAt: String?,  // ISO-8601
    val source: String,  // "auto" | "user"
    val chartSnapshotJson: String,  // JSON
    val layersJson: String,  // JSON
    val affirmationLayerJson: String,  // JSON
    val isReadOnly: Boolean = false
)

@Entity(tableName = "session_log")
data class SessionLog(
    @PrimaryKey val id: String,
    val date: String,  // ISO date
    val intention: String,
    val affirmationScript: String,
    val customVoicePath: String?,
    val comboId: String?,
    val durationMinutes: Int,
    val timerFired: Boolean = false
)

@Entity(tableName = "affirmation_cache")
data class AffirmationCache(
    @PrimaryKey val calendarDate: String,  // "YYYY-MM-DD" UTC
    val script: String,
    val generatedAt: String  // ISO-8601
)
```

### 14.3 Data Backup (Pro)

| Platform | Mechanism | What syncs |
|----------|-----------|------------|
| iOS | iCloud CloudKit (automatic via `NSPersistentCloudKitContainer`) | savedCombo, sessionLog |
| Android | Google Drive App Data (via `BackupManager` or custom) | savedCombo, sessionLog |
| Never synced | userProfile (birth data), affirmationCache, customVoicePath recordings | Privacy — stays device-local |

Pro users see "Back Up My Data" toggle in Settings → Privacy. Default off; user must opt in. Even when on, birth data is excluded from backup scope. Custom voice recordings excluded due to file size.

---

## 15. Audio Asset Spec & Delivery

### 15.1 File Format Requirements

| Parameter | Spec | Reason |
|-----------|------|--------|
| Delivery format | `.m4a` (AAC) | Cross-platform native; minimal decoding overhead |
| Master format | `.wav` 24-bit | Editing headroom |
| Sample rate | 44.1 kHz | Standard; no resampling needed |
| Bit depth (delivery) | 16-bit | Transparent for ambient audio |
| Loop length | 30–120 seconds | Long enough to avoid obvious repetition |
| Loop points | Zero-crossing at start and end | Prevents click at loop boundary |
| Loudness | -14 LUFS integrated | Platform loudness target |
| Peak | -1 dBTP | Headroom for EQ boost |

### 15.2 Asset Delivery Pipeline

Sound files are **not bundled in the app binary**. They are served from Cloudflare R2 via CDN and cached locally on first play.

**Flow:**
1. App launch → fetch `sounds_manifest.json` from CDN
2. Compare local manifest version vs remote
3. If changed: update local sound metadata (tags, scores)
4. Sound `.m4a` files: downloaded on first play, cached in app's local storage
5. Cached sounds served from local storage on subsequent plays (no network needed)

**CDN URL pattern:**
```
https://cdn.astrosleep.app/sounds/{soundId}.m4a
https://cdn.astrosleep.app/sounds_manifest.json
```

**Cache policy:**
- `sounds_manifest.json`: `Cache-Control: max-age=300` (5 min)
- `{soundId}.m4a`: `Cache-Control: max-age=31536000` (1 year, immutable)

**Sound file storage on device:**
- iOS: App's sandboxed `Documents/sounds/` directory
- Android: App's sandboxed `files/sounds/` directory
- Never stored in iCloud/Google Drive sync (too large)

### 15.3 Audio Source Recommendations

| Source | License | Best For | Cost |
|--------|---------|----------|------|
| Freesound.org | Creative Commons (varies) | Nature, mechanical | Free |
| Zapsplat.com | Royalty-free / paid tier | High-quality produced loops | Free / ~$10/mo |
| Soundsnap.com | Royalty-free commercial | Professional ambient loops | ~$20/mo |
| Self-record | Owned outright | Fan, dryer, faucet, ticking | Mic + 1 afternoon |
| Boom Library | One-time commercial license | Hero sounds (thunder, ocean) | $50–200/pack |

**Recommendation:** Self-record domestic/mechanical sounds. License nature sounds from Freesound or Zapsplat. Boom Library for thunder and ocean.

---

## 16. Dev Admin Tool (Web GUI)

A **standalone React web application** for managing the sound library, tag engine, and platform features. Accessible from anywhere via secure web interface.

### 16.1 Hosting & Access

- **Hosting:** Cloudflare Pages at `https://admin.astrosleep.app`
- **Authentication:** Cloudflare Access (Zero Trust)
  - Email allowlist: developer email only
  - One-time PIN authentication (no password)
  - JWT valid for 8 hours
- **Security:** All admin tool traffic over HTTPS (Cloudflare TLS)
- **Access control:** No public URL indexing; direct access only through Cloudflare Access portal

### 16.2 Authentication Flow

```
1. Developer navigates to https://admin.astrosleep.app
2. Cloudflare Access intercepts → requests email
3. One-time PIN sent to email
4. Developer enters PIN → Cloudflare issues signed JWT
5. JWT stored in browser sessionStorage
6. All API calls include: Authorization: Bearer <JWT>
7. Worker validates JWT signature on every request
```

### 16.3 Sound Management

**Sounds Tab:**

| Feature | Description |
|---------|-------------|
| Sound Table | All sounds with all 12 tags + computed element scores (decimal precision) |
| Add Sound | Form with all 12 tag dropdowns + file upload + live score preview |
| Edit Sound | Inline tag editing with real-time score recalculation |
| Delete Sound | Confirmation + R2 file deletion + audit log entry |
| isNew Toggle | Badge control for "NEW" indicator in app |
| Batch Upload | Drag-and-drop multiple files with CSV metadata import |
| Preview Player | In-browser audio preview with waveform visualization |

**12-Dimensional Tag Editor:**
```typescript
interface TagEditorProps {
  sound: Sound;
  onChange: (dimension: string, value: string) => void;
}

// Each dimension displayed as searchable dropdown
// Real-time score preview updates on tag change
// Validation: all 12 dimensions required before publish
```

### 16.4 Subscription Tier Management

**Tiers Tab:**

| Feature | Description |
|---------|-------------|
| Tier Overview | View current Basic/Pro feature sets |
| Feature Toggle | Enable/disable features per tier |
| Layer Limits | Edit max layers per tier (Free: 1, Basic: 2, Pro: 5+) |
| Playlist Limits | Edit save limits per tier |
| Pricing Display | View current prices (read-only from RevenueCat) |
| Trial Duration | Edit trial length (7/14/30 days) |
| New Tier Creation | Add experimental tiers (staging only) |

**Feature Configuration JSON:**
```typescript
interface TierConfig {
  tier: 'free' | 'basic' | 'pro';
  maxLayers: number;
  maxPlaylists: number;
  features: {
    oscillation: boolean;
    transitScoring: boolean;
    aiNarrative: boolean;
    customVoice: boolean;
    backupSync: boolean;
    advancedAffirmation: boolean;
  };
  limits: {
    sessionHistoryDays: number;
    voiceSelectionCount: number;
    affirmationStyles: string[];
  };
}
```

### 16.5 Tag Engine Management

**Tag Engine Tab:**

| Feature | Description |
|---------|-------------|
| Vector Table Editor | Edit all 12 dimension vector tables |
| Decimal Precision | View/edit values with 2 decimal places |
| Restore Defaults | Reset to archetypal defaults |
| Version History | View previous vector configurations |
| A/B Testing | Set up tag variants for sound testing |
| Impact Analysis | See which sounds change score with vector edits |

### 16.6 Platform Features Management

**Platform Tab:**

| Feature | Description |
|---------|-------------|
| iOS Feature Flags | Toggle iOS-specific features (widgets, Live Activities) |
| Android Feature Flags | Toggle Android-specific features (shortcuts, dynamic color) |
| Minimum Versions | Set iOS/Android minimum OS versions |
| Rollout Percentage | Staged rollout control for new features |
| Kill Switches | Emergency feature disable |

### 16.7 Analytics & Monitoring

**Analytics Tab:**

| Metric | Description |
|--------|-------------|
| Sound Popularity | Play count, skip rate, combo inclusion rate per sound |
| Tier Conversion | Free → Basic → Pro funnel |
| Session Metrics | Average session duration, sleep timer usage |
| Geographic | User distribution by region |
| Error Rates | App crashes, API failures |

### 16.8 Upload Pipeline

```
Admin Tool Upload Flow:
1. Developer selects .m4a file(s) in Upload tab
2. Client-side validation: format, sample rate, peak level, LUFS (Web Audio API)
3. Admin tool POSTs file to Cloudflare Worker admin endpoint
   Authorization: Bearer <Cloudflare Access JWT>
4. Worker validates JWT → uploads file to R2 bucket at sounds/{soundId}.m4a
5. Worker updates sounds_manifest.json in R2 (atomic write)
6. Worker purges CDN cache for sounds_manifest.json
7. Admin tool shows: "Upload successful. Sound live in ~30 seconds."

Failure handling:
- JWT expired: admin tool redirects to Cloudflare Access re-auth
- R2 write failure: Worker returns 500; admin tool shows error; no manifest update
- Invalid file: client-side validation rejects before upload; no network request
```

### 16.9 Audit Logging

All admin actions logged to Cloudflare KV (append-only):

| Field | Description |
|-------|-------------|
| timestamp | ISO-8601 |
| action | CREATE_SOUND / UPDATE_SOUND / DELETE_SOUND / UPDATE_TIER / UPDATE_VECTORS |
| targetId | soundId or tierId |
| developerEmail | From Access JWT |
| ipAddress | Request IP |
| changes | JSON diff of changes |

---

## 17. Payment & Subscription Infrastructure

### 17.1 Overview

AstroSleep uses **RevenueCat** as the subscription infrastructure layer across both platforms. RevenueCat abstracts StoreKit 2 (iOS) and Google Play Billing v6+ (Android) into a single SDK.

**Why RevenueCat:**
- Single `getCustomerInfo()` call returns current entitlement on both platforms
- Server-side receipt validation — purchases cannot be spoofed
- Webhook handling for subscription lifecycle events
- Cross-platform purchase restore
- Built-in paywall SDK for A/B testing

### 17.2 Product Configuration

Configure in both App Store Connect and Google Play Console, then mirror in RevenueCat dashboard.

| Product | App Store ID | Play Store ID | Type |
|---------|--------------|---------------|------|
| Basic Monthly | `astrosleep_basic_monthly` | `astrosleep_basic_monthly` | Auto-renewing subscription |
| Basic Annual | `astrosleep_basic_annual` | `astrosleep_basic_annual` | Auto-renewing subscription |
| Pro Monthly | `astrosleep_pro_monthly` | `astrosleep_pro_monthly` | Auto-renewing subscription |
| Pro Annual | `astrosleep_pro_annual` | `astrosleep_pro_annual` | Auto-renewing subscription |

**RevenueCat Entitlement IDs:**
- `"basic"` — grants Basic tier features
- `"pro"` — grants Pro tier features (includes all Basic)

Free trial: 7 days on all products. Configured in App Store Connect and Play Console.

### 17.3 iOS — StoreKit 2

- RevenueCat SDK wraps StoreKit 2 entirely. Do not call StoreKit APIs directly.
- Initialize: `Purchases.configure(withAPIKey: REVENUECAT_IOS_KEY)`
- Receipt validation: RevenueCat validates against Apple's server
- Subscription management: users manage via iOS Settings → Apple ID → Subscriptions

### 17.4 Android — Google Play Billing

- RevenueCat SDK wraps Google Play Billing v6+ entirely.
- Initialize: `Purchases.configure(PurchasesConfiguration.Builder(context, REVENUECAT_ANDROID_KEY).build())`
- Receipt validation: RevenueCat validates against Google's API
- Subscription management: users manage via Google Play → Subscriptions

### 17.5 Subscription Lifecycle Webhooks

RevenueCat fires webhooks to Cloudflare Worker endpoint:

| Event | Action |
|-------|--------|
| `INITIAL_PURCHASE` | Log to Supabase audit table; send welcome email |
| `RENEWAL` | Log; no user-facing action |
| `CANCELLATION` | Log; no immediate action (retain access until period end) |
| `EXPIRATION` | Log; Supabase marks subscription lapsed (analytics only) |
| `BILLING_ISSUE` | Log; app shows banner on next open |
| `PRODUCT_CHANGE` | Log; update Supabase cached tier for analytics |

**Webhook endpoint:** `https://api.astrosleep.app/webhooks/revenuecat`
**Authentication:** RevenueCat signs payloads with HMAC-SHA256. Worker validates signature before processing.

### 17.6 Purchase Restore

- [Restore Purchases] button on paywall and in Settings → Subscription
- Calls `Purchases.restorePurchases()`
- Show loading spinner during restore
- On success: "Your [Basic/Pro] plan has been restored"
- On failure: "No active subscription found"

### 17.7 Pricing Display

- Always fetch current prices from RevenueCat at runtime
- Never hardcode "$3.99" in UI — prices vary by region
- Display using `localizedPriceString` from RevenueCat `Package` object

---

## 18. Security Architecture

### 18.1 API Key Management

| Key | Where Stored | Access Pattern |
|-----|--------------|----------------|
| Anthropic API key | Cloudflare Worker environment secret | Never in app binary; proxy only |
| RevenueCat iOS key | Xcode build settings (public key) | Read-only from app |
| RevenueCat Android key | `AndroidManifest.xml` / `build.gradle` (public key) | Read-only from app |
| RevenueCat webhook secret | Cloudflare Worker environment secret | HMAC validation only |
| Google Play service account key | RevenueCat dashboard | Never in app |
| Apple shared secret | RevenueCat dashboard | Never in app |
| Supabase `anon` key | App configuration (designed to be public) | Row-level security enforces access |
| Supabase `service_role` key | Cloudflare Worker environment secret | Never in app |
| R2 write credentials | Cloudflare Worker environment secret | Admin Worker only |
| Cloudflare Access app secret | Cloudflare dashboard | Never in codebase |

**Rule:** If a key can write, delete, or read private data, it lives only in Cloudflare Worker environment secret.

### 18.2 Credential Storage on Device

| Data | iOS Storage | Android Storage |
|------|-------------|-----------------|
| Supabase auth token (JWT) | Keychain via `expo-secure-store` equivalent | Android Keystore + EncryptedSharedPreferences |
| Supabase refresh token | Keychain | EncryptedSharedPreferences |
| RevenueCat app user ID | Keychain | EncryptedSharedPreferences |
| Birth data, chart, combos | SwiftData / Core Data (encrypted on modern devices) | Room database (encrypted with SQLCipher) |
| Custom voice recordings | App `documentDirectory` (sandboxed) | App `filesDir` (sandboxed) |
| Affirmation cache | SwiftData / Core Data | Room database |

### 18.3 Supabase Row-Level Security

```sql
-- Users can only read/write their own rows
CREATE POLICY "own_data_only" ON subscription_audit
  USING (user_id = auth.uid());

-- Service role (webhook Worker) can insert audit rows
CREATE POLICY "service_insert_only" ON subscription_audit
  FOR INSERT WITH CHECK (auth.role() = 'service_role');
```

### 18.4 Network Security

- All traffic: HTTPS only. No HTTP endpoints.
- AI proxy: validates request body ≤280 chars before forwarding. Strips prompt injection attempts.
- Admin Worker: validates Cloudflare Access JWT on every request.

### 18.5 Privacy Compliance

- **GDPR / CCPA:** Privacy policy required before account creation. "Delete All My Data" wipes local database and deletes Supabase account.
- **App Store privacy label:** Data not linked to user — crash data, analytics. Data linked to user — purchase history. No health data, no location data.
- **No birth data in analytics:** PostHog events must never include birth date, birth city, coordinates, or chart placements.

---

## 19. Backend Services (Cloudflare Workers)

### 19.1 Worker 1 — API Proxy (`/api/*`)

**Route:** `https://api.astrosleep.app/api/affirmation`
**Method:** POST
**Auth:** Supabase JWT in `Authorization: Bearer <token>` header

**Request Body:**
```json
{
  "intention": "<string, max 280 chars>"
}
```

**Worker Logic:**
1. Validate Supabase JWT → extract user_id
2. Check rate limit: KV lookup for key `affirmation:{user_id}:{YYYY-MM-DD UTC}`
   - If exists: return 429 `{ error: "limit_reached", retryAfter: "<end of UTC day>" }`
3. Sanitize intention: strip HTML, truncate to 280 chars
4. Detect prompt injection: reject if intention contains "ignore previous instructions", "system:", "assistant:"
5. POST to Anthropic API with system prompt + intention
6. On success: write KV key with 24h TTL
7. Return `{ script: "<affirmation text>" }`
8. On Anthropic error: return 503 `{ error: "upstream_error" }`

**Route:** `https://api.astrosleep.app/api/transit-narrative` (Pro only)
- Same auth flow; validates Pro entitlement via RevenueCat REST API
- max_tokens: 200; system prompt for transit narrative style

### 19.2 Worker 2 — Webhooks + Admin (`/webhooks/*`, `/admin/*`)

**Webhook route:** `https://api.astrosleep.app/webhooks/revenuecat`
- Validates RevenueCat HMAC-SHA256 signature
- Processes subscription lifecycle events (see Section 17.5)
- Writes to Supabase audit table using `service_role` key

**Admin route:** `https://api.astrosleep.app/admin/upload`
- Validates Cloudflare Access JWT
- Accepts multipart form upload (sound .m4a + metadata JSON)
- Validates file format server-side (magic bytes check)
- Writes to R2, updates manifest, purges CDN cache
- Appends to audit log in KV

---

## 20. Error States & Offline Behavior

### 20.1 Offline / No Network

| Scenario | User-facing Behavior |
|----------|-------------------|
| No network on app open | App loads normally (all core features local). Tonight's Screen shows "Offline — affirmation unavailable" notice. |
| AI call fails (no network) | "Begin Without Affirmation" CTA shown. Session proceeds with ambient sounds only. Session log records empty affirmation. |
| AI call fails (API error / 5xx) | Same as above. Error logged to Sentry. |
| AI call rate-limited (429) | Same as above. Not surfaced as error. |
| Sound file not cached + no network | Sound card shows "Not downloaded yet" — grayed out. Cannot be added to combo. |
| CDN manifest fetch fails | Use locally cached manifest. No library changes until next successful fetch. |

### 20.2 Auth Errors

| Scenario | Behavior |
|----------|----------|
| Supabase token expired | SDK auto-refreshes. If refresh fails, "Session expired — please log in again." → Login screen. Local data preserved. |
| Account deleted server-side | On next token refresh failure, show "Account not found. Your local data is preserved." → option to create new account. |
| Password reset link expired | "This link has expired. Request a new one." → back to forgot-password flow. |

### 20.3 Purchase Errors

| Scenario | Behavior |
|----------|----------|
| Purchase flow cancelled | Dismiss paywall silently. No error shown. |
| Purchase failed (declined) | "Your payment could not be processed. Please check your payment method in [App Store / Play Store]." |
| Restore finds no purchases | "No active subscription found for this account." |
| RevenueCat SDK unavailable | Fall back to local cached tier for display only. Do not gate features during outage. Log to Sentry. |

### 20.4 Audio Errors

| Scenario | Behavior |
|----------|----------|
| Sound file fails to load | Remove layer from playback silently; show toast "One sound couldn't load." Combo continues. |
| Audio session interrupted permanently | Show "Audio interrupted" overlay with [Resume] button. |
| Custom voice recording fails | "Recording failed. Please try again." Re-record option shown. |
| TTS engine unavailable | Fall back to female voice if male unavailable; if TTS entirely unavailable, skip affirmation layer. |

---

## 21. Analytics & Observability

### 21.1 PostHog Events

PostHog initialized with `person_profiles: 'never'` (anonymous events only).

| Event | Properties |
|-------|------------|
| `session_started` | `tier`, `moon_phase`, `has_affirmation` (bool), `layer_count` |
| `session_ended` | `duration_minutes`, `timer_fired` (bool), `tier` |
| `combo_saved` | `source` ("auto"\|"user"), `layer_count`, `tier` |
| `sound_previewed` | `sound_id`, `element` |
| `paywall_shown` | `trigger_feature`, `tier_shown` |
| `subscription_started` | `product_id`, `is_trial` (bool) |
| `affirmation_skipped` | `reason` ("offline"\|"rate_limited"\|"error") |
| `feature_used` | `feature_name`, `tier` |

**Never include:** `intention` text, voice recordings, birth data, user email, coordinates.

### 21.2 Sentry

- Initialize in app root with DSN from Sentry project
- Capture unhandled exceptions and Promise rejections
- Attach: `tier` (cached display value), `app_version`, `platform`
- Set `beforeSend` hook to strip any accidentally included PII

### 21.3 Cloudflare Worker Analytics

Cloudflare dashboard provides: request volume, error rates, latency per route, KV operation counts.

---

## 22. App Store & Play Store Submission

### 22.1 Required Before Submission

- [ ] Privacy policy at `https://astrosleep.app/privacy`
- [ ] Terms of service at `https://astrosleep.app/terms`
- [ ] App Store Connect: subscription group configured, free trial enabled
- [ ] Google Play Console: subscription products created, base plan + offer configured
- [ ] RevenueCat: products mirrored, entitlements mapped, webhook URL configured
- [ ] Age rating: 4+ (iOS) / Everyone (Android)
- [ ] App category: Health & Fitness (primary), Lifestyle (secondary)
- [ ] Paid Applications Agreement completed in App Store Connect (required for subscriptions)

### 22.2 Content Advisory Notes

Subliminal audio may trigger review scrutiny. Prepare for App Review:
- Clear disclosure in app description: "This app plays affirmations at low volume while you sleep."
- **No claims of medical or therapeutic benefit.** Do not claim the app "cures insomnia," "treats anxiety," or "improves mental health." Apple classifies these as medical claims requiring clinical proof.
- No claims that subliminal audio is "scientifically proven."
- If asked: affirmation audio is clearly disclosed, optional, and plays at user-controlled volume.
- Stick to language like "sleep wellness," "mindfulness," "relaxation support," and "personalized soundscapes."

### 22.3 Generative AI Disclosure (iOS Critical)

Apple now requires explicit disclosure for apps using Generative AI:
- In App Store Connect, check **"This app uses Generative AI"**
- The `PrivacyInfo.xcprivacy` includes `NSGenerativeAIDisclosure` with:
  - `NSGenerativeAIUsesGenerativeModels`: true
  - `NSGenerativeAIOnDeviceOnly`: false (server-side proxy)
  - `NSGenerativeAIContentFiltering`: true (system prompt restricts output)
- The Cloudflare Worker proxy (Section 19) uses a strict system prompt that limits AI output to positive, sleep-focused affirmations only
- No user prompt injection is possible — the proxy prepends a controlled system prompt and strips any system-level instructions from user input
- If Apple asks about content filtering: affirmations are wellness-focused, first-person, and never contain medical advice, harmful content, or explicit material

### 22.4 Background Audio Critical Requirement

For a sleep app, background audio is a hard requirement:
- In Xcode, under **Signing & Capabilities**, add **"Audio, AirPlay, and Picture in Picture"** background mode
- Without this, ambient sounds will cut off the moment the user locks their screen — an immediate rejection
- The `Info.plist` declares `UIBackgroundModes` with `audio`, `fetch`, and `remote-notification`
- The `AVAudioSession` is configured with `.playback` category and `.mixWithOthers` option
- Test on physical device (arm64) — background audio behavior can differ from simulator

### 22.5 Privacy Label & Data Collection

Since birth data NEVER leaves the device (Section 6.1), the App Privacy Label is minimal:
- **Contact Info**: Not collected (auth is anonymous email/Apple ID only)
- **Health & Fitness**: Not collected (astrological data is not health data)
- **Precise Location**: Declared only if using GPS for birth city geocoding; single-use, not stored or uploaded
- **Audio Data**: Declared for Pro custom voice recording; stored locally, never uploaded
- **Purchase History**: Collected via RevenueCat for subscription validation
- **Crash Data**: Collected via Sentry for stability monitoring (no PII)
- **Product Interaction**: Collected via PostHog for feature usage analytics (no birth data, intentions, or coordinates)

The `PrivacyInfo.xcprivacy` aggregates RevenueCat, Sentry, and PostHog manifest requirements into the main app bundle.

### 22.6 RevenueCat & Paywall Compliance

Apple requires specific paywall elements:
- **"Restore Purchases"** button must be clearly visible on the paywall (`PaywallView` includes this)
- Subscription terms must explain auto-renewal and how to cancel
- Free trial must be offered with clear post-trial pricing
- All prices must match App Store Connect product configurations exactly
- The paywall must not be dismissible with a system gesture (requires explicit close button)
- Reviewers will test the purchase flow; ensure sandbox/test products are configured

### 22.7 Reviewer Account & Demo Mode

Provide Apple with a demo account that unlocks Pro features:
- Hardcode a reviewer mode triggered by a specific test email domain (e.g., `@apple.review`) or a hidden debug gesture
- Alternatively, provide an active subscription IAP code for the reviewer account
- Ensure the default "Recommended Combo" for the current moon phase is pre-loaded and functional
- Combo Builder must be fully accessible (all layers, EQ controls, speed adjustments, LFO toggles)
- Playback screen must demonstrate continuous audio with screen locked
- Test the entire flow: onboarding → birth data entry → chart computation → tonight's recommendation → playback → combo save

### 22.8 TestFlight Validation Checklist

Before final App Store submission, validate via TestFlight on a physical device:
- [ ] Audio continues playing with screen locked for 30+ minutes without interruption
- [ ] Incoming phone call pauses audio; resuming after call works correctly
- [ ] Alarm or timer interruption handled gracefully; audio resumes if within session time
- [ ] LFO oscillation behaves correctly during and after audio interruptions
- [ ] Sleep timer fires and 60-second fade-out completes without crashes
- [ ] Combo Builder saves, loads, and plays back correctly with all layer types
- [ ] Paywall displays correctly and "Restore Purchases" functions as expected
- [ ] Background fetch works for daily affirmation refresh
- [ ] App handles offline mode gracefully (no crash when opening without network)
- [ ] No memory leaks during extended playback (test 60+ minute session)
- [ ] Subscription upgrade/downgrade reflects immediately in UI without app restart

### 22.9 Screenshot & Asset Requirements

| Asset | iOS | Android |
|-------|-----|---------|
| Screenshots | 6.7" (required), 6.5", 5.5", iPad 12.9" | Phone (required), 7" tablet, 10" tablet |
| App icon | 1024×1024 PNG, no alpha | 512×512 PNG, adaptive icon layers |
| Preview video | Optional, up to 30s | Optional (Promo video in Play Console) |

**Screens to capture:** Tonight's Screen, Playback Screen, Combo Builder, Sound Library, Paywall.

### 22.10 App Store Connect Setup Checklist

- [ ] Bundle ID: `com.astrosleep.app`
- [ ] Capabilities: Background Modes (Audio), Push Notifications, Sign in with Apple, iCloud (CloudKit — Pro tier)
- [ ] Associated domains: `applinks:astrosleep.app`
- [ ] Export compliance: Uses standard encryption (HTTPS/TLS)
- [ ] Generative AI disclosure: Checked and described
- [ ] In-App Purchases: 4 subscription products created and approved
- [ ] Paid Applications Agreement: Signed and active

### 22.11 Google Play Console Setup Checklist

- [ ] Application ID: `com.astrosleep.app`
- [ ] Permissions: `INTERNET`, `RECORD_AUDIO` (custom voice), `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`
- [ ] Data safety form: declares audio recording (optional, local), no data shared except purchase history
- [ ] Target API level: 34+ (required for new apps as of 2024)

---

## 23. Implementation Phases

### Phase 1 — Core MVP (Shared Core + iOS Shell)

**Shared Core (`astrosleep-core`):**
- Kotlin Multiplatform module setup
- Data models (charts, combos, sounds)
- Tag engine algorithms (12-dimensional, decimal precision)
- Astrological calculations (WASM ephemeris wrapper)
- Subscription tier logic

**iOS Shell:**
- SwiftUI project setup
- KMP integration (Objective-C headers)
- Supabase auth (email + Apple Sign-In)
- Birth data entry + WASM ephemeris
- Single-layer playback with AVFoundation
- AI proxy integration + affirmation generation
- RevenueCat SDK (Free tier only)
- Offline fallback

### Phase 2 — Android Shell + Basic Tier

**Android Shell:**
- Jetpack Compose project setup
- KMP integration (direct Kotlin)
- Supabase auth (email + Google Sign-In)
- Feature parity with iOS Phase 1

**Both Platforms:**
- Transit scoring (nightly local pass)
- Multi-layer combo builder (up to 2 layers, Basic)
- Auto-generation algorithm
- Per-layer EQ + volume + speed (Basic)
- Basic subscription tier
- Additional TTS voices (Basic: 3)
- Paywall + restore purchases
- Playlist library with tier limits

### Phase 3 — Pro Tier + Platform Polish

**Both Platforms:**
- Oscillation LFO system
- Pro subscription tier
- Custom voice recording (Pro)
- All 23 sounds
- Pro affirmation style options
- Unlimited session history (Pro)
- iCloud / Google Drive backup (Pro)
- AI transit narrative (Pro)

**iOS-Specific:**
- Home Screen Widget
- Live Activities (Dynamic Island)
- Apple Watch companion

**Android-Specific:**
- App shortcuts
- Media notification
- Wear OS support

### Phase 4 — Growth + Dev Tool

**Dev Admin Tool:**
- React web app on Cloudflare Pages
- Cloudflare Access authentication
- Sound upload pipeline
- Tag engine editor
- Tier management
- Platform feature flags
- Analytics dashboard

**App Features:**
- Sound library expansion (via admin tool)
- Annual subscription products
- A/B test paywall pricing
- Share combo as preset

---

## 24. Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Cross-platform architecture | Kotlin Multiplatform + platform-native UI | Shared logic, native feel on both platforms |
| iOS UI framework | SwiftUI 5.0+ | Modern, declarative, native iOS patterns |
| Android UI framework | Jetpack Compose | Modern, declarative, Material3 design |
| Core language | Kotlin | Shared with KMP, type-safe, coroutines |
| Subscription infrastructure | RevenueCat | Abstracts StoreKit 2 + Play Billing |
| Auth provider | Supabase Auth | Managed, secure, supports Apple + Google Sign-In |
| API key protection | Cloudflare Worker proxy | Anthropic key never in app binary |
| Admin tool auth | Cloudflare Access Zero Trust | No passwords to manage or leak |
| Sound delivery | Cloudflare R2 + CDN + local cache | No app update needed to add sounds |
| Birth data privacy | Device-local only, never uploaded | Core trust proposition |
| Entitlement source of truth | RevenueCat (runtime) | Prevents entitlement spoofing |
| Tag engine precision | Decimal (Double/Float) | More nuanced scoring than integers |
| Tag dimensions | 12 total, domain weighted highest | Comprehensive archetypal coverage |
| Astrological completeness | All planets + nodes + asteroids + houses + aspects + stelliums | Complete natal chart coverage |
| Zodiac system | Sidereal, 13 signs, Sharatan ayanamsha | Developer's specified standard |
| House system | Equal (Ascendant = 1st), topocentric | Consistent, observer-centered |
| Lunar nodes | True Nodes | More precise than Mean |
| Analytics PII | PostHog with `person_profiles: 'never'` | No PII in analytics; GDPR-safe |
| AI model | `claude-sonnet-4-20250514` | Best instruction-following |
| Subliminal volume | 0.08–0.12 relative to mix | Below conscious perception |
| Oscillation default | Off for Earth; on for Water/Air/Fire | Matches elemental character |
| Decimal scoring | All scores stored as Double/Float | Precision for nuanced matching |

---

## Appendix A: Astrological Variable Coverage Checklist

The following natal chart variables are explicitly accounted for in the scoring system:

**Planets (10):**
- [x] Sun
- [x] Moon
- [x] Mercury
- [x] Venus
- [x] Mars
- [x] Jupiter
- [x] Saturn
- [x] Uranus
- [x] Neptune
- [x] Pluto

**Points (2):**
- [x] North Node (True)
- [x] South Node (True)

**Asteroids (2):**
- [x] Chiron
- [x] Lilith (Mean)

**Houses (12):**
- [x] All 12 house cusps (Equal system)
- [x] Planet house placements
- [x] House ruler associations

**Aspects (5 major):**
- [x] Conjunction (0°)
- [x] Sextile (60°)
- [x] Square (90°)
- [x] Trine (120°)
- [x] Opposition (180°)

**Special Configurations:**
- [x] Stelliums (3+ planets in same sign)
- [x] Dominant element calculation
- [x] Dominant modality calculation
- [x] Moon phase integration
- [x] Transit aspects (all planets)
- [x] Current house transits

---

## Appendix B: 12-Dimensional Tag Quick Reference

| Dimension | Key Values | Element Weight |
|-----------|------------|----------------|
| `domain` | water, air, fire, earth, mechanical, organic, electrical, cosmic | 9.0 |
| `celestial` | solar, lunar, stellar, planetary, void | 4.0 |
| `archetype` | maiden, mother, crone, hero, mentor, shadow, trickster | 4.0 |
| `rhythm` | steady, pulse, irregular, chaotic, rhythmic, arrhythmic | 3.0 |
| `motion` | static, flowing, surging, swirling, oscillating, drifting, pulsing | 3.0 |
| `register` | sub, deep, mid, bright, full, ultrasonic | 2.0 |
| `context` | nature, domestic, abstract, urban, industrial, spiritual | 2.0 |
| `weight` | ethereal, light, medium, heavy, massive | 2.0 |
| `texture` | smooth, rough, crystalline, diffuse, granular, glassy, metallic | 2.0 |
| `density` | vacuum, sparse, moderate, dense, saturated | 2.0 |
| `temperature` | cool, warm, hot, cold, neutral | 2.0 |
| `polarity` | active, receptive, balanced, neutral | 2.0 |

---

**END OF SPECIFICATION**

> **For AI Agents:** This document is self-contained. All algorithms, data models, UI specifications, and security rules are defined herein. Build in the order specified in Section 23 (Implementation Phases). When in doubt, prefer the explicit specification over inferred best practices.
