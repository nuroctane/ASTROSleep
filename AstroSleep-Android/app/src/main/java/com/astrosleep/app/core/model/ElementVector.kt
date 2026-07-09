package com.astrosleep.app.core.model

import kotlinx.serialization.Serializable
import kotlin.math.max
import kotlin.math.pow
import kotlin.math.round

/**
 * [Fire, Earth, Air, Water] scoring vector — port of iOS ElementVector.swift.
 * Mutable so nightly score accumulation can mirror iOS `+=` / subscript mutation.
 */
@Serializable
data class ElementVector(
    var fire: Double = 0.0,
    var earth: Double = 0.0,
    var air: Double = 0.0,
    var water: Double = 0.0,
) {
    operator fun get(element: Element): Double = when (element) {
        Element.FIRE -> fire
        Element.EARTH -> earth
        Element.AIR -> air
        Element.WATER -> water
    }

    operator fun set(element: Element, value: Double) {
        when (element) {
            Element.FIRE -> fire = value
            Element.EARTH -> earth = value
            Element.AIR -> air = value
            Element.WATER -> water = value
        }
    }

    operator fun get(index: Int): Double = when (index) {
        0 -> fire
        1 -> earth
        2 -> air
        3 -> water
        else -> 0.0
    }

    operator fun set(index: Int, value: Double) {
        when (index) {
            0 -> fire = value
            1 -> earth = value
            2 -> air = value
            3 -> water = value
        }
    }

    fun dominant(): Element {
        val maxValue = max(max(fire, earth), max(air, water))
        return when (maxValue) {
            fire -> Element.FIRE
            earth -> Element.EARTH
            air -> Element.AIR
            else -> Element.WATER
        }
    }

    /** Normalize so the strongest element equals [target] (iOS default 10). */
    fun normalize(target: Double = 10.0): ElementVector {
        val maxVal = max(max(fire, earth), max(air, water))
        if (maxVal <= 0.0) return copy()
        val scale = target / maxVal
        return ElementVector(
            fire = (fire * scale).roundedTo(2),
            earth = (earth * scale).roundedTo(2),
            air = (air * scale).roundedTo(2),
            water = (water * scale).roundedTo(2),
        )
    }

    /** iOS `dotProduct` — average of component products. */
    fun dotProduct(other: ElementVector): Double =
        (fire * other.fire + earth * other.earth + air * other.air + water * other.water) / 4.0

    fun roundedTo(decimals: Int): ElementVector = ElementVector(
        fire = fire.roundedTo(decimals),
        earth = earth.roundedTo(decimals),
        air = air.roundedTo(decimals),
        water = water.roundedTo(decimals),
    )

    operator fun plus(other: ElementVector): ElementVector = ElementVector(
        fire = fire + other.fire,
        earth = earth + other.earth,
        air = air + other.air,
        water = water + other.water,
    )

    operator fun minus(other: ElementVector): ElementVector = ElementVector(
        fire = fire - other.fire,
        earth = earth - other.earth,
        air = air - other.air,
        water = water - other.water,
    )

    operator fun times(scalar: Double): ElementVector = ElementVector(
        fire = fire * scalar,
        earth = earth * scalar,
        air = air * scalar,
        water = water * scalar,
    )

    operator fun div(scalar: Double): ElementVector {
        if (scalar == 0.0) return copy()
        return ElementVector(
            fire = fire / scalar,
            earth = earth / scalar,
            air = air / scalar,
            water = water / scalar,
        )
    }

    companion object {
        val ZERO = ElementVector()
        val zero get() = ZERO

        fun forSign(sign: Sign): ElementVector = when (sign) {
            Sign.ARIES -> ElementVector(4.0, 0.0, 1.0, 0.0)
            Sign.TAURUS -> ElementVector(0.0, 4.0, 0.0, 1.0)
            Sign.GEMINI -> ElementVector(1.0, 0.0, 4.0, 0.0)
            Sign.CANCER -> ElementVector(0.0, 1.0, 0.0, 4.0)
            Sign.LEO -> ElementVector(4.0, 0.0, 1.0, 0.0)
            Sign.VIRGO -> ElementVector(0.0, 4.0, 0.0, 1.0)
            Sign.LIBRA -> ElementVector(1.0, 0.0, 4.0, 0.0)
            Sign.SCORPIO -> ElementVector(0.0, 1.0, 0.0, 4.0)
            Sign.OPHIUCHUS -> ElementVector(1.0, 1.0, 2.0, 5.0)
            Sign.SAGITTARIUS -> ElementVector(4.0, 0.0, 1.0, 0.0)
            Sign.CAPRICORN -> ElementVector(0.0, 4.0, 0.0, 1.0)
            Sign.AQUARIUS -> ElementVector(1.0, 0.0, 4.0, 0.0)
            Sign.PISCES -> ElementVector(0.0, 1.0, 0.0, 4.0)
        }

        fun forHouse(house: House): ElementVector = when (house) {
            House.FIRST -> ElementVector(3.0, 0.0, 1.0, 0.0)
            House.SECOND -> ElementVector(0.0, 4.0, 0.0, 1.0)
            House.THIRD -> ElementVector(1.0, 0.0, 4.0, 0.0)
            House.FOURTH -> ElementVector(0.0, 1.0, 0.0, 4.0)
            House.FIFTH -> ElementVector(4.0, 0.0, 1.0, 0.0)
            House.SIXTH -> ElementVector(0.0, 4.0, 0.0, 1.0)
            House.SEVENTH -> ElementVector(1.0, 0.0, 4.0, 0.0)
            House.EIGHTH -> ElementVector(0.0, 1.0, 0.0, 4.0)
            House.NINTH -> ElementVector(4.0, 0.0, 1.0, 0.0)
            House.TENTH -> ElementVector(0.0, 4.0, 0.0, 1.0)
            House.ELEVENTH -> ElementVector(1.0, 0.0, 4.0, 0.0)
            House.TWELFTH -> ElementVector(0.0, 1.0, 0.0, 4.0)
        }

        fun phaseDelta(phase: MoonPhase): ElementVector = when (phase) {
            MoonPhase.NEW_MOON -> ElementVector(1.0, 0.0, 0.0, 2.0)
            MoonPhase.WAXING_CRESCENT -> ElementVector(1.0, 0.0, 1.0, 1.0)
            MoonPhase.FIRST_QUARTER -> ElementVector(2.0, 0.0, 1.0, 0.0)
            MoonPhase.WAXING_GIBBOUS -> ElementVector(1.0, 1.0, 0.0, 1.0)
            MoonPhase.FULL_MOON -> ElementVector(0.0, 0.0, 2.0, 2.0)
            MoonPhase.WANING_GIBBOUS -> ElementVector(0.0, 1.0, 1.0, 1.0)
            MoonPhase.LAST_QUARTER -> ElementVector(0.0, 2.0, 0.0, 1.0)
            MoonPhase.WANING_CRESCENT -> ElementVector(0.0, 1.0, 0.0, 3.0)
        }

        fun transitDelta(planet: Planet, aspect: Aspect): ElementVector? {
            val table: Map<Planet, Map<Aspect, ElementVector>> = mapOf(
                Planet.MOON to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 0.0, 3.0),
                    Aspect.TRINE to ElementVector(0.0, 0.0, 1.0, 2.0),
                    Aspect.SQUARE to ElementVector(2.0, 0.0, 0.0, 1.0),
                    Aspect.SEXTILE to ElementVector(0.0, 0.0, 1.0, 1.5),
                ),
                Planet.VENUS to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.0, 1.0, 1.0, 2.0),
                    Aspect.TRINE to ElementVector(0.0, 1.0, 0.0, 1.0),
                    Aspect.SEXTILE to ElementVector(0.5, 0.5, 0.5, 1.0),
                ),
                Planet.MARS to mapOf(
                    Aspect.CONJUNCTION to ElementVector(3.0, 0.0, 1.0, 0.0),
                    Aspect.SQUARE to ElementVector(3.0, 0.0, 0.0, -1.0),
                    Aspect.TRINE to ElementVector(2.0, 0.0, 0.5, 0.0),
                ),
                Planet.JUPITER to mapOf(
                    Aspect.CONJUNCTION to ElementVector(2.0, 1.0, 1.0, 1.0),
                    Aspect.TRINE to ElementVector(1.0, 1.0, 1.0, 1.0),
                    Aspect.SEXTILE to ElementVector(1.5, 0.5, 1.0, 0.5),
                ),
                Planet.SATURN to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.0, 3.0, 0.0, 0.0),
                    Aspect.TRINE to ElementVector(0.0, 2.0, 0.0, 0.0),
                    Aspect.SQUARE to ElementVector(-1.0, 2.0, 0.0, 0.0),
                ),
                Planet.URANUS to mapOf(
                    Aspect.CONJUNCTION to ElementVector(1.0, 0.0, 3.0, 0.0),
                    Aspect.TRINE to ElementVector(0.5, 0.0, 2.0, 0.0),
                ),
                Planet.NEPTUNE to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 1.0, 3.0),
                    Aspect.TRINE to ElementVector(0.0, 0.0, 1.0, 2.0),
                    Aspect.SEXTILE to ElementVector(0.0, 0.0, 0.5, 1.5),
                ),
                Planet.PLUTO to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 0.0, 4.0),
                    Aspect.TRINE to ElementVector(0.0, 0.0, 0.0, 2.5),
                    Aspect.SQUARE to ElementVector(0.0, 0.0, 0.0, 2.0),
                ),
                Planet.CHIRON to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.5, 0.0, 1.0, 2.0),
                    Aspect.TRINE to ElementVector(0.0, 0.0, 0.5, 1.5),
                ),
                Planet.LILITH to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.0, 0.0, 0.0, 1.5),
                    Aspect.SQUARE to ElementVector(0.0, 0.0, 0.0, 1.0),
                ),
                Planet.NORTH_NODE to mapOf(
                    Aspect.CONJUNCTION to ElementVector(0.5, 0.5, 0.5, 1.0),
                ),
            )
            return table[planet]?.get(aspect)
        }
    }
}

fun Double.roundedTo(decimals: Int): Double {
    val multiplier = 10.0.pow(decimals)
    return round(this * multiplier) / multiplier
}
