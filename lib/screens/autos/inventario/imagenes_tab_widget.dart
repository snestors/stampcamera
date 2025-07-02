import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';

class ImagenesTabWidget extends ConsumerWidget {
  final InventarioBaseResponse response;
  final int informacionUnidadId;

  const ImagenesTabWidget({
    super.key,
    required this.response,
    required this.informacionUnidadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!response.hasImages) {
      return _buildEmptyState(context, ref);
    }

    return _buildImagenesContent(context, ref);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
                Icons.photo_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'No hay imágenes registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Esta unidad aún no tiene imágenes del inventario.\nPuedes agregar fotos ahora.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addSingleImage(context, ref),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                ElevatedButton.icon(
                  onPressed: () => _addMultipleImages(context, ref),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenesContent(BuildContext context, WidgetRef ref) {
    final imagenes = response.imagenes;

    return Column(
      children: [
        // Header con controles
        _buildImagenesHeader(context, ref),

        // Grid de imágenes
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: imagenes.length,
            itemBuilder: (context, index) {
              final imagen = imagenes[index];
              return _buildImageCard(context, ref, imagen);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagenesHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imágenes del Inventario',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${response.imageCount} foto${response.imageCount != 1 ? 's' : ''} registrada${response.imageCount != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Botones de acción
          Row(
            children: [
              IconButton(
                onPressed: () => _addSingleImage(context, ref),
                icon: const Icon(Icons.camera_alt),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF003B5C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Tomar foto',
              ),

              const SizedBox(width: 8),

              IconButton(
                onPressed: () => _addMultipleImages(context, ref),
                icon: const Icon(Icons.photo_library),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Seleccionar de galería',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    WidgetRef ref,
    InventarioImagen imagen,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen
          Expanded(
            child: Stack(
              children: [
                // Imagen principal
                imagen.hasValidImage
                    ? Image.network(
                        imagen.displayUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                // Botón de eliminar
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () => _deleteImage(context, ref, imagen),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ),

                // Overlay de tap para ver en grande
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _viewImageFullscreen(context, imagen),
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información de la imagen
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imagen.descripcion != null &&
                    imagen.descripcion!.isNotEmpty)
                  Text(
                    imagen.descripcion!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Sin descripción',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        imagen.createAt ?? 'Fecha no disponible',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (imagen.createBy != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _extractUserName(imagen.createBy!),
                          style: TextStyle(
                            fontSize: 10,
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
        ],
      ),
    );
  }

  String _extractUserName(String fullUserInfo) {
    // Extraer solo el nombre del formato "Apellido, Nombre (email)"
    final match = RegExp(r'^([^(]+)').firstMatch(fullUserInfo);
    return match?.group(1)?.trim() ?? fullUserInfo;
  }

  void _addSingleImage(BuildContext context, WidgetRef ref) {
    // TODO: Implementar funcionalidad de tomar foto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚧 Funcionalidad de cámara en desarrollo')),
    );
  }

  void _addMultipleImages(BuildContext context, WidgetRef ref) {
    // TODO: Implementar funcionalidad de seleccionar múltiples imágenes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Funcionalidad de galería en desarrollo'),
      ),
    );
  }

  void _deleteImage(
    BuildContext context,
    WidgetRef ref,
    InventarioImagen imagen,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta imagen? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteImage(context, ref, imagen);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteImage(
    BuildContext context,
    WidgetRef ref,
    InventarioImagen imagen,
  ) {
    // TODO: Implementar eliminación real
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Funcionalidad de eliminación en desarrollo'),
      ),
    );
  }

  void _viewImageFullscreen(BuildContext context, InventarioImagen imagen) {
    if (!imagen.hasValidImage) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Imagen en pantalla completa
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imagen.imagenUrl!, // Usar imagen original, no thumbnail
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Botón de cerrar
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

            // Información de la imagen (opcional)
            if (imagen.descripcion != null && imagen.descripcion!.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    imagen.descripcion!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
