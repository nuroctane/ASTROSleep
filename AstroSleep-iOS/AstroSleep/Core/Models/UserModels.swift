import Foundation
import CoreLocation
import SwiftUI

// MARK: - User Profile

struct UserProfile: Codable, Identifiable {
    let id: String
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthLat: Double
    var birthLng: Double
    var birthCity: String
    var currentLat: Double
    var currentLng: Double
    var currentCity: String
    var useCurrentLocationForTransits: Bool
    var baseScore: ElementVector
    var natalChart: NatalChart?
    var cachedTierDisplayOnly: SubscriptionTier
    var selectedVoiceId: String
    var globalAffirmationSpeed: Double
    var globalAffirmationPitch: Double // semitones, -6 to +6
    var sleepTimerDefault: Int // minutes
    var notificationEnabled: Bool
    var bedtimeReminderTime: Date?
    var themeConfig: ThemeConfig
    var hasCompletedOnboarding: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String = "",
        birthDate: Date = Date(),
        birthTime: Date? = nil,
        birthLat: Double = 0,
        birthLng: Double = 0,
        birthCity: String = "",
        currentLat: Double = 0,
        currentLng: Double = 0,
        currentCity: String = "",
        useCurrentLocationForTransits: Bool = false,
        baseScore: ElementVector = .zero,
        natalChart: NatalChart? = nil,
        cachedTierDisplayOnly: SubscriptionTier = .free,
        selectedVoiceId: String = "com.apple.ttsbundle.SiriFemale_en-US",
        globalAffirmationSpeed: Double = 1.0,
        globalAffirmationPitch: Double = 0.0,
        sleepTimerDefault: Int = 60,
        notificationEnabled: Bool = false,
        bedtimeReminderTime: Date? = nil,
        themeConfig: ThemeConfig = .default,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthLat = birthLat
        self.birthLng = birthLng
        self.birthCity = birthCity
        self.currentLat = currentLat
        self.currentLng = currentLng
        self.currentCity = currentCity
        self.useCurrentLocationForTransits = useCurrentLocationForTransits
        self.baseScore = baseScore
        self.natalChart = natalChart
        self.cachedTierDisplayOnly = cachedTierDisplayOnly
        self.selectedVoiceId = selectedVoiceId
        self.globalAffirmationSpeed = globalAffirmationSpeed
        self.globalAffirmationPitch = globalAffirmationPitch
        self.sleepTimerDefault = sleepTimerDefault
        self.notificationEnabled = notificationEnabled
        self.bedtimeReminderTime = bedtimeReminderTime
        self.themeConfig = themeConfig
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

// MARK: - Theme Config

struct ThemeConfig: Codable, Equatable {
    var accentColorHex: String = "5856D6"
    var backgroundColorHex: String?
    var backgroundImagePath: String?
    var useSystemAppearance: Bool = true
    
    var accentColor: Color {
        Color(hex: accentColorHex) ?? .indigo
    }
    
    var backgroundColor: Color? {
        guard let hex = backgroundColorHex else { return nil }
        return Color(hex: hex)
    }
    
    static let `default` = ThemeConfig()
}

// MARK: - Combo Models

struct AmbientLayer: Codable, Identifiable, Equatable {
    var id = UUID()
    var soundId: String
    var layerType: LayerType = .ambient
    var volume: Double
    var playbackSpeed: Double
    var eq: EQProfile
    var oscillation: OscillationConfig?
    
    static func == (lhs: AmbientLayer, rhs: AmbientLayer) -> Bool {
        lhs.id == rhs.id
    }
}

struct EQProfile: Codable, Equatable {
    var bass: Double
    var mid: Double
    var treble: Double
    
    static let `default` = EQProfile(bass: 0.5, mid: 0.5, treble: 0.5)
    static let deep = EQProfile(bass: 0.85, mid: 0.50, treble: 0.20)
    static let mid = EQProfile(bass: 0.55, mid: 0.80, treble: 0.45)
    static let bright = EQProfile(bass: 0.30, mid: 0.60, treble: 0.85)
    static let full = EQProfile(bass: 0.65, mid: 0.70, treble: 0.55)
    static let sub = EQProfile(bass: 0.95, mid: 0.40, treble: 0.15)
    static let ultrasonic = EQProfile(bass: 0.20, mid: 0.45, treble: 0.95)
    
    static func profile(forRegister register: String) -> EQProfile {
        switch register {
        case "sub": return .sub
        case "deep": return .deep
        case "mid": return .mid
        case "bright": return .bright
        case "full": return .full
        case "ultrasonic": return .ultrasonic
        default: return .default
        }
    }
}

struct OscillationConfig: Codable, Equatable {
    var enabled: Bool
    var waveform: Waveform
    var periodSeconds: Double
    var minVolume: Double
    var maxVolume: Double
    var phaseOffset: Double
    
    static let disabled = OscillationConfig(
        enabled: false, waveform: .sine, periodSeconds: 45.0,
        minVolume: 0.5, maxVolume: 0.85, phaseOffset: 0.0
    )
}

struct AffirmationLayer: Codable, Identifiable, Equatable {
    var id = UUID()
    var layerType: LayerType = .affirmation
    var voiceId: String
    var volume: Double
    var playbackSpeed: Double
    var pitchSemitones: Double // -6 to +6
    var customVoicePath: String?
    
    static func `default`(voiceId: String = "com.apple.ttsbundle.SiriFemale_en-US") -> AffirmationLayer {
        AffirmationLayer(voiceId: voiceId, volume: 0.10, playbackSpeed: 1.0, pitchSemitones: 0.0, customVoicePath: nil)
    }
}

struct Combo: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    let createdAt: Date
    var lastPlayedAt: Date?
    var source: ComboSource
    var chartSnapshot: ChartSnapshot?
    var layers: [AmbientLayer]
    var affirmationLayer: AffirmationLayer
    var isReadOnly: Bool
    
    var layerCount: Int { layers.count }
    
    var dominantElements: [Element] {
        let counts = layers.reduce(into: [:]) { counts, layer in
            if let sound = SoundLibrary.shared.sounds.first(where: { $0.id == layer.soundId }) {
                let dominant = sound.elementScores.dominant()
                counts[dominant, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    static func == (lhs: Combo, rhs: Combo) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Session Log

struct SessionLog: Codable, Identifiable {
    let id: String
    let date: Date
    let intention: String
    let affirmationScript: String
    let customVoicePath: String?
    let comboId: String?
    let durationMinutes: Int
    let timerFired: Bool
    let tier: SubscriptionTier
    let moonPhase: MoonPhase
    let layerCount: Int
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        intention: String = "",
        affirmationScript: String = "",
        customVoicePath: String? = nil,
        comboId: String? = nil,
        durationMinutes: Int = 0,
        timerFired: Bool = false,
        tier: SubscriptionTier = .free,
        moonPhase: MoonPhase = .newMoon,
        layerCount: Int = 0
    ) {
        self.id = id
        self.date = date
        self.intention = intention
        self.affirmationScript = affirmationScript
        self.customVoicePath = customVoicePath
        self.comboId = comboId
        self.durationMinutes = durationMinutes
        self.timerFired = timerFired
        self.tier = tier
        self.moonPhase = moonPhase
        self.layerCount = layerCount
    }
}

// MARK: - Affirmation Cache

struct AffirmationCache: Codable, Identifiable {
    let id: String // calendarDate "YYYY-MM-DD"
    let script: String
    let generatedAt: Date
    let intention: String
}

// MARK: - App State

enum AppScreen: Hashable {
    case onboarding
    case main
    case playback(Combo)
    case comboBuilder(Combo?)
    case paywall(trigger: String)
}

enum TabSelection: String, CaseIterable {
    case tonight = "Tonight"
    case cosmos = "Cosmos"
    case sounds = "Sounds"
    case library = "Library"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .tonight: return "moon.fill"
        case .cosmos: return "sparkles"
        case .sounds: return "waveform"
        case .library: return "rectangle.stack.fill"
        case .settings: return "gear"
        }
    }
}

// MARK: - Audio State

enum AudioState {
    case idle
    case loading
    case playing
    case paused
    case interrupted
    case fading
    case stopped
}

// MARK: - Geocoding Result

struct GeocodingResult: Codable {
    let city: String
    let lat: Double
    let lng: Double
    let timezone: String
}

// MARK: - Color Hex Helpers

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init?(hex: String) {
        guard let color = Color(hex: hex) else { return nil }
        self.init(color)
    }
}
