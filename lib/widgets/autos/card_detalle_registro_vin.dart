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

    // Combinar estado del servidor + sesión local
    final pedeteadosLocal = ref.watch(pedeteadosEnSesionProvider);
    final isPedeteado = r.pedeteado || pedeteadosLocal.contains(r.vin);

    // Determinar color del accent strip según prioridad
    final Color accentColor;
    if (r.urgente) {
      accentColor = AppColors.error;
    } else if (r.danos) {
      accentColor = AppColors.warning;
    } else if (isPedeteado) {
      accentColor = AppColors.success;
    } else {
      accentColor = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent strip lateral
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: VIN + urgente + chevron
                    _buildHeader(r, isPedeteado),
                    SizedBox(height: DesignTokens.spaceS),

                    // Metadata: marca/modelo, color, nave
                    _buildMetadata(r),
                    SizedBox(height: DesignTokens.spaceS),

                    // Status badges
                    _buildStatusRow(r, isPedeteado),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RegistroGeneral r, bool isPedeteado) {
    return Row(
      children: [
        // Brand icon
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceS),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(
            VehicleHelpers.getVehicleIcon(r.marca ?? 'N/A'),
            color: AppColors.primary,
            size: 20,
          ),
        ),
        SizedBox(width: DesignTokens.spaceS),

        // VIN + Serie
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.vin,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (r.serie != null && r.serie!.isNotEmpty)
                Text(
                  'Serie: ${r.serie}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),

        // Urgente badge
        if (r.urgente) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              'URGENTE',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spaceS),
        ],

        Icon(
          Icons.chevron_right,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildMetadata(RegistroGeneral r) {
    return Wrap(
      spacing: DesignTokens.spaceM,
      runSpacing: DesignTokens.spaceXS,
      children: [
        _buildMetaItem(
          Icons.directions_car,
          '${r.marca ?? 'N/A'} ${r.modelo ?? ''}',
        ),
        if (r.color != null && r.color!.isNotEmpty)
          _buildMetaItem(Icons.palette, r.color!),
        if (r.naveDescarga != null && r.naveDescarga!.isNotEmpty)
          _buildMetaItem(Icons.directions_boat, r.naveDescarga!),
        if (r.version != null && r.version!.isNotEmpty)
          _buildMetaItem(Icons.info_outline, r.version!),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        SizedBox(width: DesignTokens.spaceXS),
        Text(
          text,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusRow(RegistroGeneral r, bool isPedeteado) {
    return Wrap(
      spacing: DesignTokens.spaceS,
      runSpacing: DesignTokens.spaceXS,
      children: [
        _buildBadge(
          isPedeteado ? 'Pedeteado' : 'Sin pedetear',
          isPedeteado ? AppColors.success : AppColors.warning,
          isPedeteado ? Icons.check_circle : Icons.pending,
        ),
        _buildBadge(
          r.danos ? 'Con Daños' : 'Sin Daños',
          r.danos ? AppColors.error : AppColors.success,
          r.danos ? Icons.warning : Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: DesignTokens.spaceXS),
          Text(
            text,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
