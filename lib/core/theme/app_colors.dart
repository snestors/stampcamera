// ============================================================================
// 🎨 COLORES CORPORATIVOS CENTRALIZADOS
// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  // ============================================================================
  // COLORES CORPORATIVOS PRINCIPALES
  // ============================================================================
  
  /// Azul oscuro corporativo - Color principal de la marca
  static const Color primary = Color(0xFF003B5C);
  
  /// Azul claro corporativo - Color secundario de la marca
  static const Color secondary = Color(0xFF00B4D8);
  
  /// Verde corporativo - Color de acento
  static const Color accent = Color(0xFF059669);

  // ============================================================================
  // ESTADOS Y ALERTAS
  // ============================================================================
  
  /// Verde éxito - Para operaciones exitosas
  static const Color success = Color(0xFF059669);
  
  /// Naranja warning - Para advertencias
  static const Color warning = Color(0xFFF59E0B);
  
  /// Rojo error - Para errores
  static const Color error = Color(0xFFDC2626);
  
  /// Azul info - Para información
  static const Color info = Color(0xFF00B4D8);

  // ============================================================================
  // GRISES Y NEUTROS
  // ============================================================================
  
  /// Texto principal - Para contenido principal
  static const Color textPrimary = Color(0xFF1F2937);
  
  /// Texto secundario - Para contenido secundario
  static const Color textSecondary = Color(0xFF6B7280);
  
  /// Texto claro - Para contenido menos importante
  static const Color textLight = Color(0xFF9CA3AF);
  
  /// Fondo claro - Para fondos de pantalla
  static const Color backgroundLight = Color(0xFFF8FAFC);
  
  /// Fondo oscuro - Para fondos oscuros
  static const Color backgroundDark = Color(0xFF1F2937);

  // ============================================================================
  // SEVERIDADES ESPECÍFICAS (PARA DAÑOS)
  // ============================================================================
  
  /// Leve - Naranja para daños leves
  static const Color severityLow = Color(0xFFF59E0B);
  
  /// Medio - Rojo para daños medios
  static const Color severityMedium = Color(0xFFDC2626);
  
  /// Grave - Rojo oscuro para daños graves
  static const Color severityHigh = Color(0xFF7C2D12);

  // ============================================================================
  // CONDICIONES ESPECÍFICAS (PARA INSPECCIONES)
  // ============================================================================
  
  /// Puerto - Azul para condición puerto
  static const Color puerto = Color(0xFF00B4D8);
  
  /// Recepción - Púrpura para condición recepción
  static const Color recepcion = Color(0xFF8B5CF6);
  
  /// Almacén - Verde para condición almacén
  static const Color almacen = Color(0xFF059669);
  
  /// PDI - Naranja para condición PDI
  static const Color pdi = Color(0xFFF59E0B);
  
  /// Pre-PDI - Rojo para condición pre-PDI
  static const Color prePdi = Color(0xFFEF4444);
  
  /// Arribo - Azul cielo para condición arribo
  static const Color arribo = Color(0xFF0EA5E9);

  // ============================================================================
  // COLORES COMPLEMENTARIOS
  // ============================================================================
  
  /// Azul marino - Variación del color principal
  static const Color navy = Color(0xFF1E3A8A);
  
  /// Turquesa - Variación del color secundario
  static const Color turquoise = Color(0xFF06B6D4);
  
  /// Verde claro - Variación del color de acento
  static const Color lightGreen = Color(0xFF10B981);
  
  /// Gris neutro - Para divisores y bordes
  static const Color neutral = Color(0xFFE5E7EB);
  
  /// Gris oscuro - Para fondos de cards
  static const Color darkGray = Color(0xFF374151);

  // ============================================================================
  // COLORES DE SUPERFICIE
  // ============================================================================
  
  /// Superficie - Para cards y contenedores
  static const Color surface = Colors.white;
  
  /// Superficie oscura - Para modo oscuro
  static const Color surfaceDark = Color(0xFF374151);
  
  /// Superficie con tinte - Para highlights
  static const Color surfaceTint = Color(0xFFF0F9FF);

  // ============================================================================
  // COLORES DE BORDE
  // ============================================================================
  
  /// Borde claro - Para bordes sutiles
  static const Color borderLight = Color(0xFFE5E7EB);
  
  /// Borde medio - Para bordes normales
  static const Color borderMedium = Color(0xFFD1D5DB);
  
  /// Borde oscuro - Para bordes destacados
  static const Color borderDark = Color(0xFF9CA3AF);

  // ============================================================================
  // COLORES DE OVERLAY
  // ============================================================================
  
  /// Overlay claro - Para modales y popups
  static const Color overlayLight = Color(0x80FFFFFF);
  
  /// Overlay oscuro - Para fondos de modal
  static const Color overlayDark = Color(0x80000000);
  
  /// Overlay de loading - Para estados de carga
  static const Color overlayLoading = Color(0xCCFFFFFF);

  // ============================================================================
  // COLORES ESPECÍFICOS DE COMPONENTES
  // ============================================================================
  
  /// Divider - Para separadores
  static const Color divider = Color(0xFFE5E7EB);
  
  /// Disabled - Para elementos deshabilitados
  static const Color disabled = Color(0xFFD1D5DB);
  
  /// Placeholder - Para texto placeholder
  static const Color placeholder = Color(0xFF9CA3AF);
  
  /// Focus - Para elementos enfocados
  static const Color focus = Color(0xFF3B82F6);
  
  /// Hover - Para efectos hover
  static const Color hover = Color(0xFFF3F4F6);
  
  /// Selected - Para elementos seleccionados
  static const Color selected = Color(0xFFDEF7EC);
  
  /// Pressed - Para elementos presionados
  static const Color pressed = Color(0xFFF3F4F6);

  // ============================================================================
  // GRADIENTES CORPORATIVOS
  // ============================================================================
  
  /// Gradiente principal - Para botones y headers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1E40AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradiente secundario - Para elementos destacados
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradiente de éxito - Para confirmaciones
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradiente de error - Para errores
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // COLORES SEMÁNTICOS
  // ============================================================================
  
  /// Positivo - Para valores positivos
  static const Color positive = Color(0xFF059669);
  
  /// Negativo - Para valores negativos
  static const Color negative = Color(0xFFDC2626);
  
  /// Neutro - Para valores neutros
  static const Color neutralSemantic = Color(0xFF6B7280);
  
  /// Nuevo - Para elementos nuevos
  static const Color newItem = Color(0xFF3B82F6);
  
  /// Actualizado - Para elementos actualizados
  static const Color updated = Color(0xFF8B5CF6);
  
  /// Archivado - Para elementos archivados
  static const Color archived = Color(0xFF6B7280);

  // ============================================================================
  // HELPERS PARA COLORES
  // ============================================================================
  
  /// Obtener color con opacidad personalizada
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Obtener color más claro
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
  
  /// Obtener color más oscuro
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
  
  /// Verificar si un color es claro
  static bool isLight(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.light;
  }
  
  /// Verificar si un color es oscuro
  static bool isDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }
  
  /// Obtener color de texto apropiado para un fondo
  static Color getTextColorForBackground(Color backgroundColor) {
    return isLight(backgroundColor) ? textPrimary : surface;
  }
  
  /// Obtener color de contraste
  static Color getContrastColor(Color color) {
    return isLight(color) ? Colors.black : Colors.white;
  }

  // ============================================================================
  // COLORES PARA MODO OSCURO
  // ============================================================================
  
  /// Adaptación automática para modo oscuro
  static Color adaptive(Color lightColor, Color darkColor, Brightness brightness) {
    return brightness == Brightness.light ? lightColor : darkColor;
  }
  
  /// Colores primarios para modo oscuro
  static const Color primaryDark = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF38BDF8);
  static const Color accentDark = Color(0xFF34D399);
  
  /// Colores de superficie para modo oscuro
  static const Color surfaceDarkMode = Color(0xFF1F2937);
  static const Color backgroundDarkMode = Color(0xFF111827);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
}