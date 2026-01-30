import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';
import 'package:stampcamera/widgets/common/fullscreen_image_viewer.dart';
import 'package:stampcamera/core/core.dart';

class DetalleDanos extends ConsumerWidget {
  final List<Dano> danos;
  final String vin; // ✅ Agregar VIN para las acciones
  final VoidCallback? onAddPressed; // ✅ Callback opcional adicional

  const DetalleDanos({
    super.key,
    required this.danos,
    required this.vin,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (danos.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Header de sección con botón agregar
        _buildSectionHeader(context),

        SizedBox(height: DesignTokens.spaceM),

        // ✅ Lista de daños
        ...danos.asMap().entries.map((entry) {
          final index = entry.key;
          final dano = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
            child: _buildDanoCard(context, ref, dano, index),
          );
        }),
      ],
    );
  }

  // ============================================================================
  // HEADER DE SECCIÓN CON BOTÓN AGREGAR (IGUAL QUE FOTOS)
  // ============================================================================
  Widget _buildSectionHeader(BuildContext context) {
    return AppSectionHeader(
      icon: Icons.warning_outlined,
      title: 'Daños Reportados',
      count: danos.length,
      iconColor: AppColors.error,
    );
  }

  // ============================================================================
  // ACCIÓN PARA MOSTRAR FORMULARIO DE CREAR
  // ============================================================================

  void _showAgregarDanoForm(BuildContext context) {
    onAddPressed?.call();
    context.push('/autos/dano/crear/$vin');
  }

  // ============================================================================
  // ESTADO VACÍO CON BOTÓN PARA AGREGAR PRIMER DAÑO (IGUAL QUE FOTOS)
  // ============================================================================
  Widget _buildEmptyState(BuildContext context) {
    return AppEmptyState(
      icon: Icons.check_circle_outline,
      title: 'Sin Daños',
      subtitle: 'Este vehículo no tiene daños reportados',
      color: AppColors.success,
      action: ElevatedButton.icon(
        onPressed: () => _showAgregarDanoForm(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceL,
            vertical: DesignTokens.spaceS,
          ),
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Reportar Primer Daño'),
      ),
    );
  }


  // ============================================================================
  // CARD DE DAÑO INDIVIDUAL CON BOTONES DE ACCIÓN
  // ============================================================================
  Widget _buildDanoCard(
    BuildContext context,
    WidgetRef ref,
    Dano dano,
    int index,
  ) {
    final condicionTexto = _getCondicionTexto(dano);

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header del daño CON BOTONES DE ACCIÓN
          _buildDanoHeader(context, ref, dano, index, condicionTexto),

          const SizedBox(height: 12),

          // ✅ Información principal del daño
          _buildDanoInfo(dano),

          // ✅ Información adicional
          if (_hasAdditionalInfo(dano)) ...[
            SizedBox(height: DesignTokens.spaceS),
            _buildAdditionalInfo(context, dano),
          ],

          // ✅ Fotos del daño
          if (dano.imagenes.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spaceS),
            _buildImagenesSection(dano.imagenes),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER DEL DAÑO CON BOTONES DE ACCIÓN
  // ============================================================================
  Widget _buildDanoHeader(
    BuildContext context,
    WidgetRef ref,
    Dano dano,
    int index,
    String condicionTexto,
  ) {
    return Row(
      children: [
        // ✅ Número de daño
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: VehicleHelpers.getSeveridadColor(dano.severidad.esp),
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

        SizedBox(width: DesignTokens.spaceS),

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
                      color: VehicleHelpers.getCondicionColor(
                        condicionTexto,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      VehicleHelpers.getCondicionIcon(condicionTexto),
                      size: 14,
                      color: VehicleHelpers.getCondicionColor(condicionTexto),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    condicionTexto,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VehicleHelpers.getCondicionColor(condicionTexto),
                    ),
                  ),
                ],
              ),

              SizedBox(height: DesignTokens.spaceXS),

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
                      AppColors.success,
                      Icons.verified,
                    ),
                ],
              ),
            ],
          ),
        ),

        // ✅ BOTONES DE ACCIÓN (EDIT Y DELETE)
        _buildActionButtons(context, ref, dano),
      ],
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN (EDIT Y DELETE) - IGUAL QUE FOTOS
  // ============================================================================
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Dano dano) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Botón Edit
        Container(
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _showEditForm(context, dano),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: DesignTokens.iconXXL,
                  color: AppColors.success,
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
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _confirmDelete(context, ref, dano),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, size: DesignTokens.iconXXL, color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MÉTODOS PARA EDIT/DELETE (IGUAL QUE FOTOS)
  // ============================================================================

  void _showEditForm(BuildContext context, Dano dano) {
    context.push('/autos/dano/editar/$vin/${dano.id}');
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Dano dano) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar Daño',
      message: '¿Estás seguro de eliminar el daño de ${dano.areaDano.esp}?\n\nEsta acción también eliminará todas las fotos asociadas.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      _deleteDano(context, ref, dano);
    }
  }

  Future<void> _deleteDano(
    BuildContext context,
    WidgetRef ref,
    Dano dano,
  ) async {
    final notifier = ref.read(detalleRegistroProvider(vin).notifier);

    final success = await notifier.deleteDano(dano.id);

    if (context.mounted) {
      if (success) {
        AppSnackBar.success(context, 'Daño eliminado exitosamente');
      } else {
        AppSnackBar.error(context, 'Error al eliminar daño');
      }
    }
  }

  // ============================================================================
  // RESTO DE MÉTODOS ORIGINALES (SIN CAMBIOS)
  // ============================================================================

  Widget _buildDanoInfo(Dano dano) {
    return Column(
      children: [
        // Tipo de daño
        _buildInfoRow(
          Icons.build_circle,
          'Tipo de Daño',
          dano.tipoDano.esp,
          AppColors.error,
        ),

        SizedBox(height: DesignTokens.spaceXS),

        // Área del daño
        _buildInfoRow(
          Icons.place,
          'Área Afectada',
          dano.areaDano.esp,
          AppColors.accent,
        ),

        // Zonas si existen
        if (dano.zonas.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spaceXS),
          _buildInfoRow(
            Icons.location_on,
            'Zonas',
            dano.zonas.map((z) => z.zona).join(', '),
            AppColors.secondary,
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, Dano dano) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
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
              AppColors.textSecondary,
            ),

          // Responsabilidad
          if (dano.responsabilidad?.esp != null) ...[
            if (dano.descripcion != null && dano.descripcion!.isNotEmpty)
              SizedBox(height: DesignTokens.spaceXS),
            _buildInfoRow(
              Icons.assignment_ind,
              'Responsabilidad',
              dano.responsabilidad!.esp,
              AppColors.success,
            ),
          ],

          // Documento de foto si existe
          if (dano.nDocumento != null) ...[
            if ((dano.descripcion != null && dano.descripcion!.isNotEmpty) ||
                dano.responsabilidad?.esp != null)
              SizedBox(height: DesignTokens.spaceXS),
            _buildDocumentoRow(context, dano.nDocumento!),
          ],

          // Fecha y usuario
          if (dano.createAt != null) ...[
            SizedBox(height: DesignTokens.spaceXS),
            _buildInfoRow(
              Icons.access_time,
              'Fecha de Registro',
              dano.createAt!,
              AppColors.textSecondary,
            ),
          ],

          if (dano.createBy != null) ...[
            SizedBox(height: DesignTokens.spaceXS),
            _buildInfoRow(
              Icons.person,
              'Registrado por',
              dano.createBy!,
              AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagenesSection(List<DanoImagen> imagenes) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceS),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
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
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.photo_library,
                  size: 14,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: DesignTokens.spaceXS),
              Text(
                'Fotos del Daño (${imagenes.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),

          SizedBox(height: DesignTokens.spaceXS),

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
                        size: 80,
                      ),
                    )
                  : const SizedBox.shrink();
            }).toList(),
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
          child: Icon(icon, size: 14, color: color),
        ),
        SizedBox(width: DesignTokens.spaceXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
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
        SizedBox(width: DesignTokens.spaceXS),
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
    if (documento.imagenUrl == null) return;

    FullscreenImageViewer.open(
      context,
      imageUrl: documento.imagenUrl!,
      title: 'Documento: ${documento.nDocumento ?? "Sin número"}',
    );
  }

  // ============================================================================
  // HELPERS (SIN CAMBIOS)
  // ============================================================================

  String _getCondicionTexto(Dano dano) {
    return (dano.condicion?.value == "PUERTO" &&
            (dano.responsabilidad?.esp == "SNMP" ||
                dano.responsabilidad?.esp == "NAVIERA"))
        ? "ARRIBO"
        : dano.condicion?.value ?? "";
  }

  bool _hasAdditionalInfo(Dano dano) {
    return (dano.descripcion != null && dano.descripcion!.isNotEmpty) ||
        dano.responsabilidad?.esp != null ||
        dano.nDocumento != null ||
        dano.createAt != null ||
        dano.createBy != null;
  }
}
