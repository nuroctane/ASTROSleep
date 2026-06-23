# AstroSleep Tag Engine — Comprehensive Guide

> **What this is:** A complete, plain-English explanation of how AstroSleep decides which sounds to play for you each night. It is written for developers, content managers, and anyone who wants to understand (or improve) the Sounds tab.

---

## 1. The Big Idea in One Sentence

Every sound in AstroSleep is tagged with **12 independent dimensions** (like "domain," "temperature," "archetype"). The Tag Engine converts those 12 tags into a **4-element vector** (Fire, Earth, Air, Water). Your nightly astrological chart also produces a 4-element vector. The sounds whose vectors most closely match your nightly vector get recommended.

**No human hardcodes which sound fits which night. The math does it.**

---

## 2. Why 12 Dimensions?

A single category like "nature vs. mechanical" is not enough to capture how a sound feels. AstroSleep uses 12 axes so that two sounds that are both "water" can still be meaningfully different:

- **Heavy Rain** → water, irregular, mid, nature, heavy, rough, flowing, dense, cool, receptive, lunar, mother
- **Light Rain** → water, irregular, bright, nature, light, crystalline, flowing, sparse, cool, receptive, lunar, maiden

Both are "water," but one is dense/rough/motherly and the other is sparse/crystalline/maidenly. The engine notices this.

---

## 3. The 12 Dimensions (Quick Reference)

| # | Dimension | What It Means | Options | Scoring Weight |
|---|-----------|---------------|---------|----------------|
| 1 | `domain` | The elemental "substance" of the sound | water, air, fire, earth, mechanical, organic, electrical, cosmic | **9x** |
| 2 | `rhythm` | Temporal pattern / pulse | steady, pulse, irregular, chaotic, rhythmic, arrhythmic | 3x |
| 3 | `register` | Frequency range / pitch | sub, deep, mid, bright, full, ultrasonic | 2x |
| 4 | `context` | Environmental association | nature, domestic, abstract, urban, industrial, spiritual | 2x |
| 5 | `weight` | Density / heft | ethereal, light, medium, heavy, massive | 2x |
| 6 | `texture` | Tactile quality | smooth, rough, crystalline, diffuse, granular, glassy, metallic | 2x |
| 7 | `motion` | Movement archetype | static, flowing, surging, swirling, oscillating, drifting, pulsing | 3x |
| 8 | `density` | Signal saturation | vacuum, sparse, moderate, dense, saturated | 2x |
| 9 | `temperature` | Thermal quality | cold, cool, neutral, warm, hot | 2x |
| 10 | `polarity` | Yang/Yin / modality | active, receptive, balanced, neutral | 2x |
| 11 | `celestial` | Astronomical correspondence | solar, lunar, stellar, planetary, void | **4x** |
| 12 | `archetype` | Jungian / mythic mapping | maiden, mother, crone, hero, mentor, shadow, trickster | **4x** |

**Why the weights matter:** `domain` is 9x because it is the strongest elemental signal. `celestial` and `archetype` are 4x because they tie directly to astrological symbolism. Everything else is 2–3x.

---

## 4. From 12 Tags to a 4-Element Vector

Each dimension has a **lookup table** that maps every option to a `[Fire, Earth, Air, Water]` vector. Here is a simplified example:

```
domain = "water"     → [0.5, 1.5, 1.0, 9.0]   (water gets 9.0)
domain = "fire"      → [9.0, 0.5, 1.5, 0.5]   (fire gets 9.0)
rhythm = "steady"    → [0.0, 3.0, 0.5, 1.5]   (earth gets 3.0)
register = "bright"  → [1.5, 0.5, 2.5, 0.0]   (air gets 2.5)
```

To compute a sound's final vector:

1. Look up the vector for each of the 12 tags.
2. Multiply each vector by the dimension's weight.
3. Add all 12 weighted vectors together.
4. Normalize the result so the highest element = 10.0.

**Example:** Heavy Rain
- `domain=water` (9x) → [4.5, 13.5, 9.0, 81.0]
- `rhythm=irregular` (3x) → [6.0, 0.0, 6.0, 4.5]
- `register=mid` (2x) → [2.0, 3.0, 2.0, 2.0]
- ... (9 more dimensions)
- **Raw sum:** [~23, ~31, ~24, ~104]
- **Normalized:** [0.45, 0.82, 0.38, 0.91] (water-dominant)

That final `[0.45, 0.82, 0.38, 0.91]` is the `elementScores` field you see in `sounds_manifest.json`.

---

## 5. Nightly Matching — How Sounds Are Ranked

Every night, the Astrological Engine computes your **Nightly Score**, also a `[Fire, Earth, Air, Water]` vector. It considers:

- Your natal chart (permanent baseline)
- Tonight's moon phase
- Current transits (planets moving over your natal positions)
- House emphasis (if you enable current location)

The Tag Engine then ranks every sound by taking the **dot product** of the sound's vector with the nightly vector. A dot product of:

- **1.0** = perfect match (rare)
- **0.5** = strong match
- **0.2** = weak match

The top N sounds become your "Tonight's Recommendation." N depends on your subscription tier (1 for Free, 3 for Basic, 5 for Pro).

---

## 6. What Adding a Sound Looks Like in the Dev Web GUI

Because the app reads `sounds_manifest.json` at runtime, adding a sound is **purely data entry** — no Swift code changes. The theoretical web GUI would look like this:

### Step A: Upload Audio
- Drag an `.m4a` file (44.1kHz, 16-bit, loop-trimmed)
- The GUI uploads it to Cloudflare R2 and generates a `cdnUrl`
- Optionally mark `bundleFilename` if the file should ship inside the app

### Step B: Fill the 12 Tag Dropdowns
The GUI shows 12 dropdowns, one per dimension. As you select values, a **live preview** updates the computed element scores in real time using the same `TagVectorTables` that the iOS app uses.

```
Domain:     [water ▼]
Rhythm:     [irregular ▼]
Register:   [mid ▼]
Context:    [nature ▼]
Weight:     [heavy ▼]
Texture:    [rough ▼]
Motion:     [flowing ▼]
Density:    [dense ▼]
Temperature:[cool ▼]
Polarity:   [receptive ▼]
Celestial:  [lunar ▼]
Archetype:  [mother ▼]

Live Preview:
Fire:  0.45  ████
Earth: 0.82  ████████
Air:   0.38  ███
Water: 0.91  █████████
```

### Step C: Publish
- Clicking "Publish" writes the new entry into `sounds_manifest.json`
- The CDN cache is invalidated
- The iOS app fetches the updated manifest on next launch
- **No app update required**

---

## 7. How the Sounds Tab Can Be Improved

The current Sounds tab shows a grid of cards with search and basic element filtering. Here is what a richer implementation would add:

### 7.1 Tag-Driven Discovery
Instead of only filtering by "Fire / Earth / Air / Water," let users filter by any of the 12 dimensions:
- "Show me sounds that are `celestial: lunar` and `motion: static`"
- "Show me `archetype: crone` sounds for deep introspection nights"

This is already supported in the Swift code (`activeTagFilters`) but the UI currently only exposes element and "new only."

### 7.2 Match-Percentage Badges
Each card could show a live "92% match" badge computed against tonight's score, making the astrological connection visible rather than hidden.

### 7.3 Sound Detail Sheet
Tapping a card should open a bottom sheet showing:
- All 12 tags
- The computed element score bars
- A "Why this matches tonight" explanation (e.g., "High Water because Moon is transiting your 4th house")
- 30-second preview button
- "Add to Combo" button

### 7.4 Smart Sorting Modes
- **Recommended** (default): sorted by nightly match score
- **Alphabetical**
- **Recently Added**
- **By Domain**: group all water sounds, then fire, etc.

### 7.5 Batch Admin Actions (Dev GUI only)
- Bulk-edit tags across multiple sounds
- Recompute all `elementScores` after a vector table update
- Audit: "Which sounds have `temperature: hot` but `domain: water`?" (potential inconsistencies)

---

## 8. Validation Rules (What the Script Checks)

`validate_manifest.py` enforces these rules before any build:

1. **Every sound must have all 12 tags.**
2. **Tag values must be from the approved lists.** (No invented dimensions.)
3. **No duplicate IDs.**
4. **`elementScores` must be present** (even though they are derived from tags, they are cached for performance).
5. **`bundleFilename` must exist on disk** if provided (warning, not error — CI may run before files are dropped).
6. **Optional:** Recompute scores from tags and warn if they differ from the stored values.

---

## 9. Glossary

| Term | Meaning |
|------|---------|
| **Element Vector** | A `[Fire, Earth, Air, Water]` score array. Every sound and every nightly chart has one. |
| **Tag Dimension** | One of the 12 categories (domain, rhythm, register, etc.). |
| **Tag Value** | The specific option chosen within a dimension (e.g., `domain = "water"`). |
| **Vector Table** | The lookup mapping each tag value to its elemental vector. |
| **Dimension Weight** | How much a dimension matters in the final score (domain = 9x, register = 2x). |
| **Dot Product** | The mathematical operation that compares two vectors. Higher = better match. |
| **Normalization** | Scaling a vector so its highest element = 10.0, making scores comparable across catalogs. |
| **Sound Manifest** | `sounds_manifest.json` — the runtime catalog of all sounds and tags. |

---

## 10. Summary

- **12 tags per sound** → weighted sum → **4-element vector** → normalized to 0–10.
- **Nightly chart** → another 4-element vector.
- **Dot product** of sound vector × nightly vector = recommendation rank.
- **Adding sounds** is data-only via `sounds_manifest.json`; no app rebuild needed.
- **The web GUI** is a content-management layer that outputs the exact same JSON schema the app consumes.

*This guide mirrors the logic in `AstroSleep-iOS/AstroSleep/Core/Engine/TagEngine.swift` and the vector tables in the same file.*
