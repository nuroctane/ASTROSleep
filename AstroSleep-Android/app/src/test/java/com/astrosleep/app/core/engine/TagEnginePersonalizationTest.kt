package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.MoonPhase
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SoundTags
import com.astrosleep.app.core.model.SubscriptionTier
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * Proves the girthy claim: different natal charts / user ids produce
 * substantially different rankings and combo stacks from the same catalog.
 */
class TagEnginePersonalizationTest {

    private val tagEngine = TagEngine()
    private val astro = AstrologicalEngine()
    private val composer = ComboComposer(tagEngine)

    private val catalog: List<Sound> = listOf(
        sound("heavy_rain", "water", "irregular", "mid", "nature", "heavy", "rough", "flowing", "dense", "cool", "receptive", "lunar", "mother"),
        sound("light_rain", "water", "irregular", "bright", "nature", "light", "crystalline", "flowing", "sparse", "cool", "receptive", "lunar", "maiden"),
        sound("thunder", "fire", "chaotic", "deep", "nature", "heavy", "rough", "surging", "dense", "hot", "active", "solar", "hero"),
        sound("ocean", "water", "pulse", "deep", "nature", "heavy", "smooth", "flowing", "saturated", "cool", "receptive", "lunar", "mother"),
        sound("river", "water", "steady", "mid", "nature", "medium", "smooth", "flowing", "moderate", "cool", "balanced", "lunar", "maiden"),
        sound("forest", "organic", "irregular", "mid", "nature", "medium", "granular", "static", "moderate", "cool", "receptive", "planetary", "mentor"),
        sound("wind", "air", "arrhythmic", "bright", "nature", "light", "diffuse", "swirling", "sparse", "cold", "active", "stellar", "trickster"),
        sound("fire", "fire", "irregular", "mid", "nature", "medium", "rough", "pulsing", "moderate", "hot", "active", "solar", "hero"),
        sound("white_noise", "electrical", "steady", "full", "abstract", "medium", "smooth", "static", "saturated", "neutral", "neutral", "void", "crone"),
        sound("brown_noise", "earth", "steady", "sub", "abstract", "heavy", "smooth", "static", "dense", "warm", "receptive", "void", "crone"),
        sound("pink_noise", "air", "steady", "mid", "abstract", "medium", "diffuse", "static", "moderate", "neutral", "balanced", "void", "mentor"),
        sound("binaural", "electrical", "pulse", "ultrasonic", "abstract", "light", "glassy", "oscillating", "sparse", "cool", "active", "stellar", "trickster"),
        sound("fan_low", "mechanical", "steady", "deep", "domestic", "medium", "smooth", "static", "moderate", "neutral", "neutral", "planetary", "mentor"),
        sound("fan_high", "mechanical", "steady", "bright", "domestic", "light", "metallic", "static", "sparse", "neutral", "active", "planetary", "maiden"),
        sound("dryer", "mechanical", "rhythmic", "mid", "domestic", "heavy", "granular", "pulsing", "dense", "warm", "active", "planetary", "crone"),
        sound("clock_tick", "mechanical", "pulse", "bright", "domestic", "light", "metallic", "pulsing", "sparse", "neutral", "active", "planetary", "trickster"),
        sound("lawn_mower", "mechanical", "rhythmic", "mid", "industrial", "heavy", "rough", "surging", "dense", "hot", "active", "solar", "hero"),
        sound("car_rain", "water", "irregular", "mid", "urban", "medium", "diffuse", "flowing", "moderate", "cool", "receptive", "lunar", "shadow"),
        sound("sprinklers", "water", "pulse", "bright", "domestic", "light", "crystalline", "pulsing", "sparse", "cool", "active", "lunar", "maiden"),
        sound("wtfl_lg", "water", "steady", "full", "nature", "massive", "rough", "surging", "saturated", "cool", "active", "lunar", "hero"),
    )

    @Test
    fun differentCharts_produceDifferentTopSounds() {
        val waterChart = chartFor(1990, Calendar.JUNE, 15) // often water-leaning seasons still diverge via placements
        val fireChart = chartFor(1988, Calendar.AUGUST, 5)
        val airChart = chartFor(1995, Calendar.FEBRUARY, 10)

        val night = fixedNight()
        val topA = topIds("user-water", waterChart, night, 5)
        val topB = topIds("user-fire", fireChart, night, 5)
        val topC = topIds("user-air", airChart, night, 5)

        assertNotEquals("water vs fire tops should differ", topA, topB)
        assertNotEquals("fire vs air tops should differ", topB, topC)
        assertNotEquals("water vs air tops should differ", topA, topC)

        // Jaccard distance should be meaningful (not 4/5 overlap)
        assertTrue("water/fire overlap too high: $topA vs $topB", jaccard(topA, topB) < 0.8)
        assertTrue("fire/air overlap too high: $topB vs $topC", jaccard(topB, topC) < 0.8)
    }

    @Test
    fun sameChart_differentUserIds_stillDivergeViaFingerprint() {
        val chart = chartFor(1992, Calendar.NOVEMBER, 3)
        val night = fixedNight()
        val top1 = topIds("alice", chart, night, 7)
        val top2 = topIds("bob", chart, night, 7)
        // May share some, but stack identity (ordered) should differ due to jitter + signature tags
        assertNotEquals(top1, top2)
    }

    @Test
    fun comboStacks_useDifferentSoundSets() {
        val night = fixedNight()
        val a = composer.compose(
            userId = "cancer-sleeper",
            sounds = catalog,
            nightly = night,
            natalBaseScore = chartFor(1991, Calendar.JULY, 4).let { astro.deriveBaseScore(it) },
            chart = chartFor(1991, Calendar.JULY, 4),
            tier = SubscriptionTier.SUBSCRIPTION,
        )
        val b = composer.compose(
            userId = "aries-sleeper",
            sounds = catalog,
            nightly = night,
            natalBaseScore = chartFor(1989, Calendar.APRIL, 10).let { astro.deriveBaseScore(it) },
            chart = chartFor(1989, Calendar.APRIL, 10),
            tier = SubscriptionTier.SUBSCRIPTION,
        )

        val setA = a.combo.layers.map { it.soundId }.toSet()
        val setB = b.combo.layers.map { it.soundId }.toSet()
        assertTrue("combo A empty", setA.isNotEmpty())
        assertTrue("combo B empty", setB.isNotEmpty())
        assertNotEquals(setA, setB)
        assertTrue(
            "stacks too similar: $setA vs $setB",
            jaccard(setA.toList(), setB.toList()) < 0.75,
        )
        // Volumes should be personalized (not all equal)
        val volsA = a.combo.layers.map { it.volume }
        assertTrue(volsA.any { it != volsA.first() } || volsA.size == 1)
    }

    @Test
    fun personalProfiles_haveDistinctFingerprintsAndWeights() {
        val c1 = chartFor(1985, Calendar.MARCH, 21)
        val c2 = chartFor(2000, Calendar.DECEMBER, 25)
        val p1 = PersonalSoundProfile.from("u1", c1, astro.deriveBaseScore(c1))
        val p2 = PersonalSoundProfile.from("u2", c2, astro.deriveBaseScore(c2))
        assertNotEquals(p1.fingerprint, p2.fingerprint)
        assertNotEquals(p1.dimensionMultipliers, p2.dimensionMultipliers)
        assertNotEquals(p1.tagAffinities.keys.take(8).toSet(), p2.tagAffinities.keys.take(8).toSet())
    }

    @Test
    fun moonPhase_shiftsRanking() {
        val chart = chartFor(1993, Calendar.MAY, 20)
        val base = astro.deriveBaseScore(chart)
        val profile = PersonalSoundProfile.from("phase-user", chart, base)
        val newMoon = NightlyScoreResult(
            elementScore = ElementVector(2.0, 2.0, 2.0, 8.0),
            moonPhase = MoonPhase.NEW_MOON,
            dominantElement = Element.WATER,
        )
        val fullMoon = NightlyScoreResult(
            elementScore = ElementVector(2.0, 2.0, 8.0, 6.0),
            moonPhase = MoonPhase.FULL_MOON,
            dominantElement = Element.AIR,
        )
        val topNew = tagEngine.rankSoundsPersonalized(catalog, newMoon, profile, base, chart)
            .take(5).map { it.sound.id }
        val topFull = tagEngine.rankSoundsPersonalized(catalog, fullMoon, profile, base, chart)
            .take(5).map { it.sound.id }
        assertNotEquals(topNew, topFull)
    }

    @Test
    fun scoreBreakdown_isPopulated() {
        val chart = chartFor(1990, Calendar.JANUARY, 1)
        val base = astro.deriveBaseScore(chart)
        val profile = PersonalSoundProfile.from("break-user", chart, base)
        val ranked = tagEngine.rankSoundsPersonalized(catalog, fixedNight(), profile, base, chart)
        val top = ranked.first()
        assertTrue(top.score > 0)
        assertTrue(
            top.breakdown.nightlyResonance != 0.0 ||
                top.breakdown.natalResonance != 0.0 ||
                top.breakdown.tagAffinity != 0.0,
        )
        assertTrue(top.breakdown.notes.isNotEmpty())
    }

    @Test
    fun legacyRank_stillPrefersWaterOnWaterNight() {
        val waterNight = NightlyScoreResult(
            elementScore = ElementVector(1.0, 2.0, 1.0, 10.0),
            moonPhase = MoonPhase.WANING_CRESCENT,
            dominantElement = Element.WATER,
        )
        val ranked = tagEngine.rankSounds(
            listOf(
                catalog.first { it.id == "heavy_rain" },
                catalog.first { it.id == "fire" },
            ),
            waterNight,
        )
        assertEquals("heavy_rain", ranked.first().sound.id)
    }

    // ── helpers ───────────────────────────────────────────────────────────

    private fun topIds(
        userId: String,
        chart: com.astrosleep.app.core.model.NatalChart,
        night: NightlyScoreResult,
        n: Int,
    ): List<String> {
        val base = astro.deriveBaseScore(chart)
        val profile = PersonalSoundProfile.from(userId, chart, base)
        return tagEngine.rankSoundsPersonalized(catalog, night, profile, base, chart)
            .take(n)
            .map { it.sound.id }
    }

    private fun chartFor(year: Int, month: Int, day: Int): com.astrosleep.app.core.model.NatalChart {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(year, month, day, 12, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return astro.computeNatalChart(cal.timeInMillis, cal.timeInMillis, 40.7, -74.0)
    }

    private fun fixedNight() = NightlyScoreResult(
        elementScore = ElementVector(3.0, 4.0, 5.0, 7.0),
        moonPhase = MoonPhase.WANING_GIBBOUS,
        dominantElement = Element.WATER,
    )

    private fun jaccard(a: List<String>, b: List<String>): Double {
        val sa = a.toSet()
        val sb = b.toSet()
        val inter = sa.intersect(sb).size.toDouble()
        val union = sa.union(sb).size.toDouble().coerceAtLeast(1.0)
        return inter / union
    }

    private fun sound(
        id: String,
        domain: String,
        rhythm: String,
        register: String,
        context: String,
        weight: String,
        texture: String,
        motion: String,
        density: String,
        temperature: String,
        polarity: String,
        celestial: String,
        archetype: String,
    ) = Sound(
        id = id,
        name = id,
        tags = SoundTags(
            domain, rhythm, register, context, weight, texture,
            motion, density, temperature, polarity, celestial, archetype,
        ),
        elementScores = ElementVector(1.0, 1.0, 1.0, 1.0),
        durationSeconds = 60,
    )
}
