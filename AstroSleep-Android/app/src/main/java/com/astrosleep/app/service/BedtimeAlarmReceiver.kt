package com.astrosleep.app.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class BedtimeAlarmReceiver : BroadcastReceiver() {

    @Inject
    lateinit var notifications: NotificationService

    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            NotificationService.ACTION_BEDTIME -> {
                notifications.showBedtimeNotificationNow()
                // Reschedule next day (setAndAllowWhileIdle is one-shot)
                notifications.rescheduleFromPrefs()
            }
            NotificationService.ACTION_SESSION_COMPLETE -> {
                notifications.showSessionCompleteNotification()
            }
        }
    }
}
