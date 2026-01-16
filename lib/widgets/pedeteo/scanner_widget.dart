// widgets/pedeteo/scanner_widget.dart - OPTIMIZADO: Una sola cámara
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stampcamera/config/camera/camera_config.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/utils/image_processor.dart';

// 🎯 Enum para estados del proceso
enum ProcessingState {
  idle,
  vinDetected,
  processingImage,
  completed,
}

class PedeteoScannerWidget extends ConsumerStatefulWidget {
  const PedeteoScannerWidget({super.key});

  @override
  ConsumerState<PedeteoScannerWidget> createState() =>
      _PedeteoScannerWidgetState();
}

class _PedeteoScannerWidgetState extends ConsumerState<PedeteoScannerWidget> {
  MobileScannerController? _scannerController;
  bool _isStarted = false;

  // 🎯 Estado del proceso
  ProcessingState _currentState = ProcessingState.idle;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        // 🚀 Habilitar captura de imagen para obtener foto del scan
        returnImage: true,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isStarted = true);
        }
      });
    } catch (e) {
      debugPrint('Error inicializando scanner: $e');
    }
  }

  /// 🎯 Detecta código y usa imagen del scan (UNA SOLA CÁMARA)
  void _onBarcodeDetected(BarcodeCapture capture) async {
    final startTime = DateTime.now();
    debugPrint('🕐 [INICIO] Detección VIN iniciada');

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    final captureImage = capture.image;

    if (barcode != null &&
        barcode.isNotEmpty &&
        _currentState == ProcessingState.idle &&
        mounted) {
      // 🎯 ESTADO 1: VIN Detectado
      setState(() => _currentState = ProcessingState.vinDetected);

      try {
        String imagePath;

        // 🚀 Usar imagen del scan si está disponible
        if (captureImage != null) {
          debugPrint('📸 Usando imagen del scan (una sola cámara)');

          // Guardar imagen temporalmente
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          imagePath = '${tempDir.path}/scan_$timestamp.jpg';

          final file = File(imagePath);
          await file.writeAsBytes(captureImage);

          debugPrint('📸 Imagen guardada: $imagePath');
        } else {
          // Fallback: si no hay imagen, solo usar el VIN
          debugPrint('⚠️ Sin imagen del scan, continuando solo con VIN');

          if (mounted) {
            ref.read(pedeteoStateProvider.notifier).onBarcodeScanned(barcode);
            setState(() => _currentState = ProcessingState.idle);
          }
          return;
        }

        // 🎯 ESTADO 2: Procesando Imagen
        if (mounted) {
          setState(() => _currentState = ProcessingState.processingImage);
        }

        // 🚀 PROCESAMIENTO OPTIMIZADO
        final processingStart = DateTime.now();

        final processedImagePath = await processImageWithWatermark(
          imagePath,
          config: WatermarkPresets.scanner,
          autoGPS: false,
        );

        final processingDuration = DateTime.now()
            .difference(processingStart)
            .inMilliseconds;
        debugPrint('🎨 Imagen procesada en: ${processingDuration}ms');

        // 🎯 ESTADO 3: Completado
        if (mounted) {
          setState(() => _currentState = ProcessingState.completed);

          ref.read(pedeteoStateProvider.notifier).setCapturedImage(processedImagePath);
          ref.read(pedeteoStateProvider.notifier).onBarcodeScanned(barcode);

          await Future.delayed(const Duration(milliseconds: 200));

          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint('❌ Error en detección: $e');

        if (mounted) {
          setState(() => _currentState = ProcessingState.idle);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
        debugPrint('🏁 Proceso completo en: ${totalDuration}ms (una cámara)');
      }
    }
  }

  /// 🎯 Obtener mensaje según el estado actual
  String _getStateMessage() {
    switch (_currentState) {
      case ProcessingState.idle:
        return 'Centra el VIN en el recuadro';
      case ProcessingState.vinDetected:
        return 'VIN detectado!';
      case ProcessingState.processingImage:
        return 'Procesando imagen...';
      case ProcessingState.completed:
        return 'Completado!';
    }
  }

  /// 🎯 Obtener color según el estado
  Color _getStateColor() {
    switch (_currentState) {
      case ProcessingState.idle:
        return Colors.blue;
      case ProcessingState.vinDetected:
        return Colors.green;
      case ProcessingState.processingImage:
        return Colors.purple;
      case ProcessingState.completed:
        return Colors.green;
    }
  }

  /// 🎯 Verificar si está procesando
  bool get _isProcessing => _currentState != ProcessingState.idle;

  void _toggleTorch() {
    _scannerController?.toggleTorch();
  }

  void _closeScanner() {
    ref.read(pedeteoStateProvider.notifier).toggleScanner();
  }

  @override
  void dispose() {
    debugPrint('🧹 Limpiando scanner...');
    _scannerController?.dispose();
    _scannerController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header del scanner
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escaneando VIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          _currentState == ProcessingState.idle
                              ? Icons.camera_alt
                              : Icons.sync,
                          size: 12,
                          color: _getStateColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStateMessage(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStateColor(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleTorch,
                icon: const Icon(Icons.flash_on),
                tooltip: 'Toggle Flash',
              ),
              IconButton(
                onPressed: _closeScanner,
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar Scanner',
              ),
            ],
          ),
        ),

        // Scanner
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 3),
            ),
            child: _isStarted
                ? Stack(
                    children: [
                      // Scanner principal
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onBarcodeDetected,
                      ),

                      // Overlay de procesamiento con estados
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getStateColor(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _getStateMessage(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Estado: ${_currentState.name}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Overlay del recuadro VIN
                      if (!_isProcessing)
                        Center(
                          child: Container(
                            width: 300,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'VIN',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Indicadores de esquina
                      if (!_isProcessing) _buildCornerIndicators(),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Iniciando scanner...',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        // Footer con estado
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentState == ProcessingState.idle
                        ? Icons.camera_alt
                        : Icons.sync,
                    size: 16,
                    color: _getStateColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStateMessage(),
                    style: TextStyle(
                      color: _getStateColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isProcessing
                    ? 'Procesando...'
                    : 'Foto automatica al detectar VIN',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCornerIndicators() {
    return Stack(
      children: [
        Positioned(
          top: 50,
          left: 50,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.blue, width: 4),
                left: BorderSide(color: Colors.blue, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          top: 50,
          right: 50,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.blue, width: 4),
                right: BorderSide(color: Colors.blue, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 50,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.blue, width: 4),
                left: BorderSide(color: Colors.blue, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 50,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.blue, width: 4),
                right: BorderSide(color: Colors.blue, width: 4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
