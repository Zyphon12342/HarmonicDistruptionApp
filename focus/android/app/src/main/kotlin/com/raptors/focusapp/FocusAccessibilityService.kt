package com.raptors.focusapp

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.MethodChannel

object ForegroundAppObserver {
    var lastPackageName: String? = null
    var channel: MethodChannel? = null
    var lastEventTime: Long = 0
}

class FocusAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            val currentTime = System.currentTimeMillis()
            if (packageName != null && packageName != ForegroundAppObserver.lastPackageName) {
                // Debounce: Ignore events within 1500ms of the last
                if (currentTime - ForegroundAppObserver.lastEventTime < 1500) {
                    Log.d("FocusService", "Ignoring rapid event for: $packageName")
                    return
                }
                ForegroundAppObserver.lastPackageName = packageName
                ForegroundAppObserver.lastEventTime = currentTime
                Log.d("FocusService", "Foreground app: $packageName")
                ForegroundAppObserver.channel?.invokeMethod("onForegroundAppChanged", packageName)
            }
        }
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        serviceInfo = info
    }
}