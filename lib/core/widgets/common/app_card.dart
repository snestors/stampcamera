// ============================================================================
// 🃏 TARJETA ESTÁNDAR CENTRALIZADA
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

enum AppCardType { basic, elevated, outlined, filled }

enum AppCardSize { small, medium, large }

class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardType type;
  final AppCardSize size;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? elevation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isDisabled;
  final Color? selectedColor;
  final Color? disabledColor;
  final Widget? header;
  final Widget? footer;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisAlignment? mainAxisAlignment;
  final double? width;
  final double? height;
  final String? tooltip;
  final String? semanticsLabel;

  const AppCard({
    super.key,
    required this.child,
    this.type = AppCardType.elevated,
    this.size = AppCardSize.medium,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.elevation,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isDisabled = false,
    this.selectedColor,
    this.disabledColor,
    this.header,
    this.footer,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.crossAxisAlignment,
    this.mainAxisAlignment,
    this.width,
    this.height,
    this.tooltip,
    this.semanticsLabel,
  });

  // Factory constructors para tipos específicos
  factory AppCard.basic({
    Key? key,
    required Widget child,
    AppCardSize size = AppCardSize.medium,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppCard(
      key: key,
      child: child,
      type: AppCardType.basic,
      size: size,
      padding: padding,
      margin: margin,
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
    );
  }

  factory AppCard.elevated({
    Key? key,
    required Widget child,
    AppCardSize size = AppCardSize.medium,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? elevation,
    VoidCallback? onTap,
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppCard(
      key: key,
      child: child,
      type: AppCardType.elevated,
      size: size,
      padding: padding,
      margin: margin,
      elevation: elevation,
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
    );
  }

  factory AppCard.outlined({
    Key? key,
    required Widget child,
    AppCardSize size = AppCardSize.medium,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? borderColor,
    double? borderWidth,
    VoidCallback? onTap,
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppCard(
      key: key,
      child: child,
      type: AppCardType.outlined,
      size: size,
      padding: padding,
      margin: margin,
      borderColor: borderColor,
      borderWidth: borderWidth,
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
    );
  }

  factory AppCard.filled({
    Key? key,
    required Widget child,
    AppCardSize size = AppCardSize.medium,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    VoidCallback? onTap,
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppCard(
      key: key,
      child: child,
      type: AppCardType.filled,
      size: size,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final dimensions = _getDimensions();
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(dimensions.borderRadius);
    final effectivePadding = padding ?? dimensions.padding;
    final effectiveMargin = margin ?? dimensions.margin;

    final isInteractive = onTap != null || onLongPress != null;
    final effectiveOnTap = isDisabled ? null : onTap;
    final effectiveOnLongPress = isDisabled ? null : onLongPress;

    Widget card = Container(
      width: width,
      height: height,
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: effectiveBorderRadius,
        border: colors.borderColor != null
            ? Border.all(
                color: colors.borderColor!,
                width: borderWidth ?? DesignTokens.borderWidthNormal,
              )
            : null,
        boxShadow: boxShadow ?? colors.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: isInteractive
            ? InkWell(
                onTap: effectiveOnTap,
                onLongPress: effectiveOnLongPress,
                borderRadius: effectiveBorderRadius,
                splashColor: AppColors.primary.withValues(
                  alpha: DesignTokens.opacityPressed,
                ),
                highlightColor: AppColors.primary.withValues(
                  alpha: DesignTokens.opacityFocused,
                ),
                child: _buildContent(effectivePadding),
              )
            : _buildContent(effectivePadding),
      ),
    );

    if (tooltip != null) {
      card = Tooltip(message: tooltip!, child: card);
    }

    if (semanticsLabel != null) {
      card = Semantics(
        label: semanticsLabel!,
        button: isInteractive,
        enabled: !isDisabled,
        child: card,
      );
    }

    return card;
  }

  Widget _buildContent(EdgeInsets effectivePadding) {
    final List<Widget> children = [];

    // Header si existe
    if (header != null) {
      children.add(header!);
    }

    // Título y subtítulo si existen
    if (title != null ||
        subtitle != null ||
        leading != null ||
        trailing != null) {
      children.add(_buildTitleSection());
    }

    // Separador si hay header o título
    if (children.isNotEmpty) {
      children.add(SizedBox(height: DesignTokens.spaceS));
    }

    // Contenido principal
    children.add(child);

    // Footer si existe
    if (footer != null) {
      children.add(SizedBox(height: DesignTokens.spaceS));
      children.add(footer!);
    }

    return Container(
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.stretch,
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildTitleSection() {
    if (title == null &&
        subtitle == null &&
        leading == null &&
        trailing == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: DesignTokens.spaceM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? AppColors.textLight
                        : AppColors.textPrimary,
                  ),
                ),
              if (subtitle != null) ...[
                if (title != null) SizedBox(height: DesignTokens.spaceXS),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: isDisabled
                        ? AppColors.textLight
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: DesignTokens.spaceM),
          trailing!,
        ],
      ],
    );
  }

  _CardColors _getColors() {
    Color? effectiveBackgroundColor = backgroundColor;
    Color? effectiveBorderColor = borderColor;
    List<BoxShadow>? effectiveBoxShadow;

    // Aplicar colores por estado
    if (isDisabled) {
      effectiveBackgroundColor =
          disabledColor ?? AppColors.neutral.withValues(alpha: 0.1);
    } else if (isSelected) {
      effectiveBackgroundColor =
          selectedColor ?? AppColors.primary.withValues(alpha: 0.1);
      effectiveBorderColor = AppColors.primary;
    }

    // Aplicar estilos por tipo
    switch (type) {
      case AppCardType.basic:
        effectiveBackgroundColor ??= AppColors.surface;
        break;
      case AppCardType.elevated:
        effectiveBackgroundColor ??= AppColors.surface;
        effectiveBoxShadow = [
          BoxShadow(
            color: AppColors.overlayDark.withValues(alpha: 0.1),
            blurRadius: elevation ?? 4,
            offset: Offset(0, (elevation ?? 4) / 2),
          ),
        ];
        break;
      case AppCardType.outlined:
        effectiveBackgroundColor ??= AppColors.surface;
        effectiveBorderColor ??= AppColors.neutral;
        break;
      case AppCardType.filled:
        effectiveBackgroundColor ??= AppColors.backgroundLight;
        break;
    }

    return _CardColors(
      backgroundColor: effectiveBackgroundColor!,
      borderColor: effectiveBorderColor,
      boxShadow: effectiveBoxShadow,
    );
  }

  _CardDimensions _getDimensions() {
    switch (size) {
      case AppCardSize.small:
        return _CardDimensions(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          margin: EdgeInsets.all(DesignTokens.spaceXS),
          borderRadius: DesignTokens.radiusS,
        );
      case AppCardSize.medium:
        return _CardDimensions(
          padding: EdgeInsets.all(DesignTokens.spaceL),
          margin: EdgeInsets.all(DesignTokens.spaceS),
          borderRadius: DesignTokens.radiusM,
        );
      case AppCardSize.large:
        return _CardDimensions(
          padding: EdgeInsets.all(DesignTokens.spaceXL),
          margin: EdgeInsets.all(DesignTokens.spaceM),
          borderRadius: DesignTokens.radiusL,
        );
    }
  }
}

class _CardColors {
  final Color backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  _CardColors({
    required this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });
}

class _CardDimensions {
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;

  _CardDimensions({
    required this.padding,
    required this.margin,
    required this.borderRadius,
  });
}

// ============================================================================
// APP INFO CARD - Componente especializado para información
// ============================================================================

class AppInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final AppCardType type;
  final AppCardSize size;

  const AppInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.type = AppCardType.elevated,
    this.size = AppCardSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: type,
      size: size,
      onTap: onTap,
      leading: icon != null
          ? Container(
              padding: EdgeInsets.all(DesignTokens.spaceS),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: DesignTokens.iconM,
              ),
            )
          : null,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: DesignTokens.spaceXS),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (description != null) ...[
            SizedBox(height: DesignTokens.spaceXS),
            Text(
              description!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
