// ============================================================================
// 🌾 GRANOS SCREEN - PANTALLA PRINCIPAL DEL MÓDULO DE GRANOS
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';

/// Pantalla principal del módulo de Granos
/// Actualmente es un placeholder mientras se desarrolla el módulo completo
class GranosScreen extends ConsumerWidget {
  const GranosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppCorporateBar(
        title: 'Granos',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Información',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceXXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.agriculture,
                  size: 64,
                  color: AppColors.warning,
                ),
              ),

              SizedBox(height: DesignTokens.spaceXXL),

              // Título
              Text(
                'Módulo en Desarrollo',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: DesignTokens.spaceM),

              // Descripción
              Text(
                'El módulo de gestión de granos estará disponible próximamente.',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeRegular,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: DesignTokens.spaceXXL),

              // Características planeadas
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Características planeadas:',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spaceM),
                    _buildFeatureItem(Icons.inventory_2, 'Gestión de inventario de granos'),
                    _buildFeatureItem(Icons.local_shipping, 'Control de embarques'),
                    _buildFeatureItem(Icons.assessment, 'Reportes y estadísticas'),
                    _buildFeatureItem(Icons.qr_code_scanner, 'Escaneo de tickets'),
                  ],
                ),
              ),

              SizedBox(height: DesignTokens.spaceXXL),

              // Botón de regreso
              AppButton.ghost(
                text: 'Volver al inicio',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
      child: Row(
        children: [
          Icon(icon, size: DesignTokens.iconM, color: AppColors.warning),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    AppDialog.info(
      context,
      title: 'Módulo de Granos',
      message: 'Este módulo permitirá gestionar operaciones relacionadas con '
          'granos y carga a granel. Estará disponible en una próxima actualización.',
    );
  }
}
