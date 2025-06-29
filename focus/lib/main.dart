import 'package:flutter/material.dart';
import 'focus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Foreground Tracker',
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

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing FocusDetector listener');
    FocusDetector.startListening((pkg) {
      debugPrint('Detected foreground app: $pkg');
      setState(() => _currentApp = pkg);
      
      // Debounce: Ignore rapid events within 500ms
      final now = DateTime.now();
      if (_lastOverlayTrigger != null && 
          now.difference(_lastOverlayTrigger!).inMilliseconds < 500) {
        debugPrint('Ignoring rapid app change for: $pkg');
        return;
      }
      
      if (_focusModeEnabled && !pkg.contains('com.raptors.focusapp')) {
        if (_lastProcessedPackage != pkg) {
          debugPrint('Triggering overlay for: $pkg');
          FocusDetector.showOverlayPopup(pkg);
          _lastProcessedPackage = pkg;
          _lastOverlayTrigger = now;
        } else {
          debugPrint('Overlay already triggered for: $pkg');
        }
      } else {
        debugPrint('Hiding overlay for: $pkg (Focus mode: $_focusModeEnabled)');
        FocusDetector.hideOverlayPopup();
        _lastProcessedPackage = null;
        _lastOverlayTrigger = null;
      }
    });
    
    _checkOverlayPermission();
  }
  
  void _checkOverlayPermission() async {
    debugPrint('Checking overlay permission');
    bool hasPermission = await FocusDetector.checkOverlayPermission();
    debugPrint('Overlay permission status: $hasPermission');
    if (!hasPermission) {
      debugPrint('Requesting overlay permission');
      await FocusDetector.requestOverlayPermission();
      await Future.delayed(const Duration(seconds: 1));
      hasPermission = await FocusDetector.checkOverlayPermission();
      debugPrint('Overlay permission after request: $hasPermission');
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Focus Mode: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Switch(
                  value: _focusModeEnabled,
                  onChanged: (value) async {
                    debugPrint('Focus mode toggled to: $value');
                    setState(() {
                      _focusModeEnabled = value;
                    });
                    FocusDetector.setFocusMode(value);
                    if (!value) {
                      debugPrint('Hiding overlay due to focus mode disabled');
                      FocusDetector.hideOverlayPopup();
                      _lastProcessedPackage = null;
                      _lastOverlayTrigger = null;
                    } else {
                      bool hasPermission = await FocusDetector.checkOverlayPermission();
                      debugPrint('Overlay permission when enabling focus mode: $hasPermission');
                      if (!hasPermission) {
                        debugPrint('Requesting overlay permission for focus mode');
                        await FocusDetector.requestOverlayPermission();
                        await Future.delayed(const Duration(seconds: 1));
                        hasPermission = await FocusDetector.checkOverlayPermission();
                        debugPrint('Overlay permission after request: $hasPermission');
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                debugPrint('Opening accessibility settings');
                openAccessibilitySettings();
              },
              child: const Text('Enable Accessibility Service'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () async {
                debugPrint('Manually requesting overlay permission');
                bool hasPermission = await FocusDetector.checkOverlayPermission();
                if (!hasPermission) {
                  await FocusDetector.requestOverlayPermission();
                  await Future.delayed(const Duration(seconds: 1));
                  hasPermission = await FocusDetector.checkOverlayPermission();
                  debugPrint('Overlay permission after manual request: $hasPermission');
                } else {
                  debugPrint('Already has overlay permission');
                }
              },
              child: const Text('Enable Overlay Permission'),
            ),
          ],
        ),
      ),
    );
  }
}