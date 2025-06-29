package com.example.focus

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.MethodChannel

object ForegroundAppObserver {
    var lastPackageName: String? = null
    var channel: MethodChannel? = null
}

class FocusAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            if (packageName != null && packageName != ForegroundAppObserver.lastPackageName) {
                ForegroundAppObserver.lastPackageName = packageName
                Log.d("FocusService", "Foreground app: $packageName")

                ForegroundAppObserver.channel?.invokeMethod(
                    "onForegroundAppChanged", packageName
                )
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