package com.lskram.officerelief

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin

class ReminderTimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        ReminderTimeChangeStore.markPending(context, intent?.action)
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
        } catch (error: Throwable) {
            Log.w(
                "ReminderTimeChangeRx",
                "Failed to reschedule notifications after system time change",
                error,
            )
        }
    }
}
