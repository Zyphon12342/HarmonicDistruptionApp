package com.raptors.focusapp

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "focus.accessibility"
    private val REQUEST_OVERLAY_PERMISSION = 1234
    private lateinit var overlayService: OverlayService
    private var pendingResult: MethodChannel.Result? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        overlayService = OverlayService(this)
        ForegroundAppObserver.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setFocusMode" -> {
                    val enabled = call.arguments as Boolean
                    Log.d("FocusApp", "Setting focus mode: $enabled")
                    overlayService.setFocusMode(enabled)
                    result.success(null)
                }
                "checkOverlayPermission" -> {
                    val hasPermission = checkOverlayPermission()
                    Log.d("FocusApp", "Overlay permission check: $hasPermission")
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    Log.d("FocusApp", "Requesting overlay permission")
                    pendingResult = result
                    requestOverlayPermission()
                }
                "showOverlayPopup" -> {
                    val packageName = call.arguments as String
                    Log.d("FocusApp", "Received showOverlayPopup for: $packageName")
                    if (checkOverlayPermission()) {
                        overlayService.showOverlay(packageName)
                        result.success(null)
                    } else {
                        Log.e("FocusApp", "No overlay permission!")
                        result.error("NO_PERMISSION", "Overlay permission not granted", null)
                    }
                }
                "hideOverlayPopup" -> {
                    overlayService.hideOverlay()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
            } else {
                pendingResult?.success(null)
                pendingResult = null
            }
        } else {
            pendingResult?.success(null)
            pendingResult = null
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_OVERLAY_PERMISSION) {
            val hasPermission = checkOverlayPermission()
            Log.d("FocusApp", "Overlay permission result: $hasPermission")
            pendingResult?.success(hasPermission)
            pendingResult = null
        }
    }
}