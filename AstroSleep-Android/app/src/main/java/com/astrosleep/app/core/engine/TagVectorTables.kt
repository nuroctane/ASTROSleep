package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.ElementVector

/** Lookup tables from iOS TagEngine.swift — keep values byte-identical. */
object TagVectorTables {
    val domain: Map<String, ElementVector> = mapOf(
        "water" to ElementVector(0.5, 1.5, 1.0, 9.0),
        "air" to ElementVector(1.5, 0.5, 9.0, 1.0),
        "fire" to ElementVector(9.0, 0.5, 1.5, 0.5),
        "earth" to ElementVector(0.5, 9.0, 0.5, 1.5),
        "mechanical" to ElementVector(1.5, 6.0, 2.0, 1.0),
        "organic" to ElementVector(1.0, 5.0, 1.5, 4.0),
        "electrical" to ElementVector(3.0, 1.0, 7.0, 0.5),
        "cosmic" to ElementVector(4.0, 1.0, 6.0, 2.0),
    )

    val rhythm: Map<String, ElementVector> = mapOf(
        "steady" to ElementVector(0.0, 3.0, 0.5, 1.5),
        "pulse" to ElementVector(1.0, 2.0, 1.0, 1.5),
        "irregular" to ElementVector(2.0, 0.0, 2.0, 1.5),
        "chaotic" to ElementVector(3.0, 0.0, 2.5, 0.5),
        "rhythmic" to ElementVector(1.5, 2.0, 1.0, 2.0),
        "arrhythmic" to ElementVector(1.0, 0.0, 2.0, 2.0),
    )

    val register: Map<String, ElementVector> = mapOf(
        "sub" to ElementVector(0.0, 3.0, 0.0, 2.0),
        "deep" to ElementVector(0.0, 2.5, 0.0, 1.5),
        "mid" to ElementVector(1.0, 1.5, 1.0, 1.0),
        "bright" to ElementVector(1.5, 0.5, 2.5, 0.0),
        "full" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "ultrasonic" to ElementVector(0.5, 0.0, 3.0, 0.0),
    )

    val context: Map<String, ElementVector> = mapOf(
        "nature" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "domestic" to ElementVector(0.0, 2.0, 0.5, 1.5),
        "abstract" to ElementVector(0.5, 0.0, 2.0, 1.0),
        "urban" to ElementVector(1.5, 1.0, 2.0, 0.5),
        "industrial" to ElementVector(1.0, 3.0, 1.5, 0.0),
        "spiritual" to ElementVector(1.0, 0.5, 2.0, 2.5),
    )

    val weight: Map<String, ElementVector> = mapOf(
        "ethereal" to ElementVector(0.0, 0.0, 2.0, 1.0),
        "light" to ElementVector(0.0, 0.0, 1.5, 1.5),
        "medium" to ElementVector(1.0, 1.5, 0.5, 0.5),
        "heavy" to ElementVector(2.5, 1.0, 1.0, 0.5),
        "massive" to ElementVector(2.0, 3.0, 0.0, 0.0),
    )

    val texture: Map<String, ElementVector> = mapOf(
        "smooth" to ElementVector(1.0, 2.5, 1.0, 3.0),
        "rough" to ElementVector(3.5, 3.5, 0.5, 1.0),
        "crystalline" to ElementVector(2.5, 1.0, 4.0, 1.5),
        "diffuse" to ElementVector(1.0, 1.0, 2.5, 3.0),
        "granular" to ElementVector(2.0, 2.0, 1.0, 1.0),
        "glassy" to ElementVector(1.5, 1.0, 3.5, 1.0),
        "metallic" to ElementVector(2.0, 3.0, 2.0, 0.0),
    )

    val motion: Map<String, ElementVector> = mapOf(
        "static" to ElementVector(0.0, 4.0, 0.0, 1.0),
        "flowing" to ElementVector(1.0, 0.0, 1.0, 4.0),
        "surging" to ElementVector(4.5, 0.0, 2.0, 1.0),
        "swirling" to ElementVector(2.5, 0.0, 4.0, 1.0),
        "oscillating" to ElementVector(2.0, 1.0, 3.0, 1.0),
        "drifting" to ElementVector(1.0, 0.5, 3.0, 2.5),
        "pulsing" to ElementVector(2.5, 0.5, 1.5, 2.0),
    )

    val density: Map<String, ElementVector> = mapOf(
        "vacuum" to ElementVector(3.0, 0.0, 2.5, 1.0),
        "sparse" to ElementVector(2.5, 0.0, 2.0, 1.0),
        "moderate" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "dense" to ElementVector(1.0, 3.0, 1.0, 2.0),
        "saturated" to ElementVector(1.5, 2.5, 2.0, 2.5),
    )

    val temperature: Map<String, ElementVector> = mapOf(
        "cold" to ElementVector(0.0, 3.0, 1.0, 2.0),
        "cool" to ElementVector(0.5, 2.0, 1.5, 2.0),
        "neutral" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "warm" to ElementVector(2.5, 1.0, 1.5, 1.0),
        "hot" to ElementVector(4.0, 0.5, 1.0, 0.0),
    )

    val polarity: Map<String, ElementVector> = mapOf(
        "active" to ElementVector(3.0, 1.0, 2.0, 0.5),
        "receptive" to ElementVector(0.5, 2.0, 1.0, 3.0),
        "balanced" to ElementVector(1.0, 1.0, 1.0, 1.0),
        "neutral" to ElementVector(1.0, 1.0, 1.0, 1.0),
    )

    val celestial: Map<String, ElementVector> = mapOf(
        "solar" to ElementVector(4.0, 0.5, 1.0, 0.0),
        "lunar" to ElementVector(0.0, 1.0, 0.0, 4.0),
        "stellar" to ElementVector(1.0, 0.5, 3.0, 1.0),
        "planetary" to ElementVector(1.5, 1.5, 1.5, 1.5),
        "void" to ElementVector(0.5, 0.5, 0.5, 0.5),
    )

    val archetype: Map<String, ElementVector> = mapOf(
        "maiden" to ElementVector(1.0, 0.5, 3.0, 1.0),
        "mother" to ElementVector(0.5, 2.0, 0.5, 3.0),
        "crone" to ElementVector(1.0, 3.0, 2.0, 2.0),
        "hero" to ElementVector(4.0, 1.0, 2.0, 0.5),
        "mentor" to ElementVector(1.5, 3.0, 2.0, 1.0),
        "shadow" to ElementVector(0.5, 0.5, 1.0, 4.0),
        "trickster" to ElementVector(2.0, 0.5, 4.0, 1.0),
    )
}
