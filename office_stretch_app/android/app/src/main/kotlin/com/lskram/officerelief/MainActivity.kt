package com.lskram.officerelief

import android.content.Intent
import android.os.Bundle

class MainActivity : BaseFlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        captureAutomationIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureAutomationIntent(intent)
    }
}
