# AstroSleep iOS — Liquid Glass (iOS 26) Compatibility

AstroSleep is configured to **adopt** Apple’s Liquid Glass design on iOS 26+, not opt out.

## What we do

| Item | Status |
|------|--------|
| `UIDesignRequiresCompatibility` | **`false`** in `Info.plist` (system Liquid Glass enabled) |
| Opaque nav/tab bar chrome | Removed — default/translucent appearances |
| `TabView` | Native tabs + `.tabBarMinimizeBehavior(.onScrollDown)` on iOS 26 |
| Floating cards | `astroGlassCard` / `astroContentCard` → `glassEffect` on 26+, materials earlier |
| Toolbars | No solid `toolbarBackground(.visible)` overrides |
| ThemeService | Tints only; bars stay translucent on iOS 26 |

## Key files

- `Supporting Files/Info.plist` — design compatibility flag  
- `Views/Common/LiquidGlassSupport.swift` — glass helpers + fallbacks  
- `AstroSleepApp.swift` — UIAppearance for Liquid Glass  
- `Views/ContentView.swift` — tab bar minimize  
- `Views/Main/TonightView.swift`, `PlaybackView.swift`, library cards — glass surfaces  

## Building

1. **Xcode 26+** with **iOS 26 SDK** (App Store requirement for current uploads).  
2. Run on an **iOS 26 simulator or device** to see Liquid Glass chrome.  
3. On older OS versions, materials / secondary backgrounds are used automatically.

## Temporary opt-out (not recommended)

If you ever need the pre–Liquid Glass look while debugging:

```xml
<key>UIDesignRequiresCompatibility</key>
<true/>
```

Apple removes this escape hatch for apps linking against **iOS 27+**. Prefer fixing layout under glass instead of long-term opt-out.

## Design checklist when adding UI

- [ ] Don’t paint opaque backgrounds behind tab/nav bars  
- [ ] Prefer `astroContentCard` / `astroGlassCard` for floating panels  
- [ ] Use system `TabView` / `NavigationStack` / `toolbar`  
- [ ] Test scroll under the floating tab bar (minimize behavior)  
- [ ] Ensure text contrast on glass over light and dark content  

## References

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)  
- [WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)  
- [UIDesignRequiresCompatibility](https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility)
