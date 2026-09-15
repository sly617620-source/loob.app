import 'package:flutter/material.dart';

/// Unified Black & Gold theme for the whole app.
/// Every screen (including the Auth flow) must pull its colors from here
/// so there is a single source of truth and no stray/off-brand colors
/// (e.g. the old teal accent) leak into the UI.
class AppColors {
  // Core - Black & Gold
  static const Color primary = Color(0xFFFFD700); // Gold
  static const Color secondary = Color(0xFFFFD700); // Gold (alias of primary)
  static const Color background = Color(0xFF121212); // App background (black)
  static const Color surface = Color(0xFF1E1E1E); // Slightly lighter black
  static const Color error = Color(0xFFCF6679);

  // Added to match usages across the app
  static const Color accent = Color(0xFFFFD700); // Gold accent
  static const Color accentLight = Color(0xFFFFE768); // Lighter gold
  static const Color accentDark = Color(0xFFC9A600); // Darker gold

  static const Color card = Color(0xFF1A1A1A); // Card / field background

  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF8A8A8A);

  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFFFFD700); // was cyan/teal - now gold
}

extension AppColorExtensions on Color {
  /// Returns a color with the same RGB channels and the given opacity (0.0 - 1.0).
  /// This avoids using the deprecated withOpacity API.
  Color withValues(double alpha) {
    final int clampedA = (alpha.clamp(0.0, 1.0) * 255).round();

    // Extract ARGB components using toARGB32() (avoids deprecated .value)
    final int argb32 = toARGB32();
    final int rr = (argb32 >> 16) & 0xFF;
    final int gg = (argb32 >> 8) & 0xFF;
    final int bb = argb32 & 0xFF;

    return Color.fromARGB(clampedA, rr, gg, bb);
  }

  /// Convert color to hex (#AARRGGBB)
  String toHex() {
    final int argb32 = toARGB32();
    return '#${argb32.toRadixString(16).padLeft(8, '0')}';
  }

  /// Create color from hex (#RRGGBB or #AARRGGBB)
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    final cleaned = hexString.replaceFirst('#', '');
    if (cleaned.length == 6) {
      buffer.write('ff');
    }
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
