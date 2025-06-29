import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';

class FocusDetector {
  static const MethodChannel _channel = MethodChannel('focus.accessibility');

  static void startListening(void Function(String packageName) onAppChanged) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onForegroundAppChanged') {
        final pkg = call.arguments as String;
        onAppChanged(pkg);
      }
    });
  }

  static void setFocusMode(bool enabled) {
    _channel.invokeMethod('setFocusMode', enabled);
  }

  static Future<bool> checkOverlayPermission() async {
    final result = await _channel.invokeMethod('checkOverlayPermission');
    return result as bool;
  }

  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static void showOverlayPopup(String packageName) {
    _channel.invokeMethod('showOverlayPopup', packageName);
  }

  static void hideOverlayPopup() {
    _channel.invokeMethod('hideOverlayPopup');
  }
}

Future<void> openAccessibilitySettings() async {
  final intent = AndroidIntent(
    action: 'android.settings.ACCESSIBILITY_SETTINGS',
  );
  await intent.launch();
}