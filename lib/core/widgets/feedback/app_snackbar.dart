// ============================================================================
// 📢 APP SNACKBAR - COMPONENTE DE NOTIFICACIÓN ESTANDARIZADO
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

/// Tipos de snackbar disponibles
enum AppSnackBarType {
  success,
  error,
  warning,
  info,
}

/// Clase principal de snackbars estandarizados
class AppSnackBar {
  /// Duración por defecto de los snackbars
  static const Duration defaultDuration = Duration(seconds: 3);

  /// Muestra un snackbar de éxito
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackBarType.success,
      icon: Icons.check_circle,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un snackbar de error
  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackBarType.error,
      icon: Icons.error,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un snackbar de advertencia
  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackBarType.warning,
      icon: Icons.warning_amber,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un snackbar informativo
  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      type: AppSnackBarType.info,
      icon: Icons.info,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un snackbar personalizado
  static void custom(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showCustom(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      textColor: textColor,
      duration: duration,
      action: action,
    );
  }

  /// Método interno para mostrar snackbars tipados
  static void _show(
    BuildContext context, {
    required String message,
    required AppSnackBarType type,
    required IconData icon,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final config = _getConfig(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: DesignTokens.iconXL,
              ),
              const SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: config.backgroundColor,
        duration: duration ?? defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spaceL),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        action: action,
      ),
    );
  }

  /// Método interno para mostrar snackbars personalizados
  static void _showCustom(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: DesignTokens.iconXL,
              ),
              const SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spaceL),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        action: action,
      ),
    );
  }

  /// Obtener configuración según tipo
  static _SnackBarConfig _getConfig(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return _SnackBarConfig(
          backgroundColor: AppColors.success,
        );
      case AppSnackBarType.error:
        return _SnackBarConfig(
          backgroundColor: AppColors.error,
        );
      case AppSnackBarType.warning:
        return _SnackBarConfig(
          backgroundColor: AppColors.warning,
        );
      case AppSnackBarType.info:
        return _SnackBarConfig(
          backgroundColor: AppColors.info,
        );
    }
  }

  /// Ocultar el snackbar actual
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Limpiar todos los snackbars
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

/// Configuración interna del snackbar
class _SnackBarConfig {
  final Color backgroundColor;

  const _SnackBarConfig({
    required this.backgroundColor,
  });
}
