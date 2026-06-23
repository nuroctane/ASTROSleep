import Foundation

// MARK: - Tag Engine v3.0
/// 12-dimensional archetypal scoring with decimal precision.
final class TagEngine {
    static let shared = TagEngine()
    
    private let dimensions = [
        "domain", "rhythm", "register", "context", "weight",
        "texture", "motion", "density", "temperature",
        "polarity", "celestial", "archetype"
    ]
    
    // Dimension weights per spec
    private let dimensionWeights: [String: Double] = [
        "domain": 9.0,
        "celestial": 4.0,
        "archetype": 4.0,
        "rhythm": 3.0,
        "motion": 3.0,
        "register": 2.0,
        "context": 2.0,
        "weight": 2.0,
        "texture": 2.0,
        "density": 2.0,
        "temperature": 2.0,
        "polarity": 2.0
    ]
    
    private init() {}
    
    // MARK: - Tag Vector Calculation
    
    func calculateTagVector(for sound: Sound) -> ElementVector {
        var raw = ElementVector.zero
        let tags = sound.tags
        
        // Domain (highest weight)
        if let vector = TagVectorTables.domain[tags.domain] {
            raw += vector * dimensionWeights["domain"]!
        }
        
        // Rhythm
        if let vector = TagVectorTables.rhythm[tags.rhythm] {
            raw += vector * dimensionWeights["rhythm"]!
        }
        
        // Register
        if let vector = TagVectorTables.register[tags.register] {
            raw += vector * dimensionWeights["register"]!
        }
        
        // Context
        if let vector = TagVectorTables.context[tags.context] {
            raw += vector * dimensionWeights["context"]!
        }
        
        // Weight
        if let vector = TagVectorTables.weight[tags.weight] {
            raw += vector * dimensionWeights["weight"]!
        }
        
        // Texture
        if let vector = TagVectorTables.texture[tags.texture] {
            raw += vector * dimensionWeights["texture"]!
        }
        
        // Motion
        if let vector = TagVectorTables.motion[tags.motion] {
            raw += vector * dimensionWeights["motion"]!
        }
        
        // Density
        if let vector = TagVectorTables.density[tags.density] {
            raw += vector * dimensionWeights["density"]!
        }
        
        // Temperature
        if let vector = TagVectorTables.temperature[tags.temperature] {
            raw += vector * dimensionWeights["temperature"]!
        }
        
        // Polarity
        if let vector = TagVectorTables.polarity[tags.polarity] {
            raw += vector * dimensionWeights["polarity"]!
        }
        
        // Celestial
        if let vector = TagVectorTables.celestial[tags.celestial] {
            raw += vector * dimensionWeights["celestial"]!
        }
        
        // Archetype
        if let vector = TagVectorTables.archetype[tags.archetype] {
            raw += vector * dimensionWeights["archetype"]!
        }
        
        return raw
    }
    
    // MARK: - Normalization
    
    func normalizeSoundVectors(_ sounds: [Sound]) -> [ElementVector] {
        let rawScores = sounds.map { calculateTagVector(for: $0) }
        
        let maxValues = ElementVector(
            fire: rawScores.map { $0.fire }.max() ?? 1.0,
            earth: rawScores.map { $0.earth }.max() ?? 1.0,
            air: rawScores.map { $0.air }.max() ?? 1.0,
            water: rawScores.map { $0.water }.max() ?? 1.0
        )
        
        return rawScores.map { raw in
            ElementVector(
                fire: maxValues.fire > 0 ? (raw.fire / maxValues.fire * 10.0).roundedTo(2) : 0.0,
                earth: maxValues.earth > 0 ? (raw.earth / maxValues.earth * 10.0).roundedTo(2) : 0.0,
                air: maxValues.air > 0 ? (raw.air / maxValues.air * 10.0).roundedTo(2) : 0.0,
                water: maxValues.water > 0 ? (raw.water / maxValues.water * 10.0).roundedTo(2) : 0.0
            )
        }
    }
    
    // MARK: - Sound Ranking
    
    func rankSounds(
        _ sounds: [Sound],
        against nightlyScore: NightlyScoreResult
    ) -> [RankedSound] {
        let nightlyElementScore = nightlyScore.elementScore
        
        return sounds.map { sound in
            let tagVector = calculateTagVector(for: sound)
            
            // Weighted dot product with decimal precision
            let rankScore = (
                nightlyElementScore.fire * tagVector.fire +
                nightlyElementScore.earth * tagVector.earth +
                nightlyElementScore.air * tagVector.air +
                nightlyElementScore.water * tagVector.water
            ) / 4.0
            
            return RankedSound(
                sound: sound,
                score: rankScore.roundedTo(2),
                matchPercentage: (rankScore * 10.0).roundedTo(1)
            )
        }.sorted(by: >)
    }
}

// MARK: - Tag Vector Tables

struct TagVectorTables {
    // MARK: Domain (weight 9)
    static let domain: [String: ElementVector] = [
        "water": ElementVector(fire: 0.5, earth: 1.5, air: 1.0, water: 9.0),
        "air": ElementVector(fire: 1.5, earth: 0.5, air: 9.0, water: 1.0),
        "fire": ElementVector(fire: 9.0, earth: 0.5, air: 1.5, water: 0.5),
        "earth": ElementVector(fire: 0.5, earth: 9.0, air: 0.5, water: 1.5),
        "mechanical": ElementVector(fire: 1.5, earth: 6.0, air: 2.0, water: 1.0),
        "organic": ElementVector(fire: 1.0, earth: 5.0, air: 1.5, water: 4.0),
        "electrical": ElementVector(fire: 3.0, earth: 1.0, air: 7.0, water: 0.5),
        "cosmic": ElementVector(fire: 4.0, earth: 1.0, air: 6.0, water: 2.0)
    ]
    
    // MARK: Rhythm (weight 3)
    static let rhythm: [String: ElementVector] = [
        "steady": ElementVector(fire: 0.0, earth: 3.0, air: 0.5, water: 1.5),
        "pulse": ElementVector(fire: 1.0, earth: 2.0, air: 1.0, water: 1.5),
        "irregular": ElementVector(fire: 2.0, earth: 0.0, air: 2.0, water: 1.5),
        "chaotic": ElementVector(fire: 3.0, earth: 0.0, air: 2.5, water: 0.5),
        "rhythmic": ElementVector(fire: 1.5, earth: 2.0, air: 1.0, water: 2.0),
        "arrhythmic": ElementVector(fire: 1.0, earth: 0.0, air: 2.0, water: 2.0)
    ]
    
    // MARK: Register (weight 2)
    static let register: [String: ElementVector] = [
        "sub": ElementVector(fire: 0.0, earth: 3.0, air: 0.0, water: 2.0),
        "deep": ElementVector(fire: 0.0, earth: 2.5, air: 0.0, water: 1.5),
        "mid": ElementVector(fire: 1.0, earth: 1.5, air: 1.0, water: 1.0),
        "bright": ElementVector(fire: 1.5, earth: 0.5, air: 2.5, water: 0.0),
        "full": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "ultrasonic": ElementVector(fire: 0.5, earth: 0.0, air: 3.0, water: 0.0)
    ]
    
    // MARK: Context (weight 2)
    static let context: [String: ElementVector] = [
        "nature": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "domestic": ElementVector(fire: 0.0, earth: 2.0, air: 0.5, water: 1.5),
        "abstract": ElementVector(fire: 0.5, earth: 0.0, air: 2.0, water: 1.0),
        "urban": ElementVector(fire: 1.5, earth: 1.0, air: 2.0, water: 0.5),
        "industrial": ElementVector(fire: 1.0, earth: 3.0, air: 1.5, water: 0.0),
        "spiritual": ElementVector(fire: 1.0, earth: 0.5, air: 2.0, water: 2.5)
    ]
    
    // MARK: Weight (weight 2)
    static let weight: [String: ElementVector] = [
        "ethereal": ElementVector(fire: 0.0, earth: 0.0, air: 2.0, water: 1.0),
        "light": ElementVector(fire: 0.0, earth: 0.0, air: 1.5, water: 1.5),
        "medium": ElementVector(fire: 1.0, earth: 1.5, air: 0.5, water: 0.5),
        "heavy": ElementVector(fire: 2.5, earth: 1.0, air: 1.0, water: 0.5),
        "massive": ElementVector(fire: 2.0, earth: 3.0, air: 0.0, water: 0.0)
    ]
    
    // MARK: Texture (weight 2)
    static let texture: [String: ElementVector] = [
        "smooth": ElementVector(fire: 1.0, earth: 2.5, air: 1.0, water: 3.0),
        "rough": ElementVector(fire: 3.5, earth: 3.5, air: 0.5, water: 1.0),
        "crystalline": ElementVector(fire: 2.5, earth: 1.0, air: 4.0, water: 1.5),
        "diffuse": ElementVector(fire: 1.0, earth: 1.0, air: 2.5, water: 3.0),
        "granular": ElementVector(fire: 2.0, earth: 2.0, air: 1.0, water: 1.0),
        "glassy": ElementVector(fire: 1.5, earth: 1.0, air: 3.5, water: 1.0),
        "metallic": ElementVector(fire: 2.0, earth: 3.0, air: 2.0, water: 0.0)
    ]
    
    // MARK: Motion (weight 3)
    static let motion: [String: ElementVector] = [
        "static": ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0),
        "flowing": ElementVector(fire: 1.0, earth: 0.0, air: 1.0, water: 4.0),
        "surging": ElementVector(fire: 4.5, earth: 0.0, air: 2.0, water: 1.0),
        "swirling": ElementVector(fire: 2.5, earth: 0.0, air: 4.0, water: 1.0),
        "oscillating": ElementVector(fire: 2.0, earth: 1.0, air: 3.0, water: 1.0),
        "drifting": ElementVector(fire: 1.0, earth: 0.5, air: 3.0, water: 2.5),
        "pulsing": ElementVector(fire: 2.5, earth: 0.5, air: 1.5, water: 2.0)
    ]
    
    // MARK: Density (weight 2)
    static let density: [String: ElementVector] = [
        "vacuum": ElementVector(fire: 3.0, earth: 0.0, air: 2.5, water: 1.0),
        "sparse": ElementVector(fire: 2.5, earth: 0.0, air: 2.0, water: 1.0),
        "moderate": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "dense": ElementVector(fire: 1.0, earth: 3.0, air: 1.0, water: 2.0),
        "saturated": ElementVector(fire: 1.5, earth: 2.5, air: 2.0, water: 2.5)
    ]
    
    // MARK: Temperature (weight 2)
    static let temperature: [String: ElementVector] = [
        "cold": ElementVector(fire: 0.0, earth: 3.0, air: 1.0, water: 2.0),
        "cool": ElementVector(fire: 0.5, earth: 2.0, air: 1.5, water: 2.0),
        "neutral": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "warm": ElementVector(fire: 2.5, earth: 1.0, air: 1.5, water: 1.0),
        "hot": ElementVector(fire: 4.0, earth: 0.5, air: 1.0, water: 0.0)
    ]
    
    // MARK: Polarity (weight 2)
    static let polarity: [String: ElementVector] = [
        "active": ElementVector(fire: 3.0, earth: 1.0, air: 2.0, water: 0.5),
        "receptive": ElementVector(fire: 0.5, earth: 2.0, air: 1.0, water: 3.0),
        "balanced": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "neutral": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0)
    ]
    
    // MARK: Celestial (weight 4)
    static let celestial: [String: ElementVector] = [
        "solar": ElementVector(fire: 4.0, earth: 0.5, air: 1.0, water: 0.0),
        "lunar": ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0),
        "stellar": ElementVector(fire: 1.0, earth: 0.5, air: 3.0, water: 1.0),
        "planetary": ElementVector(fire: 1.5, earth: 1.5, air: 1.5, water: 1.5),
        "void": ElementVector(fire: 0.5, earth: 0.5, air: 0.5, water: 0.5)
    ]
    
    // MARK: Archetype (weight 4)
    static let archetype: [String: ElementVector] = [
        "maiden": ElementVector(fire: 1.0, earth: 0.5, air: 3.0, water: 1.0),
        "mother": ElementVector(fire: 0.5, earth: 2.0, air: 0.5, water: 3.0),
        "crone": ElementVector(fire: 1.0, earth: 3.0, air: 2.0, water: 2.0),
        "hero": ElementVector(fire: 4.0, earth: 1.0, air: 2.0, water: 0.5),
        "mentor": ElementVector(fire: 1.5, earth: 3.0, air: 2.0, water: 1.0),
        "shadow": ElementVector(fire: 0.5, earth: 0.5, air: 1.0, water: 4.0),
        "trickster": ElementVector(fire: 2.0, earth: 0.5, air: 4.0, water: 1.0)
    ]
}
