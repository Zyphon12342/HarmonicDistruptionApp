import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'focus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Load .env
  debugPrint('ENV vars loaded: ${dotenv.env}');
  await Firebase.initializeApp(); // Initialize Firebase
  debugPrint('Firebase initialized: ${Firebase.apps.map((a) => a.name)}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Foreground Tracker',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentApp = 'Unknown';
  bool _focusModeEnabled = false;
  String? _lastProcessedPackage;
  DateTime? _lastOverlayTrigger;

  late final DatabaseReference _dbRootRef;
  late final DatabaseReference _focusModeRef;
  late final Stream<DatabaseEvent> _focusModeStream;

  @override
  void initState() {
    super.initState();

    // 1) Setup Firebase DB references
    final dbUrl = dotenv.env['FIREBASE_DB_URL'] ?? '';
    debugPrint('▶️ Connecting to DB URL: $dbUrl');
    _dbRootRef =
        FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: dbUrl,
        ).ref();

    // Path to the live focusMode boolean
    _focusModeRef = _dbRootRef.child('users/User0/settings/focusMode');
    // Separate path for app usage logs

    // 2) Listen in real time to focusMode
    _focusModeStream = _focusModeRef.onValue;
    _focusModeStream.listen(
      (event) {
        final val = event.snapshot.value;
        debugPrint('⟳ focusMode snapshot received: $val');
        if (val is bool) {
          setState(() => _focusModeEnabled = val);
          debugPrint('→ _focusModeEnabled updated to: $_focusModeEnabled');
          debugPrint('→ Focus mode changed: $val');
          // **TELL the native service too:**
          FocusDetector.setFocusMode(val);
          debugPrint('→ Focus mode chaasasdnged: $val');
          debugPrint('→ FocusDetector.setFocusMode($val) called');
        } else {
          debugPrint(
            '⚠️ focusMode missing or not bool (type=${val.runtimeType})',
          );
        }
      },
      onError: (err) {
        debugPrint('❌ focusMode listener error: $err');
      },
    );

    // 3) Kick off permission flows and start detection
    requestExactAlarmPermission();
    startFocusDetection();
    _checkOverlayPermission();
  }

  void startFocusDetection() {
    debugPrint('🔍 Starting FocusDetector listener');
    FocusDetector.startListening((pkg) async {
      debugPrint('  • Detected foreground app: $pkg');
      setState(() => _currentApp = pkg);
      // Debounce overlay
      final now = DateTime.now();
      if (_lastOverlayTrigger != null &&
          now.difference(_lastOverlayTrigger!).inMilliseconds < 500) {
        debugPrint('⏱ Debounced overlay for $pkg');
        return;
      }

      // Overlay logic
      if (_focusModeEnabled /*&& !pkg.contains('com.raptors.focusapp')*/ ) {
        debugPrint('💡 focusModeEnabled=$_focusModeEnabled, pkg=$pkg');
        bool canOverlay = await FocusDetector.checkOverlayPermission();
        debugPrint('   overlay permission: $canOverlay');
        if (!canOverlay) {
          debugPrint('   ❗️ Requesting overlay permission before show');
          await FocusDetector.requestOverlayPermission();
          await Future.delayed(const Duration(milliseconds: 500));
          canOverlay = await FocusDetector.checkOverlayPermission();
          debugPrint('   overlay permission after request: $canOverlay');
        }

        if (canOverlay && _lastProcessedPackage != pkg) {
          debugPrint('▶︎ Showing overlay for $pkg');
          FocusDetector.showOverlayPopup(pkg);
          _lastProcessedPackage = pkg;
          _lastOverlayTrigger = now;
        } else {
          debugPrint('ℹ️ Skipping overlay (canOverlay=$canOverlay)');
        }
      } else {
        debugPrint('◼︎ Hiding overlay (focusMode=$_focusModeEnabled)');
        FocusDetector.hideOverlayPopup();
        _lastProcessedPackage = null;
        _lastOverlayTrigger = null;
      }
    });
  }

  Future<void> _checkOverlayPermission() async {
    debugPrint('🔍 Checking overlay permission...');
    try {
      bool hasPermission = await FocusDetector.checkOverlayPermission();
      debugPrint('→ Overlay permission status: $hasPermission');
      if (!hasPermission) {
        debugPrint('→ Requesting overlay permission...');
        await FocusDetector.requestOverlayPermission();
        await Future.delayed(const Duration(seconds: 1));
        hasPermission = await FocusDetector.checkOverlayPermission();
        debugPrint('→ Permission after request: $hasPermission');
      }
    } catch (e) {
      debugPrint('❌ Overlay permission check error: $e');
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      debugPrint('🔍 Requesting exact-alarm permission (Android 12+)...');
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      try {
        await intent.launch();
        debugPrint('→ Exact-alarm settings launched');
      } catch (e) {
        debugPrint('❌ Failed to launch exact-alarm intent: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Foreground Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Foreground App:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _currentApp,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Text(
              'Focus Mode: $_focusModeEnabled',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: openAccessibilitySettings,
              child: const Text('Enable Accessibility Service'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkOverlayPermission,
              child: const Text('Enable Overlay Permission'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: requestExactAlarmPermission,
              child: const Text('Request Exact Alarm Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
