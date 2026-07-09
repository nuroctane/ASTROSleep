package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.ElementVector
import javax.inject.Inject
import javax.inject.Singleton

data class NightlyScoreResult(
    val score: ElementVector,
    val dominant: Element,
    val computedAtEpochMs: Long,
    val notes: List<String> = emptyList(),
)

/**
 * Natal chart + transit scoring (Sidereal 13-sign, Sharatan ayanamsha).
 * Port of iOS `AstrologicalEngine.swift` — implement full math in Phase A.
 */
@Singleton
class AstrologicalEngine @Inject constructor() {

    /** Sharatan ayanamsha ≈ 24°06'18" */
    val sharatanAyanamshaDegrees: Double = 24.0 + 6.0 / 60.0 + 18.0 / 3600.0

    fun calculateNightlyScore(
        baseScore: ElementVector,
        nowEpochMs: Long = System.currentTimeMillis(),
    ): NightlyScoreResult {
        // TODO(port): transits + moon phase blend from iOS engine
        // Temporary: pass through base score so UI scaffolding works.
        val score = if (baseScore == ElementVector.ZERO) {
            ElementVector(fire = 2.5, earth = 3.0, air = 2.0, water = 4.5).normalize()
        } else {
            baseScore.normalize()
        }
        return NightlyScoreResult(
            score = score,
            dominant = score.dominant(),
            computedAtEpochMs = nowEpochMs,
            notes = listOf("Android engine shell — full transit math pending port"),
        )
    }
}
