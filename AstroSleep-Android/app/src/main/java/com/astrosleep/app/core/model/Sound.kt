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
)

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
)

@Serializable
data class SoundManifest(
    val version: Int = 1,
    val generatedAt: String? = null,
    val sounds: List<Sound> = emptyList(),
)

data class RankedSound(
    val sound: Sound,
    val score: Double,
) : Comparable<RankedSound> {
    val id: String get() = sound.id
    override fun compareTo(other: RankedSound): Int = other.score.compareTo(score)
}
