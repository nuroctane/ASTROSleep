package com.astrosleep.app.core.model

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class ThemeConfig(
    val accentColorHex: String = "5856D6",
    val backgroundColorHex: String? = null,
    val backgroundImagePath: String? = null,
    val useSystemAppearance: Boolean = true,
)

@Serializable
data class UserProfile(
    val id: String,
    val name: String = "",
    val birthDateEpochMs: Long = 0L,
    val birthTimeEpochMs: Long? = null,
    val birthLat: Double = 0.0,
    val birthLng: Double = 0.0,
    val birthCity: String = "",
    val currentLat: Double = 0.0,
    val currentLng: Double = 0.0,
    val currentCity: String = "",
    val useCurrentLocationForTransits: Boolean = false,
    val baseScore: ElementVector = ElementVector.ZERO,
    val natalChart: NatalChart? = null,
    val hasCompletedOnboarding: Boolean = false,
    val cachedTierDisplayOnly: SubscriptionTier = SubscriptionTier.FREE,
    val selectedVoiceId: String = "female",
    val globalAffirmationSpeed: Double = 1.0,
    val globalAffirmationPitch: Double = 0.0,
    val sleepTimerDefault: Int = 60,
    val notificationEnabled: Boolean = false,
    val bedtimeReminderEpochMs: Long? = null,
    val themeConfig: ThemeConfig = ThemeConfig(),
)

@Serializable
data class EQProfile(
    val bass: Double = 0.5,
    val mid: Double = 0.5,
    val treble: Double = 0.5,
) {
    companion object {
        val DEFAULT = EQProfile()
        val DEEP = EQProfile(bass = 0.85, mid = 0.50, treble = 0.20)
        val MID = EQProfile(bass = 0.55, mid = 0.80, treble = 0.45)
        val BRIGHT = EQProfile(bass = 0.30, mid = 0.60, treble = 0.85)
        val FULL = EQProfile(bass = 0.65, mid = 0.70, treble = 0.55)
        val SUB = EQProfile(bass = 0.95, mid = 0.40, treble = 0.15)
        val ULTRASONIC = EQProfile(bass = 0.20, mid = 0.45, treble = 0.95)

        fun profileForRegister(register: String): EQProfile = when (register) {
            "sub" -> SUB
            "deep" -> DEEP
            "mid" -> MID
            "bright" -> BRIGHT
            "full" -> FULL
            "ultrasonic" -> ULTRASONIC
            else -> DEFAULT
        }
    }
}

@Serializable
data class OscillationConfig(
    val enabled: Boolean = false,
    val waveform: Waveform = Waveform.SINE,
    val periodSeconds: Double = 45.0,
    val minVolume: Double = 0.5,
    val maxVolume: Double = 0.85,
    val phaseOffset: Double = 0.0,
) {
    companion object {
        val DISABLED = OscillationConfig(enabled = false)
    }
}

@Serializable
data class AmbientLayer(
    val id: String = UUID.randomUUID().toString(),
    val soundId: String,
    val layerType: LayerType = LayerType.AMBIENT,
    val volume: Double = 0.7,
    val playbackSpeed: Double = 1.0,
    val eq: EQProfile = EQProfile.DEFAULT,
    val oscillation: OscillationConfig? = null,
)

@Serializable
data class AffirmationLayer(
    val id: String = UUID.randomUUID().toString(),
    val layerType: LayerType = LayerType.AFFIRMATION,
    val voiceId: String = "female",
    val volume: Double = 0.10,
    val playbackSpeed: Double = 1.0,
    val pitchSemitones: Double = 0.0,
    val customVoicePath: String? = null,
    val text: String = "",
    val intervalSeconds: Int = 120,
)

@Serializable
data class Combo(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val createdAtEpochMs: Long = System.currentTimeMillis(),
    val lastPlayedAtEpochMs: Long? = null,
    val source: ComboSource = ComboSource.AUTO,
    val chartSnapshot: ChartSnapshot? = null,
    val layers: List<AmbientLayer> = emptyList(),
    val affirmationLayer: AffirmationLayer = AffirmationLayer(),
    val isReadOnly: Boolean = false,
    val isFavorite: Boolean = false,
    val sleepTimerMinutes: Int? = null,
) {
    val layerCount: Int get() = layers.size
}

@Serializable
data class SessionLog(
    val id: String = UUID.randomUUID().toString(),
    val dateEpochMs: Long = System.currentTimeMillis(),
    val intention: String = "",
    val affirmationScript: String = "",
    val customVoicePath: String? = null,
    val comboId: String? = null,
    val durationMinutes: Int = 0,
    val timerFired: Boolean = false,
    val tier: SubscriptionTier = SubscriptionTier.FREE,
    val moonPhase: MoonPhase = MoonPhase.NEW_MOON,
    val layerCount: Int = 0,
)

@Serializable
data class AffirmationCache(
    val id: String, // calendar date "YYYY-MM-DD"
    val script: String,
    val generatedAtEpochMs: Long,
    val intention: String,
)

@Serializable
data class GeocodingResult(
    val city: String,
    val lat: Double,
    val lng: Double,
    val timezone: String = "",
)
