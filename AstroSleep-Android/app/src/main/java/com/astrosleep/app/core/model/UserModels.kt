package com.astrosleep.app.core.model

import kotlinx.serialization.Serializable

@Serializable
enum class SubscriptionTier {
    FREE,
    BASIC,
    PRO,
}

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
    val hasCompletedOnboarding: Boolean = false,
    val cachedTierDisplayOnly: SubscriptionTier = SubscriptionTier.FREE,
    val selectedVoiceId: String = "",
    val globalAffirmationSpeed: Double = 1.0,
    val globalAffirmationPitch: Double = 0.0,
    val sleepTimerDefault: Int = 60,
    val notificationEnabled: Boolean = false,
    val bedtimeReminderEpochMs: Long? = null,
    val themeConfig: ThemeConfig = ThemeConfig(),
)

@Serializable
data class AmbientLayer(
    val id: String,
    val soundId: String,
    val volume: Double = 0.7,
    val speed: Double = 1.0,
    val pan: Double = 0.0,
    val lfoEnabled: Boolean = false,
    val lfoRate: Double = 0.05,
    val lfoDepth: Double = 0.15,
)

@Serializable
data class AffirmationLayer(
    val id: String,
    val text: String = "",
    val volume: Double = 0.5,
    val intervalSeconds: Int = 120,
)

@Serializable
data class Combo(
    val id: String,
    val name: String,
    val ambientLayers: List<AmbientLayer> = emptyList(),
    val affirmationLayer: AffirmationLayer? = null,
    val sleepTimerMinutes: Int? = null,
    val isFavorite: Boolean = false,
    val createdAtEpochMs: Long = System.currentTimeMillis(),
)
