import 'dart:io';
import 'dart:ui';
import 'dart:math'; // Needed for cos() and sin()

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'focus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C64E9),
        brightness: Brightness.dark,
        fontFamily: 'Montserrat',
      ),
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _currentApp = 'Unknown';
  bool _focusModeEnabled = false;
  String? _lastProcessedPackage;
  DateTime? _lastOverlayTrigger;

  late final DatabaseReference _dbRootRef;
  late final DatabaseReference _focusModeRef;
  late final Stream<DatabaseEvent> _focusModeStream;
  
  late AnimationController _slideController;
  late AnimationController _gradientController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    
    _slideController.forward();
    
    final dbUrl = dotenv.env['FIREBASE_DB_URL'] ?? '';
    _dbRootRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    ).ref();
    _focusModeRef = _dbRootRef.child('users/User0/settings/focusMode');
    _focusModeStream = _focusModeRef.onValue;
    _focusModeStream.listen((event) {
      final val = event.snapshot.value;
      if (val is bool) {
        setState(() => _focusModeEnabled = val);
        FocusDetector.setFocusMode(val);
      }
    });
    requestExactAlarmPermission();
    startFocusDetection();
    _checkOverlayPermission();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void startFocusDetection() {
    FocusDetector.startListening((pkg) async {
      setState(() => _currentApp = pkg);
      final now = DateTime.now();
      if (_lastOverlayTrigger != null &&
          now.difference(_lastOverlayTrigger!).inMilliseconds < 500) return;
      if (_focusModeEnabled) {
        bool canOverlay = await FocusDetector.checkOverlayPermission();
        if (!canOverlay) {
          await FocusDetector.requestOverlayPermission();
          await Future.delayed(const Duration(milliseconds: 500));
          canOverlay = await FocusDetector.checkOverlayPermission();
        }
        if (canOverlay && _lastProcessedPackage != pkg) {
          FocusDetector.showOverlayPopup(pkg);
          _lastProcessedPackage = pkg;
          _lastOverlayTrigger = now;
        }
      } else {
        FocusDetector.hideOverlayPopup();
        _lastProcessedPackage = null;
        _lastOverlayTrigger = null;
      }
    });
  }

  Future<void> _checkOverlayPermission() async {
    try {
      bool hasPermission = await FocusDetector.checkOverlayPermission();
      if (!hasPermission) {
        await FocusDetector.requestOverlayPermission();
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (_) {}
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    }
  }

  String _getAppDisplayName(String packageName) {
    // Extract app name from package name for better display
    if (packageName.contains('.')) {
      final parts = packageName.split('.');
      return parts.last.replaceAll('_', ' ').split(' ')
          .map((word) => word.isNotEmpty ? 
              '${word[0].toUpperCase()}${word.substring(1)}' : '')
          .join(' ');
    }
    return packageName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          final angle = _gradientController.value * 2 * pi;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(cos(angle), sin(angle)),
                end: Alignment(-cos(angle), -sin(angle)),
                colors: const [
                  Color(0xFF141431),
                  Color(0xFF1A171A),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.center_focus_strong,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Focus Tracker',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Stay focused, stay productive',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Minimal Status Card (no box)
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Minimal Focus Mode Status (no box)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _focusModeEnabled ? Icons.check_circle : Icons.cancel,
                                        color: _focusModeEnabled ? Color(0xFF6C64E9) : Colors.redAccent,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _focusModeEnabled ? "Focus Mode: ON" : "Focus Mode: OFF",
                                        style: TextStyle(
                                          color: _focusModeEnabled ? Color(0xFF6C64E9) : Colors.redAccent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Current App (no box)
                                  Text(
                                    'Current App',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getAppDisplayName(_currentApp),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Minimal Action Buttons (all gray)
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildMinimalButton(
                                  onPressed: openAccessibilitySettings,
                                  icon: Icons.accessibility,
                                  label: 'Accessibility Service',
                                  color: const Color(0xFF353434),
                                ),
                                _buildMinimalButton(
                                  onPressed: _checkOverlayPermission,
                                  icon: Icons.layers,
                                  label: 'Overlay Permission',
                                  color: const Color(0xFF353434),
                                ),
                                _buildMinimalButton(
                                  onPressed: requestExactAlarmPermission,
                                  icon: Icons.schedule,
                                  label: 'Exact Alarm Permission',
                                  color: const Color(0xFF353434),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color, // ignored for glass style
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Glass background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.13),
                      Colors.white.withOpacity(0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            // Button content
            Positioned.fill(
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, color: Colors.white, size: 20),
                label: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}