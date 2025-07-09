// ============================================================================
// 🎨 DESIGN TOKENS - SISTEMA DE DISEÑO CENTRALIZADO
// ============================================================================

import 'package:flutter/material.dart';

class DesignTokens {
  // ============================================================================
  // TYPOGRAPHY SCALE
  // ============================================================================

  /// Tamaños de fuente estándar
  static const double fontSizeXXL = 32.0; // Títulos principales
  static const double fontSizeXL = 28.0; // Títulos de sección
  static const double fontSizeL = 24.0; // Títulos de card
  static const double fontSizeM = 20.0; // Subtítulos
  static const double fontSizeRegular = 16.0; // Texto normal
  static const double fontSizeS = 14.0; // Texto pequeño
  static const double fontSizeXS = 12.0; // Captions
  static const double fontSizeXXS = 10.0; // Labels pequeños

  /// Pesos de fuente
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  /// Altura de línea
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;

  // ============================================================================
  // SPACING SCALE
  // ============================================================================

  /// Espaciado estándar (múltiplos de 4)
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;
  static const double spaceHuge = 48.0;
  static const double spaceGiant = 64.0;

  /// Espaciado para componentes específicos
  static const double spacingButton = 16.0;
  static const double spacingCard = 16.0;
  static const double spacingModal = 24.0;
  static const double spacingPage = 20.0;
  static const double spacingSection = 32.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// Radio de borde estándar
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 20.0;
  static const double radiusXXXL = 24.0;
  static const double radiusRound = 999.0;

  /// Radio para componentes específicos
  static const double radiusButton = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusModal = 20.0;
  static const double radiusChip = 20.0;
  static const double radiusInput = 8.0;

  // ============================================================================
  // ELEVATIONS & SHADOWS
  // ============================================================================

  /// Elevaciones estándar
  static const double elevationNone = 0.0;
  static const double elevationXS = 1.0;
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 12.0;
  static const double elevationXXL = 16.0;
  static const double elevationXXXL = 24.0;

  /// Elevaciones para componentes específicos
  static const double elevationCard = 2.0;
  static const double elevationModal = 16.0;
  static const double elevationAppBar = 4.0;
  static const double elevationFAB = 6.0;
  static const double elevationDrawer = 16.0;

  /// Sombras personalizadas
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowStrong = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Tamaños de iconos estándar
  static const double iconXXS = 10.0;
  static const double iconXS = 12.0;
  static const double iconS = 14.0;
  static const double iconM = 16.0;
  static const double iconL = 18.0;
  static const double iconXL = 20.0;
  static const double iconXXL = 24.0;
  static const double iconXXXL = 32.0;
  static const double iconHuge = 48.0;
  static const double iconGiant = 64.0;

  /// Iconos para componentes específicos
  static const double iconButton = 20.0;
  static const double iconAppBar = 24.0;
  static const double iconFAB = 24.0;
  static const double iconChip = 16.0;
  static const double iconListTile = 24.0;

  // ============================================================================
  // BUTTON SIZES
  // ============================================================================

  /// Alturas de botón estándar
  static const double buttonHeightS = 32.0;
  static const double buttonHeightM = 40.0;
  static const double buttonHeightL = 48.0;
  static const double buttonHeightXL = 56.0;

  /// Padding de botón
  static const EdgeInsets buttonPaddingS = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );
  static const EdgeInsets buttonPaddingM = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets buttonPaddingL = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
  static const EdgeInsets buttonPaddingXL = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 20.0,
  );

  // ============================================================================
  // INPUT SIZES
  // ============================================================================

  /// Alturas de input estándar
  static const double inputHeightS = 40.0;
  static const double inputHeightM = 48.0;
  static const double inputHeightL = 56.0;

  /// Padding de input
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets inputPaddingMultiline = EdgeInsets.all(16.0);

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Duraciones de animación estándar
  static const Duration animationInstant = Duration(milliseconds: 0);
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationSlower = Duration(milliseconds: 700);
  static const Duration animationSlowest = Duration(milliseconds: 1000);

  /// Duraciones para componentes específicos
  static const Duration animationButton = Duration(milliseconds: 150);
  static const Duration animationModal = Duration(milliseconds: 300);
  static const Duration animationPage = Duration(milliseconds: 250);
  static const Duration animationToast = Duration(milliseconds: 200);
  static const Duration animationRipple = Duration(milliseconds: 300);

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================

  /// Curvas de animación estándar
  static const Curve curveLinear = Curves.linear;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveEaseInBack = Curves.easeInBack;
  static const Curve curveEaseOutBack = Curves.easeOutBack;
  static const Curve curveEaseInOutBack = Curves.easeInOutBack;
  static const Curve curveBounce = Curves.bounceOut;
  static const Curve curveElastic = Curves.elasticOut;

  // ============================================================================
  // BORDER WIDTHS
  // ============================================================================

  /// Anchos de borde estándar
  static const double borderWidthNone = 0.0;
  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthThick = 2.0;
  static const double borderWidthThicker = 3.0;
  static const double borderWidthThickest = 4.0;

  /// Anchos para componentes específicos
  static const double borderWidthInput = 1.0;
  static const double borderWidthInputFocused = 2.0;
  static const double borderWidthCard = 1.0;
  static const double borderWidthDivider = 0.5;

  // ============================================================================
  // OPACITY LEVELS
  // ============================================================================

  /// Niveles de opacidad estándar
  static const double opacityDisabled = 0.38;
  static const double opacityMuted = 0.54;
  static const double opacitySecondary = 0.70;
  static const double opacityPrimary = 0.87;
  static const double opacityFull = 1.0;

  /// Opacidad para estados
  static const double opacityHover = 0.08;
  static const double opacityPressed = 0.12;
  static const double opacityFocused = 0.12;
  static const double opacitySelected = 0.12;
  static const double opacityDrag = 0.16;

  // ============================================================================
  // BREAKPOINTS
  // ============================================================================

  /// Breakpoints para responsive design
  static const double breakpointMobile = 576.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 992.0;
  static const double breakpointWide = 1200.0;

  // ============================================================================
  // GRID SYSTEM
  // ============================================================================

  /// Sistema de grid
  static const int gridColumns = 12;
  static const double gridGutter = 16.0;
  static const double gridMargin = 16.0;

  // ============================================================================
  // Z-INDEX SCALE
  // ============================================================================

  /// Niveles de z-index
  static const int zIndexBase = 0;
  static const int zIndexSticky = 10;
  static const int zIndexFixed = 20;
  static const int zIndexOverlay = 30;
  static const int zIndexModal = 40;
  static const int zIndexPopover = 50;
  static const int zIndexTooltip = 60;
  static const int zIndexToast = 70;

  // ============================================================================
  // ASPECT RATIOS
  // ============================================================================

  /// Proporciones de aspecto comunes
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioLandscape = 16.0 / 9.0;
  static const double aspectRatioPortrait = 9.0 / 16.0;
  static const double aspectRatioWide = 21.0 / 9.0;
  static const double aspectRatioPhoto = 4.0 / 3.0;

  // ============================================================================
  // COMPONENT SPECIFIC TOKENS
  // ============================================================================

  /// Tokens específicos para cards
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardMargin = EdgeInsets.all(8.0);
  static const double cardMinHeight = 120.0;

  /// Tokens específicos para modales
  static const EdgeInsets modalPadding = EdgeInsets.all(24.0);
  static const EdgeInsets modalMargin = EdgeInsets.all(16.0);
  static const double modalMaxWidth = 600.0;

  /// Tokens específicos para listas
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const double listItemMinHeight = 48.0;
  static const double listItemDividerHeight = 1.0;

  /// Tokens específicos para formularios
  static const EdgeInsets formSectionPadding = EdgeInsets.all(16.0);
  static const double formFieldSpacing = 16.0;
  static const double formButtonSpacing = 24.0;

  // ============================================================================
  // ACCESSIBILITY TOKENS
  // ============================================================================

  /// Tamaños mínimos para touch targets
  static const double minTouchTarget = 48.0;
  static const double minTouchTargetSmall = 32.0;

  /// Contrastes mínimos
  static const double minContrastNormal = 4.5;
  static const double minContrastLarge = 3.0;

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Obtener padding según tamaño
  static EdgeInsets getPadding(String size) {
    switch (size) {
      case 'xs':
        return const EdgeInsets.all(spaceXS);
      case 's':
        return const EdgeInsets.all(spaceS);
      case 'm':
        return const EdgeInsets.all(spaceM);
      case 'l':
        return const EdgeInsets.all(spaceL);
      case 'xl':
        return const EdgeInsets.all(spaceXL);
      case 'xxl':
        return const EdgeInsets.all(spaceXXL);
      default:
        return const EdgeInsets.all(spaceM);
    }
  }

  /// Obtener margin según tamaño
  static EdgeInsets getMargin(String size) {
    return getPadding(size);
  }

  /// Obtener border radius según tamaño
  static BorderRadius getBorderRadius(String size) {
    switch (size) {
      case 'xs':
        return BorderRadius.circular(radiusXS);
      case 's':
        return BorderRadius.circular(radiusS);
      case 'm':
        return BorderRadius.circular(radiusM);
      case 'l':
        return BorderRadius.circular(radiusL);
      case 'xl':
        return BorderRadius.circular(radiusXL);
      case 'xxl':
        return BorderRadius.circular(radiusXXL);
      case 'round':
        return BorderRadius.circular(radiusRound);
      default:
        return BorderRadius.circular(radiusM);
    }
  }

  /// Obtener text style según tamaño
  static TextStyle getTextStyle(String size, {FontWeight? weight}) {
    double fontSize;
    switch (size) {
      case 'xxl':
        fontSize = fontSizeXXL;
        break;
      case 'xl':
        fontSize = fontSizeXL;
        break;
      case 'l':
        fontSize = fontSizeL;
        break;
      case 'm':
        fontSize = fontSizeM;
        break;
      case 's':
        fontSize = fontSizeS;
        break;
      case 'xs':
        fontSize = fontSizeXS;
        break;
      case 'xxs':
        fontSize = fontSizeXXS;
        break;
      default:
        fontSize = fontSizeRegular;
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight ?? fontWeightRegular,
      height: lineHeightNormal,
    );
  }

  /// Verificar si es mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointTablet;
  }

  /// Verificar si es tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointTablet && width < breakpointDesktop;
  }

  /// Verificar si es desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }
}
