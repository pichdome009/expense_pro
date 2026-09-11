import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'screens/lock_screen.dart';
import 'screens/main_controller_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/security_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ModernExpenseApp());
  // Non-blocking notification initialization in background
  NotificationService.init().catchError((e) {
    debugPrint('Notification init error: $e');
  });
}

class ModernExpenseApp extends StatefulWidget {
  const ModernExpenseApp({super.key});

  @override
  State<ModernExpenseApp> createState() => _ModernExpenseAppState();
}

class _ModernExpenseAppState extends State<ModernExpenseApp>
    with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLocked = false;
  bool _isInitialized = false;
  bool _showSplash = true;

  // Cache text themes once to prevent re-computing on every frame/rebuild
  static final _lightTextTheme = GoogleFonts.kantumruyProTextTheme();
  static final _darkTextTheme = _lightTextTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  Future<void> _checkInitialLock() async {
    final locked = await SecurityService.isAppLockEnabled();
    if (mounted) {
      setState(() {
        _isLocked = locked;
        _isInitialized = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      SecurityService.isAppLockEnabled().then((enabled) {
        if (enabled && mounted) {
          setState(() => _isLocked = true);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _toggleTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Pro',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
        cardColor: Colors.white,
        useMaterial3: true,
        textTheme: _lightTextTheme,
        splashFactory: InkRipple.splashFactory,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: const Color(0xFF34D399),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,
        cardColor: AppColors.cardDark,
        useMaterial3: true,
        textTheme: _darkTextTheme,
      ),
      home: _showSplash
          ? SplashScreen(
              onFinish: () {
                setState(() => _showSplash = false);
              },
            )
          : !_isInitialized
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _isLocked
                  ? LockScreen(
                      onUnlocked: () => setState(() => _isLocked = false),
                    )
                  : MainControllerScreen(
                      onToggleTheme: _toggleTheme,
                      isDark: _themeMode == ThemeMode.dark,
                    ),
    );
  }
}