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
}

Future<void> openAccessibilitySettings() async {
  final intent = AndroidIntent(
    action: 'android.settings.ACCESSIBILITY_SETTINGS',
  );
  await intent.launch();
}
