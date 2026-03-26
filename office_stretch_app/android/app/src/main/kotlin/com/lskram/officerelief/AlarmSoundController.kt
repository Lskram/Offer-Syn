package com.lskram.officerelief

import android.content.Context
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.provider.Settings
import android.util.Log
import org.json.JSONObject

object AlarmSoundController {
    private var ringtone: Ringtone? = null

    fun playIfNeeded(context: Context, payload: String) {
        val json =
            try {
                JSONObject(payload)
            } catch (_: Throwable) {
                return
            }

        if (!json.optBoolean("soundEnabled", false)) {
            stop()
            return
        }

        val soundUri =
            json.optString("notificationSoundUri")
                ?.takeIf { it.isNotBlank() }
                ?.let(Uri::parse)
                ?: Settings.System.DEFAULT_NOTIFICATION_URI

        try {
            stop()
            val nextRingtone =
                RingtoneManager.getRingtone(context.applicationContext, soundUri) ?: return
            nextRingtone.audioAttributes =
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            nextRingtone.play()
            ringtone = nextRingtone
            Log.i("AlarmSoundController", "Playing alarm sound uri=$soundUri")
        } catch (error: Throwable) {
            Log.w("AlarmSoundController", "Failed to play alarm sound", error)
        }
    }

    fun stop() {
        try {
            ringtone?.stop()
        } catch (_: Throwable) {
            // Ignore stop failures and clear the reference anyway.
        } finally {
            ringtone = null
        }
    }
}
