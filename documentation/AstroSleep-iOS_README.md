# AstroSleep iOS

A native iOS sleep app with astrological personalization, AI-generated subliminal affirmations, and a 12-dimensional tag-based ambient sound engine.

## Architecture

- **UI Framework**: SwiftUI 5.0+ (iOS 26+ SDK required for App Store submission)
- **Architecture Pattern**: MVVM + Combine
- **Audio Engine**: AVFoundation (AVAudioEngine, AVAudioPlayerNode, AVAudioUnitEQ, AVSpeechSynthesizer)
- **Local Storage**: Core Data + Keychain (auth tokens)
- **Sound Delivery**: Bundled assets + CDN fallback with JSON manifest
- **Auth**: Supabase Auth + Apple Sign-In
- **Subscriptions**: RevenueCat (StoreKit 2 abstraction)
- **Networking**: URLSession (AI proxy, CDN)
- **Notifications**: UserNotifications

## Project Structure

```
AstroSleep/
├── App/
│   ├── AstroSleepApp.swift       # App entry point
│   ├── AppState.swift            # Central app state (MVVM)
│   └── SceneDelegate.swift       # Scene lifecycle
├── Core/
│   ├── Models/
│   │   ├── AstrologicalTypes.swift   # Enums: Element, Sign, Planet, Aspect, etc.
│   │   ├── ElementVector.swift       # [Fire, Earth, Air, Water] scoring vector
│   │   ├── Sound.swift               # 12-dimensional tagged sound model
│   │   └── UserModels.swift          # UserProfile, Combo, SessionLog
│   └── Engine/
│       ├── AstrologicalEngine.swift  # Natal chart, transit scoring, base score
│       └── TagEngine.swift           # 12-dimensional archetypal scoring
├── Services/
│   ├── AudioService.swift        # Multi-track AVFoundation playback, LFO, EQ
│   ├── StorageService.swift      # Core Data persistence
│   ├── AuthService.swift         # Supabase auth + Apple Sign-In
│   ├── NetworkService.swift      # AI proxy + CDN calls
│   ├── RevenueCatService.swift   # Subscription management
│   └── NotificationService.swift # Bedtime reminders
├── Views/
│   ├── ContentView.swift         # Root navigation container
│   ├── Onboarding/
│   │   └── OnboardingFlowView.swift
│   ├── Main/
│   │   └── TonightView.swift     # Home screen
│   ├── Playback/
│   │   └── PlaybackView.swift    # Full-screen session player
│   ├── Sounds/
│   │   ├── SoundLibraryView.swift
│   │   └── ComboBuilderView.swift
│   ├── Library/
│   │   └── PlaylistLibraryView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Common/
│       └── PaywallView.swift
├── Sounds/
│   ├── sounds_manifest.json      # Runtime sound catalog (24 sounds + tags)
│   ├── validate_manifest.py      # CI validation script
│   ├── README.md                 # Sound library documentation
│   └── *.m4a                     # Bundled audio assets (optional)
├── Resources/
│   ├── CoreDataModel.xcdatamodeld/   # Core Data schema
│   └── PrivacyInfo.xcprivacy         # Apple privacy manifest (required)
└── Supporting Files/
    ├── Info.plist
    └── AstroSleep.entitlements
```

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode 26+ and create a new iOS App project
2. Product Name: `AstroSleep`
3. Organization Identifier: `com.astrosleep`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. Minimum iOS Version: **26.0** (Apple mandates iOS 26 SDK for all App Store uploads since April 28, 2026)

### 2. Configure Project

1. Copy all source files from `AstroSleep/` into the Xcode project
2. Add the Core Data model: `File > Add Files` → select `CoreDataModel.xcdatamodeld`
3. Update `Info.plist` with your actual API keys
4. Update `AstroSleep.entitlements` with your team ID

### 3. Add Dependencies (Swift Package Manager)

Add via `File > Add Package Dependencies`:

- **RevenueCat**: `https://github.com/RevenueCat/purchases-ios` (v4+)
- **PostHog**: `https://github.com/PostHog/posthog-ios` (v3+)
- **Sentry**: `https://github.com/getsentry/sentry-cocoa` (v8+)
- **Supabase Swift**: `https://github.com/supabase/supabase-swift`

### 4. Configure Capabilities

In Xcode, select the target → Signing & Capabilities → + Capability:

- [x] **Push Notifications**
- [x] **Background Modes**: Audio, Background fetch, Remote notifications
- [x] **Sign in with Apple**
- [x] **iCloud**: CloudKit (for Pro tier backup)
- [x] **Associated Domains**: `applinks:astrosleep.app`

### 5. Required Configuration

API keys are now injected via build settings (xcconfig or Xcode build settings). Do **not** hardcode keys in source files.

Create an `AstroSleep.xcconfig`:

```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-anon-key
REVENUECAT_API_KEY = your-revenuecat-public-key
```

Then in Xcode: Project → Target → Build Settings → Add User-Defined Setting for each key.

### 6. Local Sound Setup (Optional)

Sounds can be bundled locally for offline testing or shipped with the app:

1. Add `.m4a` files to `AstroSleep-iOS/Sounds/`
2. Ensure each sound has an entry in `sounds_manifest.json` with `bundleFilename` set
3. In Xcode, drag the `Sounds/` folder into the project as a **folder reference** (blue folder)
4. Include it in the app target — both `sounds_manifest.json` and `.m4a` files are copied to the bundle
5. Run validation: `python Sounds/validate_manifest.py`

At runtime, the app resolves audio in this order:
1. App bundle (no download needed)
2. Documents cache (previously downloaded from CDN)
3. CDN download (falls back to remote URL)

See `Sounds/README.md` for the full manifest schema and tag reference.

### 7. App Store Connect Setup

1. Register bundle ID: `com.astrosleep.app`
2. Enable capabilities (matches entitlements file)
3. Create subscription products in App Store Connect:
   - `astrosleep_basic_monthly`
   - `astrosleep_basic_annual`
   - `astrosleep_pro_monthly`
   - `astrosleep_pro_annual`
4. Configure RevenueCat dashboard with products and entitlements
5. Configure Cloudflare Worker with Anthropic API key
6. Configure Supabase with auth providers (email, Apple)
7. Complete "Paid Applications Agreement" in Agreements, Tax, and Banking

### 8. App Store Submission Guide

#### Background Audio Critical Requirement
In Xcode, under **Signing & Capabilities**, add **"Audio, AirPlay, and Picture in Picture"** background mode. Without this, ambient sounds will cut off when the screen locks — an immediate rejection for a sleep app.

#### Generative AI Disclosure
Apple requires disclosure of Generative AI usage. In App Store Connect:
- Check the **"This app uses Generative AI"** box
- The `PrivacyInfo.xcprivacy` includes `NSGenerativeAIDisclosure` with content filtering enabled
- The Cloudflare Worker proxy strictly limits AI output to positive, sleep-focused affirmations via a controlled system prompt
- **Do not** claim the app "cures insomnia" or "treats anxiety" in App Store metadata — stick to "sleep wellness" and "mindfulness"

#### Privacy Label Configuration
Since birth data never leaves the device:
- **Contact Info**: Not collected (auth is anonymous)
- **Health & Fitness**: Not collected (astrological data is not health data)
- **Precise Location**: Declared only if using GPS for birth city geocoding (single use, not stored)
- The `PrivacyInfo.xcprivacy` includes entries for Audio Data (voice recordings) and Coarse Location

#### RevenueCat & Paywall Compliance
- The paywall includes a clearly visible **"Restore Purchases"** button (required by Apple)
- Subscription terms explain auto-renewal and cancellation
- Free trial is offered (7-day) with clear pricing after trial

#### Reviewer Account Setup
Provide Apple with a demo account that unlocks Pro features:
- The app pre-loads a default "Recommended Combo" for the current moon phase
- Ensure Combo Builder (all layers, EQ, speed controls) is fully accessible
- Test on physical device (arm64) before submission, as KMP frameworks may behave differently than simulator

#### TestFlight Validation Checklist
Before final submission, verify via TestFlight on a physical device:
- [ ] Audio continues playing with screen locked for 30+ minutes
- [ ] Incoming phone call pauses audio; resuming works correctly
- [ ] LFO oscillation behaves correctly during audio interruptions
- [ ] Sleep timer fires and fade-out completes gracefully
- [ ] Combo Builder saves and loads correctly with all layer types
- [ ] Paywall displays correctly and Restore Purchases functions
- [ ] Background fetch works for daily affirmation refresh

### 9. Build & Run

Select a target device/simulator and press **Cmd+R**.

## Security Checklist

- [x] **No API keys in source code** (injected via build settings / xcconfig)
- [x] **Auth tokens in Keychain** (`kSecAttrAccessibleAfterFirstUnlock`)
- [x] **Birth data never leaves device** (local Core Data only, never uploaded)
- [x] **HTTPS only** (`NSAllowsArbitraryLoads = false`)
- [x] **Localhost exception** for development only (`NSExceptionAllowsInsecureHTTPLoads`)
- [x] **Rate limiting on AI proxy** (server-side, 1 affirmation/day/user)
- [x] **Subscription validation server-side** (RevenueCat, never trust local tier)
- [x] **Prompt injection defense** (proxy strips system prompts, controlled output)
- [x] **PII not in analytics** (no birth data, coordinates, or intentions)
- [x] **Privacy manifest included** (`PrivacyInfo.xcprivacy` with accessed API declarations)
- [x] **Generative AI disclosure** (`NSGenerativeAIDisclosure` in Info.plist)
- [x] **Encryption export compliance** (`ITSAppUsesNonExemptEncryption = false`)

## Astrological System

All calculations use:
- **Zodiac**: Sidereal (13 signs with Ophiuchus)
- **Ayanamsha**: Sharatan (Beta Arietis)
- **House System**: Equal (Ascendant = 1st house cusp)
- **Coordinates**: Topocentric
- **Nodes**: True Nodes
- **Asteroids**: Chiron, Lilith (Mean)

## Tag Engine v3.0

12-dimensional archetypal scoring with decimal precision:
`domain` (9x weight), `celestial` (4x), `archetype` (4x), `rhythm` (3x), `motion` (3x), `register`, `context`, `weight`, `texture`, `density`, `temperature`, `polarity` (2x each)

## License

Proprietary. All rights reserved.
