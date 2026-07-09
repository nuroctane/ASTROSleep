package com.astrosleep.app.state

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.astrosleep.app.core.engine.AstrologicalEngine
import com.astrosleep.app.core.engine.TagEngine
import com.astrosleep.app.core.model.AffirmationCache
import com.astrosleep.app.core.model.AffirmationLayer
import com.astrosleep.app.core.model.AmbientLayer
import com.astrosleep.app.core.model.Combo
import com.astrosleep.app.core.model.ComboSource
import com.astrosleep.app.core.model.Element
import com.astrosleep.app.core.model.EQProfile
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.OscillationConfig
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SoundLibrary
import com.astrosleep.app.core.model.SubscriptionTier
import com.astrosleep.app.core.model.UserProfile
import com.astrosleep.app.core.model.Waveform
import com.astrosleep.app.core.model.roundedTo
import com.astrosleep.app.data.StorageRepository
import com.astrosleep.app.service.AuthService
import com.astrosleep.app.service.NetworkError
import com.astrosleep.app.service.NetworkService
import com.astrosleep.app.service.RevenueCatService
import com.astrosleep.app.service.audio.AudioService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import javax.inject.Inject

data class AppUiState(
    val isLoading: Boolean = true,
    val profile: UserProfile? = null,
    val hasCompletedOnboarding: Boolean = false,
    val selectedTab: Int = 0,
    val currentTier: SubscriptionTier = SubscriptionTier.FREE,
    val nightlyScore: NightlyScoreResult? = null,
    val activeCombo: Combo? = null,
    val cachedAffirmation: String? = null,
    val showPaywall: Boolean = false,
    val paywallTrigger: String = "",
    val errorMessage: String? = null,
    val isPlaying: Boolean = false,
    val soundCount: Int = 0,
)

@HiltViewModel
class AppViewModel @Inject constructor(
    private val storage: StorageRepository,
    private val astroEngine: AstrologicalEngine,
    private val tagEngine: TagEngine,
    private val soundLibrary: SoundLibrary,
    private val audioService: AudioService,
    private val networkService: NetworkService,
    private val authService: AuthService,
    private val revenueCat: RevenueCatService,
) : ViewModel() {

    private val _ui = MutableStateFlow(AppUiState())
    val ui: StateFlow<AppUiState> = _ui.asStateFlow()

    private var lastNightlyScoreDate: Long? = null

    init {
        revenueCat.configureIfNeeded()
        _ui.update { it.copy(soundCount = soundLibrary.sounds.size) }
        viewModelScope.launch {
            revenueCat.currentTier.collect { tier ->
                _ui.update { it.copy(currentTier = tier) }
            }
        }
        viewModelScope.launch {
            audioService.isPlaying.collect { playing ->
                _ui.update { it.copy(isPlaying = playing) }
            }
        }
        refreshProfile()
    }

    fun allSounds(): List<Sound> = soundLibrary.sounds

    fun refreshProfile() {
        viewModelScope.launch {
            _ui.update { it.copy(isLoading = true) }
            val profile = storage.loadProfile()
            _ui.update {
                it.copy(
                    isLoading = false,
                    profile = profile,
                    hasCompletedOnboarding = profile?.hasCompletedOnboarding == true,
                )
            }
            if (profile?.hasCompletedOnboarding == true) {
                computeNightlyScore()
            }
        }
    }

    fun completeOnboarding(
        name: String,
        birthDateEpochMs: Long,
        birthTimeEpochMs: Long?,
        birthLat: Double,
        birthLng: Double,
        birthCity: String,
    ) {
        viewModelScope.launch {
            _ui.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                val chart = astroEngine.computeNatalChart(
                    birthDateEpochMs = birthDateEpochMs,
                    birthTimeEpochMs = birthTimeEpochMs,
                    lat = birthLat,
                    lng = birthLng,
                )
                val baseScore = astroEngine.deriveBaseScore(chart)
                val profile = UserProfile(
                    id = authService.currentUserId ?: UUID.randomUUID().toString(),
                    name = name,
                    birthDateEpochMs = birthDateEpochMs,
                    birthTimeEpochMs = birthTimeEpochMs,
                    birthLat = birthLat,
                    birthLng = birthLng,
                    birthCity = birthCity,
                    baseScore = baseScore,
                    natalChart = chart,
                    hasCompletedOnboarding = true,
                )
                storage.saveProfile(profile)
                lastNightlyScoreDate = null
                _ui.update {
                    it.copy(
                        isLoading = false,
                        profile = profile,
                        hasCompletedOnboarding = true,
                    )
                }
                computeNightlyScore()
            } catch (e: Exception) {
                _ui.update {
                    it.copy(isLoading = false, errorMessage = e.message ?: "Onboarding failed")
                }
            }
        }
    }

    fun computeNightlyScore() {
        val profile = _ui.value.profile ?: return
        val chart = profile.natalChart ?: return
        val now = System.currentTimeMillis()
        val last = lastNightlyScoreDate
        if (last != null && isSameDay(last, now) && _ui.value.nightlyScore != null) {
            return
        }
        val score = astroEngine.calculateNightlyScore(
            baseScore = profile.baseScore,
            dateEpochMs = now,
            natalChart = chart,
            currentLat = profile.currentLat,
            currentLng = profile.currentLng,
            useCurrentLocation = profile.useCurrentLocationForTransits,
        )
        lastNightlyScoreDate = now
        _ui.update { it.copy(nightlyScore = score) }
    }

    fun autoGenerateCombo(intention: String = ""): Combo {
        computeNightlyScore()
        val tier = _ui.value.currentTier
        val score = _ui.value.nightlyScore
            ?: return createDefaultCombo(tier)

        val ranked = tagEngine.rankSounds(soundLibrary.sounds, score)
        val topRanked = ranked.take(tier.maxLayers)
        val totalScore = topRanked.sumOf { it.score }

        val layers = topRanked.mapIndexed { index, rankedSound ->
            val volume = if (totalScore > 0) (rankedSound.score / totalScore) * 0.75 else 0.15
            AmbientLayer(
                soundId = rankedSound.sound.id,
                volume = volume.roundedTo(2),
                playbackSpeed = 1.0,
                eq = EQProfile.profileForRegister(rankedSound.sound.tags.register),
                oscillation = buildOscillation(index, score.dominantElement),
            )
        }

        val combo = Combo(
            id = UUID.randomUUID().toString(),
            name = "${score.moonPhase.displayName} Session",
            source = ComboSource.AUTO,
            chartSnapshot = score.toSnapshot(),
            layers = layers,
            affirmationLayer = AffirmationLayer(
                voiceId = _ui.value.profile?.selectedVoiceId ?: "female",
            ),
        )
        _ui.update { it.copy(activeCombo = combo) }
        return combo
    }

    fun startSession(combo: Combo? = null, sleepTimerMinutes: Int? = null) {
        val c = combo ?: _ui.value.activeCombo ?: autoGenerateCombo()
        _ui.update { it.copy(activeCombo = c) }
        audioService.loadCombo(c)
        val timer = sleepTimerMinutes
            ?: c.sleepTimerMinutes
            ?: _ui.value.profile?.sleepTimerDefault
        audioService.play(timer)
        c.affirmationLayer.text.takeIf { it.isNotBlank() }?.let {
            audioService.speakAffirmation(it, c.affirmationLayer.volume.toFloat())
        }
    }

    fun pauseSession() = audioService.pause()
    fun resumeSession() = audioService.resume()
    fun stopSession() = audioService.stopAll()

    fun getOrCreateAffirmation(intention: String) {
        viewModelScope.launch {
            val dateId = utcDateString(System.currentTimeMillis())
            storage.loadAffirmationCache(dateId)?.let { cache ->
                _ui.update { it.copy(cachedAffirmation = cache.script) }
                return@launch
            }
            val userId = authService.currentUserId ?: return@launch
            try {
                val script = networkService.generateAffirmation(intention, userId)
                storage.cacheAffirmation(
                    AffirmationCache(
                        id = dateId,
                        script = script,
                        generatedAtEpochMs = System.currentTimeMillis(),
                        intention = intention,
                    ),
                )
                _ui.update { it.copy(cachedAffirmation = script) }
            } catch (_: NetworkError.RateLimited) {
                // silent — rate limited
            } catch (e: Exception) {
                _ui.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun selectTab(index: Int) {
        _ui.update { it.copy(selectedTab = index) }
    }

    fun enforceTier(required: SubscriptionTier, feature: String): Boolean {
        if (_ui.value.currentTier < required) {
            _ui.update { it.copy(showPaywall = true, paywallTrigger = feature) }
            return false
        }
        return true
    }

    fun dismissPaywall() {
        _ui.update { it.copy(showPaywall = false) }
    }

    fun restorePurchases() {
        revenueCat.restorePurchases { }
    }

    private fun createDefaultCombo(tier: SubscriptionTier): Combo {
        val selected = soundLibrary.sounds.take(tier.maxLayers)
        val layers = selected.map { sound ->
            AmbientLayer(
                soundId = sound.id,
                volume = 0.5,
                eq = EQProfile.DEFAULT,
            )
        }
        val combo = Combo(
            name = "Tonight's Session",
            source = ComboSource.AUTO,
            layers = layers,
        )
        _ui.update { it.copy(activeCombo = combo) }
        return combo
    }

    private fun buildOscillation(index: Int, dominant: Element): OscillationConfig? =
        when (dominant) {
            Element.WATER -> OscillationConfig(
                enabled = index == 0,
                waveform = Waveform.SINE,
                periodSeconds = 45.0,
                minVolume = 0.45,
                maxVolume = 0.85,
                phaseOffset = index * 0.33,
            )
            Element.AIR -> OscillationConfig(
                enabled = index <= 1,
                waveform = Waveform.PERLIN,
                periodSeconds = 18.0,
                minVolume = 0.40,
                maxVolume = 0.80,
                phaseOffset = index * 0.33,
            )
            Element.FIRE -> OscillationConfig(
                enabled = index == 0,
                waveform = Waveform.PERLIN,
                periodSeconds = 12.0,
                minVolume = 0.35,
                maxVolume = 0.75,
                phaseOffset = index * 0.33,
            )
            Element.EARTH -> null
        }

    private fun isSameDay(a: Long, b: Long): Boolean {
        val ca = Calendar.getInstance().apply { timeInMillis = a }
        val cb = Calendar.getInstance().apply { timeInMillis = b }
        return ca.get(Calendar.YEAR) == cb.get(Calendar.YEAR) &&
            ca.get(Calendar.DAY_OF_YEAR) == cb.get(Calendar.DAY_OF_YEAR)
    }

    private fun utcDateString(epochMs: Long): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        fmt.timeZone = TimeZone.getTimeZone("UTC")
        return fmt.format(Date(epochMs))
    }
}
