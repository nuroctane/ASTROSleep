import Foundation

// MARK: - Tag affinity tables (parity with Android TagAffinityTables.kt)

/// Chart symbols → sonic tag affinities. Strengths are relative;
/// TagEngine normalizes contribution at score time.
enum TagAffinityTables {

    /// Pool for per-user signature tag injection (deterministic from fingerprint).
    static let signaturePool: [String] = [
        "water", "air", "fire", "earth", "mechanical", "organic", "electrical", "cosmic",
        "steady", "pulse", "irregular", "chaotic", "rhythmic", "arrhythmic",
        "sub", "deep", "mid", "bright", "full", "ultrasonic",
        "nature", "domestic", "abstract", "urban", "industrial", "spiritual",
        "ethereal", "light", "medium", "heavy", "massive",
        "smooth", "rough", "crystalline", "diffuse", "granular", "glassy", "metallic",
        "static", "flowing", "surging", "swirling", "oscillating", "drifting", "pulsing",
        "vacuum", "sparse", "moderate", "dense", "saturated",
        "cold", "cool", "neutral", "warm", "hot",
        "active", "receptive", "balanced",
        "solar", "lunar", "stellar", "planetary", "void",
        "maiden", "mother", "crone", "hero", "mentor", "shadow", "trickster"
    ]

    static func signTagPreferences(_ sign: Sign) -> [String: Double] {
        switch sign {
        case .aries:
            return ["fire": 1.4, "active": 1.3, "surging": 1.2, "hot": 1.1,
                    "hero": 1.2, "rough": 0.9, "pulse": 1.0, "solar": 0.8]
        case .taurus:
            return ["earth": 1.5, "steady": 1.4, "heavy": 1.2, "smooth": 1.1,
                    "mother": 1.0, "organic": 1.1, "static": 0.9, "warm": 0.8]
        case .gemini:
            return ["air": 1.4, "bright": 1.3, "crystalline": 1.2, "arrhythmic": 1.0,
                    "trickster": 1.2, "electrical": 1.0, "pulse": 0.9, "light": 0.9]
        case .cancer:
            return ["water": 1.6, "lunar": 1.5, "mother": 1.4, "flowing": 1.2,
                    "receptive": 1.3, "domestic": 1.0, "cool": 0.9, "dense": 0.8]
        case .leo:
            return ["fire": 1.4, "solar": 1.5, "hero": 1.3, "warm": 1.2,
                    "full": 1.0, "active": 1.1, "surging": 0.9, "nature": 0.7]
        case .virgo:
            return ["earth": 1.3, "granular": 1.3, "moderate": 1.1, "mentor": 1.2,
                    "steady": 1.1, "mechanical": 0.9, "mid": 1.0, "organic": 0.8]
        case .libra:
            return ["air": 1.3, "balanced": 1.5, "smooth": 1.3, "maiden": 1.1,
                    "bright": 1.0, "drifting": 1.0, "spiritual": 0.9]
        case .scorpio:
            return ["water": 1.4, "shadow": 1.6, "dense": 1.3, "deep": 1.4,
                    "heavy": 1.1, "receptive": 1.0, "void": 0.9, "rough": 0.8]
        case .ophiuchus:
            return ["water": 1.2, "cosmic": 1.4, "shadow": 1.3, "mentor": 1.2,
                    "spiritual": 1.3, "oscillating": 1.1, "planetary": 1.0, "crystalline": 0.9]
        case .sagittarius:
            return ["fire": 1.3, "cosmic": 1.2, "drifting": 1.2, "hero": 1.1,
                    "bright": 1.0, "nature": 1.1, "active": 0.9, "stellar": 1.0]
        case .capricorn:
            return ["earth": 1.5, "mechanical": 1.2, "heavy": 1.3, "crone": 1.2,
                    "static": 1.1, "cold": 1.0, "industrial": 1.0, "steady": 1.2]
        case .aquarius:
            return ["air": 1.4, "electrical": 1.5, "abstract": 1.3, "ultrasonic": 1.2,
                    "trickster": 1.1, "stellar": 1.2, "vacuum": 1.0, "glassy": 1.0]
        case .pisces:
            return ["water": 1.6, "ethereal": 1.4, "diffuse": 1.3, "drifting": 1.3,
                    "spiritual": 1.4, "lunar": 1.2, "receptive": 1.2, "shadow": 0.9]
        }
    }

    static func planetTagPreferences(_ planet: Planet) -> [String: Double] {
        switch planet {
        case .sun:
            return ["solar": 1.4, "warm": 1.1, "active": 1.0, "fire": 0.9, "hero": 0.8]
        case .moon:
            return ["lunar": 1.6, "water": 1.2, "receptive": 1.2, "mother": 1.0, "flowing": 0.9]
        case .mercury:
            return ["bright": 1.1, "electrical": 1.0, "pulse": 1.0, "air": 0.9, "trickster": 0.8]
        case .venus:
            return ["smooth": 1.3, "warm": 1.1, "balanced": 1.0, "organic": 0.9, "maiden": 0.8]
        case .mars:
            return ["fire": 1.3, "rough": 1.2, "active": 1.2, "surging": 1.1, "hot": 1.0]
        case .jupiter:
            return ["full": 1.1, "cosmic": 1.0, "nature": 0.9, "mentor": 0.9]
        case .saturn:
            return ["earth": 1.2, "heavy": 1.3, "mechanical": 1.1, "static": 1.1, "crone": 1.0, "cold": 0.9]
        case .uranus:
            return ["electrical": 1.5, "chaotic": 1.2, "ultrasonic": 1.2, "abstract": 1.1, "air": 0.9]
        case .neptune:
            return ["water": 1.3, "ethereal": 1.4, "diffuse": 1.3, "spiritual": 1.2, "drifting": 1.2, "void": 0.8]
        case .pluto:
            return ["shadow": 1.5, "dense": 1.3, "deep": 1.3, "heavy": 1.1, "water": 0.9]
        case .chiron:
            return ["mentor": 1.3, "spiritual": 1.1, "organic": 0.9, "mid": 0.8, "cosmic": 0.8]
        case .lilith:
            return ["shadow": 1.4, "void": 1.2, "irregular": 1.0, "rough": 0.9, "lunar": 0.8]
        case .northNode:
            return ["stellar": 1.1, "active": 0.9, "cosmic": 1.0, "drifting": 0.8]
        case .southNode:
            return ["void": 1.1, "crone": 0.9, "static": 0.8, "shadow": 0.8]
        }
    }

    static func elementTagPreferences(_ element: Element) -> [String: Double] {
        switch element {
        case .fire:
            return ["fire": 1.5, "hot": 1.3, "active": 1.2, "surging": 1.1,
                    "rough": 0.9, "solar": 1.0, "hero": 1.0, "pulse": 0.8]
        case .earth:
            return ["earth": 1.5, "heavy": 1.3, "steady": 1.3, "dense": 1.2,
                    "static": 1.1, "organic": 1.0, "mechanical": 0.9, "smooth": 0.8]
        case .air:
            return ["air": 1.5, "bright": 1.3, "light": 1.2, "crystalline": 1.2,
                    "electrical": 1.1, "drifting": 1.1, "sparse": 1.0, "trickster": 0.9]
        case .water:
            return ["water": 1.6, "flowing": 1.4, "cool": 1.2, "receptive": 1.3,
                    "lunar": 1.2, "dense": 1.0, "mother": 1.1, "diffuse": 1.0]
        }
    }

    static func moonPhaseTagPreferences(_ phase: MoonPhase) -> [String: Double] {
        switch phase {
        case .newMoon:
            return ["void": 1.4, "sparse": 1.3, "ethereal": 1.2, "sub": 1.1,
                    "receptive": 1.2, "shadow": 1.0, "cold": 0.9]
        case .waxingCrescent:
            return ["light": 1.2, "maiden": 1.2, "pulse": 1.1, "bright": 1.0,
                    "active": 0.9, "air": 0.8]
        case .firstQuarter:
            return ["active": 1.3, "pulse": 1.2, "fire": 1.0, "rough": 0.9,
                    "hero": 1.0, "mid": 0.8]
        case .waxingGibbous:
            return ["dense": 1.1, "full": 1.1, "organic": 1.0, "warm": 1.0,
                    "flowing": 0.9, "balanced": 0.9]
        case .fullMoon:
            return ["lunar": 1.5, "bright": 1.2, "saturated": 1.2, "water": 1.1,
                    "air": 1.0, "full": 1.1, "crystalline": 1.0]
        case .waningGibbous:
            return ["diffuse": 1.2, "mentor": 1.1, "drifting": 1.1, "cool": 1.0,
                    "spiritual": 1.0, "moderate": 0.9]
        case .lastQuarter:
            return ["earth": 1.2, "crone": 1.2, "steady": 1.1, "heavy": 1.0,
                    "static": 0.9, "mechanical": 0.8]
        case .waningCrescent:
            return ["water": 1.3, "ethereal": 1.3, "receptive": 1.3, "void": 1.1,
                    "drifting": 1.2, "sparse": 1.0, "shadow": 1.0, "cool": 1.1]
        }
    }

    /// Which tags play well for each stack role — used when picking layers.
    static func roleFit(_ role: StackRole, tags: SoundTags) -> Double {
        var s = 0.0
        func hit(_ cond: Bool, _ w: Double) { if cond { s += w } }
        switch role {
        case .bedrock:
            hit(["sub", "deep"].contains(tags.register), 2.2)
            hit(["heavy", "massive"].contains(tags.weight), 1.8)
            hit(["dense", "saturated"].contains(tags.density), 1.4)
            hit(["earth", "mechanical", "water"].contains(tags.domain), 1.2)
            hit(tags.motion == "static" || tags.rhythm == "steady", 1.0)
        case .foundation:
            hit(["water", "earth", "organic", "air"].contains(tags.domain), 1.6)
            hit(["medium", "heavy"].contains(tags.weight), 1.2)
            hit(["moderate", "dense"].contains(tags.density), 1.0)
            hit(tags.context == "nature" || tags.context == "domestic", 0.8)
        case .flow:
            hit(["flowing", "drifting", "swirling"].contains(tags.motion), 2.0)
            hit(tags.domain == "water" || tags.domain == "air", 1.4)
            hit(["irregular", "arrhythmic", "pulse"].contains(tags.rhythm), 1.0)
        case .texture:
            hit(["granular", "rough", "crystalline", "metallic", "glassy"].contains(tags.texture), 2.0)
            hit(["mechanical", "electrical", "organic"].contains(tags.domain), 1.2)
            hit(["mid", "bright"].contains(tags.register), 0.9)
        case .veil:
            hit(["ethereal", "light"].contains(tags.weight), 2.0)
            hit(["diffuse", "smooth", "crystalline"].contains(tags.texture), 1.5)
            hit(["sparse", "vacuum", "moderate"].contains(tags.density), 1.2)
            hit(["lunar", "stellar", "void"].contains(tags.celestial), 1.0)
        case .spark:
            hit(["bright", "ultrasonic", "full"].contains(tags.register), 2.0)
            hit(["warm", "hot"].contains(tags.temperature), 1.2)
            hit(["fire", "electrical", "cosmic"].contains(tags.domain), 1.3)
            hit(tags.polarity == "active", 1.0)
        case .accent:
            hit(["trickster", "hero", "shadow", "maiden"].contains(tags.archetype), 1.5)
            hit(["urban", "industrial", "spiritual", "abstract"].contains(tags.context), 1.2)
            hit(["planetary", "solar", "stellar"].contains(tags.celestial), 1.0)
            hit(isNewLike(tags), 0.3)
        }
        return s
    }

    private static func isNewLike(_ tags: SoundTags) -> Bool {
        ["electrical", "cosmic"].contains(tags.domain)
            || ["glassy", "metallic"].contains(tags.texture)
    }
}
