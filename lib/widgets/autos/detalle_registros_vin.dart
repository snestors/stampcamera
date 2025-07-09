import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';
import 'package:stampcamera/widgets/autos/forms/registro_vin_forms.dart';
import 'package:stampcamera/theme/custom_colors.dart';

class DetalleRegistrosVin extends ConsumerWidget {
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

        // ✅ Lista de registros
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final registro = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRegistroCard(context, ref, registro, index),
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
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.history, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        const Text(
          'Historial de Inspecciones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),

        // ✅ Counter badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${items.length}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ✅ Botón agregar nuevo registro
        Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
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

    // ✅ Mostrar formulario en modo CREAR
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RegistroVinForm(vin: vin), // ✅ Sin registroVin = modo crear
    );
  }

  void _showEditarRegistroForm(BuildContext context, RegistroVin registro) {
    // ✅ Mostrar formulario en modo EDITAR
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegistroVinForm(
        // ✅ Mismo componente
        vin: vin,
        registroVin: registro, // ✅ Con registroVin = modo editar
      ),
    );
  }

  // ============================================================================
  // ESTADO VACÍO CON BOTÓN PARA AGREGAR PRIMER REGISTRO
  // ============================================================================
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin Historial',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay registros de inspecciones para este vehículo',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // ✅ Botón para agregar primer registro
          ElevatedButton.icon(
            onPressed: () => _showAgregarRegistroForm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
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
  // CARD DE REGISTRO INDIVIDUAL CON ACCIONES
  // ============================================================================
  Widget _buildRegistroCard(
    BuildContext context,
    WidgetRef ref,
    RegistroVin registro,
    int index,
  ) {
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
            // ✅ Header del registro con botones de acción
            _buildRegistroHeader(context, ref, registro, index),

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
  // HEADER DEL REGISTRO CON BOTONES DE ACCIÓN
  // ============================================================================
  Widget _buildRegistroHeader(
    BuildContext context,
    WidgetRef ref,
    RegistroVin registro,
    int index,
  ) {
    return Row(
      children: [
        // ✅ Número de orden
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: VehicleHelpers.getCondicionColor(registro.condicion),
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
                      color: VehicleHelpers.getCondicionColor(
                        registro.condicion,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      VehicleHelpers.getCondicionIcon(registro.condicion),
                      size: 14,
                      color: VehicleHelpers.getCondicionColor(
                        registro.condicion,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    registro.condicion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VehicleHelpers.getCondicionColor(
                        registro.condicion,
                      ),
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

        // ✅ BOTONES DE ACCIÓN (Edit y Delete)
        _buildActionButtons(context, ref, registro),
      ],
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN (EDIT Y DELETE)
  // ============================================================================
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    RegistroVin registro,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Botón Edit
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _showEditarRegistroForm(context, registro),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.edit, size: 16, color: Colors.orange),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

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
              onTap: () => _showDeleteConfirmation(context, ref, registro),
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
  // CONFIRMACIÓN DE ELIMINACIÓN - ACTUALIZADA CON CONTENEDOR
  // ============================================================================
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    RegistroVin registro,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Confirmar Eliminación'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás seguro de que deseas eliminar este registro de inspección?',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Condición: ${registro.condicion}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (registro.fecha != null)
                      Text('Fecha: ${registro.fecha}'),
                    if (registro.zonaInspeccion != null)
                      Text('Zona: ${registro.zonaInspeccion!.value}'),

                    // ✅ NUEVO: Mostrar contenedor en confirmación
                    if (registro.contenedor != null)
                      Text('Contenedor: ${registro.contenedor!.value}'),

                    // ✅ NUEVO: Mostrar bloque si existe
                    if (registro.bloque != null)
                      Text('Bloque: ${registro.bloque!.value}'),

                    // ✅ NUEVO: Mostrar fila y posición si existen
                    if (registro.fila != null || registro.posicion != null) ...[
                      Text(_buildUbicacionText(registro)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Esta acción no se puede deshacer.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteRegistro(context, ref, registro);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // ✅ NUEVO: Helper para construir texto de ubicación
  String _buildUbicacionText(RegistroVin registro) {
    final ubicacionParts = <String>[];

    if (registro.fila != null) {
      ubicacionParts.add('Fila ${registro.fila}');
    }

    if (registro.posicion != null) {
      ubicacionParts.add('Posición ${registro.posicion}');
    }

    return 'Ubicación: ${ubicacionParts.join(' - ')}';
  }

  Future<void> _deleteRegistro(
    BuildContext context,
    WidgetRef ref,
    RegistroVin registro,
  ) async {
    // Mostrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Eliminando registro...'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final notifier = ref.read(detalleRegistroProvider(vin).notifier);
      final success = await notifier.deleteRegistroVin(registro.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Registro eliminado exitosamente'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Error al eliminar registro'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // INFORMACIÓN DEL REGISTRO - ACTUALIZADA CON CONTENEDOR
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
            AppColors.secondary,
          ),

        // ✅ NUEVO: Contenedor (solo para condición ALMACEN)
        if (registro.contenedor != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.inventory_2,
            'Contenedor',
            registro.contenedor!.value,
            AppColors.accent,
          ),
        ],

        // Bloque si existe (solo para condición PUERTO)
        if (registro.bloque != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.view_module,
            'Bloque',
            registro.bloque!.value,
            AppColors.accent,
          ),
        ],

        // ✅ NUEVO: Fila y Posición (solo para condición PUERTO)
        if (registro.fila != null || registro.posicion != null) ...[
          const SizedBox(height: 8),
          _buildFilaPosicionRow(registro),
        ],

        // Creado por
        if (registro.createBy != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person,
            'Registrado por',
            registro.createBy!,
            AppColors.textSecondary,
          ),
        ],
      ],
    );
  }

  // ✅ NUEVO: Método para mostrar Fila y Posición en la misma fila
  Widget _buildFilaPosicionRow(RegistroVin registro) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.grid_view,
            size: 14,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicación en Puerto',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  if (registro.fila != null) ...[
                    Text(
                      'Fila ${registro.fila}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (registro.fila != null && registro.posicion != null)
                    Text(
                      ' • ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  if (registro.posicion != null) ...[
                    Text(
                      'Pos. ${registro.posicion}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
                  color: AppColors.textPrimary,
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
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.camera_alt,
            size: 14,
            color: AppColors.accent,
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
                  color: AppColors.textSecondary,
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
}
