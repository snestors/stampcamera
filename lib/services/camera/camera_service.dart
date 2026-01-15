import 'dart:io';
import 'dart:ui' show Offset;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stampcamera/config/camera/camera_config.dart';
import 'package:stampcamera/utils/image_processor.dart';

/// Resultado de una operación de cámara
class CameraResult {
  final bool success;
  final String? imagePath;
  final String? processedPath;
  final String? error;
  final Duration? processingTime;

  const CameraResult({
    required this.success,
    this.imagePath,
    this.processedPath,
    this.error,
    this.processingTime,
  });

  factory CameraResult.success({
    required String imagePath,
    String? processedPath,
    Duration? processingTime,
  }) {
    return CameraResult(
      success: true,
      imagePath: imagePath,
      processedPath: processedPath ?? imagePath,
      processingTime: processingTime,
    );
  }

  factory CameraResult.failure(String error) {
    return CameraResult(success: false, error: error);
  }

  factory CameraResult.cancelled() {
    return const CameraResult(success: false, error: 'Operación cancelada');
  }
}

/// Opciones para captura de imagen
class CaptureOptions {
  final WatermarkConfig watermarkConfig;
  final ResolutionPreset resolution;
  final bool enableAudio;
  final ImageSource source;

  const CaptureOptions({
    this.watermarkConfig = WatermarkPresets.camera,
    this.resolution = ResolutionPreset.high,
    this.enableAudio = false,
    this.source = ImageSource.camera,
  });

  CaptureOptions copyWith({
    WatermarkConfig? watermarkConfig,
    ResolutionPreset? resolution,
    bool? enableAudio,
    ImageSource? source,
  }) {
    return CaptureOptions(
      watermarkConfig: watermarkConfig ?? this.watermarkConfig,
      resolution: resolution ?? this.resolution,
      enableAudio: enableAudio ?? this.enableAudio,
      source: source ?? this.source,
    );
  }
}

/// Servicio centralizado de cámara
///
/// Proporciona una interfaz unificada para:
/// - Capturar fotos con la cámara
/// - Seleccionar imágenes de la galería
/// - Procesar imágenes con watermark
/// - Guardar imágenes procesadas
///
/// Uso:
/// ```dart
/// final service = CameraService();
///
/// // Capturar desde cámara
/// final result = await service.captureFromCamera(
///   config: WatermarkPresets.camera,
/// );
///
/// // Seleccionar desde galería
/// final result = await service.pickFromGallery(
///   config: WatermarkPresets.gallery,
/// );
///
/// // Procesar imagen existente
/// final processedPath = await service.processImage(
///   imagePath: '/path/to/image.jpg',
///   config: WatermarkPresets.withGps,
/// );
/// ```
class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();

  CameraService._();
  factory CameraService() => instance;

  final ImagePicker _picker = ImagePicker();
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  /// Verifica si el servicio está inicializado
  bool get isInitialized => _isInitialized;

  /// Obtiene las cámaras disponibles
  List<CameraDescription> get cameras => _cameras ?? [];

  /// Obtiene el controlador actual de la cámara
  CameraController? get controller => _controller;

  // ═══════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════

  /// Inicializa el servicio de cámara
  ///
  /// Debe llamarse antes de usar cualquier funcionalidad de cámara.
  /// Normalmente se llama en el initState de la pantalla de cámara.
  Future<bool> initialize({
    ResolutionPreset resolution = ResolutionPreset.high,
    int cameraIndex = 0,
  }) async {
    try {
      // Inicializar procesador de imágenes (carga logo en caché)
      await ImageProcessor().initialize();

      // Obtener cámaras disponibles
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('CameraService: No se encontraron cámaras');
        return false;
      }

      // Crear controlador
      final cameraToUse = _cameras![cameraIndex.clamp(0, _cameras!.length - 1)];
      _controller = CameraController(
        cameraToUse,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;

      debugPrint('CameraService: Inicializado correctamente');
      return true;
    } catch (e) {
      debugPrint('CameraService: Error al inicializar: $e');
      return false;
    }
  }

  /// Libera recursos del servicio
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  // ═══════════════════════════════════════════════════════════════════
  // CAPTURA Y SELECCIÓN
  // ═══════════════════════════════════════════════════════════════════

  /// Captura una foto con la cámara
  ///
  /// Retorna un [CameraResult] con la ruta de la imagen procesada.
  Future<CameraResult> captureFromCamera({
    WatermarkConfig config = WatermarkPresets.camera,
  }) async {
    if (!_isInitialized || _controller == null) {
      return CameraResult.failure('Cámara no inicializada');
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Capturar imagen
      final XFile file = await _controller!.takePicture();

      // Procesar con watermark
      final processedPath = await processImage(
        imagePath: file.path,
        config: config,
      );

      stopwatch.stop();

      if (processedPath != null) {
        return CameraResult.success(
          imagePath: file.path,
          processedPath: processedPath,
          processingTime: stopwatch.elapsed,
        );
      } else {
        return CameraResult.failure('Error al procesar imagen');
      }
    } catch (e) {
      debugPrint('CameraService: Error al capturar: $e');
      return CameraResult.failure('Error al capturar: $e');
    }
  }

  /// Selecciona una imagen de la galería
  ///
  /// [applyWatermark] determina si se aplica watermark a la imagen.
  Future<CameraResult> pickFromGallery({
    WatermarkConfig config = WatermarkPresets.gallery,
    bool applyWatermark = true,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Seleccionar imagen
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Máxima calidad, comprimimos después
      );

      if (file == null) {
        return CameraResult.cancelled();
      }

      String finalPath = file.path;

      // Procesar si se requiere watermark
      if (applyWatermark) {
        final processedPath = await processImage(
          imagePath: file.path,
          config: config,
        );

        if (processedPath != null) {
          finalPath = processedPath;
        }
      }

      stopwatch.stop();

      return CameraResult.success(
        imagePath: file.path,
        processedPath: finalPath,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      debugPrint('CameraService: Error al seleccionar de galería: $e');
      return CameraResult.failure('Error al seleccionar imagen: $e');
    }
  }

  /// Selecciona múltiples imágenes de la galería
  Future<List<CameraResult>> pickMultipleFromGallery({
    WatermarkConfig config = WatermarkPresets.gallery,
    bool applyWatermark = true,
    int? limit,
  }) async {
    try {
      // Seleccionar imágenes
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 100,
        limit: limit,
      );

      if (files.isEmpty) {
        return [CameraResult.cancelled()];
      }

      final results = <CameraResult>[];

      for (final file in files) {
        String finalPath = file.path;

        if (applyWatermark) {
          final processedPath = await processImage(
            imagePath: file.path,
            config: config,
          );
          if (processedPath != null) {
            finalPath = processedPath;
          }
        }

        results.add(CameraResult.success(
          imagePath: file.path,
          processedPath: finalPath,
        ));
      }

      return results;
    } catch (e) {
      debugPrint('CameraService: Error al seleccionar múltiples: $e');
      return [CameraResult.failure('Error al seleccionar imágenes: $e')];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROCESAMIENTO
  // ═══════════════════════════════════════════════════════════════════

  /// Procesa una imagen con watermark
  ///
  /// Aplica logo, timestamp y/o ubicación según la configuración.
  /// Retorna la ruta de la imagen procesada o null si falla.
  Future<String?> processImage({
    required String imagePath,
    required WatermarkConfig config,
  }) async {
    try {
      // Verificar que el archivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('CameraService: Archivo no existe: $imagePath');
        return null;
      }

      // Convertir WatermarkConfig local a formato del procesador
      final processorConfig = _convertToProcessorConfig(config);

      // Procesar imagen
      final processedPath = await processImageWithWatermark(
        imagePath,
        config: processorConfig,
      );

      return processedPath;
    } catch (e) {
      debugPrint('CameraService: Error al procesar imagen: $e');
      return null;
    }
  }

  /// Procesa múltiples imágenes con la misma configuración
  Future<List<String?>> processMultipleImages({
    required List<String> imagePaths,
    required WatermarkConfig config,
  }) async {
    final results = <String?>[];

    for (final path in imagePaths) {
      final processedPath = await processImage(
        imagePath: path,
        config: config,
      );
      results.add(processedPath);
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTROL DE CÁMARA
  // ═══════════════════════════════════════════════════════════════════

  /// Cambia el modo de flash
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null && _isInitialized) {
      await _controller!.setFlashMode(mode);
    }
  }

  /// Cambia entre cámara frontal y trasera
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return false;

    final currentIndex = _cameras!.indexOf(_controller!.description);
    final newIndex = (currentIndex + 1) % _cameras!.length;

    await _controller?.dispose();

    _controller = CameraController(
      _cameras![newIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    return true;
  }

  /// Enfoca en un punto específico
  Future<void> setFocusPoint(Offset point) async {
    if (_controller != null && _isInitialized) {
      try {
        await _controller!.setFocusPoint(point);
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('CameraService: Error al enfocar: $e');
      }
    }
  }

  /// Ajusta el zoom
  Future<void> setZoom(double zoom) async {
    if (_controller != null && _isInitialized) {
      final minZoom = await _controller!.getMinZoomLevel();
      final maxZoom = await _controller!.getMaxZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // UTILIDADES PRIVADAS
  // ═══════════════════════════════════════════════════════════════════

  /// Convierte WatermarkConfig local a formato del procesador existente
  // ignore: unused_element
  dynamic _convertToProcessorConfig(WatermarkConfig config) {
    // El procesador existente usa su propia clase WatermarkConfig
    // Esta función mapea entre las dos versiones
    // TODO: Unificar cuando se refactorice image_processor.dart completamente
    return config;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EXTENSIONES DE CONVENIENCIA
// ═══════════════════════════════════════════════════════════════════════

extension CameraResultExtension on CameraResult {
  /// Verifica si la operación fue exitosa y tiene una imagen procesada
  bool get hasProcessedImage => success && processedPath != null;

  /// Obtiene el archivo procesado o null
  File? get processedFile =>
      processedPath != null ? File(processedPath!) : null;
}
