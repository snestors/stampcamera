// ============================================================================
// 🏢 APP CORPORATE BAR - APPBAR CORPORATIVO ESTANDARIZADO
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stampcamera/core/theme/app_colors.dart';
import 'package:stampcamera/core/theme/design_tokens.dart';

/// AppBar corporativo con diseño consistente
class AppCorporateBar extends StatelessWidget implements PreferredSizeWidget {
  /// Título del AppBar
  final String title;

  /// Acciones del AppBar (botones a la derecha)
  final List<Widget>? actions;

  /// Si muestra el botón de regreso
  final bool showBackButton;

  /// Callback personalizado para el botón de regreso
  final VoidCallback? onBack;

  /// Widget leading personalizado (reemplaza el botón de regreso)
  final Widget? leading;

  /// Widget bottom (como TabBar)
  final PreferredSizeWidget? bottom;

  /// Si el título debe estar centrado
  final bool centerTitle;

  /// Elevación del AppBar
  final double elevation;

  /// Color de fondo personalizado (default: AppColors.primary)
  final Color? backgroundColor;

  /// Color del texto y iconos (default: blanco)
  final Color? foregroundColor;

  /// Si usa fondo transparente
  final bool transparent;

  /// Si el título es grande (estilo hero)
  final bool largeTitle;

  const AppCorporateBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBack,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.transparent = false,
    this.largeTitle = false,
  });

  /// Constructor para AppBar oscuro (cámara, galería)
  factory AppCorporateBar.dark({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBack,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    return AppCorporateBar(
      title: title,
      actions: actions,
      showBackButton: showBackButton,
      onBack: onBack,
      leading: leading,
      bottom: bottom,
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: Colors.white,
    );
  }

  /// Constructor para AppBar transparente (sobre imágenes)
  factory AppCorporateBar.transparent({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBack,
    Widget? leading,
  }) {
    return AppCorporateBar(
      title: title,
      actions: actions,
      showBackButton: showBackButton,
      onBack: onBack,
      leading: leading,
      transparent: true,
      foregroundColor: Colors.white,
    );
  }

  /// Constructor para AppBar claro (formularios, detalles)
  factory AppCorporateBar.light({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBack,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    return AppCorporateBar(
      title: title,
      actions: actions,
      showBackButton: showBackButton,
      onBack: onBack,
      leading: leading,
      bottom: bottom,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = transparent
        ? Colors.transparent
        : (backgroundColor ?? AppColors.primary);
    final fgColor = foregroundColor ?? Colors.white;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: transparent ? 0 : elevation,
      centerTitle: centerTitle,
      systemOverlayStyle: _getSystemOverlayStyle(bgColor),
      leading: _buildLeading(context, fgColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: largeTitle ? DesignTokens.fontSizeXL : DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: fgColor,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  Widget? _buildLeading(BuildContext context, Color fgColor) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios, color: fgColor, size: DesignTokens.iconXL),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
        tooltip: 'Regresar',
      );
    }

    return null;
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(Color bgColor) {
    final isDark = AppColors.isDark(bgColor);
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

/// SliverAppBar corporativo para listas con scroll
class AppCorporateSliverBar extends StatelessWidget {
  /// Título del AppBar
  final String title;

  /// Acciones del AppBar
  final List<Widget>? actions;

  /// Si el AppBar debe expandirse
  final bool expandedHeight;

  /// Altura expandida personalizada
  final double? customExpandedHeight;

  /// Si el AppBar debe flotar
  final bool floating;

  /// Si el AppBar debe fijarse
  final bool pinned;

  /// Widget flexible (imagen de fondo, etc)
  final Widget? flexibleSpace;

  const AppCorporateSliverBar({
    super.key,
    required this.title,
    this.actions,
    this.expandedHeight = false,
    this.customExpandedHeight,
    this.floating = false,
    this.pinned = true,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      floating: floating,
      pinned: pinned,
      expandedHeight: expandedHeight
          ? (customExpandedHeight ?? 200.0)
          : null,
      flexibleSpace: flexibleSpace != null
          ? FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              background: flexibleSpace,
            )
          : null,
      title: flexibleSpace == null
          ? Text(
              title,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            )
          : null,
      actions: actions,
    );
  }
}
