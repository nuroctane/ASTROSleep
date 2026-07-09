# Bug review — AstroSleep + Digital Sea Blackjack

Date: 2026-07-09 · Severity: P0 blocker / P1 high / P2 medium / P3 polish

---

## AstroSleep

### Fixed this pass

| Sev | Issue | Fix |
|-----|--------|-----|
| P1 | Android `Scaffold` discarded `paddingValues` → content under nav bar | Apply `Modifier.padding(padding)` wrapper in `AstroSleepRoot` |
| P1 | Tonight "Begin" called `onGenerate()` then immediate `onPlay()` (async race) | `startSession()` already auto-generates; call `onPlay()` only |
| P2 | Cosmic WebView used deprecated `javaScriptEnabled`; weak load paths | `WKWebpagePreferences.allowsContentJavaScript` + multi-path bundle load + nav error logging |
| P2 | Xcode bundle membership for `cosmic-systems` undocumented | `documentation/XCODE_COSMIC_BUNDLE.md` |

### Residual / platform

| Sev | Issue | Notes |
|-----|--------|-------|
| P1 | **No committed `.xcodeproj`** | Sources only; cosmic assets must be added to target manually (doc above). Cannot fully automate on this machine. |
| P2 | iOS Cosmic tab needs **Copy Bundle Resources** | Without it, users see “bundle missing” HTML |
| P2 | CocoaPods / Xcode not on Windows for Cap iOS of sibling apps | N/A to AstroSleep native |
| P3 | Android Cosmic WebView uses deprecated file-URL access flags | Required for offline `vendor/three.min.js`; monitor Android API deprecations |
| P3 | Affirmation network errors only partially surfaced | Existing behavior; rate-limit silent |

### Review notes (no change)

- iOS Liquid Glass adoption looks correct (no opaque bars, glass helpers, tab minimize).
- `ThemeConfig` default accent already `5856D6`.
- Natal privacy: Cosmic tab systems-only is correct.

---

## Blackjack (`nuroctane/blackjack`)

### Fixed this pass

| Sev | Issue | Fix |
|-----|--------|-----|
| **P0** | Mid-hand / low-penetration `freshShoe()` **reintroduced dealt cards** into the shoe | Reshuffle only between hands (`nextRound` / pre-deal); mid-draw uses `rebuildShoeExcluding` by rank/suit multiset |
| P1 | Soft-total `soft` flag messy dual-path | Single ace-as-11 counter after reduction |
| P1 | Dealer always stood on soft 17 | Explicit **H17** (`DEALER_HITS_SOFT_17`) |
| P1 | No SIWE after wallet connect | `SiweButton` + EIP-4361 message + local session (24h); **server verify still open** |
| P2 | Capacitor export missing `out/` (ts config ignored) | `next.config.mjs` with `output: "export"` |
| P2 | Android edge-to-edge / status bar | `MainActivity` translucent bars + void color |
| P2 | iOS dark UI / ATS | `Info.plist` dark + no arbitrary loads |
| P2 | Odds/UI craft | Liquid glass CSS, press scale, reduced-motion |

### Residual

| Sev | Issue | Notes |
|-----|--------|-------|
| P1 | **SIWE not server-verified** | Local signature only — do not trust for payouts until backend verify |
| P1 | No double / split / insurance | Documented backlog |
| P1 | iOS Cap build needs **Mac + CocoaPods + Xcode** | Project generated; open via `npx cap open ios` on Mac |
| P2 | Wagmi/MetaMask peer warnings (`async-storage`, `pino-pretty`) | Build succeeds; consider `npm i pino-pretty` or connector pruning |
| P2 | Demo WalletConnect project id | Set `NEXT_PUBLIC_WC_PROJECT_ID` for production |
| P3 | GitHub auth is link-only | NextAuth not wired |

### Tests

```bash
cd Laboratory/blackjack
npx tsx src/lib/shoe.test.ts   # must print: all passed
```

---

## Blockers matrix (addressed vs residual)

| Blocker | Status |
|---------|--------|
| Cosmic Xcode membership | **Documented + multi-path load**; still needs human Xcode step (no pbxproj in repo) |
| Blackjack liquid glass + native shell | **Addressed** (CSS materials + Cap iOS/Android + edge-to-edge) |
| SIWE | **Client path addressed**; server verify residual P1 |
| Shoe integrity | **Fixed P0** |
| Android content under nav | **Fixed** |
| Cap static `out/` | **Fixed** via `next.config.mjs` |
| Mac/Xcode for Cap iOS | **Residual** (environment) |

---

## Recommended next engineering order

1. Xcode: add cosmic-systems to AstroSleep target (5 min)  
2. Backend SIWE verify endpoint + HttpOnly cookie  
3. Blackjack double/split  
4. Mac: `pod install` + run Cap iOS on device  
5. Optional: prune MetaMask connector warnings  
