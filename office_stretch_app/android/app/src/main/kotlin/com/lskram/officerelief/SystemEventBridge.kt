package com.lskram.officerelief

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object SystemEventBridge {
    private const val channelName = "office_stretch_app/system_events"

    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingEvents = ArrayDeque<Map<String, Any?>>()

    private var bridgeReady = false
    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    fun attach(context: Context, binaryMessenger: BinaryMessenger) {
        bridgeReady = false
        appContext = context.applicationContext
        channel =
            MethodChannel(binaryMessenger, channelName).also { methodChannel ->
                methodChannel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "takePendingSystemEvent" -> {
                            result.success(dequeuePendingEvent())
                        }

                        "markSystemEventBridgeReady" -> {
                            bridgeReady = true
                            deliverPendingEvents()
                            result.success(null)
                        }

                        "acknowledgePendingSystemEvent" -> {
                            appContext?.let(ReminderTimeChangeStore::clear)
                            result.success(null)
                        }

                        else -> result.notImplemented()
                    }
                }
            }
    }

    fun enqueue(event: Map<String, Any?>) {
        mainHandler.post {
            pendingEvents.addLast(event)
            deliverPendingEvents()
        }
    }

    private fun dequeuePendingEvent(): Map<String, Any?>? {
        return if (pendingEvents.isEmpty()) {
            null
        } else {
            pendingEvents.removeFirst()
        }
    }

    private fun deliverPendingEvents() {
        val activeChannel = channel ?: return
        if (!bridgeReady) {
            return
        }

        while (pendingEvents.isNotEmpty()) {
            val event = pendingEvents.removeFirst()
            try {
                activeChannel.invokeMethod("didReceiveSystemEvent", event)
            } catch (_: Throwable) {
                pendingEvents.addFirst(event)
                return
            }
        }
    }
}
