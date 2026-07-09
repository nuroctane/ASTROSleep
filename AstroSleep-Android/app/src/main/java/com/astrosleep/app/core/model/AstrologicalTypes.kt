package com.astrosleep.app.core.model

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
enum class Element(val displayName: String) {
    FIRE("Fire"),
    EARTH("Earth"),
    AIR("Air"),
    WATER("Water");

    val index: Int get() = ordinal
}

@Serializable
enum class Modality(val displayName: String) {
    CARDINAL("Cardinal"),
    FIXED("Fixed"),
    MUTABLE("Mutable"),
}

/** Sidereal 13-sign zodiac (includes Ophiuchus). */
@Serializable
enum class Sign(val displayName: String) {
    ARIES("Aries"),
    TAURUS("Taurus"),
    GEMINI("Gemini"),
    CANCER("Cancer"),
    LEO("Leo"),
    VIRGO("Virgo"),
    LIBRA("Libra"),
    SCORPIO("Scorpio"),
    OPHIUCHUS("Ophiuchus"),
    SAGITTARIUS("Sagittarius"),
    CAPRICORN("Capricorn"),
    AQUARIUS("Aquarius"),
    PISCES("Pisces");

    val index: Int get() = ordinal

    val element: Element
        get() = when (this) {
            ARIES, LEO, SAGITTARIUS -> Element.FIRE
            TAURUS, VIRGO, CAPRICORN -> Element.EARTH
            GEMINI, LIBRA, AQUARIUS -> Element.AIR
            CANCER, SCORPIO, OPHIUCHUS, PISCES -> Element.WATER
        }

    val modality: Modality
        get() = when (this) {
            ARIES, CANCER, LIBRA, CAPRICORN -> Modality.CARDINAL
            TAURUS, LEO, SCORPIO, OPHIUCHUS, AQUARIUS -> Modality.FIXED
            GEMINI, VIRGO, SAGITTARIUS, PISCES -> Modality.MUTABLE
        }
}

@Serializable
enum class Planet(val displayName: String) {
    SUN("Sun"),
    MOON("Moon"),
    MERCURY("Mercury"),
    VENUS("Venus"),
    MARS("Mars"),
    JUPITER("Jupiter"),
    SATURN("Saturn"),
    URANUS("Uranus"),
    NEPTUNE("Neptune"),
    PLUTO("Pluto"),
    CHIRON("Chiron"),
    LILITH("Lilith"),
    NORTH_NODE("North Node"),
    SOUTH_NODE("South Node");

    /** Weight in BaseScore calculation (iOS parity). */
    val baseScoreWeight: Double
        get() = when (this) {
            MOON -> 4.0
            SUN -> 2.0
            VENUS -> 1.5
            MERCURY, MARS -> 1.0
            JUPITER, NEPTUNE -> 0.8
            SATURN -> 0.7
            PLUTO -> 0.6
            URANUS, CHIRON, NORTH_NODE -> 0.5
            LILITH, SOUTH_NODE -> 0.4
        }

    /**
     * Primary modern rulership. Dual rulers use the first traditional match
     * (iOS uses randomElement — we pick a stable primary for determinism).
     */
    val rulingSign: Sign?
        get() = when (this) {
            SUN -> Sign.LEO
            MOON -> Sign.CANCER
            MERCURY -> Sign.GEMINI
            VENUS -> Sign.TAURUS
            MARS -> Sign.ARIES
            JUPITER -> Sign.SAGITTARIUS
            SATURN -> Sign.CAPRICORN
            URANUS -> Sign.AQUARIUS
            NEPTUNE -> Sign.PISCES
            PLUTO -> Sign.SCORPIO
            CHIRON -> Sign.OPHIUCHUS
            else -> null
        }
}

@Serializable
enum class Aspect(val displayName: String) {
    CONJUNCTION("Conjunction"),
    SEXTILE("Sextile"),
    SQUARE("Square"),
    TRINE("Trine"),
    OPPOSITION("Opposition");

    val angle: Double
        get() = when (this) {
            CONJUNCTION -> 0.0
            SEXTILE -> 60.0
            SQUARE -> 90.0
            TRINE -> 120.0
            OPPOSITION -> 180.0
        }

    val orb: Double
        get() = when (this) {
            SEXTILE -> 6.0
            else -> 8.0
        }
}

@Serializable
enum class MoonPhase(val displayName: String) {
    NEW_MOON("New Moon"),
    WAXING_CRESCENT("Waxing Crescent"),
    FIRST_QUARTER("First Quarter"),
    WAXING_GIBBOUS("Waxing Gibbous"),
    FULL_MOON("Full Moon"),
    WANING_GIBBOUS("Waning Gibbous"),
    LAST_QUARTER("Last Quarter"),
    WANING_CRESCENT("Waning Crescent"),
}

@Serializable
enum class House(val number: Int) {
    FIRST(1), SECOND(2), THIRD(3), FOURTH(4),
    FIFTH(5), SIXTH(6), SEVENTH(7), EIGHTH(8),
    NINTH(9), TENTH(10), ELEVENTH(11), TWELFTH(12);

    companion object {
        fun fromNumber(n: Int): House? = entries.find { it.number == n }
    }
}

/** Matches iOS `SubscriptionTier` in AstrologicalTypes.swift */
@Serializable
enum class SubscriptionTier {
    FREE,
    SUBSCRIPTION,
    LIFETIME;

    val displayName: String
        get() = when (this) {
            FREE -> "Free"
            SUBSCRIPTION -> "Subscription"
            LIFETIME -> "Pro (Lifetime)"
        }

    val maxLayers: Int
        get() = when (this) {
            FREE -> 2
            SUBSCRIPTION, LIFETIME -> 7
        }

    val maxPlaylists: Int
        get() = when (this) {
            FREE -> 5
            else -> Int.MAX_VALUE
        }

    val sessionHistoryDays: Int
        get() = when (this) {
            FREE -> 14
            else -> Int.MAX_VALUE
        }

    val hasCustomVoice: Boolean get() = this != FREE
    val hasBackup: Boolean get() = this != FREE
    val includesFutureFeatures: Boolean get() = this != FREE
}

@Serializable
data class ChartPlacement(
    val planet: Planet,
    val sign: Sign,
    val house: House? = null,
    val degree: Double = 0.0,
    val isRetrograde: Boolean = false,
)

@Serializable
data class AspectarianEntry(
    val id: String = UUID.randomUUID().toString(),
    val planet1: Planet,
    val planet2: Planet,
    val aspect: Aspect,
    val orb: Double,
)

@Serializable
data class Transit(
    val id: String = UUID.randomUUID().toString(),
    val planet: Planet,
    val natalPlanet: Planet,
    val aspectType: Aspect,
    val orb: Double,
    val isApplying: Boolean,
    val angularBoost: Double = 1.0,
) {
    val strength: Double
        get() {
            val baseStrength = when (planet) {
                Planet.MOON -> 3.0
                Planet.VENUS -> 2.0
                Planet.MARS -> 2.5
                Planet.JUPITER -> 1.5
                Planet.SATURN -> 2.0
                Planet.URANUS -> 1.0
                Planet.NEPTUNE -> 2.0
                Planet.PLUTO -> 2.5
                Planet.CHIRON -> 1.5
                Planet.LILITH -> 1.0
                Planet.NORTH_NODE -> 1.0
                Planet.SOUTH_NODE -> 0.5
                else -> 1.0
            }
            val orbFactor = maxOf(0.0, 1.0 - (orb / aspectType.orb))
            return baseStrength * orbFactor * angularBoost
        }
}

@Serializable
data class Stellium(
    val id: String = UUID.randomUUID().toString(),
    val sign: Sign,
    val planets: List<Planet>,
) {
    val count: Int get() = planets.size
}

@Serializable
data class NatalChart(
    val computedAtEpochMs: Long,
    val placements: List<ChartPlacement>,
    val ascendant: Sign? = null,
    val mc: Sign? = null,
    val dominantElement: Element,
    val dominantModality: Modality,
    val aspects: List<AspectarianEntry> = emptyList(),
    val stelliums: List<Sign> = emptyList(),
    val hasBirthTime: Boolean = false,
) {
    fun placement(forPlanet: Planet): ChartPlacement? =
        placements.firstOrNull { it.planet == forPlanet }

    val sunSign: Sign? get() = placement(Planet.SUN)?.sign
    val moonSign: Sign? get() = placement(Planet.MOON)?.sign
    val mercurySign: Sign? get() = placement(Planet.MERCURY)?.sign
    val venusSign: Sign? get() = placement(Planet.VENUS)?.sign
    val marsSign: Sign? get() = placement(Planet.MARS)?.sign
    val jupiterSign: Sign? get() = placement(Planet.JUPITER)?.sign
    val saturnSign: Sign? get() = placement(Planet.SATURN)?.sign
    val uranusSign: Sign? get() = placement(Planet.URANUS)?.sign
    val neptuneSign: Sign? get() = placement(Planet.NEPTUNE)?.sign
    val plutoSign: Sign? get() = placement(Planet.PLUTO)?.sign
    val chironSign: Sign? get() = placement(Planet.CHIRON)?.sign
    val lilithSign: Sign? get() = placement(Planet.LILITH)?.sign
    val northNode: ChartPlacement? get() = placement(Planet.NORTH_NODE)
    val southNode: ChartPlacement? get() = placement(Planet.SOUTH_NODE)
    val moonHouse: House? get() = placement(Planet.MOON)?.house
    val sunHouse: House? get() = placement(Planet.SUN)?.house

    fun houseRuler(house: House): Planet {
        val signIndex = (house.number - 1) % 12
        val houseSign = Sign.entries[signIndex]
        return Planet.entries.firstOrNull { it.rulingSign == houseSign } ?: Planet.SUN
    }
}

@Serializable
data class NightlyScoreResult(
    val elementScore: ElementVector,
    val moonPhase: MoonPhase,
    val activeTransits: List<Transit> = emptyList(),
    val dominantElement: Element,
    val topTransit: Transit? = null,
    val stelliums: List<Stellium> = emptyList(),
) {
    fun toSnapshot(computedAtEpochMs: Long = System.currentTimeMillis()): ChartSnapshot =
        ChartSnapshot(
            moonPhase = moonPhase,
            dominantElement = dominantElement,
            topTransit = topTransit?.planet?.displayName ?: "None",
            aspectarian = emptyList(),
            stelliums = stelliums.map { it.sign.displayName },
            computedAtEpochMs = computedAtEpochMs,
        )
}

@Serializable
data class ChartSnapshot(
    val moonPhase: MoonPhase,
    val dominantElement: Element,
    val topTransit: String,
    val aspectarian: List<AspectarianEntry> = emptyList(),
    val stelliums: List<String> = emptyList(),
    val computedAtEpochMs: Long,
)

@Serializable
enum class ComboSource { AUTO, USER }

@Serializable
enum class LayerType { AMBIENT, AFFIRMATION }

@Serializable
enum class Waveform { SINE, PERLIN, STEP, TRIANGLE }

@Serializable
enum class VoiceOption { FEMALE, MALE, CUSTOM }

@Serializable
enum class AffirmationTone { NEUTRAL, WARM, COMMANDING, WHISPER }

@Serializable
enum class AffirmationLength { SHORT, STANDARD, EXTENDED }

@Serializable
enum class AffirmationEnding { GROUNDING, SLEEP_INDUCTION, GRATITUDE }

enum class AudioState {
    IDLE, LOADING, PLAYING, PAUSED, INTERRUPTED, FADING, STOPPED
}

enum class TabSelection { TONIGHT, COSMOS, SOUNDS, LIBRARY, SETTINGS }
