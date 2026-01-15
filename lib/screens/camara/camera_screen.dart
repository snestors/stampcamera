import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import '../../providers/camera_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  String? _animatingImagePath;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _slideAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerCaptureAnimation(String imagePath) {
    setState(() => _animatingImagePath = imagePath);
    _animController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _animatingImagePath = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraProvider(widget.camera));
    final notifier = ref.read(cameraProvider(widget.camera).notifier);

    // Escuchar cambios en lastCapturedPath para la animación
    ref.listen<CameraState>(cameraProvider(widget.camera), (prev, next) {
      if (next.lastCapturedPath != null &&
          prev?.lastCapturedPath != next.lastCapturedPath &&
          !next.isProcessing) {
        _triggerCaptureAnimation(next.lastCapturedPath!);
      }
    });

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Cámara', style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              state.flashMode == FlashMode.off
                  ? Icons.flash_off
                  : Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: notifier.toggleFlash,
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // Preview de cámara
                        state.isReady
                            ? CameraPreview(notifier.controller)
                            : const SizedBox.expand(
                                child: ColoredBox(color: Colors.black),
                              ),

                        // Botón de captura centrado
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: FloatingActionButton(
                                heroTag: 'capture_btn',
                                backgroundColor: Colors.white,
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  notifier.takePicture();
                                },
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Carrusel de fotos
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header del carrusel con indicador y botón galería
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              // Indicador de procesamiento
                              if (state.isProcessing)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Procesando ${state.processingCount}...',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              const Spacer(),
                              // Contador de fotos
                              Text(
                                '${state.imagenes.length} fotos',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Botón ver galería completa
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(
                                    'gallery',
                                    extra: {'camera': widget.camera},
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.grid_view,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ver todo',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lista de imágenes
                        Expanded(
                          child: state.imagenes.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Sin fotos aún",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  itemCount: state.imagenes.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        context.pushNamed(
                                          'fullscreen',
                                          extra: {
                                            'camera': widget.camera,
                                            'index': index,
                                          },
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            state.imagenes[index],
                                            width: 70,
                                            height: 70,
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
                ],
              ),

              // Animación de foto bajando
              if (_animatingImagePath != null)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Positioned(
                      top: _slideAnim.value * (screenSize.height - 200),
                      left: screenSize.width / 2 -
                          (screenSize.width * 0.4 * _scaleAnim.value) / 2,
                      child: Opacity(
                        opacity: 1.0 - (_slideAnim.value * 0.5),
                        child: Container(
                          width: screenSize.width * 0.4 * _scaleAnim.value,
                          height: screenSize.width * 0.5 * _scaleAnim.value,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_animatingImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.photo,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
