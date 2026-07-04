import 'package:flutter/material.dart';

/// TezShare brand colors
/// Electric Blue = speed, trust, technology
/// Amber/Lightning Yellow = energy, fast transfer, "bijli" feel
class AppColors {
  static const Color electricBlue = Color(0xFF1E56E8);
  static const Color darkBlue = Color(0xFF0D1B3E);
  static const Color amber = Color(0xFFFFC107);
  static const Color background = Color(0xFF0B1220);
  static const Color cardBackground = Color(0xFF141C2F);
  static const Color textLight = Color(0xFFF5F7FA);
  static const Color textMuted = Color(0xFF8A93A6);
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
}

ThemeData buildTezShareTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.electricBlue,
      brightness: Brightness.dark,
      primary: AppColors.electricBlue,
      secondary: AppColors.amber,
      surface: AppColors.cardBackground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textLight,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textLight),
      bodyMedium: TextStyle(color: AppColors.textLight),
      bodySmall: TextStyle(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electricBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.amber,
      foregroundColor: AppColors.darkBlue,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
