import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';

class DetalleInfoGeneral extends StatelessWidget {
  final DetalleRegistroModel r;

  const DetalleInfoGeneral({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con gradient (VIN + Marca + Serie)
        _buildHeader(),
        SizedBox(height: DesignTokens.spaceM),

        // Sección: Vehículo
        _buildSection(
          title: 'Vehículo',
          icon: Icons.directions_car,
          children: [
            _buildInfoRow('Modelo', r.informacionUnidad?.modelo ?? 'N/A'),
            _buildInfoRow('Versión', r.informacionUnidad?.version ?? 'N/A'),
            _buildInfoRow('Color', r.color ?? 'N/A'),
            SizedBox(height: DesignTokens.spaceS),
            _buildInventarioButton(context),
          ],
        ),
        SizedBox(height: DesignTokens.spaceM),

        // Sección: Embarque / Nave
        _buildSection(
          title: 'Embarque',
          icon: Icons.directions_boat,
          children: [
            _buildInfoRow('Nave', r.naveDescarga ?? 'N/A'),
            if (r.puertoDescarga != null)
              _buildInfoRow('Puerto', r.puertoDescarga!),
            if (r.fechaAtraque != null)
              _buildInfoRow('Fecha Atraque', r.fechaAtraque!),
            _buildInfoRow('BL', r.bl ?? 'N/A'),
            _buildInfoRow('Factura', r.factura ?? 'N/A'),
            if (r.nViaje != null)
              _buildInfoRow('N° Viaje', r.nViaje!),
            if (r.cantidadEmbarque != null)
              _buildInfoRow('Cant. Embarque', '${r.cantidadEmbarque} unidades'),
            if (r.destinatario != null || r.agenteAduanal != null) ...[
              const Divider(),
              if (r.destinatario != null)
                _buildInfoRow('Destinatario', r.destinatario!),
              if (r.agenteAduanal != null)
                _buildInfoRow('Agente Aduanal', r.agenteAduanal!),
            ],
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // HEADER CON GRADIENT
  // ============================================================================
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // VIN en toda la línea
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              r.vin,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          // Badges + icono de marca
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: DesignTokens.spaceS,
                  runSpacing: DesignTokens.spaceXS,
                  children: [
                    _buildHeaderBadge(
                      r.informacionUnidad?.marca.marca ?? 'N/A',
                      Icons.directions_car,
                    ),
                    if (r.serie != null && r.serie!.isNotEmpty)
                      _buildHeaderBadge(
                        'Serie: ${r.serie}',
                        Icons.tag,
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(
                  VehicleHelpers.getVehicleIcon(
                    r.informacionUnidad?.marca.marca ?? 'N/A',
                  ),
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          SizedBox(width: DesignTokens.spaceXS),
          Text(
            text,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SECCIÓN CON TÍTULO
  // ============================================================================
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // FILA DE INFO (label: value)
  // ============================================================================
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTÓN DE INVENTARIO
  // ============================================================================
  Widget _buildInventarioButton(BuildContext context) {
    final hasInventario = r.informacionUnidad?.inventario == true;
    final hasId = r.informacionUnidad?.id != null;
    final statusColor = hasInventario ? AppColors.success : AppColors.warning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasId
            ? () => context.push(
                '/autos/inventario/detalle/${r.informacionUnidad!.id}')
            : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasInventario ? Icons.inventory_2 : Icons.inventory_2_outlined,
                size: 18,
                color: statusColor,
              ),
              SizedBox(width: DesignTokens.spaceS),
              Expanded(
                child: Text(
                  hasInventario ? 'Inventario completado' : 'Inventario pendiente',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (hasId) ...[
                Text(
                  'Ver',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
