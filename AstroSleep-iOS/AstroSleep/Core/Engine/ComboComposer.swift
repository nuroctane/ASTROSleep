import Foundation

// MARK: - ComboComposer (Tag Engine v4 — parity with Android ComboComposer.kt)

/// Builds multi-layer combos that are structurally different per user:
/// role-based seat assignment, diversity pressure, natal volume curves,
/// and chart-driven oscillation / EQ / speed — not just top-N by score.
final class ComboComposer {
    static let shared = ComboComposer()

    private let tagEngine = TagEngine.shared

    struct ComposeResult {
        let combo: Combo
        let ranked: [RankedSound]
        let profile: PersonalSoundProfile
        let selected: [SelectedLayer]
    }

    struct SelectedLayer {
        let ranked: RankedSound
        let role: StackRole
        var volume: Double
        let playbackSpeed: Double
    }

    private init() {}

    func compose(
        userId: String,
        sounds: [Sound],
        nightly: NightlyScoreResult,
        natalBaseScore: ElementVector,
        chart: NatalChart?,
        tier: SubscriptionTier,
        voiceId: String = "female"
    ) -> ComposeResult {
        let profile = PersonalSoundProfile.from(
            userId: userId,
            chart: chart,
            baseScore: natalBaseScore
        )
        let ranked = tagEngine.rankSoundsPersonalized(
            sounds: sounds,
            nightly: nightly,
            profile: profile,
            natalBaseScore: natalBaseScore,
            chart: chart
        )

        let maxLayers = tier.maxLayers
        let selected = pickDiverseRoleStack(ranked: ranked, profile: profile, maxLayers: maxLayers)
        let layers = selected.enumerated().map { index, sel in
            AmbientLayer(
                soundId: sel.ranked.sound.id,
                volume: sel.volume,
                playbackSpeed: sel.playbackSpeed,
                eq: eqFor(sound: sel.ranked.sound, profile: profile, role: sel.role),
                oscillation: oscillationFor(
                    index: index,
                    role: sel.role,
                    profile: profile,
                    nightDominant: nightly.dominantElement
                )
            )
        }

        let moonName = nightly.moonPhase.displayName
        let signBit = profile.moonSign?.displayName ?? profile.dominantElement.displayName
        let combo = Combo(
            id: UUID().uuidString,
            name: "\(moonName) · \(signBit)",
            createdAt: Date(),
            source: .auto,
            chartSnapshot: nightly.toSnapshot(),
            layers: layers,
            affirmationLayer: AffirmationLayer.default(voiceId: voiceId),
            isReadOnly: false
        )

        return ComposeResult(combo: combo, ranked: ranked, profile: profile, selected: selected)
    }

    // MARK: - Role stack

    private func pickDiverseRoleStack(
        ranked: [RankedSound],
        profile: PersonalSoundProfile,
        maxLayers: Int
    ) -> [SelectedLayer] {
        guard !ranked.isEmpty, maxLayers > 0 else { return [] }

        var picked: [SelectedLayer] = []
        var usedIds = Set<String>()
        var roles: [StackRole] = []
        for r in profile.roleOrder + StackRole.allCases {
            if !roles.contains(r) { roles.append(r) }
            if roles.count >= maxLayers { break }
        }

        for role in roles {
            if picked.count >= maxLayers { break }
            var best: (RankedSound, Double)?
            for rs in ranked where !usedIds.contains(rs.sound.id) {
                let roleFit = TagAffinityTables.roleFit(role, tags: rs.sound.tags)
                let diversityPenalty = picked.reduce(0.0) { acc, prev in
                    acc + tagEngine.tagOverlap(prev.ranked.sound.tags, rs.sound.tags)
                } * (8.0 * profile.diversityBias)
                let seatScore = rs.score + roleFit * 6.5 - diversityPenalty
                if best == nil || seatScore > best!.1 {
                    best = (rs, seatScore)
                }
            }
            guard let (rs, _) = best else { break }
            usedIds.insert(rs.sound.id)
            picked.append(SelectedLayer(
                ranked: rs,
                role: role,
                volume: 0,
                playbackSpeed: speedFor(role: role, profile: profile)
            ))
        }

        if picked.count < maxLayers {
            for rs in ranked {
                if picked.count >= maxLayers { break }
                if usedIds.contains(rs.sound.id) { continue }
                usedIds.insert(rs.sound.id)
                picked.append(SelectedLayer(
                    ranked: rs,
                    role: .accent,
                    volume: 0,
                    playbackSpeed: speedFor(role: .accent, profile: profile)
                ))
            }
        }

        return assignVolumes(layers: picked, profile: profile)
    }

    private func assignVolumes(
        layers: [SelectedLayer],
        profile: PersonalSoundProfile
    ) -> [SelectedLayer] {
        guard !layers.isEmpty else { return layers }
        let roleGain: [StackRole: Double] = [
            .bedrock: 1.15,
            .foundation: 1.25,
            .flow: 1.05,
            .texture: 0.85,
            .veil: 0.70,
            .spark: 0.55,
            .accent: 0.65
        ]
        let raw: [Double] = layers.map { sel in
            let vec = tagEngine.calculateTagVector(
                tags: sel.ranked.sound.tags,
                dimensionMultipliers: profile.dimensionMultipliers
            )
            let elemBoost: Double
            switch vec.dominant() {
            case profile.dominantElement: elemBoost = 1.20
            case profile.secondaryElement: elemBoost = 1.05
            default: elemBoost = 0.90
            }
            let scoreWeight = max(0.05, sel.ranked.score)
            return scoreWeight * (roleGain[sel.role] ?? 1.0) * elemBoost
        }
        let sum = max(1e-6, raw.reduce(0, +))
        let budget = 0.72 + profile.salt01 * 0.16
        return layers.enumerated().map { i, sel in
            var copy = sel
            let v = (raw[i] / sum) * budget
            copy.volume = min(0.42, max(0.06, v)).roundedTo(3)
            return copy
        }
    }

    private func speedFor(role: StackRole, profile: PersonalSoundProfile) -> Double {
        let base: Double
        switch role {
        case .bedrock, .foundation: base = 0.92
        case .flow: base = 1.0
        case .texture: base = 1.05
        case .veil: base = 0.88
        case .spark: base = 1.12
        case .accent: base = 1.0
        }
        let modalitySpan: Double
        switch profile.modality {
        case .mutable: modalitySpan = 0.12
        case .cardinal: modalitySpan = 0.07
        case .fixed: modalitySpan = 0.03
        }
        let wobble = (profile.salt01 - 0.5) * 2.0 * modalitySpan
        return min(1.2, max(0.8, base + wobble)).roundedTo(3)
    }

    private func eqFor(sound: Sound, profile: PersonalSoundProfile, role: StackRole) -> EQProfile {
        let reg = EQProfile.profile(forRegister: sound.tags.register)
        let bassTilt: Double
        switch profile.dominantElement {
        case .earth: bassTilt = 0.12
        case .water: bassTilt = 0.06
        case .fire: bassTilt = -0.04
        case .air: bassTilt = -0.08
        }
        let trebleTilt: Double
        switch profile.dominantElement {
        case .air: trebleTilt = 0.12
        case .fire: trebleTilt = 0.08
        case .water: trebleTilt = -0.04
        case .earth: trebleTilt = -0.08
        }
        let roleBass: Double
        switch role {
        case .bedrock: roleBass = 0.10
        case .spark, .veil: roleBass = -0.08
        default: roleBass = 0.0
        }
        return EQProfile(
            bass: min(0.98, max(0.05, reg.bass + bassTilt + roleBass)),
            mid: min(0.98, max(0.05, reg.mid)),
            treble: min(0.98, max(0.05, reg.treble + trebleTilt))
        )
    }

    private func oscillationFor(
        index: Int,
        role: StackRole,
        profile: PersonalSoundProfile,
        nightDominant: Element
    ) -> OscillationConfig? {
        if profile.dominantElement == .earth
            && profile.modality == .fixed
            && (role == .bedrock || role == .foundation) {
            return nil
        }

        let enabled: Bool
        switch role {
        case .flow, .veil: enabled = true
        case .foundation: enabled = index == 0 || profile.modality != .fixed
        case .texture: enabled = profile.modality == .mutable
        case .spark: enabled = true
        case .accent: enabled = index <= 2
        case .bedrock: enabled = false
        }
        guard enabled else { return nil }

        let waveform: Waveform
        if profile.dominantElement == .water || nightDominant == .water {
            waveform = .sine
        } else if profile.dominantElement == .air {
            waveform = .perlin
        } else if profile.dominantElement == .fire {
            waveform = .triangle
        } else {
            waveform = .sine
        }

        let period: Double
        switch role {
        case .flow: period = 38.0 + profile.salt01 * 24.0
        case .veil: period = 55.0 + profile.salt01 * 30.0
        case .spark: period = 10.0 + profile.salt01 * 12.0
        case .texture: period = 16.0 + profile.salt01 * 14.0
        default: period = 28.0 + profile.salt01 * 20.0
        }

        let depth = 0.12 + profile.contrastBias * 0.18
        let center = 0.65
        return OscillationConfig(
            enabled: true,
            waveform: waveform,
            periodSeconds: period.roundedTo(1),
            minVolume: min(0.7, max(0.25, center - depth)),
            maxVolume: min(0.95, max(0.55, center + depth)),
            phaseOffset: (Double(index) * (0.19 + profile.salt01 * 0.17)).roundedTo(3)
        )
    }
}
