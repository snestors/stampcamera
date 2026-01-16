import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';
import 'package:stampcamera/widgets/autos/forms/fotos_presentacion_form.dart';
import 'package:stampcamera/core/core.dart';

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

        SizedBox(height: DesignTokens.spaceM),

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
        Expanded(
          child: AppSectionHeader(
            icon: Icons.photo_library,
            title: 'Fotos de Presentación',
            count: items.length,
          ),
        ),
        SizedBox(width: DesignTokens.spaceXS),

        // ✅ Botón agregar nueva foto
        Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              onTap: () => _showAgregarFotoForm(context),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                child: Icon(
                  Icons.add_a_photo,
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
    return AppEmptyState(
      icon: Icons.photo_library_outlined,
      title: 'Sin Fotos',
      subtitle: 'No hay fotos de presentación para este vehículo',
      action: AppButton.primary(
        text: 'Agregar Primera Foto',
        icon: Icons.add_a_photo,
        onPressed: () => _showAgregarFotoForm(context),
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
            padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
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
    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ HEADER: Tipo + Botones
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceXXS),
                decoration: BoxDecoration(
                  color: _getTipoColor(foto.tipo).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                ),
                child: Icon(
                  _getTipoIcon(foto.tipo),
                  size: DesignTokens.iconS,
                  color: _getTipoColor(foto.tipo),
                ),
              ),
              SizedBox(width: DesignTokens.spaceXS),
              Expanded(
                child: Text(
                  _getTipoLabel(foto.tipo),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.bold,
                    color: _getTipoColor(foto.tipo),
                  ),
                ),
              ),
              _buildActionButtons(context, ref, foto),
            ],
          ),

          SizedBox(height: DesignTokens.spaceS),

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
                        AppColors.primary,
                      ),

                    // Documento si existe
                    if (foto.nDocumento != null &&
                        foto.nDocumento!.isNotEmpty) ...[
                      SizedBox(height: DesignTokens.spaceXS),
                      _buildInfoRow(
                        Icons.description,
                        'Documento',
                        foto.nDocumento!,
                        AppColors.success,
                      ),
                    ],

                    // Fecha y usuario
                    if (foto.createAt != null) ...[
                      SizedBox(height: DesignTokens.spaceXS),
                      _buildInfoRow(
                        Icons.access_time,
                        'Fecha',
                        foto.createAt!,
                        AppColors.textSecondary,
                      ),
                    ],

                    if (foto.createBy != null) ...[
                      SizedBox(height: DesignTokens.spaceXS),
                      _buildInfoRow(
                        Icons.person,
                        'Registrado por',
                        foto.createBy!,
                        AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: DesignTokens.spaceM),

              // Foto (lado derecho)
              if (foto.imagenThumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  child: NetworkImagePreview(
                    thumbnailUrl: foto.imagenThumbnailUrl!,
                    fullImageUrl: foto.imagenUrl!,
                    size: 120,
                  ),
                ),
            ],
          ),
        ],
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
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
              onTap: () => _confirmDelete(context, ref, foto),
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
  // MÉTODOS PARA EDIT/DELETE
  // ============================================================================

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FotoPresentacion foto,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar Foto',
      message: '¿Estás seguro de eliminar la foto de ${_getTipoLabel(foto.tipo)}?',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      _deleteFoto(context, ref, foto);
    }
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
        AppSnackBar.success(context, 'Foto eliminada exitosamente');
      } else {
        AppSnackBar.error(context, 'Error al eliminar foto');
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

  // ============================================================================
  // HELPERS PARA COLORES E ÍCONOS POR TIPO
  // ============================================================================
  Color _getTipoColor(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return AppColors.success; // Verde - documento oficial
      case 'AUTO':
        return AppColors.primary; // Azul - foto del vehículo
      case 'KM':
        return AppColors.warning; // Naranja - kilometraje
      case 'DR':
        return AppColors.error; // Rojo - damage report
      case 'OTRO':
        return AppColors.accent; // Púrpura - otros documentos
      default:
        return AppColors.textSecondary; // Gris - desconocido
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
