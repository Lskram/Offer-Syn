package com.lskram.officerelief

import android.app.Activity
import android.os.Build
import android.view.WindowManager

object AlarmWindowController {
    fun enable(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            activity.setShowWhenLocked(true)
            activity.setTurnScreenOn(true)
            return
        }

        @Suppress("DEPRECATION")
        activity.window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
        )
    }
}
