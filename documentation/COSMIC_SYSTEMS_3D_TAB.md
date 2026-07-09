# Cosmic Systems — 3D interactive experience tab (iOS + Android)

## Intent

A main-app tab (or primary library entry) for an **interactive 3D sidereal “systems” sky / horoscope experience**.

This is **not** a dump of the user’s personal natal chart into 3D.  
It teaches and *feels* the **astrological systems** AstroSleep is built on (zodiac, ayanamsha, houses, nodes, frame), using a solar-system style scene as the vehicle.

Personal birth data stays on-device and is used only by the existing natal/tag engines. This tab defaults to **system reference mode**.

## System reference (from chart standard — not personal placements)

Source of truth for *which* systems to encode (labels match the sidereal chart sheet style):

| System axis | Value |
|-------------|--------|
| Zodiac | **13-sign** (Zodiac 13 / Aspectarians; includes Ophiuchus) |
| Ayanamsha | **Custom Sharatan (Beta Aries)** — reference offset **02° Aries 15′** |
| Frame | **Topocentric** |
| Houses | **Equal** (Asc = 1st) when a local horizon is shown |
| Nodes | **True Nodes** |
| Body set | **Modern** (planets + modern points as product allows: SN, ALC/ALN labels only if already in engine) |

> The JPEG at `E:\Workstation\ASSETs\Image Assets\Personal\dd astro chart sidereal.jpeg` is a **systems reference** for labels and layout language. **Do not** hardcode that chart’s personal longitudes into the app or ship PII.

## Visual / tech baseline

| Piece | Source | How we use it |
|-------|--------|----------------|
| 3D scene, camera fly, planet focus | [thebuggeddev/solar-system](https://github.com/thebuggeddev/solar-system) | Port patterns: Three.js planet rail, GSAP camera rig, fog, textures — **not** the Gemini AI Studio shell as a product dependency |
| Brand / glass / motion | `Building & Projects/DESIGN.md` | Sea void background, biolume accents, quiet motion; optional liquid-glass hero only on marketing web |
| Glass native | `IOS_LIQUID_GLASS.md` | UI chrome around the scene, not the WebGL itself |

### Port strategy

1. **iOS:** SceneKit or RealityKit *or* a thin WKWebView hosting a local Three.js bundle (faster parity with reference). Prefer one stack for both platforms if maintenance cost matters → **shared WebView bundle** under `shared/cosmic-systems/` is acceptable v1.  
2. **Android:** WebView + same bundle, or Filament/SceneView later.  
3. Strip Gemini / Express server from the reference app — pure offline scene.  
4. Recolor planets/sky to Digital Sea (void `#070B14`, accents `#5856D6` / `#5AC8FA`).

## UX — tab “Cosmos” / “Systems”

### Modes

1. **Systems overview (default)**  
   - 3D sky: slow orbit, zodiac band (13 sectors labeled), ecliptic, optional equal-house pie when “horizon” is on.  
   - HUD chips: `Sharatan · 13-sign · Equal · True Node · Topocentric · Modern`.  
   - Tap a chip → short plain-language explainer (no birth data).

2. **Body tour**  
   - Fly-to planet (from solar-system camera pattern).  
   - Card: modern name, symbol, one-line meaning in AstroSleep tone.  
   - Optional link into **sounds** filtered by that body’s archetype (tag engine), still not personal chart.

3. **Tonight overlay (optional v1.1)**  
   - Using **device time + coarse location permission** only: show current sky-ish orientation / moon phase vector already used by nightly score — still **not** full natal redraw.  
   - Explicit toggle: “Use location for sky orientation”.

4. **Personal placements (explicit opt-in, later)**  
   - Only if user has completed onboarding.  
   - Render **on-device** computed positions as markers on the same systems frame.  
   - Never upload chart; never default this mode on first open.

### Interactions

- Drag orbit, pinch zoom, tap planet → focus (GSAP-like ease, 300–500ms).  
- Hover/press on web: DESIGN.md ripple / lift.  
- Loading: single Whimsy-style calm loader recolored to sea tokens.

## Data / engine wiring

- Reuse `AstrologicalEngine` / sidereal constants already in iOS/Android (Sharatan, 13-sign).  
- Single shared constants module if not already: ayanamsha degrees, sign list including Ophiuchus.  
- Aspect lines: optional wireframe (like chart’s aspect web) in muted biolume — decorative in systems mode; real aspects only in personal mode.

## Privacy

- Default systems mode: **zero birth data**.  
- Personal mode: on-device only; screenshot share must strip identity fields.  
- The reference chart JPEG must **not** ship inside the app binary.

## Acceptance criteria

- [ ] Tab present on iOS and Android nav  
- [ ] Systems chips match table above  
- [ ] 13-sign band visible and labeled  
- [ ] Sharatan / Equal / True Node / Topocentric / Modern explained in UI  
- [ ] Offline-capable 3D scene (no Gemini key)  
- [ ] Sea branding (no pure black-only marketing demo look without tokens)  
- [ ] No hard-coded personal natal from the JPEG  
- [ ] Performance: 30fps mid-tier devices; degrade to 2D zodiac wheel if GPU fails  

## Implementation order

1. Spec + constants parity (this doc + engine)  
2. Shared WebView three.js port of solar-system (offline)  
3. Systems HUD chips + copy  
4. Body tour + tag-engine deep link  
5. Optional tonight / personal markers  

## References

- Chart systems sheet: `E:\Workstation\ASSETs\Image Assets\Personal\dd astro chart sidereal.jpeg`  
- 3D baseline: https://github.com/thebuggeddev/solar-system  
- Spec 4.0, DESIGN.md, TAG_ENGINE guides  
