// widgets/pedeteo/scanner_widget.dart (con estados detallados)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:stampcamera/config/camera/camera_config.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/utils/image_processor.dart';

// 🎯 Enum para estados del proceso
enum ProcessingState {
  idle,
  detectingVin,
  vinDetected,
  takingPhoto,
  photoTaken,
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
  CameraController? _cameraController; // 📸 Cámara en paralelo
  bool _isStarted = false;
  bool _cameraReady = false;

  // 🎯 Estado del proceso
  ProcessingState _currentState = ProcessingState.idle;

  @override
  void initState() {
    super.initState();
    _initScanner();
    _initParallelCamera(); // 🚀 Inicializar cámara en paralelo
  }

  void _initScanner() {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isStarted = true);
        }
      });
    } catch (e) {
      debugPrint('Error inicializando scanner: $e');
    }
  }

  /// 📸 Inicializa cámara en segundo plano (con estado)
  Future<void> _initParallelCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        // 🎯 Actualizar estado mientras se inicializa
        setState(() => _currentState = ProcessingState.detectingVin);

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _cameraReady = true;
            _currentState = ProcessingState.idle; // Listo para detectar
          });
          debugPrint('📸 Cámara paralela lista para captura');
        }
      }
    } catch (e) {
      debugPrint('❌ Error inicializando cámara paralela: $e');
      if (mounted) {
        setState(() => _currentState = ProcessingState.idle);
      }
    }
  }

  /// 🎯 Detecta código y toma foto automáticamente con estados
  void _onBarcodeDetected(BarcodeCapture capture) async {
    final startTime = DateTime.now();
    debugPrint(
      '🕐 [INICIO] Detección de código iniciada: ${startTime.millisecondsSinceEpoch}',
    );

    final barcode = capture.barcodes.first.rawValue;

    if (barcode != null &&
        barcode.isNotEmpty &&
        _currentState == ProcessingState.idle &&
        _cameraReady &&
        mounted) {
      // 🎯 ESTADO 1: VIN Detectado
      setState(() => _currentState = ProcessingState.vinDetected);
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Breve pausa visual

      try {
        if (_cameraController?.value.isInitialized == true && mounted) {
          // 🎯 ESTADO 2: Tomando Foto
          setState(() => _currentState = ProcessingState.takingPhoto);

          debugPrint('📸 Tomando foto automática...');
          final photoStart = DateTime.now();

          final image = await _cameraController!.takePicture();

          final photoDuration = DateTime.now()
              .difference(photoStart)
              .inMilliseconds;
          debugPrint('📸 [FOTO] Captura completada en: ${photoDuration}ms');

          // 🎯 ESTADO 3: Foto Tomada
          if (mounted) {
            setState(() => _currentState = ProcessingState.photoTaken);
            await Future.delayed(
              const Duration(milliseconds: 200),
            ); // Breve confirmación
          }

          // 🎯 ESTADO 4: Procesando Imagen
          if (mounted) {
            setState(() => _currentState = ProcessingState.processingImage);
          }

          // 🚀 PROCESAMIENTO OPTIMIZADO usando preset de scanner
          final processingStart = DateTime.now();
          debugPrint(
            '🎨 [PROCESAMIENTO] Iniciando procesamiento optimizado...',
          );

          final processedImagePath = await processImageWithWatermark(
            image.path,
            config: WatermarkPresets.scanner,
            autoGPS: false,
          );

          final processingDuration = DateTime.now()
              .difference(processingStart)
              .inMilliseconds;
          debugPrint(
            '🎨 [PROCESAMIENTO] Imagen procesada en: ${processingDuration}ms',
          );

          // 🎯 ESTADO 5: Completado
          if (mounted) {
            setState(() => _currentState = ProcessingState.completed);

            ref
                .read(pedeteoStateProvider.notifier)
                .setCapturedImage(processedImagePath);
            ref.read(pedeteoStateProvider.notifier).onBarcodeScanned(barcode);

            // Delay reducido
            await Future.delayed(const Duration(milliseconds: 300));

            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      } catch (e) {
        debugPrint('❌ [ERROR] Error en detección/captura: $e');

        if (mounted) {
          setState(() => _currentState = ProcessingState.idle);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime).inMilliseconds;
        debugPrint('🏁 [OPTIMIZADO] Proceso completo en: ${totalDuration}ms');
        debugPrint('═══════════════════════════════════════════════════════');
      }
    }
  }

  /// 🎯 Obtener mensaje según el estado actual
  String _getStateMessage() {
    switch (_currentState) {
      case ProcessingState.idle:
        return _cameraReady
            ? 'Centra el VIN en el recuadro'
            : 'Preparando cámara...';
      case ProcessingState.detectingVin:
        return 'Preparando detector...';
      case ProcessingState.vinDetected:
        return '✅ VIN detectado!';
      case ProcessingState.takingPhoto:
        return '📸 Tomando foto...';
      case ProcessingState.photoTaken:
        return '📸 Foto tomada!';
      case ProcessingState.processingImage:
        return '🔄 Procesando imagen...';
      case ProcessingState.completed:
        return '✅ Proceso completado!';
    }
  }

  /// 🎯 Obtener color según el estado
  Color _getStateColor() {
    switch (_currentState) {
      case ProcessingState.idle:
        return _cameraReady ? Colors.blue : Colors.orange;
      case ProcessingState.detectingVin:
        return Colors.orange;
      case ProcessingState.vinDetected:
        return Colors.green;
      case ProcessingState.takingPhoto:
        return Colors.blue;
      case ProcessingState.photoTaken:
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
    // 🛡️ Orden correcto de dispose para evitar errores
    debugPrint('🧹 Limpiando scanner y cámara...');

    // Primero detener scanner
    _scannerController?.dispose();

    // Pequeña pausa antes de dispose de cámara
    Future.delayed(const Duration(milliseconds: 100), () {
      _cameraController?.dispose();
    });

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
                              ? (_cameraReady
                                    ? Icons.camera_alt
                                    : Icons.hourglass_empty)
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

        // Footer actualizado con estados
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
                        ? (_cameraReady
                              ? Icons.camera_alt
                              : Icons.hourglass_empty)
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
                    ? 'Procesando automáticamente...'
                    : '📸 La foto se toma automáticamente al detectar el VIN',
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
