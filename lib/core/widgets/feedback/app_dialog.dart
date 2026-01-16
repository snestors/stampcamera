// ============================================================================
// 💬 APP DIALOG - COMPONENTE DE DIÁLOGO ESTANDARIZADO
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

/// Tipos de diálogo disponibles
enum AppDialogType {
  info,
  success,
  warning,
  error,
  confirm,
}

/// Clase principal de diálogos estandarizados
class AppDialog {
  /// Muestra un diálogo de confirmación (Sí/No)
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
    bool isDanger = false,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AppDialogWidget(
        type: AppDialogType.confirm,
        title: title,
        message: message,
        icon: icon ?? Icons.help_outline,
        iconColor: iconColor ?? (isDanger ? AppColors.error : AppColors.primary),
        actions: [
          _DialogButton(
            text: cancelText ?? 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
            isOutlined: true,
          ),
          _DialogButton(
            text: confirmText ?? 'Confirmar',
            onPressed: () => Navigator.of(context).pop(true),
            color: isDanger ? AppColors.error : AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de éxito
  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AppDialogWidget(
        type: AppDialogType.success,
        title: title,
        message: message,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        actions: [
          _DialogButton(
            text: buttonText ?? 'Aceptar',
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de error
  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AppDialogWidget(
        type: AppDialogType.error,
        title: title,
        message: message,
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        actions: [
          _DialogButton(
            text: buttonText ?? 'Aceptar',
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de advertencia
  static Future<void> warning(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AppDialogWidget(
        type: AppDialogType.warning,
        title: title,
        message: message,
        icon: Icons.warning_amber_outlined,
        iconColor: AppColors.warning,
        actions: [
          _DialogButton(
            text: buttonText ?? 'Entendido',
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo informativo
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AppDialogWidget(
        type: AppDialogType.info,
        title: title,
        message: message,
        icon: Icons.info_outline,
        iconColor: AppColors.info,
        actions: [
          _DialogButton(
            text: buttonText ?? 'Aceptar',
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo personalizado con widget como contenido
  static Future<T?> custom<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? icon,
    Color? iconColor,
    bool barrierDismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _AppDialogWidget(
        type: AppDialogType.info,
        title: title,
        customContent: content,
        icon: icon,
        iconColor: iconColor,
        customActions: actions,
      ),
    );
  }

  /// Muestra un diálogo de loading
  static Future<void> loading(
    BuildContext context, {
    String? message,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                if (message != null) ...[
                  const SizedBox(height: DesignTokens.spaceL),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cierra el diálogo de loading
  static void closeLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Widget interno del diálogo
class _AppDialogWidget extends StatelessWidget {
  final AppDialogType type;
  final String title;
  final String? message;
  final Widget? customContent;
  final IconData? icon;
  final Color? iconColor;
  final List<_DialogButton>? actions;
  final List<Widget>? customActions;

  const _AppDialogWidget({
    required this.type,
    required this.title,
    this.message,
    this.customContent,
    this.icon,
    this.iconColor,
    this.actions,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con icono
            if (icon != null)
              Container(
                padding: const EdgeInsets.only(top: DesignTokens.spaceXXL),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: iconColor ?? AppColors.primary,
                  ),
                ),
              ),

            // Título
            Padding(
              padding: EdgeInsets.only(
                top: icon != null ? DesignTokens.spaceL : DesignTokens.spaceXXL,
                left: DesignTokens.spaceXXL,
                right: DesignTokens.spaceXXL,
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Mensaje o contenido personalizado
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: DesignTokens.spaceS,
                  left: DesignTokens.spaceXXL,
                  right: DesignTokens.spaceXXL,
                ),
                child: Text(
                  message!,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (customContent != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: DesignTokens.spaceL,
                  left: DesignTokens.spaceL,
                  right: DesignTokens.spaceL,
                ),
                child: customContent!,
              ),

            // Acciones
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: customActions ??
                  (actions ?? [])
                      .map((action) => Expanded(child: action))
                      .toList()
                      .expand((widget) => [widget, const SizedBox(width: DesignTokens.spaceS)])
                      .toList()
                    ..removeLast(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón interno del diálogo
class _DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool isOutlined;

  const _DialogButton({
    required this.text,
    required this.onPressed,
    this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceL,
            vertical: DesignTokens.spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceL,
          vertical: DesignTokens.spaceM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    );
  }
}
