import Foundation

// MARK: - App Configuration
/// Centralized configuration that reads from Info.plist build settings.
/// Prevents hardcoding secrets in source files. Values must be injected
/// via xcconfig or Xcode User-Defined Build Settings.
enum AppConfig {
    private static let infoDictionary = Bundle.main.infoDictionary ?? [:]
    
    static var supabaseURL: URL {
        let raw = (infoDictionary["SUPABASE_URL"] as? String)
            ?? ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? "https://localhost"
        return URL(string: raw) ?? URL(fileURLWithPath: "/")
    }
    
    static var supabaseAnonKey: String {
        (infoDictionary["SUPABASE_ANON_KEY"] as? String)
            ?? ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? ""
    }
    
    static var revenueCatAPIKey: String {
        (infoDictionary["REVENUECAT_API_KEY"] as? String)
            ?? ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]
            ?? ""
    }
    
    static var proxyBaseURL: URL {
        let raw = (infoDictionary["PROXY_BASE_URL"] as? String)
            ?? ProcessInfo.processInfo.environment["PROXY_BASE_URL"]
            ?? "https://api.astrosleep.app/api"
        return URL(string: raw) ?? URL(string: "https://localhost")!
    }
    
    static var soundManifestURL: URL {
        let raw = (infoDictionary["SOUND_MANIFEST_URL"] as? String)
            ?? ProcessInfo.processInfo.environment["SOUND_MANIFEST_URL"]
            ?? "https://cdn.astrosleep.app/sounds_manifest.json"
        return URL(string: raw) ?? URL(string: "https://localhost")!
    }
}
