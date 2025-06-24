import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';

class DetalleRegistroCard extends StatelessWidget {
  final RegistroGeneral registro;

  const DetalleRegistroCard({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    final r = registro;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 4,
      shadowColor: const Color(
        0xFF003B5C,
      ).withValues(alpha: 0.15), // Sombra corporativa
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(
            0xFF003B5C,
          ).withValues(alpha: 0.1), // Border corporativo
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Header con VIN y Serie
            _buildHeader(r),

            const SizedBox(height: 12),

            // ✅ Información del vehículo
            _buildVehicleInfo(r),

            const SizedBox(height: 12),

            // ✅ Información de logística
            _buildLogisticsInfo(r),

            const SizedBox(height: 16),

            // ✅ Estados con badges
            _buildStatusBadges(r),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RegistroGeneral r) {
    return Row(
      children: [
        // VIN principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.vin,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003B5C), // Color corporativo para VIN
                ),
              ),
              if (r.serie != null && r.serie!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF00B4D8,
                    ).withValues(alpha: 0.1), // Secundario corporativo
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Serie: ${r.serie}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00B4D8), // Secundario corporativo
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Icono indicativo
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(
              0xFF003B5C,
            ).withValues(alpha: 0.1), // Fondo corporativo
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.directions_car,
            color: Color(0xFF003B5C), // Icono corporativo
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo(RegistroGeneral r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(
          0xFF003B5C,
        ).withValues(alpha: 0.03), // Fondo corporativo muy sutil
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(
            0xFF003B5C,
          ).withValues(alpha: 0.15), // Border corporativo
          width: 1,
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
            const Color(0xFF003B5C), // Color corporativo primario
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Color
              Expanded(
                child: _buildInfoRow(
                  Icons.palette,
                  'Color',
                  r.color ?? 'N/A',
                  const Color(0xFF1A5B75), // Variación corporativa
                ),
              ),
              const SizedBox(width: 16),

              // Versión
              Expanded(
                child: _buildInfoRow(
                  Icons.info_outline,
                  'Versión',
                  r.version ?? 'N/A',
                  const Color(0xFF00B4D8), // Secundario corporativo
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(
          0xFF00B4D8,
        ).withValues(alpha: 0.05), // Secundario corporativo
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
          width: 1,
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
              const Color(0xFF00B4D8), // Secundario corporativo
            ),
          ),
          const SizedBox(width: 16),

          // BL
          Expanded(
            child: _buildInfoRow(
              Icons.receipt_long,
              'BL',
              r.bl ?? 'N/A',
              const Color(0xFF003B5C), // Primario corporativo
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937), // Gris oscuro corporativo
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadges(RegistroGeneral r) {
    return Row(
      children: [
        // Badge Pedeteado
        Expanded(
          child: _buildStatusBadge(
            'Pedeteado',
            r.pedeteado
                ? const Color(0xFF059669) // Verde corporativo
                : const Color(0xFFF59E0B), // Naranja corporativo
            r.pedeteado ? Icons.check_circle : Icons.pending,
          ),
        ),
        const SizedBox(width: 12),

        // Badge Daños
        Expanded(
          child: _buildStatusBadge(
            r.danos ? 'Con Daños' : 'Sin Daños',
            r.danos
                ? const Color(0xFFDC2626) // Rojo corporativo
                : const Color(0xFF059669), // Verde corporativo
            r.danos ? Icons.warning : Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
