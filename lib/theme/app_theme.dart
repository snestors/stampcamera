// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================================
  // 🎨 COLORES EXACTOS A&G
  // ============================================================================

  /// Azul Marino - Color base
  static const Color primaryNavy = Color(0xFF003B5C);

  /// Turquesa - Color secundario
  static const Color primaryTurquoise = Color(0xFF00B4D8);

  // ============================================================================
  // 🌅 TEMA LIGHT
  // ============================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: primaryTurquoise,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryTurquoise),
        ),
      ),
    );
  }

  // ============================================================================
  // 🌚 TEMA DARK - COLORES INVERTIDOS
  // ============================================================================

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTurquoise,
        primary: primaryTurquoise, // Invertir
        secondary: primaryNavy, // Invertir
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.white, // MISMO que light
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryTurquoise, // Invertir
        foregroundColor: primaryNavy, // Invertir
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTurquoise, // Invertir
          foregroundColor: primaryNavy, // Invertir
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryNavy), // Invertir
        ),
      ),
    );
  }
}
