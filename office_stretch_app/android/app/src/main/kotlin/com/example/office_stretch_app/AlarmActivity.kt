package com.example.office_stretch_app

import android.content.Intent
import android.os.Bundle

class AlarmActivity : BaseFlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableAlarmWindowBehavior()
        captureAlarmLaunchIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        enableAlarmWindowBehavior()
        captureAlarmLaunchIntent(intent)
    }
}
