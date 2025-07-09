// ============================================================================
// ⏳ ESTADOS DE CARGA CENTRALIZADOS
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

enum AppLoadingType {
  circular,
  linear,
  dots,
  pulse,
  skeleton,
  shimmer,
}

enum AppLoadingSize {
  small,
  medium,
  large,
  extraLarge,
}

class AppLoadingState extends StatelessWidget {
  final AppLoadingType type;
  final AppLoadingSize size;
  final String? message;
  final Color? color;
  final Color? backgroundColor;
  final bool overlay;
  final EdgeInsets? padding;
  final double? strokeWidth;
  final double? value;
  final Animation<double>? animation;
  final bool showBackground;
  final BorderRadius? borderRadius;
  final Duration? duration;
  final String? semanticsLabel;

  const AppLoadingState({
    super.key,
    this.type = AppLoadingType.circular,
    this.size = AppLoadingSize.medium,
    this.message,
    this.color,
    this.backgroundColor,
    this.overlay = false,
    this.padding,
    this.strokeWidth,
    this.value,
    this.animation,
    this.showBackground = true,
    this.borderRadius,
    this.duration,
    this.semanticsLabel,
  });

  // Factory constructors para casos comunes
  factory AppLoadingState.circular({
    AppLoadingSize size = AppLoadingSize.medium,
    String? message,
    Color? color,
    double? strokeWidth,
    double? value,
    String? semanticsLabel,
  }) {
    return AppLoadingState(
      type: AppLoadingType.circular,
      size: size,
      message: message,
      color: color,
      strokeWidth: strokeWidth,
      value: value,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppLoadingState.linear({
    String? message,
    Color? color,
    Color? backgroundColor,
    double? value,
    String? semanticsLabel,
  }) {
    return AppLoadingState(
      type: AppLoadingType.linear,
      message: message,
      color: color,
      backgroundColor: backgroundColor,
      value: value,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppLoadingState.overlay({
    AppLoadingType type = AppLoadingType.circular,
    AppLoadingSize size = AppLoadingSize.medium,
    String? message,
    Color? color,
    Color? backgroundColor,
    String? semanticsLabel,
  }) {
    return AppLoadingState(
      type: type,
      size: size,
      message: message,
      color: color,
      backgroundColor: backgroundColor,
      overlay: true,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppLoadingState.skeleton({
    AppLoadingSize size = AppLoadingSize.medium,
    BorderRadius? borderRadius,
    Duration? duration,
    String? semanticsLabel,
  }) {
    return AppLoadingState(
      type: AppLoadingType.skeleton,
      size: size,
      borderRadius: borderRadius,
      duration: duration,
      semanticsLabel: semanticsLabel,
    );
  }

  factory AppLoadingState.shimmer({
    AppLoadingSize size = AppLoadingSize.medium,
    BorderRadius? borderRadius,
    Duration? duration,
    String? semanticsLabel,
  }) {
    return AppLoadingState(
      type: AppLoadingType.shimmer,
      size: size,
      borderRadius: borderRadius,
      duration: duration,
      semanticsLabel: semanticsLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBackgroundColor = backgroundColor ?? AppColors.backgroundLight;

    Widget loadingWidget = _buildLoadingWidget(dimensions, effectiveColor, effectiveBackgroundColor);

    if (message != null) {
      loadingWidget = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loadingWidget,
          SizedBox(height: dimensions.spacing),
          _buildMessage(dimensions),
        ],
      );
    }

    if (showBackground && !overlay) {
      loadingWidget = Container(
        padding: padding ?? dimensions.padding,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
        ),
        child: loadingWidget,
      );
    }

    if (overlay) {
      loadingWidget = Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: dimensions.padding,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
            ),
            child: loadingWidget,
          ),
        ),
      );
    }

    if (semanticsLabel != null) {
      loadingWidget = Semantics(
        label: semanticsLabel!,
        child: loadingWidget,
      );
    }

    return loadingWidget;
  }

  Widget _buildLoadingWidget(
    _LoadingDimensions dimensions,
    Color effectiveColor,
    Color effectiveBackgroundColor,
  ) {
    switch (type) {
      case AppLoadingType.circular:
        return _buildCircularIndicator(dimensions, effectiveColor);
      case AppLoadingType.linear:
        return _buildLinearIndicator(dimensions, effectiveColor, effectiveBackgroundColor);
      case AppLoadingType.dots:
        return _buildDotsIndicator(dimensions, effectiveColor);
      case AppLoadingType.pulse:
        return _buildPulseIndicator(dimensions, effectiveColor);
      case AppLoadingType.skeleton:
        return _buildSkeletonIndicator(dimensions, effectiveColor);
      case AppLoadingType.shimmer:
        return _buildShimmerIndicator(dimensions, effectiveColor);
    }
  }

  Widget _buildCircularIndicator(_LoadingDimensions dimensions, Color color) {
    return SizedBox(
      width: dimensions.size,
      height: dimensions.size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? dimensions.strokeWidth,
        value: value,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildLinearIndicator(
    _LoadingDimensions dimensions,
    Color color,
    Color backgroundColor,
  ) {
    return SizedBox(
      width: dimensions.width,
      height: dimensions.strokeWidth,
      child: LinearProgressIndicator(
        value: value,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Widget _buildDotsIndicator(_LoadingDimensions dimensions, Color color) {
    return _DotsLoadingIndicator(
      color: color,
      size: dimensions.dotSize,
      spacing: dimensions.dotSpacing,
      duration: duration ?? const Duration(milliseconds: 1200),
    );
  }

  Widget _buildPulseIndicator(_LoadingDimensions dimensions, Color color) {
    return _PulseLoadingIndicator(
      color: color,
      size: dimensions.size,
      duration: duration ?? const Duration(milliseconds: 1000),
    );
  }

  Widget _buildSkeletonIndicator(_LoadingDimensions dimensions, Color color) {
    return _SkeletonLoadingIndicator(
      width: dimensions.width,
      height: dimensions.height,
      color: color.withValues(alpha: 0.1),
      borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusS),
    );
  }

  Widget _buildShimmerIndicator(_LoadingDimensions dimensions, Color color) {
    return _ShimmerLoadingIndicator(
      width: dimensions.width,
      height: dimensions.height,
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusS),
      duration: duration ?? const Duration(milliseconds: 1500),
    );
  }

  Widget _buildMessage(_LoadingDimensions dimensions) {
    return Text(
      message!,
      style: TextStyle(
        fontSize: dimensions.fontSize,
        color: AppColors.textSecondary,
        fontWeight: DesignTokens.fontWeightMedium,
      ),
      textAlign: TextAlign.center,
    );
  }

  _LoadingDimensions _getDimensions() {
    switch (size) {
      case AppLoadingSize.small:
        return _LoadingDimensions(
          size: 16.0,
          strokeWidth: 2.0,
          width: 100.0,
          height: 16.0,
          fontSize: DesignTokens.fontSizeXS,
          spacing: DesignTokens.spaceS,
          padding: const EdgeInsets.all(DesignTokens.spaceM),
          dotSize: 6.0,
          dotSpacing: 4.0,
        );
      case AppLoadingSize.medium:
        return _LoadingDimensions(
          size: 24.0,
          strokeWidth: 3.0,
          width: 200.0,
          height: 24.0,
          fontSize: DesignTokens.fontSizeS,
          spacing: DesignTokens.spaceM,
          padding: const EdgeInsets.all(DesignTokens.spaceL),
          dotSize: 8.0,
          dotSpacing: 6.0,
        );
      case AppLoadingSize.large:
        return _LoadingDimensions(
          size: 32.0,
          strokeWidth: 4.0,
          width: 300.0,
          height: 32.0,
          fontSize: DesignTokens.fontSizeRegular,
          spacing: DesignTokens.spaceL,
          padding: const EdgeInsets.all(DesignTokens.spaceXL),
          dotSize: 10.0,
          dotSpacing: 8.0,
        );
      case AppLoadingSize.extraLarge:
        return _LoadingDimensions(
          size: 48.0,
          strokeWidth: 5.0,
          width: 400.0,
          height: 48.0,
          fontSize: DesignTokens.fontSizeM,
          spacing: DesignTokens.spaceXL,
          padding: const EdgeInsets.all(DesignTokens.spaceXXL),
          dotSize: 12.0,
          dotSpacing: 10.0,
        );
    }
  }
}

class _LoadingDimensions {
  final double size;
  final double strokeWidth;
  final double width;
  final double height;
  final double fontSize;
  final double spacing;
  final EdgeInsets padding;
  final double dotSize;
  final double dotSpacing;

  _LoadingDimensions({
    required this.size,
    required this.strokeWidth,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.spacing,
    required this.padding,
    required this.dotSize,
    required this.dotSpacing,
  });
}

// ============================================================================
// INDICADORES PERSONALIZADOS
// ============================================================================

class _DotsLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final double spacing;
  final Duration duration;

  const _DotsLoadingIndicator({
    required this.color,
    required this.size,
    required this.spacing,
    required this.duration,
  });

  @override
  State<_DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<_DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            (index * 0.15) + 0.7,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index < 2 ? widget.spacing : 0,
              ),
              child: Transform.scale(
                scale: 0.5 + (_animations[index].value * 0.5),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.3 + (_animations[index].value * 0.7)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulseLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const _PulseLoadingIndicator({
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<_PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.2 + (_animation.value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _SkeletonLoadingIndicator extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;

  const _SkeletonLoadingIndicator({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );
  }
}

class _ShimmerLoadingIndicator extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final BorderRadius borderRadius;
  final Duration duration;

  const _ShimmerLoadingIndicator({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
    required this.duration,
  });

  @override
  State<_ShimmerLoadingIndicator> createState() => _ShimmerLoadingIndicatorState();
}

class _ShimmerLoadingIndicatorState extends State<_ShimmerLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.color.withValues(alpha: 0.1),
                widget.color.withValues(alpha: 0.3),
                widget.color.withValues(alpha: 0.1),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// WIDGET PARA LOADING ESPECÍFICO DE LISTAS
// ============================================================================

class AppListLoadingState extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? itemPadding;
  final EdgeInsets? itemMargin;
  final BorderRadius? itemBorderRadius;
  final Color? itemColor;
  final Widget? separator;

  const AppListLoadingState({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 60.0,
    this.itemPadding,
    this.itemMargin,
    this.itemBorderRadius,
    this.itemColor,
    this.separator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Column(
          children: [
            Container(
              height: itemHeight,
              margin: itemMargin ?? const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceL,
                vertical: DesignTokens.spaceXS,
              ),
              padding: itemPadding ?? const EdgeInsets.all(DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: itemColor ?? AppColors.backgroundLight,
                borderRadius: itemBorderRadius ?? BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: AppLoadingState.shimmer(
                size: AppLoadingSize.medium,
                borderRadius: itemBorderRadius ?? BorderRadius.circular(DesignTokens.radiusS),
              ),
            ),
            if (separator != null && index < itemCount - 1) separator!,
          ],
        );
      }),
    );
  }
}

// ============================================================================
// WIDGET PARA LOADING DE CARDS
// ============================================================================

class AppCardLoadingState extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool showHeader;
  final bool showFooter;
  final int lineCount;

  const AppCardLoadingState({
    super.key,
    this.width = double.infinity,
    this.height = 200.0,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.showHeader = true,
    this.showFooter = true,
    this.lineCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(DesignTokens.spaceM),
      padding: padding ?? const EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundLight,
        borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            AppLoadingState.shimmer(
              size: AppLoadingSize.medium,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            SizedBox(height: DesignTokens.spaceM),
          ],
          ...List.generate(lineCount, (index) {
            return Column(
              children: [
                AppLoadingState.shimmer(
                  size: AppLoadingSize.small,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                if (index < lineCount - 1) SizedBox(height: DesignTokens.spaceS),
              ],
            );
          }),
          if (showFooter) ...[
            SizedBox(height: DesignTokens.spaceM),
            AppLoadingState.shimmer(
              size: AppLoadingSize.medium,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
          ],
        ],
      ),
    );
  }
}