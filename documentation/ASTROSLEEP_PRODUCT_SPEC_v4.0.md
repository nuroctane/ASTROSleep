# AstroSleep — Complete Product Specification v4.0

> **Agent-Optimized Build Brief** — Paste this file into any AI agent terminal as a self-contained construction manual.
>
> **Version:** 4.0 | **Tag Engine:** 12-dimensional with decimal precision | **Platform Strategy:** Separate iOS/Android native UI builds from shared core logic
> **Preview App:** `testing/astrosleep-preview/index.html` (v4.0, localized Swift webapp for 1:1 UX parity testing)

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

1. [Version History & Changelog](#1-version-history--changelog)
2. [Product Vision](#2-product-vision)
3. [Core Differentiators](#3-core-differentiators)
4. [Tech Stack — Dual Native UI Strategy](#4-tech-stack--dual-native-ui-strategy)
5. [Platform-Specific UI Specifications](#5-platform-specific-ui-specifications)
6. [User Flows](#6-user-flows)
7. [Astrological Engine](#7-astrological-engine)
8. [Tag Engine v3.1 — 12-Dimensional Archetypal Scoring](#8-tag-engine-v31--12-dimensional-archetypal-scoring)
9. [Sound Library & Filtering](#9-sound-library--filtering)
10. [Combo System](#10-combo-system)
11. [Subliminal Audio System](#11-subliminal-audio-system)
12. [Subscription Tiers v4.0](#12-subscription-tiers-v40)
13. [Screen-by-Screen UI Spec](#13-screen-by-screen-ui-spec)
14. [Backend Architecture](#14-backend-architecture)
15. [Local Data Model](#15-local-data-model)
16. [Audio Asset Spec & Delivery](#16-audio-asset-spec--delivery)
17. [Dev Admin Tool (Web GUI)](#17-dev-admin-tool-web-gui)
18. [Payment & Subscription Infrastructure](#18-payment--subscription-infrastructure)
19. [Security Architecture](#19-security-architecture)
20. [Backend Services (Cloudflare Workers)](#20-backend-services-cloudflare-workers)
21. [Error States & Offline Behavior](#21-error-states--offline-behavior)
22. [Analytics & Observability](#22-analytics--observability)
23. [App Store & Play Store Submission](#23-app-store--play-store-submission)
24. [Implementation Phases](#24-implementation-phases)
25. [Key Design Decisions](#25-key-design-decisions)
26. [Preview Web App Spec](#26-preview-web-app-spec)

---

## 1. Version History & Changelog

### v4.0 — Current (Consolidated Release)
- **Subscription model simplified** to three tiers: Free / Subscription ($7.99/mo) / Pro Lifetime ($79.99 one-time, all future updates included)
- **Voice system overhauled**: iOS on-device voice picker (Siri voices, enhanced quality), pitch slider (-6 to +6 semitones), speed slider with numerical readout, independent controls for personal recordings
- **Sound Library UX upgraded**: tap sound card to auto-play preview; triple-dot context menu (Preview, Add to Combo, Sound Details, Cancel); close (X) buttons on all sheets/overlays; swipe-from-left-edge back navigation
- **Tag filtering replaced**: removed "Show New Only" toggle; added iOS 26 Messages-style tag filter pills/dropdowns for all 12 tag dimensions
- **Permissions hardened**: added `NSSpeechRecognitionUsageDescription` for Siri voice access; created `LocationPermissionService` for runtime location permission requests; all permissions (location, notifications, microphone, speech) declared in Info.plist with runtime request gates
- **Preview app v4.0**: full 1:1 UI/UX parity with iOS app for rapid testing — includes onboarding, Apple Sign-In flow, restore purchases, sign-out, all tier logic, sound card interactions, and Messages-style filters
- **Codebase audit**: all tier references updated from `basic`/`pro` to `subscription`/`lifetime`; `SubscriptionTier` enum, `RevenueCatService`, `PaywallView`, `AppState`, and preview all cross-referenced consistently

### v3.1 — Location Scoring Update
- Added `ASTROSLEEP_LOCATION_SCORING_v3.1.md` with transit house scoring based on current location
- Added `useCurrentLocationForTransits` toggle to user profile

### v3.0 — Baseline
- 12-dimensional tag engine with decimal precision
- Three-tier subscription system (Free / Basic / Pro)
- AI affirmation proxy via Cloudflare Worker
- Dual native UI strategy (SwiftUI + Jetpack Compose)
- Full astrological engine with complete variable coverage

---

## 2. Product Vision

AstroSleep is a cross-platform (iOS + Android) sleep app that helps users direct their subconscious mind toward specific problems or intentions during rest. It combines:

- **Astrological personalization** — natal chart + live transits drive sound recommendations
- **AI-generated subliminal affirmations** — user intent → first-person audio script
- **Tag-based ambient sound engine** — formula-driven scoring with decimal precision, no manual hardcoding
- **Layered combo system** — multi-track ambient mixes with volume, EQ, and LFO oscillation
- **Comprehensive chart coverage** — every astrological variable contributes to scoring

---

## 3. Core Differentiators

| Feature | Rain Rain | Calm | Insight Timer | AstroSleep |
|---------|-----------|------|---------------|------------|
| Astrological personalization | ✗ | ✗ | ✗ | ✓ |
| Transit-aware nightly scoring | ✗ | ✗ | ✗ | ✓ |
| 12-dimensional archetypal tag engine | ✗ | ✗ | ✗ | ✓ |
| iOS on-device Siri voice affirmations | ✗ | ✗ | ✗ | ✓ |
| Pitch + speed independent control | ✗ | ✗ | ✗ | ✓ |
| AI subliminal affirmation audio | ✗ | ✗ | ✗ | ✓ |
| Multi-layer combo with LFO | ✓ | ✗ | ✗ | ✓ |
| Lifetime purchase (all future updates) | ✗ | ✗ | ✗ | ✓ |
| Messages-style tag filters | ✗ | ✗ | ✗ | ✓ |
| Platform-native UI feel | ✗ | ✗ | ✗ | ✓ |
| Web-based dev admin tool | ✗ | ✗ | ✗ | ✓ |
| iOS + Android | ✓ | ✓ | ✓ | ✓ |

---

## 4. Tech Stack — Dual Native UI Strategy

### 4.1 Framework Decision: Separate Native UI Layers with Shared Core

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
│  • AVAudioEngine          │  • ExoPlayer / Oboe                        │
│  • CoreLocation           │  • Fused Location Provider                 │
│  • Sign in with Apple     │  • Google Sign-In                          │
├─────────────────────────────────────────────────────────────────────────┤
│                         SHARED CORE (Kotlin Multiplatform)                │
│  ─────────────────────────────────────────────────────────────────────  │
│  • Astrological calculations (ephemeris WASM)                           │
│  • Tag engine scoring (12-dimensional, decimal precision)               │
│  • Data models (charts, combos, sounds, sessions)                         │
│  • RevenueCat entitlement abstraction                                     │
│  • Network layer (Ktor client → Cloudflare Worker proxy)                │
├─────────────────────────────────────────────────────────────────────────┤
│                         BACKEND SERVICES                                │
│  ─────────────────────────────────────────────────────────────────────  │
│  • Supabase (Auth + Postgres)                                           │
│  • Cloudflare Workers (AI proxy, nightly score cache)                   │
│  • RevenueCat (subscription validation + webhooks)                      │
│  • CDN (Cloudflare R2) — audio asset delivery                           │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 iOS Specifics

| Component | Technology | Notes |
|-----------|-----------|-------|
| UI Framework | SwiftUI 5.0+ | iOS 17+ target; iOS 26 design language adoption |
| Audio Engine | AVAudioEngine | Multi-track mixer with per-layer EQ and time-pitch |
| Audio Session | AVAudioSession | `.playback` category with `.mixWithOthers` |
| Background Audio | UIBackgroundModes | `audio`, `fetch`, `remote-notification` |
| Location | CoreLocation | `CLLocationManager` with `requestWhenInUseAuthorization()` |
| Auth | Supabase Auth + Apple Sign-In | `ASAuthorizationAppleIDProvider` |
| Subscriptions | RevenueCat SDK (`PurchasesSwift`) | StoreKit 2 abstraction |
| Push | UserNotifications | Bedtime reminders, session complete, trial ending |
| Speech | AVSpeechSynthesizer | On-device voices only; no network TTS |
| Analytics | PostHog iOS SDK | Event tracking, funnels |
| On-device DB | SwiftData / Core Data | Profile, combos, session history |

### 4.3 Preview Web App (v4.0)

A localized Swift-syntax HTML/JS web app simulates the iOS app UI for rapid UX testing without building to device:

- **Path:** `testing/astrosleep-preview/index.html`
- **Version:** 4.0.0
- **Features:** Full tab navigation (Tonight, Sounds, Library, Settings), onboarding flow, Apple Sign-In simulation, paywall with three tiers, combo builder, sound library with Messages-style filters, voice & speed settings with pitch, sleep timer, profile editing, location editing, theme picker
- **Audio:** Simulated only (no actual playback); visual indicators show "playing" state
- **State:** `localStorage` persistence; survives reload
- **CDN base:** `https://cdn.astrosleep.app/sounds/`
- **Purpose:** 1:1 UI/UX parity testing before iOS implementation; stakeholder demos; design iteration

---

## 5. Platform-Specific UI Specifications

### 5.1 iOS Design Language

- **Navigation:** `NavigationStack` with `.toolbar` items; swipe-from-left-edge back gesture on all sub-screens
- **Sheets:** `.sheet` presentation with close (X) button in top trailing; tap backdrop or swipe down to dismiss
- **Lists:** `.list` with `.insetGrouped` style; `Section` headers in title case
- **Pickers:** `.pickerStyle(.navigationLink)` for voice selection; `.pickerStyle(.segmented)` for binary toggles
- **Sliders:** Custom track with fill indicator; numerical readout below
- **Buttons:** `.borderedProminent` for primary actions; `.borderless` for destructive/cancel
- **Context Menus:** Triple-dot (⋮) button on sound cards; overlay menu with dimmed backdrop; X button to dismiss; swipe-from-left-edge also dismisses
- **Filters:** iOS 26 Messages-style horizontal scrollable pill buttons; active pills show accent color; dropdown sheets for multi-select tag dimensions

### 5.2 Android Design Language

- **Navigation:** `NavHost` with `BottomNavigation`; system back button
- **Sheets:** `ModalBottomSheet` with drag handle and close action
- **Lists:** `LazyColumn` with `Card` containers; `Divider` between items
- **Pickers:** `ExposedDropdownMenuBox` for voice selection
- **Sliders:** `Slider` with custom thumb and track colors
- **Buttons:** `FilledTonalButton` for primary; `TextButton` for secondary
- **Context Menus:** `DropdownMenu` anchored to card action button
- **Filters:** `FilterChip` in horizontally scrolling `Row`; `ModalBottomSheet` for multi-select

---

## 6. User Flows

### 6.1 First-Time User

```
Open app
  → Check Supabase session + RevenueCat entitlement
  → No profile → Onboarding Flow
    → Intro carousel (3 pages: Sleep with Intention, Astrological Personalization, Subliminal Affirmations)
    → "Get Started" CTA
    → Birth Data Entry: name, date, time, city (geocoded to lat/lng)
    → Apple Sign-In / Google Sign-In OR anonymous skip
    → Subscription preview (dismissible; shows three-tier comparison)
    → Tonight's Screen (first session)
```

### 6.2 Returning User

```
Open app
  → Check RevenueCat entitlement (CustomerInfo) — determines active tier
  → Tonight's Screen
      shows: "Good evening, [Name]" + current Moon phase icon + phase name
      shows: top recommended combo for tonight
      shows: intention input field (pre-filled with last intention)
      CTA: "Begin Tonight's Session"
```

### 6.3 Playback Flow

```
Tonight's Screen → "Begin Session"
  → [If network] AI proxy generates affirmation (cached for 24h)
  → Playback Screen opens
    → Full-screen dark ambient UI with element visualization
    → Layer waveform visualization (1–5 tracks)
    → Play/Pause, Stop, Sleep Timer
    → Swipe up: Layer Panel (per-layer volume, speed, EQ)
    → Tap "Save This Combo" → name input → saves locally
```

### 6.4 Sound Library Flow

```
Sounds tab
  → Search bar at top
  → Messages-style filter pills (horizontal scroll): Element (Fire/Earth/Air/Water), Domain, Register, Rhythm, Texture, Mood, etc.
  → Tapping a pill opens dropdown/multi-select sheet for that dimension
  → Active filter count badge on filter bar
  → Sound cards in grid
    → Tap card → auto-plays sound preview (simulated in preview; actual audio in app)
    → Triple-dot (⋮) button → context menu overlay
      → Preview
      → Add to Combo
      → Sound Details
      → Cancel
    → Context menu dismiss: tap X, tap backdrop, or swipe from left edge
  → Swipe-from-left-edge back gesture returns to previous screen
```

### 6.5 Settings Flow

```
Settings tab
  → Profile: name, birth data (re-enter to recompute chart)
  → Subscription: current tier label, [Manage Subscription] → RevenueCat paywall,
                  [Restore Purchases] button
  → Audio: background audio toggle, sleep timer default
  → Affirmation: Voice & Speed → Voice picker (on-device Siri/enhanced voices),
                  Speed slider (0.5–1.5×, numerical readout),
                  Pitch slider (-6 to +6 semitones, numerical readout)
  → Location: current city, use current location for transits toggle
  → Notifications: bedtime reminder toggle + time picker
  → Theme: accent color picker, background picker, appearance (system/light/dark)
  → Account: Sign Out, Delete Account
```

---

## 7. Astrological Engine

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 6 for complete ephemeris, natal chart computation, transit scoring, and house system specifications.)*

**Key addition in v4.0:**
- `LocationPermissionService` (iOS) requests `requestWhenInUseAuthorization()` when user enables "Use Current Location for Transits"
- `useCurrentLocationForTransits` boolean stored in `UserProfile`
- When enabled, current lat/lng fetched via `CLLocationManager` and reverse-geocoded to city name
- Transit house scoring computed against current location (see `ASTROSLEEP_LOCATION_SCORING_v3.1.md`)

---

## 8. Tag Engine v3.1 — 12-Dimensional Archetypal Scoring

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 7 for complete tag dimension definitions, scoring formulas, and decimal precision rules.)*

---

## 9. Sound Library & Filtering

### 9.1 Sound Card UX (v4.0)

**Tap behavior:**
- **Tap card body** → immediately begins sound preview playback
- **Triple-dot (⋮) button** → opens context menu overlay without stopping preview
- **Context menu actions:**
  - **Preview** — plays sound (same as card tap)
  - **Add to Combo** — adds to current combo; shows paywall if layer limit reached
  - **Sound Details** — opens detail sheet with full tag breakdown, element bars, description
  - **Cancel** — dismisses menu
- **Menu dismissal:** X button in menu header, tap backdrop overlay, or swipe-from-left-edge gesture

**Card layout:**
- Domain icon (large, colored by dominant element)
- "NEW" badge if `isNew == true`
- Sound name
- Element score bars (4-color mini bar chart)
- Tag pills: domain, rhythm, register
- Dominant element dot + label

### 9.2 Messages-Style Tag Filters (v4.0)

**Removed:** "Show New Only" toggle

**Replaced with:** Horizontal scrollable filter bar with pill buttons for all 12 tag dimensions:

| Dimension | Filter Style | Values |
|-----------|-------------|--------|
| Element | Single-select pills | Fire, Earth, Air, Water |
| Domain | Multi-select dropdown | Nature, Synthetic, Hybrid, Mechanical, Celestial |
| Register | Single-select pills | Low, Mid, High, Full |
| Rhythm | Single-select pills | Static, Slow Pulse, Medium Pulse, Fast Pulse, Aperiodic |
| Texture | Multi-select dropdown | Smooth, Granular, Layered, Gritty, Glassy |
| Mood | Multi-select dropdown | Calm, Mysterious, Warm, Vast, Intimate, Melancholy, Ethereal |
| Timbre | Multi-select dropdown | Warm, Cold, Bright, Dark, Metallic, Wooden, Organic |
| Duration | Single-select pills | Loop, Long, Short |
| Seasonality | Single-select pills | Winter, Spring, Summer, Autumn, Year-Round |
| TimeOfDay | Single-select pills | Night, Dawn, Day, Dusk, Any |
| EnergyLevel | Single-select pills | Low, Medium, High |
| Archetype | Multi-select dropdown | The Hermit, The Lover, The Warrior, The Sage, The Fool, The Caregiver, The Ruler, The Creator, The Explorer, The Innocent, The Rebel, The Magician, The Everyperson |

**Filter bar UI:**
- Horizontal scroll at top of Sounds tab
- Each pill shows dimension name + count of selected values (e.g., "Domain · 2")
- Active pills use accent color background
- Tapping pill opens bottom sheet with selectable options for that dimension
- Sheet has X button to close without applying; "Clear" button resets that dimension
- Active filter count shown as badge on filter bar

---

## 10. Combo System

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 9 for combo builder, layer limits, EQ profiles, and oscillation rules.)*

**Tier limits updated in v4.0:**
- Free: 2 layers max
- Subscription: 7 layers max
- Lifetime: 7 layers max

---

## 11. Subliminal Audio System

### 11.1 Affirmation Generation

*(Unchanged from v3.0 — see Section 19 for AI proxy specification.)*

### 11.2 Voice System (v4.0)

**Voice selection:**
- Free tier: all on-device voices available (no gating on voice selection)
- Lifetime tier: custom voice recording enabled

**iOS Voice Picker UI:**
- `Picker` with `.navigationLink` style
- Lists all available `AVSpeechSynthesisVoice` instances where:
  - `language.hasPrefix("en")` AND
  - `quality == .enhanced` OR `name.lowercased().contains("siri")`
- Each row shows: voice name + quality badge ("Enhanced" or "Default")
- Selected voice stored as `identifier` string in `UserProfile.selectedVoiceId`

**Playback Speed:**
- Slider: 0.5× to 1.5×, step 0.05
- Numerical readout below slider: "1.00x"
- Applied to `AVSpeechUtterance.rate` as `Float(rate * 0.4)` for subliminal delivery
- Stored in `UserProfile.globalAffirmationSpeed`

**Pitch Shift:**
- Slider: -6 to +6 semitones, step 0.5
- Numerical readout: "+0.0 semitones" or "-2.5 semitones"
- Conversion: `pitchMultiplier = pow(2.0, pitchSemitones / 12.0)`
- Applied to `AVSpeechUtterance.pitchMultiplier`
- Stored in `UserProfile.globalAffirmationPitch`
- Default: 0.0 (no pitch change)
- Purpose: prevent chipmunk effect when speeding up, prevent guttural effect when slowing down

**Personal Recordings:**
- Lifetime tier only
- Recorded via `AVAudioRecorder`, stored locally as `.m4a`
- Playback uses `AVAudioPlayerNode` with independent speed and pitch via `AVAudioUnitTimePitch`
- Speed and pitch sliders in Settings apply to both TTS and personal recordings

### 11.3 Audio Service API (v4.0)

```swift
func speakAffirmation(
    _ text: String,
    voiceId: String,           // AVSpeechSynthesisVoice.identifier
    volume: Double,
    rate: Double,
    pitchSemitones: Double = 0.0
)
```

**Voice resolution priority:**
1. Exact match by `identifier`
2. Fallback: match by gender heuristic (`name.contains("Male")` vs `"Female")`)
3. Final fallback: `AVSpeechSynthesisVoice(language: "en-US")`

---

## 12. Subscription Tiers v4.0

| Feature | Free | Subscription $7.99/mo | Pro Lifetime $79.99 |
|---------|------|---------------------|----------------------|
| Sound recommendations | ✓ | ✓ | ✓ |
| Custom combo builder | ✓ | ✓ | ✓ |
| Combo layers | 2 | 7 | 7 |
| Volume + EQ per layer | ✓ | ✓ | ✓ |
| Per-layer playback speed | ✓ | ✓ | ✓ |
| Oscillation / LFO | ✓ | ✓ | ✓ |
| Transit-aware scoring | ✓ | ✓ | ✓ |
| AI transit narrative | ✓ | ✓ | ✓ |
| AI affirmation generation | ✓ | ✓ | ✓ |
| Saved playlists | 5 | Unlimited | Unlimited |
| Subliminal affirmation (TTS) | ✓ | ✓ | ✓ |
| Affirmation voice — all on-device TTS | ✓ | ✓ | ✓ |
| Custom voice recording | ✗ | ✓ | ✓ |
| Session history | Last 14 days | Unlimited | Unlimited |
| Data backup (iCloud/Drive) | ✗ | ✓ | ✓ |
| Future features & updates | ✗ | ✓ | ✓ |

**Key v4.0 changes:**
- Removed Basic tier ($3.99/mo); replaced with single Subscription tier ($7.99/mo)
- Added Pro Lifetime as one-time $79.99 non-consumable purchase
- Subscription and Lifetime have **identical feature availability** — difference is only payment model (monthly vs one-time)
- Core experience (transit scoring, AI affirmations, tag engine, oscillation, EQ, speed) is **free for all tiers**
- Only combo layers (2 vs 7), storage limits (playlists/history), custom voice recording, and data backup are gated
- Both paid tiers receive ALL future features and updates
- Free trial: 7-day free trial on Subscription tier only
- RevenueCat entitlements: `subscription` (monthly) and `lifetime` (one-time)

**Tier Enforcement Rules:**
- Entitlement checked via `Purchases.shared.getCustomerInfo()` on every app open and before any gated action
- Never derive entitlement from local storage. `cachedTierDisplayOnly` is display-only; reconciled with RevenueCat on next network access
- If subscription lapses: user drops to Free tier. Combos above Free limit become read-only (not deleted). Banner: "Your plan has changed. Upgrade to edit these playlists."
- Grace period: RevenueCat handles Apple's 16-day billing grace period automatically. App treats grace-period users as active paid subscribers.
- Lifetime purchase: non-consumable IAP. Once purchased, always active. Restored via standard `restorePurchases()` flow.

---

## 13. Screen-by-Screen UI Spec

### 13.1 Splash / Launch

*(Unchanged from v3.0 — see v3.0 Section 12.1)*

### 13.2 Birth Data Entry

*(Unchanged from v3.0 — see v3.0 Section 12.2)*

**v4.0 addition:** Location permission request flow:
- When user enters birth city, if location services not authorized → prompt for `requestWhenInUseAuthorization()`
- If denied, allow manual city text entry without lat/lng (transit scoring uses birth location only)

### 13.3 Tonight's Screen (Home)

*(Unchanged from v3.0 — see v3.0 Section 12.3)*

### 13.4 Playback Screen

*(Unchanged from v3.0 — see v3.0 Section 12.4)*

**v4.0 addition:** Close (X) button on Layer Panel sheet; swipe-from-left-edge returns to Playback Screen.

### 13.5 Combo Builder

*(Unchanged from v3.0 — see v3.0 Section 12.5)*

### 13.6 Sound Library (v4.0)

- **Filter bar:** Horizontal scrollable pill buttons at top
  - Pills: Element, Domain, Register, Rhythm, Texture, Mood, Timbre, Seasonality, TimeOfDay, EnergyLevel, Archetype
  - Active pills show accent background + selection count
  - Tap pill → bottom sheet with selectable options for that dimension
  - Sheet has X close button and "Clear Filters" action
- **Search bar:** `TextField` with `search` SF Symbol; filters by sound name
- **Sound grid:** 2-column grid on iPhone, 3-column on iPad
  - Cards have rounded corners, subtle shadow, element-colored domain icon
  - Tap card → auto-play preview (visual feedback: icon pulses, "Playing..." label)
  - Triple-dot (⋮) button → context menu overlay with dimmed backdrop
- **Context menu overlay:**
  - Backdrop: 40% black overlay; tap to dismiss
  - Menu card: centered, white background, rounded corners
  - Header: sound name + X close button
  - Actions: Preview (▶), Add to Combo (+), Sound Details (ℹ), Cancel
  - Swipe-from-left-edge gesture also dismisses
- **Empty state:** "No sounds match your filters" + "Clear All Filters" button

### 13.7 Playlist Library

*(Unchanged from v3.0 — see v3.0 Section 12.7)*

### 13.8 Settings (v4.0)

- **Profile section:** Name, birth data, [Edit Profile]
- **Subscription section:** Current tier badge, [Manage Subscription], [Restore Purchases]
- **Audio section:** Background audio toggle, sleep timer default picker
- **Affirmation section:** [Voice & Speed] → navigation link
  - **Voice & Speed screen:**
    - On-Device Voice picker (navigation link style, shows selected voice)
    - Playback Speed slider (0.5–1.5×, numerical readout)
    - Pitch Shift slider (-6 to +6 semitones, numerical readout)
    - Volume slider (2%–20%, percentage readout)
    - [Save] button
- **Location section:** Current city display, "Use current location for transits" toggle
  - Toggle ON → triggers `LocationPermissionService.requestPermission()`
  - If denied → shows alert: "Location access is required for transit scoring. Please enable it in Settings."
- **Notifications section:** Bedtime reminder toggle, time picker
- **Theme section:** Accent color picker, background picker, appearance (system/light/dark)
- **Account section:** [Sign Out], [Delete Account] (with confirmation)

### 13.9 Paywall (v4.0)

- **Header:** Crown icon + "Unlock Your Full Potential" + subtitle
- **Feature comparison table:** 3 columns (Free / Subscription / Pro Lifetime)
  - Rows: Sound Recommendations, Combo Layers, Transit Scoring, Oscillation/LFO, Saved Playlists, Session History, Custom Voice Recording, Future Features
- **Product cards:**
  - **Subscription card:** Title "Subscription", description "Monthly access to enhanced features", price "$7.99/month", button "Start 7-Day Free Trial", color `.blue`
  - **Lifetime card:** Title "Pro — One Time", description "Full app forever. All future updates included.", price "$79.99 One-time", button "Unlock Pro Forever", color `accentColor`, "Best Value" badge
- **Footer:** [Restore Purchases] button + legal text: "Subscription auto-renews monthly. Cancel anytime in App Store settings. One-time Pro is a non-consumable in-app purchase."
- **Close button:** Top leading toolbar item

---

## 14. Backend Architecture

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 13)*

---

## 15. Local Data Model

### 15.1 UserProfile (v4.0)

```swift
struct UserProfile: Codable, Identifiable {
    let id: String
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthLat: Double
    var birthLng: Double
    var birthCity: String
    var currentLat: Double
    var currentLng: Double
    var currentCity: String
    var useCurrentLocationForTransits: Bool
    var baseScore: ElementVector
    var natalChart: NatalChart?
    var cachedTierDisplayOnly: SubscriptionTier
    var selectedVoiceId: String       // AVSpeechSynthesisVoice.identifier
    var globalAffirmationSpeed: Double // 0.5–1.5
    var globalAffirmationPitch: Double // -6 to +6 semitones
    var sleepTimerDefault: Int         // minutes
    var notificationEnabled: Bool
    var bedtimeReminderTime: Date?
    var themeConfig: ThemeConfig
    var hasCompletedOnboarding: Bool
}
```

### 15.2 AffirmationLayer (v4.0)

```swift
struct AffirmationLayer: Codable, Identifiable, Equatable {
    var id = UUID()
    var layerType: LayerType = .affirmation
    var voiceId: String
    var volume: Double
    var playbackSpeed: Double
    var pitchSemitones: Double  // NEW in v4.0
    var customVoicePath: String?
}
```

### 15.3 Other Models

*(Unchanged from v3.0 — see v3.0 Section 14 for Combo, Sound, SessionRecord, ThemeConfig, etc.)*

---

## 16. Audio Asset Spec & Delivery

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 15)*

**CDN base URL:** `https://cdn.astrosleep.app/sounds/`

---

## 17. Dev Admin Tool (Web GUI)

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 16)*

---

## 18. Payment & Subscription Infrastructure

### 18.1 RevenueCat Configuration (v4.0)

**Products:**

| Identifier | Type | Tier | Price | Display Name |
|-----------|------|------|-------|-------------|
| `subscription_monthly` | Auto-renewable subscription | subscription | $7.99/mo | Subscription Monthly |
| `lifetime_pro` | Non-consumable IAP | lifetime | $79.99 | Pro — One Time |

**Entitlements:**
- `subscription` → maps to `subscription_monthly`
- `lifetime` → maps to `lifetime_pro`

**Offering IDs:**
- `default` → contains both products

### 18.2 Purchase Flow

1. User taps purchase button on paywall
2. `RevenueCatService.purchase(_ package:)` called
3. For production: delegates to `Purchases.shared.purchase(package:)`
4. For development: simulates 1s delay, updates `currentTier` locally
5. On success: dismisses paywall, updates `UserProfile.cachedTierDisplayOnly`
6. On failure: shows error alert "Purchase failed. Please try again."

### 18.3 Restore Purchases

1. User taps "Restore Purchases" on paywall or Settings
2. `RevenueCatService.restorePurchases()` called
3. For production: delegates to `Purchases.shared.restorePurchases()`
4. For development: simulates 1s delay, returns `currentTier`
5. Shows alert: "Your [Tier] plan has been restored." or "No active subscription found."

### 18.4 Receipt Validation

- RevenueCat handles Apple App Store receipt validation server-side
- Webhook endpoint receives `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `BILLING_ISSUE` events
- Backend updates `user_entitlements` table for audit trail

---

## 19. Security Architecture

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 18)*

---

## 20. Backend Services (Cloudflare Workers)

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 19)*

---

## 21. Error States & Offline Behavior

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 20)*

---

## 22. Analytics & Observability

*(Unchanged from v3.0 — see `ASTROSLEEP_PRODUCT_SPEC_v3.0.md` Section 21)*

**v4.0 additional events:**
- `sound_card_tapped` — user taps sound card to preview
- `context_menu_opened` — user opens triple-dot menu
- `filter_applied` — user applies a tag filter
- `filter_cleared` — user clears all filters
- `pitch_changed` — user adjusts pitch slider
- `voice_changed` — user selects different voice
- `location_permission_requested` / `location_permission_granted` / `location_permission_denied`

---

## 23. App Store & Play Store Submission

### 23.1 iOS Permissions (v4.0)

All required permissions declared in `Info.plist` with runtime request gates:

| Permission | Info.plist Key | Runtime Request | Purpose |
|-----------|---------------|-----------------|---------|
| Microphone | `NSMicrophoneUsageDescription` | On custom voice record (Lifetime only) | Record custom affirmation voice |
| Location When In Use | `NSLocationWhenInUseUsageDescription` | On enabling "Use Current Location" toggle | Transit house scoring |
| Speech Recognition | `NSSpeechRecognitionUsageDescription` | On first voice picker open | Access Siri/enhanced on-device voices |
| Notifications | `UNUserNotificationCenter.requestAuthorization()` | On enabling bedtime reminder | Bedtime reminders, session complete |
| Tracking | `NSUserTrackingUsageDescription` | App launch (if required by analytics) | Analytics attribution |

**Critical:** Location permission description exists in plist but `CLLocationManager.requestWhenInUseAuthorization()` was missing in v3.0. **v4.0 adds `LocationPermissionService`** that properly requests authorization when user enables the feature.

### 23.2 Content Advisory Notes

*(Unchanged from v3.0 — see v3.0 Section 22.2)*

### 23.3 Generative AI Disclosure

*(Unchanged from v3.0 — see v3.0 Section 22.3)*

### 23.4 Background Audio

*(Unchanged from v3.0 — see v3.0 Section 22.4)*

### 23.5 Privacy Label & Data Collection

*(Unchanged from v3.0 — see v3.0 Section 22.5)*

### 23.6 RevenueCat & Paywall Compliance

- **"Restore Purchases"** button clearly visible on paywall
- Subscription terms explain auto-renewal and cancellation
- Free trial offered with clear post-trial pricing ($7.99/mo)
- Lifetime price ($79.99) displayed prominently
- All prices match App Store Connect product configurations
- Paywall requires explicit close button (not dismissible by swipe)
- Reviewers will test both subscription and lifetime purchase flows

### 23.7 Reviewer Account & Demo Mode

- Provide demo account with Lifetime entitlement active
- Ensure Combo Builder is fully accessible (all 7 layers, EQ, speed, LFO)
- Test entire flow: onboarding → birth data → chart → tonight → playback → combo save → settings → sign out
- Test Apple Sign-In, restore purchases, and paywall presentation

### 23.8 TestFlight Validation Checklist (v4.0 additions)

- [ ] Sound card tap triggers preview playback
- [ ] Triple-dot menu opens and dismisses correctly (X, backdrop, swipe)
- [ ] Messages-style tag filters apply and clear correctly
- [ ] Voice picker shows Siri and enhanced voices
- [ ] Speed and pitch sliders update affirmation playback in real-time
- [ ] Location permission requested only when toggle enabled
- [ ] Subscription and Lifetime paywall cards display correct pricing
- [ ] Restore purchases works for both subscription and lifetime
- [ ] All other v3.0 checklist items still pass

### 23.9 App Store Connect Setup (v4.0)

- [ ] Bundle ID: `com.astrosleep.app`
- [ ] In-App Purchases: 1 subscription product + 1 non-consumable lifetime product created
- [ ] Capabilities: Background Modes (Audio), Push Notifications, Sign in with Apple, iCloud (CloudKit — Lifetime tier)
- [ ] Paid Applications Agreement: Signed and active

### 23.10 Google Play Console Setup

*(Unchanged from v3.0 — see v3.0 Section 22.11)*

---

## 24. Implementation Phases

### Phase 1 — Core MVP (v4.0 scope)

**iOS Shell:**
- [x] SwiftUI app shell with tab navigation (Tonight, Sounds, Library, Settings)
- [x] Onboarding flow (intro → birth data → account → subscription preview)
- [x] Apple Sign-In via `AuthService.signInWithApple()`
- [x] RevenueCat integration with three-tier entitlement checking
- [x] Paywall with Free / Subscription / Lifetime cards
- [x] Sound library with Messages-style tag filters
- [x] Sound card tap-to-play + triple-dot context menu
- [x] Combo builder with layer limits (1/2/5)
- [x] Playback screen with LFO visualization
- [x] Settings with voice picker, speed slider, pitch slider
- [x] Location permission service
- [x] Notification permission service
- [x] Theme picker (accent, background, appearance)
- [x] Profile editing, sign out, delete account
- [x] Restore purchases functionality

**Preview Web App:**
- [x] `testing/astrosleep-preview/index.html` v4.0
- [x] 1:1 UI/UX parity with iOS app
- [x] All interactive flows functional (simulated)

### Phase 2 — Advanced Features

- [ ] AI affirmation proxy integration (Cloudflare Worker)
- [ ] Ephemeris WASM integration for real-time chart computation
- [ ] Transit scoring engine (nightly recomputation)
- [ ] Android shell (Jetpack Compose)

### Phase 3 — Polish & Scale

- [ ] Dev admin tool deployment
- [ ] Sound library expansion (100+ sounds)
- [ ] Analytics instrumentation
- [ ] App Store submission

---

## 25. Key Design Decisions

1. **Three-tier simplification:** Removed the middle Basic tier to reduce user confusion. Free → Subscription → Lifetime is a clearer value ladder.
2. **Identical paid feature sets:** Subscription and Lifetime have the exact same feature availability. The only difference is payment model (monthly vs one-time). This is for user payment flexibility, not a restriction paywall.
3. **Core experience is free:** Transit scoring, AI affirmation generation, the full tag engine, oscillation/LFO, per-layer EQ and speed, and all on-device TTS voices are free. These are the main selling points and should not be gated.
4. **Minimal gating:** The only paywalled features are combo layer depth (2 vs 7), storage limits (playlists, session history), custom voice recording, and data backup. Everything else is free.
5. **No custom AI voices or background noise:** Removed custom accent/background and voice profile concepts. The only "custom" vocal option is the user's own voice recording, sped up/EQ'd/mixed in the builder.
6. **Lifetime purchase:** One-time $79.99 IAP with "all future updates" promise. Both paid tiers (Subscription and Lifetime) receive all future features.
7. **On-device voices only:** All TTS happens via `AVSpeechSynthesizer` with local voices. No network TTS calls — privacy-preserving and offline-capable.
8. **Pitch control:** Added after UX testing revealed chipmunk/guttural artifacts when changing speed. Pitch decoupled from speed for finer control.
9. **Messages-style filters:** Replaced toggle-based filtering with pill buttons + dropdowns after reviewing iOS 26 design patterns. More discoverable and flexible.
10. **Tap-to-play:** Sound cards now play on tap (not open details). This matches user expectations from music apps (Spotify, Apple Music).
11. **Swipe-from-left-edge:** Added native-feeling back gesture to all sub-screens in preview. iOS app uses `NavigationStack` native gesture; preview simulates it.
12. **Location runtime request:** Discovered that location permission was declared in Info.plist but never requested at runtime. Added `LocationPermissionService` to gate the feature properly.

---

## 26. Preview Web App Spec

### 26.1 Purpose
The preview app is a **single-file localized Swift-syntax HTML/JS application** that simulates the iOS app UI and logic for rapid UX testing, stakeholder demos, and design iteration. It does **not** play actual audio — it simulates playback states visually.

### 26.2 File Location
`testing/astrosleep-preview/index.html`

### 26.3 Version
4.0.0

### 26.4 State Management
```javascript
function defaultState() {
  return {
    screen: "scr-onboarding-intro",
    tab: "tonight",
    profile: null,
    currentTier: "free",          // "free" | "subscription" | "lifetime"
    theme: { accent: "#5856D6", bg: null, appearance: "system" },
    combos: [],
    currentCombo: null,
    isPlaying: false,
    masterVolume: 0.6,
    sleepTimer: 60,
    intention: "",
    soundsFilter: {
      search: "",
      element: null,
      tagFilters: {}              // { dimension: [values] }
    },
    affirmationSettings: {
      voice: "siri-female-en",     // voice identifier
      speed: 1.0,                  // 0.5–1.5
      pitch: 0.0                   // -6 to +6
    },
    timerDefault: 60,
    locationToggle: false,
    currentCity: "",
    notificationEnabled: false,
    contextSoundId: null           // active context menu sound
  };
}
```

### 26.5 Key UI Components

**Messages-Style Filter Bar:**
- Horizontal scroll container with pill buttons
- Each pill shows dimension name + active selection count
- Active pills use accent color
- Tap opens bottom sheet with checkboxes for that dimension's values
- Sheet has X close button and "Clear" action

**Sound Cards:**
- Grid layout (2 columns)
- Domain icon colored by dominant element
- Element score bars (4 mini bars)
- Tag pills for domain, rhythm, register
- Tap card → `playSound(id)` simulates playback
- Triple-dot button → `openContextMenu(id)` shows overlay

**Context Menu Overlay:**
- 40% black backdrop; tap to dismiss
- Centered white card with rounded corners
- Header: sound name + X button
- Actions: Preview, Add to Combo, Sound Details, Cancel
- Menu actions call corresponding handlers

**Swipe-from-Left-Edge:**
- 20px-wide transparent detector on left edge of screen
- Touch start + move >60px right triggers `goBack()`
- Navigates back through `screenStack` history
- Disabled on onboarding and main tab screens

**Affirmation Settings Screen:**
- Voice rows: selectable list of iOS Siri voices (male/female variants)
- Selected voice highlighted with checkmark
- Speed slider: custom track with fill and thumb; numerical readout below
- Pitch slider: same custom track; semitones readout below
- Save button persists to state

**Paywall:**
- Feature comparison table: Free / Subscription / Pro Lifetime
- Subscription card: $7.99/mo, "Start 7-Day Free Trial"
- Lifetime card: $79.99 one-time, "Unlock Pro Forever", "Best Value" badge
- Restore Purchases button + legal footer

### 26.6 Tier Logic
```javascript
const maxLayers = state.currentTier === 'lifetime' ? 7 :
                    state.currentTier === 'subscription' ? 7 : 2;
const maxPlaylists = state.currentTier === 'lifetime' ? '∞' :
                       state.currentTier === 'subscription' ? '∞' : 5;
```
All tier checks consistently use `lifetime` / `subscription` / `free`. Theme customization (accent color, background color) is free for all tiers.

### 26.7 Navigation Back-Stack
```javascript
const screenStack = [];
const origShowScreen = showScreen;
showScreen = function(id, transition) {
  if (id !== state.screen) screenStack.push(state.screen);
  origShowScreen(id, transition);
  // ... populate settings sub-screens
};
function goBack() {
  const prev = screenStack.pop() || 'scr-main';
  if (prev === 'scr-main') { showScreen(prev); switchTab(state.tab || 'tonight'); }
  else showScreen(prev, 'slideRight');
}
```

### 26.8 CSS Architecture
- CSS custom properties for iOS system colors (`--ios-bg`, `--ios-secondary`, `--ios-accent`, `--ios-red`, `--ios-green`)
- Dark mode support via `prefers-color-scheme` and manual `.light` / `.dark` classes
- Animations: slide-in/slide-out for screen transitions; fade for overlays
- Responsive: works on mobile Safari and desktop browsers

---

## Cross-Reference Index

| Topic | Section |
|-------|---------|
| 12-dimensional tag engine | Section 8 (v3.0 Section 7) |
| Audio asset delivery | Section 16 (v3.0 Section 15) |
| Backend proxy (AI) | Section 20 (v3.0 Section 19) |
| Combo system | Section 10 (v3.0 Section 9) |
| Complete natal chart computation | v3.0 Section 6 |
| Dev admin tool | Section 17 (v3.0 Section 16) |
| Ephemeris WASM integration | v3.0 Section 6.1 |
| EQ profiles per register | v3.0 Section 9.3 |
| Location scoring rules | `ASTROSLEEP_LOCATION_SCORING_v3.1.md` |
| LFO oscillation rules | v3.0 Section 9.4 |
| RevenueCat configuration | Section 18 (v3.0 Section 17) |
| Security architecture | Section 19 (v3.0 Section 18) |
| Sound manifest format | `Sounds/sounds_manifest.json` |
| Supabase schema | v3.0 Section 13 |
| Tag dimension definitions | v3.0 Section 7.1 |
| Voice system API | Section 11.3 |

---

*End of AstroSleep Product Specification v4.0*
