// widgets/pedeteo/scanner_widget.dart - OPTIMIZADO: Una sola cámara
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stampcamera/config/camera/camera_config.dart';
import 'package:stampcamera/core/core.dart';
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

  // VIN leído, para mostrarlo como confirmación inmediata en el overlay
  String? _scannedVin;

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
        // Con returnImage el plugin codifica el frame COMPLETO a PNG antes
        // de avisar la detección (1920x1080 por defecto = segundos de
        // retraso). A 720p el aviso llega ~3x más rápido y la foto del VIN
        // sigue siendo legible (igual se comprime al estamparla).
        cameraResolution: const Size(1280, 720),
        // Solo los formatos usados en etiquetas VIN: analizar TODOS los
        // formatos hace más lento cada frame y retrasa la detección.
        formats: const [
          BarcodeFormat.code39,
          BarcodeFormat.code128,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.qrCode,
          BarcodeFormat.pdf417,
        ],
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
      // 🎯 ESTADO 1: VIN Detectado — feedback INMEDIATO (vibración + visual)
      HapticFeedback.mediumImpact();
      setState(() {
        _currentState = ProcessingState.vinDetected;
        _scannedVin = barcode;
      });

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
            setState(() {
              _currentState = ProcessingState.idle;
              _scannedVin = null;
            });
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

        // 🎯 ESTADO 3: Completado — onBarcodeScanned oculta el scanner
        // (showScanner=false) y abre el formulario de inmediato; el VIN
        // queda confirmado en el propio formulario (DetalleRegistroCard).
        if (mounted) {
          setState(() => _currentState = ProcessingState.completed);

          ref.read(pedeteoStateProvider.notifier).setCapturedImage(processedImagePath);
          ref.read(pedeteoStateProvider.notifier).onBarcodeScanned(barcode);
        }
      } catch (e) {
        debugPrint('❌ Error en detección: $e');

        if (mounted) {
          setState(() {
            _currentState = ProcessingState.idle;
            _scannedVin = null;
          });
          AppSnackBar.error(context, 'Error: $e');
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
        return 'Apunta al código del VIN';
      case ProcessingState.vinDetected:
        return '¡VIN escaneado!';
      case ProcessingState.processingImage:
        return 'Guardando foto...';
      case ProcessingState.completed:
        return '¡Listo!';
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
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          // Header del scanner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceS,
            ),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: DesignTokens.iconM,
                ),
                const SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escanear VIN',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeM,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getStateMessage(),
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleTorch,
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  tooltip: 'Linterna',
                ),
                IconButton(
                  onPressed: _closeScanner,
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),

          // Scanner
          Expanded(
            child: _isStarted
                ? Stack(
                    children: [
                      // Scanner principal
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onBarcodeDetected,
                      ),

                      // Overlay de confirmación: check inmediato + VIN leído
                      if (_isProcessing) _buildConfirmationOverlay(),

                      // Visor de escaneo: marco con esquinas + instrucción
                      if (!_isProcessing) _buildScanOverlay(),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spaceM),
                        Text(
                          'Iniciando cámara...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: DesignTokens.fontSizeS,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Confirmación de escaneo: el check y el VIN aparecen APENAS se detecta
  /// el código (con vibración), y debajo va el progreso del guardado.
  /// Así no queda duda de si ya escaneó o no.
  Widget _buildConfirmationOverlay() {
    final isSaving = _currentState == ProcessingState.processingImage ||
        _currentState == ProcessingState.vinDetected;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 72,
            ),
            const SizedBox(height: DesignTokens.spaceM),
            const Text(
              '¡VIN escaneado!',
              style: TextStyle(
                color: Colors.white,
                fontSize: DesignTokens.fontSizeL,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_scannedVin != null) ...[
              const SizedBox(height: DesignTokens.spaceS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  _scannedVin!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spaceL),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceS),
                ],
                Text(
                  isSaving ? 'Guardando foto...' : 'Abriendo formulario...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: DesignTokens.fontSizeS,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Visor centrado: 4 esquinas alineadas al marco + instrucción debajo
  Widget _buildScanOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            height: 110,
            child: Stack(
              children: [
                Positioned(top: 0, left: 0, child: _corner(top: true, left: true)),
                Positioned(top: 0, right: 0, child: _corner(top: true, left: false)),
                Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true)),
                Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false)),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spaceM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            ),
            child: const Text(
              'Centra el código del VIN en el marco',
              style: TextStyle(
                color: Colors.white,
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    const side = BorderSide(color: Colors.white, width: 3);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: !top ? side : BorderSide.none,
          left: left ? side : BorderSide.none,
          right: !left ? side : BorderSide.none,
        ),
      ),
    );
  }
}
