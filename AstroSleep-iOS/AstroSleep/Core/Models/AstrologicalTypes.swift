import Foundation
import SwiftUI

// MARK: - Elements

enum Element: String, CaseIterable, Codable, Identifiable {
    case fire = "Fire"
    case earth = "Earth"
    case air = "Air"
    case water = "Water"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var index: Int {
        switch self {
        case .fire: return 0
        case .earth: return 1
        case .air: return 2
        case .water: return 3
        }
    }
    
    /// The canonical UI color for this element across the app.
    var color: Color {
        switch self {
        case .fire: return .orange
        case .earth: return .brown
        case .air: return .yellow
        case .water: return .blue
        }
    }
    
    /// The canonical SF Symbol icon name for this element.
    var icon: String {
        switch self {
        case .fire: return "flame.fill"
        case .earth: return "mountain.fill"
        case .air: return "wind"
        case .water: return "drop.fill"
        }
    }
}

// MARK: - Modalities

enum Modality: String, CaseIterable, Codable {
    case cardinal = "Cardinal"
    case fixed = "Fixed"
    case mutable = "Mutable"
}

// MARK: - Signs (13-sign Sidereal Zodiac)

enum Sign: String, CaseIterable, Codable, Identifiable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case ophiuchus = "Ophiuchus"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .ophiuchus, .pisces: return .water
        }
    }
    
    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn: return .cardinal
        case .taurus, .leo, .scorpio, .ophiuchus, .aquarius: return .fixed
        case .gemini, .virgo, .sagittarius, .pisces: return .mutable
        }
    }
    
    var index: Int {
        Sign.allCases.firstIndex(of: self) ?? 0
    }
    
    /// Sidereal ingress dates (approximate, exact dates computed via ephemeris)
    var siderealDateRange: (start: (month: Int, day: Int), end: (month: Int, day: Int)) {
        switch self {
        case .aries: return ((4, 19), (5, 13))
        case .taurus: return ((5, 14), (6, 19))
        case .gemini: return ((6, 20), (7, 20))
        case .cancer: return ((7, 21), (8, 9))
        case .leo: return ((8, 10), (9, 15))
        case .virgo: return ((9, 16), (10, 30))
        case .libra: return ((10, 31), (11, 22))
        case .scorpio: return ((11, 23), (11, 29))
        case .ophiuchus: return ((11, 30), (12, 17))
        case .sagittarius: return ((12, 18), (1, 18))
        case .capricorn: return ((1, 19), (2, 15))
        case .aquarius: return ((2, 16), (3, 11))
        case .pisces: return ((3, 12), (4, 18))
        }
    }
}

// MARK: - Planets

enum Planet: String, CaseIterable, Codable, Identifiable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
    case chiron = "Chiron"
    case lilith = "Lilith"
    case northNode = "North Node"
    case southNode = "South Node"
    
    var id: String { rawValue }
    
    /// Weight in BaseScore calculation
    var baseScoreWeight: Double {
        switch self {
        case .moon: return 4.0
        case .sun: return 2.0
        case .venus: return 1.5
        case .mercury, .mars: return 1.0
        case .jupiter: return 0.8
        case .neptune: return 0.8
        case .saturn: return 0.7
        case .pluto: return 0.6
        case .uranus: return 0.5
        case .chiron: return 0.5
        case .northNode: return 0.6
        case .lilith: return 0.4
        case .southNode: return 0.4
        }
    }
    
    /// Primary modern rulership (deterministic — never random).
    var rulingSign: Sign? {
        switch self {
        case .sun: return .leo
        case .moon: return .cancer
        case .mercury: return .gemini
        case .venus: return .taurus
        case .mars: return .aries
        case .jupiter: return .sagittarius
        case .saturn: return .capricorn
        case .uranus: return .aquarius
        case .neptune: return .pisces
        case .pluto: return .scorpio
        case .chiron: return .ophiuchus
        default: return nil
        }
    }
}

// MARK: - Aspects

enum Aspect: String, CaseIterable, Codable {
    case conjunction = "Conjunction"
    case sextile = "Sextile"
    case square = "Square"
    case trine = "Trine"
    case opposition = "Opposition"
    
    var angle: Double {
        switch self {
        case .conjunction: return 0.0
        case .sextile: return 60.0
        case .square: return 90.0
        case .trine: return 120.0
        case .opposition: return 180.0
        }
    }
    
    var orb: Double {
        switch self {
        case .conjunction: return 8.0
        case .sextile: return 6.0
        case .square: return 8.0
        case .trine: return 8.0
        case .opposition: return 8.0
        }
    }
}

// MARK: - Moon Phases

enum MoonPhase: String, CaseIterable, Codable, Identifiable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var sfSymbolName: String {
        switch self {
        case .newMoon: return "moon.fill"
        case .waxingCrescent: return "moonphase.waxing.crescent"
        case .firstQuarter: return "moonphase.first.quarter"
        case .waxingGibbous: return "moonphase.waxing.gibbous"
        case .fullMoon: return "moon.circle.fill"
        case .waningGibbous: return "moonphase.waning.gibbous"
        case .lastQuarter: return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }
}

// MARK: - Houses

enum House: Int, CaseIterable, Codable {
    case first = 1, second = 2, third = 3, fourth = 4
    case fifth = 5, sixth = 6, seventh = 7, eighth = 8
    case ninth = 9, tenth = 10, eleventh = 11, twelfth = 12
}

// MARK: - Subscription Tiers

enum SubscriptionTier: String, CaseIterable, Codable, Comparable {
    case free = "free"
    case subscription = "subscription"
    case lifetime = "lifetime"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .subscription: return "Subscription"
        case .lifetime: return "Pro (Lifetime)"
        }
    }
    
    var maxLayers: Int {
        switch self {
        case .free: return 2
        case .subscription: return 7
        case .lifetime: return 7
        }
    }
    
    var maxPlaylists: Int {
        switch self {
        case .free: return 5
        case .subscription: return Int.max
        case .lifetime: return Int.max
        }
    }
    
    var sessionHistoryDays: Int {
        switch self {
        case .free: return 14
        case .subscription: return Int.max
        case .lifetime: return Int.max
        }
    }
    
    var hasOscillation: Bool { true }
    
    var hasTransitScoring: Bool { true }
    
    var hasAINarrative: Bool { true }
    
    var hasCustomVoice: Bool {
        self == .subscription || self == .lifetime
    }
    
    var hasBackup: Bool {
        self == .subscription || self == .lifetime
    }
    
    var hasPerLayerSpeed: Bool { true }
    
    var hasCustomTheming: Bool { true }
    
    /// Both paid tiers receive all future features and updates regardless of when they ship.
    var includesFutureFeatures: Bool {
        self == .subscription || self == .lifetime
    }
    
    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let order: [SubscriptionTier] = [.free, .subscription, .lifetime]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Transit

struct Transit: Codable, Identifiable {
    var id = UUID()
    let planet: Planet
    let natalPlanet: Planet
    let aspectType: Aspect
    let orb: Double
    let isApplying: Bool
    var angularBoost: Double = 1.0
    
    var strength: Double {
        let baseStrength: Double
        switch planet {
        case .moon: baseStrength = 3.0
        case .venus: baseStrength = 2.0
        case .mars: baseStrength = 2.5
        case .jupiter: baseStrength = 1.5
        case .saturn: baseStrength = 2.0
        case .uranus: baseStrength = 1.0
        case .neptune: baseStrength = 2.0
        case .pluto: baseStrength = 2.5
        case .chiron: baseStrength = 1.5
        case .lilith: baseStrength = 1.0
        case .northNode: baseStrength = 1.0
        case .southNode: baseStrength = 0.5
        default: baseStrength = 1.0
        }
        
        let orbFactor = max(0, 1.0 - (orb / aspectType.orb))
        return baseStrength * orbFactor * angularBoost
    }
}

// MARK: - Chart Placement

struct ChartPlacement: Codable {
    let planet: Planet
    let sign: Sign
    let house: House?
    let degree: Double
    let isRetrograde: Bool
}

// MARK: - Natal Chart

struct NatalChart: Codable {
    let computedAt: Date
    let placements: [ChartPlacement]
    let ascendant: Sign?
    let mc: Sign?
    let dominantElement: Element
    let dominantModality: Modality
    let aspects: [AspectarianEntry]
    let stelliums: [Sign]
    let hasBirthTime: Bool
    
    func placement(for planet: Planet) -> ChartPlacement? {
        placements.first { $0.planet == planet }
    }
    
    var sunSign: Sign? {
        placement(for: .sun)?.sign
    }
    
    var moonSign: Sign? {
        placement(for: .moon)?.sign
    }
    
    var mercurySign: Sign? {
        placement(for: .mercury)?.sign
    }
    
    var venusSign: Sign? {
        placement(for: .venus)?.sign
    }
    
    var marsSign: Sign? {
        placement(for: .mars)?.sign
    }
    
    var jupiterSign: Sign? {
        placement(for: .jupiter)?.sign
    }
    
    var saturnSign: Sign? {
        placement(for: .saturn)?.sign
    }
    
    var uranusSign: Sign? {
        placement(for: .uranus)?.sign
    }
    
    var neptuneSign: Sign? {
        placement(for: .neptune)?.sign
    }
    
    var plutoSign: Sign? {
        placement(for: .pluto)?.sign
    }
    
    var chironSign: Sign? {
        placement(for: .chiron)?.sign
    }
    
    var lilithSign: Sign? {
        placement(for: .lilith)?.sign
    }
    
    var northNode: ChartPlacement? {
        placement(for: .northNode)
    }
    
    var southNode: ChartPlacement? {
        placement(for: .southNode)
    }
    
    var moonHouse: House? {
        placement(for: .moon)?.house
    }
    
    var sunHouse: House? {
        placement(for: .sun)?.house
    }
    
    func houseRuler(_ house: House) -> Planet {
        // Simplified: return planet ruling the house cusp sign
        // In equal house system, each house cusp = sign
        // Real implementation needs ephemeris computation
        let signIndex = (house.rawValue - 1) % 12
        let signs = Sign.allCases
        let houseSign = signs[signIndex]
        
        // Find planet that rules this sign
        for planet in Planet.allCases {
            if planet.rulingSign == houseSign {
                return planet
            }
        }
        return .sun // fallback
    }
}

// MARK: - Aspectarian Entry

struct AspectarianEntry: Codable, Identifiable {
    var id = UUID()
    let planet1: Planet
    let planet2: Planet
    let aspect: Aspect
    let orb: Double
}

// MARK: - Stellium

struct Stellium: Codable, Identifiable {
    var id = UUID()
    let sign: Sign
    let planets: [Planet]
    
    var count: Int { planets.count }
}

// MARK: - Nightly Score Result

struct NightlyScoreResult: Codable {
    let elementScore: ElementVector
    let moonPhase: MoonPhase
    let activeTransits: [Transit]
    let dominantElement: Element
    let topTransit: Transit?
    let stelliums: [Stellium]
    
    func toSnapshot() -> ChartSnapshot {
        ChartSnapshot(
            moonPhase: moonPhase,
            dominantElement: dominantElement,
            topTransit: topTransit?.planet.rawValue ?? "None",
            aspectarian: [],
            stelliums: stelliums.map { $0.sign.rawValue },
            computedAt: Date()
        )
    }
}

// MARK: - Chart Snapshot (for combo storage)

struct ChartSnapshot: Codable {
    let moonPhase: MoonPhase
    let dominantElement: Element
    let topTransit: String
    let aspectarian: [AspectarianEntry]
    let stelliums: [String]
    let computedAt: Date
}

// MARK: - Voice Options

enum VoiceOption: String, CaseIterable, Codable {
    case female = "female"
    case male = "male"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .custom: return "My Voice"
        }
    }
}

// MARK: - Affirmation Tone (Pro)

enum AffirmationTone: String, CaseIterable, Codable {
    case neutral = "neutral"
    case warm = "warm"
    case commanding = "commanding"
    case whisper = "whisper"
}

// MARK: - Affirmation Length (Pro)

enum AffirmationLength: String, CaseIterable, Codable {
    case short = "short"
    case standard = "standard"
    case extended = "extended"
}

// MARK: - Affirmation Ending (Pro)

enum AffirmationEnding: String, CaseIterable, Codable {
    case grounding = "grounding"
    case sleepInduction = "sleep_induction"
    case gratitude = "gratitude"
}

// MARK: - Combo Source

enum ComboSource: String, Codable {
    case auto = "auto"
    case user = "user"
}

// MARK: - Layer Type

enum LayerType: String, Codable {
    case ambient = "ambient"
    case affirmation = "affirmation"
}

// MARK: - Waveform

enum Waveform: String, CaseIterable, Codable {
    case sine = "sine"
    case perlin = "perlin"
    case step = "step"
    case triangle = "triangle"
}
