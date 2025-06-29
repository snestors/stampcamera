import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';
import 'package:stampcamera/widgets/autos/forms/registro_vin_forms.dart';

class DetalleRegistrosVin extends StatelessWidget {
  final List<RegistroVin> items;
  final String vin; // ✅ VIN para el formulario
  final VoidCallback? onAddPressed; // ✅ Callback opcional adicional

  const DetalleRegistrosVin({
    super.key,
    required this.items,
    required this.vin,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Header de sección con botón agregar
        _buildSectionHeader(context),

        const SizedBox(height: 16),

        // ✅ Lista de registros
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final registro = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRegistroCard(registro, index),
          );
        }),
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
          child: const Icon(Icons.history, size: 18, color: Color(0xFF003B5C)),
        ),
        const SizedBox(width: 10),
        const Text(
          'Historial de Inspecciones',
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

        // ✅ Botón agregar nuevo registro
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00B4D8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showAgregarRegistroForm(context),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.add, size: 18, color: Colors.white),
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

  void _showAgregarRegistroForm(BuildContext context) {
    // Ejecutar callback adicional si existe
    onAddPressed?.call();

    // Mostrar formulario
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegistroVinForm(vin: vin),
    );
  }

  // ============================================================================
  // ESTADO VACÍO CON BOTÓN PARA AGREGAR PRIMER REGISTRO
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
            Icons.history_outlined,
            size: 48,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin Historial',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay registros de inspecciones para este vehículo',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // ✅ Botón para agregar primer registro
          ElevatedButton.icon(
            onPressed: () => _showAgregarRegistroForm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B4D8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primera Inspección'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CARD DE REGISTRO INDIVIDUAL
  // ============================================================================
  Widget _buildRegistroCard(RegistroVin registro, int index) {
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
            // ✅ Header del registro
            _buildRegistroHeader(registro, index),

            const SizedBox(height: 12),

            // ✅ Información del registro
            _buildRegistroInfo(registro),

            // ✅ Foto si existe
            if (registro.fotoVinThumbnailUrl != null) ...[
              const SizedBox(height: 12),
              _buildFotoSection(registro),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER DEL REGISTRO
  // ============================================================================
  Widget _buildRegistroHeader(RegistroVin registro, int index) {
    return Row(
      children: [
        // ✅ Número de orden
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _getCondicionColor(registro.condicion),
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

        // ✅ Condición y fecha
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getCondicionColor(
                        registro.condicion,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getCondicionIcon(registro.condicion),
                      size: 14,
                      color: _getCondicionColor(registro.condicion),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    registro.condicion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getCondicionColor(registro.condicion),
                    ),
                  ),
                ],
              ),

              if (registro.fecha != null) ...[
                const SizedBox(height: 4),
                Text(
                  registro.fecha!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // INFORMACIÓN DEL REGISTRO
  // ============================================================================
  Widget _buildRegistroInfo(RegistroVin registro) {
    return Column(
      children: [
        // Zona de inspección
        if (registro.zonaInspeccion != null)
          _buildInfoRow(
            Icons.location_on,
            'Zona de Inspección',
            registro.zonaInspeccion!.value,
            const Color(0xFF00B4D8),
          ),

        // Bloque si existe
        if (registro.bloque != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.view_module,
            'Bloque',
            registro.bloque!.value,
            const Color(0xFF059669),
          ),
        ],

        // Creado por
        if (registro.createBy != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person,
            'Registrado por',
            registro.createBy!,
            const Color(0xFF6B7280),
          ),
        ],
      ],
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
  // SECCIÓN DE FOTO
  // ============================================================================
  Widget _buildFotoSection(RegistroVin registro) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.camera_alt,
            size: 14,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foto VIN',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: NetworkImagePreview(
            thumbnailUrl: registro.fotoVinThumbnailUrl!,
            fullImageUrl: registro.fotoVinUrl!,
            size: 40,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPERS PARA COLORES E ÍCONOS POR LUGAR DE REVISIÓN
  // ============================================================================
  Color _getCondicionColor(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return const Color(0xFF00B4D8); // Azul - zona portuaria
      case 'RECEPCION':
        return const Color(0xFF8B5CF6); // Púrpura - área de recepción
      case 'ALMACEN':
        return const Color(0xFF059669); // Verde - zona de almacenamiento
      case 'PDI':
        return const Color(0xFFF59E0B); // Naranja - inspección pre-entrega
      case 'PRE-PDI':
        return const Color(0xFFEF4444); // Rojo - inspección previa
      default:
        return const Color(0xFF6B7280); // Gris - desconocido
    }
  }

  IconData _getCondicionIcon(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return Icons.anchor; // Ancla para puerto
      case 'RECEPCION':
        return Icons.login; // Entrada para recepción
      case 'ALMACEN':
        return Icons.warehouse; // Almacén
      case 'PDI':
        return Icons.build_circle; // Herramientas para inspección final
      case 'PRE-PDI':
        return Icons.search; // Lupa para inspección previa
      default:
        return Icons.location_on; // Ubicación genérica
    }
  }
}
