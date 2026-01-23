import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class VinScannerScreen extends StatefulWidget {
  final void Function(String vin) onScanned;

  const VinScannerScreen({super.key, required this.onScanned});

  @override
  State<VinScannerScreen> createState() => _VinScannerScreenState();
}

class _VinScannerScreenState extends State<VinScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() {
        _hasScanned = true;
      });

      _controller?.stop();

      // Directamente enviar el código al buscador y cerrar
      widget.onScanned(code);
      Navigator.pop(context);
    }
  }

  void _toggleTorch() async {
    await _controller?.toggleTorch();
    setState(() {
      _torchOn = !_torchOn; // ✅ Actualizar estado manual
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Botón de flash
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.yellow : Colors.white,
            ),
            tooltip: 'Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner principal
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onBarcodeDetected,
            ),

          // Overlay con guías visuales
          CustomPaint(painter: ScannerOverlayPainter(), child: Container()),

          // Instrucciones
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Posiciona el código dentro del marco',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ============================================================================
// PAINTER PARA EL OVERLAY DEL SCANNER
// ============================================================================
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.3,
    );

    // Fondo oscuro
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12)))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Marco del área de escaneo
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(12)),
      borderPaint,
    );

    // Esquinas del marco
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Esquina superior izquierda
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top + cornerLength),
      Offset(scanArea.left, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.top),
      Offset(scanArea.right, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      Offset(scanArea.left, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
