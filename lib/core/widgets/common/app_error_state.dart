// ============================================================================
// ❌ ESTADOS DE ERROR CENTRALIZADOS
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../buttons/app_button.dart';

enum AppErrorType {
  network,
  server,
  notFound,
  unauthorized,
  forbidden,
  timeout,
  unknown,
  validation,
  empty,
  maintenance,
}

class AppErrorState extends StatelessWidget {
  final AppErrorType type;
  final String? title;
  final String? message;
  final String? details;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onRetry;
  final String? retryText;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final bool showDetails;
  final bool compact;
  final EdgeInsets? padding;
  final double? iconSize;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final TextStyle? detailsStyle;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Widget? customAction;
  final List<Widget>? actions;
  final bool showIcon;
  final String? semanticsLabel;

  const AppErrorState({
    super.key,
    this.type = AppErrorType.unknown,
    this.title,
    this.message,
    this.details,
    this.icon,
    this.iconColor,
    this.onRetry,
    this.retryText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.showDetails = false,
    this.compact = false,
    this.padding,
    this.iconSize,
    this.titleStyle,
    this.messageStyle,
    this.detailsStyle,
    this.backgroundColor,
    this.borderRadius,
    this.customAction,
    this.actions,
    this.showIcon = true,
    this.semanticsLabel,
  });

  // Factory constructors para tipos específicos
  factory AppErrorState.network({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryText,
    bool compact = false,
    String? semanticsLabel,
  }) {
    return AppErrorState(
      type: AppErrorType.network,
      title: title,
      message: message ?? 'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      onRetry: onRetry,
      retryText: retryText,
      compact: compact,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppErrorState.server({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryText,
    bool compact = false,
    String? semanticsLabel,
  }) {
    return AppErrorState(
      type: AppErrorType.server,
      title: title,
      message: message ?? 'Error del servidor. Intenta nuevamente en unos minutos.',
      onRetry: onRetry,
      retryText: retryText,
      compact: compact,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppErrorState.notFound({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryText,
    bool compact = false,
    String? semanticsLabel,
  }) {
    return AppErrorState(
      type: AppErrorType.notFound,
      title: title,
      message: message ?? 'No se encontró la información solicitada.',
      onRetry: onRetry,
      retryText: retryText,
      compact: compact,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppErrorState.unauthorized({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryText,
    bool compact = false,
    String? semanticsLabel,
  }) {
    return AppErrorState(
      type: AppErrorType.unauthorized,
      title: title,
      message: message ?? 'Tu sesión ha expirado. Inicia sesión nuevamente.',
      onRetry: onRetry,
      retryText: retryText ?? 'Iniciar Sesión',
      compact: compact,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppErrorState.timeout({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryText,
    bool compact = false,
    String? semanticsLabel,
  }) {
    return AppErrorState(
      type: AppErrorType.timeout,
      title: title,
      message: message ?? 'La operación tardó demasiado tiempo. Intenta nuevamente.',
      onRetry: onRetry,
      retryText: retryText,
      compact: compact,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppErrorState.validation({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryText,
    bool compact = false,
    String? semanticsLabel,
  }) {
    return AppErrorState(
      type: AppErrorType.validation,
      title: title,
      message: message ?? 'Hay errores en los datos ingresados. Verifica e intenta nuevamente.',
      onRetry: onRetry,
      retryText: retryText,
      compact: compact,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppErrorState.empty({
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryText,
    bool compact = false,
    String? semanticsLabel,
  }) {
    return AppErrorState(
      type: AppErrorType.empty,
      title: title,
      message: message ?? 'No hay datos para mostrar.',
      onRetry: onRetry,
      retryText: retryText,
      compact: compact,
      semanticsLabel: semanticsLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorConfig = _getErrorConfig();
    final spacing = compact ? DesignTokens.spaceM : DesignTokens.spaceL;
    final effectivePadding = padding ?? (compact 
        ? const EdgeInsets.all(DesignTokens.spaceL) 
        : const EdgeInsets.all(DesignTokens.spaceXXL));

    Widget errorWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showIcon) ...[
          _buildIcon(errorConfig),
          SizedBox(height: spacing),
        ],
        if (title != null || errorConfig.title != null) ...[
          _buildTitle(errorConfig),
          SizedBox(height: compact ? DesignTokens.spaceS : DesignTokens.spaceM),
        ],
        if (message != null || errorConfig.message != null) ...[
          _buildMessage(errorConfig),
          if (showDetails && details != null) ...[
            SizedBox(height: DesignTokens.spaceS),
            _buildDetails(),
          ],
          SizedBox(height: spacing),
        ],
        if (customAction != null) ...[
          customAction!,
        ] else if (actions != null) ...[
          _buildActions(),
        ] else ...[
          _buildDefaultActions(errorConfig),
        ],
      ],
    );

    if (backgroundColor != null) {
      errorWidget = Container(
        padding: effectivePadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
        ),
        child: errorWidget,
      );
    } else {
      errorWidget = Padding(
        padding: effectivePadding,
        child: errorWidget,
      );
    }

    if (semanticsLabel != null) {
      errorWidget = Semantics(
        label: semanticsLabel!,
        child: errorWidget,
      );
    }

    return errorWidget;
  }

  Widget _buildIcon(_ErrorConfig config) {
    return Icon(
      icon ?? config.icon,
      size: iconSize ?? (compact ? DesignTokens.iconXXL : DesignTokens.iconHuge),
      color: iconColor ?? config.color,
    );
  }

  Widget _buildTitle(_ErrorConfig config) {
    return Text(
      title ?? config.title!,
      style: titleStyle ?? TextStyle(
        fontSize: compact ? DesignTokens.fontSizeL : DesignTokens.fontSizeXL,
        fontWeight: DesignTokens.fontWeightBold,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(_ErrorConfig config) {
    return Text(
      message ?? config.message!,
      style: messageStyle ?? TextStyle(
        fontSize: compact ? DesignTokens.fontSizeS : DesignTokens.fontSizeRegular,
        color: AppColors.textSecondary,
        height: DesignTokens.lineHeightRelaxed,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDetails() {
    return ExpansionTile(
      title: Text(
        'Ver detalles',
        style: TextStyle(
          fontSize: DesignTokens.fontSizeS,
          color: AppColors.textSecondary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceM),
          child: Text(
            details!,
            style: detailsStyle ?? TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (actions!.length == 1) {
      return actions!.first;
    }

    return Wrap(
      spacing: DesignTokens.spaceM,
      runSpacing: DesignTokens.spaceS,
      alignment: WrapAlignment.center,
      children: actions!,
    );
  }

  Widget _buildDefaultActions(_ErrorConfig config) {
    final List<Widget> actionWidgets = [];

    if (onRetry != null) {
      actionWidgets.add(
        AppButton.primary(
          text: retryText ?? config.retryText,
          onPressed: onRetry,
          size: compact ? AppButtonSize.small : AppButtonSize.medium,
          icon: config.retryIcon,
        ),
      );
    }

    if (onSecondaryAction != null) {
      actionWidgets.add(
        AppButton.secondary(
          text: secondaryActionText ?? 'Cancelar',
          onPressed: onSecondaryAction,
          size: compact ? AppButtonSize.small : AppButtonSize.medium,
        ),
      );
    }

    if (actionWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    if (actionWidgets.length == 1) {
      return actionWidgets.first;
    }

    return Wrap(
      spacing: DesignTokens.spaceM,
      runSpacing: DesignTokens.spaceS,
      alignment: WrapAlignment.center,
      children: actionWidgets,
    );
  }

  _ErrorConfig _getErrorConfig() {
    switch (type) {
      case AppErrorType.network:
        return _ErrorConfig(
          icon: Icons.wifi_off,
          color: AppColors.error,
          title: 'Sin conexión',
          message: 'Verifica tu conexión a internet e intenta nuevamente.',
          retryText: 'Reintentar',
          retryIcon: Icons.refresh,
        );
      case AppErrorType.server:
        return _ErrorConfig(
          icon: Icons.cloud_off,
          color: AppColors.error,
          title: 'Error del servidor',
          message: 'Estamos experimentando problemas técnicos. Intenta más tarde.',
          retryText: 'Reintentar',
          retryIcon: Icons.refresh,
        );
      case AppErrorType.notFound:
        return _ErrorConfig(
          icon: Icons.search_off,
          color: AppColors.warning,
          title: 'No encontrado',
          message: 'La información que buscas no está disponible.',
          retryText: 'Buscar nuevamente',
          retryIcon: Icons.search,
        );
      case AppErrorType.unauthorized:
        return _ErrorConfig(
          icon: Icons.lock_outline,
          color: AppColors.warning,
          title: 'Sesión expirada',
          message: 'Tu sesión ha caducado. Inicia sesión para continuar.',
          retryText: 'Iniciar sesión',
          retryIcon: Icons.login,
        );
      case AppErrorType.forbidden:
        return _ErrorConfig(
          icon: Icons.block,
          color: AppColors.error,
          title: 'Acceso denegado',
          message: 'No tienes permisos para acceder a esta información.',
          retryText: 'Contactar soporte',
          retryIcon: Icons.support_agent,
        );
      case AppErrorType.timeout:
        return _ErrorConfig(
          icon: Icons.timer_off,
          color: AppColors.warning,
          title: 'Tiempo agotado',
          message: 'La operación tardó demasiado tiempo en completarse.',
          retryText: 'Reintentar',
          retryIcon: Icons.refresh,
        );
      case AppErrorType.validation:
        return _ErrorConfig(
          icon: Icons.error_outline,
          color: AppColors.warning,
          title: 'Datos inválidos',
          message: 'Hay errores en la información ingresada.',
          retryText: 'Corregir',
          retryIcon: Icons.edit,
        );
      case AppErrorType.empty:
        return _ErrorConfig(
          icon: Icons.inbox_outlined,
          color: AppColors.textSecondary,
          title: 'Sin datos',
          message: 'No hay información para mostrar en este momento.',
          retryText: 'Actualizar',
          retryIcon: Icons.refresh,
        );
      case AppErrorType.maintenance:
        return _ErrorConfig(
          icon: Icons.construction,
          color: AppColors.warning,
          title: 'Mantenimiento',
          message: 'El sistema está en mantenimiento. Intenta más tarde.',
          retryText: 'Reintentar',
          retryIcon: Icons.refresh,
        );
      case AppErrorType.unknown:
      default:
        return _ErrorConfig(
          icon: Icons.error_outline,
          color: AppColors.error,
          title: 'Error inesperado',
          message: 'Ocurrió un error inesperado. Intenta nuevamente.',
          retryText: 'Reintentar',
          retryIcon: Icons.refresh,
        );
    }
  }
}

class _ErrorConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String retryText;
  final IconData retryIcon;

  _ErrorConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.retryText,
    required this.retryIcon,
  });
}

// ============================================================================
// WIDGET PARA ERRORES INLINE
// ============================================================================

class AppInlineError extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final bool dismissible;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const AppInlineError({
    super.key,
    required this.message,
    this.icon,
    this.color,
    this.onDismiss,
    this.showIcon = true,
    this.dismissible = false,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.error;
    final effectiveBackgroundColor = backgroundColor ?? effectiveColor.withValues(alpha: 0.1);

    return Container(
      padding: padding ?? const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.3),
          width: DesignTokens.borderWidthThin,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              icon ?? Icons.error_outline,
              size: DesignTokens.iconM,
              color: effectiveColor,
            ),
            SizedBox(width: DesignTokens.spaceS),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: effectiveColor,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
          if (dismissible && onDismiss != null) ...[
            SizedBox(width: DesignTokens.spaceS),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: DesignTokens.iconS,
                color: effectiveColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET PARA ERRORES DE FORMULARIO
// ============================================================================

class AppFormError extends StatelessWidget {
  final String message;
  final bool show;
  final Duration animationDuration;
  final EdgeInsets? padding;

  const AppFormError({
    super.key,
    required this.message,
    this.show = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animationDuration,
      height: show ? null : 0,
      child: show ? Padding(
        padding: padding ?? const EdgeInsets.only(top: DesignTokens.spaceXS),
        child: Text(
          message,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.error,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ) : null,
    );
  }
}

// ============================================================================
// MIXIN PARA MANEJO DE ERRORES
// ============================================================================

mixin ErrorHandlerMixin {
  AppErrorType getErrorTypeFromException(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') || 
        errorString.contains('socket')) {
      return AppErrorType.network;
    }
    
    if (errorString.contains('timeout')) {
      return AppErrorType.timeout;
    }
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return AppErrorType.unauthorized;
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return AppErrorType.forbidden;
    }
    
    if (errorString.contains('404') || errorString.contains('not found')) {
      return AppErrorType.notFound;
    }
    
    if (errorString.contains('500') || errorString.contains('server')) {
      return AppErrorType.server;
    }
    
    return AppErrorType.unknown;
  }
  
  String getErrorMessage(dynamic error) {
    final errorType = getErrorTypeFromException(error);
    
    switch (errorType) {
      case AppErrorType.network:
        return 'Problema de conexión. Verifica tu internet.';
      case AppErrorType.timeout:
        return 'La operación tardó demasiado tiempo.';
      case AppErrorType.unauthorized:
        return 'Tu sesión ha expirado.';
      case AppErrorType.forbidden:
        return 'No tienes permisos para esta acción.';
      case AppErrorType.notFound:
        return 'La información solicitada no existe.';
      case AppErrorType.server:
        return 'Error del servidor. Intenta más tarde.';
      default:
        return 'Error inesperado. Intenta nuevamente.';
    }
  }
}