import Foundation

// MARK: - Tag Engine v4
/// Deeply personalized 12-dimensional scoring — parity with Android TagEngine.kt.
/// Ranking is not a single nightly dot-product. Each user gets a PersonalSoundProfile
/// that remaps dimension weights, injects tag affinities, blends natal vs nightly pull,
/// folds in active transits + moon phase, and applies deterministic fingerprint jitter.
final class TagEngine {
    static let shared = TagEngine()

    private let baseDimensionWeights: [String: Double] = [
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

    // MARK: - Tag vector

    func calculateTagVector(for sound: Sound) -> ElementVector {
        calculateTagVector(tags: sound.tags, dimensionMultipliers: [:])
    }

    func calculateTagVector(tags: SoundTags) -> ElementVector {
        calculateTagVector(tags: tags, dimensionMultipliers: [:])
    }

    /// Weighted 12-dim → ElementVector. Optional per-user dimension multipliers
    /// stretch the sonic space so the same catalog reads differently per chart.
    func calculateTagVector(
        tags: SoundTags,
        dimensionMultipliers: [String: Double]
    ) -> ElementVector {
        var raw = ElementVector.zero

        func add(_ table: [String: ElementVector], _ key: String, _ weightKey: String) {
            guard let vector = table[key] else { return }
            let base = baseDimensionWeights[weightKey] ?? 1.0
            let mult = dimensionMultipliers[weightKey] ?? 1.0
            raw += vector * (base * mult)
        }

        add(TagVectorTables.domain, tags.domain, "domain")
        add(TagVectorTables.rhythm, tags.rhythm, "rhythm")
        add(TagVectorTables.register, tags.register, "register")
        add(TagVectorTables.context, tags.context, "context")
        add(TagVectorTables.weight, tags.weight, "weight")
        add(TagVectorTables.texture, tags.texture, "texture")
        add(TagVectorTables.motion, tags.motion, "motion")
        add(TagVectorTables.density, tags.density, "density")
        add(TagVectorTables.temperature, tags.temperature, "temperature")
        add(TagVectorTables.polarity, tags.polarity, "polarity")
        add(TagVectorTables.celestial, tags.celestial, "celestial")
        add(TagVectorTables.archetype, tags.archetype, "archetype")

        return raw
    }

    func normalizeSoundVectors(_ sounds: [Sound]) -> [ElementVector] {
        let rawScores = sounds.map { calculateTagVector(for: $0) }
        let maxValues = ElementVector(
            fire: rawScores.map(\.fire).max() ?? 1.0,
            earth: rawScores.map(\.earth).max() ?? 1.0,
            air: rawScores.map(\.air).max() ?? 1.0,
            water: rawScores.map(\.water).max() ?? 1.0
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

    // MARK: - Ranking

    /// Legacy simple rank — routes through personalized path with anonymous profile.
    func rankSounds(
        _ sounds: [Sound],
        against nightlyScore: NightlyScoreResult
    ) -> [RankedSound] {
        rankSoundsPersonalized(
            sounds: sounds,
            nightly: nightlyScore,
            profile: PersonalSoundProfile.from(
                userId: "anonymous",
                chart: nil,
                baseScore: nightlyScore.elementScore
            ),
            natalBaseScore: nightlyScore.elementScore,
            chart: nil
        )
    }

    /// Full personalized ranking — what combo generation must call.
    func rankSoundsPersonalized(
        sounds: [Sound],
        nightly: NightlyScoreResult,
        profile: PersonalSoundProfile,
        natalBaseScore: ElementVector,
        chart: NatalChart?
    ) -> [RankedSound] {
        let transitAffinity = buildTransitAffinity(
            transits: nightly.activeTransits,
            transitPull: profile.transitPull
        )
        let phaseAffinity = TagAffinityTables.moonPhaseTagPreferences(nightly.moonPhase)
        let oppositeElement = opposite(profile.dominantElement)

        return sounds.map { sound in
            scoreSound(
                sound: sound,
                nightly: nightly,
                profile: profile,
                natalBaseScore: natalBaseScore,
                transitAffinity: transitAffinity,
                phaseAffinity: phaseAffinity,
                oppositeElement: oppositeElement
            )
        }.sorted(by: >)
    }

    private func scoreSound(
        sound: Sound,
        nightly: NightlyScoreResult,
        profile: PersonalSoundProfile,
        natalBaseScore: ElementVector,
        transitAffinity: [String: Double],
        phaseAffinity: [String: Double],
        oppositeElement: Element
    ) -> RankedSound {
        let tags = sound.tags
        var notes: [String] = []

        let personalVector = calculateTagVector(tags: tags, dimensionMultipliers: profile.dimensionMultipliers)

        let nightlyRes = elementProduct(nightly.elementScore, personalVector) * profile.nightlyPull
        notes.append("nightly×\(profile.nightlyPull.roundedTo(2))")

        let natalRes = elementProduct(natalBaseScore, personalVector) * profile.natalPull
        notes.append("natal×\(profile.natalPull.roundedTo(2))")

        let catalogRes = elementProduct(nightly.elementScore, sound.elementScores) * 0.35

        let tagVals = tags.allValues()
        var tagAff = 0.0
        var hitCount = 0
        for t in tagVals {
            let a = profile.tagAffinities[t] ?? 0
            if a != 0 {
                tagAff += a
                hitCount += 1
            }
        }
        let tagAffinityScore = tagAff > 0 ? log(1.0 + tagAff) * 18.0 : 0.0
        if hitCount > 0 { notes.append("tagHits=\(hitCount)") }

        var transitScore = 0.0
        for t in tagVals {
            transitScore += transitAffinity[t] ?? 0
        }
        transitScore = log(1.0 + transitScore) * 14.0 * profile.transitPull
        if transitScore > 0.5 {
            notes.append("transit+\(transitScore.roundedTo(1))")
        }

        var phaseScore = 0.0
        for t in tagVals {
            phaseScore += phaseAffinity[t] ?? 0
        }
        phaseScore = log(1.0 + phaseScore) * 12.0
        if phaseScore > 0.5 {
            notes.append("phase+\(phaseScore.roundedTo(1))")
        }

        let soundDom = personalVector.dominant()
        let elementAlign: Double
        switch soundDom {
        case profile.dominantElement: elementAlign = 22.0
        case profile.secondaryElement: elementAlign = 11.0
        case oppositeElement: elementAlign = 4.0 * profile.contrastBias
        default: elementAlign = 3.0
        }
        notes.append("elem=\(soundDom.displayName)")

        let modalityFit = modalityCongruence(profile: profile, tags: tags) * 8.0

        let rxBoost: Double
        if ["irregular", "arrhythmic", "chaotic"].contains(tags.rhythm)
            || tags.archetype == "shadow"
            || tags.celestial == "void" {
            if let shadow = profile.tagAffinities["shadow"] {
                rxBoost = min(shadow, 2.0) * 2.5
            } else {
                rxBoost = 0
            }
        } else {
            rxBoost = 0
        }

        let personalPull = (personalVector.fire + personalVector.earth
            + personalVector.air + personalVector.water) * 0.02

        let jitter = fingerprintJitter(fingerprint: profile.fingerprint, soundId: sound.id) * 6.5

        let contrastBonus = soundDom == oppositeElement ? 5.0 * profile.contrastBias : 0.0

        let lunarBias = (profile.moonSign != nil && tags.celestial == "lunar")
            ? 6.0 + profile.natalPull
            : 0.0

        let total = nightlyRes + natalRes + catalogRes + tagAffinityScore
            + transitScore + phaseScore + elementAlign + modalityFit
            + rxBoost + personalPull + jitter + contrastBonus + lunarBias

        let role = profile.roleOrder.max(by: {
            TagAffinityTables.roleFit($0, tags: tags) < TagAffinityTables.roleFit($1, tags: tags)
        })

        let matchPct = min(99.9, max(1.0, total / 3.5)).roundedTo(1)

        return RankedSound(
            sound: sound,
            score: total.roundedTo(3),
            matchPercentage: matchPct,
            breakdown: ScoreBreakdown(
                nightlyResonance: nightlyRes.roundedTo(3),
                natalResonance: natalRes.roundedTo(3),
                tagAffinity: tagAffinityScore.roundedTo(3),
                transitResonance: transitScore.roundedTo(3),
                moonPhaseAffinity: phaseScore.roundedTo(3),
                personalizedVectorPull: personalPull.roundedTo(3),
                fingerprintJitter: jitter.roundedTo(3),
                contrastBonus: contrastBonus.roundedTo(3),
                notes: notes
            ),
            suggestedRole: role
        )
    }

    private func elementProduct(_ a: ElementVector, _ b: ElementVector) -> Double {
        (a.fire * b.fire + a.earth * b.earth + a.air * b.air + a.water * b.water) / 4.0
    }

    private func modalityCongruence(profile: PersonalSoundProfile, tags: SoundTags) -> Double {
        switch profile.modality {
        case .cardinal:
            if ["surging", "pulsing", "flowing"].contains(tags.motion) { return 1.3 }
            if tags.polarity == "active" { return 1.1 }
            if tags.rhythm == "steady" { return 0.4 }
            return 0.6
        case .fixed:
            if ["steady", "rhythmic", "pulse"].contains(tags.rhythm) { return 1.4 }
            if tags.motion == "static" || ["dense", "saturated"].contains(tags.density) { return 1.2 }
            if ["chaotic", "arrhythmic"].contains(tags.rhythm) { return 0.3 }
            return 0.6
        case .mutable:
            if ["diffuse", "crystalline", "granular"].contains(tags.texture) { return 1.3 }
            if ["drifting", "swirling", "oscillating"].contains(tags.motion) { return 1.3 }
            if ["irregular", "arrhythmic"].contains(tags.rhythm) { return 1.1 }
            return 0.6
        }
    }

    private func buildTransitAffinity(
        transits: [Transit],
        transitPull: Double
    ) -> [String: Double] {
        guard !transits.isEmpty else { return [:] }
        var out: [String: Double] = [:]
        let top = transits.sorted { $0.strength > $1.strength }.prefix(12)
        for t in top {
            let prefs = TagAffinityTables.planetTagPreferences(t.planet)
            let w = t.strength * (0.5 + transitPull * 0.5)
            for (tag, pref) in prefs {
                out[tag, default: 0] += pref * w
            }
            switch t.aspectType {
            case .square, .opposition:
                out["rough", default: 0] += 0.4 * w
                out["dense", default: 0] += 0.3 * w
                out["heavy", default: 0] += 0.25 * w
            case .trine, .sextile:
                out["smooth", default: 0] += 0.4 * w
                out["flowing", default: 0] += 0.35 * w
                out["light", default: 0] += 0.2 * w
            case .conjunction:
                out["saturated", default: 0] += 0.35 * w
                out["full", default: 0] += 0.25 * w
            }
            if t.planet == .moon {
                out["lunar", default: 0] += 0.8 * w
                out["water", default: 0] += 0.5 * w
            }
        }
        return out
    }

    /// Deterministic -1..1 jitter from fingerprint ⊕ soundId (Android-identical algorithm).
    func fingerprintJitter(fingerprint: Int64, soundId: String) -> Double {
        var h = fingerprint
        for u in soundId.unicodeScalars {
            h ^= Int64(u.value)
            h &*= 0x5DEECE66D
            h &+= 0xB
        }
        let unit = Double((UInt64(bitPattern: h) >> 17) & 0xFFFF) / 65535.0
        let amp = 0.55 + abs(sin(Double(fingerprint) * 1e-9)) * 0.45
        return (unit * 2.0 - 1.0) * amp
    }

    private func opposite(_ e: Element) -> Element {
        switch e {
        case .fire: return .water
        case .water: return .fire
        case .earth: return .air
        case .air: return .earth
        }
    }

    /// Pairwise stack diversity: higher = more similar (worse for diversity).
    func tagOverlap(_ a: SoundTags, _ b: SoundTags) -> Double {
        let av = Set(a.allValues())
        let bv = Set(b.allValues())
        let inter = Double(av.intersection(bv).count)
        let union = max(1.0, Double(av.union(bv).count))
        var penalty = inter / union
        if a.domain == b.domain { penalty += 0.35 }
        if a.celestial == b.celestial { penalty += 0.20 }
        if a.archetype == b.archetype { penalty += 0.15 }
        if a.motion == b.motion { penalty += 0.10 }
        return penalty
    }

    func cosineSimilarity(_ a: ElementVector, _ b: ElementVector) -> Double {
        let dot = a.fire * b.fire + a.earth * b.earth + a.air * b.air + a.water * b.water
        let magA = sqrt(a.fire * a.fire + a.earth * a.earth + a.air * a.air + a.water * a.water)
        let magB = sqrt(b.fire * b.fire + b.earth * b.earth + b.air * b.air + b.water * b.water)
        if magA == 0 || magB == 0 { return 0 }
        return dot / (magA * magB)
    }
}

// MARK: - Tag Vector Tables (shared with Android — keep values byte-identical)

struct TagVectorTables {
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

    static let rhythm: [String: ElementVector] = [
        "steady": ElementVector(fire: 0.0, earth: 3.0, air: 0.5, water: 1.5),
        "pulse": ElementVector(fire: 1.0, earth: 2.0, air: 1.0, water: 1.5),
        "irregular": ElementVector(fire: 2.0, earth: 0.0, air: 2.0, water: 1.5),
        "chaotic": ElementVector(fire: 3.0, earth: 0.0, air: 2.5, water: 0.5),
        "rhythmic": ElementVector(fire: 1.5, earth: 2.0, air: 1.0, water: 2.0),
        "arrhythmic": ElementVector(fire: 1.0, earth: 0.0, air: 2.0, water: 2.0)
    ]

    static let register: [String: ElementVector] = [
        "sub": ElementVector(fire: 0.0, earth: 3.0, air: 0.0, water: 2.0),
        "deep": ElementVector(fire: 0.0, earth: 2.5, air: 0.0, water: 1.5),
        "mid": ElementVector(fire: 1.0, earth: 1.5, air: 1.0, water: 1.0),
        "bright": ElementVector(fire: 1.5, earth: 0.5, air: 2.5, water: 0.0),
        "full": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "ultrasonic": ElementVector(fire: 0.5, earth: 0.0, air: 3.0, water: 0.0)
    ]

    static let context: [String: ElementVector] = [
        "nature": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "domestic": ElementVector(fire: 0.0, earth: 2.0, air: 0.5, water: 1.5),
        "abstract": ElementVector(fire: 0.5, earth: 0.0, air: 2.0, water: 1.0),
        "urban": ElementVector(fire: 1.5, earth: 1.0, air: 2.0, water: 0.5),
        "industrial": ElementVector(fire: 1.0, earth: 3.0, air: 1.5, water: 0.0),
        "spiritual": ElementVector(fire: 1.0, earth: 0.5, air: 2.0, water: 2.5)
    ]

    static let weight: [String: ElementVector] = [
        "ethereal": ElementVector(fire: 0.0, earth: 0.0, air: 2.0, water: 1.0),
        "light": ElementVector(fire: 0.0, earth: 0.0, air: 1.5, water: 1.5),
        "medium": ElementVector(fire: 1.0, earth: 1.5, air: 0.5, water: 0.5),
        "heavy": ElementVector(fire: 2.5, earth: 1.0, air: 1.0, water: 0.5),
        "massive": ElementVector(fire: 2.0, earth: 3.0, air: 0.0, water: 0.0)
    ]

    static let texture: [String: ElementVector] = [
        "smooth": ElementVector(fire: 1.0, earth: 2.5, air: 1.0, water: 3.0),
        "rough": ElementVector(fire: 3.5, earth: 3.5, air: 0.5, water: 1.0),
        "crystalline": ElementVector(fire: 2.5, earth: 1.0, air: 4.0, water: 1.5),
        "diffuse": ElementVector(fire: 1.0, earth: 1.0, air: 2.5, water: 3.0),
        "granular": ElementVector(fire: 2.0, earth: 2.0, air: 1.0, water: 1.0),
        "glassy": ElementVector(fire: 1.5, earth: 1.0, air: 3.5, water: 1.0),
        "metallic": ElementVector(fire: 2.0, earth: 3.0, air: 2.0, water: 0.0)
    ]

    static let motion: [String: ElementVector] = [
        "static": ElementVector(fire: 0.0, earth: 4.0, air: 0.0, water: 1.0),
        "flowing": ElementVector(fire: 1.0, earth: 0.0, air: 1.0, water: 4.0),
        "surging": ElementVector(fire: 4.5, earth: 0.0, air: 2.0, water: 1.0),
        "swirling": ElementVector(fire: 2.5, earth: 0.0, air: 4.0, water: 1.0),
        "oscillating": ElementVector(fire: 2.0, earth: 1.0, air: 3.0, water: 1.0),
        "drifting": ElementVector(fire: 1.0, earth: 0.5, air: 3.0, water: 2.5),
        "pulsing": ElementVector(fire: 2.5, earth: 0.5, air: 1.5, water: 2.0)
    ]

    static let density: [String: ElementVector] = [
        "vacuum": ElementVector(fire: 3.0, earth: 0.0, air: 2.5, water: 1.0),
        "sparse": ElementVector(fire: 2.5, earth: 0.0, air: 2.0, water: 1.0),
        "moderate": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "dense": ElementVector(fire: 1.0, earth: 3.0, air: 1.0, water: 2.0),
        "saturated": ElementVector(fire: 1.5, earth: 2.5, air: 2.0, water: 2.5)
    ]

    static let temperature: [String: ElementVector] = [
        "cold": ElementVector(fire: 0.0, earth: 3.0, air: 1.0, water: 2.0),
        "cool": ElementVector(fire: 0.5, earth: 2.0, air: 1.5, water: 2.0),
        "neutral": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "warm": ElementVector(fire: 2.5, earth: 1.0, air: 1.5, water: 1.0),
        "hot": ElementVector(fire: 4.0, earth: 0.5, air: 1.0, water: 0.0)
    ]

    static let polarity: [String: ElementVector] = [
        "active": ElementVector(fire: 3.0, earth: 1.0, air: 2.0, water: 0.5),
        "receptive": ElementVector(fire: 0.5, earth: 2.0, air: 1.0, water: 3.0),
        "balanced": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0),
        "neutral": ElementVector(fire: 1.0, earth: 1.0, air: 1.0, water: 1.0)
    ]

    static let celestial: [String: ElementVector] = [
        "solar": ElementVector(fire: 4.0, earth: 0.5, air: 1.0, water: 0.0),
        "lunar": ElementVector(fire: 0.0, earth: 1.0, air: 0.0, water: 4.0),
        "stellar": ElementVector(fire: 1.0, earth: 0.5, air: 3.0, water: 1.0),
        "planetary": ElementVector(fire: 1.5, earth: 1.5, air: 1.5, water: 1.5),
        "void": ElementVector(fire: 0.5, earth: 0.5, air: 0.5, water: 0.5)
    ]

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
