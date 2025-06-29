package com.example.focus

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val CHANNEL = "focus.app/check"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "getFocusApp" -> result.success(getFocusAppPackage())
          else           -> result.notImplemented()
        }
      }
  }

  private fun getFocusAppPackage(): String? {
    val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    val end = System.currentTimeMillis()
    val begin = end - 10_000L  // last 10 seconds
    val stats: List<UsageStats> = usm.queryUsageStats(
      UsageStatsManager.INTERVAL_DAILY, begin, end
    )
    val lastUsed = stats.maxByOrNull { it.lastTimeUsed }
    return lastUsed?.packageName
  }
}
