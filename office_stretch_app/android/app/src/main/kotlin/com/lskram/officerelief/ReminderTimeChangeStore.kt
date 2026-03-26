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
        val payload = readPayload(preferences) ?: return null

        clear(preferences)

        return payload
    }

    fun peek(context: Context): Map<String, Any?>? {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        return readPayload(preferences)
    }

    fun clear(context: Context) {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        clear(preferences)
    }

    private fun clear(preferences: android.content.SharedPreferences) {
        preferences
            .edit()
            .remove(pendingKey)
            .remove(actionKey)
            .remove(observedAtKey)
            .remove(timeZoneIdKey)
            .remove(systemTimeKey)
            .apply()
    }

    private fun readPayload(
        preferences: android.content.SharedPreferences,
    ): Map<String, Any?>? {
        if (!preferences.getBoolean(pendingKey, false)) {
            return null
        }

        return mapOf(
            "action" to preferences.getString(actionKey, null),
            "observedAtMillis" to preferences.getLong(observedAtKey, System.currentTimeMillis()),
            "timeZoneId" to preferences.getString(timeZoneIdKey, null),
            "systemTimeMillis" to preferences.getLong(systemTimeKey, System.currentTimeMillis()),
        )
    }
}
