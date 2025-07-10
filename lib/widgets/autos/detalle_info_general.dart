import 'package:flutter/material.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:go_router/go_router.dart';

class DetalleInfoGeneral extends StatelessWidget {
  final DetalleRegistroModel r;

  const DetalleInfoGeneral({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Header principal con VIN y Serie
        _buildMainHeader(),

        SizedBox(height: DesignTokens.spaceM),

        // ✅ Información del vehículo
        _buildVehicleInfo(context),

        SizedBox(height: DesignTokens.spaceM),

        // ✅ Información de logística
        _buildLogisticsInfo(),
      ],
    );
  }

  // ============================================================================
  // HEADER PRINCIPAL
  // ============================================================================
  Widget _buildMainHeader() {
    return Material(
      type: MaterialType.transparency,
      child: AppCard.elevated(
        child: Row(
          children: [
            // VIN principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIN',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS * 0.8,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spaceXS),
                  Text(
                    r.vin,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  // Marca sin logo
                  SizedBox(height: DesignTokens.spaceS),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: DesignTokens.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: DesignTokens.borderWidthNormal,
                      ),
                    ),
                    child: Text(
                      r.informacionUnidad?.marca.marca ?? 'N/A',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Serie si existe
                  if (r.serie != null && r.serie!.isNotEmpty) ...[
                    SizedBox(height: DesignTokens.spaceS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceS,
                        vertical: DesignTokens.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusM,
                        ),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Logo de la marca como ícono indicativo
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: _buildBrandLogo(r.informacionUnidad?.marca.marca ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // INFORMACIÓN DEL VEHÍCULO
  // ============================================================================
  Widget _buildVehicleInfo(BuildContext context) {
    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          _buildSectionTitle(
            icon: Icons.directions_car,
            title: 'Información del Vehículo',
          ),

          SizedBox(height: DesignTokens.spaceL),

          // Modelo
          _buildInfoRow(
            Icons.directions_car,
            'Modelo',
            r.informacionUnidad?.modelo ?? 'N/A',
            AppColors.primary,
            isLarge: true,
          ),

          SizedBox(height: DesignTokens.spaceM),

          // Versión
          GestureDetector(
            onTap: r.informacionUnidad?.id != null
                ? () => _navigateToInventarioDetail(
                    context,
                    r.informacionUnidad!.id!,
                  )
                : null,
            child: _buildInfoRow(
              r.informacionUnidad?.inventario == true
                  ? Icons.inventory_2
                  : Icons.inventory_2_outlined,
              'Versión / Inventario',
              '${r.informacionUnidad?.version ?? 'N/A'} • ${r.informacionUnidad?.inventario == true ? 'Completado' : 'Pendiente'}',
              r.informacionUnidad?.inventario == true
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),

          SizedBox(height: DesignTokens.spaceM),

          // Color
          _buildInfoRow(
            Icons.palette,
            'Color',
            r.color ?? 'N/A',
            AppColors.accent,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // INFORMACIÓN DE LOGÍSTICA
  // ============================================================================
  Widget _buildLogisticsInfo() {
    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          _buildSectionTitle(
            icon: Icons.local_shipping,
            title: 'Información Nave',
          ),

          SizedBox(height: DesignTokens.spaceL),

          // Nave de descarga
          _buildInfoRow(
            Icons.local_shipping,
            'Nave de Descarga',
            r.naveDescarga ?? 'N/A',
            AppColors.secondary,
          ),

          SizedBox(height: DesignTokens.spaceM),

          // BL y Factura
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.receipt_long,
                  'BL',
                  r.bl ?? 'N/A',
                  AppColors.primary,
                ),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: _buildInfoRow(
                  Icons.description,
                  'Factura',
                  r.factura ?? 'N/A',
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGETS AUXILIARES
  // ============================================================================
  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceXS),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(icon, size: DesignTokens.iconM, color: AppColors.primary),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Text(
          title,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeRegular,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(icon, size: DesignTokens.iconS, color: color),
        ),
        SizedBox(width: DesignTokens.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM * 0.7,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: DesignTokens.spaceXXS),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge
                      ? DesignTokens.fontSizeRegular
                      : DesignTokens.fontSizeS,
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

  // ============================================================================
  // HELPER PARA ÍCONOS POR TIPO DE VEHÍCULO
  // ============================================================================
  Widget _buildBrandLogo(String marca) {
    return Icon(
      VehicleHelpers.getVehicleIcon(marca),
      size: DesignTokens.iconXXL,
      color: AppColors.primary,
    );
  }

  void _navigateToInventarioDetail(
    BuildContext context,
    int informacionUnidadId,
  ) {
    context.push('/autos/inventario/detalle/$informacionUnidadId');
  }
}
