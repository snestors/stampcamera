import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../providers/camera_provider.dart';

class FullscreenImage extends ConsumerStatefulWidget {
  final int initialIndex;
  final CameraDescription camera;

  const FullscreenImage({
    super.key,
    required this.camera,
    required this.initialIndex,
  });

  @override
  ConsumerState<FullscreenImage> createState() => _FullscreenImageState();
}

class _FullscreenImageState extends ConsumerState<FullscreenImage> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Borrar imagen?'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta imagen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final notifier = ref.read(cameraProvider(widget.camera).notifier);
    await notifier.deleteImageAtIndex(_currentIndex);

    final updatedList = ref.read(cameraProvider(widget.camera)).imagenes;
    if (updatedList.isEmpty && mounted) {
      context.goNamed('camera', extra: widget.camera);
    } else {
      setState(() {
        _currentIndex = _currentIndex.clamp(0, updatedList.length - 1);
      });
    }
  }

  Future<void> _shareCurrentImage(File file) async {
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );

    if (result.status == ShareResultStatus.success) {
      debugPrint('✅ Compartido con éxito');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraProvider(widget.camera));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // o .maybePop() si es necesario
            if (!context.mounted) return;
            context.pushNamed('camera', extra: {'camera': widget.camera});
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Seleccionar para compartir',
            onPressed: () {
              context.pushNamed('gallery', extra: {'camera': widget.camera});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Borrar',
            onPressed: state.imagenes.isEmpty ? null : () => _confirmDelete(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: state.imagenes.isEmpty
                ? null
                : () => _shareCurrentImage(state.imagenes[_currentIndex]),
          ),
        ],
      ),
      body: SafeArea(
        child: state.imagenes.isEmpty
            ? const Center(
                child: Text(
                  'Sin imágenes',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : PageView.builder(
                controller: _pageController,
                itemCount: state.imagenes.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _transformationController.value = Matrix4.identity();
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onDoubleTapDown: (details) => _doubleTapDetails = details,
                    onDoubleTap: _handleDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Center(
                        child: Image.file(
                          state.imagenes[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
