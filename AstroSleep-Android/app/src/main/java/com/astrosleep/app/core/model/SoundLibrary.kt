package com.astrosleep.app.core.model

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Loads the 12-dim sound catalog from assets/sounds/sounds_manifest.json.
 * Port of iOS SoundLibrary — O(1) lookup by id.
 */
@Singleton
class SoundLibrary @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    val sounds: List<Sound> by lazy { loadSounds() }

    private val soundById: Map<String, Sound> by lazy {
        sounds.associateBy { it.id }
    }

    fun sound(id: String): Sound? = soundById[id]

    private fun loadSounds(): List<Sound> {
        return try {
            context.assets.open("sounds/sounds_manifest.json").use { stream ->
                val text = stream.bufferedReader().readText()
                val manifest = json.decodeFromString<SoundManifest>(text)
                android.util.Log.i(TAG, "Loaded ${manifest.sounds.size} sounds from manifest v${manifest.version}")
                manifest.sounds
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "Failed to load sounds_manifest.json — using embedded fallback", e)
            defaultSounds()
        }
    }

    companion object {
        private const val TAG = "SoundLibrary"

        /** Minimal embedded fallback when assets are missing. */
        fun defaultSounds(): List<Sound> = listOf(
            Sound(
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
                cdnUrl = "https://cdn.astrosleep.app/sounds/heavy_rain.m4a",
                bundleFilename = "heavy_rain.m4a",
            ),
            Sound(
                id = "light_rain",
                name = "Light Rain",
                tags = SoundTags(
                    domain = "water", rhythm = "irregular", register = "bright",
                    context = "nature", weight = "light", texture = "crystalline",
                    motion = "flowing", density = "sparse", temperature = "cool",
                    polarity = "receptive", celestial = "lunar", archetype = "maiden",
                ),
                elementScores = ElementVector(0.40, 0.55, 0.62, 0.88),
                durationSeconds = 45,
                cdnUrl = "https://cdn.astrosleep.app/sounds/light_rain.m4a",
                bundleFilename = "light_rain.m4a",
            ),
        )
    }
}
