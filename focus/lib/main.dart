import 'dart:io';
import 'dart:ui';
import 'dart:math'; // Needed for cos() and sin()

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'focus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();
  runApp(const SynapseApp());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedCode();
  }

  Future<void> _checkSavedCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('user_code');

    if (savedCode != null) {
      // Verify the code is still valid
      try {
        final dbUrl = dotenv.env['FIREBASE_DB_URL'] ?? '';
        final dbRef =
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: dbUrl,
            ).ref();
        final snapshot = await dbRef.child('users/$savedCode').get();

        if (snapshot.exists) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomePage(code: savedCode)),
          );
          return;
        }
      } catch (e) {
        // If verification fails, clear the saved code
        await prefs.remove('user_code');
      }
    }

    // If no valid saved code, go to code entry
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const CodeEntryPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141431), Color(0xFF1A171A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C64E9)),
        ),
      ),
    );
  }
}

class SynapseApp extends StatelessWidget {
  const SynapseApp({super.key});
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
      home: const SplashScreen(),
    );
  }
}

class CodeEntryPage extends StatefulWidget {
  const CodeEntryPage({super.key});

  @override
  State<CodeEntryPage> createState() => _CodeEntryPageState();
}

class _CodeEntryPageState extends State<CodeEntryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _checkCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final code = _controller.text.trim();
    try {
      final dbUrl = dotenv.env['FIREBASE_DB_URL'] ?? '';
      final dbRef =
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: dbUrl,
          ).ref();
      final snapshot = await dbRef.child('users/$code').get();
      if (snapshot.exists) {
        // Save the code to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_code', code);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(code: code)),
        );
      } else {
        setState(() => _error = 'Invalid code');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A171A),
              Color(0xFF1A171A),
              Color(0xFF201E40),
            ],
            stops: [0, 0.75, 1],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Synapse SVG Logo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: SizedBox(
                      width: 140,
                      height: 32,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: _SynapseLogoSvg(),
                      ),
                    ),
                  ),
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: const Color(0xFF494852),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 20,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        SizedBox(
                          width: 220,
                          child: Text(
                            'Enter your unique ID here',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.41),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Input box
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF767676),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: TextField(
                            controller: _controller,
                            enabled: !_loading,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w300,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your code here',
                              hintStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w300,
                              ),
                              errorText: _error,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _checkCode(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _checkCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C64E9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
}

// SVG logo widget
class _SynapseLogoSvg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 325,
      height: 75,
      child: Image.asset(
        'assets/synapse_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to SVG if asset not found
          return const _SynapseLogoSvgRaw();
        },
      ),
    );
  }
}

// Inline SVG fallback (raw)
class _SynapseLogoSvgRaw extends StatelessWidget {
  const _SynapseLogoSvgRaw();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 325,
      height: 75,
      child: Center(
        child: Text(
          'Synapse',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String code;

  const HomePage({super.key, required this.code});
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
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    _slideController.forward();

    final dbUrl = dotenv.env['FIREBASE_DB_URL'] ?? '';
    _dbRootRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    ).ref();
    _focusModeRef = _dbRootRef.child('users/${widget.code}/settings/focusMode');
    _focusModeStream = _focusModeRef.onValue;
    _focusModeStream.listen((event) {
      final val = event.snapshot.value;
      if (val is bool) {
        setState(() => _focusModeEnabled = val);
        FocusDetector.setFocusMode(val);
      }
    });
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

  Future<void> _reEnterCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_code');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CodeEntryPage()),
        (route) => false,
      );
    }
  }

  String _getAppDisplayName(String packageName) {
    if (packageName.contains('.')) {
      final parts = packageName.split('.');
      return parts.last
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
          .join(' ');
    }
    return packageName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A171A),
              Color(0xFF1A171A),
              Color(0xFF201E40),
            ],
            stops: [0, 0.75, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo at the top
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0, bottom: 0),
                      child: SizedBox(
                        width: 140,
                        height: 32,
                        child: _SynapseLogoSvg(),
                      ),
                    ),
                    // Middle content
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.29),
                                    offset: Offset(0, 2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              children: [
                                const TextSpan(text: 'Focus Mode : '),
                                TextSpan(
                                  text: _focusModeEnabled ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    color: _focusModeEnabled
                                        ? Color(0xFF769AFF)
                                        : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              const Text(
                                'Current App',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.41),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _getAppDisplayName(_currentApp),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.41),
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Buttons at the bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0, top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDashboardButton(
                            label: 'Re-Enter Code',
                            color: const Color(0xFF6C64E9),
                            onTap: _reEnterCode,
                          ),
                          const SizedBox(height: 24),
                          _buildDashboardButton(
                            label: 'Accessibility',
                            color: const Color(0xFF767676),
                            onTap: openAccessibilitySettings,
                          ),
                          const SizedBox(height: 24),
                          _buildDashboardButton(
                            label: 'Overlay Settings',
                            color: const Color(0xFF767676),
                            onTap: _checkOverlayPermission,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 300, // Increased width for a more balanced look
          height: 48,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
