package com.example.office_stretch_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationSoundPickerRequestCode = 2048
    private var pendingSoundPickerResult: MethodChannel.Result? = null

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

                "pickNotificationSound" -> {
                    pickNotificationSound(call.argument("existingUri"), result)
                }

                else -> result.notImplemented()
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
                    "label" to "เสียงเริ่มต้นของระบบ",
                    "isDefault" to true,
                ),
            )
            return
        }

        val title =
            RingtoneManager.getRingtone(applicationContext, pickedUri)?.getTitle(applicationContext)
                ?: "เสียงระบบที่เลือก"
        result.success(
            mapOf(
                "uri" to pickedUri.toString(),
                "label" to title,
                "isDefault" to false,
            ),
        )
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
                putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "เลือกเสียงแจ้งเตือน")
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
