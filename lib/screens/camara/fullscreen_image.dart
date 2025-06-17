import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stampcamera/screens/camara/gallery_selector_screen.dart';

class FullscreenImage extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  const FullscreenImage({super.key, required this.images, required this.initialIndex});

  @override
  State<FullscreenImage> createState() => _FullscreenImageState();
}

class _FullscreenImageState extends State<FullscreenImage> {
  late PageController _pageController;
  late int _currentIndex;
  late List<File> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<void> _deleteCurrentImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Borrar imagen?'),
        content: const Text('¿Estás seguro de que deseas eliminar esta imagen?'),
        actions: [
          
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar')),
        ],
      ),
    );

    if (confirm != true) return;

    final file = _images[_currentIndex];
    if (await file.exists()) await file.delete();

    setState(() {
      _images.removeAt(_currentIndex);
      if (_currentIndex >= _images.length) {
        _currentIndex = _images.length - 1;
      }
    });

    if (!mounted) return;
    if (_images.isEmpty) {
      Navigator.pop(context, <File>[]);
    }
  }

  Future<void> _shareCurrentImage() async {
    final file = _images[_currentIndex];
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );

    if (result.status == ShareResultStatus.success) {
      debugPrint('¡Gracias por compartir!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _images),
        ),
        actions: [
          IconButton(
    icon: const Icon(Icons.select_all),
    tooltip: 'Seleccionar para compartir',
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GallerySelectorScreen(images: _images),
        ),
      );
      if (result != null && result is List<File>) {
        // puedes hacer algo con los archivos compartidos, si quieres
      }
    },
  ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Borrar',
            onPressed: _images.isEmpty ? null : _deleteCurrentImage,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: _images.isEmpty ? null : _shareCurrentImage,
          ),
        ],
      ),
      body: SafeArea(
        child: _images.isEmpty
            ? const Center(
                child: Text(
                  'Sin imágenes',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.file(
                        _images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

