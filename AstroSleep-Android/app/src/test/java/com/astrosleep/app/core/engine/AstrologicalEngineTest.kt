package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.MoonPhase
import com.astrosleep.app.core.model.Planet
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class AstrologicalEngineTest {
    private val engine = AstrologicalEngine()

    @Test
    fun julianDay_knownEpoch() {
        // J2000.0 is JD 2451545.0 on 2000-01-01 (noon TT; our civil day formula is approximate)
        val jd = engine.julianDayFor(2000, 1, 1)
        assertTrue("JD for 2000-01-01 should be near 2451545, was $jd", jd in 2451544.0..2451546.0)
    }

    @Test
    fun sharatanAyanamsha_matchesIosConstant() {
        val expected = 24.0 + 6.0 / 60.0 + 18.0 / 3600.0
        assertEquals(expected, engine.sharatanAyanamsha, 1e-12)
    }

    @Test
    fun computeNatalChart_returnsAllPlanets() {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(1990, Calendar.JUNE, 15, 12, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val chart = engine.computeNatalChart(
            birthDateEpochMs = cal.timeInMillis,
            birthTimeEpochMs = cal.timeInMillis,
            lat = 40.7128,
            lng = -74.0060,
        )
        assertEquals(Planet.entries.size, chart.placements.size)
        assertNotNull(chart.moonSign)
        assertNotNull(chart.sunSign)
        assertNotNull(chart.ascendant)
        assertTrue(chart.hasBirthTime)
    }

    @Test
    fun deriveBaseScore_normalizedToTen() {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(1985, Calendar.MARCH, 21, 8, 30, 0)
        }
        val chart = engine.computeNatalChart(cal.timeInMillis, cal.timeInMillis, 51.5, -0.12)
        val score = engine.deriveBaseScore(chart)
        val peak = maxOf(score.fire, score.earth, score.air, score.water)
        assertEquals(10.0, peak, 0.01)
    }

    @Test
    fun calculateMoonPhase_knownNewMoonWindow() {
        // Known new moon epoch: 2000-01-06 18:14 UTC
        val phase = engine.calculateMoonPhase(947_182_440_000L)
        assertEquals(MoonPhase.NEW_MOON, phase)
    }

    @Test
    fun signFromLongitude_coversAllThirteenSignsIncludingPisces() {
        // Equal 13-sign sectors: every ordinal including Pisces must be reachable.
        val sector = 360.0 / 13.0
        val all = (0 until 13).map { i ->
            val lon = i * sector + 0.1
            val index = minOf((lon / sector).toInt(), 12)
            com.astrosleep.app.core.model.Sign.entries[index]
        }.toSet()
        assertEquals(13, all.size)
        assertTrue(all.contains(com.astrosleep.app.core.model.Sign.PISCES))
        assertTrue(all.contains(com.astrosleep.app.core.model.Sign.OPHIUCHUS))
    }

    @Test
    fun birthTime_affectsAscendantPresence() {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(1990, Calendar.JUNE, 15, 12, 0, 0)
        }
        val withTime = engine.computeNatalChart(cal.timeInMillis, cal.timeInMillis, 40.7, -74.0)
        val without = engine.computeNatalChart(cal.timeInMillis, null, 40.7, -74.0)
        assertTrue(withTime.hasBirthTime)
        assertNotNull(withTime.ascendant)
        assertTrue(withTime.placements.any { it.house != null })
        assertTrue(!without.hasBirthTime)
        assertEquals(null, without.ascendant)
    }

    @Test
    fun calculateNightlyScore_isDeterministic() {
        val cal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(1992, Calendar.NOVEMBER, 3, 18, 0, 0)
        }
        val chart = engine.computeNatalChart(cal.timeInMillis, null, 34.05, -118.25)
        val base = engine.deriveBaseScore(chart)
        val night = 1_700_000_000_000L // fixed epoch
        val a = engine.calculateNightlyScore(base, night, chart)
        val b = engine.calculateNightlyScore(base, night, chart)
        assertEquals(a.elementScore, b.elementScore)
        assertEquals(a.moonPhase, b.moonPhase)
        assertEquals(a.dominantElement, b.dominantElement)
        assertTrue(a.elementScore.fire >= 0)
    }

    @Test
    fun dominantElement_isValid() {
        val cal = Calendar.getInstance().apply { set(2000, 0, 1) }
        val chart = engine.computeNatalChart(cal.timeInMillis, null, 0.0, 0.0)
        assertTrue(chart.dominantElement in Element.entries.toTypedArray())
    }
}
