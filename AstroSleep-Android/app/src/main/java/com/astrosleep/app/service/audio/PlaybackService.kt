package com.astrosleep.app.service.audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat as MediaNotificationCompat
import com.astrosleep.app.MainActivity
import com.astrosleep.app.R

/**
 * Foreground service so ambient playback survives screen-off.
 * MediaStyle notification exposes Pause / Stop for lockscreen & shade (roadmap: MediaSession deep controls).
 * Started/stopped by [AudioService].
 */
class PlaybackService : Service() {

    private var mediaSession: MediaSessionCompat? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannel()
        mediaSession = MediaSessionCompat(this, "AstroSleepPlayback").apply {
            setPlaybackState(
                PlaybackStateCompat.Builder()
                    .setActions(
                        PlaybackStateCompat.ACTION_PLAY or
                            PlaybackStateCompat.ACTION_PAUSE or
                            PlaybackStateCompat.ACTION_STOP or
                            PlaybackStateCompat.ACTION_PLAY_PAUSE,
                    )
                    .setState(PlaybackStateCompat.STATE_PLAYING, 0L, 1f)
                    .build(),
            )
            isActive = true
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                sendBroadcast(Intent(ACTION_STOP).setPackage(packageName))
                teardown()
                return START_NOT_STICKY
            }
            ACTION_PAUSE -> {
                sendBroadcast(Intent(ACTION_PAUSE).setPackage(packageName))
                mediaSession?.setPlaybackState(
                    PlaybackStateCompat.Builder()
                        .setActions(
                            PlaybackStateCompat.ACTION_PLAY or
                                PlaybackStateCompat.ACTION_STOP or
                                PlaybackStateCompat.ACTION_PLAY_PAUSE,
                        )
                        .setState(PlaybackStateCompat.STATE_PAUSED, 0L, 0f)
                        .build(),
                )
                startForeground(NOTIFICATION_ID, buildNotification(playing = false))
                return START_STICKY
            }
            else -> {
                mediaSession?.setPlaybackState(
                    PlaybackStateCompat.Builder()
                        .setActions(
                            PlaybackStateCompat.ACTION_PAUSE or
                                PlaybackStateCompat.ACTION_STOP or
                                PlaybackStateCompat.ACTION_PLAY_PAUSE,
                        )
                        .setState(PlaybackStateCompat.STATE_PLAYING, 0L, 1f)
                        .build(),
                )
                startForeground(NOTIFICATION_ID, buildNotification(playing = true))
            }
        }
        return START_STICKY
    }

    private fun buildNotification(playing: Boolean): Notification {
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val pauseIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, PlaybackService::class.java).setAction(ACTION_PAUSE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopIntent = PendingIntent.getService(
            this,
            2,
            Intent(this, PlaybackService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(if (playing) "Playing tonight's soundscape" else "Paused")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(open)
            .setOngoing(playing)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setStyle(
                MediaNotificationCompat.MediaStyle()
                    .setMediaSession(mediaSession?.sessionToken)
                    .setShowActionsInCompactView(0, 1),
            )
            .addAction(
                if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if (playing) "Pause" else "Play",
                pauseIntent,
            )
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopIntent)

        return builder.build()
    }

    private fun teardown() {
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        mediaSession?.release()
        mediaSession = null
        super.onDestroy()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Playback",
                NotificationManager.IMPORTANCE_LOW,
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    companion object {
        const val ACTION_START = "com.astrosleep.app.playback.START"
        const val ACTION_STOP = "com.astrosleep.app.playback.STOP"
        const val ACTION_PAUSE = "com.astrosleep.app.playback.PAUSE"
        private const val CHANNEL_ID = "astrosleep_playback"
        private const val NOTIFICATION_ID = 42
    }
}
