import SwiftUI

// MARK: - Liquid Glass Compatibility (iOS 26+)
/// AstroSleep adopts Apple’s Liquid Glass design when built with the iOS 26 SDK and
/// running on iOS 26+. Earlier OS versions get material / secondary-background fallbacks.
///
/// ## Requirements (Apple “Adopting Liquid Glass”)
/// 1. **Do not** set `UIDesignRequiresCompatibility = YES` (we set it `false` in Info.plist).
/// 2. Avoid opaque custom backgrounds on tab bars, toolbars, and navigation bars.
/// 3. Prefer system TabView / NavigationStack chrome so the glass layer can float.
/// 4. Use materials / glass surfaces for floating cards instead of solid fills over scroll content.
///
/// Temporary opt-out (not used): `UIDesignRequiresCompatibility = YES` — expires with iOS 27.

// MARK: Glass / material surfaces

extension View {
    /// Floating surface: Liquid Glass on iOS 26+, ultra-thin material otherwise.
    @ViewBuilder
    func astroGlassCard(cornerRadius: CGFloat = 16) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.background {
                shape
                    .fill(.clear)
                    .glassEffect(Glass.regular, in: shape)
            }
            .clipShape(shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// Interactive chip / badge glass (iOS 26+) or thin material fallback.
    @ViewBuilder
    func astroGlassChip(cornerRadius: CGFloat = 8) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.background {
                shape
                    .fill(.clear)
                    .glassEffect(Glass.regular.interactive(), in: shape)
            }
            .clipShape(shape)
        } else {
            self.background(.thinMaterial, in: shape)
        }
    }

    /// Content card over scrollable night-sky UI: glass on 26+, secondary fill earlier.
    @ViewBuilder
    func astroContentCard(cornerRadius: CGFloat = 16) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.background {
                shape
                    .fill(.clear)
                    .glassEffect(Glass.regular, in: shape)
            }
            .clipShape(shape)
        } else {
            self.background(Color(.secondarySystemBackground), in: shape)
        }
    }

    /// Extra bottom margin so scroll content clears the floating Liquid Glass tab bar.
    @ViewBuilder
    func astroScrollEdgeAware() -> some View {
        if #available(iOS 26.0, *) {
            self.contentMargins(.bottom, 16, for: .scrollContent)
        } else {
            self
        }
    }

    /// Lets navigation use system glass (no forced solid toolbar fill on iOS 26+).
    @ViewBuilder
    func astroSystemGlassToolbar() -> some View {
        if #available(iOS 26.0, *) {
            self.toolbarBackground(.automatic, for: .navigationBar)
        } else {
            self
        }
    }
}

// MARK: Tab bar

extension View {
    /// Floating Liquid Glass tab bar minimizes while the user scrolls (iOS 26+).
    @ViewBuilder
    func astroTabBarLiquidGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}

// MARK: Design system flags

enum AstroDesignSystem {
    /// Running on an OS that provides Liquid Glass system chrome.
    static var usesLiquidGlass: Bool {
        if #available(iOS 26.0, *) { true } else { false }
    }
}

// MARK: - Press feedback (Apple / Emil craft)

/// Motion tokens — .agents/DESIGN.md / emilkowalski/skills
enum SeaMotion {
    static let pressDuration: Double = 0.14
    static let uiDuration: Double = 0.20
    static let enterDuration: Double = 0.22
    static let pressScale: CGFloat = 0.97
    static let enterScale: CGFloat = 0.95
    /// Strong ease-out (cubic-bezier 0.23, 1, 0.32, 1) approximated
    static var easeOut: Animation { .timingCurve(0.23, 1, 0.32, 1, duration: pressDuration) }
    static var easeOutUI: Animation { .timingCurve(0.23, 1, 0.32, 1, duration: uiDuration) }
}

struct SeaPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? SeaMotion.pressScale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : SeaMotion.easeOut, value: configuration.isPressed)
    }
}

/// Soft enter: never from scale(0) — starts at 0.95 + opacity 0.
struct SeaEnterModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .scaleEffect(shown || reduceMotion ? 1 : SeaMotion.enterScale)
            .onAppear {
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(SeaMotion.easeOutUI) { shown = true }
                }
            }
    }
}

extension View {
    func seaEnter() -> some View {
        modifier(SeaEnterModifier())
    }

    func seaPressable() -> some View {
        buttonStyle(SeaPressButtonStyle())
    }
}
