# UI deep dive — best repos from bookmarks → AstroSleep / Blackjack

## Top tier (use as agent SoT)

| Repo / resource | Why it wins | Apply to |
|-----------------|-------------|----------|
| **[emilkowalski/skills](https://github.com/emilkowalski/skills)** especially `apple-design` | WWDC fluid interfaces: interruptible motion, materials, typography, restraint | Both; installed under `.agents/skills/` |
| `emil-design-eng` + `review-animations` | Taste rules: ease-out, scale(0.97), no scale(0), &lt;300ms UI | Web blackjack + any CSS |
| **Apple Adopting Liquid Glass** (WWDC / docs) | Native iOS 26 glass, no opaque chrome | AstroSleep iOS (already wired) |
| **liquidglass-oss** | Real WebGL glass for web heroes | Marketing / blackjack glass |
| **lucide-animated** | Micro icon motion without noise | Settings / chrome icons |
| **VoltAgent/awesome-design-md** | Drop-in DESIGN.md systems | Keep `.agents/DESIGN.md` as repo SoT (Obsidian family mirror OK) |
| **Refero Styles** | Design systems for agents | Token validation |
| **Design Spells** (bookmark) | Micro-details that feel magical | Odds panel, chips |

## Apple WWDC principles we encode

From `apple-design` skill (Designing Fluid Interfaces + materials + WWDC craft):

1. Response on press-down, not release  
2. 1:1 drag / continuous feedback  
3. Interruptible motion  
4. Springs over fixed scripts for gestures  
5. Translucent materials for hierarchy  
6. Spatial consistency (enter/exit same path)  
7. Reduced motion / reduced transparency  
8. System font + optical tracking  

AstroSleep native already targets **Liquid Glass on iOS 26+** (`LiquidGlassSupport.swift`, `UIDesignRequiresCompatibility=false`).

## Android parity principles

- Material 3 expressive dark theme with Digital Sea tokens  
- Edge-to-edge, translucent nav (no opaque slabs)  
- Press scale 0.97 via indication  
- Large dynamic type friendly spacing  
- Prefer system components over custom chrome  

## Agent install

```bash
# already copied into:
# Laboratory/ASTROSleep/.agents/skills/{apple-design,emil-design-eng,animation-vocabulary,review-animations}
# Laboratory/blackjack/.agents/skills/...
```
