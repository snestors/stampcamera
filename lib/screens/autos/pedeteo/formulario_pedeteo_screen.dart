import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';
import 'package:stampcamera/widgets/autos/card_detalle_registro_vin.dart';
import 'package:stampcamera/widgets/common/custom_select_search.dart';
import 'package:stampcamera/widgets/vin_scanner_screen.dart';

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

  final FocusNode _vinFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<RegistroGeneral> _sugerencias = [];
  RegistroGeneral? _registro;
  bool _loadingVin = false;

  @override
  void initState() {
    super.initState();

    _vinCtrl.addListener(() {
      final input = _vinCtrl.text.trim();
      if (input.length == 17) {
        _buscarVin();
      } else {
        _actualizarSugerencias(input);
      }
    });

    _vinFocus.addListener(() {
      if (!_vinFocus.hasFocus) _removeOverlay();
    });
  }

  @override
  void dispose() {
    _vinCtrl.dispose();
    _bloqueCtrl.dispose();
    _condicionCtrl.dispose();
    _vinFocus.dispose();
    super.dispose();
  }

  void _buscarVin() async {
    final vin = _vinCtrl.text.trim();
    if (vin.isEmpty) return;

    setState(() {
      _loadingVin = true;
      _registro = null;
    });

    await ref.read(registroGeneralProvider.notifier).search(vin);
    final resultados = ref.read(registroGeneralProvider).value ?? [];

    if (resultados.isNotEmpty) {
      setState(() => _registro = resultados.first);
    }

    _removeOverlay();
    setState(() => _loadingVin = false);
  }

  void _actualizarSugerencias(String input) async {
    if (input.isEmpty || input.length >= 17) {
      _removeOverlay();
      return;
    }

    await ref.read(registroGeneralProvider.notifier).search(input);
    final resultados = ref.read(registroGeneralProvider).value ?? [];

    _sugerencias = resultados;
    _removeOverlay();

    if (_sugerencias.isEmpty) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(16, 60),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _sugerencias.map((r) {
                return ListTile(
                  title: Text(r.vin),
                  subtitle: Text('${r.marca ?? ''} ${r.modelo ?? ''}'),
                  onTap: () {
                    _vinCtrl.text = r.vin;
                    _buscarVin();
                    _removeOverlay();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildVinInput() {
    return CustomSelectSearch<RegistroGeneral>(
      labelText: 'VIN',
      onSearch: (query) async {
        await ref.read(registroGeneralProvider.notifier).search(query);
        return ref.read(registroGeneralProvider).value ?? [];
      },
      itemToString: (r) => r.vin,
      onItemSelected: (r) {
        setState(() => _registro = r);
      },
      suffixIcon: IconButton(
        icon: const Icon(Icons.qr_code_scanner),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VinScannerScreen(
                onScanned: (vin) {
                  // ejemplo: asignar y buscar
                  ref.read(registroGeneralProvider.notifier).search(vin);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildVinInput(),
            const SizedBox(height: 16),

            if (_loadingVin) const CircularProgressIndicator(),

            if (_registro != null) DetalleRegistroCard(registro: _registro!),

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
}
