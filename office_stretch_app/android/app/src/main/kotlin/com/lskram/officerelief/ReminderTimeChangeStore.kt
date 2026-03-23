package com.lskram.officerelief

import android.content.Context
import java.util.TimeZone

object ReminderTimeChangeStore {
    private const val preferencesName = "office_relief.time_change_state"
    private const val pendingKey = "pending"
    private const val actionKey = "action"
    private const val observedAtKey = "observed_at_millis"
    private const val timeZoneIdKey = "time_zone_id"
    private const val systemTimeKey = "system_time_millis"

    fun markPending(context: Context, action: String?) {
        val now = System.currentTimeMillis()
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(pendingKey, true)
            .putString(actionKey, action)
            .putLong(observedAtKey, now)
            .putString(timeZoneIdKey, TimeZone.getDefault().id)
            .putLong(systemTimeKey, now)
            .apply()
    }

    fun consume(context: Context): Map<String, Any?>? {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        if (!preferences.getBoolean(pendingKey, false)) {
            return null
        }

        val payload =
            mapOf(
                "action" to preferences.getString(actionKey, null),
                "observedAtMillis" to preferences.getLong(observedAtKey, System.currentTimeMillis()),
                "timeZoneId" to preferences.getString(timeZoneIdKey, null),
                "systemTimeMillis" to preferences.getLong(systemTimeKey, System.currentTimeMillis()),
            )

        preferences
            .edit()
            .remove(pendingKey)
            .remove(actionKey)
            .remove(observedAtKey)
            .remove(timeZoneIdKey)
            .remove(systemTimeKey)
            .apply()

        return payload
    }
}
