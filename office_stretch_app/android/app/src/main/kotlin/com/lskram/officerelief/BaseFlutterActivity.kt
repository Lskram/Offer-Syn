package com.lskram.officerelief

import android.app.Activity
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

abstract class BaseFlutterActivity : FlutterActivity() {
    companion object {
        private const val alarmFullscreenAction =
            "com.lskram.officerelief.action.ALARM_FULLSCREEN"
        private const val alarmPayloadExtra =
            "com.lskram.officerelief.extra.ALARM_PAYLOAD"
    }

    private val notificationSoundPickerRequestCode = 2048

    private var appLaunchBridgeReady = false
    private var pendingAutomationCommand: Map<String, Any?>? = null
    private var pendingLaunchCommand: Map<String, Any?>? = null
    private var pendingSoundPickerResult: MethodChannel.Result? = null
    private var appLaunchChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "office_stretch_app/device_settings",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }

                "openAppNotificationSettings" -> {
                    result.success(openAppNotificationSettings())
                }

                "openBatteryOptimizationSettings" -> {
                    result.success(openBatteryOptimizationSettings())
                }

                "canUseFullScreenIntent" -> {
                    result.success(canUseFullScreenIntent())
                }

                "openFullScreenIntentSettings" -> {
                    result.success(openFullScreenIntentSettings())
                }

                "getActiveNotifications" -> {
                    result.success(getActiveNotifications())
                }

                "clearActiveNotifications" -> {
                    result.success(clearActiveNotifications())
                }

                "takePendingTimeChangeSignal" -> {
                    result.success(ReminderTimeChangeStore.consume(this))
                }

                "pickNotificationSound" -> {
                    pickNotificationSound(call.argument("existingUri"), result)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "office_stretch_app/device_automation",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "takePendingAutomationCommand" -> {
                    val command = pendingAutomationCommand
                    pendingAutomationCommand = null
                    result.success(command)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "office_stretch_app/host_activity",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "finishIfAlarmHost" -> {
                    val shouldFinish = javaClass.simpleName == "AlarmActivity"
                    if (shouldFinish) {
                        finish()
                    }
                    result.success(shouldFinish)
                }

                else -> result.notImplemented()
            }
        }

        appLaunchChannel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "office_stretch_app/app_launch",
            ).also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "takePendingLaunchCommand" -> {
                            val command = pendingLaunchCommand
                            pendingLaunchCommand = null
                            result.success(command)
                        }

                        "markLaunchBridgeReady" -> {
                            appLaunchBridgeReady = true
                            deliverPendingLaunchCommand()
                            result.success(null)
                        }

                        else -> result.notImplemented()
                    }
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != notificationSoundPickerRequestCode) {
            return
        }

        val result = pendingSoundPickerResult ?: return
        pendingSoundPickerResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val pickedUri = getPickedRingtoneUri(data)
        if (pickedUri == null) {
            result.success(null)
            return
        }

        val isDefault = pickedUri == Settings.System.DEFAULT_NOTIFICATION_URI
        if (isDefault) {
            result.success(
                mapOf(
                    "uri" to pickedUri.toString(),
                    "label" to "Default system sound",
                    "isDefault" to true,
                ),
            )
            return
        }

        val title =
            RingtoneManager.getRingtone(applicationContext, pickedUri)?.getTitle(applicationContext)
                ?: "Selected system sound"
        result.success(
            mapOf(
                "uri" to pickedUri.toString(),
                "label" to title,
                "isDefault" to false,
            ),
        )
    }

    protected fun captureAutomationIntent(intent: Intent?) {
        if (intent == null) {
            return
        }

        val action = intent.getStringExtra("codexAction") ?: return
        if (
            action != "prepareScheduledReminder" &&
                action != "postImmediateNotification" &&
                action != "armImmediateNotification"
        ) {
            return
        }

        pendingAutomationCommand =
            mapOf(
                "action" to action,
                "alertMode" to intent.getStringExtra("alertMode"),
                "intervalMinutes" to intent.getIntExtra("intervalMinutes", 1),
                "delayMinutes" to intent.getIntExtra("delayMinutes", 1),
                "delaySeconds" to intent.getIntExtra("delaySeconds", 8),
                "startHour" to intent.getIntExtra("startHour", 0),
                "startMinute" to intent.getIntExtra("startMinute", 0),
                "endHour" to intent.getIntExtra("endHour", 23),
                "endMinute" to intent.getIntExtra("endMinute", 59),
            )
    }

    protected fun captureAlarmLaunchIntent(intent: Intent?) {
        if (intent == null || intent.action != alarmFullscreenAction) {
            return
        }

        val payload = intent.getStringExtra(alarmPayloadExtra) ?: return
        pendingLaunchCommand =
            mapOf(
                "action" to "presentAlarmLaunch",
                "payload" to payload,
            )

        if (appLaunchBridgeReady) {
            deliverPendingLaunchCommand()
        }
    }

    protected fun enableAlarmWindowBehavior() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            return
        }

        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
        )
    }

    private fun deliverPendingLaunchCommand() {
        val command = pendingLaunchCommand ?: return
        val channel = appLaunchChannel ?: return

        try {
            channel.invokeMethod("didReceiveLaunchCommand", command)
            pendingLaunchCommand = null
        } catch (error: Throwable) {
            // Keep the command queued so Flutter can pick it up later.
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return null
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        return powerManager?.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openAppNotificationSettings(): Boolean {
        val intent =
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

        return startIntentSafely(intent)
    }

    private fun openBatteryOptimizationSettings(): Boolean {
        val requestIntent =
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

        if (startIntentSafely(requestIntent)) {
            return true
        }

        val fallbackIntent =
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

        return startIntentSafely(fallbackIntent)
    }

    private fun canUseFullScreenIntent(): Boolean? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return true
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        return notificationManager?.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return openAppNotificationSettings()
        }

        val intent =
            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

        if (startIntentSafely(intent)) {
            return true
        }

        return openAppNotificationSettings()
    }

    private fun getActiveNotifications(): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return emptyList()
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return emptyList()

        return notificationManager.activeNotifications
            .filter { it.packageName == packageName }
            .map { statusBarNotification ->
                val notification = statusBarNotification.notification
                mapOf(
                    "id" to statusBarNotification.id,
                    "tag" to statusBarNotification.tag,
                    "channelId" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) notification.channelId else null,
                    "category" to notification.category,
                    "hasFullScreenIntent" to (notification.fullScreenIntent != null),
                    "title" to notification.extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
                    "text" to notification.extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
                )
            }
    }

    private fun clearActiveNotifications(): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return 0
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return 0

        var clearedCount = 0
        notificationManager.activeNotifications
            .filter { it.packageName == packageName }
            .forEach { statusBarNotification ->
                val tag = statusBarNotification.tag
                if (tag == null) {
                    notificationManager.cancel(statusBarNotification.id)
                } else {
                    notificationManager.cancel(tag, statusBarNotification.id)
                }
                clearedCount += 1
            }

        return clearedCount
    }

    private fun pickNotificationSound(existingUri: String?, result: MethodChannel.Result) {
        if (pendingSoundPickerResult != null) {
            result.error("picker_busy", "Notification sound picker is already open", null)
            return
        }

        val intent =
            Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                putExtra(RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI, Settings.System.DEFAULT_NOTIFICATION_URI)
                putExtra(
                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                    existingUri?.takeIf { it.isNotBlank() }?.let(Uri::parse)
                        ?: Settings.System.DEFAULT_NOTIFICATION_URI,
                )
                putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Choose notification sound")
            }

        if (intent.resolveActivity(packageManager) == null) {
            result.success(null)
            return
        }

        pendingSoundPickerResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(intent, notificationSoundPickerRequestCode)
    }

    private fun getPickedRingtoneUri(intent: Intent?): Uri? {
        if (intent == null) {
            return null
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI) as? Uri
        }
    }

    private fun startIntentSafely(intent: Intent): Boolean {
        return if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
            true
        } else {
            false
        }
    }
}
