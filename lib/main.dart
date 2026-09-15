import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:loob/firebase_options.dart';
import 'package:loob/services/app_controller.dart';
import 'package:loob/services/payment_service.dart';
import 'package:loob/services/storage_service.dart';
import 'package:loob/services/settings_controller.dart';
import 'package:loob/providers/app_provider.dart';
import 'package:loob/screens/profile/main_navigation_screen.dart';
import 'package:loob/screens/auth/auth_screen.dart';
import 'package:loob/screens/auth/splash_screen.dart';
import 'package:loob/theme/app_colors.dart';

void main() {
  // Catch ALL errors including async errors
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('STACK: ${details.stack}');
  };

  runZonedGuarded(
    () async {
      await _initializeApp();
      runApp(const LoobApp());
    },
    (error, stack) {
      debugPrint('UNCAUGHT ERROR: $error');
      debugPrint('STACK: $stack');
      // Show error app instead of black screen
      runApp(ErrorApp(error: error.toString()));
    },
  );
}

Future<void> _initializeApp() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');

    // Initialize Stripe (optional - don't crash if missing)
    const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (stripeKey.isNotEmpty) {
      await PaymentService().initialize(stripeKey);
      debugPrint('✅ Stripe initialized');
    } else {
      debugPrint('⚠️ Stripe key not provided, skipping Stripe init');
    }

    // Initialize services
    Get.put(AppController(), permanent: true);
    Get.put(StorageService(), permanent: true);

    // Settings (theme + notifications) - loaded before runApp so the very
    // first frame already reflects whatever the user picked last session.
    final settings = Get.put(SettingsController(), permanent: true);
    await settings.load();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    debugPrint('✅ App initialization complete');
  } catch (e, stack) {
    debugPrint('❌ Initialization failed: $e');
    debugPrint('STACK: $stack');
    rethrow; // Will be caught by runZonedGuarded
  }
}

/// The single unified Black & Gold theme used everywhere in the app
/// (AppBar, ElevatedButton, TextField/InputDecoration, ColorScheme, etc.)
final ThemeData _loobTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Cairo',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    primary: AppColors.accent,
    secondary: AppColors.accentLight,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.accent,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.accent),
    titleTextStyle: TextStyle(
      color: AppColors.accent,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Cairo',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.black,
      disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
      disabledForegroundColor: Colors.black54,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.accent,
      side: const BorderSide(color: AppColors.accent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.black,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.card,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: AppColors.accent,
    selectionColor: AppColors.accentDark,
    selectionHandleColor: AppColors.accent,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.accent,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.card,
    contentTextStyle: const TextStyle(color: AppColors.textPrimary),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textPrimary),
    bodySmall: TextStyle(color: AppColors.textSecondary),
  ),
  iconTheme: const IconThemeData(color: AppColors.accent),
  dividerColor: AppColors.textMuted,
);

/// Light companion to [_loobTheme], kept in the same Black & Gold family
/// (gold accent, dark text) but on light surfaces - used when the user
/// flips the Settings screen's theme toggle to "light".
///
/// NOTE: [AppColors] is intentionally a set of `static const` values (a
/// single source of truth documented in theme/app_colors.dart), and most
/// screens read straight from it (`AppColors.background`, etc.) rather
/// than from `Theme.of(context)`. That means this ThemeData correctly
/// re-themes every default Material widget (AppBar, buttons, inputs,
/// dialogs, snackbars, ...), but a handful of screens with hardcoded
/// `AppColors.background`/`AppColors.card` reads won't flip automatically
/// until those call sites are migrated to `Theme.of(context).colorScheme`.
/// The persistence/toggle plumbing below is fully wired and ready for
/// that migration.
final ThemeData _loobLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Cairo',
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accentDark,
    brightness: Brightness.light,
    primary: AppColors.accentDark,
    secondary: AppColors.accent,
    surface: Colors.white,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.accentDark,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.accentDark),
    titleTextStyle: TextStyle(
      color: AppColors.accentDark,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Cairo',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentDark,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF0F0F0),
    hintStyle: const TextStyle(color: Colors.black45),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accentDark, width: 1.4),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black54),
  ),
  iconTheme: const IconThemeData(color: AppColors.accentDark),
  dividerColor: Colors.black12,
);

class LoobApp extends StatelessWidget {
  const LoobApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds whenever the Settings screen's dark/light toggle (persisted
    // via SettingsController + SharedPreferences) changes, so the switch
    // takes effect immediately and again on the next cold start.
    return AnimatedBuilder(
      animation: SettingsController.to,
      builder: (context, _) {
        return GetMaterialApp(
          title: 'Loob - منصة المحتوى التسويقي',
          debugShowCheckedModeBanner: false,
          // Wrap every screen with the AppProvider InheritedNotifier so that
          // `AppProvider.of(context)` resolves anywhere in the widget tree.
          builder: (context, child) {
            return AppProvider(
              notifier: Get.find<AppController>(),
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: _loobLightTheme,
          darkTheme: _loobTheme,
          themeMode: SettingsController.to.themeMode,
          locale: const Locale('ar'),
          fallbackLocale: const Locale('ar'),
          home: const AppLoader(),
        );
      },
    );
  }
}

/// Handles loading state and navigation based on auth status
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  String? _error;

  /// Called by [SplashScreen] once its internal 2.5s timer fires. This is
  /// where we decide whether the user goes to the Auth screen or straight
  /// into the app, based on the (by-then-resolved) auth state.
  Future<void> _onSplashComplete() async {
    try {
      final controller = Get.find<AppController>();

      // Pick up an already-signed-in Firebase session before deciding
      // where to send the user - see AppController.restoreSession for why
      // this matters.
      await controller.restoreSession();

      if (!mounted) return;

      if (controller.isAuthenticated) {
        Get.offAll(() => const MainNavigationScreen());
      } else {
        Get.offAll(() => const AuthScreen());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ في تحميل التطبيق',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show the Splash screen (dark background + gold glow behind the LOOB
    // logo). It manages its own 2.5s Timer internally and calls
    // `_onSplashComplete` once it elapses, so the brand screen is always
    // clearly visible before the automatic transition to Auth/Home.
    return SplashScreen(onComplete: _onSplashComplete);
  }
}

/// Error fallback app when initialization fails completely
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'فشل تشغيل التطبيق',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
