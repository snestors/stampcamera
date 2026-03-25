// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampcamera/core/theme/app_theme.dart';

/// 🎨 ENUMS PARA MANEJO DE TEMA
enum AppThemeMode { light, dark, system }

/// 📱 ESTADO DEL TEMA
class ThemeState {
  final AppThemeMode mode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const ThemeState({
    required this.mode,
    required this.lightTheme,
    required this.darkTheme,
  });

  ThemeState copyWith({
    AppThemeMode? mode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }

  /// Obtiene el tema actual basado en el brightness del sistema
  ThemeData getCurrentTheme(Brightness systemBrightness) {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.system:
        return systemBrightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }

  /// Obtiene el ThemeMode de Material para MaterialApp
  ThemeMode get materialThemeMode {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// 🔧 NOTIFIER DEL TEMA
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier()
    : super(
        ThemeState(
          mode: AppThemeMode.light,
          lightTheme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
        ),
      ) {
    _loadThemeFromPrefs();
  }

  /// Cargar tema guardado al iniciar la app
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        final themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => AppThemeMode.light,
        );

        state = state.copyWith(mode: themeMode);
        debugPrint('✅ Tema cargado: ${themeMode.name}');
      } else {
        debugPrint('📱 Primer uso - tema light por defecto');
      }
    } catch (e) {
      debugPrint('❌ Error cargando tema: $e');
    }
  }

  /// Cambiar tema y persistir
  Future<void> setTheme(AppThemeMode newMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, newMode.name);

      state = state.copyWith(mode: newMode);
      debugPrint('✅ Tema cambiado a: ${newMode.name}');
    } catch (e) {
      debugPrint('❌ Error guardando tema: $e');
    }
  }

  /// Toggle entre light y dark (ignora system)
  Future<void> toggleTheme() async {
    final newMode = state.mode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    await setTheme(newMode);
  }

  /// Resetear a tema por defecto
  Future<void> resetToDefault() async {
    await setTheme(AppThemeMode.light);
  }
}

/// 🎯 PROVIDER PRINCIPAL DEL TEMA
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// 🎨 PROVIDER PARA OBTENER EL TEMA ACTUAL
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeProvider);
  final brightness = ref.watch(systemBrightnessProvider);

  return themeState.getCurrentTheme(brightness);
});

/// 🌅 PROVIDER PARA EL BRIGHTNESS DEL SISTEMA
final systemBrightnessProvider = Provider<Brightness>((ref) {
  return Brightness.light;
});

/// 📱 PROVIDER PARA VERIFICAR SI ESTÁ EN MODO OSCURO
final isDarkModeProvider = Provider<bool>((ref) {
  final themeState = ref.watch(themeProvider);
  final brightness = ref.watch(systemBrightnessProvider);

  switch (themeState.mode) {
    case AppThemeMode.light:
      return false;
    case AppThemeMode.dark:
      return true;
    case AppThemeMode.system:
      return brightness == Brightness.dark;
  }
});

/// 🎛️ PROVIDER PARA EL MODO MATERIAL APP
final materialThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.materialThemeMode;
});
