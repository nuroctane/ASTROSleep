package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.MoonPhase
import com.astrosleep.app.core.model.Planet
import com.astrosleep.app.core.model.Sign

/**
 * Giant preference maps: chart symbols → sonic tag affinities.
 * Strengths are relative; TagEngine normalizes contribution at score time.
 */
object TagAffinityTables {

    /** Pool for per-user signature tag injection (deterministic from fingerprint). */
    val signaturePool: List<String> = listOf(
        "water", "air", "fire", "earth", "mechanical", "organic", "electrical", "cosmic",
        "steady", "pulse", "irregular", "chaotic", "rhythmic", "arrhythmic",
        "sub", "deep", "mid", "bright", "full", "ultrasonic",
        "nature", "domestic", "abstract", "urban", "industrial", "spiritual",
        "ethereal", "light", "medium", "heavy", "massive",
        "smooth", "rough", "crystalline", "diffuse", "granular", "glassy", "metallic",
        "static", "flowing", "surging", "swirling", "oscillating", "drifting", "pulsing",
        "vacuum", "sparse", "moderate", "dense", "saturated",
        "cold", "cool", "neutral", "warm", "hot",
        "active", "receptive", "balanced",
        "solar", "lunar", "stellar", "planetary", "void",
        "maiden", "mother", "crone", "hero", "mentor", "shadow", "trickster",
    )

    fun signTagPreferences(sign: Sign): Map<String, Double> = when (sign) {
        Sign.ARIES -> mapOf(
            "fire" to 1.4, "active" to 1.3, "surging" to 1.2, "hot" to 1.1,
            "hero" to 1.2, "rough" to 0.9, "pulse" to 1.0, "solar" to 0.8,
        )
        Sign.TAURUS -> mapOf(
            "earth" to 1.5, "steady" to 1.4, "heavy" to 1.2, "smooth" to 1.1,
            "mother" to 1.0, "organic" to 1.1, "static" to 0.9, "warm" to 0.8,
        )
        Sign.GEMINI -> mapOf(
            "air" to 1.4, "bright" to 1.3, "crystalline" to 1.2, "arrhythmic" to 1.0,
            "trickster" to 1.2, "electrical" to 1.0, "pulse" to 0.9, "light" to 0.9,
        )
        Sign.CANCER -> mapOf(
            "water" to 1.6, "lunar" to 1.5, "mother" to 1.4, "flowing" to 1.2,
            "receptive" to 1.3, "domestic" to 1.0, "cool" to 0.9, "dense" to 0.8,
        )
        Sign.LEO -> mapOf(
            "fire" to 1.4, "solar" to 1.5, "hero" to 1.3, "warm" to 1.2,
            "full" to 1.0, "active" to 1.1, "surging" to 0.9, "nature" to 0.7,
        )
        Sign.VIRGO -> mapOf(
            "earth" to 1.3, "granular" to 1.3, "moderate" to 1.1, "mentor" to 1.2,
            "steady" to 1.1, "mechanical" to 0.9, "mid" to 1.0, "organic" to 0.8,
        )
        Sign.LIBRA -> mapOf(
            "air" to 1.3, "balanced" to 1.5, "smooth" to 1.3, "maiden" to 1.1,
            "harmonic" to 0.0, "bright" to 1.0, "drifting" to 1.0, "spiritual" to 0.9,
        )
        Sign.SCORPIO -> mapOf(
            "water" to 1.4, "shadow" to 1.6, "dense" to 1.3, "deep" to 1.4,
            "heavy" to 1.1, "receptive" to 1.0, "void" to 0.9, "rough" to 0.8,
        )
        Sign.OPHIUCHUS -> mapOf(
            "water" to 1.2, "cosmic" to 1.4, "shadow" to 1.3, "mentor" to 1.2,
            "spiritual" to 1.3, "oscillating" to 1.1, "planetary" to 1.0, "crystalline" to 0.9,
        )
        Sign.SAGITTARIUS -> mapOf(
            "fire" to 1.3, "cosmic" to 1.2, "drifting" to 1.2, "hero" to 1.1,
            "bright" to 1.0, "nature" to 1.1, "active" to 0.9, "stellar" to 1.0,
        )
        Sign.CAPRICORN -> mapOf(
            "earth" to 1.5, "mechanical" to 1.2, "heavy" to 1.3, "crone" to 1.2,
            "static" to 1.1, "cold" to 1.0, "industrial" to 1.0, "steady" to 1.2,
        )
        Sign.AQUARIUS -> mapOf(
            "air" to 1.4, "electrical" to 1.5, "abstract" to 1.3, "ultrasonic" to 1.2,
            "trickster" to 1.1, "stellar" to 1.2, "vacuum" to 1.0, "glassy" to 1.0,
        )
        Sign.PISCES -> mapOf(
            "water" to 1.6, "ethereal" to 1.4, "diffuse" to 1.3, "drifting" to 1.3,
            "spiritual" to 1.4, "lunar" to 1.2, "receptive" to 1.2, "shadow" to 0.9,
        )
    }

    fun planetTagPreferences(planet: Planet): Map<String, Double> = when (planet) {
        Planet.SUN -> mapOf("solar" to 1.4, "warm" to 1.1, "active" to 1.0, "fire" to 0.9, "hero" to 0.8)
        Planet.MOON -> mapOf("lunar" to 1.6, "water" to 1.2, "receptive" to 1.2, "mother" to 1.0, "flowing" to 0.9)
        Planet.MERCURY -> mapOf("bright" to 1.1, "electrical" to 1.0, "pulse" to 1.0, "air" to 0.9, "trickster" to 0.8)
        Planet.VENUS -> mapOf("smooth" to 1.3, "warm" to 1.1, "balanced" to 1.0, "organic" to 0.9, "maiden" to 0.8)
        Planet.MARS -> mapOf("fire" to 1.3, "rough" to 1.2, "active" to 1.2, "surging" to 1.1, "hot" to 1.0)
        Planet.JUPITER -> mapOf("full" to 1.1, "cosmic" to 1.0, "expansive" to 0.0, "nature" to 0.9, "mentor" to 0.9)
        Planet.SATURN -> mapOf("earth" to 1.2, "heavy" to 1.3, "mechanical" to 1.1, "static" to 1.1, "crone" to 1.0, "cold" to 0.9)
        Planet.URANUS -> mapOf("electrical" to 1.5, "chaotic" to 1.2, "ultrasonic" to 1.2, "abstract" to 1.1, "air" to 0.9)
        Planet.NEPTUNE -> mapOf("water" to 1.3, "ethereal" to 1.4, "diffuse" to 1.3, "spiritual" to 1.2, "drifting" to 1.2, "void" to 0.8)
        Planet.PLUTO -> mapOf("shadow" to 1.5, "dense" to 1.3, "deep" to 1.3, "heavy" to 1.1, "water" to 0.9)
        Planet.CHIRON -> mapOf("mentor" to 1.3, "spiritual" to 1.1, "organic" to 0.9, "mid" to 0.8, "cosmic" to 0.8)
        Planet.LILITH -> mapOf("shadow" to 1.4, "void" to 1.2, "irregular" to 1.0, "rough" to 0.9, "lunar" to 0.8)
        Planet.NORTH_NODE -> mapOf("stellar" to 1.1, "active" to 0.9, "cosmic" to 1.0, "drifting" to 0.8)
        Planet.SOUTH_NODE -> mapOf("void" to 1.1, "crone" to 0.9, "static" to 0.8, "shadow" to 0.8)
    }

    fun elementTagPreferences(element: Element): Map<String, Double> = when (element) {
        Element.FIRE -> mapOf(
            "fire" to 1.5, "hot" to 1.3, "active" to 1.2, "surging" to 1.1,
            "rough" to 0.9, "solar" to 1.0, "hero" to 1.0, "pulse" to 0.8,
        )
        Element.EARTH -> mapOf(
            "earth" to 1.5, "heavy" to 1.3, "steady" to 1.3, "dense" to 1.2,
            "static" to 1.1, "organic" to 1.0, "mechanical" to 0.9, "smooth" to 0.8,
        )
        Element.AIR -> mapOf(
            "air" to 1.5, "bright" to 1.3, "light" to 1.2, "crystalline" to 1.2,
            "electrical" to 1.1, "drifting" to 1.1, "sparse" to 1.0, "trickster" to 0.9,
        )
        Element.WATER -> mapOf(
            "water" to 1.6, "flowing" to 1.4, "cool" to 1.2, "receptive" to 1.3,
            "lunar" to 1.2, "dense" to 1.0, "mother" to 1.1, "diffuse" to 1.0,
        )
    }

    fun moonPhaseTagPreferences(phase: MoonPhase): Map<String, Double> = when (phase) {
        MoonPhase.NEW_MOON -> mapOf(
            "void" to 1.4, "sparse" to 1.3, "ethereal" to 1.2, "sub" to 1.1,
            "receptive" to 1.2, "shadow" to 1.0, "cold" to 0.9,
        )
        MoonPhase.WAXING_CRESCENT -> mapOf(
            "light" to 1.2, "maiden" to 1.2, "pulse" to 1.1, "bright" to 1.0,
            "active" to 0.9, "air" to 0.8,
        )
        MoonPhase.FIRST_QUARTER -> mapOf(
            "active" to 1.3, "pulse" to 1.2, "fire" to 1.0, "rough" to 0.9,
            "hero" to 1.0, "mid" to 0.8,
        )
        MoonPhase.WAXING_GIBBOUS -> mapOf(
            "dense" to 1.1, "full" to 1.1, "organic" to 1.0, "warm" to 1.0,
            "flowing" to 0.9, "balanced" to 0.9,
        )
        MoonPhase.FULL_MOON -> mapOf(
            "lunar" to 1.5, "bright" to 1.2, "saturated" to 1.2, "water" to 1.1,
            "air" to 1.0, "full" to 1.1, "crystalline" to 1.0,
        )
        MoonPhase.WANING_GIBBOUS -> mapOf(
            "diffuse" to 1.2, "mentor" to 1.1, "drifting" to 1.1, "cool" to 1.0,
            "spiritual" to 1.0, "moderate" to 0.9,
        )
        MoonPhase.LAST_QUARTER -> mapOf(
            "earth" to 1.2, "crone" to 1.2, "steady" to 1.1, "heavy" to 1.0,
            "static" to 0.9, "mechanical" to 0.8,
        )
        MoonPhase.WANING_CRESCENT -> mapOf(
            "water" to 1.3, "ethereal" to 1.3, "receptive" to 1.3, "void" to 1.1,
            "drifting" to 1.2, "sparse" to 1.0, "shadow" to 1.0, "cool" to 1.1,
        )
    }

    /**
     * Which tags "play well" for each stack role — used when picking layers.
     * Higher score = better fit for that seat in the mix.
     */
    fun roleFit(role: StackRole, tags: com.astrosleep.app.core.model.SoundTags): Double {
        var s = 0.0
        fun hit(cond: Boolean, w: Double) { if (cond) s += w }
        when (role) {
            StackRole.BEDROCK -> {
                hit(tags.register in setOf("sub", "deep"), 2.2)
                hit(tags.weight in setOf("heavy", "massive"), 1.8)
                hit(tags.density in setOf("dense", "saturated"), 1.4)
                hit(tags.domain in setOf("earth", "mechanical", "water"), 1.2)
                hit(tags.motion == "static" || tags.rhythm == "steady", 1.0)
            }
            StackRole.FOUNDATION -> {
                hit(tags.domain in setOf("water", "earth", "organic", "air"), 1.6)
                hit(tags.weight in setOf("medium", "heavy"), 1.2)
                hit(tags.density in setOf("moderate", "dense"), 1.0)
                hit(tags.context == "nature" || tags.context == "domestic", 0.8)
            }
            StackRole.FLOW -> {
                hit(tags.motion in setOf("flowing", "drifting", "swirling"), 2.0)
                hit(tags.domain == "water" || tags.domain == "air", 1.4)
                hit(tags.rhythm in setOf("irregular", "arrhythmic", "pulse"), 1.0)
            }
            StackRole.TEXTURE -> {
                hit(tags.texture in setOf("granular", "rough", "crystalline", "metallic", "glassy"), 2.0)
                hit(tags.domain in setOf("mechanical", "electrical", "organic"), 1.2)
                hit(tags.register in setOf("mid", "bright"), 0.9)
            }
            StackRole.VEIL -> {
                hit(tags.weight in setOf("ethereal", "light"), 2.0)
                hit(tags.texture in setOf("diffuse", "smooth", "crystalline"), 1.5)
                hit(tags.density in setOf("sparse", "vacuum", "moderate"), 1.2)
                hit(tags.celestial in setOf("lunar", "stellar", "void"), 1.0)
            }
            StackRole.SPARK -> {
                hit(tags.register in setOf("bright", "ultrasonic", "full"), 2.0)
                hit(tags.temperature in setOf("warm", "hot"), 1.2)
                hit(tags.domain in setOf("fire", "electrical", "cosmic"), 1.3)
                hit(tags.polarity == "active", 1.0)
            }
            StackRole.ACCENT -> {
                hit(tags.archetype in setOf("trickster", "hero", "shadow", "maiden"), 1.5)
                hit(tags.context in setOf("urban", "industrial", "spiritual", "abstract"), 1.2)
                hit(tags.celestial in setOf("planetary", "solar", "stellar"), 1.0)
                hit(tags.isNewLike(), 0.3)
            }
        }
        return s
    }

    private fun com.astrosleep.app.core.model.SoundTags.isNewLike(): Boolean =
        domain in setOf("electrical", "cosmic") || texture in setOf("glassy", "metallic")
}
