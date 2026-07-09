package com.astrosleep.app.core.model

import kotlinx.serialization.Serializable
import kotlin.math.max

/**
 * Four-element scoring vector [Fire, Earth, Air, Water].
 * Port of iOS `ElementVector.swift` — keep math parity with golden tests.
 */
@Serializable
data class ElementVector(
    val fire: Double = 0.0,
    val earth: Double = 0.0,
    val air: Double = 0.0,
    val water: Double = 0.0,
) {
    operator fun plus(other: ElementVector): ElementVector = ElementVector(
        fire = fire + other.fire,
        earth = earth + other.earth,
        air = air + other.air,
        water = water + other.water,
    )

    operator fun times(scalar: Double): ElementVector = ElementVector(
        fire = fire * scalar,
        earth = earth * scalar,
        air = air * scalar,
        water = water * scalar,
    )

    /** Normalize so the strongest element equals [target] (iOS: `normalize(target:)`). */
    fun normalize(target: Double = 10.0): ElementVector {
        val peak = max(max(fire, earth), max(air, water))
        if (peak <= 0.0) return ZERO
        val scale = target / peak
        return this * scale
    }

    fun dominant(): Element {
        val values = listOf(
            Element.FIRE to fire,
            Element.EARTH to earth,
            Element.AIR to air,
            Element.WATER to water,
        )
        return values.maxBy { it.second }.first
    }

    fun cosineSimilarity(other: ElementVector): Double {
        val dot = fire * other.fire + earth * other.earth + air * other.air + water * other.water
        val magA = kotlin.math.sqrt(fire * fire + earth * earth + air * air + water * water)
        val magB = kotlin.math.sqrt(
            other.fire * other.fire + other.earth * other.earth +
                other.air * other.air + other.water * other.water,
        )
        if (magA == 0.0 || magB == 0.0) return 0.0
        return dot / (magA * magB)
    }

    companion object {
        val ZERO = ElementVector()
    }
}
