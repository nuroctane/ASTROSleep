# Digital Sea — AstroSleep Design System

> Agent-oriented design source of truth. Derived from [emilkowalski/skills](https://github.com/emilkowalski/skills)
> (emil-design-eng + apple-design), iOS 26 Liquid Glass, and family Digital Sea tokens.
> Related bookmarks: VoltAgent/awesome-design-md, TourKit (onboarding craft), OriginKit (motion vocabulary).

## Product feel

**Quiet night, not casino.** Deep void field, glass surfaces, biolume accents, restrained motion.
Sleep UX prioritizes calm feedback over spectacle. Every press should feel heard; nothing should thrash.

## Color tokens

| Token | Value | Role |
|-------|-------|------|
| `--sea-void` | `#070B14` | App chrome / night sky base |
| `--sea-field` | `#0B1220` | Gradient stop / secondary field |
| `--sea-surface` | `#121A2B` | Elevated surfaces (Material surface) |
| `--sea-elevated` | `#1A2438` | Cards above surface |
| `--sea-border` | `#2A3650` | Hairline borders |
| `--sea-border-soft` | `rgba(255,255,255,0.08)` | Glass edge |
| `--sea-glass-edge` | `rgba(255,255,255,0.22)` | Top specular on glass |
| `--sea-text` | `#E8EEF8` | Primary text |
| `--sea-muted` | `#9AA8C0` | Secondary text |
| `--sea-faint` | `#6B7A94` | Tertiary / labels |
| `--sea-accent` | `#5856D6` | Primary actions (iOS system indigo family) |
| `--sea-accent-soft` | `rgba(88,86,214,0.22)` | Selected chips |
| `--sea-biolume` | `#5AC8FA` | Highlights, moon, live stats |
| `--sea-success` | `#34C759` | Success / restore OK |
| `--sea-danger` | `#FF453A` | Errors |

**Android:** `Theme.kt` + `SeaSurfaces.kt`  
**iOS:** Digital Sea gradients in views + `LiquidGlassSupport.swift`  
**Web (family):** blackjack `src/styles/sea.css`

## Materials

1. **System Liquid Glass (iOS 26+)** — prefer system TabView/Nav chrome; never force opaque toolbar fills.
2. **Content glass cards** — gradient fill + hairline border + soft top edge; blur when platform allows.
3. **Reduced transparency** — fall back to solid `--sea-surface` (no blur).

### Android glass recipe (`SeaGlassCard`)

```
linear gradient: rgba(255,255,255,0.09) → #121A2B@0.8 → #0B1220@0.9
border: 1dp rgba(255,255,255,0.13)
corner: 16dp continuous
```

### iOS glass recipe

- iOS 26+: `.glassEffect(Glass.regular, in: shape)`
- Earlier: `.ultraThinMaterial` / `secondarySystemBackground`

## Typography

- Prefer system SF / Roboto / system-ui
- Display titles: semibold–bold, slight negative tracking
- Stats / fingerprints / scores: monospaced / tabular nums
- Body secondary: `--sea-muted`

## Motion (Emil + Apple)

### Curves

| Name | Curve | Use |
|------|-------|-----|
| ease-out | `cubic-bezier(0.23, 1, 0.32, 1)` | Enter, press release, UI state |
| ease-in-out | `cubic-bezier(0.77, 0, 0.175, 1)` | On-screen morph |
| drawer | `cubic-bezier(0.32, 0.72, 0, 1)` | Sheets / drawers |

### Durations

| Interaction | Duration |
|-------------|----------|
| Press scale | 100–160ms |
| Chips / small UI | 125–200ms |
| Cards / sections enter | 150–250ms |
| Sheets | 200–400ms |
| **Hard cap for UI** | **≤ 300ms** |

### Rules (non-negotiable)

1. **Press feedback** — every tappable scales to `0.97` (Emil). Opacity ~0.92 optional.
2. **Never animate from scale(0)** — enter at `scale(0.95)+opacity 0`.
3. **ease-out for UI**; never ease-in on controls.
4. **Only animate transform + opacity** (GPU). No layout thrash on press.
5. **prefers-reduced-motion** — keep opacity/color; drop position/scale travel.
6. **Stagger lists** 30–80ms between items; never block interaction.
7. **No animation on high-frequency actions** (rapid tab switches may crossfade lightly only).
8. **Touch hover gating** — hover lift only when `(hover: hover) and (pointer: fine)`.

### Platform hooks

| Platform | Press | Reduced motion | Glass |
|----------|-------|----------------|-------|
| Android Compose | `Modifier.seaPressable()` | `LocalAccessibilityManager` / `reduceMotion` | `SeaGlassCard` |
| iOS SwiftUI | `SeaPressButtonStyle` | `accessibilityReduceMotion` | `astroGlassCard` |
| Web | `.sea-btn:active { scale(0.97) }` | `@media (prefers-reduced-motion)` | `.sea-glass` |

## Layout & density

- Screen padding 20dp/pt
- Card stack gap 12–16
- Bottom nav content inset respected (scaffold padding)
- Scroll content clears floating glass tab bar (iOS `astroScrollEdgeAware`)

## Onboarding (TourKit-inspired craft)

- One calm column; privacy line first-class
- Primary CTA only after required fields
- Progress feel via step copy, not flashy carousels
- Birth data privacy callout always visible near form

## Accessibility

- Contrast: text on void meets WCAG AA for body
- Dynamic Type / font scale respected (system)
- Reduced motion + reduced transparency supported
- Touch targets ≥ 44pt / 48dp for primary actions
- Meaningful content descriptions on logo / icons

## Component checklist

| Component | Must have |
|-----------|-----------|
| Primary button | Accent fill, press 0.97, disabled opacity 0.4 |
| Secondary button | Border only, soft fill on press |
| Glass card | Gradient + hairline + continuous corners |
| Nav tab | Selected biolume/accent, no bounce |
| Paywall | Clear tiers, restore path, no dark patterns |
| Playback controls | Immediate state change + press feedback |

## Anti-patterns

- Slot-machine neon, confetti on sleep flows
- `transition: all`
- Bounce springs on professional sleep UI (subtle only)
- Opaque custom tab bars on iOS 26 (kills Liquid Glass)
- DEBUG purchase unlocks in release builds

## Family products

AstroSleep and Digital Sea Blackjack share tokens, motion rules, and glass recipes.
When in doubt, match blackjack `sea.css` and this file — not ad-hoc hex values.
