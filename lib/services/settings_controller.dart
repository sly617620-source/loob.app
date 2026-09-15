import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists app-level preferences (theme mode, notifications) across
/// restarts and exposes them as a [ChangeNotifier] so any widget
/// (`AnimatedBuilder`, `ListenableBuilder`, `context.watch`, ...) can
/// react to changes immediately.
///
/// Call [SettingsController.load] once at startup (e.g. alongside
/// `SessionManager.restore`) before it's used to build `MaterialApp.theme`.
///
/// ```dart
/// final settings = SettingsController();
/// await settings.load();
///
/// // in MaterialApp:
/// AnimatedBuilder(
///   animation: settings,
///   builder: (context, _) => MaterialApp(
///     themeMode: settings.themeMode,
///     theme: lightTheme,
///     darkTheme: darkTheme,
///     home: ...,
///   ),
/// )
/// ```
class SettingsController extends ChangeNotifier {
  /// Convenience static accessor (`SettingsController.to`), mirroring how
  /// `AppController.to` is used elsewhere - registered once via
  /// `Get.put(SettingsController(), permanent: true)` in main.dart.
  static SettingsController get to => Get.find<SettingsController>();

  static const _kThemeMode = 'settings_theme_mode'; // 'light' | 'dark' | 'system'
  static const _kNotificationsEnabled = 'settings_notifications_enabled';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<SharedPreferences> get _prefsInstance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final prefs = await _prefsInstance;

    final storedMode = prefs.getString(_kThemeMode);
    _themeMode = switch (storedMode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // default matches the app's black/gold identity
    };

    _notificationsEnabled = prefs.getBool(_kNotificationsEnabled) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await _prefsInstance;
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> toggleTheme() =>
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await _prefsInstance;
    await prefs.setBool(_kNotificationsEnabled, enabled);
  }
}
