import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';

class DetalleRegistroCard extends ConsumerWidget {
  final RegistroGeneral registro;

  const DetalleRegistroCard({
    super.key,
    required this.registro,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = registro;

    // 🎯 TIEMPO REAL: Combinar estado del servidor + sesión local
    final pedeteadosLocal = ref.watch(pedeteadosEnSesionProvider);
    final isPedeteado = r.pedeteado || pedeteadosLocal.contains(r.vin);

    return AppCard.elevated(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXS,
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(r),
          SizedBox(height: DesignTokens.spaceM),
          _buildVehicleInfo(r),
          SizedBox(height: DesignTokens.spaceM),
          _buildLogisticsInfo(r),
          SizedBox(height: DesignTokens.spaceL),
          _buildStatusBadges(r, isPedeteado),
        ],
      ),
    );
  }

  Widget _buildHeader(RegistroGeneral r) {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // VIN principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.vin,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeL * 0.9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (r.serie != null && r.serie!.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spaceXS),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: DesignTokens.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        width: DesignTokens.borderWidthNormal,
                      ),
                    ),
                    child: Text(
                      'Serie: ${r.serie}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Icono indicativo (camión o auto según marca)
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceS),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: _buildBrandIcon(r.marca ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🚛🚗 MÉTODO PARA ÍCONO SEGÚN TIPO DE VEHÍCULO
  // ============================================================================
  Widget _buildBrandIcon(String marca) {
    // Marcas que son principalmente camiones/comerciales
    final truckBrands = {
      'HINO', 'FUSO', 'T-KING', 'UD TRUCKS', 'JAC PESADO', 'KOMATSU',
      'JAC', // JAC también maneja comerciales
    };

    if (truckBrands.contains(marca.toUpperCase())) {
      return Icon(
        Icons.local_shipping, // Camión
        color: AppColors.primary,
        size: DesignTokens.iconXXL,
      );
    } else {
      // Default para autos
      return Icon(
        Icons.directions_car, // Auto
        color: AppColors.primary,
        size: DesignTokens.iconXXL,
      );
    }
  }

  Widget _buildVehicleInfo(RegistroGeneral r) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: DesignTokens.borderWidthNormal,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marca y Modelo
          _buildInfoRow(
            Icons.branding_watermark,
            'Marca / Modelo',
            '${r.marca ?? 'N/A'} ${r.modelo ?? ''}',
            AppColors.primary,
          ),
          SizedBox(height: DesignTokens.spaceS),

          Row(
            children: [
              // Color
              Expanded(
                child: _buildInfoRow(
                  Icons.palette,
                  'Color',
                  r.color ?? 'N/A',
                  AppColors.accent,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),

              // Versión
              Expanded(
                child: _buildInfoRow(
                  Icons.info_outline,
                  'Versión',
                  r.version ?? 'N/A',
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsInfo(RegistroGeneral r) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: DesignTokens.borderWidthNormal,
        ),
      ),
      child: Row(
        children: [
          // Nave
          Expanded(
            child: _buildInfoRow(
              Icons.local_shipping,
              'Nave',
              r.naveDescarga ?? 'N/A',
              AppColors.secondary,
            ),
          ),
          SizedBox(width: DesignTokens.spaceL),

          // BL
          Expanded(
            child: _buildInfoRow(
              Icons.receipt_long,
              'BL',
              r.bl ?? 'N/A',
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          ),
          child: Icon(icon, size: DesignTokens.iconS, color: color),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS * 0.8,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadges(RegistroGeneral r, bool isPedeteado) {
    return Row(
      children: [
        // Badge Pedeteado (usa estado en tiempo real)
        Expanded(
          child: _buildStatusBadge(
            isPedeteado ? 'Pedeteado' : 'No Pedeteado',
            isPedeteado ? AppColors.success : AppColors.warning,
            isPedeteado ? Icons.check_circle : Icons.pending,
          ),
        ),
        SizedBox(width: DesignTokens.spaceM),

        // Badge Daños
        Expanded(
          child: _buildStatusBadge(
            r.danos ? 'Con Daños' : 'Sin Daños',
            r.danos ? AppColors.error : AppColors.success,
            r.danos ? Icons.warning : Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: DesignTokens.borderWidthNormal,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: DesignTokens.iconS, color: color),
          SizedBox(width: DesignTokens.spaceXS),
          Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
