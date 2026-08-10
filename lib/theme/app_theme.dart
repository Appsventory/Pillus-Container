import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna adaptif. JANGAN pakai di dalam `const` expression —
/// getter bergantung pada [brightness] yang berubah saat tema diganti.
class AppColors {
  static Brightness brightness = Brightness.dark;

  static bool get isDark => brightness == Brightness.dark;

  /// Sinkronkan dari mode settings + brightness platform.
  static void sync(String themeMode, Brightness platform) {
    switch (themeMode) {
      case 'light':
        brightness = Brightness.light;
      case 'dark':
        brightness = Brightness.dark;
      default:
        brightness = platform;
    }
  }

  static Color get bgDark =>
      isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7);

  static Color get surfaceDark =>
      isDark ? const Color(0xFF171A21) : const Color(0xFFFFFFFF);

  static Color get surfaceDarkAlt =>
      isDark ? const Color(0xFF1E2229) : const Color(0xFFF0F1F4);

  static Color get border =>
      isDark ? const Color(0xFF2A2E37) : const Color(0xFFE2E4E9);

  static const accent = Color(0xFF4C8DFF);
  static const success = Color(0xFF3DD68C);
  static const warning = Color(0xFFF5B84C);
  static const danger = Color(0xFFEF5A5A);

  static Color get textPrimary =>
      isDark ? const Color(0xFFE7E9EE) : const Color(0xFF1A1D24);

  static Color get textSecondary =>
      isDark ? const Color(0xFF8A8F9C) : const Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xFF171A21),
        primary: AppColors.accent,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFE7E9EE),
        displayColor: const Color(0xFFE7E9EE),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF171A21),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: Color(0xFF2A2E37), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1115),
        elevation: 0,
        centerTitle: false,
        foregroundColor: Color(0xFFE7E9EE),
      ),
      dividerColor: const Color(0xFF2A2E37),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF171A21),
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F5F7),
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        surface: Colors.white,
        primary: AppColors.accent,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1A1D24),
        displayColor: const Color(0xFF1A1D24),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: Color(0xFFE2E4E9), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F5F7),
        elevation: 0,
        centerTitle: false,
        foregroundColor: Color(0xFF1A1D24),
      ),
      dividerColor: const Color(0xFFE2E4E9),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
      ),
    );
  }
}
