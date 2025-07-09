// ============================================================================
// 🔘 BOTÓN ESTÁNDAR CENTRALIZADO
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

enum AppButtonType {
  primary,
  secondary,
  tertiary,
  success,
  warning,
  error,
  info,
  ghost,
}

enum AppButtonSize {
  small,
  medium,
  large,
  extraLarge,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool isOutlined;
  final bool isDisabled;
  final double? customWidth;
  final double? customHeight;
  final EdgeInsets? customPadding;
  final BorderRadius? customBorderRadius;
  final TextStyle? customTextStyle;
  final Color? customColor;
  final Color? customTextColor;
  final Widget? customChild;
  final bool iconAfterText;
  final double? iconSize;
  final Color? iconColor;
  final double? elevation;
  final List<BoxShadow>? customShadow;
  final bool hapticFeedback;
  final Duration? animationDuration;
  final String? tooltip;
  final String? semanticsLabel;
  final Key? key;

  const AppButton({
    this.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isOutlined = false,
    this.isDisabled = false,
    this.customWidth,
    this.customHeight,
    this.customPadding,
    this.customBorderRadius,
    this.customTextStyle,
    this.customColor,
    this.customTextColor,
    this.customChild,
    this.iconAfterText = false,
    this.iconSize,
    this.iconColor,
    this.elevation,
    this.customShadow,
    this.hapticFeedback = true,
    this.animationDuration,
    this.tooltip,
    this.semanticsLabel,
  }) : super(key: key);

  // Factory constructors para tipos específicos
  factory AppButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    bool isDisabled = false,
    String? tooltip,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: AppButtonType.primary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      tooltip: tooltip,
    );
  }

  factory AppButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    bool isDisabled = false,
    String? tooltip,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: AppButtonType.secondary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      tooltip: tooltip,
    );
  }

  factory AppButton.success({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    bool isDisabled = false,
    String? tooltip,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: AppButtonType.success,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      tooltip: tooltip,
    );
  }

  factory AppButton.warning({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    bool isDisabled = false,
    String? tooltip,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: AppButtonType.warning,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      tooltip: tooltip,
    );
  }

  factory AppButton.error({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    bool isDisabled = false,
    String? tooltip,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: AppButtonType.error,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      tooltip: tooltip,
    );
  }

  factory AppButton.ghost({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
    bool isDisabled = false,
    String? tooltip,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: AppButtonType.ghost,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      isDisabled: isDisabled,
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final dimensions = _getDimensions();
    final textStyle = _getTextStyle();
    final borderRadius = customBorderRadius ?? BorderRadius.circular(dimensions.borderRadius);
    final padding = customPadding ?? dimensions.padding;
    final isButtonDisabled = isDisabled || isLoading;
    final effectiveOnPressed = isButtonDisabled ? null : onPressed;

    Widget button = Container(
      width: isFullWidth ? double.infinity : customWidth,
      height: customHeight ?? dimensions.height,
      constraints: BoxConstraints(
        minWidth: DesignTokens.minTouchTarget,
        minHeight: DesignTokens.minTouchTarget,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: borderRadius,
        border: isOutlined || type == AppButtonType.ghost
            ? Border.all(color: colors.borderColor, width: DesignTokens.borderWidthNormal)
            : null,
        boxShadow: customShadow ?? (elevation != null ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation!,
            offset: Offset(0, elevation! / 2),
          )
        ] : null),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveOnPressed != null && !isLoading
              ? () {
                  if (hapticFeedback) {
                    // HapticFeedback.lightImpact();
                  }
                  effectiveOnPressed!();
                }
              : null,
          borderRadius: borderRadius,
          splashColor: colors.textColor.withOpacity(DesignTokens.opacityPressed),
          highlightColor: colors.textColor.withOpacity(DesignTokens.opacityFocused),
          child: AnimatedContainer(
            duration: animationDuration ?? DesignTokens.animationButton,
            curve: DesignTokens.curveEaseInOut,
            padding: padding,
            child: _buildContent(colors, textStyle, dimensions),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (semanticsLabel != null) {
      button = Semantics(
        label: semanticsLabel!,
        button: true,
        enabled: !isButtonDisabled,
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(_ButtonColors colors, TextStyle textStyle, _ButtonDimensions dimensions) {
    if (customChild != null) {
      return customChild!;
    }

    final List<Widget> children = [];

    // Icono antes del texto
    if (icon != null && !iconAfterText) {
      children.add(_buildIcon(colors, dimensions));
      if (text.isNotEmpty) {
        children.add(SizedBox(width: dimensions.iconSpacing));
      }
    }

    // Loading indicator
    if (isLoading) {
      children.add(_buildLoadingIndicator(colors, dimensions));
      if (text.isNotEmpty) {
        children.add(SizedBox(width: dimensions.iconSpacing));
      }
    }

    // Texto
    if (text.isNotEmpty) {
      children.add(
        Flexible(
          child: Text(
            text,
            style: textStyle.copyWith(
              color: customTextColor ?? colors.textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Icono después del texto
    if (icon != null && iconAfterText) {
      if (text.isNotEmpty) {
        children.add(SizedBox(width: dimensions.iconSpacing));
      }
      children.add(_buildIcon(colors, dimensions));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildIcon(_ButtonColors colors, _ButtonDimensions dimensions) {
    return Icon(
      icon,
      size: iconSize ?? dimensions.iconSize,
      color: iconColor ?? colors.textColor,
    );
  }

  Widget _buildLoadingIndicator(_ButtonColors colors, _ButtonDimensions dimensions) {
    return SizedBox(
      width: dimensions.iconSize,
      height: dimensions.iconSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(colors.textColor),
      ),
    );
  }

  _ButtonColors _getColors() {
    if (customColor != null) {
      return _ButtonColors(
        backgroundColor: customColor!,
        textColor: customTextColor ?? Colors.white,
        borderColor: customColor!,
      );
    }

    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        borderColor = AppColors.primary;
        break;
      case AppButtonType.secondary:
        backgroundColor = AppColors.secondary;
        textColor = Colors.white;
        borderColor = AppColors.secondary;
        break;
      case AppButtonType.tertiary:
        backgroundColor = AppColors.backgroundLight;
        textColor = AppColors.textPrimary;
        borderColor = AppColors.textSecondary;
        break;
      case AppButtonType.success:
        backgroundColor = AppColors.success;
        textColor = Colors.white;
        borderColor = AppColors.success;
        break;
      case AppButtonType.warning:
        backgroundColor = AppColors.warning;
        textColor = Colors.white;
        borderColor = AppColors.warning;
        break;
      case AppButtonType.error:
        backgroundColor = AppColors.error;
        textColor = Colors.white;
        borderColor = AppColors.error;
        break;
      case AppButtonType.info:
        backgroundColor = AppColors.info;
        textColor = Colors.white;
        borderColor = AppColors.info;
        break;
      case AppButtonType.ghost:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
        break;
    }

    if (isOutlined) {
      return _ButtonColors(
        backgroundColor: Colors.transparent,
        textColor: backgroundColor,
        borderColor: borderColor,
      );
    }

    if (isDisabled) {
      return _ButtonColors(
        backgroundColor: backgroundColor.withOpacity(DesignTokens.opacityDisabled),
        textColor: textColor.withOpacity(DesignTokens.opacityDisabled),
        borderColor: borderColor.withOpacity(DesignTokens.opacityDisabled),
      );
    }

    return _ButtonColors(
      backgroundColor: backgroundColor,
      textColor: textColor,
      borderColor: borderColor,
    );
  }

  _ButtonDimensions _getDimensions() {
    switch (size) {
      case AppButtonSize.small:
        return _ButtonDimensions(
          height: DesignTokens.buttonHeightS,
          padding: DesignTokens.buttonPaddingS,
          iconSize: DesignTokens.iconS,
          iconSpacing: DesignTokens.spaceXS,
          borderRadius: DesignTokens.radiusButton,
        );
      case AppButtonSize.medium:
        return _ButtonDimensions(
          height: DesignTokens.buttonHeightM,
          padding: DesignTokens.buttonPaddingM,
          iconSize: DesignTokens.iconM,
          iconSpacing: DesignTokens.spaceS,
          borderRadius: DesignTokens.radiusButton,
        );
      case AppButtonSize.large:
        return _ButtonDimensions(
          height: DesignTokens.buttonHeightL,
          padding: DesignTokens.buttonPaddingL,
          iconSize: DesignTokens.iconL,
          iconSpacing: DesignTokens.spaceM,
          borderRadius: DesignTokens.radiusButton,
        );
      case AppButtonSize.extraLarge:
        return _ButtonDimensions(
          height: DesignTokens.buttonHeightXL,
          padding: DesignTokens.buttonPaddingXL,
          iconSize: DesignTokens.iconXL,
          iconSpacing: DesignTokens.spaceM,
          borderRadius: DesignTokens.radiusButton,
        );
    }
  }

  TextStyle _getTextStyle() {
    if (customTextStyle != null) {
      return customTextStyle!;
    }

    switch (size) {
      case AppButtonSize.small:
        return DesignTokens.getTextStyle('s', weight: DesignTokens.fontWeightSemiBold);
      case AppButtonSize.medium:
        return DesignTokens.getTextStyle('regular', weight: DesignTokens.fontWeightSemiBold);
      case AppButtonSize.large:
        return DesignTokens.getTextStyle('m', weight: DesignTokens.fontWeightSemiBold);
      case AppButtonSize.extraLarge:
        return DesignTokens.getTextStyle('l', weight: DesignTokens.fontWeightSemiBold);
    }
  }
}

class _ButtonColors {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  _ButtonColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

class _ButtonDimensions {
  final double height;
  final EdgeInsets padding;
  final double iconSize;
  final double iconSpacing;
  final double borderRadius;

  _ButtonDimensions({
    required this.height,
    required this.padding,
    required this.iconSize,
    required this.iconSpacing,
    required this.borderRadius,
  });
}

// ============================================================================
// ICON BUTTON
// ============================================================================

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Color? customColor;
  final Color? customIconColor;
  final double? customSize;
  final EdgeInsets? customPadding;
  final BorderRadius? customBorderRadius;
  final String? tooltip;
  final String? semanticsLabel;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.customColor,
    this.customIconColor,
    this.customSize,
    this.customPadding,
    this.customBorderRadius,
    this.tooltip,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: '',
      icon: icon,
      onPressed: onPressed,
      type: type,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
      customColor: customColor,
      iconColor: customIconColor,
      customWidth: customSize,
      customHeight: customSize,
      customPadding: customPadding,
      customBorderRadius: customBorderRadius,
      tooltip: tooltip,
      semanticsLabel: semanticsLabel,
    );
  }
}