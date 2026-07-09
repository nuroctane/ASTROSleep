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
import com.astrosleep.app.service.GeocodingException
import com.astrosleep.app.service.GeocodingService
import com.astrosleep.app.service.NetworkError
import com.astrosleep.app.service.NetworkService
import com.astrosleep.app.service.NotificationService
import com.astrosleep.app.service.RevenueCatService
import com.astrosleep.app.service.SoundCacheService
import com.astrosleep.app.service.audio.AudioService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
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
    val localUserId: String? = null,
    val authEmail: String? = null,
    val authStatusMessage: String? = null,
    val savedCombos: List<Combo> = emptyList(),
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
    private val geocodingService: GeocodingService,
    private val notifications: NotificationService,
    private val soundCache: SoundCacheService,
) : ViewModel() {

    private val _ui = MutableStateFlow(AppUiState())
    val ui: StateFlow<AppUiState> = _ui.asStateFlow()

    private var lastNightlyScoreDate: Long? = null

    init {
        revenueCat.configureIfNeeded()
        _ui.update {
            it.copy(
                soundCount = soundLibrary.sounds.size,
                localUserId = authService.currentUserId,
                authEmail = authService.email.value,
            )
        }
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
        viewModelScope.launch {
            authService.userId.collect { id ->
                _ui.update { it.copy(localUserId = id) }
            }
        }
        viewModelScope.launch {
            authService.email.collect { email ->
                _ui.update { it.copy(authEmail = email) }
            }
        }
        viewModelScope.launch {
            authService.statusMessage.collect { msg ->
                _ui.update { it.copy(authStatusMessage = msg) }
            }
        }
        refreshProfile()
    }

    fun linkEmail(email: String) {
        authService.linkEmail(email)
    }

    fun signOutLocal() {
        authService.signOutLocal()
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

    /**
     * Complete onboarding. Prefer [birthCity] geocoding when lat/lng are zero/blank.
     */
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
                var lat = birthLat
                var lng = birthLng
                var city = birthCity.trim().ifBlank { "Unknown" }
                val needsGeocode = city != "Unknown" &&
                    (kotlin.math.abs(lat) < 1e-6 && kotlin.math.abs(lng) < 1e-6 || birthLat == 0.0 && birthLng == 0.0)
                if (needsGeocode || (city.isNotBlank() && city != "Unknown" && kotlin.math.abs(lat) < 1e-6)) {
                    try {
                        val geo = geocodingService.geocode(city)
                        lat = geo.lat
                        lng = geo.lng
                        city = geo.city
                    } catch (e: GeocodingException) {
                        if (kotlin.math.abs(lat) < 1e-6 && kotlin.math.abs(lng) < 1e-6) {
                            throw e
                        }
                        // Keep manual coords if geocode fails but user entered numbers
                    }
                }
                val chart = astroEngine.computeNatalChart(
                    birthDateEpochMs = birthDateEpochMs,
                    birthTimeEpochMs = birthTimeEpochMs,
                    lat = lat,
                    lng = lng,
                )
                val baseScore = astroEngine.deriveBaseScore(chart)
                val profile = UserProfile(
                    id = authService.currentUserId ?: UUID.randomUUID().toString(),
                    name = name,
                    birthDateEpochMs = birthDateEpochMs,
                    birthTimeEpochMs = birthTimeEpochMs,
                    birthLat = lat,
                    birthLng = lng,
                    birthCity = city,
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

    fun geocodeCityPreview(
        city: String,
        onResult: (lat: Double, lng: Double, name: String) -> Unit,
        onDone: () -> Unit = {},
    ) {
        viewModelScope.launch {
            try {
                val geo = geocodingService.geocode(city)
                onResult(geo.lat, geo.lng, geo.city)
                _ui.update { it.copy(errorMessage = null) }
            } catch (e: Exception) {
                _ui.update { it.copy(errorMessage = e.message ?: "Geocode failed") }
            } finally {
                onDone()
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
        val wantGps = profile.useCurrentLocationForTransits
        val gpsOk = wantGps && (kotlin.math.abs(profile.currentLat) > 1e-6 || kotlin.math.abs(profile.currentLng) > 1e-6)
        val transitLat = if (gpsOk) profile.currentLat else profile.birthLat
        val transitLng = if (gpsOk) profile.currentLng else profile.birthLng
        val score = astroEngine.calculateNightlyScore(
            baseScore = profile.baseScore,
            dateEpochMs = now,
            natalChart = chart,
            currentLat = transitLat,
            currentLng = transitLng,
            useCurrentLocation = gpsOk || !wantGps, // birth place when GPS requested but unset
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
        // Prefetch audio for top layers (bundle → cache → CDN)
        viewModelScope.launch(Dispatchers.IO) {
            soundCache.prefetch(result.combo.layers.map { it.soundId })
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

    fun startSession(combo: Combo? = null, sleepTimerMinutes: Int? = null, intention: String = "") {
        viewModelScope.launch {
            // Ensure affirmation cache is warm before speak (iOS parity)
            ensureAffirmation(intention.ifBlank { "Sleep well" })
            val c = combo ?: _ui.value.activeCombo ?: autoGenerateCombo(intention)
            val script = c.affirmationLayer.text.takeIf { it.isNotBlank() }
                ?: _ui.value.cachedAffirmation
            val withVoice = if (!script.isNullOrBlank() && c.affirmationLayer.text.isBlank()) {
                c.copy(
                    affirmationLayer = c.affirmationLayer.copy(text = script),
                )
            } else {
                c
            }
            _ui.update { it.copy(activeCombo = withVoice, errorMessage = null) }
            audioService.loadCombo(withVoice)
            if (audioService.errorMessage.value != null) {
                _ui.update { it.copy(errorMessage = audioService.errorMessage.value) }
                return@launch
            }
            val timer = sleepTimerMinutes
                ?: withVoice.sleepTimerMinutes
                ?: _ui.value.profile?.sleepTimerDefault
            audioService.play(timer)
            timer?.takeIf { it > 0 }?.let { minutes ->
                notifications.scheduleSessionCompleteNotification(minutes)
            }
            val speak = withVoice.affirmationLayer.text.takeIf { it.isNotBlank() }
                ?: _ui.value.cachedAffirmation
            speak?.let {
                audioService.speakAffirmation(it, withVoice.affirmationLayer.volume.toFloat())
            }
        }
    }

    fun pauseSession() = audioService.pause(fromUser = true)
    fun resumeSession() = audioService.resume()
    fun stopSession() = audioService.stopAll()

    fun getOrCreateAffirmation(intention: String) {
        viewModelScope.launch { ensureAffirmation(intention) }
    }

    private suspend fun ensureAffirmation(intention: String) {
        val dateId = utcDateString(System.currentTimeMillis())
        storage.loadAffirmationCache(dateId)?.let { cache ->
            _ui.update { it.copy(cachedAffirmation = cache.script) }
            return
        }
        if (_ui.value.cachedAffirmation != null) return
        // Parity with iOS: auth id → profile id → guest
        val userId = authService.currentUserId
            ?: _ui.value.profile?.id
            ?: "guest"
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
            // silent — rate limited; session still plays ambient
        } catch (_: Exception) {
            // Offline: keep ambient
        }
    }

    fun selectTab(index: Int) {
        _ui.update { it.copy(selectedTab = index) }
        if (index == 3) refreshLibrary()
    }

    fun refreshLibrary() {
        viewModelScope.launch {
            val combos = storage.loadCombos()
            _ui.update { it.copy(savedCombos = combos) }
        }
    }

    fun saveActiveCombo() {
        val combo = _ui.value.activeCombo ?: return
        val tier = _ui.value.currentTier
        viewModelScope.launch {
            val existing = storage.loadCombos()
            if (existing.none { it.id == combo.id } && existing.size >= tier.maxPlaylists &&
                tier.maxPlaylists != Int.MAX_VALUE
            ) {
                if (!enforceTier(SubscriptionTier.SUBSCRIPTION, "Saved playlists")) return@launch
            }
            storage.saveCombo(combo)
            refreshLibrary()
        }
    }

    fun deleteCombo(id: String) {
        viewModelScope.launch {
            storage.deleteCombo(id)
            refreshLibrary()
        }
    }

    fun playSavedCombo(combo: Combo) {
        startSession(combo = combo)
    }

    fun setBedtimeReminder(enabled: Boolean, hour: Int = 22, minute: Int = 30) {
        viewModelScope.launch {
            if (enabled) {
                notifications.scheduleBedtimeReminder(hour, minute)
            } else {
                notifications.cancelBedtimeReminder()
            }
            storage.updateProfile { p ->
                p.copy(
                    notificationEnabled = enabled,
                    bedtimeReminderEpochMs = if (enabled) {
                        Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, hour)
                            set(Calendar.MINUTE, minute)
                        }.timeInMillis
                    } else {
                        null
                    },
                )
            }?.let { updated ->
                _ui.update { it.copy(profile = updated) }
            }
        }
    }

    fun updateTransitLocationToggle(useCurrent: Boolean) {
        viewModelScope.launch {
            storage.updateProfile { it.copy(useCurrentLocationForTransits = useCurrent) }?.let { p ->
                _ui.update { it.copy(profile = p) }
                lastNightlyScoreDate = null
                computeNightlyScore()
            }
        }
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
        revenueCat.restorePurchases { result ->
            result.onSuccess { tier ->
                _ui.update { it.copy(currentTier = tier, errorMessage = null) }
            }.onFailure { e ->
                _ui.update { it.copy(errorMessage = e.message ?: "Restore failed") }
            }
        }
    }

    fun purchaseSubscription() {
        revenueCat.purchaseSubscription { result ->
            result.onSuccess { tier ->
                _ui.update {
                    it.copy(currentTier = tier, showPaywall = false, errorMessage = null)
                }
            }.onFailure { e ->
                _ui.update { it.copy(errorMessage = e.message ?: "Purchase failed") }
            }
        }
    }

    fun openPlaySubscriptions() {
        revenueCat.openManageSubscriptions()
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
