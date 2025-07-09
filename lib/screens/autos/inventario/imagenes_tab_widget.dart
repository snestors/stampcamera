// screens/autos/inventario/imagenes_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        backgroundColor: const Color(0xFF003B5C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_library, color: const Color(0xFF003B5C), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imágenes del Inventario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.response.imageCount} imagen${widget.response.imageCount != 1 ? 'es' : ''} registrada${widget.response.imageCount != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
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
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        imagen.createAt ?? 'Fecha no disponible',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            imagen.createBy ?? 'Usuario no disponible',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
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
                  color: Colors.red,
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
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay imágenes registradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar la primera imagen del inventario',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Icon(Icons.arrow_downward, size: 32, color: Colors.grey.shade400),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta imagen? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Eliminando imagen...'),
          ],
        ),
      ),
    );

    try {
      final notifier = ref.read(
        inventarioDetalleProvider(widget.informacionUnidadId).notifier,
      );

      await notifier.deleteImage(imagen.id);

      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading

        // Actualizar automáticamente la lista
        ref.invalidate(inventarioDetalleProvider(widget.informacionUnidadId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Imagen eliminada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Descripción actualizada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
