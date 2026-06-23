# iOS Go-Live Checklist

> **Purpose:** A comprehensive checklist to publish AstroSleep to the Apple App Store from its current state. Reviewed against Apple's requirements as of May 2026.

---

## Critical Dates

- **April 28, 2026:** Apple mandates all new uploads use **iOS 26 SDK / Xcode 26**.
- **Before submission:** All items in this checklist must be green.

---

## 1. Build Environment & Compatibility

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.1 | Install **Xcode 26** (or later) from Mac App Store or developer portal | 🔴 | Required for App Store Connect uploads |
| 1.2 | Verify **iOS 26 SDK** is selected in project build settings | 🔴 | `IPHONEOS_DEPLOYMENT_TARGET` should be `26.0` minimum |
| 1.3 | Set **minimum iOS version** to `26.0` (not 16.0) | 🔴 | Apple no longer accepts builds targeting older SDKs |
| 1.4 | Enable **Strict Concurrency Checking** in Swift compiler settings | 🟡 | Already in codebase; verify flag is on |
| 1.5 | Build on **physical device** (arm64) — not just simulator | 🔴 | Critical for audio / push / Sign-In with Apple validation |
| 1.6 | Run unit tests and UI tests without failures | 🔴 | Add tests for TagEngine, AudioService, AppState |
| 1.7 | Verify no deprecated API warnings remain | 🟡 | v3.2 changelog addressed most; do a final sweep |

---

## 2. Assets & Visual Identity

| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.1 | Create **AppIcon.appiconset** with all required sizes (iPhone + iPad) | 🔴 | Not yet in repo |
| 2.2 | Design **LaunchScreen.storyboard** or launch screen SwiftUI view | 🔴 | Not yet in repo |
| 2.3 | Add **App Store screenshots** for all supported devices | 🔴 | iPhone 15 Pro, iPhone 15, iPhone SE, iPad Pro, iPad Air |
| 2.4 | Create **App Preview** video (optional but recommended) | 🔴 | 15–30 seconds demonstrating Tonight → Playback flow |
| 2.5 | Verify **dark mode** appearance across all screens | 🟡 | Most views use system backgrounds; test manually |
| 2.6 | Verify **dynamic type / accessibility** text scaling | 🟡 | Test largest accessibility size on each screen |

---

## 3. Apple Compliance Files

| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.1 | `PrivacyInfo.xcprivacy` is present and accurate | 🟢 | Added v3.1; verify against actual API usage |
| 3.2 | `AstroSleep.entitlements` has all required capabilities | 🟢 | Push, Apple Sign-In, IAP, Associated Domains, Keychain |
| 3.3 | `Info.plist` uses build-setting injection for API keys | 🟢 | `$(SUPABASE_URL)`, `$(SUPABASE_ANON_KEY)`, etc. |
| 3.4 | `ITSAppUsesNonExemptEncryption = false` is set | 🟢 | Added v3.1 |
| 3.5 | `NSGenerativeAIDisclosure` is present | 🟢 | Already present |
| 3.6 | `NSMicrophoneUsageDescription` is present | 🟢 | For Pro voice recording |
| 3.7 | `NSLocationWhenInUseUsageDescription` is present | 🟢 | For birth city geocoding |
| 3.8 | App Transport Security allows **HTTPS only** | 🟢 | `NSAllowsArbitraryLoads = false` |
| 3.9 | **localhost exception** is development-only | 🟢 | `NSExceptionAllowsInsecureHTTPLoads` for localhost |
| 3.10 | **Privacy Policy URL** is live: `https://astrosleep.app/privacy` | 🔴 | Must be a real, reachable webpage |
| 3.11 | **Terms of Service URL** is live: `https://astrosleep.app/terms` | 🔴 | Must be a real, reachable webpage |

---

## 4. App Store Connect Configuration

| # | Task | Status | Notes |
|---|------|--------|-------|
| 4.1 | Register **Bundle ID**: `com.astrosleep.app` | 🔴 | In Apple Developer portal |
| 4.2 | Create app record in **App Store Connect** | 🔴 | With correct bundle ID, SKU, primary category (Health & Fitness or Lifestyle) |
| 4.3 | Configure **App Pricing** (Free with subscriptions) | 🔴 | |
| 4.4 | Create **subscription products** in App Store Connect | 🔴 | `astrosleep_basic_monthly`, `astrosleep_basic_annual`, `astrosleep_pro_monthly`, `astrosleep_pro_annual` |
| 4.5 | Configure **RevenueCat dashboard** with product IDs and entitlements | 🔴 | Must match App Store Connect exactly |
| 4.6 | Set up **Sign in with Apple** capability in Developer portal | 🔴 | Must be enabled for the App ID |
| 4.7 | Configure **Associated Domains** with Apple App Site Association file | 🔴 | Host `apple-app-site-association` at `astrosleep.app/.well-known/` |
| 4.8 | Upload **TestFlight build** and verify on device | 🔴 | Do this before final submission |
| 4.9 | Complete **Paid Applications Agreement** | 🔴 | Required for any paid app or IAP |
| 4.10 | Configure **EU Digital Services Act (DSA) trader status** | 🔴 | Required for EU App Store distribution |
| 4.11 | Update **age rating** to align with Apple's new system (April 2026) | 🔴 | Apple auto-updated; verify in App Store Connect |

---

## 5. Backend & Services

| # | Task | Status | Notes |
|---|------|--------|-------|
| 5.1 | **Supabase project** is live with auth providers enabled | 🔴 | Email + Apple Sign-In |
| 5.2 | **Cloudflare Worker** (AI proxy) is deployed with Anthropic key | 🔴 | Must enforce rate limit: 1 affirmation/day/user |
| 5.3 | **CDN / R2 bucket** is serving sound files over HTTPS | 🔴 | `cdn.astrosleep.app/sounds/` |
| 5.4 | **Cloudflare Worker** returns controlled system prompts only | 🟢 | Proxy strips user-injected system prompts |
| 5.5 | **RevenueCat webhooks** are configured for receipt validation | 🔴 | |
| 5.6 | **Privacy policy** and **Terms** pages are hosted and linked | 🔴 | See 3.10 and 3.11 |

---

## 6. Audio & Playback Validation (TestFlight on Device)

| # | Task | Status | Notes |
|---|------|--------|-------|
| 6.1 | Audio continues playing with **screen locked** for 30+ minutes | 🔴 | Background audio mode must be enabled |
| 6.2 | Incoming **phone call** pauses audio; resuming works correctly | 🔴 | |
| 6.3 | **LFO oscillation** behaves correctly during interruptions | 🔴 | Pro feature |
| 6.4 | **Sleep timer** fires and fade-out completes gracefully | 🔴 | Test 30, 60, 90, 120 min options |
| 6.5 | **Combo Builder** saves and loads correctly with all layer types | 🔴 | |
| 6.6 | **Per-layer volume sliders** affect actual playback | 🔴 | |
| 6.7 | **Playback speed** changes pitch-correctly on each layer | 🔴 | Basic + Pro feature |
| 6.8 | **EQ profiles** (sub, deep, mid, bright, full) are audible | 🔴 | |
| 6.9 | **Affirmation TTS** speaks at configured speed and volume | 🔴 | Test female, male, custom (Pro) voices |
| 6.10 | **Sound bundle fallback** works when offline (bundled .m4a) | 🟡 | Verify `bundleFilename` references in manifest |

---

## 7. Subscription & Paywall Compliance

| # | Task | Status | Notes |
|---|------|--------|-------|
| 7.1 | **"Restore Purchases"** button is visible and functional | 🟢 | Present on PaywallView |
| 7.2 | **Auto-renewal terms** displayed before purchase | 🟢 | On paywall card |
| 7.3 | **Free trial** (7-day) is offered with clear post-trial pricing | 🟢 | Basic and Pro cards show this |
| 7.4 | **Tier enforcement** works: Free = 1 layer, Basic = 2, Pro = 5 | 🟢 | `SubscriptionTier.maxLayers` |
| 7.5 | Paywall triggers correctly for **Pro-only features** | 🟢 | Oscillation, custom theming, custom voice |
| 7.6 | **Receipt validation** is server-side (RevenueCat), never local | 🟢 | Never trust `currentTier` from device alone |

---

## 8. Security & Privacy

| # | Task | Status | Notes |
|---|------|--------|-------|
| 8.1 | **No API keys in compiled binary** | 🟢 | Build-setting injection via xcconfig |
| 8.2 | **Auth tokens stored in Keychain** with `kSecAttrAccessibleAfterFirstUnlock` | 🟢 | Verify in `AuthService.swift` |
| 8.3 | **Birth data never uploaded** | 🟢 | Local Core Data only; stated in privacy policy |
| 8.4 | **Intentions / affirmations** not stored in analytics | 🟢 | PostHog events must not include PII |
| 8.5 | **Rate limiting** on AI proxy prevents abuse | 🟢 | 1 affirmation/day/user server-side |
| 8.6 | **Prompt injection defense** on Cloudflare Worker | 🟢 | Controlled output, stripped system prompts |

---

## 9. Reviewer Demo Account

| # | Task | Status | Notes |
|---|------|--------|-------|
| 9.1 | Create a **demo Apple ID** with pre-completed onboarding | 🔴 | Supply credentials in App Store Connect |
| 9.2 | Ensure **Pro tier** is unlockable in demo mode | 🔴 | Or provide promo code / sandbox purchase flow |
| 9.3 | Document **combo builder** and **playback** steps for reviewer | 🔴 | Short bullet list in review notes |

---

## 10. Final Submission Steps

| # | Task | Status | Notes |
|---|------|--------|-------|
| 10.1 | Archive build in Xcode with **Release** configuration | 🔴 | |
| 10.2 | Validate archive against App Store Connect | 🔴 | Product → Archive → Validate App |
| 10.3 | Upload to **App Store Connect / TestFlight** | 🔴 | |
| 10.4 | Submit for **Beta App Review** (TestFlight) | 🔴 | Do this first |
| 10.5 | Internal testing with TestFlight on 3+ physical devices | 🔴 | iPhone models with different screen sizes |
| 10.6 | Submit for **App Review** | 🔴 | Only after TestFlight validation passes |
| 10.7 | Monitor **App Review** feedback and respond within 24 hours | 🔴 | |

---

## Summary — Blockers Before Go-Live

These are the **absolute must-haves** that are currently red:

1. **Xcode 26 + iOS 26 SDK** minimum target
2. **AppIcon.appiconset** and **Launch Screen**
3. **App Store screenshots** for all device sizes
4. **Privacy Policy** and **Terms of Service** web pages live
5. **Backend services** (Supabase, Cloudflare Worker, RevenueCat, CDN) fully deployed
6. **App Store Connect** app record, subscriptions, and agreements configured
7. **Physical device testing** of all audio features via TestFlight
8. **DSA trader status** for EU distribution
9. **Reviewer demo account** with clear instructions

*Last updated: 2026-05-12 | AstroSleep v3.2*
