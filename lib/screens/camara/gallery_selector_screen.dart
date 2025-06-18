import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class GallerySelectorScreen extends StatefulWidget {
  final List<File> images;
  const GallerySelectorScreen({super.key, required this.images});

  @override
  State<GallerySelectorScreen> createState() => _GallerySelectorScreenState();
}

class _GallerySelectorScreenState extends State<GallerySelectorScreen> {
  late List<File> _images;
  final List<File> selected = [];

  @override
  void initState() {
    super.initState();
    _images = List<File>.from(widget.images);
  }

  void _toggleSelection(File image) {
    setState(() {
      if (selected.contains(image)) {
        selected.remove(image);
      } else {
        selected.add(image);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selected.clear();
      selected.addAll(_images);
    });
  }

  void _deselectAll() {
    setState(() {
      selected.clear();
    });
  }

  Future<void> _shareSelected() async {
    if (selected.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se pueden compartir hasta 15 imágenes.')),
      );
      return;
    }

    final result = await SharePlus.instance.share(
      ShareParams(files: selected.map((f) => XFile(f.path)).toList()),
    );

    if (result.status == ShareResultStatus.success) {
      debugPrint('Compartido');
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
        content: Text('Se eliminarán ${selected.length} imágenes seleccionadas. ¿Deseas continuar?'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          TextButton(child: const Text('Eliminar'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _images.removeWhere((img) => selected.contains(img));
        selected.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionadas: ${selected.length}'),
        actions: [
          if (selected.length < _images.length)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Seleccionar todo',
              onPressed: _selectAll,
            ),
          if (selected.isNotEmpty)
            ...[
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
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: selected.isEmpty ? null : _shareSelected,
          ),
        ],
      ),
      body: _images.isEmpty
          ? const Center(child: Text('No hay imágenes'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final image = _images[index];
                final isSelected = selected.contains(image);
                return GestureDetector(
                  onTap: () => _toggleSelection(image),
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
                          child: Icon(Icons.check_circle, color: Colors.lightBlueAccent),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
