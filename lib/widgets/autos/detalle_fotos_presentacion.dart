import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';

class DetalleFotosPresentacion extends StatelessWidget {
  final List<FotoPresentacion> items;

  const DetalleFotosPresentacion({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Header de sección
        _buildSectionHeader(),

        const SizedBox(height: 16),

        // ✅ Grid de fotos por tipo
        ..._buildPhotosByType(),
      ],
    );
  }

  // ============================================================================
  // HEADER DE SECCIÓN
  // ============================================================================
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF003B5C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.photo_library,
            size: 18,
            color: Color(0xFF003B5C),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Fotos de Presentación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF003B5C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${items.length}',
            style: const TextStyle(
              color: Color(0xFF003B5C),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // LISTA DE FOTOS SIMPLE
  // ============================================================================
  List<Widget> _buildPhotosByType() {
    return items
        .map(
          (foto) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFotoCard(foto),
          ),
        )
        .toList();
  }

  // ============================================================================
  // CARD DE FOTO INDIVIDUAL
  // ============================================================================
  Widget _buildFotoCard(FotoPresentacion foto) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF003B5C).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF003B5C).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // ✅ Información de la foto (lado izquierdo)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de foto
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getTipoColor(
                            foto.tipo,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getTipoIcon(foto.tipo),
                          size: 14,
                          color: _getTipoColor(foto.tipo),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTipoLabel(foto.tipo),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getTipoColor(foto.tipo),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Condición
                  if (foto.condicion != null)
                    _buildInfoRow(
                      Icons.location_on,
                      'Condición',
                      foto.condicion!,
                      const Color(0xFF00B4D8),
                    ),

                  // Documento si existe
                  if (foto.nDocumento != null &&
                      foto.nDocumento!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.description,
                      'Documento',
                      foto.nDocumento!,
                      const Color(0xFF059669),
                    ),
                  ],

                  // Fecha y usuario
                  if (foto.createAt != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.access_time,
                      'Fecha',
                      foto.createAt!,
                      const Color(0xFF6B7280),
                    ),
                  ],

                  if (foto.createBy != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.person,
                      'Registrado por',
                      foto.createBy!,
                      const Color(0xFF6B7280),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ✅ Foto (lado derecho)
            if (foto.imagenThumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: NetworkImagePreview(
                  thumbnailUrl: foto.imagenThumbnailUrl!,
                  fullImageUrl: foto.imagenUrl!,
                  size: 80,
                ),
              ),
          ],
        ),
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
          child: Icon(icon, size: 14, color: color),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ESTADO VACÍO
  // ============================================================================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B7280).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Color(0xFF6B7280),
          ),
          SizedBox(height: 16),
          Text(
            'Sin Fotos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No hay fotos de presentación para este vehículo',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS PARA COLORES E ÍCONOS POR TIPO
  // ============================================================================
  Color _getTipoColor(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return const Color(0xFF059669); // Verde - documento oficial
      case 'AUTO':
        return const Color(0xFF00B4D8); // Azul - foto del vehículo
      case 'KM':
        return const Color(0xFFF59E0B); // Naranja - kilometraje
      case 'DR':
        return const Color(0xFFDC2626); // Rojo - damage report
      case 'OTRO':
        return const Color(0xFF8B5CF6); // Púrpura - otros documentos
      default:
        return const Color(0xFF6B7280); // Gris - desconocido
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return Icons.assignment; // Documento/tarja
      case 'AUTO':
        return Icons.directions_car; // Vehículo
      case 'KM':
        return Icons.speed; // Velocímetro para KM
      case 'DR':
        return Icons.report_problem; // Reporte de daños
      case 'OTRO':
        return Icons.description; // Documento genérico
      default:
        return Icons.photo; // Foto genérica
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return 'Tarja/Documento';
      case 'AUTO':
        return 'Foto del Vehículo';
      case 'KM':
        return 'Kilometraje';
      case 'DR':
        return 'Damage Report';
      case 'OTRO':
        return 'Otros Documentos';
      default:
        return tipo;
    }
  }
}
