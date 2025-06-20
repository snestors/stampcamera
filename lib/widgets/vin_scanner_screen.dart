import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class VinScannerScreen extends StatelessWidget {
  final void Function(String vin) onScanned;

  const VinScannerScreen({super.key, required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear VIN')),
      body: MobileScanner(
        onDetect: (barcode) {
          final code = barcode.barcodes.firstOrNull;
          final vin = code?.rawValue;
          if (vin != null) {
            onScanned(vin);
            Navigator.pop(context); // Cerramos después del callback
          }
        },
      ),
    );
  }
}
