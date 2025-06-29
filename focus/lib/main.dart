import 'dart:async';
import 'package:flutter/material.dart';
import 'focus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Background Logger',
      theme: ThemeData(primarySwatch: Colors.indigo),
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
  String? _currentPackage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start checking periodically every 3 seconds
    _startForegroundAppChecker();
  }

  void _startForegroundAppChecker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final pkg = await FocusDetector.getFocusApp();
      if (pkg != null && pkg != _currentPackage) {
        debugPrint("💡 Foreground app changed: $pkg");
        setState(() => _currentPackage = pkg);
      } else {
        debugPrint("📌 Still in: $pkg");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus App Monitor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentPackage == null
                  ? 'No app detected yet'
                  : 'Current foreground app:\n$_currentPackage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: openUsageAccessSettings,
              child: const Text('Open Usage Access Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
