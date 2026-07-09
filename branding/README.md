# AstroSleep branding

Temporary intuitive mark: **crescent moon + night sky** (indigo on deep navy).  
Safe to replace later — keep filenames stable where apps reference them.

**Family design system:** see repo root [`DESIGN.md`](../DESIGN.md) (Digital Sea tokens, accent `#5856D6`, glass recipes, Emil/Apple motion). Obsidian `Building & Projects/DESIGN.md` may mirror the same tokens. New UI should follow the repo SoT so AstroSleep and Digital Sea Blackjack share optical identity.

| File | Use |
|------|-----|
| `astrosleep-logo.png` | Master 1024×1024 |
| `astrosleep-logo-512.png` | Medium |
| `astrosleep-logo-256.png` | Small / favicon-ish |
| `astrosleep-logo-128.png` | Tiny |
| `astrosleep-logo-readme.png` | GitHub README |

**App wiring**

- Android launcher: `AstroSleep-Android/app/src/main/res/mipmap-*/ic_launcher*.png`
- Android adaptive FG: `.../drawable/ic_launcher_foreground.png`
- Android in-app: `@drawable/logo_astrosleep`
- iOS App Icon: `AstroSleep-iOS/.../AppIcon.appiconset/`
- iOS in-app: `Image("Logo")` → `Logo.imageset`
