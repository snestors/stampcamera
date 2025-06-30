import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';
import 'package:stampcamera/widgets/autos/forms/fotos_presentacion_form.dart';

class DetalleFotosPresentacion extends ConsumerWidget {
  final List<FotoPresentacion> items;
  final String vin; // ✅ VIN para el formulario
  final VoidCallback? onAddPressed; // ✅ Callback opcional adicional

  const DetalleFotosPresentacion({
    super.key,
    required this.items,
    required this.vin,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Header de sección con botón agregar
        _buildSectionHeader(context),

        const SizedBox(height: 16),

        // ✅ Lista de fotos
        ..._buildPhotosByType(context, ref),
      ],
    );
  }

  // ============================================================================
  // HEADER DE SECCIÓN CON BOTÓN AGREGAR
  // ============================================================================
  Widget _buildSectionHeader(BuildContext context) {
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

        // ✅ Counter badge
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

        const SizedBox(width: 8),

        // ✅ Botón agregar nueva foto
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showAgregarFotoForm(context),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.add_a_photo, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ACCIÓN PARA MOSTRAR FORMULARIO
  // ============================================================================

  void _showAgregarFotoForm(BuildContext context) {
    // Ejecutar callback adicional si existe
    onAddPressed?.call();

    // Mostrar formulario
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FotoPresentacionForm(vin: vin),
    );
  }

  // ============================================================================
  // ESTADO VACÍO CON BOTÓN PARA AGREGAR PRIMERA FOTO
  // ============================================================================
  Widget _buildEmptyState(BuildContext context) {
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
      child: Column(
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin Fotos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay fotos de presentación para este vehículo',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // ✅ Botón para agregar primera foto
          ElevatedButton.icon(
            onPressed: () => _showAgregarFotoForm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Agregar Primera Foto'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LISTA DE FOTOS SIMPLE
  // ============================================================================
  List<Widget> _buildPhotosByType(BuildContext context, WidgetRef ref) {
    return items
        .map(
          (foto) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFotoCard(context, ref, foto),
          ),
        )
        .toList();
  }

  // ============================================================================
  // CARD DE FOTO INDIVIDUAL - NUEVA ESTRUCTURA
  // ============================================================================
  Widget _buildFotoCard(
    BuildContext context,
    WidgetRef ref,
    FotoPresentacion foto,
  ) {
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
            // ✅ HEADER: Tipo + Botones
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getTipoColor(foto.tipo).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getTipoIcon(foto.tipo),
                    size: 14,
                    color: _getTipoColor(foto.tipo),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTipoLabel(foto.tipo),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getTipoColor(foto.tipo),
                    ),
                  ),
                ),
                _buildActionButtons(context, ref, foto),
              ],
            ),

            const SizedBox(height: 12),

            // ✅ CONTENIDO: Información + Foto
            Row(
              children: [
                // Información (lado izquierdo)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Condición
                      if (foto.condicion != null)
                        _buildInfoRow(
                          Icons.location_on,
                          'Condición',
                          foto.condicion!.value,
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

                // Foto (lado derecho)
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
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN (EDIT Y DELETE) - MISMO ESTILO QUE REGISTROS_VIN
  // ============================================================================
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    FotoPresentacion foto,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Botón Edit

        // ✅ Botón Delete
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _confirmDelete(context, ref, foto),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MÉTODOS PARA EDIT/DELETE
  // ============================================================================

  void _showEditForm(BuildContext context, FotoPresentacion foto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FotoPresentacionForm(
        vin: vin,
        fotoId: foto.id,
        tipoInicial: foto.tipo,
        nDocumentoInicial: foto.nDocumento,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FotoPresentacion foto,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: Text(
          '¿Estás seguro de eliminar la foto de ${_getTipoLabel(foto.tipo)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFoto(context, ref, foto);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFoto(
    BuildContext context,
    WidgetRef ref,
    FotoPresentacion foto,
  ) async {
    final notifier = ref.read(detalleRegistroProvider(vin).notifier);

    final success = await notifier.deleteFoto(foto.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Foto eliminada exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al eliminar foto')),
        );
      }
    }
  }

  // ============================================================================
  // MÉTODOS ORIGINALES
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
