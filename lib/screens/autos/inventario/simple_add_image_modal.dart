// widgets/autos/inventario/simple_add_image_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';

class SimpleAddImageModal extends ConsumerStatefulWidget {
  final int informacionUnidadId;
  final VoidCallback? onImageAdded;

  const SimpleAddImageModal({
    super.key,
    required this.informacionUnidadId,
    this.onImageAdded,
  });

  @override
  ConsumerState<SimpleAddImageModal> createState() =>
      _SimpleAddImageModalState();
}

class _SimpleAddImageModalState extends ConsumerState<SimpleAddImageModal> {
  final bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: keyboardHeight + 20,
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [_buildMultipleImagesSection()]),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.add_a_photo, color: Color(0xFF003B5C), size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Agregar Imagen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildMultipleImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Imágenes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona una o varias imágenes desde la galería',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickMultipleImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar Imágenes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B5C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE ACCIÓN
  // ============================================================================

  Future<void> _pickMultipleImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 90, limit: 10);

      if (images.isNotEmpty && mounted) {
        // NO cerrar el modal aquí, esperar a que termine el proceso
        await _processMultipleImages(images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al seleccionar imágenes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processMultipleImages(List<XFile> images) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Subiendo ${images.length} imágenes...'),
          ],
        ),
      ),
    );

    try {
      final imagePaths = images.map((image) => image.path).toList();
      final descriptions = <String>[];

      for (int i = 0; i < images.length; i++) {
        descriptions.add('');
      }

      final imageNotifier = ref.read(
        inventarioImageProvider(widget.informacionUnidadId).notifier,
      );

      await imageNotifier.addMultipleImages(
        imagePaths: imagePaths,
        descripciones: descriptions,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        Navigator.pop(context); // Cerrar modal principal
        widget.onImageAdded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${images.length} imágenes agregadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
