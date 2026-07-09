package com.astrosleep.app.core.model

import kotlinx.serialization.Serializable

@Serializable
data class SoundTags(
    val domain: String,
    val rhythm: String,
    val register: String,
    val context: String,
    val weight: String,
    val texture: String,
    val motion: String,
    val density: String,
    val temperature: String,
    val polarity: String,
    val celestial: String,
    val archetype: String,
) {
    fun validate(): Boolean {
        val validDomains = setOf("water", "air", "fire", "earth", "mechanical", "organic", "electrical", "cosmic")
        val validRhythms = setOf("steady", "pulse", "irregular", "chaotic", "rhythmic", "arrhythmic")
        val validRegisters = setOf("sub", "deep", "mid", "bright", "full", "ultrasonic")
        val validContexts = setOf("nature", "domestic", "abstract", "urban", "industrial", "spiritual")
        val validWeights = setOf("ethereal", "light", "medium", "heavy", "massive")
        val validTextures = setOf("smooth", "rough", "crystalline", "diffuse", "granular", "glassy", "metallic")
        val validMotions = setOf("static", "flowing", "surging", "swirling", "oscillating", "drifting", "pulsing")
        val validDensities = setOf("vacuum", "sparse", "moderate", "dense", "saturated")
        val validTemperatures = setOf("cold", "cool", "neutral", "warm", "hot")
        val validPolarities = setOf("active", "receptive", "balanced", "neutral")
        val validCelestials = setOf("solar", "lunar", "stellar", "planetary", "void")
        val validArchetypes = setOf("maiden", "mother", "crone", "hero", "mentor", "shadow", "trickster")
        return domain in validDomains &&
            rhythm in validRhythms &&
            register in validRegisters &&
            context in validContexts &&
            weight in validWeights &&
            texture in validTextures &&
            motion in validMotions &&
            density in validDensities &&
            temperature in validTemperatures &&
            polarity in validPolarities &&
            celestial in validCelestials &&
            archetype in validArchetypes
    }
}

@Serializable
data class Sound(
    val id: String,
    val name: String,
    val tags: SoundTags,
    val elementScores: ElementVector,
    val durationSeconds: Int,
    val isNew: Boolean = false,
    val version: Int = 1,
    val cdnUrl: String = "",
    val bundleFilename: String? = null,
) {
    val displayName: String get() = name
}

@Serializable
data class SoundManifest(
    val version: Int = 1,
    val generatedAt: String? = null,
    val sounds: List<Sound> = emptyList(),
)

data class RankedSound(
    val sound: Sound,
    val score: Double,
    val matchPercentage: Double = 0.0,
) : Comparable<RankedSound> {
    val id: String get() = sound.id
    override fun compareTo(other: RankedSound): Int = score.compareTo(other.score)
}
