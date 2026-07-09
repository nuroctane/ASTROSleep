import Foundation
import SwiftUI
import Combine

// MARK: - Theme Service
/// Manages app-wide visual theming. Free for all tiers: accent color, background color, background image.
@MainActor
final class ThemeService: ObservableObject {
    static let shared = ThemeService()
    
    @Published var accentColor: Color = .indigo
    @Published var backgroundColor: Color = Color(.systemBackground)
    @Published var backgroundImage: UIImage?
    @Published var useSystemAppearance: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let themeKey = "theme_config"
    
    private init() {
        loadTheme()
    }
    
    // MARK: - Persistence
    
    func loadTheme() {
        guard let data = userDefaults.data(forKey: themeKey),
              let config = try? JSONDecoder().decode(ThemeConfig.self, from: data) else {
            apply(theme: ThemeConfig.default)
            return
        }
        apply(theme: config)
    }
    
    func saveTheme(_ config: ThemeConfig) {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: themeKey)
        }
        apply(theme: config)
    }
    
    func resetToDefault() {
        let defaultConfig = ThemeConfig.default
        userDefaults.removeObject(forKey: themeKey)
        apply(theme: defaultConfig)
        updateProfileTheme(defaultConfig)
    }
    
    // MARK: - Apply Theme
    
    private func apply(theme: ThemeConfig) {
        accentColor = theme.accentColor
        backgroundColor = theme.backgroundColor ?? Color(.systemBackground)
        useSystemAppearance = theme.useSystemAppearance
        
        if let path = theme.backgroundImagePath,
           let image = loadImage(from: path) {
            backgroundImage = image
        } else {
            backgroundImage = nil
        }
        
        // Tint only — do not force opaque bar backgrounds (fights Liquid Glass on iOS 26+).
        let uiColor = UIColor(theme.accentColor)
        UINavigationBar.appearance().tintColor = uiColor
        UITabBar.appearance().tintColor = uiColor
        UISwitch.appearance().onTintColor = uiColor
        UISlider.appearance().tintColor = uiColor
        UIRefreshControl.appearance().tintColor = uiColor
        
        if #available(iOS 26.0, *) {
            // Keep bars translucent so system Liquid Glass can composite over content.
            UINavigationBar.appearance().isTranslucent = true
            UITabBar.appearance().isTranslucent = true
        }
    }
    
    // MARK: - Image Handling
    
    func saveBackgroundImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85),
              let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let filename = "bg_\(UUID().uuidString).jpg"
        let dir = docs.appendingPathComponent("themes", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let fileURL = dir.appendingPathComponent(filename)
            try data.write(to: fileURL)
            return filename
        } catch {
            print("Failed to save background image: \(error)")
            return nil
        }
    }
    
    func loadImage(from filename: String) -> UIImage? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = docs.appendingPathComponent("themes", isDirectory: true)
        let fileURL = dir.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func deleteBackgroundImage(_ filename: String) {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let dir = docs.appendingPathComponent("themes", isDirectory: true)
        let fileURL = dir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Profile Sync
    
    func updateProfileTheme(_ config: ThemeConfig) {
        try? StorageService.shared.updateProfile { profile in
            profile.themeConfig = config
        }
    }
    
    // MARK: - Convenience
    
    var currentConfig: ThemeConfig {
        ThemeConfig(
            accentColorHex: accentColor.toHex() ?? "5856D6",
            backgroundColorHex: backgroundColor.toHex(),
            backgroundImagePath: backgroundImage != nil ? userDefaults.string(forKey: "bg_image_path") : nil,
            useSystemAppearance: useSystemAppearance
        )
    }
}

// MARK: - Color Hex Export

extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb = (Int(r * 255) << 16) | (Int(g * 255) << 8) | Int(b * 255)
        return String(format: "%06X", rgb)
    }
}
