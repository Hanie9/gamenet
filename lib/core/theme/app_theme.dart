import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceLight = Color(0xFF21262D);
  static const border = Color(0xFF30363D);
  static const primary = Color(0xFF58A6FF);
  static const primaryDark = Color(0xFF1F6FEB);
  static const accent = Color(0xFF3FB950);
  static const accentOrange = Color(0xFFF78166);
  static const warning = Color(0xFFD29922);
  static const danger = Color(0xFFF85149);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const gaming = Color(0xFF8957E5);
}

class AppTheme {
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.danger,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Segoe UI',
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.primary, size: 26),
        unselectedIconTheme:
            IconThemeData(color: AppColors.textSecondary, size: 24),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        indicatorColor: Color(0x331F6FEB),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
