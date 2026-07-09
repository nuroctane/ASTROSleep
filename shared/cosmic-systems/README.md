# Cosmic Systems (shared WebView bundle)

Offline Three.js systems sky for **iOS + Android** Cosmic Systems tabs.

## Copy targets

| Platform | Path |
|----------|------|
| Source of truth | `shared/cosmic-systems/` |
| iOS | `AstroSleep-iOS/AstroSleep/Resources/cosmic-systems/` (**add to Xcode target → Copy Bundle Resources**) |
| Android | `AstroSleep-Android/app/src/main/assets/cosmic-systems/` |

## After editing `index.html`

Re-copy:

```powershell
$src = "shared\cosmic-systems"
Copy-Item "$src\*" "AstroSleep-iOS\AstroSleep\Resources\cosmic-systems" -Recurse -Force
Copy-Item "$src\*" "AstroSleep-Android\app\src\main\assets\cosmic-systems" -Recurse -Force
```

## Spec

`documentation/COSMIC_SYSTEMS_3D_TAB.md`
