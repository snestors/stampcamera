import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import '../../providers/camera_provider.dart';

class GallerySelectorScreen extends ConsumerStatefulWidget {
  final CameraDescription camera;

  const GallerySelectorScreen({super.key, required this.camera});

  @override
  ConsumerState<GallerySelectorScreen> createState() =>
      _GallerySelectorScreenState();
}

class _GallerySelectorScreenState extends ConsumerState<GallerySelectorScreen> {
  final List<File> selected = [];
  bool isSelecting = false;

  void _toggleSelection(File image) {
    setState(() {
      if (selected.contains(image)) {
        selected.remove(image);
      } else {
        selected.add(image);
      }
    });
  }

  void _selectAll(List<File> all) {
    setState(() {
      selected.clear();
      selected.addAll(all);
      isSelecting = true;
    });
  }

  void _deselectAll() {
    setState(() {
      selected.clear();
      isSelecting = false;
    });
  }

  Future<void> _shareSelected() async {
    if (selected.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden compartir hasta 15 imágenes.'),
        ),
      );
      return;
    }

    final result = await SharePlus.instance.share(
      ShareParams(files: selected.map((f) => XFile(f.path)).toList()),
    );

    if (result.status == ShareResultStatus.success) {
      debugPrint('✅ Compartido');
    }

    if (!mounted) return;
    Navigator.pop(context, selected);
  }

  Future<void> _deleteSelected() async {
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar imágenes?'),
        content: Text(
          'Se eliminarán ${selected.length} imágenes seleccionadas. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Eliminar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(cameraProvider(widget.camera).notifier);
      await notifier.deleteFiles(selected);
      _deselectAll();
    }
  }

  void _onImageTap(File image, int index) {
    if (isSelecting) {
      _toggleSelection(image);
    } else {
      context.pop(index); // Devuelve index a FullscreenImage
    }
  }

  void _onImageLongPress(File image) {
    if (!isSelecting) {
      setState(() {
        isSelecting = true;
        selected.add(image);
      });
    } else {
      _toggleSelection(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraProvider(widget.camera));
    final images = state.imagenes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelecting
              ? 'Seleccionadas: ${selected.length}'
              : 'Galería (${images.length})',
        ),
        actions: [
          if (isSelecting && selected.length < images.length)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Seleccionar todo',
              onPressed: () => _selectAll(images),
            ),
          if (isSelecting && selected.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Deseleccionar todo',
              onPressed: _deselectAll,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Eliminar seleccionados',
              onPressed: _deleteSelected,
            ),
          ],
          if (isSelecting)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: selected.isEmpty ? null : _shareSelected,
            ),
        ],
      ),
      body: images.isEmpty
          ? const Center(child: Text('No hay imágenes'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final image = images[index];
                final isSelected = selected.contains(image);
                return GestureDetector(
                  onTap: () => _onImageTap(image, index),
                  onLongPress: () => _onImageLongPress(image),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(image, fit: BoxFit.cover),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
