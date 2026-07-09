package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.Modality
import com.astrosleep.app.core.model.NatalChart
import com.astrosleep.app.core.model.Planet
import com.astrosleep.app.core.model.Sign
import kotlin.math.abs

/**
 * Per-user sonic fingerprint derived from natal chart + stable user id.
 * Two different birth charts (or even same chart, different user salt) produce
 * distinct dimension weights, tag affinities, stacking roles, and rank jitter.
 */
data class PersonalSoundProfile(
    val userId: String,
    val fingerprint: Long,
    /** Multipliers applied to the 12 tag-dimension weights (default 1.0). */
    val dimensionMultipliers: Map<String, Double>,
    /** Preferred tag values → affinity strength (0..1+, can exceed 1 for strong pulls). */
    val tagAffinities: Map<String, Double>,
    /** How strongly natal base score should pull ranking (0.4–1.8). */
    val natalPull: Double,
    /** How strongly nightly sky should pull ranking (0.5–1.8). */
    val nightlyPull: Double,
    /** How strongly active transits reshape tag affinity (0.3–1.6). */
    val transitPull: Double,
    /** Diversity pressure when stacking layers (higher = less tag collision). */
    val diversityBias: Double,
    /** Prefer complementary opposite-element accents (0–1). */
    val contrastBias: Double,
    /** Preferred stacking roles order for layers. */
    val roleOrder: List<StackRole>,
    val dominantElement: Element,
    val secondaryElement: Element,
    val modality: Modality,
    val moonSign: Sign?,
    val sunSign: Sign?,
    val risingSign: Sign?,
    /** Stable 0..1 salt used for deterministic micro-jitter (never random). */
    val salt01: Double,
) {
    companion object {
        private val ALL_DIMENSIONS = listOf(
            "domain", "rhythm", "register", "context", "weight",
            "texture", "motion", "density", "temperature",
            "polarity", "celestial", "archetype",
        )

        fun from(
            userId: String,
            chart: NatalChart?,
            baseScore: ElementVector,
        ): PersonalSoundProfile {
            val fp = fingerprint(userId, chart, baseScore)
            val salt01 = ((fp ushr 11) and 0xFFFFL).toDouble() / 65535.0
            val saltB = ((fp ushr 27) and 0xFFFFL).toDouble() / 65535.0
            val saltC = ((fp ushr 43) and 0xFFFFL).toDouble() / 65535.0

            val moon = chart?.moonSign
            val sun = chart?.sunSign
            val rising = chart?.ascendant
            val modality = chart?.dominantModality ?: Modality.CARDINAL
            val dominant = chart?.dominantElement ?: baseScore.dominant()
            val secondary = secondaryElement(baseScore, dominant)

            val dimMult = mutableMapOf<String, Double>().apply {
                ALL_DIMENSIONS.forEach { this[it] = 1.0 }
            }

            // Element → dimension emphasis
            when (dominant) {
                Element.WATER -> {
                    bump(dimMult, "domain", 1.45)
                    bump(dimMult, "motion", 1.35)
                    bump(dimMult, "celestial", 1.40)
                    bump(dimMult, "archetype", 1.25)
                    bump(dimMult, "density", 1.15)
                    bump(dimMult, "register", 0.85)
                }
                Element.FIRE -> {
                    bump(dimMult, "domain", 1.40)
                    bump(dimMult, "temperature", 1.50)
                    bump(dimMult, "polarity", 1.35)
                    bump(dimMult, "motion", 1.30)
                    bump(dimMult, "texture", 1.15)
                    bump(dimMult, "density", 0.80)
                }
                Element.AIR -> {
                    bump(dimMult, "register", 1.45)
                    bump(dimMult, "texture", 1.40)
                    bump(dimMult, "rhythm", 1.25)
                    bump(dimMult, "context", 1.20)
                    bump(dimMult, "celestial", 1.15)
                    bump(dimMult, "weight", 0.80)
                }
                Element.EARTH -> {
                    bump(dimMult, "weight", 1.50)
                    bump(dimMult, "density", 1.40)
                    bump(dimMult, "rhythm", 1.35)
                    bump(dimMult, "texture", 1.20)
                    bump(dimMult, "motion", 0.75)
                    bump(dimMult, "temperature", 0.90)
                }
            }

            // Modality reshapes motion/rhythm priority
            when (modality) {
                Modality.CARDINAL -> {
                    bump(dimMult, "motion", 1.25)
                    bump(dimMult, "polarity", 1.20)
                    bump(dimMult, "rhythm", 0.90)
                }
                Modality.FIXED -> {
                    bump(dimMult, "rhythm", 1.35)
                    bump(dimMult, "density", 1.25)
                    bump(dimMult, "motion", 0.80)
                }
                Modality.MUTABLE -> {
                    bump(dimMult, "texture", 1.30)
                    bump(dimMult, "register", 1.20)
                    bump(dimMult, "context", 1.15)
                }
            }

            // Rising sign tweaks context/register (how the world "lands" on them)
            when (rising?.element) {
                Element.FIRE -> bump(dimMult, "context", 1.15)
                Element.EARTH -> bump(dimMult, "weight", 1.20)
                Element.AIR -> bump(dimMult, "register", 1.20)
                Element.WATER -> bump(dimMult, "celestial", 1.15)
                null -> Unit
            }

            // Per-user salt micro-skew so twins with same chart still diverge slightly
            ALL_DIMENSIONS.forEachIndexed { i, dim ->
                val wave = kotlin.math.sin((salt01 + i * 0.17) * Math.PI * 2.0)
                bump(dimMult, dim, 1.0 + wave * 0.12)
            }

            val affinities = mutableMapOf<String, Double>()
            fun prefer(tag: String, strength: Double) {
                affinities[tag] = (affinities[tag] ?: 0.0) + strength
            }

            // Moon sign is the sleep-critical axis
            moon?.let { sign ->
                TagAffinityTables.signTagPreferences(sign).forEach { (tag, w) -> prefer(tag, w * 1.6) }
            }
            sun?.let { sign ->
                TagAffinityTables.signTagPreferences(sign).forEach { (tag, w) -> prefer(tag, w * 0.9) }
            }
            rising?.let { sign ->
                TagAffinityTables.signTagPreferences(sign).forEach { (tag, w) -> prefer(tag, w * 0.7) }
            }

            // Planet placements inject targeted tag pulls
            chart?.placements?.forEach { placement ->
                val planetWeight = placement.planet.baseScoreWeight
                TagAffinityTables.planetTagPreferences(placement.planet).forEach { (tag, w) ->
                    prefer(tag, w * planetWeight * 0.35)
                }
                TagAffinityTables.signTagPreferences(placement.sign).forEach { (tag, w) ->
                    prefer(tag, w * planetWeight * 0.12)
                }
                if (placement.isRetrograde) {
                    prefer("arrhythmic", 0.25 * planetWeight)
                    prefer("shadow", 0.20 * planetWeight)
                    prefer("void", 0.15 * planetWeight)
                }
            }

            // Stellium = hard push toward that sign's sonic palette
            chart?.stelliums?.forEach { sign ->
                TagAffinityTables.signTagPreferences(sign).forEach { (tag, w) ->
                    prefer(tag, w * 1.8)
                }
            }

            // Dominant element palette
            TagAffinityTables.elementTagPreferences(dominant).forEach { (tag, w) ->
                prefer(tag, w * 1.1)
            }
            TagAffinityTables.elementTagPreferences(secondary).forEach { (tag, w) ->
                prefer(tag, w * 0.55)
            }

            // User-id salt: inject a few "signature" tags so every account is unique
            val signatureTags = TagAffinityTables.signaturePool
            val sigCount = 4 + (fp % 4).toInt()
            repeat(sigCount) { i ->
                val idx = abs((fp xor (i.toLong() * 0x9E3779B9L)).toInt()) % signatureTags.size
                prefer(signatureTags[idx], 0.35 + saltB * 0.55)
            }

            val natalPull = (0.55 + salt01 * 0.9 + when (modality) {
                Modality.FIXED -> 0.25
                Modality.CARDINAL -> 0.10
                Modality.MUTABLE -> 0.0
            }).coerceIn(0.4, 1.85)

            val nightlyPull = (0.70 + saltB * 0.75 + when (dominant) {
                Element.WATER, Element.AIR -> 0.15
                else -> 0.0
            }).coerceIn(0.5, 1.85)

            val transitPull = (0.45 + saltC * 0.9).coerceIn(0.3, 1.65)
            val diversityBias = (0.55 + saltB * 0.7 + if (modality == Modality.MUTABLE) 0.25 else 0.0)
                .coerceIn(0.35, 1.6)
            val contrastBias = (0.25 + saltC * 0.65 + if (modality == Modality.CARDINAL) 0.2 else 0.0)
                .coerceIn(0.1, 1.0)

            val roleOrder = buildRoleOrder(dominant, modality, salt01)

            return PersonalSoundProfile(
                userId = userId,
                fingerprint = fp,
                dimensionMultipliers = dimMult.mapValues { it.value.coerceIn(0.45, 2.4) },
                tagAffinities = affinities,
                natalPull = natalPull,
                nightlyPull = nightlyPull,
                transitPull = transitPull,
                diversityBias = diversityBias,
                contrastBias = contrastBias,
                roleOrder = roleOrder,
                dominantElement = dominant,
                secondaryElement = secondary,
                modality = modality,
                moonSign = moon,
                sunSign = sun,
                risingSign = rising,
                salt01 = salt01,
            )
        }

        private fun bump(map: MutableMap<String, Double>, key: String, factor: Double) {
            map[key] = (map[key] ?: 1.0) * factor
        }

        private fun secondaryElement(base: ElementVector, dominant: Element): Element {
            val pairs = listOf(
                Element.FIRE to base.fire,
                Element.EARTH to base.earth,
                Element.AIR to base.air,
                Element.WATER to base.water,
            ).sortedByDescending { it.second }
            return pairs.firstOrNull { it.first != dominant }?.first ?: Element.EARTH
        }

        private fun buildRoleOrder(
            dominant: Element,
            modality: Modality,
            salt: Double,
        ): List<StackRole> {
            val base = when (dominant) {
                Element.WATER -> listOf(
                    StackRole.FOUNDATION, StackRole.FLOW, StackRole.TEXTURE,
                    StackRole.VEIL, StackRole.ACCENT, StackRole.SPARK, StackRole.BEDROCK,
                )
                Element.FIRE -> listOf(
                    StackRole.BEDROCK, StackRole.SPARK, StackRole.TEXTURE,
                    StackRole.ACCENT, StackRole.FOUNDATION, StackRole.FLOW, StackRole.VEIL,
                )
                Element.AIR -> listOf(
                    StackRole.VEIL, StackRole.TEXTURE, StackRole.SPARK,
                    StackRole.FLOW, StackRole.ACCENT, StackRole.FOUNDATION, StackRole.BEDROCK,
                )
                Element.EARTH -> listOf(
                    StackRole.BEDROCK, StackRole.FOUNDATION, StackRole.TEXTURE,
                    StackRole.FLOW, StackRole.ACCENT, StackRole.VEIL, StackRole.SPARK,
                )
            }
            // Rotate by modality + salt so same-element users still stack differently
            val rotate = when (modality) {
                Modality.CARDINAL -> 0
                Modality.FIXED -> 1
                Modality.MUTABLE -> 2
            } + (salt * 3).toInt()
            return base.drop(rotate % base.size) + base.take(rotate % base.size)
        }

        /**
         * Stable 64-bit fingerprint from user id + chart geometry.
         * Same inputs always → same profile; different charts/ids diverge hard.
         */
        fun fingerprint(userId: String, chart: NatalChart?, baseScore: ElementVector): Long {
            var h = 0xCBF29CE484222325UL
            fun mix(v: Long) {
                h = h xor v.toULong()
                h *= 0x100000001B3UL
            }
            fun mixStr(s: String) {
                s.forEach { mix(it.code.toLong()) }
            }
            mixStr(userId)
            mix((baseScore.fire * 1000).toLong())
            mix((baseScore.earth * 1000).toLong())
            mix((baseScore.air * 1000).toLong())
            mix((baseScore.water * 1000).toLong())
            chart?.placements?.sortedBy { it.planet.ordinal }?.forEach { p ->
                mix(p.planet.ordinal.toLong())
                mix(p.sign.ordinal.toLong())
                mix((p.degree * 100).toLong())
                mix(if (p.isRetrograde) 1 else 0)
            }
            chart?.ascendant?.let { mix(it.ordinal.toLong() + 100) }
            chart?.stelliums?.forEach { mix(it.ordinal.toLong() + 200) }
            chart?.dominantModality?.let { mix(it.ordinal.toLong() + 300) }
            return h.toLong()
        }
    }
}

/** Layer roles used when stacking a personalized combo. */
enum class StackRole {
    /** Deep bed / sub-weight anchor */
    BEDROCK,
    /** Primary ambient body */
    FOUNDATION,
    /** Flowing / liquid mid layer */
    FLOW,
    /** Textural / grain interest */
    TEXTURE,
    /** Soft mask / ethereal cover */
    VEIL,
    /** Bright accent / sparkle */
    SPARK,
    /** Character accent / secondary motif */
    ACCENT,
}
