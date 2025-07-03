import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/theme/custom_colors.dart';

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

        const SizedBox(height: 16),

        // ✅ Información del vehículo
        _buildVehicleInfo(context),

        const SizedBox(height: 16),

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
      child: Card(
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // VIN principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VIN',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.vin,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    // Marca sin logo
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        r.informacionUnidad?.marca.marca ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Serie si existe
                    if (r.serie != null && r.serie!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Serie: ${r.serie}',
                          style: const TextStyle(
                            fontSize: 13,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildBrandLogo(
                  r.informacionUnidad?.marca.marca ?? 'N/A',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // INFORMACIÓN DEL VEHÍCULO
  // ============================================================================
  Widget _buildVehicleInfo(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de sección
            _buildSectionTitle(
              icon: Icons.directions_car,
              title: 'Información del Vehículo',
            ),

            const SizedBox(height: 16),

            // Modelo
            _buildInfoRow(
              Icons.directions_car,
              'Modelo',
              r.informacionUnidad?.modelo ?? 'N/A',
              AppColors.primary,
              isLarge: true,
            ),

            const SizedBox(height: 12),

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

            const SizedBox(height: 12),

            // Color
            _buildInfoRow(
              Icons.palette,
              'Color',
              r.color ?? 'N/A',
              AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // INFORMACIÓN DE LOGÍSTICA
  // ============================================================================
  Widget _buildLogisticsInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de sección
            _buildSectionTitle(
              icon: Icons.local_shipping,
              title: 'Información Nave',
            ),

            const SizedBox(height: 16),

            // Nave de descarga
            _buildInfoRow(
              Icons.local_shipping,
              'Nave de Descarga',
              r.naveDescarga ?? 'N/A',
              AppColors.secondary,
            ),

            const SizedBox(height: 12),

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
                const SizedBox(width: 16),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge ? 16 : 14,
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
      size: 28,
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
