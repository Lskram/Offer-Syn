package com.lskram.officerelief

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import java.util.TimeZone

class ReminderTimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i(
            "ReminderTimeChangeRx",
            "Received action=${intent?.action ?: "unknown"} zone=${TimeZone.getDefault().id}",
        )
        ReminderTimeChangeStore.markPending(context, intent?.action)
        ReminderTimeChangeStore.peek(context)?.let(SystemEventBridge::enqueue)
        Log.i("ReminderTimeChangeRx", "Stored pending time-change signal for Flutter recovery.")
        reschedulePluginNotifications(context)
    }

    private fun reschedulePluginNotifications(context: Context) {
        try {
            val method =
                FlutterLocalNotificationsPlugin::class.java.getDeclaredMethod(
                    "rescheduleNotifications",
                    Context::class.java,
                )
            method.isAccessible = true
            method.invoke(null, context)
            Log.i(
                "ReminderTimeChangeRx",
                "Rescheduled plugin notifications after system time change.",
            )
        } catch (error: Throwable) {
            Log.w(
                "ReminderTimeChangeRx",
                "Failed to reschedule notifications after system time change",
                error,
            )
        }
    }
}
