package com.lskram.officerelief

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import org.json.JSONObject

class EntryActivity : Activity() {
    companion object {
        const val ACTION_ALARM_FULLSCREEN = "com.lskram.officerelief.action.ALARM_FULLSCREEN"
        const val EXTRA_ALARM_PAYLOAD = "com.lskram.officerelief.extra.ALARM_PAYLOAD"

        private const val payloadExtraKey = "payload"
        private const val selectNotificationAction = "SELECT_NOTIFICATION"
        private const val selectForegroundNotificationAction = "SELECT_FOREGROUND_NOTIFICATION"
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

        val targetIntent = if (shouldOpenAlarmActivity(sourceIntent)) {
            buildAlarmIntent(sourceIntent)
        } else {
            buildMainIntent(sourceIntent)
        }

        startActivity(targetIntent)
        finish()
    }

    private fun shouldOpenAlarmActivity(sourceIntent: Intent): Boolean {
        val isNotificationLaunch =
            sourceIntent.action == selectNotificationAction ||
                sourceIntent.action == selectForegroundNotificationAction
        if (!isNotificationLaunch) {
            return false
        }

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
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
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
