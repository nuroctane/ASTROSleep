# AstroSleep Sound Library

This folder contains the **sound manifest** and bundled audio files for AstroSleep.

## How It Works

The app loads its sound catalog from `sounds_manifest.json` at runtime. This decouples sound metadata from Swift code — you can add, edit, or remove sounds without recompiling.

### Resolution Order (at runtime)

When the app needs to play a sound:

1. **App Bundle** — checks if `bundleFilename` exists inside the app binary (no download)
2. **Documents Cache** — checks if the file was previously downloaded from the CDN
3. **CDN Download** — fetches from `cdnUrl` and caches for next time

## File Structure

```
Sounds/
  sounds_manifest.json   # Catalog of all sounds + tags + metadata
  validate_manifest.py   # Validation script
  *.m4a                  # Audio files bundled with the app (optional)
```

## Adding a New Sound (Manual)

1. **Drop the `.m4a` file** into this `Sounds/` folder.
2. **Open `sounds_manifest.json`** and add a new entry to the `sounds` array:

```json
{
  "id": "my_new_sound",
  "name": "My New Sound",
  "tags": {
    "domain": "water",
    "rhythm": "steady",
    "register": "deep",
    "context": "nature",
    "weight": "medium",
    "texture": "smooth",
    "motion": "flowing",
    "density": "moderate",
    "temperature": "cool",
    "polarity": "receptive",
    "celestial": "lunar",
    "archetype": "mother"
  },
  "elementScores": {
    "fire": 0.3,
    "earth": 0.5,
    "air": 0.4,
    "water": 0.8
  },
  "durationSeconds": 60,
  "isNew": true,
  "version": 1,
  "cdnUrl": "https://cdn.astrosleep.app/sounds/my_new_sound.m4a",
  "bundleFilename": "my_new_sound.m4a"
}
```

3. **Run validation**:

```bash
cd AstroSleep-iOS/Sounds
python validate_manifest.py
```

4. **Add the folder to Xcode**:
   - Drag the `Sounds/` folder into your Xcode project
   - Select **"Create folder references"** (not "Create groups")
   - Ensure the folder is included in the app target
   - This copies both `sounds_manifest.json` and any `.m4a` files into the app bundle

5. **Build and run** — the new sound appears in the library immediately.

## Tag Dimensions (12 Total)

All 12 dimensions are required. See `validate_manifest.py` for the complete list of valid values per dimension.

| Dimension | Description | Weight in Scoring |
|-----------|-------------|-------------------|
| `domain` | Elemental identity | 9x |
| `celestial` | Astronomical correspondence | 4x |
| `archetype` | Jungian / mythic mapping | 4x |
| `rhythm` | Temporal pattern | 3x |
| `motion` | Movement archetype | 3x |
| `register` | Frequency register | 2x |
| `context` | Environmental context | 2x |
| `weight` | Density / planetary affinity | 2x |
| `texture` | Tactile quality | 2x |
| `density` | Signal saturation | 2x |
| `temperature` | Thermal quality | 2x |
| `polarity` | Yang/Yin modality | 2x |

## Fields Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Unique machine identifier (snake_case) |
| `name` | String | Yes | Human-readable display name |
| `tags` | Object | Yes | All 12 tag dimensions |
| `elementScores` | Object | Yes | Pre-computed `[fire, earth, air, water]` 0-10 |
| `durationSeconds` | Int | Yes | Loop duration for UI display |
| `isNew` | Bool | Yes | Shows "NEW" badge in app |
| `version` | Int | Yes | Increment when updating a sound |
| `cdnUrl` | String | Yes | Remote fallback URL |
| `bundleFilename` | String | No | Local filename if shipping inside app bundle |

## Dev Web GUI (Future)

The eventual admin tool will:
- Display the same 12 tag dropdowns
- Live-compute element scores from tags
- Generate this exact JSON structure
- Upload audio to R2/Cloudflare and update the manifest

The JSON schema here is the single source of truth for both local development and production CDN.
