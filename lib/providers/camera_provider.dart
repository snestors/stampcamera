import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/config/camera/camera_config.dart';
import 'package:stampcamera/utils/image_processor.dart';

class CameraState {
  final bool isReady;
  final FlashMode flashMode;
  final List<File> imagenes;
  final int processingCount; // Cuántas fotos se están procesando
  final String? lastCapturedPath; // Para animación de foto bajando

  CameraState({
    this.isReady = false,
    this.flashMode = FlashMode.off,
    this.imagenes = const [],
    this.processingCount = 0,
    this.lastCapturedPath,
  });

  bool get isProcessing => processingCount > 0;

  CameraState copyWith({
    bool? isReady,
    FlashMode? flashMode,
    List<File>? imagenes,
    int? processingCount,
    String? lastCapturedPath,
  }) {
    return CameraState(
      isReady: isReady ?? this.isReady,
      flashMode: flashMode ?? this.flashMode,
      imagenes: imagenes ?? this.imagenes,
      processingCount: processingCount ?? this.processingCount,
      lastCapturedPath: lastCapturedPath ?? this.lastCapturedPath,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier(this._camera) : super(CameraState()) {
    _init();
  }

  final CameraDescription _camera;
  CameraController? _controller;
  bool _isCapturing = false; // Previene capturas simultáneas

  CameraController get controller => _controller!;

  Future<void> _init() async {
    try {
      _controller = CameraController(
        _camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Precargar el procesador de imágenes (carga logo en caché)
      await ImageProcessor().initialize();

      await _loadImages();
      state = state.copyWith(isReady: true);
    } catch (e) {
      print('❌ Error inicializando cámara: $e');
    }
  }

  Future<void> _loadImages() async {
    final dir = Directory('/storage/emulated/0/DCIM/StampCamera');
    if (!await dir.exists()) return;

    final files = dir.listSync()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final fotos = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
        .toList();

    state = state.copyWith(imagenes: fotos);
  }

  Future<void> _processInBackground(String path) async {
    try {
      // Usar configuración centralizada desde WatermarkPresets
      final processedPath = await processImageWithWatermark(path, config: WatermarkPresets.camera);

      await _loadImages();

      // Decrementar contador y actualizar última foto
      state = state.copyWith(
        processingCount: (state.processingCount - 1).clamp(0, 100),
        lastCapturedPath: processedPath,
      );
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error al procesar en segundo plano: $e');
      state = state.copyWith(
        processingCount: (state.processingCount - 1).clamp(0, 100),
      );
    }
  }

  Future<void> takePicture() async {
    // Prevenir capturas simultáneas (evita crashes)
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    _isCapturing = true;

    try {
      final picture = await _controller!.takePicture();

      // Incrementar contador de procesamiento
      state = state.copyWith(processingCount: state.processingCount + 1);

      // Procesar en background SIN esperar (permite tomar más fotos)
      _processInBackground(picture.path);
    } catch (e) {
      print('❌ Error al tomar foto: $e');
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> deleteFiles(List<File> filesToDelete) async {
    final newList = <File>[];

    for (final file in state.imagenes) {
      if (filesToDelete.contains(file)) {
        if (await file.exists()) await file.delete();
      } else {
        newList.add(file);
      }
    }

    state = state.copyWith(imagenes: newList);
  }

  Future<void> deleteImageAtIndex(int index) async {
    if (index < 0 || index >= state.imagenes.length) return;

    final file = state.imagenes[index];
    if (await file.exists()) await file.delete();

    final newList = List<File>.from(state.imagenes)..removeAt(index);
    state = state.copyWith(imagenes: newList);
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final newMode = state.flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await _controller!.setFlashMode(newMode);
      state = state.copyWith(flashMode: newMode);
    } catch (e) {
      print('❌ Error al cambiar flash: $e');
    }
  }

  void updateImages(List<File> newList) {
    state = state.copyWith(imagenes: newList);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

final cameraProvider = StateNotifierProvider.autoDispose
    .family<CameraNotifier, CameraState, CameraDescription>(
      (ref, camera) => CameraNotifier(camera),
    );
