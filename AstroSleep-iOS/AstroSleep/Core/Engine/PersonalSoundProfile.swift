import Foundation

// MARK: - Stack roles (parity with Android StackRole)

/// Layer seats used when stacking a personalized combo.
enum StackRole: String, CaseIterable, Codable {
    /// Deep bed / sub-weight anchor
    case bedrock
    /// Primary ambient body
    case foundation
    /// Flowing / liquid mid layer
    case flow
    /// Textural / grain interest
    case texture
    /// Soft mask / ethereal cover
    case veil
    /// Bright accent / sparkle
    case spark
    /// Character accent / secondary motif
    case accent
}

// MARK: - PersonalSoundProfile (Tag Engine v4 — parity with Android)

/// Per-user sonic fingerprint derived from natal chart + stable user id.
/// Two different birth charts (or same chart, different user salt) produce
/// distinct dimension weights, tag affinities, stacking roles, and rank jitter.
struct PersonalSoundProfile {
    let userId: String
    let fingerprint: Int64
    /// Multipliers applied to the 12 tag-dimension weights (default 1.0).
    let dimensionMultipliers: [String: Double]
    /// Preferred tag values → affinity strength.
    let tagAffinities: [String: Double]
    let natalPull: Double
    let nightlyPull: Double
    let transitPull: Double
    let diversityBias: Double
    let contrastBias: Double
    let roleOrder: [StackRole]
    let dominantElement: Element
    let secondaryElement: Element
    let modality: Modality
    let moonSign: Sign?
    let sunSign: Sign?
    let risingSign: Sign?
    /// Stable 0..1 salt used for deterministic micro-jitter (never random).
    let salt01: Double

    private static let allDimensions = [
        "domain", "rhythm", "register", "context", "weight",
        "texture", "motion", "density", "temperature",
        "polarity", "celestial", "archetype"
    ]

    static func from(
        userId: String,
        chart: NatalChart?,
        baseScore: ElementVector
    ) -> PersonalSoundProfile {
        let fp = fingerprint(userId: userId, chart: chart, baseScore: baseScore)
        let salt01 = Double((UInt64(bitPattern: fp) >> 11) & 0xFFFF) / 65535.0
        let saltB = Double((UInt64(bitPattern: fp) >> 27) & 0xFFFF) / 65535.0
        let saltC = Double((UInt64(bitPattern: fp) >> 43) & 0xFFFF) / 65535.0

        let moon = chart?.moonSign
        let sun = chart?.sunSign
        let rising = chart?.ascendant
        let modality = chart?.dominantModality ?? .cardinal
        let dominant = chart?.dominantElement ?? baseScore.dominant()
        let secondary = secondaryElement(base: baseScore, dominant: dominant)

        var dimMult: [String: Double] = [:]
        for d in allDimensions { dimMult[d] = 1.0 }

        switch dominant {
        case .water:
            bump(&dimMult, "domain", 1.45)
            bump(&dimMult, "motion", 1.35)
            bump(&dimMult, "celestial", 1.40)
            bump(&dimMult, "archetype", 1.25)
            bump(&dimMult, "density", 1.15)
            bump(&dimMult, "register", 0.85)
        case .fire:
            bump(&dimMult, "domain", 1.40)
            bump(&dimMult, "temperature", 1.50)
            bump(&dimMult, "polarity", 1.35)
            bump(&dimMult, "motion", 1.30)
            bump(&dimMult, "texture", 1.15)
            bump(&dimMult, "density", 0.80)
        case .air:
            bump(&dimMult, "register", 1.45)
            bump(&dimMult, "texture", 1.40)
            bump(&dimMult, "rhythm", 1.25)
            bump(&dimMult, "context", 1.20)
            bump(&dimMult, "celestial", 1.15)
            bump(&dimMult, "weight", 0.80)
        case .earth:
            bump(&dimMult, "weight", 1.50)
            bump(&dimMult, "density", 1.40)
            bump(&dimMult, "rhythm", 1.35)
            bump(&dimMult, "texture", 1.20)
            bump(&dimMult, "motion", 0.75)
            bump(&dimMult, "temperature", 0.90)
        }

        switch modality {
        case .cardinal:
            bump(&dimMult, "motion", 1.25)
            bump(&dimMult, "polarity", 1.20)
            bump(&dimMult, "rhythm", 0.90)
        case .fixed:
            bump(&dimMult, "rhythm", 1.35)
            bump(&dimMult, "density", 1.25)
            bump(&dimMult, "motion", 0.80)
        case .mutable:
            bump(&dimMult, "texture", 1.30)
            bump(&dimMult, "register", 1.20)
            bump(&dimMult, "context", 1.15)
        }

        if let risingEl = rising?.element {
            switch risingEl {
            case .fire: bump(&dimMult, "context", 1.15)
            case .earth: bump(&dimMult, "weight", 1.20)
            case .air: bump(&dimMult, "register", 1.20)
            case .water: bump(&dimMult, "celestial", 1.15)
            }
        }

        for (i, dim) in allDimensions.enumerated() {
            let wave = sin((salt01 + Double(i) * 0.17) * .pi * 2.0)
            bump(&dimMult, dim, 1.0 + wave * 0.12)
        }

        var affinities: [String: Double] = [:]
        func prefer(_ tag: String, _ strength: Double) {
            affinities[tag, default: 0] += strength
        }

        if let moon {
            for (tag, w) in TagAffinityTables.signTagPreferences(moon) {
                prefer(tag, w * 1.6)
            }
        }
        if let sun {
            for (tag, w) in TagAffinityTables.signTagPreferences(sun) {
                prefer(tag, w * 0.9)
            }
        }
        if let rising {
            for (tag, w) in TagAffinityTables.signTagPreferences(rising) {
                prefer(tag, w * 0.7)
            }
        }

        if let chart {
            for placement in chart.placements {
                let planetWeight = placement.planet.baseScoreWeight
                for (tag, w) in TagAffinityTables.planetTagPreferences(placement.planet) {
                    prefer(tag, w * planetWeight * 0.35)
                }
                for (tag, w) in TagAffinityTables.signTagPreferences(placement.sign) {
                    prefer(tag, w * planetWeight * 0.12)
                }
                if placement.isRetrograde {
                    prefer("arrhythmic", 0.25 * planetWeight)
                    prefer("shadow", 0.20 * planetWeight)
                    prefer("void", 0.15 * planetWeight)
                }
            }
            for sign in chart.stelliums {
                for (tag, w) in TagAffinityTables.signTagPreferences(sign) {
                    prefer(tag, w * 1.8)
                }
            }
        }

        for (tag, w) in TagAffinityTables.elementTagPreferences(dominant) {
            prefer(tag, w * 1.1)
        }
        for (tag, w) in TagAffinityTables.elementTagPreferences(secondary) {
            prefer(tag, w * 0.55)
        }

        let signatureTags = TagAffinityTables.signaturePool
        let sigCount = 4 + Int(abs(fp % 4))
        for i in 0..<sigCount {
            let mixed = fp ^ (Int64(i) &* 0x9E3779B9)
            let idx = abs(Int(mixed)) % signatureTags.count
            prefer(signatureTags[idx], 0.35 + saltB * 0.55)
        }

        let natalPull = (0.55 + salt01 * 0.9 + {
            switch modality {
            case .fixed: return 0.25
            case .cardinal: return 0.10
            case .mutable: return 0.0
            }
        }()).clamped(to: 0.4...1.85)

        let nightlyPull = (0.70 + saltB * 0.75 + {
            switch dominant {
            case .water, .air: return 0.15
            default: return 0.0
            }
        }()).clamped(to: 0.5...1.85)

        let transitPull = (0.45 + saltC * 0.9).clamped(to: 0.3...1.65)
        let diversityBias = (0.55 + saltB * 0.7 + (modality == .mutable ? 0.25 : 0.0))
            .clamped(to: 0.35...1.6)
        let contrastBias = (0.25 + saltC * 0.65 + (modality == .cardinal ? 0.2 : 0.0))
            .clamped(to: 0.1...1.0)

        let roleOrder = buildRoleOrder(dominant: dominant, modality: modality, salt: salt01)

        let clampedDims = dimMult.mapValues { $0.clamped(to: 0.45...2.4) }

        return PersonalSoundProfile(
            userId: userId,
            fingerprint: fp,
            dimensionMultipliers: clampedDims,
            tagAffinities: affinities,
            natalPull: natalPull,
            nightlyPull: nightlyPull,
            transitPull: transitPull,
            diversityBias: diversityBias,
            contrastBias: contrastBias,
            roleOrder: roleOrder,
            dominantElement: dominant,
            secondaryElement: secondary,
            modality: modality,
            moonSign: moon,
            sunSign: sun,
            risingSign: rising,
            salt01: salt01
        )
    }

    private static func bump(_ map: inout [String: Double], _ key: String, _ factor: Double) {
        map[key] = (map[key] ?? 1.0) * factor
    }

    private static func secondaryElement(base: ElementVector, dominant: Element) -> Element {
        let pairs: [(Element, Double)] = [
            (.fire, base.fire), (.earth, base.earth), (.air, base.air), (.water, base.water)
        ].sorted { $0.1 > $1.1 }
        return pairs.first { $0.0 != dominant }?.0 ?? .earth
    }

    private static func buildRoleOrder(
        dominant: Element,
        modality: Modality,
        salt: Double
    ) -> [StackRole] {
        let base: [StackRole]
        switch dominant {
        case .water:
            base = [.foundation, .flow, .texture, .veil, .accent, .spark, .bedrock]
        case .fire:
            base = [.bedrock, .spark, .texture, .accent, .foundation, .flow, .veil]
        case .air:
            base = [.veil, .texture, .spark, .flow, .accent, .foundation, .bedrock]
        case .earth:
            base = [.bedrock, .foundation, .texture, .flow, .accent, .veil, .spark]
        }
        let rotateBase: Int
        switch modality {
        case .cardinal: rotateBase = 0
        case .fixed: rotateBase = 1
        case .mutable: rotateBase = 2
        }
        let rotate = (rotateBase + Int(salt * 3)) % base.count
        return Array(base[rotate...]) + Array(base[..<rotate])
    }

    /// Stable 64-bit fingerprint from user id + chart geometry.
    /// Same inputs always → same profile; different charts/ids diverge hard.
    /// Algorithm matches Android `PersonalSoundProfile.fingerprint` (FNV-1a 64).
    static func fingerprint(
        userId: String,
        chart: NatalChart?,
        baseScore: ElementVector
    ) -> Int64 {
        var h: UInt64 = 0xCBF29CE484222325
        func mix(_ v: Int64) {
            h ^= UInt64(bitPattern: v)
            h &*= 0x100000001B3
        }
        func mixStr(_ s: String) {
            for u in s.unicodeScalars {
                mix(Int64(u.value))
            }
        }
        mixStr(userId)
        mix(Int64(baseScore.fire * 1000))
        mix(Int64(baseScore.earth * 1000))
        mix(Int64(baseScore.air * 1000))
        mix(Int64(baseScore.water * 1000))
        if let chart {
            for p in chart.placements.sorted(by: { $0.planet.caseIndex < $1.planet.caseIndex }) {
                mix(Int64(p.planet.caseIndex))
                mix(Int64(p.sign.caseIndex))
                mix(Int64(p.degree * 100))
                mix(p.isRetrograde ? 1 : 0)
            }
            if let asc = chart.ascendant {
                mix(Int64(asc.caseIndex + 100))
            }
            for s in chart.stelliums {
                mix(Int64(s.caseIndex + 200))
            }
            mix(Int64(chart.dominantModality.caseIndex + 300))
        }
        return Int64(bitPattern: h)
    }
}

// MARK: - Case indices (declaration order = Kotlin ordinal)

private extension Planet {
    var caseIndex: Int { Planet.allCases.firstIndex(of: self) ?? 0 }
}

private extension Sign {
    var caseIndex: Int { Sign.allCases.firstIndex(of: self) ?? 0 }
}

private extension Modality {
    var caseIndex: Int { Modality.allCases.firstIndex(of: self) ?? 0 }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
