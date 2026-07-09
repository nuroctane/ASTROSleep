package com.astrosleep.app.state

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.astrosleep.app.core.engine.AstrologicalEngine
import com.astrosleep.app.core.engine.ComboComposer
import com.astrosleep.app.core.engine.PersonalSoundProfile
import com.astrosleep.app.core.engine.TagEngine
import com.astrosleep.app.core.model.AffirmationCache
import com.astrosleep.app.core.model.AmbientLayer
import com.astrosleep.app.core.model.Combo
import com.astrosleep.app.core.model.ComboSource
import com.astrosleep.app.core.model.EQProfile
import com.astrosleep.app.core.model.NightlyScoreResult
import com.astrosleep.app.core.model.RankedSound
import com.astrosleep.app.core.model.Sound
import com.astrosleep.app.core.model.SoundLibrary
import com.astrosleep.app.core.model.SubscriptionTier
import com.astrosleep.app.core.model.UserProfile
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
    /** Top ranked sounds for the current user+night (for Sounds tab / debug). */
    val rankedPreview: List<RankedSound> = emptyList(),
    val personalFingerprint: Long? = null,
)

@HiltViewModel
class AppViewModel @Inject constructor(
    private val storage: StorageRepository,
    private val astroEngine: AstrologicalEngine,
    private val tagEngine: TagEngine,
    private val comboComposer: ComboComposer,
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
        val profile = _ui.value.profile
        val score = _ui.value.nightlyScore
            ?: return createDefaultCombo(tier)

        val userId = profile?.id
            ?: authService.currentUserId
            ?: UUID.randomUUID().toString()
        val baseScore = profile?.baseScore ?: score.elementScore
        val chart = profile?.natalChart

        val result = comboComposer.compose(
            userId = userId,
            sounds = soundLibrary.sounds,
            nightly = score,
            natalBaseScore = baseScore,
            chart = chart,
            tier = tier,
            voiceId = profile?.selectedVoiceId ?: "female",
        )

        _ui.update {
            it.copy(
                activeCombo = result.combo,
                rankedPreview = result.ranked.take(12),
                personalFingerprint = result.profile.fingerprint,
            )
        }
        return result.combo
    }

    /** Recompute ranked preview without building a full combo (e.g. Sounds tab). */
    fun refreshRankedPreview() {
        val profile = _ui.value.profile ?: return
        val score = _ui.value.nightlyScore ?: return
        val personal = PersonalSoundProfile.from(profile.id, profile.natalChart, profile.baseScore)
        val ranked = tagEngine.rankSoundsPersonalized(
            sounds = soundLibrary.sounds,
            nightly = score,
            profile = personal,
            natalBaseScore = profile.baseScore,
            chart = profile.natalChart,
        )
        _ui.update {
            it.copy(
                rankedPreview = ranked.take(12),
                personalFingerprint = personal.fingerprint,
            )
        }
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
