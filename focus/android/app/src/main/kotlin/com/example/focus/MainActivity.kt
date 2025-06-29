package com.example.focus

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register MethodChannel for communication with Dart
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focus.accessibility")
        ForegroundAppObserver.channel = channel
    }
}
