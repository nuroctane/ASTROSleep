package com.astrosleep.app.service.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.speech.tts.TextToSpeech
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.astrosleep.app.core.model.AmbientLayer
import com.astrosleep.app.core.model.AudioState
import com.astrosleep.app.core.model.Combo
import com.astrosleep.app.core.model.SoundLibrary
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.PI
import kotlin.math.sin

/**
 * Multi-track ambient playback via Media3 ExoPlayer (one player per layer).
 * LFO volume oscillation + sleep-timer fade + TTS affirmations.
 * Background: pair with [PlaybackService] MediaSession (Phase D polish).
 */
@Singleton
class AudioService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val soundLibrary: SoundLibrary,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val _state = MutableStateFlow(AudioState.IDLE)
    val state: StateFlow<AudioState> = _state.asStateFlow()

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _masterVolume = MutableStateFlow(1.0)
    val masterVolume: StateFlow<Double> = _masterVolume.asStateFlow()

    private data class LayerPlayer(
        val layerId: String,
        val player: ExoPlayer,
        val baseVolume: Float,
        val oscillation: com.astrosleep.app.core.model.OscillationConfig?,
    )

    private val layers = mutableMapOf<String, LayerPlayer>()
    private var lfoJob: Job? = null
    private var sleepTimerJob: Job? = null
    private var fadeJob: Job? = null
    private var tts: TextToSpeech? = null
    private var focusRequest: AudioFocusRequest? = null

    fun loadCombo(combo: Combo) {
        stopAll()
        _state.value = AudioState.LOADING
        for (layer in combo.layers) {
            val url = resolveSoundUri(layer.soundId) ?: continue
            val player = ExoPlayer.Builder(context).build().apply {
                setMediaItem(MediaItem.fromUri(url))
                repeatMode = Player.REPEAT_MODE_ONE
                volume = (layer.volume * _masterVolume.value).toFloat()
                prepare()
            }
            layers[layer.id] = LayerPlayer(
                layerId = layer.id,
                player = player,
                baseVolume = layer.volume.toFloat(),
                oscillation = layer.oscillation,
            )
        }
        _state.value = AudioState.IDLE
    }

    fun play(sleepTimerMinutes: Int? = null) {
        if (!requestAudioFocus()) return
        layers.values.forEach { it.player.play() }
        _isPlaying.value = true
        _state.value = AudioState.PLAYING
        startLfo()
        if (sleepTimerMinutes != null && sleepTimerMinutes > 0) {
            startSleepTimer(sleepTimerMinutes)
        }
    }

    fun pause() {
        layers.values.forEach { it.player.pause() }
        _isPlaying.value = false
        _state.value = AudioState.PAUSED
        lfoJob?.cancel()
    }

    fun resume() {
        play()
    }

    fun stopAll() {
        sleepTimerJob?.cancel()
        fadeJob?.cancel()
        lfoJob?.cancel()
        layers.values.forEach {
            it.player.stop()
            it.player.release()
        }
        layers.clear()
        _isPlaying.value = false
        _state.value = AudioState.STOPPED
        abandonAudioFocus()
    }

    fun setMasterVolume(volume: Double) {
        _masterVolume.value = volume.coerceIn(0.0, 1.0)
        layers.values.forEach { layer ->
            layer.player.volume = (layer.baseVolume * _masterVolume.value).toFloat()
        }
    }

    fun speakAffirmation(text: String, volume: Float = 0.1f) {
        if (text.isBlank()) return
        if (tts == null) {
            tts = TextToSpeech(context) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    tts?.language = Locale.US
                    speakNow(text, volume)
                }
            }
        } else {
            speakNow(text, volume)
        }
    }

    private fun speakNow(text: String, volume: Float) {
        tts?.setSpeechRate(0.9f)
        // Bundle volume not uniformly available; best-effort
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, UUID.randomUUID().toString())
    }

    fun fadeOut(durationMs: Long = 15_000L) {
        fadeJob?.cancel()
        _state.value = AudioState.FADING
        fadeJob = scope.launch {
            val start = _masterVolume.value
            val steps = 30
            val stepMs = durationMs / steps
            for (i in 1..steps) {
                if (!isActive) return@launch
                setMasterVolume(start * (1.0 - i.toDouble() / steps))
                delay(stepMs)
            }
            stopAll()
        }
    }

    private fun startSleepTimer(minutes: Int) {
        sleepTimerJob?.cancel()
        sleepTimerJob = scope.launch {
            delay(minutes * 60_000L)
            fadeOut()
        }
    }

    private fun startLfo() {
        lfoJob?.cancel()
        val startNs = System.nanoTime()
        lfoJob = scope.launch {
            while (isActive && _isPlaying.value) {
                val t = (System.nanoTime() - startNs) / 1_000_000_000.0
                layers.values.forEach { layer ->
                    val osc = layer.oscillation
                    val vol = if (osc != null && osc.enabled) {
                        val phase = 2.0 * PI * (t / osc.periodSeconds + osc.phaseOffset)
                        val wave = (sin(phase) + 1.0) / 2.0
                        val lfo = osc.minVolume + (osc.maxVolume - osc.minVolume) * wave
                        (layer.baseVolume * lfo * _masterVolume.value).toFloat()
                    } else {
                        (layer.baseVolume * _masterVolume.value).toFloat()
                    }
                    layer.player.volume = vol
                }
                delay(50)
            }
        }
    }

    private fun resolveSoundUri(soundId: String): String? {
        val sound = soundLibrary.sound(soundId) ?: return null
        // 1) Bundled assets
        sound.bundleFilename?.let { name ->
            try {
                context.assets.openFd("sounds/$name").close()
                return "asset:///sounds/$name"
            } catch (_: Exception) {
                // not bundled
            }
        }
        // 2) Cache
        val cache = File(context.filesDir, "sounds/$soundId.m4a")
        if (cache.exists()) return cache.toURI().toString()
        // 3) CDN
        return sound.cdnUrl.ifBlank { null }
    }

    private fun requestAudioFocus(): Boolean {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener { focus ->
                    when (focus) {
                        AudioManager.AUDIOFOCUS_LOSS,
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                        -> pause()
                        AudioManager.AUDIOFOCUS_GAIN -> if (_state.value == AudioState.PAUSED) resume()
                    }
                }
                .build()
            focusRequest = req
            audioManager.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                { },
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        }
    }
}
