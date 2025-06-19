import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FormularioPedeteoScreen extends ConsumerStatefulWidget {
  const FormularioPedeteoScreen({super.key});

  @override
  ConsumerState<FormularioPedeteoScreen> createState() =>
      _FormularioPedeteoScreenState();
}

class _FormularioPedeteoScreenState
    extends ConsumerState<FormularioPedeteoScreen> {
  final TextEditingController _vinCtrl = TextEditingController();
  final TextEditingController _bloqueCtrl = TextEditingController();
  final TextEditingController _condicionCtrl = TextEditingController();

  RegistroGeneral? _registro;
  bool _loadingVin = false;

  void _buscarVin() async {
    final vin = _vinCtrl.text.trim();
    if (vin.isEmpty) return;

    setState(() => _loadingVin = true);
    await ref.read(registroGeneralProvider.notifier).search(vin);
    final resultados = ref.read(registroGeneralProvider).value ?? [];

    if (resultados.isNotEmpty) {
      setState(() => _registro = resultados.first);
    } else {
      setState(() => _registro = null);
    }

    setState(() => _loadingVin = false);
  }

  void _abrirEscaner() async {
    final vinEscaneado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Escanear VIN')),
          body: MobileScanner(
            onDetect: (barcode) {
              final code = barcode.barcodes.firstOrNull;
              ;
              if (code != null) {
                Navigator.pop(context, code);
              }
            },
          ),
        ),
      ),
    );

    if (vinEscaneado != null && vinEscaneado is String) {
      _vinCtrl.text = vinEscaneado;
      _buscarVin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo PEDATEO')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _vinCtrl,
              decoration: InputDecoration(
                labelText: 'VIN',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _abrirEscaner,
                ),
              ),
              onSubmitted: (_) => _buscarVin(),
            ),
            const SizedBox(height: 16),

            if (_loadingVin) const CircularProgressIndicator(),

            if (_registro != null) _buildCardRegistro(_registro!),

            const SizedBox(height: 20),
            TextField(
              controller: _bloqueCtrl,
              decoration: const InputDecoration(labelText: 'Bloque'),
            ),
            TextField(
              controller: _condicionCtrl,
              decoration: const InputDecoration(labelText: 'Condición'),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // TODO: Guardar PEDATEO
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRegistro(RegistroGeneral r) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.serie != null && r.serie!.isNotEmpty
                  ? '${r.vin} (${r.serie})'
                  : r.vin,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${r.marca ?? ''} - ${r.modelo ?? ''}'),
            Text('Color: ${r.color ?? 'N/A'}'),
            Text('Versión: ${r.version ?? 'N/A'}'),
            Text('Nave: ${r.naveDescarga ?? 'N/A'}'),
            Text('BL: ${r.bl ?? 'N/A'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  r.pedeteado ? Icons.check_circle : Icons.cancel,
                  color: r.pedeteado ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text('Pedeteado', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Icon(
                  r.danos ? Icons.check_circle : Icons.cancel,
                  color: r.danos ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text('Daños', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
