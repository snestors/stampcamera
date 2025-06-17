import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:stampcamera/screens/camara/fullscreen_image.dart';
import '../../utils/image_processor.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isReady = false;
  bool _isProcessing = false;
  List<File> imagenes = [];

  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _controller.initialize().then((_) async {
      if (!mounted) return;
      setState(() => _isReady = true);
      _cargarImagenes();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarImagenes() async {
    final dir = Directory('/storage/emulated/0/DCIM/MiEmpresa');
    if (!await dir.exists()) return;

    final files = dir.listSync()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final fotos = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
        .toList();

    setState(() => imagenes = fotos);
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final picture = await _controller.takePicture();
      await processAndSaveImage(picture.path);
      await _cargarImagenes();
    } catch (e) {
      debugPrint('❌ Error al tomar/guardar la foto: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _toggleFlash() async {
    setState(() {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    });
    await _controller.setFlashMode(_flashMode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Cámara', style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, imagenes),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    CameraPreview(_controller),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton(
                          onPressed: _isProcessing ? null : _takePicture,
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : const Icon(Icons.camera_alt),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 100,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: imagenes.isEmpty
                    ? const Center(
                        child: Text(
                          "Sin fotos aún",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        scrollDirection: Axis.horizontal,
                        itemCount: imagenes.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () async {
                              final updatedList = await Navigator.push<List<File>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullscreenImage(
                                    images: imagenes,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                              if (updatedList != null &&
                                  updatedList.length != imagenes.length) {
                                setState(() => imagenes = updatedList);
                              }
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  imagenes[index],
                                  width: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
