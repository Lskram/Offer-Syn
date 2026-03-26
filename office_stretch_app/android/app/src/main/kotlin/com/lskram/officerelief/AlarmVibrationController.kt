package com.lskram.officerelief

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import org.json.JSONObject

object AlarmVibrationController {
    fun vibrateIfNeeded(context: Context, payload: String) {
        val json =
            try {
                JSONObject(payload)
            } catch (_: Throwable) {
                return
            }

        if (!json.optBoolean("vibrationEnabled", false)) {
            return
        }

        val pattern =
            when (json.optString("vibrationLevel")) {
                "light" -> longArrayOf(0, 140, 90, 140)
                "strong" -> longArrayOf(0, 420, 160, 420, 160, 420)
                else -> longArrayOf(0, 260, 120, 260, 120, 260)
            }

        val vibrator = resolveVibrator(context) ?: return
        if (!vibrator.hasVibrator()) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    private fun resolveVibrator(context: Context): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(VibratorManager::class.java)
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
