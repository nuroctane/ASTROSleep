package com.astrosleep.app.service

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.astrosleep.app.MainActivity
import com.astrosleep.app.R
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.Calendar
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Bedtime reminders + session-complete local notifications.
 * Uses AlarmManager with boot reschedule via [BootReceiver].
 */
@Singleton
class NotificationService @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val channelId = "astrosleep_bedtime"
    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    init {
        ensureChannel()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Bedtime reminders",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "AstroSleep bedtime and session notifications"
            }
            val nm = context.getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    fun isNotificationPermissionGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Schedule a repeating daily bedtime alarm at [hour]:[minute] local time.
     * Persists schedule so [rescheduleFromPrefs] can restore after reboot.
     */
    fun scheduleBedtimeReminder(hour: Int, minute: Int) {
        prefs.edit()
            .putBoolean(KEY_ENABLED, true)
            .putInt(KEY_HOUR, hour.coerceIn(0, 23))
            .putInt(KEY_MINUTE, minute.coerceIn(0, 59))
            .apply()
        val triggerAt = nextTriggerEpochMs(hour, minute)
        scheduleAlarm(triggerAt)
    }

    fun scheduleBedtimeReminder(triggerAtEpochMs: Long) {
        val cal = Calendar.getInstance().apply { timeInMillis = triggerAtEpochMs }
        scheduleBedtimeReminder(cal.get(Calendar.HOUR_OF_DAY), cal.get(Calendar.MINUTE))
    }

    fun cancelBedtimeReminder() {
        prefs.edit().putBoolean(KEY_ENABLED, false).apply()
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(bedtimePendingIntent())
    }

    /** Call from [BootReceiver] after reboot. */
    fun rescheduleFromPrefs() {
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        val hour = prefs.getInt(KEY_HOUR, 22)
        val minute = prefs.getInt(KEY_MINUTE, 30)
        scheduleAlarm(nextTriggerEpochMs(hour, minute))
    }

    fun showBedtimeNotificationNow() {
        if (!isNotificationPermissionGranted()) return
        val open = PendingIntent.getActivity(
            context,
            1002,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Time to Sleep")
            .setContentText("Your personalized AstroSleep session is ready. Set your intention for tonight.")
            .setContentIntent(open)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.notify(NOTIF_BEDTIME, notification)
    }

    fun scheduleSessionCompleteNotification(afterMinutes: Int) {
        if (afterMinutes <= 0) return
        val trigger = System.currentTimeMillis() + afterMinutes * 60_000L
        val intent = Intent(context, BedtimeAlarmReceiver::class.java).apply {
            action = ACTION_SESSION_COMPLETE
        }
        val pending = PendingIntent.getBroadcast(
            context,
            REQ_SESSION,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
        } else {
            @Suppress("DEPRECATION")
            alarm.set(AlarmManager.RTC_WAKEUP, trigger, pending)
        }
    }

    fun showSessionCompleteNotification() {
        if (!isNotificationPermissionGranted()) return
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Sleep Session Complete")
            .setContentText("Your AstroSleep session has ended. Sweet dreams.")
            .setAutoCancel(true)
            .setSilent(true)
            .build()
        context.getSystemService(NotificationManager::class.java)
            .notify(NOTIF_SESSION, notification)
    }

    private fun scheduleAlarm(triggerAtEpochMs: Long) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = bedtimePendingIntent()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtEpochMs, pending)
            } else {
                @Suppress("DEPRECATION")
                alarm.set(AlarmManager.RTC_WAKEUP, triggerAtEpochMs, pending)
            }
        } catch (_: SecurityException) {
            // Exact alarms may require SCHEDULE_EXACT_ALARM — fall back to inexact
            alarm.set(AlarmManager.RTC_WAKEUP, triggerAtEpochMs, pending)
        }
    }

    private fun bedtimePendingIntent(): PendingIntent {
        val intent = Intent(context, BedtimeAlarmReceiver::class.java).apply {
            action = ACTION_BEDTIME
        }
        return PendingIntent.getBroadcast(
            context,
            REQ_BEDTIME,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun nextTriggerEpochMs(hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis() + 15_000L) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        return cal.timeInMillis
    }

    companion object {
        const val PREFS = "astrosleep_notifications"
        const val KEY_ENABLED = "bedtime_enabled"
        const val KEY_HOUR = "bedtime_hour"
        const val KEY_MINUTE = "bedtime_minute"
        const val ACTION_BEDTIME = "com.astrosleep.app.action.BEDTIME"
        const val ACTION_SESSION_COMPLETE = "com.astrosleep.app.action.SESSION_COMPLETE"
        private const val REQ_BEDTIME = 1001
        private const val REQ_SESSION = 1003
        private const val NOTIF_BEDTIME = 2001
        private const val NOTIF_SESSION = 2002
    }
}
