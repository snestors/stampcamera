// screens/autos/inventario/imagenes_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/screens/autos/inventario/simple_add_image_modal.dart';
import 'package:stampcamera/utils/debouncer.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';

class ImagenesTabWidget extends ConsumerStatefulWidget {
  final InventarioBaseResponse response;
  final int informacionUnidadId;

  const ImagenesTabWidget({
    super.key,
    required this.response,
    required this.informacionUnidadId,
  });

  @override
  ConsumerState<ImagenesTabWidget> createState() => _ImagenesTabWidgetState();
}

class _ImagenesTabWidgetState extends ConsumerState<ImagenesTabWidget> {
  final Map<int, Debouncer> _debounceMap = {};

  @override
  void dispose() {
    for (final debouncer in _debounceMap.values) {
      debouncer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: widget.response.hasImages
                ? _buildImagesList()
                : _buildEmptyState(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddImageModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.neutral)),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_library, color: AppColors.primary, size: 24),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imágenes del Inventario',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeL + 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.response.imageCount} imagen${widget.response.imageCount != 1 ? 'es' : ''} registrada${widget.response.imageCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LISTA DE IMÁGENES
  // ============================================================================

  Widget _buildImagesList() {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(inventarioDetalleProvider(widget.informacionUnidadId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.response.imagenes.length,
        itemBuilder: (context, index) {
          final imagen = widget.response.imagenes[index];
          return _buildImageListItem(context, imagen, index);
        },
      ),
    );
  }

  Widget _buildImageListItem(
    BuildContext context,
    InventarioImagen imagen,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Preview de imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imagen.hasValidImage
                    ? NetworkImagePreview(
                        thumbnailUrl: imagen.displayUrl!,
                        fullImageUrl: imagen.imagenUrl!,
                        size: 80,
                      )
                    : Container(
                        color: AppColors.surface,
                        child: Icon(
                          Icons.image,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Información de la imagen
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de descripción editable
                  TextField(
                    controller: TextEditingController(
                      text: imagen.descripcion ?? '',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Agregar descripción...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      // Crear debouncer para esta imagen si no existe
                      _debounceMap[imagen.id] ??= Debouncer(
                        delay: const Duration(milliseconds: 500),
                      );

                      // Ejecutar con debounce
                      _debounceMap[imagen.id]!.run(() {
                        _updateImageDescription(context, imagen.id, value, ref);
                      });
                    },
                    onSubmitted: (value) {
                      _updateImageDescription(context, imagen.id, value, ref);
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        imagen.createAt ?? 'Fecha no disponible',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (imagen.createBy != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            imagen.createBy ?? 'Usuario no disponible',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Botones de acción
            Column(
              children: [
                IconButton(
                  onPressed: () => _confirmDeleteImage(context, imagen),
                  icon: const Icon(Icons.delete),
                  color: AppColors.error,
                  iconSize: 20,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ESTADO VACÍO
  // ============================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay imágenes registradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar la primera imagen del inventario',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Icon(Icons.arrow_downward, size: 32, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MODALES
  // ============================================================================

  void _showAddImageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SimpleAddImageModal(
        informacionUnidadId: widget.informacionUnidadId,
        onImageAdded: () {
          ref.invalidate(inventarioDetalleProvider(widget.informacionUnidadId));
        },
      ),
    );
  }

  // ============================================================================
  // ELIMINACIÓN DE IMÁGENES
  // ============================================================================

  Future<void> _confirmDeleteImage(
    BuildContext context,
    InventarioImagen imagen,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar imagen',
      message: '¿Estás seguro de que quieres eliminar esta imagen? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDanger: true,
    );

    if (confirmed == true && context.mounted) {
      await _deleteImage(context, imagen);
    }
  }

  Future<void> _deleteImage(
    BuildContext context,
    InventarioImagen imagen,
  ) async {
    // Mostrar loading
    AppDialog.loading(context, message: 'Eliminando imagen...');

    try {
      final notifier = ref.read(
        inventarioDetalleProvider(widget.informacionUnidadId).notifier,
      );

      await notifier.deleteImage(imagen.id);

      if (context.mounted) {
        AppDialog.closeLoading(context);

        // Actualizar automáticamente la lista
        ref.invalidate(inventarioDetalleProvider(widget.informacionUnidadId));

        AppSnackBar.success(context, 'Imagen eliminada exitosamente');
      }
    } catch (e) {
      if (context.mounted) {
        AppDialog.closeLoading(context);
        AppSnackBar.error(context, 'Error al eliminar imagen: $e');
      }
    }
  }

  // ============================================================================
  // ACTUALIZACIÓN DE DESCRIPCIÓN
  // ============================================================================

  void _updateImageDescription(
    BuildContext context,
    int imageId,
    String description,
    WidgetRef ref,
  ) async {
    try {
      final imageNotifier = ref.read(
        inventarioImageProvider(widget.informacionUnidadId).notifier,
      );

      await imageNotifier.updateImage(
        imageId: imageId,
        descripcion: description.trim(),
      );

      // Actualizar la lista después de editar
      ref.invalidate(inventarioDetalleProvider(widget.informacionUnidadId));

      if (context.mounted) {
        AppSnackBar.success(context, 'Descripción actualizada');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Error al actualizar: $e');
      }
    }
  }
}
