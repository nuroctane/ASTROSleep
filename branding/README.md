# AstroSleep branding

**Mark:** Constellation Field — linked star nodes forming a soft crescent silhouette on Digital Sea void navy. No solid moon mass. Biolume (`#5AC8FA`) on a few nodes; lines in indigo family (`#5856D6`).

**Design system:** [`.agents/DESIGN.md`](../.agents/DESIGN.md) (Digital Sea tokens, glass, motion). Keep optical association with the wider family (quiet night, not neon SaaS).

| File | Size | Use |
|------|------|-----|
| `astrosleep-logo.png` | 1024×1024 | Master |
| `astrosleep-logo-512.png` | 512×512 | Medium / store |
| `astrosleep-logo-256.png` | 256×256 | Small |
| `astrosleep-logo-128.png` | 128×128 | Tiny |
| `astrosleep-constellation.png (README) / astrosleep-logo-readme.png` | 512×512 | GitHub README hero |

**App wiring**

| Surface | Path |
|---------|------|
| Android launcher | `AstroSleep-Android/app/src/main/res/mipmap-*/ic_launcher*.png` |
| Android adaptive FG | `.../drawable/ic_launcher_foreground.png` |
| Android in-app | `@drawable/logo_astrosleep` |
| iOS App Icon | `AstroSleep-iOS/.../AppIcon.appiconset/` |
| iOS in-app | `Image("Logo")` → `Logo.imageset` |

When regenerating, keep **filenames stable** so README and native assets do not break.
