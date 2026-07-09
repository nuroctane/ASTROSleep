# Xcode: ship Cosmic Systems WebView assets

No `.xcodeproj` is committed in this monorepo layout (sources only). When you open/create the Xcode project:

## One-time

1. In Xcode Project Navigator, right-click `AstroSleep` group → **Add Files to "AstroSleep"…**
2. Select folder: `AstroSleep-iOS/AstroSleep/Resources/cosmic-systems`
3. Options:
   - **Create folder references** (blue folder) *or* groups — either works if files land in the app bundle
   - ☑ **Copy items if needed** — off if already in tree
   - ☑ Target **AstroSleep** membership
4. Build Phases → **Copy Bundle Resources** must list:
   - `cosmic-systems/index.html`
   - `cosmic-systems/vendor/three.min.js`  
   (or the whole `cosmic-systems` folder reference)

## Verify

After install on simulator:

```text
Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "cosmic-systems")
```

must be non-nil. Cosmos tab should show the 3D scene, not the red “bundle missing” HTML.

## Sync after HTML edits

```powershell
$src = "shared\cosmic-systems"
Copy-Item "$src\*" "AstroSleep-iOS\AstroSleep\Resources\cosmic-systems" -Recurse -Force
Copy-Item "$src\*" "AstroSleep-Android\app\src\main\assets\cosmic-systems" -Recurse -Force
```
