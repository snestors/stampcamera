// widgets/pedeteo/scanner_widget.dart (con cámara en paralelo)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/utils/image_processor.dart';

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
  bool _isProcessing = false;
  bool _cameraReady = false;

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

  /// 📸 Inicializa cámara en segundo plano (sin preview)
  Future<void> _initParallelCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() => _cameraReady = true);
          debugPrint('📸 Cámara paralela lista para captura');
        }
      }
    } catch (e) {
      debugPrint('❌ Error inicializando cámara paralela: $e');
    }
  }

  /// 🎯 Detecta código y toma foto automáticamente
  void _onBarcodeDetected(BarcodeCapture capture) async {
    final startTime = DateTime.now();
    debugPrint(
      '🕐 [INICIO] Detección de código iniciada: ${startTime.millisecondsSinceEpoch}',
    );

    final barcode = capture.barcodes.first.rawValue;

    if (barcode != null &&
        barcode.isNotEmpty &&
        !_isProcessing &&
        _cameraReady &&
        mounted) {
      setState(() => _isProcessing = true);

      try {
        if (_cameraController?.value.isInitialized == true && mounted) {
          debugPrint('📸 Tomando foto automática...');
          final photoStart = DateTime.now();

          final image = await _cameraController!.takePicture();

          final photoDuration = DateTime.now()
              .difference(photoStart)
              .inMilliseconds;
          debugPrint('📸 [FOTO] Captura completada en: ${photoDuration}ms');

          // 🚀 PROCESAMIENTO OPTIMIZADO
          final processingStart = DateTime.now();
          debugPrint(
            '🎨 [PROCESAMIENTO] Iniciando procesamiento optimizado...',
          );

          final processedImagePath = await processAndSaveImage(image.path);

          final processingDuration = DateTime.now()
              .difference(processingStart)
              .inMilliseconds;
          debugPrint(
            '🎨 [PROCESAMIENTO] Imagen procesada en: ${processingDuration}ms',
          );

          if (mounted) {
            ref
                .read(pedeteoStateProvider.notifier)
                .setCapturedImage(processedImagePath);
            ref.read(pedeteoStateProvider.notifier).onBarcodeScanned(barcode);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ VIN: $barcode\n📸 Foto tomada automáticamente',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);

          final endTime = DateTime.now();
          final totalDuration = endTime.difference(startTime).inMilliseconds;
          debugPrint('🏁 [OPTIMIZADO] Proceso completo en: ${totalDuration}ms');
          debugPrint('═══════════════════════════════════════════════════════');
        }
      }
    }
  }

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
                    Text(
                      _cameraReady
                          ? '📸 Cámara lista'
                          : '⏳ Preparando cámara...',
                      style: TextStyle(
                        fontSize: 12,
                        color: _cameraReady ? Colors.green : Colors.orange,
                      ),
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

                      // Overlay de procesamiento
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '✅ VIN detectado!\n📸 Tomando foto...\n🔄 Procesando imagen...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
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

        // Footer actualizado
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _cameraReady ? Icons.camera_alt : Icons.hourglass_empty,
                    size: 16,
                    color: _cameraReady ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _cameraReady
                        ? 'Centra el VIN - Foto automática activada'
                        : 'Preparando captura automática...',
                    style: TextStyle(
                      color: _cameraReady ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '📸 La foto se toma automáticamente al detectar el VIN',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
