package com.astrosleep.app.core.model

import com.astrosleep.app.core.engine.StackRole

/**
 * Sound ranked for a specific user + night, with full score anatomy
 * so stacking and UI can reason about *why* a sound won.
 */
data class RankedSound(
    val sound: Sound,
    val score: Double,
    val matchPercentage: Double = 0.0,
    val breakdown: ScoreBreakdown = ScoreBreakdown(),
    val suggestedRole: StackRole? = null,
) : Comparable<RankedSound> {
    val id: String get() = sound.id
    override fun compareTo(other: RankedSound): Int = score.compareTo(other.score)
}

data class ScoreBreakdown(
    val nightlyResonance: Double = 0.0,
    val natalResonance: Double = 0.0,
    val tagAffinity: Double = 0.0,
    val transitResonance: Double = 0.0,
    val moonPhaseAffinity: Double = 0.0,
    val personalizedVectorPull: Double = 0.0,
    val fingerprintJitter: Double = 0.0,
    val contrastBonus: Double = 0.0,
    val notes: List<String> = emptyList(),
)
