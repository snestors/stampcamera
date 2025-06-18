import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/image_processor.dart';

class CameraState {
  final bool isReady;
  final bool isProcessing;
  final FlashMode flashMode;
  final List<File> imagenes;

  CameraState({
    this.isReady = false,
    this.isProcessing = false,
    this.flashMode = FlashMode.off,
    this.imagenes = const [],
  });

  CameraState copyWith({
    bool? isReady,
    bool? isProcessing,
    FlashMode? flashMode,
    List<File>? imagenes,
  }) {
    return CameraState(
      isReady: isReady ?? this.isReady,
      isProcessing: isProcessing ?? this.isProcessing,
      flashMode: flashMode ?? this.flashMode,
      imagenes: imagenes ?? this.imagenes,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier(this._camera) : super(CameraState()) {
    _init();
  }

  final CameraDescription _camera;
  late CameraController controller;

  Future<void> _init() async {
    controller = CameraController(_camera, ResolutionPreset.high);
    await controller.initialize();
    await _loadImages();
    state = state.copyWith(isReady: true);
  }

  Future<void> _loadImages() async {
    final dir = Directory('/storage/emulated/0/DCIM/MiEmpresa');
    if (!await dir.exists()) return;

    final files = dir.listSync()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final fotos = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
        .toList();

    state = state.copyWith(imagenes: fotos);
  }

  Future<void> takePicture() async {
    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true);

    try {
      final picture = await controller.takePicture();
      await processAndSaveImage(picture.path);
      await _loadImages();
    } catch (e) {
      print('❌ Error al tomar foto: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
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
    final newMode = state.flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    await controller.setFlashMode(newMode);
    state = state.copyWith(flashMode: newMode);
  }

  void updateImages(List<File> newList) {
    state = state.copyWith(imagenes: newList);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

final cameraProvider = StateNotifierProvider.autoDispose
    .family<CameraNotifier, CameraState, CameraDescription>(
      (ref, camera) => CameraNotifier(camera),
    );
