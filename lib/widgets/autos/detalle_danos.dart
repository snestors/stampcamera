import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';

class DetalleDanos extends StatelessWidget {
  final List<Dano> danos;

  const DetalleDanos({super.key, required this.danos});

  @override
  Widget build(BuildContext context) {
    if (danos.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Header de sección
        _buildSectionHeader(),

        const SizedBox(height: 16),

        // ✅ Lista de daños
        ...danos.asMap().entries.map((entry) {
          final index = entry.key;
          final dano = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDanoCard(context, dano, index),
          );
        }),
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
            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.warning_outlined,
            size: 18,
            color: Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Daños Reportados',
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
            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${danos.length}',
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // CARD DE DAÑO INDIVIDUAL
  // ============================================================================
  Widget _buildDanoCard(BuildContext context, Dano dano, int index) {
    final condicionTexto = _getCondicionTexto(dano);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Header del daño
            _buildDanoHeader(dano, index, condicionTexto),

            const SizedBox(height: 12),

            // ✅ Información principal del daño
            _buildDanoInfo(dano),

            // ✅ Información adicional
            if (_hasAdditionalInfo(dano)) ...[
              const SizedBox(height: 12),
              _buildAdditionalInfo(context, dano),
            ],

            // ✅ Fotos del daño
            if (dano.imagenes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImagenesSection(dano.imagenes),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER DEL DAÑO
  // ============================================================================
  Widget _buildDanoHeader(Dano dano, int index, String condicionTexto) {
    return Row(
      children: [
        // ✅ Número de daño
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _getSeveridadColor(dano.severidad.esp),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ✅ Condición y badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Condición
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getCondicionColor(
                        condicionTexto,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getCondicionIcon(condicionTexto),
                      size: 14,
                      color: _getCondicionColor(condicionTexto),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    condicionTexto,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getCondicionColor(condicionTexto),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Badges de estado
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  // Severidad con color específico
                  _buildSeveridadBadge(dano.severidad.esp),

                  // Relevante si aplica
                  if (dano.relevante)
                    _buildStatusBadge(
                      'RELEVANTE',
                      const Color(0xFFF59E0B),
                      Icons.priority_high,
                    ),

                  // Verificado si aplica
                  if (dano.verificadoBool)
                    _buildStatusBadge(
                      'VERIFICADO',
                      const Color(0xFF059669),
                      Icons.verified,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // INFORMACIÓN PRINCIPAL DEL DAÑO
  // ============================================================================
  Widget _buildDanoInfo(Dano dano) {
    return Column(
      children: [
        // Tipo de daño
        _buildInfoRow(
          Icons.build_circle,
          'Tipo de Daño',
          dano.tipoDano.esp,
          const Color(0xFFDC2626),
        ),

        const SizedBox(height: 8),

        // Área del daño
        _buildInfoRow(
          Icons.place,
          'Área Afectada',
          dano.areaDano.esp,
          const Color(0xFF00B4D8),
        ),

        // Zonas si existen
        if (dano.zonas.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.location_on,
            'Zonas',
            dano.zonas.map((z) => z.zona).join(', '),
            const Color(0xFF8B5CF6),
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // INFORMACIÓN ADICIONAL
  // ============================================================================
  Widget _buildAdditionalInfo(BuildContext context, Dano dano) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B7280).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Descripción
          if (dano.descripcion != null && dano.descripcion!.isNotEmpty)
            _buildInfoRow(
              Icons.description,
              'Descripción',
              dano.descripcion!,
              const Color(0xFF6B7280),
            ),

          // Responsabilidad
          if (dano.responsabilidad?.esp != null) ...[
            if (dano.descripcion != null && dano.descripcion!.isNotEmpty)
              const SizedBox(height: 8),
            _buildInfoRow(
              Icons.assignment_ind,
              'Responsabilidad',
              dano.responsabilidad!.esp,
              const Color(0xFF059669),
            ),
          ],

          // Documento de foto si existe
          if (dano.nDocumento != null) ...[
            if ((dano.descripcion != null && dano.descripcion!.isNotEmpty) ||
                dano.responsabilidad?.esp != null)
              const SizedBox(height: 8),
            _buildDocumentoRow(context, dano.nDocumento!),
          ],

          // Fecha y usuario
          if (dano.createAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Fecha de Registro',
              dano.createAt!,
              const Color(0xFF6B7280),
            ),
          ],

          if (dano.createBy != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.person,
              'Registrado por',
              dano.createBy!,
              const Color(0xFF6B7280),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // SECCIÓN DE IMÁGENES
  // ============================================================================
  Widget _buildImagenesSection(List<DanoImagen> imagenes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.photo_library,
                  size: 14,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Fotos del Daño (${imagenes.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: imagenes.map((img) {
              return img.imagenThumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkImagePreview(
                        thumbnailUrl: img.imagenThumbnailUrl!,
                        fullImageUrl: img.imagenUrl!,
                        size: 60,
                      ),
                    )
                  : const SizedBox.shrink();
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGETS AUXILIARES
  // ============================================================================
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

  Widget _buildSeveridadBadge(String severidad) {
    IconData icon;
    Color color;

    if (severidad.contains('LEVE')) {
      icon = Icons.info_outline;
      color = const Color(0xFFF59E0B); // Naranja
    } else if (severidad.contains('MEDIO')) {
      icon = Icons.warning_outlined;
      color = const Color(0xFFDC2626); // Rojo
    } else if (severidad.contains('GRAVE')) {
      icon = Icons.dangerous_outlined;
      color = const Color(0xFF7C2D12); // Rojo oscuro
    } else {
      icon = Icons.error_outline;
      color = const Color(0xFF6B7280); // Gris
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            severidad,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentoRow(BuildContext context, FotoPresentacion documento) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.article, size: 14, color: Color(0xFF00B4D8)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documento de Referencia',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                documento.nDocumento ?? 'Sin número',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        if (documento.imagenThumbnailUrl != null)
          GestureDetector(
            onTap: () => _showDocumentoModal(context, documento),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, size: 12, color: Color(0xFF00B4D8)),
                  SizedBox(width: 4),
                  Text(
                    'Ver',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00B4D8),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentoModal(BuildContext context, FotoPresentacion documento) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
              maxWidth: MediaQuery.of(dialogContext).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del modal
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF003B5C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.article, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Documento de Referencia',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              documento.nDocumento ?? 'Sin número',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Imagen del documento
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkImagePreview(
                        thumbnailUrl: documento.imagenThumbnailUrl!,
                        fullImageUrl: documento.imagenUrl!,
                        size: double.infinity,
                      ),
                    ),
                  ),
                ),

                // Footer con información adicional
                if (documento.createAt != null || documento.createBy != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003B5C).withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (documento.createAt != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Fecha: ${documento.createAt}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        if (documento.createBy != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Por: ${documento.createBy}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // ESTADO VACÍO
  // ============================================================================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF059669)),
          SizedBox(height: 16),
          Text(
            'Sin Daños',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Este vehículo no tiene daños reportados',
            style: TextStyle(fontSize: 12, color: Color(0xFF059669)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  String _getCondicionTexto(Dano dano) {
    return (dano.condicion == "PUERTO" &&
            (dano.responsabilidad?.esp == "SNMP" ||
                dano.responsabilidad?.esp == "NAVIERA"))
        ? "ARRIBO"
        : dano.condicion ?? "";
  }

  bool _hasAdditionalInfo(Dano dano) {
    return (dano.descripcion != null && dano.descripcion!.isNotEmpty) ||
        dano.responsabilidad?.esp != null ||
        dano.nDocumento != null ||
        dano.createAt != null ||
        dano.createBy != null;
  }

  Color _getSeveridadColor(String severidad) {
    if (severidad.contains('LEVE')) {
      return const Color(0xFFF59E0B); // Naranja
    } else if (severidad.contains('MEDIO')) {
      return const Color(0xFFDC2626); // Rojo
    } else if (severidad.contains('GRAVE')) {
      return const Color(0xFF7C2D12); // Rojo oscuro
    }
    return const Color(0xFF6B7280); // Gris por defecto
  }

  Color _getCondicionColor(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return const Color(0xFF00B4D8);
      case 'RECEPCION':
        return const Color(0xFF8B5CF6);
      case 'ALMACEN':
        return const Color(0xFF059669);
      case 'ARRIBO':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCondicionIcon(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return Icons.anchor;
      case 'RECEPCION':
        return Icons.login;
      case 'ALMACEN':
        return Icons.warehouse;
      case 'ARRIBO':
        return Icons.flight_land;
      default:
        return Icons.location_on;
    }
  }
}
