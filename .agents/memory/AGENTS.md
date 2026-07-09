# Agent notes — AstroSleep

## Source of truth

1. Product features: Obsidian `Building & Projects/AstroSleep/AstroSleep Spec 4.0.md` (only keep 4.0; older specs removed)
2. Visual identity: Obsidian `Building & Projects/DESIGN.md` (Digital Sea + motion recipes)
3. Competition / pipeline: Obsidian `Building & Projects/AstroSleep/Competition Eval Matrix.md`
4. iOS glass: `documentation/IOS_LIQUID_GLASS.md`
5. Brand assets: `branding/README.md`

## Project agent layout (parity across Laboratory)

```
.agents/
  memory/     ← this file + long-lived agent memory notes
  skills/     ← project-local skills (optional)
```

## Hard rules

- Do **not** invent features absent from Spec 4.0.
- Do **not** put API keys in app binaries — affirmation proxy first.
- Do **not** trust local tier strings — RevenueCat at runtime.
- Keep iOS and Android UI implementations separate; share engine logic only.
- UI chrome uses Digital Sea tokens (void/field/accent `#5856D6`); elemental colors only on chart/tag UI.
- Motion: quiet 150–400ms; glass hover/actuation from DESIGN.md motion section — no neon casino bounce.

## Default theme accent

`#5856D6` (Spec 4.0 preview / DESIGN.md `--sea-accent`).

## Motion / 3D baselines (see DESIGN.md § Motion)

- liquidglass-oss (WebGL glass) for marketing heroes  
- Whimsy Loaders (one calm loader, sea recolor)  
- lucide-animated (micro icon motion)  
- Water-ripple style actuation on primary Play CTA only  

## Cosmic Systems 3D tab (iOS + Android)

Full spec: `documentation/COSMIC_SYSTEMS_3D_TAB.md`

- Interactive 3D **systems** experience (not default personal natal dump).  
- Systems from sidereal chart standard: **13-sign**, **Sharatan (Beta Aries 02°15′)**, **topocentric**, **equal houses**, **true nodes**, **modern** bodies.  
- Scene baseline: https://github.com/thebuggeddev/solar-system (Three.js + camera tour) — offline, no Gemini.  
- Personal placements only as **explicit opt-in** later; never ship the personal JPEG chart data.
