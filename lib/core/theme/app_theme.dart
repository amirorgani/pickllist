import 'package:flutter/material.dart';

/// Theme for the app. Uses Material 3 with a green seed evoking produce.
class AppTheme {
  /// Light color scheme used by default.
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Dark color scheme used when the platform requests dark mode.
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
