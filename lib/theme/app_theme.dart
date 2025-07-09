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

class VehicleHelpers {
  // Colores para condiciones
  static Color getCondicionColor(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return const Color(0xFF00B4D8);
      case 'RECEPCION':
        return const Color(0xFF8B5CF6);
      case 'ALMACEN':
        return const Color(0xFF059669);
      case 'PDI':
        return const Color(0xFFF59E0B);
      case 'PRE-PDI':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // Íconos para condiciones
  static IconData getCondicionIcon(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return Icons.anchor;
      case 'RECEPCION':
        return Icons.login;
      case 'ALMACEN':
        return Icons.warehouse;
      case 'PDI':
        return Icons.build_circle;
      case 'PRE-PDI':
        return Icons.search;
      default:
        return Icons.location_on;
    }
  }
}
