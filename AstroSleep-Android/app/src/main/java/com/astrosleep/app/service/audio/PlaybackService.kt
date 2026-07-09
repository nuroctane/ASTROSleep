package com.astrosleep.app.service.audio

import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * Foreground media playback service.
 * Will host Media3 MediaSession + multi-track ambient mixing (Phase B).
 */
class PlaybackService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO(port): startForeground + MediaSession
        return START_STICKY
    }
}
