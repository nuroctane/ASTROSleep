# Tag Engine v4 — Personalized Sonic Fingerprints (Android + iOS)

> Goal: every sign-in / natal chart produces a **vastly different** ranking and layer stack from the same sound catalog. Sound **assets** are unchanged; the math is what diverges.

> **Parity (2026-07-09):** iOS ships the same architecture (`PersonalSoundProfile`, `TagAffinityTables`, `TagEngine`, `ComboComposer`). **Any change to this math must land on both platforms in the same change set.**

## Why v3 wasn't enough

v3 ranked with a single nightly × tag-vector dot product. Two users with similar elemental nights often got the **same top-N** and the same volume split.

## Architecture

```
NatalChart + userId
        │
        ▼
PersonalSoundProfile          ◄── fingerprint, dim multipliers, tag affinities,
        │                           natal/nightly/transit pulls, role order
        ▼
TagEngine.rankSoundsPersonalized
        │   • remapped 12-dim vectors
        │   • nightly + natal resonance
        │   • planet/sign/phase tag affinity
        │   • transit aspect texture pulls
        │   • deterministic fingerprint jitter
        ▼
ComboComposer.compose
        │   • role seats: BEDROCK → FOUNDATION → FLOW → TEXTURE → VEIL → SPARK → ACCENT
        │   • diversity penalty (tag Jaccard + domain collision)
        │   • per-role volume / speed / EQ / LFO
        ▼
Combo (layers unique to this user+night)
```

## Score anatomy (per sound)

| Term | What it captures |
|------|------------------|
| Nightly resonance | Tonight's ElementVector × personalized tag vector × `nightlyPull` |
| Natal resonance | Lifelong base score × tag vector × `natalPull` |
| Catalog prior | Soft pull from manifest `elementScores` |
| Tag affinity | Moon/sun/rising/planets/stelliums/signature tags (log-compressed) |
| Transit resonance | Active transit planets + hard/soft aspect texture bias |
| Moon phase palette | Phase-specific tag preferences |
| Element align | Dominant / secondary / opposite (contrastBias) |
| Modality fit | Cardinal motion vs fixed rhythm vs mutable texture |
| Fingerprint jitter | Stable −1…1 from `userId ⊕ chart ⊕ soundId` — breaks ties uniquely |
| Lunar bias | Extra weight for lunar-tagged sounds when moon is known |

`ScoreBreakdown` is attached to every `RankedSound` for UI/debug.

## PersonalSoundProfile levers

Derived once per user from chart + id:

- **dimensionMultipliers** — stretch domain/celestial/… weights (e.g. water natives amplify motion+celestial)
- **tagAffinities** — sparse map of preferred tag strings with strengths
- **natalPull / nightlyPull / transitPull** — how much each sky layer matters
- **diversityBias / contrastBias** — stack variety vs opposite-element spice
- **roleOrder** — which mix seats fill first (rotated by element + modality + salt)
- **fingerprint** — 64-bit FNV-style hash of placements + base score + user id

Same chart + same user id → identical results (deterministic).  
Different chart **or** different user id → different tops and stacks (proven in unit tests).

## Combo stacking

Not top-N by score. For each seat in `roleOrder`:

1. Score candidates = rank score + role-fit − diversity penalty vs already picked
2. Assign volumes from role gains × element boost, normalized to a user-specific master budget
3. Playback speed, EQ tilt, and LFO period/depth come from role + modality + salt

## Tests

`TagEnginePersonalizationTest` asserts:

- Different birth charts → different top-5 (Jaccard < 0.8)
- Same chart, different user ids → different ordered tops
- Cancer vs Aries combos → different layer sets
- New moon vs full moon → different tops for same user
- Breakdown fields populated

## Files

| File | Role |
|------|------|
| `PersonalSoundProfile.kt` | Fingerprint + affinity profile |
| `TagAffinityTables.kt` | Sign/planet/phase/role lookup tables |
| `TagEngine.kt` | Multi-factor scoring |
| `ComboComposer.kt` | Role-based stack builder |
| `RankedSound.kt` | Score + breakdown model |
