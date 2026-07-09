package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.RankedSound
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SoundTags
import com.astrosleep.app.core.model.roundedTo
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 12-dimensional archetypal scoring — port of iOS TagEngine.swift.
 * Ranking uses raw tag vectors (not precomputed elementScores) for iOS parity.
 */
@Singleton
class TagEngine @Inject constructor() {

    private val dimensionWeights: Map<String, Double> = mapOf(
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

    fun calculateTagVector(sound: Sound): ElementVector =
        calculateTagVector(sound.tags)

    fun calculateTagVector(tags: SoundTags): ElementVector {
        var raw = ElementVector()

        fun add(table: Map<String, ElementVector>, key: String, weightKey: String) {
            val vector = table[key] ?: return
            val w = dimensionWeights[weightKey] ?: 1.0
            raw = raw + vector * w
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

    fun rankSounds(
        sounds: List<Sound>,
        against: NightlyScoreResult,
    ): List<RankedSound> {
        val nightly = against.elementScore
        return sounds.map { sound ->
            val tagVector = calculateTagVector(sound)
            val rankScore = (
                nightly.fire * tagVector.fire +
                    nightly.earth * tagVector.earth +
                    nightly.air * tagVector.air +
                    nightly.water * tagVector.water
                ) / 4.0
            RankedSound(
                sound = sound,
                score = rankScore.roundedTo(2),
                matchPercentage = (rankScore * 10.0).roundedTo(1),
            )
        }.sortedDescending()
    }
}
