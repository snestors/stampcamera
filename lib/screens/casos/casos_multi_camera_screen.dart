// =============================================================================
// CASOS MULTI CAMERA SCREEN - Captura múltiple de fotos para subir a carpetas
// =============================================================================
//
// Pantalla de cámara que permite tomar varias fotos, ver miniaturas
// y confirmar para subirlas al explorador de carpetas.
// Retorna List<File> al hacer pop.
// =============================================================================

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:stampcamera/config/camera/camera_config.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/utils/image_processor.dart';

class CasosMultiCameraScreen extends StatefulWidget {
  const CasosMultiCameraScreen({super.key});

  @override
  State<CasosMultiCameraScreen> createState() => _CasosMultiCameraScreenState();
}

class _CasosMultiCameraScreenState extends State<CasosMultiCameraScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _initError;

  /// Fotos procesadas listas para subir
  final List<File> _capturedPhotos = [];

  /// Cantidad de fotos procesándose en background
  int _processingCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout al obtener cámaras'),
      );

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _initError = 'No se encontraron cámaras disponibles');
        }
        return;
      }

      // Intentar con resoluciones progresivamente menores
      final resolutions = [
        ResolutionPreset.veryHigh,
        ResolutionPreset.high,
        ResolutionPreset.medium,
      ];

      for (final resolution in resolutions) {
        try {
          await _cameraController?.dispose();
          _cameraController = CameraController(
            cameras.first,
            resolution,
            imageFormatGroup: ImageFormatGroup.jpeg,
            enableAudio: false,
          );

          await _cameraController!.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timeout al inicializar cámara'),
          );

          if (mounted) setState(() => _isInitialized = true);
          return;
        } catch (e) {
          debugPrint('Cámara: falló con resolución $resolution: $e');
        }
      }

      if (mounted) {
        setState(() => _initError = 'No se pudo inicializar la cámara');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _initError = 'Error al inicializar cámara: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController?.value.isInitialized != true || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final image = await _cameraController!.takePicture();

      // Incrementar procesando
      setState(() {
        _isCapturing = false;
        _processingCount++;
      });

      // Procesar con watermark en background
      final processedPath = await processImageWithWatermark(
        image.path,
        config: WatermarkPresets.camera,
        autoGPS: false,
      );

      if (mounted) {
        setState(() {
          _processingCount--;
          _capturedPhotos.add(File(processedPath));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _processingCount = (_processingCount - 1).clamp(0, 999);
        });
        AppSnackBar.error(context, 'Error al capturar: $e');
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _capturedPhotos.removeAt(index));
  }

  void _confirmAndReturn() {
    Navigator.of(context).pop(_capturedPhotos);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = _capturedPhotos.length;
    final hasPhotos = photoCount > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(null),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          hasPhotos ? '$photoCount foto${photoCount > 1 ? 's' : ''}' : 'Tomar fotos',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (hasPhotos)
            TextButton.icon(
              onPressed: _processingCount > 0 ? null : _confirmAndReturn,
              icon: Icon(
                Icons.check,
                color: _processingCount > 0 ? Colors.white38 : Colors.white,
              ),
              label: Text(
                _processingCount > 0 ? 'Espere...' : 'Listo',
                style: TextStyle(
                  color: _processingCount > 0 ? Colors.white38 : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview
            Expanded(child: _buildCameraPreview()),

            // Thumbnail strip
            if (hasPhotos || _processingCount > 0) _buildThumbnailStrip(),

            // Capture button
            _buildCaptureControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Error de cámara',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _initError!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _initError = null;
                    _isInitialized = false;
                  });
                  _initCamera();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Iniciando cámara...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 88,
      color: Colors.black87,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _capturedPhotos.length + (_processingCount > 0 ? _processingCount : 0),
        itemBuilder: (context, index) {
          // Fotos procesándose al final
          if (index >= _capturedPhotos.length) {
            return Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }

          // Foto ya procesada
          return GestureDetector(
            onLongPress: () => _showRemoveDialog(index),
            child: Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30, width: 1),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      _capturedPhotos[index],
                      fit: BoxFit.cover,
                      width: 72,
                      height: 72,
                    ),
                  ),
                  // Número de foto
                  Positioned(
                    bottom: 2,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRemoveDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: Text('¿Eliminar foto ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removePhoto(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Capture button
          GestureDetector(
            onTap: _isInitialized && !_isCapturing ? _takePicture : null,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCapturing ? Colors.grey : Colors.white,
                ),
                child: _isCapturing
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.black54,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
