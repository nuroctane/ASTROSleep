package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.NatalChart
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.Planet
import com.astrosleep.app.core.model.RankedSound
import com.astrosleep.app.core.model.ScoreBreakdown
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SoundTags
import com.astrosleep.app.core.model.Transit
import com.astrosleep.app.core.model.allValues
import com.astrosleep.app.core.model.roundedTo
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Tag Engine v4 — deeply personalized 12-dimensional scoring.
 *
 * Ranking is no longer a single nightly dot-product. Each user gets a
 * [PersonalSoundProfile] that remaps dimension weights, injects tag affinities
 * from moon/sun/rising/planets/stelliums, blends natal vs nightly pull, folds
 * in active transits + moon phase, and applies deterministic fingerprint jitter
 * so two sign-ins never collapse to the same stack.
 */
@Singleton
class TagEngine @Inject constructor() {

    private val baseDimensionWeights: Map<String, Double> = mapOf(
        "domain" to 9.0,
        "celestial" to 4.0,
        "archetype" to 4.0,
        "rhythm" to 3.0,
        "motion" to 3.0,
        "register" to 2.0,
        "context" to 2.0,
        "weight" to 2.0,
        "texture" to 2.0,
        "density" to 2.0,
        "temperature" to 2.0,
        "polarity" to 2.0,
    )

    // ── Vector calculation ────────────────────────────────────────────────

    fun calculateTagVector(sound: Sound): ElementVector =
        calculateTagVector(sound.tags, dimensionMultipliers = emptyMap())

    fun calculateTagVector(tags: SoundTags): ElementVector =
        calculateTagVector(tags, dimensionMultipliers = emptyMap())

    /**
     * Weighted 12-dim → ElementVector. Optional per-user dimension multipliers
     * stretch the sonic space so the same catalog reads differently per chart.
     */
    fun calculateTagVector(
        tags: SoundTags,
        dimensionMultipliers: Map<String, Double>,
    ): ElementVector {
        var raw = ElementVector()

        fun add(table: Map<String, ElementVector>, key: String, weightKey: String) {
            val vector = table[key] ?: return
            val base = baseDimensionWeights[weightKey] ?: 1.0
            val mult = dimensionMultipliers[weightKey] ?: 1.0
            raw = raw + vector * (base * mult)
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

    fun normalizeSoundVectors(sounds: List<Sound>): List<ElementVector> {
        val rawScores = sounds.map { calculateTagVector(it) }
        val maxValues = ElementVector(
            fire = rawScores.maxOfOrNull { it.fire } ?: 1.0,
            earth = rawScores.maxOfOrNull { it.earth } ?: 1.0,
            air = rawScores.maxOfOrNull { it.air } ?: 1.0,
            water = rawScores.maxOfOrNull { it.water } ?: 1.0,
        )
        return rawScores.map { raw ->
            ElementVector(
                fire = if (maxValues.fire > 0) (raw.fire / maxValues.fire * 10.0).roundedTo(2) else 0.0,
                earth = if (maxValues.earth > 0) (raw.earth / maxValues.earth * 10.0).roundedTo(2) else 0.0,
                air = if (maxValues.air > 0) (raw.air / maxValues.air * 10.0).roundedTo(2) else 0.0,
                water = if (maxValues.water > 0) (raw.water / maxValues.water * 10.0).roundedTo(2) else 0.0,
            )
        }
    }

    // ── Ranking ───────────────────────────────────────────────────────────

    /**
     * Legacy simple rank (nightly only) — kept for tests / fallbacks.
     */
    fun rankSounds(
        sounds: List<Sound>,
        against: NightlyScoreResult,
    ): List<RankedSound> = rankSoundsPersonalized(
        sounds = sounds,
        nightly = against,
        profile = PersonalSoundProfile.from(
            userId = "anonymous",
            chart = null,
            baseScore = against.elementScore,
        ),
        natalBaseScore = against.elementScore,
        chart = null,
    )

    /**
     * Full personalized ranking. This is what combo generation should call.
     */
    fun rankSoundsPersonalized(
        sounds: List<Sound>,
        nightly: NightlyScoreResult,
        profile: PersonalSoundProfile,
        natalBaseScore: ElementVector,
        chart: NatalChart?,
    ): List<RankedSound> {
        val transitAffinity = buildTransitAffinity(nightly.activeTransits, profile.transitPull)
        val phaseAffinity = TagAffinityTables.moonPhaseTagPreferences(nightly.moonPhase)
        val oppositeElement = opposite(profile.dominantElement)

        return sounds.map { sound ->
            scoreSound(
                sound = sound,
                nightly = nightly,
                profile = profile,
                natalBaseScore = natalBaseScore,
                transitAffinity = transitAffinity,
                phaseAffinity = phaseAffinity,
                oppositeElement = oppositeElement,
            )
        }.sortedDescending()
    }

    private fun scoreSound(
        sound: Sound,
        nightly: NightlyScoreResult,
        profile: PersonalSoundProfile,
        natalBaseScore: ElementVector,
        transitAffinity: Map<String, Double>,
        phaseAffinity: Map<String, Double>,
        oppositeElement: Element,
    ): RankedSound {
        val tags = sound.tags
        val notes = mutableListOf<String>()

        // 1) Personalized tag vector (dimension weights remapped for this chart)
        val personalVector = calculateTagVector(tags, profile.dimensionMultipliers)
        val baseVector = calculateTagVector(tags)

        // 2) Nightly resonance — classic weighted product, scaled by user nightlyPull
        val nightlyRes = elementProduct(nightly.elementScore, personalVector) * profile.nightlyPull
        notes += "nightly×${profile.nightlyPull.roundedTo(2)}"

        // 3) Natal resonance — lifelong palette, scaled by natalPull
        val natalRes = elementProduct(natalBaseScore, personalVector) * profile.natalPull
        notes += "natal×${profile.natalPull.roundedTo(2)}"

        // 4) Manifest elementScores as a soft prior (catalog-authored)
        val catalogRes = elementProduct(nightly.elementScore, sound.elementScores) * 0.35

        // 5) Tag affinity sum — moon/sun/planets/signature tags
        val tagVals = tags.allValues()
        var tagAff = 0.0
        var hitCount = 0
        for (t in tagVals) {
            val a = profile.tagAffinities[t] ?: 0.0
            if (a != 0.0) {
                tagAff += a
                hitCount++
            }
        }
        // Soft-log so multi-hit sounds don't explode
        val tagAffinityScore = if (tagAff > 0) ln(1.0 + tagAff) * 18.0 else 0.0
        if (hitCount > 0) notes += "tagHits=$hitCount"

        // 6) Transit resonance — tonight's active planets → tags
        var transitScore = 0.0
        for (t in tagVals) {
            transitScore += transitAffinity[t] ?: 0.0
        }
        transitScore = ln(1.0 + transitScore) * 14.0 * profile.transitPull
        if (transitScore > 0.5) notes += "transit+${transitScore.roundedTo(1)}"

        // 7) Moon phase palette
        var phaseScore = 0.0
        for (t in tagVals) {
            phaseScore += phaseAffinity[t] ?: 0.0
        }
        phaseScore = ln(1.0 + phaseScore) * 12.0
        if (phaseScore > 0.5) notes += "phase+${phaseScore.roundedTo(1)}"

        // 8) Dominant-element agreement / secondary support
        val soundDom = personalVector.dominant()
        val elementAlign = when (soundDom) {
            profile.dominantElement -> 22.0
            profile.secondaryElement -> 11.0
            oppositeElement -> 4.0 * profile.contrastBias // contrast can still score
            else -> 3.0
        }
        notes += "elem=${soundDom.displayName}"

        // 9) Modality ↔ rhythm/motion congruence
        val modalityFit = modalityCongruence(profile, tags) * 8.0

        // 10) Retrograde-sensitive textures (if chart heavy on Rx, reward irregularity)
        // (folded into affinities already; small explicit boost)
        val rxBoost = if (
            tags.rhythm in setOf("irregular", "arrhythmic", "chaotic") ||
            tags.archetype == "shadow" ||
            tags.celestial == "void"
        ) {
            profile.tagAffinities["shadow"]?.let { min(it, 2.0) * 2.5 } ?: 0.0
        } else 0.0

        // 11) Personalized vector magnitude pull — users with high dim mult on a axis
        //     will prefer sounds that light up that axis after remapping
        val personalPull = (personalVector.fire + personalVector.earth +
            personalVector.air + personalVector.water) * 0.02

        // 12) Deterministic fingerprint jitter — unique per (user, sound) but stable
        val jitter = fingerprintJitter(profile.fingerprint, sound.id) * 6.5
        // keep small relative to other terms but enough to break ties differently per user

        // 13) Contrast bonus: secondary layer spice for opposite-element accents
        val contrastBonus = if (soundDom == oppositeElement) {
            5.0 * profile.contrastBias
        } else 0.0

        // 14) Celestial special cases for moon-dominant sleepers
        val lunarBias = if (profile.moonSign != null && tags.celestial == "lunar") {
            6.0 + profile.natalPull
        } else 0.0

        val total = (
            nightlyRes +
                natalRes +
                catalogRes +
                tagAffinityScore +
                transitScore +
                phaseScore +
                elementAlign +
                modalityFit +
                rxBoost +
                personalPull +
                jitter +
                contrastBonus +
                lunarBias
            )

        // Suggested mix role from tag anatomy
        val role = profile.roleOrder.maxByOrNull { role ->
            TagAffinityTables.roleFit(role, tags)
        }

        // Match % calibrated so ~top scores land near 100
        val matchPct = min(99.9, max(1.0, total / 3.5)).roundedTo(1)

        return RankedSound(
            sound = sound,
            score = total.roundedTo(3),
            matchPercentage = matchPct,
            breakdown = ScoreBreakdown(
                nightlyResonance = nightlyRes.roundedTo(3),
                natalResonance = natalRes.roundedTo(3),
                tagAffinity = tagAffinityScore.roundedTo(3),
                transitResonance = transitScore.roundedTo(3),
                moonPhaseAffinity = phaseScore.roundedTo(3),
                personalizedVectorPull = personalPull.roundedTo(3),
                fingerprintJitter = jitter.roundedTo(3),
                contrastBonus = contrastBonus.roundedTo(3),
                notes = notes,
            ),
            suggestedRole = role,
        )
    }

    private fun elementProduct(a: ElementVector, b: ElementVector): Double =
        (a.fire * b.fire + a.earth * b.earth + a.air * b.air + a.water * b.water) / 4.0

    private fun modalityCongruence(profile: PersonalSoundProfile, tags: SoundTags): Double {
        return when (profile.modality) {
            com.astrosleep.app.core.model.Modality.CARDINAL -> when {
                tags.motion in setOf("surging", "pulsing", "flowing") -> 1.3
                tags.polarity == "active" -> 1.1
                tags.rhythm == "steady" -> 0.4
                else -> 0.6
            }
            com.astrosleep.app.core.model.Modality.FIXED -> when {
                tags.rhythm in setOf("steady", "rhythmic", "pulse") -> 1.4
                tags.motion == "static" || tags.density in setOf("dense", "saturated") -> 1.2
                tags.rhythm in setOf("chaotic", "arrhythmic") -> 0.3
                else -> 0.6
            }
            com.astrosleep.app.core.model.Modality.MUTABLE -> when {
                tags.texture in setOf("diffuse", "crystalline", "granular") -> 1.3
                tags.motion in setOf("drifting", "swirling", "oscillating") -> 1.3
                tags.rhythm in setOf("irregular", "arrhythmic") -> 1.1
                else -> 0.6
            }
        }
    }

    private fun buildTransitAffinity(
        transits: List<Transit>,
        transitPull: Double,
    ): Map<String, Double> {
        if (transits.isEmpty()) return emptyMap()
        val out = mutableMapOf<String, Double>()
        // Top transits dominate; use strength as weight
        val top = transits.sortedByDescending { it.strength }.take(12)
        for (t in top) {
            val prefs = TagAffinityTables.planetTagPreferences(t.planet)
            val w = t.strength * (0.5 + transitPull * 0.5)
            prefs.forEach { (tag, pref) ->
                out[tag] = (out[tag] ?: 0.0) + pref * w
            }
            // Hard aspects prefer denser/rougher textures; soft prefer smooth/flow
            when (t.aspectType) {
                com.astrosleep.app.core.model.Aspect.SQUARE,
                com.astrosleep.app.core.model.Aspect.OPPOSITION,
                -> {
                    out["rough"] = (out["rough"] ?: 0.0) + 0.4 * w
                    out["dense"] = (out["dense"] ?: 0.0) + 0.3 * w
                    out["heavy"] = (out["heavy"] ?: 0.0) + 0.25 * w
                }
                com.astrosleep.app.core.model.Aspect.TRINE,
                com.astrosleep.app.core.model.Aspect.SEXTILE,
                -> {
                    out["smooth"] = (out["smooth"] ?: 0.0) + 0.4 * w
                    out["flowing"] = (out["flowing"] ?: 0.0) + 0.35 * w
                    out["light"] = (out["light"] ?: 0.0) + 0.2 * w
                }
                com.astrosleep.app.core.model.Aspect.CONJUNCTION -> {
                    out["saturated"] = (out["saturated"] ?: 0.0) + 0.35 * w
                    out["full"] = (out["full"] ?: 0.0) + 0.25 * w
                }
            }
            // Moon transits always matter for sleep
            if (t.planet == Planet.MOON) {
                out["lunar"] = (out["lunar"] ?: 0.0) + 0.8 * w
                out["water"] = (out["water"] ?: 0.0) + 0.5 * w
            }
        }
        return out
    }

    /**
     * Deterministic -1..1 jitter from fingerprint ⊕ soundId.
     * Same user+sound always identical; different users diverge.
     */
    fun fingerprintJitter(fingerprint: Long, soundId: String): Double {
        var h = fingerprint
        soundId.forEach { c ->
            h = h xor c.code.toLong()
            h *= 0x5DEECE66DL
            h += 0xBL
        }
        // map to roughly -1..1
        val unit = ((h ushr 17) and 0xFFFFL).toDouble() / 65535.0
        return (unit * 2.0 - 1.0) * (0.55 + abs(sin(fingerprint.toDouble() * 1e-9)) * 0.45)
    }

    private fun opposite(e: Element): Element = when (e) {
        Element.FIRE -> Element.WATER
        Element.WATER -> Element.FIRE
        Element.EARTH -> Element.AIR
        Element.AIR -> Element.EARTH
    }

    /**
     * Pairwise stack diversity: how much two sounds collide in tag space.
     * Higher = more similar (worse for diversity).
     */
    fun tagOverlap(a: SoundTags, b: SoundTags): Double {
        val av = a.allValues()
        val bv = b.allValues()
        val inter = av.intersect(bv).size.toDouble()
        val union = av.union(bv).size.toDouble().coerceAtLeast(1.0)
        // Weight domain/celestial/archetype collisions harder
        var penalty = inter / union
        if (a.domain == b.domain) penalty += 0.35
        if (a.celestial == b.celestial) penalty += 0.20
        if (a.archetype == b.archetype) penalty += 0.15
        if (a.motion == b.motion) penalty += 0.10
        return penalty
    }

    fun cosineSimilarity(a: ElementVector, b: ElementVector): Double {
        val dot = a.fire * b.fire + a.earth * b.earth + a.air * b.air + a.water * b.water
        val magA = sqrt(a.fire * a.fire + a.earth * a.earth + a.air * a.air + a.water * a.water)
        val magB = sqrt(b.fire * b.fire + b.earth * b.earth + b.air * b.air + b.water * b.water)
        if (magA == 0.0 || magB == 0.0) return 0.0
        return dot / (magA * magB)
    }
}
