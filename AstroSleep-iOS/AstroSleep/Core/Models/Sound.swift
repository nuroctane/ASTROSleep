import Foundation

// MARK: - Sound (12-Dimensional Tagged Audio)

struct Sound: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let tags: SoundTags
    let elementScores: ElementVector
    let durationSeconds: Int
    var isNew: Bool
    let version: Int
    let cdnUrl: String
    
    /// Filename of the audio file bundled inside the app (e.g. "heavy_rain.m4a").
    /// When provided, the app plays from the bundle without downloading.
    var bundleFilename: String?
    
    var displayName: String { name }
    
    /// Resolved file path: checks app bundle first, then Documents cache.
    var localPath: String? {
        // 1. Check app bundle (shipped audio files)
        if let bundleFilename = bundleFilename,
           let bundlePath = Bundle.main.path(forResource: bundleFilename, ofType: nil),
           FileManager.default.fileExists(atPath: bundlePath) {
            return bundlePath
        }
        
        // 2. Check Documents cache (previously downloaded from CDN)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let soundsDir = docs?.appendingPathComponent("sounds")
        let filePath = soundsDir?.appendingPathComponent("\(id).m4a")
        if let path = filePath?.path, FileManager.default.fileExists(atPath: path) {
            return path
        }
        return nil
    }
    
    var isDownloaded: Bool {
        localPath != nil
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Sound, rhs: Sound) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sound Tags (12 Dimensions)

struct SoundTags: Codable, Equatable {
    let domain: String        // water, air, fire, earth, mechanical, organic, electrical, cosmic
    let rhythm: String        // steady, pulse, irregular, chaotic, rhythmic, arrhythmic
    let register: String      // sub, deep, mid, bright, full, ultrasonic
    let context: String       // nature, domestic, abstract, urban, industrial, spiritual
    let weight: String        // ethereal, light, medium, heavy, massive
    let texture: String       // smooth, rough, crystalline, diffuse, granular, glassy, metallic
    let motion: String        // static, flowing, surging, swirling, oscillating, drifting, pulsing
    let density: String       // vacuum, sparse, moderate, dense, saturated
    let temperature: String // cold, cool, neutral, warm, hot
    let polarity: String      // active, receptive, balanced, neutral
    let celestial: String     // solar, lunar, stellar, planetary, void
    let archetype: String     // maiden, mother, crone, hero, mentor, shadow, trickster
    
    func validate() -> Bool {
        let validDomains = ["water", "air", "fire", "earth", "mechanical", "organic", "electrical", "cosmic"]
        let validRhythms = ["steady", "pulse", "irregular", "chaotic", "rhythmic", "arrhythmic"]
        let validRegisters = ["sub", "deep", "mid", "bright", "full", "ultrasonic"]
        let validContexts = ["nature", "domestic", "abstract", "urban", "industrial", "spiritual"]
        let validWeights = ["ethereal", "light", "medium", "heavy", "massive"]
        let validTextures = ["smooth", "rough", "crystalline", "diffuse", "granular", "glassy", "metallic"]
        let validMotions = ["static", "flowing", "surging", "swirling", "oscillating", "drifting", "pulsing"]
        let validDensities = ["vacuum", "sparse", "moderate", "dense", "saturated"]
        let validTemperatures = ["cold", "cool", "neutral", "warm", "hot"]
        let validPolarities = ["active", "receptive", "balanced", "neutral"]
        let validCelestials = ["solar", "lunar", "stellar", "planetary", "void"]
        let validArchetypes = ["maiden", "mother", "crone", "hero", "mentor", "shadow", "trickster"]
        
        return validDomains.contains(domain)
            && validRhythms.contains(rhythm)
            && validRegisters.contains(register)
            && validContexts.contains(context)
            && validWeights.contains(weight)
            && validTextures.contains(texture)
            && validMotions.contains(motion)
            && validDensities.contains(density)
            && validTemperatures.contains(temperature)
            && validPolarities.contains(polarity)
            && validCelestials.contains(celestial)
            && validArchetypes.contains(archetype)
    }
}

// MARK: - Ranked Sound

struct RankedSound: Identifiable, Comparable {
    let id = UUID()
    let sound: Sound
    let score: Double
    let matchPercentage: Double
    
    static func < (lhs: RankedSound, rhs: RankedSound) -> Bool {
        lhs.score < rhs.score
    }
}

// MARK: - Sound Manifest

struct SoundManifest: Codable {
    let version: Int
    let generatedAt: String?
    let sounds: [Sound]
}

// MARK: - Sound Library

final class SoundLibrary {
    static let shared = SoundLibrary()
    
    let sounds: [Sound]
    
    /// O(1) lookup by sound ID. Populated at init.
    private(set) var soundById: [String: Sound] = [:]
    
    private init() {
        let loaded = SoundLibrary.loadFromManifest() ?? SoundLibrary.defaultSounds()
        self.sounds = loaded
        self.soundById = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
    
    /// O(1) sound lookup. Returns nil if ID not found.
    func sound(id: String) -> Sound? {
        soundById[id]
    }
    
    /// Attempts to load sounds from the bundled `sounds_manifest.json`.
    /// Returns `nil` if the manifest is missing or malformed.
    private static func loadFromManifest() -> [Sound]? {
        guard let url = Bundle.main.url(forResource: "sounds_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(SoundManifest.self, from: data) else {
            print("[SoundLibrary] Failed to load sounds_manifest.json — falling back to embedded defaults")
            return nil
        }
        print("[SoundLibrary] Loaded \(manifest.sounds.count) sounds from manifest v\(manifest.version)")
        return manifest.sounds
    }
    
    /// Embedded fallback catalog. Used when the JSON manifest is unavailable.
    private static func defaultSounds() -> [Sound] {
        return [
        Sound(
            id: "heavy_rain",
            name: "Heavy Rain",
            tags: SoundTags(
                domain: "water", rhythm: "irregular", register: "mid",
                context: "nature", weight: "heavy", texture: "rough",
                motion: "flowing", density: "dense", temperature: "cool",
                polarity: "receptive", celestial: "lunar", archetype: "mother"
            ),
            elementScores: ElementVector(fire: 0.45, earth: 0.82, air: 0.38, water: 0.91),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/heavy_rain.m4a"
        ),
        Sound(
            id: "light_rain",
            name: "Light Rain",
            tags: SoundTags(
                domain: "water", rhythm: "irregular", register: "bright",
                context: "nature", weight: "light", texture: "crystalline",
                motion: "flowing", density: "sparse", temperature: "cool",
                polarity: "receptive", celestial: "lunar", archetype: "maiden"
            ),
            elementScores: ElementVector(fire: 0.32, earth: 0.45, air: 0.55, water: 0.78),
            durationSeconds: 45, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/light_rain.m4a"
        ),
        Sound(
            id: "thunder",
            name: "Thunderstorm",
            tags: SoundTags(
                domain: "electrical", rhythm: "chaotic", register: "full",
                context: "nature", weight: "massive", texture: "rough",
                motion: "surging", density: "saturated", temperature: "cool",
                polarity: "active", celestial: "planetary", archetype: "shadow"
            ),
            elementScores: ElementVector(fire: 0.88, earth: 0.65, air: 0.72, water: 0.41),
            durationSeconds: 90, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/thunder.m4a"
        ),
        Sound(
            id: "ocean",
            name: "Ocean Waves",
            tags: SoundTags(
                domain: "water", rhythm: "pulse", register: "deep",
                context: "nature", weight: "medium", texture: "smooth",
                motion: "flowing", density: "dense", temperature: "cool",
                polarity: "receptive", celestial: "lunar", archetype: "mother"
            ),
            elementScores: ElementVector(fire: 0.28, earth: 0.48, air: 0.35, water: 0.89),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/ocean.m4a"
        ),
        Sound(
            id: "river",
            name: "River / Stream",
            tags: SoundTags(
                domain: "water", rhythm: "rhythmic", register: "mid",
                context: "nature", weight: "medium", texture: "rough",
                motion: "flowing", density: "moderate", temperature: "cool",
                polarity: "receptive", celestial: "planetary", archetype: "mentor"
            ),
            elementScores: ElementVector(fire: 0.35, earth: 0.62, air: 0.42, water: 0.81),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/river.m4a"
        ),
        Sound(
            id: "forest",
            name: "Forest / Birds",
            tags: SoundTags(
                domain: "organic", rhythm: "arrhythmic", register: "full",
                context: "nature", weight: "light", texture: "diffuse",
                motion: "drifting", density: "moderate", temperature: "neutral",
                polarity: "balanced", celestial: "stellar", archetype: "trickster"
            ),
            elementScores: ElementVector(fire: 0.42, earth: 0.58, air: 0.48, water: 0.52),
            durationSeconds: 90, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/forest.m4a"
        ),
        Sound(
            id: "wind",
            name: "Wind",
            tags: SoundTags(
                domain: "air", rhythm: "irregular", register: "bright",
                context: "nature", weight: "medium", texture: "diffuse",
                motion: "swirling", density: "sparse", temperature: "cool",
                polarity: "active", celestial: "planetary", archetype: "trickster"
            ),
            elementScores: ElementVector(fire: 0.55, earth: 0.25, air: 0.88, water: 0.32),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/wind.m4a"
        ),
        Sound(
            id: "fire",
            name: "Fire / Crackling",
            tags: SoundTags(
                domain: "fire", rhythm: "irregular", register: "mid",
                context: "nature", weight: "medium", texture: "rough",
                motion: "surging", density: "moderate", temperature: "hot",
                polarity: "active", celestial: "solar", archetype: "hero"
            ),
            elementScores: ElementVector(fire: 0.92, earth: 0.35, air: 0.48, water: 0.25),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/fire.m4a"
        ),
        Sound(
            id: "white_noise",
            name: "White Noise",
            tags: SoundTags(
                domain: "electrical", rhythm: "steady", register: "full",
                context: "abstract", weight: "medium", texture: "smooth",
                motion: "static", density: "saturated", temperature: "neutral",
                polarity: "neutral", celestial: "void", archetype: "crone"
            ),
            elementScores: ElementVector(fire: 0.48, earth: 0.52, air: 0.51, water: 0.49),
            durationSeconds: 30, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/white_noise.m4a"
        ),
        Sound(
            id: "brown_noise",
            name: "Brown Noise",
            tags: SoundTags(
                domain: "earth", rhythm: "steady", register: "sub",
                context: "abstract", weight: "medium", texture: "smooth",
                motion: "static", density: "dense", temperature: "cool",
                polarity: "receptive", celestial: "planetary", archetype: "mother"
            ),
            elementScores: ElementVector(fire: 0.25, earth: 0.88, air: 0.22, water: 0.65),
            durationSeconds: 30, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/brown_noise.m4a"
        ),
        Sound(
            id: "pink_noise",
            name: "Pink Noise",
            tags: SoundTags(
                domain: "electrical", rhythm: "steady", register: "full",
                context: "abstract", weight: "light", texture: "smooth",
                motion: "static", density: "moderate", temperature: "neutral",
                polarity: "balanced", celestial: "stellar", archetype: "mentor"
            ),
            elementScores: ElementVector(fire: 0.42, earth: 0.48, air: 0.55, water: 0.45),
            durationSeconds: 30, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/pink_noise.m4a"
        ),
        Sound(
            id: "binaural",
            name: "Tibetan / Binaural",
            tags: SoundTags(
                domain: "cosmic", rhythm: "pulse", register: "sub",
                context: "spiritual", weight: "ethereal", texture: "crystalline",
                motion: "oscillating", density: "sparse", temperature: "cool",
                polarity: "receptive", celestial: "stellar", archetype: "crone"
            ),
            elementScores: ElementVector(fire: 0.35, earth: 0.72, air: 0.68, water: 0.45),
            durationSeconds: 120, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/binaural.m4a"
        ),
        Sound(
            id: "sprinklers",
            name: "Sprinklers",
            tags: SoundTags(
                domain: "mechanical", rhythm: "pulse", register: "bright",
                context: "domestic", weight: "light", texture: "crystalline",
                motion: "pulsing", density: "sparse", temperature: "cool",
                polarity: "active", celestial: "planetary", archetype: "maiden"
            ),
            elementScores: ElementVector(fire: 0.48, earth: 0.58, air: 0.62, water: 0.32),
            durationSeconds: 45, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/sprinklers.m4a"
        ),
        Sound(
            id: "fan_low",
            name: "Box Fan (Low)",
            tags: SoundTags(
                domain: "mechanical", rhythm: "steady", register: "deep",
                context: "domestic", weight: "light", texture: "smooth",
                motion: "static", density: "moderate", temperature: "cool",
                polarity: "neutral", celestial: "planetary", archetype: "mentor"
            ),
            elementScores: ElementVector(fire: 0.32, earth: 0.68, air: 0.45, water: 0.35),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/fan_low.m4a"
        ),
        Sound(
            id: "fan_med",
            name: "Box Fan (Med)",
            tags: SoundTags(
                domain: "mechanical", rhythm: "steady", register: "mid",
                context: "domestic", weight: "medium", texture: "smooth",
                motion: "static", density: "moderate", temperature: "cool",
                polarity: "neutral", celestial: "planetary", archetype: "mentor"
            ),
            elementScores: ElementVector(fire: 0.35, earth: 0.65, air: 0.48, water: 0.32),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/fan_med.m4a"
        ),
        Sound(
            id: "fan_high",
            name: "Box Fan (High)",
            tags: SoundTags(
                domain: "air", rhythm: "steady", register: "bright",
                context: "domestic", weight: "medium", texture: "diffuse",
                motion: "swirling", density: "moderate", temperature: "cool",
                polarity: "active", celestial: "planetary", archetype: "hero"
            ),
            elementScores: ElementVector(fire: 0.55, earth: 0.35, air: 0.82, water: 0.28),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/fan_high.m4a"
        ),
        Sound(
            id: "wtfl_sm",
            name: "Small Waterfall",
            tags: SoundTags(
                domain: "water", rhythm: "steady", register: "bright",
                context: "nature", weight: "medium", texture: "crystalline",
                motion: "flowing", density: "moderate", temperature: "cool",
                polarity: "receptive", celestial: "lunar", archetype: "maiden"
            ),
            elementScores: ElementVector(fire: 0.38, earth: 0.52, air: 0.48, water: 0.72),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/wtfl_sm.m4a"
        ),
        Sound(
            id: "wtfl_lg",
            name: "Large Waterfall",
            tags: SoundTags(
                domain: "water", rhythm: "steady", register: "sub",
                context: "nature", weight: "heavy", texture: "rough",
                motion: "surging", density: "dense", temperature: "cool",
                polarity: "active", celestial: "lunar", archetype: "mother"
            ),
            elementScores: ElementVector(fire: 0.42, earth: 0.65, air: 0.35, water: 0.88),
            durationSeconds: 90, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/wtfl_lg.m4a"
        ),
        Sound(
            id: "car_rain",
            name: "Car in Rain",
            tags: SoundTags(
                domain: "mechanical", rhythm: "rhythmic", register: "mid",
                context: "urban", weight: "medium", texture: "smooth",
                motion: "flowing", density: "dense", temperature: "cool",
                polarity: "receptive", celestial: "planetary", archetype: "shadow"
            ),
            elementScores: ElementVector(fire: 0.35, earth: 0.62, air: 0.48, water: 0.55),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/car_rain.m4a"
        ),
        Sound(
            id: "dryer",
            name: "Clothes Dryer",
            tags: SoundTags(
                domain: "mechanical", rhythm: "pulse", register: "deep",
                context: "domestic", weight: "medium", texture: "smooth",
                motion: "swirling", density: "moderate", temperature: "warm",
                polarity: "receptive", celestial: "planetary", archetype: "mother"
            ),
            elementScores: ElementVector(fire: 0.42, earth: 0.72, air: 0.38, water: 0.48),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/dryer.m4a"
        ),
        Sound(
            id: "lawn_mower",
            name: "Lawn Mower (Distant)",
            tags: SoundTags(
                domain: "mechanical", rhythm: "steady", register: "deep",
                context: "urban", weight: "heavy", texture: "rough",
                motion: "static", density: "dense", temperature: "neutral",
                polarity: "active", celestial: "planetary", archetype: "hero"
            ),
            elementScores: ElementVector(fire: 0.52, earth: 0.78, air: 0.42, water: 0.28),
            durationSeconds: 60, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/lawn_mower.m4a"
        ),
        Sound(
            id: "clock_tick",
            name: "Clock Ticking",
            tags: SoundTags(
                domain: "mechanical", rhythm: "pulse", register: "bright",
                context: "domestic", weight: "light", texture: "crystalline",
                motion: "pulsing", density: "sparse", temperature: "neutral",
                polarity: "balanced", celestial: "planetary", archetype: "crone"
            ),
            elementScores: ElementVector(fire: 0.42, earth: 0.55, air: 0.62, water: 0.41),
            durationSeconds: 30, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/clock_tick.m4a"
        ),
        Sound(
            id: "sink_faucet",
            name: "Sink Faucet",
            tags: SoundTags(
                domain: "water", rhythm: "steady", register: "bright",
                context: "domestic", weight: "light", texture: "smooth",
                motion: "flowing", density: "sparse", temperature: "cool",
                polarity: "receptive", celestial: "lunar", archetype: "maiden"
            ),
            elementScores: ElementVector(fire: 0.32, earth: 0.45, air: 0.52, water: 0.71),
            durationSeconds: 45, isNew: false, version: 1,
            cdnUrl: "https://cdn.astrosleep.app/sounds/sink_faucet.m4a"
        )
    ]
    }
}
