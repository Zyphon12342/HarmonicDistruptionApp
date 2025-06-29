package com.raptors.focusapp

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.LinearLayout

class OverlayService(private val context: Context) {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var focusModeEnabled = false
    private var currentPackage: String? = null
    
    init {
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        Log.d("OverlayService", "OverlayService initialized")
    }
    
    fun setFocusMode(enabled: Boolean) {
        focusModeEnabled = enabled
        Log.d("OverlayService", "Focus mode set to: $enabled")
        if (!enabled) {
            hideOverlay()
        }
    }
    
    fun showOverlay(packageName: String) {
        Log.d("OverlayService", "Attempting to show overlay for: $packageName")
        
        if (!focusModeEnabled) {
            Log.d("OverlayService", "Focus mode disabled, not showing overlay")
            return
        }
        
        if (packageName.contains("com.raptors.focusapp")) {
            Log.d("OverlayService", "Own app in foreground, not showing overlay")
            hideOverlay()
            return
        }
        
        if (currentPackage == packageName && overlayView != null) {
            Log.d("OverlayService", "Overlay already shown for $packageName, skipping")
            return
        }
        
        hideOverlay() // Hide existing overlay if any
        currentPackage = packageName
        
        overlayView = createOverlayView(packageName)
        
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_SYSTEM_ERROR
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR,
            PixelFormat.TRANSLUCENT
        )
        
        layoutParams.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        layoutParams.y = 20 // Close to top for visibility
        
        try {
            windowManager?.addView(overlayView, layoutParams)
            Log.d("OverlayService", "Overlay added successfully for $packageName")
        } catch (e: Exception) {
            Log.e("OverlayService", "Failed to add overlay: ${e.message}", e)
            currentPackage = null
        }
    }
    
    private fun createOverlayView(packageName: String): View {
        Log.d("OverlayService", "Creating overlay view for: $packageName")
        val overlayView = LinearLayout(context)
        overlayView.orientation = LinearLayout.VERTICAL
        overlayView.setBackgroundColor(0xCCFF5722.toInt()) // Semi-transparent orange
        overlayView.setPadding(40, 40, 40, 40)
        
        // Title
        val titleText = TextView(context)
        titleText.text = "⚠️ Focus Mode Active"
        titleText.textSize = 18f
        titleText.setTextColor(0xFFFFFFFF.toInt())
        titleText.gravity = Gravity.CENTER
        overlayView.addView(titleText)
        
        // App name
        val appNameText = TextView(context)
        val appName = getAppName(packageName)
        appNameText.text = "Close $appName\nThis app is causing distraction!"
        appNameText.textSize = 16f
        appNameText.setTextColor(0xFFFFFFFF.toInt())
        appNameText.gravity = Gravity.CENTER
        val appNameMargin = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        appNameMargin.setMargins(0, 20, 0, 40)
        appNameText.layoutParams = appNameMargin
        overlayView.addView(appNameText)
        
        // Button container
        val buttonContainer = LinearLayout(context)
        buttonContainer.orientation = LinearLayout.HORIZONTAL
        buttonContainer.gravity = Gravity.CENTER
        
        // Close button
        val closeButton = Button(context)
        closeButton.text = "Close App"
        closeButton.setTextColor(0xFFFF5722.toInt())
        closeButton.setBackgroundColor(0xFFFFFFFF.toInt())
        closeButton.setOnClickListener {
            Log.d("OverlayService", "Close button clicked for $packageName")
            closeApp(packageName)
            hideOverlay()
        }
        
        // Dismiss button
        val dismissButton = Button(context)
        dismissButton.text = "Dismiss"
        dismissButton.setTextColor(0xFFFFFFFF.toInt())
        dismissButton.setBackgroundColor(0x00000000) // Transparent
        dismissButton.setOnClickListener {
            Log.d("OverlayService", "Dismiss button clicked")
            hideOverlay()
        }
        
        // Add margins to buttons
        val buttonMargin = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        buttonMargin.setMargins(10, 0, 10, 0)
        closeButton.layoutParams = buttonMargin
        dismissButton.layoutParams = buttonMargin
        
        buttonContainer.addView(closeButton)
        buttonContainer.addView(dismissButton)
        overlayView.addView(buttonContainer)
        
        return overlayView
    }
    
    fun hideOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
                Log.d("OverlayService", "Overlay removed successfully")
            } catch (e: Exception) {
                Log.e("OverlayService", "Failed to remove overlay: ${e.message}", e)
            }
            overlayView = null
            currentPackage = null
        }
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = context.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            Log.e("OverlayService", "Failed to get app name for $packageName: ${e.message}")
            packageName
        }
    }
    
    private fun closeApp(packageName: String) {
        try {
            val homeIntent = android.content.Intent(android.content.Intent.ACTION_MAIN)
            homeIntent.addCategory(android.content.Intent.CATEGORY_HOME)
            homeIntent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(homeIntent)
            Log.d("OverlayService", "Closed app $packageName by launching home")
        } catch (e: Exception) {
            Log.e("OverlayService", "Error closing app $packageName: ${e.message}", e)
        }
    }
}