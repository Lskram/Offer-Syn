package com.lskram.officerelief

import android.content.Intent
import android.os.Bundle
import android.util.Log

class AlarmActivity : BaseFlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        AlarmWindowController.enable(this)
        Log.i("AlarmActivity", "onCreate action=${intent?.action ?: "null"}")
        vibrateAlarmIfNeeded(intent)
        playAlarmSoundIfNeeded(intent)
        captureAlarmLaunchIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        AlarmWindowController.enable(this)
        Log.i("AlarmActivity", "onNewIntent action=${intent.action ?: "null"}")
        vibrateAlarmIfNeeded(intent)
        playAlarmSoundIfNeeded(intent)
        captureAlarmLaunchIntent(intent)
    }

    override fun onDestroy() {
        stopAlarmAttention()
        super.onDestroy()
    }
}
