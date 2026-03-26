package com.lskram.officerelief

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import org.json.JSONObject

class EntryActivity : Activity() {
    companion object {
        const val ACTION_ALARM_FULLSCREEN = "com.lskram.officerelief.action.ALARM_FULLSCREEN"
        const val EXTRA_ALARM_PAYLOAD = "com.lskram.officerelief.extra.ALARM_PAYLOAD"

        private const val payloadExtraKey = "payload"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        routeIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        routeIntent(intent)
    }

    private fun routeIntent(sourceIntent: Intent?) {
        if (sourceIntent == null) {
            finish()
            return
        }

        val shouldOpenAlarm = shouldOpenAlarmActivity(sourceIntent)
        if (shouldOpenAlarm) {
            AlarmWindowController.enable(this)
        }

        val targetIntent = if (shouldOpenAlarm) {
            buildAlarmIntent(sourceIntent)
        } else {
            buildMainIntent(sourceIntent)
        }

        Log.i(
            "EntryActivity",
            "Routing intent to ${if (shouldOpenAlarm) "AlarmActivity" else "MainActivity"} action=${sourceIntent.action ?: "null"}",
        )
        startActivity(targetIntent)
        finish()
    }

    private fun shouldOpenAlarmActivity(sourceIntent: Intent): Boolean {
        val payload = sourceIntent.getStringExtra(payloadExtraKey) ?: return false
        return try {
            JSONObject(payload).optString("alertMode") == "exactFullScreen"
        } catch (_: Throwable) {
            false
        }
    }

    private fun buildMainIntent(sourceIntent: Intent): Intent {
        return Intent(this, MainActivity::class.java).apply {
            copyIntentMetadataFrom(sourceIntent)
        }
    }

    private fun buildAlarmIntent(sourceIntent: Intent): Intent {
        return Intent(this, AlarmActivity::class.java).apply {
            action = ACTION_ALARM_FULLSCREEN
            putExtra(EXTRA_ALARM_PAYLOAD, sourceIntent.getStringExtra(payloadExtraKey))
            addFlags(
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK,
            )
        }
    }

    private fun Intent.copyIntentMetadataFrom(sourceIntent: Intent) {
        action = sourceIntent.action
        data = sourceIntent.data
        sourceIntent.extras?.let(::putExtras)
        sourceIntent.categories?.forEach(::addCategory)
        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    }
}
