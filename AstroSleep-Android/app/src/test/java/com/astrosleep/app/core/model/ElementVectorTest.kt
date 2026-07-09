package com.astrosleep.app.core.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ElementVectorTest {
    @Test
    fun normalize_scalesPeakToTarget() {
        val v = ElementVector(fire = 1.0, earth = 2.0, air = 4.0, water = 8.0).normalize(10.0)
        assertEquals(10.0, v.water, 1e-9)
        assertEquals(5.0, v.air, 1e-9)
    }

    @Test
    fun dominant_picksStrongest_fireFirstOnTieBreakStyle() {
        val v = ElementVector(fire = 1.0, earth = 9.0, air = 2.0, water = 3.0)
        assertEquals(Element.EARTH, v.dominant())
    }

    @Test
    fun plusAndTimes_matchIosArithmetic() {
        val a = ElementVector(1.0, 1.0, 1.0, 1.0)
        val b = a * 2.0 + ElementVector(1.0, 0.0, 0.0, 0.0)
        assertEquals(3.0, b.fire, 1e-9)
        assertEquals(2.0, b.earth, 1e-9)
    }

    @Test
    fun forSign_ophiuchusIsWaterDominant() {
        val v = ElementVector.forSign(Sign.OPHIUCHUS)
        assertEquals(Element.WATER, v.dominant())
        assertEquals(5.0, v.water, 1e-9)
    }

    @Test
    fun phaseDelta_fullMoonIsAirWater() {
        val v = ElementVector.phaseDelta(MoonPhase.FULL_MOON)
        assertEquals(2.0, v.air, 1e-9)
        assertEquals(2.0, v.water, 1e-9)
    }

    @Test
    fun transitDelta_moonConjunctionBoostsWater() {
        val v = ElementVector.transitDelta(Planet.MOON, Aspect.CONJUNCTION)!!
        assertEquals(3.0, v.water, 1e-9)
    }

    @Test
    fun roundedTo_twoDecimals() {
        assertEquals(1.23, 1.2345.roundedTo(2), 1e-9)
    }

    @Test
    fun dotProduct_averagesComponentProducts() {
        val a = ElementVector(2.0, 2.0, 2.0, 2.0)
        val b = ElementVector(2.0, 2.0, 2.0, 2.0)
        assertEquals(4.0, a.dotProduct(b), 1e-9)
    }

    @Test
    fun plus_isImmutableStyle() {
        val v = ElementVector(1.0, 0.0, 0.0, 0.0) + ElementVector(0.0, 2.0, 0.0, 0.0)
        assertEquals(1.0, v.fire, 1e-9)
        assertEquals(2.0, v.earth, 1e-9)
    }
}
