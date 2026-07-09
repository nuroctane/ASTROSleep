package com.astrosleep.app.service.audio

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.speech.tts.TextToSpeech
import androidx.core.content.ContextCompat
import androidx.media3.common.AudioAttributes as Media3AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.PlaybackParameters
import androidx.media3.exoplayer.ExoPlayer
import com.astrosleep.app.core.model.AudioState
import com.astrosleep.app.core.model.Combo
import com.astrosleep.app.core.model.EQProfile
import com.astrosleep.app.core.model.OscillationConfig
import com.astrosleep.app.core.model.SoundLibrary
import com.astrosleep.app.core.model.Waveform
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
import kotlin.math.abs
import kotlin.math.sin

/**
 * Multi-track ambient playback via Media3 ExoPlayer.
 * Fixes: master-volume restore after fade, FGS lifecycle, speed/LFO waveforms,
 * empty-load error state.
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

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private data class LayerPlayer(
        val layerId: String,
        val player: ExoPlayer,
        val baseVolume: Float,
        val oscillation: OscillationConfig?,
    )

    private val layers = mutableMapOf<String, LayerPlayer>()
    private var lfoJob: Job? = null
    private var sleepTimerJob: Job? = null
    private var fadeJob: Job? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var pendingSpeech: Pair<String, Float>? = null
    private var focusRequest: AudioFocusRequest? = null
    /** True only when the user (or permanent focus loss) requested pause — not transient duck/interrupt. */
    private var userPaused = false
    private var pausedByFocus = false
    /** Volume before fade; restored after stop so next session is audible. */
    private var volumeBeforeFade: Double = 1.0

    private val transportReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            when (intent?.action) {
                PlaybackService.ACTION_PAUSE -> {
                    // Notification toggle: pause when playing, resume when paused
                    if (_isPlaying.value) pause(fromUser = true) else resume()
                }
                PlaybackService.ACTION_STOP -> stopAll(resetMasterVolume = true)
            }
        }
    }

    init {
        val filter = IntentFilter().apply {
            addAction(PlaybackService.ACTION_PAUSE)
            addAction(PlaybackService.ACTION_STOP)
        }
        ContextCompat.registerReceiver(
            context,
            transportReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    fun loadCombo(combo: Combo) {
        stopAll(resetMasterVolume = false)
        _errorMessage.value = null
        _state.value = AudioState.LOADING
        // Restore audible master if a prior fade left it at 0
        if (_masterVolume.value < 0.05) {
            _masterVolume.value = volumeBeforeFade.coerceIn(0.05, 1.0)
        }

        var loaded = 0
        for (layer in combo.layers) {
            val url = resolveSoundUri(layer.soundId) ?: continue
            val player = ExoPlayer.Builder(context).build().apply {
                setAudioAttributes(
                    Media3AudioAttributes.Builder()
                        .setUsage(C.USAGE_MEDIA)
                        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                        .build(),
                    /* handleAudioFocus= */ false,
                )
                setMediaItem(MediaItem.fromUri(url))
                repeatMode = Player.REPEAT_MODE_ONE
                playbackParameters = PlaybackParameters(layer.playbackSpeed.toFloat().coerceIn(0.5f, 2.0f))
                volume = (layer.volume * _masterVolume.value).toFloat()
                prepare()
            }
            layers[layer.id] = LayerPlayer(
                layerId = layer.id,
                player = player,
                baseVolume = layer.volume.toFloat(),
                oscillation = layer.oscillation,
            )
            loaded++
        }

        if (loaded == 0) {
            _state.value = AudioState.IDLE
            _errorMessage.value = "No playable sounds (offline or missing assets)."
        } else {
            _state.value = AudioState.IDLE
        }
    }

    fun play(sleepTimerMinutes: Int? = null) {
        if (layers.isEmpty()) {
            _errorMessage.value = _errorMessage.value ?: "Nothing to play."
            return
        }
        if (!requestAudioFocus()) {
            _errorMessage.value = "Audio focus denied."
            return
        }
        userPaused = false
        pausedByFocus = false
        layers.values.forEach { it.player.play() }
        _isPlaying.value = true
        _state.value = AudioState.PLAYING
        startLfo()
        notifyPlaybackService(playing = true)
        if (sleepTimerMinutes != null && sleepTimerMinutes > 0) {
            startSleepTimer(sleepTimerMinutes)
        } else if (sleepTimerMinutes != null && sleepTimerMinutes <= 0) {
            sleepTimerJob?.cancel()
            sleepTimerJob = null
        }
    }

    /**
     * @param fromUser true for UI / notification / permanent focus loss.
     *        Transient focus loss must pass false so GAIN can auto-resume.
     */
    fun pause(fromUser: Boolean = true) {
        if (fromUser) {
            userPaused = true
            pausedByFocus = false
        } else {
            pausedByFocus = true
        }
        layers.values.forEach { it.player.pause() }
        _isPlaying.value = false
        _state.value = AudioState.PAUSED
        lfoJob?.cancel()
        notifyPlaybackService(playing = false)
    }

    fun resume() {
        if (layers.isEmpty()) return
        if (_state.value == AudioState.STOPPED || _state.value == AudioState.IDLE) {
            play()
            return
        }
        userPaused = false
        pausedByFocus = false
        if (!requestAudioFocus()) return
        layers.values.forEach { it.player.play() }
        _isPlaying.value = true
        _state.value = AudioState.PLAYING
        startLfo()
        notifyPlaybackService(playing = true)
    }

    /**
     * @param resetMasterVolume when true (default after stop/fade), restore audible level
     */
    fun stopAll(resetMasterVolume: Boolean = true) {
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
        stopPlaybackService()
        if (resetMasterVolume) {
            _masterVolume.value = volumeBeforeFade.coerceIn(0.05, 1.0)
        }
    }

    fun setMasterVolume(volume: Double) {
        val v = volume.coerceIn(0.0, 1.0)
        _masterVolume.value = v
        if (_state.value != AudioState.FADING) {
            volumeBeforeFade = v
        }
        layers.values.forEach { layer ->
            if (layer.oscillation?.enabled != true) {
                layer.player.volume = (layer.baseVolume * v).toFloat()
            }
        }
    }

    fun speakAffirmation(text: String, volume: Float = 0.1f) {
        if (text.isBlank()) return
        if (tts == null) {
            tts = TextToSpeech(context) { status ->
                ttsReady = status == TextToSpeech.SUCCESS
                if (ttsReady) {
                    tts?.language = Locale.US
                    pendingSpeech?.let { (t, vol) ->
                        pendingSpeech = null
                        speakNow(t, vol)
                    }
                }
            }
            pendingSpeech = text to volume
        } else if (!ttsReady) {
            pendingSpeech = text to volume
        } else {
            speakNow(text, volume)
        }
    }

    private fun speakNow(text: String, volume: Float) {
        tts?.setSpeechRate(0.9f)
        val params = android.os.Bundle().apply {
            // Soft under ambient (0.05–0.35 typical for affirmation layer)
            putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume.coerceIn(0.05f, 1f))
        }
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, UUID.randomUUID().toString())
    }

    fun fadeOut(durationMs: Long = 15_000L) {
        fadeJob?.cancel()
        volumeBeforeFade = _masterVolume.value.coerceAtLeast(0.05)
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
            stopAll(resetMasterVolume = true)
        }
    }

    fun release() {
        try {
            context.unregisterReceiver(transportReceiver)
        } catch (_: Exception) {
            // already unregistered
        }
        stopAll(resetMasterVolume = true)
        tts?.shutdown()
        tts = null
        ttsReady = false
    }

    private fun startSleepTimer(minutes: Int) {
        if (minutes <= 0) {
            sleepTimerJob?.cancel()
            sleepTimerJob = null
            return
        }
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
                        val cycle = ((t / osc.periodSeconds) + osc.phaseOffset) % 1.0
                        val wave = waveformValue(osc.waveform, cycle)
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

    /** Map waveform to 0..1 envelope. */
    private fun waveformValue(waveform: Waveform, cyclePosition: Double): Double {
        val c = ((cyclePosition % 1.0) + 1.0) % 1.0
        return when (waveform) {
            Waveform.SINE -> (sin(2.0 * PI * c) + 1.0) / 2.0
            Waveform.TRIANGLE -> {
                val t = c
                (4.0 * abs(t - 0.5)).let { v -> (v).coerceIn(0.0, 1.0) }.let {
                    // convert -1..1 triangle to 0..1: (tri+1)/2 where tri = 4*|t-0.5|-1
                    val tri = 4.0 * abs(t - 0.5) - 1.0
                    (tri + 1.0) / 2.0
                }
            }
            Waveform.STEP -> if (c < 0.5) 0.0 else 1.0
            Waveform.PERLIN -> {
                val s = sin(c * 2 * PI) * 0.5 + sin(c * 4 * PI) * 0.25 + sin(c * 8 * PI) * 0.125
                (s + 0.875) / 1.75 // rough normalize to 0..1
            }
        }
    }

    private fun resolveSoundUri(soundId: String): String? {
        val sound = soundLibrary.sound(soundId) ?: return null
        sound.bundleFilename?.let { name ->
            try {
                context.assets.openFd("sounds/$name").close()
                return "asset:///sounds/$name"
            } catch (_: Exception) {
                // not bundled
            }
        }
        val cache = File(context.filesDir, "sounds/$soundId.m4a")
        if (cache.exists()) return cache.toURI().toString()
        return sound.cdnUrl.ifBlank { null }
    }

    /** Start or refresh FGS + MediaSession state so lockscreen matches in-app controls. */
    private fun notifyPlaybackService(playing: Boolean) {
        val action = if (playing) PlaybackService.ACTION_START else PlaybackService.ACTION_SYNC_PAUSED
        val intent = Intent(context, PlaybackService::class.java).setAction(action)
        if (playing) {
            ContextCompat.startForegroundService(context, intent)
        } else {
            // Service may already be running — update notification without re-START race
            try {
                context.startService(intent)
            } catch (_: Exception) {
                ContextCompat.startForegroundService(
                    context,
                    Intent(context, PlaybackService::class.java).setAction(PlaybackService.ACTION_START),
                )
                context.startService(Intent(context, PlaybackService::class.java).setAction(action))
            }
        }
    }

    private fun stopPlaybackService() {
        val intent = Intent(context, PlaybackService::class.java).setAction(PlaybackService.ACTION_STOP)
        try {
            context.startService(intent)
        } catch (_: Exception) {
            // already stopped
        }
    }

    private fun requestAudioFocus(): Boolean {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener { focus ->
                    when (focus) {
                        AudioManager.AUDIOFOCUS_LOSS -> {
                            pause(fromUser = true)
                            abandonAudioFocus()
                        }
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> pause(fromUser = false)
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                            layers.values.forEach { it.player.volume = it.baseVolume * 0.3f }
                        }
                        AudioManager.AUDIOFOCUS_GAIN -> {
                            if (!userPaused && (pausedByFocus || _state.value == AudioState.PAUSED)) {
                                resume()
                            } else if (_isPlaying.value) {
                                layers.values.forEach {
                                    it.player.volume = (it.baseVolume * _masterVolume.value).toFloat()
                                }
                            }
                        }
                    }
                }
                .build()
            focusRequest = req
            audioManager.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                { focus ->
                    when (focus) {
                        AudioManager.AUDIOFOCUS_LOSS -> pause(fromUser = true)
                        AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> pause(fromUser = false)
                        AudioManager.AUDIOFOCUS_GAIN -> {
                            if (!userPaused && pausedByFocus) resume()
                        }
                    }
                },
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        }
    }
}
