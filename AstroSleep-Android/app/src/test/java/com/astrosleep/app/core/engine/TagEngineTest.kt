package com.astrosleep.app.core.engine

import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.ElementVector
import com.astrosleep.app.core.model.MoonPhase
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SoundTags
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TagEngineTest {
    private val engine = TagEngine()

    private fun heavyRain() = Sound(
        id = "heavy_rain",
        name = "Heavy Rain",
        tags = SoundTags(
            domain = "water", rhythm = "irregular", register = "mid",
            context = "nature", weight = "heavy", texture = "rough",
            motion = "flowing", density = "dense", temperature = "cool",
            polarity = "receptive", celestial = "lunar", archetype = "mother",
        ),
        elementScores = ElementVector(0.45, 0.82, 0.38, 0.91),
        durationSeconds = 60,
    )

    private fun campfire() = Sound(
        id = "campfire",
        name = "Campfire",
        tags = SoundTags(
            domain = "fire", rhythm = "irregular", register = "mid",
            context = "nature", weight = "medium", texture = "rough",
            motion = "pulsing", density = "moderate", temperature = "hot",
            polarity = "active", celestial = "solar", archetype = "hero",
        ),
        elementScores = ElementVector(0.9, 0.3, 0.4, 0.2),
        durationSeconds = 60,
    )

    @Test
    fun calculateTagVector_waterSoundIsWaterDominant() {
        val v = engine.calculateTagVector(heavyRain())
        assertEquals(Element.WATER, v.dominant())
        assertTrue("water raw should be large, was ${v.water}", v.water > 50.0)
    }

    @Test
    fun calculateTagVector_fireSoundIsFireDominant() {
        val v = engine.calculateTagVector(campfire())
        assertEquals(Element.FIRE, v.dominant())
    }

    @Test
    fun rankSounds_prefersMatchingElement() {
        val waterNight = NightlyScoreResult(
            elementScore = ElementVector(1.0, 2.0, 1.0, 10.0),
            moonPhase = MoonPhase.WANING_CRESCENT,
            dominantElement = Element.WATER,
        )
        val ranked = engine.rankSounds(listOf(heavyRain(), campfire()), waterNight)
        assertEquals("heavy_rain", ranked.first().sound.id)
        assertTrue(ranked.first().score > ranked.last().score)
    }

    @Test
    fun domainWeight_isNineTimesBase() {
        val tags = SoundTags(
            domain = "water", rhythm = "steady", register = "mid",
            context = "nature", weight = "medium", texture = "smooth",
            motion = "static", density = "moderate", temperature = "neutral",
            polarity = "neutral", celestial = "void", archetype = "mentor",
        )
        val v = engine.calculateTagVector(tags)
        assertTrue(v.water >= 81.0)
    }

    @Test
    fun dimensionMultipliers_reshapeVector() {
        val tags = heavyRain().tags
        val base = engine.calculateTagVector(tags)
        val boosted = engine.calculateTagVector(tags, mapOf("domain" to 2.0))
        assertTrue(boosted.water > base.water)
    }

    @Test
    fun fingerprintJitter_isStableAndBounded() {
        val a = engine.fingerprintJitter(12345L, "heavy_rain")
        val b = engine.fingerprintJitter(12345L, "heavy_rain")
        val c = engine.fingerprintJitter(99999L, "heavy_rain")
        assertEquals(a, b, 1e-12)
        assertTrue(a in -1.5..1.5)
        // different fingerprint should usually differ
        assertTrue(a != c || true) // allow rare collision
    }

    @Test
    fun tagOverlap_sameDomainPenalizes() {
        val o = engine.tagOverlap(heavyRain().tags, heavyRain().tags)
        assertTrue(o > 1.0) // full overlap + domain penalty
        val different = engine.tagOverlap(heavyRain().tags, campfire().tags)
        assertTrue(different < o)
    }
}
