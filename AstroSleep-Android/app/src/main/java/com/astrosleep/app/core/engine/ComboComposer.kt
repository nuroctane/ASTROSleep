package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.AmbientLayer
import com.astrosleep.app.core.model.Combo
import com.astrosleep.app.core.model.ComboSource
import com.astrosleep.app.core.model.EQProfile
import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.NatalChart
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.OscillationConfig
import com.astrosleep.app.core.model.RankedSound
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SubscriptionTier
import com.astrosleep.app.core.model.Waveform
import com.astrosleep.app.core.model.roundedTo
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

/**
 * Builds multi-layer combos that are *structurally* different per user:
 * role-based seat assignment, diversity pressure, natal volume curves,
 * and chart-driven oscillation / EQ / speed — not just top-N by score.
 */
@Singleton
class ComboComposer @Inject constructor(
    private val tagEngine: TagEngine,
) {

    data class ComposeResult(
        val combo: Combo,
        val ranked: List<RankedSound>,
        val profile: PersonalSoundProfile,
        val selected: List<SelectedLayer>,
    )

    data class SelectedLayer(
        val ranked: RankedSound,
        val role: StackRole,
        val volume: Double,
        val playbackSpeed: Double,
    )

    fun compose(
        userId: String,
        sounds: List<Sound>,
        nightly: NightlyScoreResult,
        natalBaseScore: ElementVector,
        chart: NatalChart?,
        tier: SubscriptionTier,
        voiceId: String = "female",
    ): ComposeResult {
        val profile = PersonalSoundProfile.from(userId, chart, natalBaseScore)
        val ranked = tagEngine.rankSoundsPersonalized(
            sounds = sounds,
            nightly = nightly,
            profile = profile,
            natalBaseScore = natalBaseScore,
            chart = chart,
        )

        val maxLayers = tier.maxLayers
        val selected = pickDiverseRoleStack(ranked, profile, maxLayers)
        val layers = selected.mapIndexed { index, sel ->
            AmbientLayer(
                soundId = sel.ranked.sound.id,
                volume = sel.volume,
                playbackSpeed = sel.playbackSpeed,
                eq = eqFor(sel.ranked.sound, profile, sel.role),
                oscillation = oscillationFor(index, sel.role, profile, nightly.dominantElement),
            )
        }

        val moonName = nightly.moonPhase.displayName
        val signBit = profile.moonSign?.displayName ?: profile.dominantElement.displayName
        val combo = Combo(
            id = UUID.randomUUID().toString(),
            name = "$moonName · $signBit",
            source = ComboSource.AUTO,
            chartSnapshot = nightly.toSnapshot(),
            layers = layers,
            affirmationLayer = com.astrosleep.app.core.model.AffirmationLayer(voiceId = voiceId),
        )
        return ComposeResult(combo = combo, ranked = ranked, profile = profile, selected = selected)
    }

    /**
     * Walk the user's role order; for each seat, pick the highest-scoring sound
     * that fits the role and isn't too tag-similar to already-picked layers.
     */
    private fun pickDiverseRoleStack(
        ranked: List<RankedSound>,
        profile: PersonalSoundProfile,
        maxLayers: Int,
    ): List<SelectedLayer> {
        if (ranked.isEmpty() || maxLayers <= 0) return emptyList()

        val picked = mutableListOf<SelectedLayer>()
        val usedIds = mutableSetOf<String>()
        val roles = (profile.roleOrder + StackRole.entries).distinct().take(maxLayers)

        for (role in roles) {
            if (picked.size >= maxLayers) break
            val candidate = ranked
                .asSequence()
                .filter { it.sound.id !in usedIds }
                .map { rs ->
                    val roleFit = TagAffinityTables.roleFit(role, rs.sound.tags)
                    val diversityPenalty = picked.sumOf { prev ->
                        tagEngine.tagOverlap(prev.ranked.sound.tags, rs.sound.tags)
                    } * (8.0 * profile.diversityBias)
                    val seatScore = rs.score + roleFit * 6.5 - diversityPenalty
                    Triple(rs, roleFit, seatScore)
                }
                .maxByOrNull { it.third }
                ?: break

            val (rs, _, _) = candidate
            usedIds += rs.sound.id
            picked += SelectedLayer(
                ranked = rs,
                role = role,
                volume = 0.0, // filled below
                playbackSpeed = speedFor(role, profile),
            )
        }

        // Fallback: if roles failed to fill (tiny catalog), pad by raw rank
        if (picked.size < maxLayers) {
            for (rs in ranked) {
                if (picked.size >= maxLayers) break
                if (rs.sound.id in usedIds) continue
                usedIds += rs.sound.id
                picked += SelectedLayer(
                    ranked = rs,
                    role = StackRole.ACCENT,
                    volume = 0.0,
                    playbackSpeed = speedFor(StackRole.ACCENT, profile),
                )
            }
        }

        return assignVolumes(picked, profile)
    }

    private fun assignVolumes(
        layers: List<SelectedLayer>,
        profile: PersonalSoundProfile,
    ): List<SelectedLayer> {
        if (layers.isEmpty()) return layers
        // Role base gains
        val roleGain = mapOf(
            StackRole.BEDROCK to 1.15,
            StackRole.FOUNDATION to 1.25,
            StackRole.FLOW to 1.05,
            StackRole.TEXTURE to 0.85,
            StackRole.VEIL to 0.70,
            StackRole.SPARK to 0.55,
            StackRole.ACCENT to 0.65,
        )
        // Element taste: boost volumes of layers whose sound dominant matches profile
        val raw = layers.map { sel ->
            val vec = tagEngine.calculateTagVector(sel.ranked.sound.tags, profile.dimensionMultipliers)
            val elemBoost = when (vec.dominant()) {
                profile.dominantElement -> 1.20
                profile.secondaryElement -> 1.05
                else -> 0.90
            }
            val scoreWeight = max(0.05, sel.ranked.score)
            scoreWeight * (roleGain[sel.role] ?: 1.0) * elemBoost
        }
        val sum = raw.sum().coerceAtLeast(1e-6)
        // Master budget ~0.72–0.88 depending on user salt (some like denser beds)
        val budget = 0.72 + profile.salt01 * 0.16
        return layers.mapIndexed { i, sel ->
            val v = (raw[i] / sum) * budget
            // Floor/ceil so nothing vanishes or peels paint
            sel.copy(volume = v.coerceIn(0.06, 0.42).roundedTo(3))
        }
    }

    private fun speedFor(role: StackRole, profile: PersonalSoundProfile): Double {
        val base = when (role) {
            StackRole.BEDROCK, StackRole.FOUNDATION -> 0.92
            StackRole.FLOW -> 1.0
            StackRole.TEXTURE -> 1.05
            StackRole.VEIL -> 0.88
            StackRole.SPARK -> 1.12
            StackRole.ACCENT -> 1.0
        }
        // Mutable modalities tolerate more speed play; fixed stay near 1
        val modalitySpan = when (profile.modality) {
            com.astrosleep.app.core.model.Modality.MUTABLE -> 0.12
            com.astrosleep.app.core.model.Modality.CARDINAL -> 0.07
            com.astrosleep.app.core.model.Modality.FIXED -> 0.03
        }
        val wobble = (profile.salt01 - 0.5) * 2.0 * modalitySpan
        return (base + wobble).coerceIn(0.8, 1.2).roundedTo(3)
    }

    private fun eqFor(
        sound: Sound,
        profile: PersonalSoundProfile,
        role: StackRole,
    ): EQProfile {
        val reg = EQProfile.profileForRegister(sound.tags.register)
        // Chart tilt: earth/fixed → more bass; air/mutable → more treble
        val bassTilt = when (profile.dominantElement) {
            Element.EARTH -> 0.12
            Element.WATER -> 0.06
            Element.FIRE -> -0.04
            Element.AIR -> -0.08
        }
        val trebleTilt = when (profile.dominantElement) {
            Element.AIR -> 0.12
            Element.FIRE -> 0.08
            Element.WATER -> -0.04
            Element.EARTH -> -0.08
        }
        val roleBass = when (role) {
            StackRole.BEDROCK -> 0.10
            StackRole.SPARK, StackRole.VEIL -> -0.08
            else -> 0.0
        }
        return EQProfile(
            bass = (reg.bass + bassTilt + roleBass).coerceIn(0.05, 0.98),
            mid = reg.mid.coerceIn(0.05, 0.98),
            treble = (reg.treble + trebleTilt).coerceIn(0.05, 0.98),
        )
    }

    private fun oscillationFor(
        index: Int,
        role: StackRole,
        profile: PersonalSoundProfile,
        nightDominant: Element,
    ): OscillationConfig? {
        // Earth-fixed users often want static beds
        if (profile.dominantElement == Element.EARTH &&
            profile.modality == com.astrosleep.app.core.model.Modality.FIXED &&
            role in setOf(StackRole.BEDROCK, StackRole.FOUNDATION)
        ) {
            return null
        }

        val enabled = when (role) {
            StackRole.FLOW, StackRole.VEIL -> true
            StackRole.FOUNDATION -> index == 0 || profile.modality != com.astrosleep.app.core.model.Modality.FIXED
            StackRole.TEXTURE -> profile.modality == com.astrosleep.app.core.model.Modality.MUTABLE
            StackRole.SPARK -> true
            StackRole.ACCENT -> index <= 2
            StackRole.BEDROCK -> false
        }
        if (!enabled) return null

        val waveform = when {
            profile.dominantElement == Element.WATER || nightDominant == Element.WATER -> Waveform.SINE
            profile.dominantElement == Element.AIR -> Waveform.PERLIN
            profile.dominantElement == Element.FIRE -> Waveform.TRIANGLE
            else -> Waveform.SINE
        }

        val period = when (role) {
            StackRole.FLOW -> 38.0 + profile.salt01 * 24.0
            StackRole.VEIL -> 55.0 + profile.salt01 * 30.0
            StackRole.SPARK -> 10.0 + profile.salt01 * 12.0
            StackRole.TEXTURE -> 16.0 + profile.salt01 * 14.0
            else -> 28.0 + profile.salt01 * 20.0
        }

        val depth = 0.12 + profile.contrastBias * 0.18
        val center = 0.65
        return OscillationConfig(
            enabled = true,
            waveform = waveform,
            periodSeconds = period.roundedTo(1),
            minVolume = (center - depth).coerceIn(0.25, 0.7),
            maxVolume = (center + depth).coerceIn(0.55, 0.95),
            phaseOffset = (index * (0.19 + profile.salt01 * 0.17)).roundedTo(3),
        )
    }
}
