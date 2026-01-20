import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';
import 'package:stampcamera/widgets/autos/forms/registro_vin_forms.dart';
import 'package:stampcamera/core/core.dart';

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

        SizedBox(height: DesignTokens.spaceM),

        // ✅ Lista de registros
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final registro = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
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
        Expanded(
          child: AppSectionHeader(
            icon: Icons.history,
            title: 'Historial de Inspecciones',
            count: items.length,
          ),
        ),
        SizedBox(width: DesignTokens.spaceXS),

        // ✅ Botón agregar nuevo registro
        Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              onTap: () => _showAgregarRegistroForm(context),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                child: Icon(
                  Icons.add,
                  size: DesignTokens.iconXL,
                  color: Colors.white,
                ),
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
    return AppEmptyState(
      icon: Icons.history_outlined,
      title: 'Sin Historial',
      subtitle: 'No hay registros de inspecciones para este vehículo',
      action: AppButton.primary(
        text: 'Agregar Primera Inspección',
        icon: Icons.add,
        onPressed: () => _showAgregarRegistroForm(context),
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
    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header del registro con botones de acción
          _buildRegistroHeader(context, ref, registro, index),

          SizedBox(height: DesignTokens.spaceS),

          // ✅ Información del registro y foto en row
          if (registro.fotoVinThumbnailUrl != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto (lado izquierdo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  child: NetworkImagePreview(
                    thumbnailUrl: registro.fotoVinThumbnailUrl!,
                    fullImageUrl: registro.fotoVinUrl!,
                    size: 120,
                  ),
                ),
                
                SizedBox(width: DesignTokens.spaceM),
                
                // Información (lado derecho)
                Expanded(
                  child: _buildRegistroInfo(registro),
                ),
              ],
            )
          else
            // Si no hay foto, mostrar solo la información
            _buildRegistroInfo(registro),
        ],
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
          width: DesignTokens.iconL,
          height: DesignTokens.iconL,
          decoration: BoxDecoration(
            color: VehicleHelpers.getCondicionColor(registro.condicion),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: DesignTokens.fontSizeXS,
              ),
            ),
          ),
        ),

        SizedBox(width: DesignTokens.spaceS),

        // ✅ Condición y fecha
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spaceXXS),
                    decoration: BoxDecoration(
                      color: VehicleHelpers.getCondicionColor(
                        registro.condicion,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusXS,
                      ),
                    ),
                    child: Icon(
                      VehicleHelpers.getCondicionIcon(registro.condicion),
                      size: DesignTokens.iconS,
                      color: VehicleHelpers.getCondicionColor(
                        registro.condicion,
                      ),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    registro.condicion,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: FontWeight.bold,
                      color: VehicleHelpers.getCondicionColor(
                        registro.condicion,
                      ),
                    ),
                  ),
                ],
              ),

              if (registro.fecha != null) ...[
                SizedBox(height: DesignTokens.spaceXXS),
                Text(
                  registro.fecha!,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS * 0.9,
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
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              onTap: () => _showEditarRegistroForm(context, registro),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spaceXXS),
                child: Icon(
                  Icons.edit,
                  size: DesignTokens.iconXXL,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: DesignTokens.spaceXS),

        // ✅ Botón Delete
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              onTap: () => _showDeleteConfirmation(context, ref, registro),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spaceXXS),
                child: Icon(
                  Icons.delete_outline,
                  size: DesignTokens.iconXXL,
                  color: Colors.red,
                ),
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
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: DesignTokens.iconL,
              ),
              SizedBox(width: DesignTokens.spaceXS),
              Expanded(
                child: Text(
                  'Confirmar Eliminación',
                  style: TextStyle(fontSize: DesignTokens.fontSizeRegular),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás seguro de que deseas eliminar este registro de inspección?',
              ),
              SizedBox(height: DesignTokens.spaceS),
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
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
    AppSnackBar.info(context, 'Eliminando registro...');

    try {
      final notifier = ref.read(detalleRegistroProvider(vin).notifier);
      final success = await notifier.deleteRegistroVin(registro.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (success) {
          AppSnackBar.success(context, 'Registro eliminado exitosamente');
        } else {
          AppSnackBar.error(context, 'Error al eliminar registro');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Limpiar el mensaje de Exception: si viene
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        AppSnackBar.error(context, errorMsg);
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
          SizedBox(height: DesignTokens.spaceXS),
          _buildInfoRow(
            Icons.inventory_2,
            'Contenedor',
            registro.contenedor!.value,
            AppColors.accent,
          ),
        ],

        // Bloque si existe (solo para condición PUERTO)
        if (registro.bloque != null) ...[
          SizedBox(height: DesignTokens.spaceXS),
          _buildInfoRow(
            Icons.view_module,
            'Bloque',
            registro.bloque!.value,
            AppColors.accent,
          ),
        ],

        // ✅ NUEVO: Fila y Posición (solo para condición PUERTO)
        if (registro.fila != null || registro.posicion != null) ...[
          SizedBox(height: DesignTokens.spaceXS),
          _buildFilaPosicionRow(registro),
        ],

        // Creado por
        if (registro.createBy != null) ...[
          SizedBox(height: DesignTokens.spaceXS),
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
          padding: EdgeInsets.all(DesignTokens.spaceXXS),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          ),
          child: const Icon(
            Icons.grid_view,
            size: DesignTokens.iconS,
            color: AppColors.secondary,
          ),
        ),
        SizedBox(width: DesignTokens.spaceXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicación en Puerto',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS * 0.8,
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
                        fontSize: DesignTokens.fontSizeXS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (registro.fila != null && registro.posicion != null)
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        color: Colors.grey[400],
                      ),
                    ),
                  if (registro.posicion != null) ...[
                    Text(
                      'Pos. ${registro.posicion}',
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
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
          padding: EdgeInsets.all(DesignTokens.spaceXXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          ),
          child: Icon(icon, size: DesignTokens.iconS, color: color),
        ),
        SizedBox(width: DesignTokens.spaceXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS * 0.8,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
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

}
