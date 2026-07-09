# TagEngine v4 → iOS port

**Status: DONE (2026-07-09).** iOS and Android both ship Tag Engine v4. Keep them synced.

## What shipped on iOS

| Piece | Path |
|-------|------|
| `PersonalSoundProfile` + `StackRole` | `Core/Engine/PersonalSoundProfile.swift` |
| Affinity tables | `Core/Engine/TagAffinityTables.swift` |
| Tag Engine v4 ranking | `Core/Engine/TagEngine.swift` |
| Role-based stacking | `Core/Engine/ComboComposer.swift` |
| Score breakdown | `ScoreBreakdown` on `RankedSound` in `Sound.swift` |
| Wiring | `AppState.autoGenerateCombo` → `ComboComposer.compose` |

Parity notes:

- FNV-1a 64-bit fingerprint algorithm matches Android `PersonalSoundProfile.fingerprint`
- Fingerprint jitter uses the same LCG-style mix as Android
- Dimension weights, role gains, affinity tables, and score terms mirrored from Kotlin
- Free tier still uses `tier.maxLayers` (2) via composer

## Ongoing parity rule

**Any change to scoring, affinity tables, role stacking, or fingerprint math must land on both platforms in the same change set.** Do not advance Android v4 features without the Swift twin (and vice versa).

## Remaining polish

1. Optional golden tests: same userId + natal fixtures → same fingerprint + top-N sound ids (cross-platform).
2. Tonight UI: quiet mono truncated hex for `personalFingerprint` (Android already can show “layers · fp …”).
