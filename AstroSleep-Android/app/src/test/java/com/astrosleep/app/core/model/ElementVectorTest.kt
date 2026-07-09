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
    fun cosineSimilarity_identicalIsOne() {
        val v = ElementVector(1.0, 2.0, 3.0, 4.0)
        assertEquals(1.0, v.cosineSimilarity(v), 1e-9)
    }

    @Test
    fun dominant_picksStrongest() {
        val v = ElementVector(fire = 1.0, earth = 9.0, air = 2.0, water = 3.0)
        assertEquals(Element.EARTH, v.dominant())
    }

    @Test
    fun plusAndTimes() {
        val a = ElementVector(1.0, 1.0, 1.0, 1.0)
        val b = a * 2.0 + ElementVector(1.0, 0.0, 0.0, 0.0)
        assertTrue(b.fire > 2.9)
    }
}
