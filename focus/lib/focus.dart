import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

/// A helper that wraps the platform channel for detecting the foreground app.
class FocusDetector {
  static const MethodChannel _channel = MethodChannel('focus.app/check');

  /// Returns the package name of the current foreground app, or null if unavailable.
  static Future<String?> getFocusApp() async {
    try {
      final String? pkg = await _channel.invokeMethod<String>('getFocusApp');
      debugPrint('DEBUG: Detected foreground package: $pkg');
      return pkg;
    } on PlatformException catch (e) {
      debugPrint('FocusDetector error: $e');
      return null;
    }
  }
}

/// Opens the Android Usage Access settings so the user can grant your app
/// the PACKAGE_USAGE_STATS permission.
Future<void> openUsageAccessSettings() async {
  final intent = AndroidIntent(
    action: 'android.settings.USAGE_ACCESS_SETTINGS',
  );
  await intent.launch();
}
