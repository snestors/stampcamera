// ============================================================================
// 🎨 GUÍA DE ESTILOS - PROYECTO STAMPCAMERA
// ============================================================================

// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Colores Corporativos Principales
  static const Color primary = Color(0xFF003B5C); // Azul oscuro corporativo
  static const Color secondary = Color(0xFF00B4D8); // Azul claro corporativo
  static const Color accent = Color(0xFF059669); // Verde corporativo

  // Estados y Alertas
  static const Color success = Color(0xFF059669); // Verde éxito
  static const Color warning = Color(0xFFF59E0B); // Naranja warning
  static const Color error = Color(0xFFDC2626); // Rojo error
  static const Color info = Color(0xFF00B4D8); // Azul info

  // Grises y Neutros
  static const Color textPrimary = Color(0xFF1F2937); // Texto principal
  static const Color textSecondary = Color(0xFF6B7280); // Texto secundario
  static const Color textLight = Color(0xFF9CA3AF); // Texto claro
  static const Color backgroundLight = Color(0xFFF8FAFC); // Fondo claro

  // Severidades específicas (para daños)
  static const Color severityLow = Color(0xFFF59E0B); // Leve - Naranja
  static const Color severityMedium = Color(0xFFDC2626); // Medio - Rojo
  static const Color severityHigh = Color(0xFF7C2D12); // Grave - Rojo oscuro

  // Condiciones específicas (para inspecciones)
  static const Color puerto = Color(0xFF00B4D8); // Puerto - Azul
  static const Color recepcion = Color(0xFF8B5CF6); // Recepción - Púrpura
  static const Color almacen = Color(0xFF059669); // Almacén - Verde
  static const Color pdi = Color(0xFFF59E0B); // PDI - Naranja
  static const Color prePdi = Color(0xFFEF4444); // Pre-PDI - Rojo
  static const Color arribo = Color(0xFF0EA5E9); // Arribo - Azul cielo
}

// ============================================================================
// 📏 DIMENSIONES Y ESPACIADO
// ============================================================================

class AppDimensions {
  // Padding y Margins estándar
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 32.0;

  // Border Radius estándar
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 20.0;

  // Elevaciones estándar
  static const double elevationCard = 2.0;
  static const double elevationModal = 8.0;
  static const double elevationFAB = 6.0;

  // Tamaños de iconos
  static const double iconXS = 12.0;
  static const double iconS = 14.0;
  static const double iconM = 16.0;
  static const double iconL = 18.0;
  static const double iconXL = 20.0;
  static const double iconXXL = 24.0;

  // Tamaños de imágenes
  static const double imagePreviewS = 40.0;
  static const double imagePreviewM = 60.0;
  static const double imagePreviewL = 80.0;
  static const double imagePreviewXL = 100.0;
}

// ============================================================================
// 🎯 WIDGETS ESTÁNDAR REUTILIZABLES
// ============================================================================

// lib/core/widgets/app_card.dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? AppDimensions.elevationCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        side: BorderSide(
          color: borderColor ?? AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        child: child,
      ),
    );
  }
}

// ============================================================================
// 🏷️ BADGES Y STATUS WIDGETS
// ============================================================================

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isSmall;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 10 : 12, color: color),
            SizedBox(width: isSmall ? 3 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 9 : 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📝 WIDGETS DE INFORMACIÓN
// ============================================================================

class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  const AppInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(icon, size: AppDimensions.iconS, color: color),
        ),
        const SizedBox(width: AppDimensions.paddingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge ? 16 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 🎨 HEADERS DE SECCIÓN
// ============================================================================

class AppSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final Color? iconColor;

  const AppSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.count,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Icon(icon, size: AppDimensions.iconL, color: color),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (count != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingS,
              vertical: AppDimensions.paddingXS,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// 📱 APPBAR CORPORATIVO
// ============================================================================

class CorporateAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const CorporateAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      bottom: bottom,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

// ============================================================================
// 🎯 ESTADOS VACÍOS ESTÁNDAR
// ============================================================================

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final stateColor = color ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: stateColor.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: stateColor),
          const SizedBox(height: AppDimensions.paddingL),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: stateColor,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: stateColor),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppDimensions.paddingL),
            action!,
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 🚗 HELPERS PARA MARCAS DE VEHÍCULOS
// ============================================================================

class VehicleHelpers {
  // Marcas que son principalmente camiones/comerciales
  static const Set<String> truckBrands = {
    'HINO',
    'FUSO',
    'T-KING',
    'UD TRUCKS',
    'JAC PESADO',
    'KOMATSU',
    'JAC',
  };

  static IconData getVehicleIcon(String marca) {
    return truckBrands.contains(marca.toUpperCase())
        ? Icons
              .local_shipping // Camión
        : Icons.directions_car; // Auto
  }

  static Color getCondicionColor(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return AppColors.puerto;
      case 'RECEPCION':
        return AppColors.recepcion;
      case 'ALMACEN':
        return AppColors.almacen;
      case 'PDI':
        return AppColors.pdi;
      case 'PRE-PDI':
        return AppColors.prePdi;
      case 'ARRIBO':
        return AppColors.arribo;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData getCondicionIcon(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return Icons.anchor;
      case 'RECEPCION':
        return Icons.login;
      case 'ALMACEN':
        return Icons.warehouse;
      case 'PDI':
        return Icons.build_circle;
      case 'PRE-PDI':
        return Icons.search;
      case 'ARRIBO':
        return Icons.flight_land;
      default:
        return Icons.location_on;
    }
  }

  static Color getSeveridadColor(String severidad) {
    if (severidad.contains('LEVE')) {
      return AppColors.severityLow;
    } else if (severidad.contains('MEDIO')) {
      return AppColors.severityMedium;
    } else if (severidad.contains('GRAVE')) {
      return AppColors.severityHigh;
    }
    return AppColors.textSecondary;
  }
}

// ============================================================================
// 📋 INSTRUCCIONES DE USO
// ============================================================================

/*
INSTRUCCIONES PARA NUEVAS VISTAS:

1. COLORES:
   - Usa AppColors.primary para elementos principales
   - Usa AppColors.secondary para acentos
   - Usa AppColors.success/warning/error según contexto

2. CARDS:
   - Siempre usa AppCard() para contenedores
   - Mantén elevation: 2 y borderRadius: 16

3. HEADERS:
   - Usa AppSectionHeader() para títulos de sección
   - Incluye contador si es relevante

4. INFO ROWS:
   - Usa AppInfoRow() para mostrar información estructurada
   - Mantén consistencia en iconos y colores

5. BADGES:
   - Usa AppBadge() para estados y categorías
   - Colores según contexto (severidad, condición, etc.)

6. ESTADOS VACÍOS:
   - Usa AppEmptyState() con mensaje apropiado
   - Color verde para "sin problemas", gris para "vacío"

7. APPBARS:
   - Usa CorporateAppBar() para consistencia
   - Color corporativo estándar

8. HELPERS:
   - Usa VehicleHelpers para lógica de vehículos
   - Mantén íconos y colores consistentes

EJEMPLO DE NUEVA VISTA:
```dart
class NuevaVista extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CorporateAppBar(title: 'Nueva Vista'),
      body: Column(
        children: [
          AppSectionHeader(
            icon: Icons.list,
            title: 'Mi Lista',
            count: items.length,
          ),
          AppCard(
            child: AppInfoRow(
              icon: Icons.info,
              label: 'Información',
              value: 'Valor',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

¡Sigue estos patrones para mantener la consistencia visual en todo el proyecto!
*/
