// screens/pedeteo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/pedeteo/pedeteo_provider.dart';

// screens/pedeteo_screen.dart

class PedeteoScreen extends ConsumerStatefulWidget {
  const PedeteoScreen({super.key});

  @override
  ConsumerState<PedeteoScreen> createState() => _PedeteoScreenState();
}

class _PedeteoScreenState extends ConsumerState<PedeteoScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _searchFocusNode = FocusNode();
  MobileScannerController? _scannerController;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
    }
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      _hideDropdown();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    // ✅ Usar el StateNotifier para manejar el query
    ref.read(pedeteoStateProvider.notifier).updateSearchQuery(query);

    setState(() {
      // Mostrar dropdown si hay query y menos de 17 caracteres
      if (query.isNotEmpty && query.length < 17) {
        _showSearchDropdown();
      } else {
        _hideDropdown();
      }
    });
  }

  void _selectVin(RegistroGeneral vin) {
    // ✅ Usar el StateNotifier para seleccionar VIN
    ref.read(pedeteoStateProvider.notifier).selectVin(vin);
    _searchController.text = vin.vin;
    _hideDropdown();

    // ✅ Inicializar formulario con valores por defecto
    ref.read(pedeteoOptionsProvider.future).then((options) {
      ref
          .read(pedeteoStateProvider.notifier)
          .initializeFormWithDefaults(options.initialValues);
    });
  }

  void _toggleScanner() {
    // ✅ Usar el StateNotifier para toggle scanner
    ref.read(pedeteoStateProvider.notifier).toggleScanner();

    final state = ref.read(pedeteoStateProvider);

    if (state.showScanner) {
      _scannerController = MobileScannerController();
      _hideDropdown();
      _searchFocusNode.unfocus();
    } else {
      _scannerController?.dispose();
      _scannerController = null;
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.first.rawValue;
    if (barcode != null) {
      _searchController.text = barcode;
      // ✅ Usar el StateNotifier para manejar el código escaneado
      ref.read(pedeteoStateProvider.notifier).onBarcodeScanned(barcode);
    }
  }

  void _showSearchDropdown() {
    _hideDropdown(); // Remove existing overlay

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Consumer(
                builder: (context, ref, child) {
                  // ✅ Usar el provider de búsqueda local optimizado
                  final searchResults = ref.watch(pedeteoSearchResultsProvider);

                  if (searchResults.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No se encontraron resultados'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final vin = searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(vin.vin),
                        subtitle: Text(
                          '${vin.marca ?? ''} ${vin.modelo ?? ''} - Serie: ${vin.serie ?? 'N/A'}',
                        ),
                        onTap: () => _selectVin(vin),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      final XFile image = await _cameraController!.takePicture();
      final File savedImage = File(filePath);
      await savedImage.writeAsBytes(await image.readAsBytes());

      // ✅ Usar el StateNotifier para guardar la imagen
      ref.read(pedeteoStateProvider.notifier).setCapturedImage(savedImage.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  Future<void> _saveAndContinue() async {
    // ✅ Usar el StateNotifier para guardar (incluye validaciones)
    await ref.read(pedeteoStateProvider.notifier).saveRegistro();

    final state = ref.read(pedeteoStateProvider);

    if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado exitosamente')),
      );
    }
  }

  void _resetForm() {
    // ✅ Usar el StateNotifier para reset
    ref.read(pedeteoStateProvider.notifier).resetForm();
    _searchController.clear();
    _hideDropdown();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scannerController?.dispose();
    _cameraController?.dispose();
    _hideDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Escuchar el estado principal
    final state = ref.watch(pedeteoStateProvider);

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar por VIN o Serie...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _resetForm();
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          state.showScanner
                              ? Icons.close
                              : Icons.qr_code_scanner,
                        ),
                        onPressed: _toggleScanner,
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),

          // Scanner de códigos de barras
          if (state.showScanner)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetected,
                ),
              ),
            ),

          // Formulario de registro
          if (state.showForm && !state.showScanner)
            Expanded(child: _buildRegistrationForm(state)),

          // Estado inicial
          if (!state.showScanner && !state.showForm)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Busca por VIN o Serie',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'También puedes usar el scanner de código de barras',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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

  Widget _buildRegistrationForm(PedeteoState state) {
    final selectedVin = state.selectedVin;

    if (selectedVin == null) {
      return const Center(child: Text('No hay VIN seleccionado'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del vehículo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Vehículo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('VIN:', selectedVin.vin),
                  _buildInfoRow('Serie:', selectedVin.serie ?? 'N/A'),
                  _buildInfoRow('Marca:', selectedVin.marca ?? 'N/A'),
                  _buildInfoRow('Modelo:', selectedVin.modelo ?? 'N/A'),
                  _buildInfoRow('Color:', selectedVin.color ?? 'N/A'),
                  _buildInfoRow('Nave:', selectedVin.naveDescarga ?? 'N/A'),
                  _buildInfoRow('BL:', selectedVin.bl ?? 'N/A'),
                  _buildInfoRow('Versión:', selectedVin.version ?? 'N/A'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sección de campos del formulario
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos del Registro',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildFormFields(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sección de foto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto del VIN',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  if (state.capturedImagePath != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(state.capturedImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toca para tomar foto',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        state.capturedImagePath != null
                            ? 'Cambiar foto'
                            : 'Tomar foto',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2D3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  child: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.capturedImagePath != null && !state.isLoading
                      ? _saveAndContinue
                      : null,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Guardar y Continuar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2D3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          // Mostrar errores si los hay
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(pedeteoStateProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Consumer(
      builder: (context, ref, child) {
        final optionsAsync = ref.watch(pedeteoOptionsProvider);

        return optionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
          data: (options) {
            final fieldPermissions = options.fieldPermissions;
            final initialValues = options.initialValues;

            return Column(
              children: [
                // Condición
                if (fieldPermissions['condicion']?.editable ?? true)
                  _buildCondicionDropdown(options, initialValues),

                const SizedBox(height: 12), // ✅ Espaciado reducido
                // Zona de Inspección
                if (fieldPermissions['zona_inspeccion']?.editable ?? true)
                  _buildZonaInspeccionDropdown(options, initialValues),

                const SizedBox(height: 12), // ✅ Espaciado reducido
                // Bloque
                if (fieldPermissions['bloque']?.editable ?? true)
                  _buildBloqueDropdown(options, initialValues),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCondicionDropdown(options, Map<String, dynamic> initialValues) {
    final state = ref.watch(pedeteoStateProvider);
    final condiciones = options.condiciones;
    final currentValue =
        state.formData['condicion'] ?? initialValues['condicion'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: const InputDecoration(
          labelText: 'Condición',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true, // ✅ Evita overflow del texto
        items: condiciones.map<DropdownMenuItem<String>>((condicion) {
          return DropdownMenuItem<String>(
            value: condicion.value,
            child: Text(
              condicion.label,
              overflow: TextOverflow.ellipsis, // ✅ Truncar texto largo
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            ref
                .read(pedeteoStateProvider.notifier)
                .updateFormField('condicion', newValue);
          }
        },
      ),
    );
  }

  Widget _buildZonaInspeccionDropdown(
    options,
    Map<String, dynamic> initialValues,
  ) {
    final state = ref.watch(pedeteoStateProvider);
    final zonas = options.zonasInspeccion;
    final currentValue =
        state.formData['zona_inspeccion'] ?? initialValues['zona_inspeccion'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<int>(
        value: currentValue,
        decoration: const InputDecoration(
          labelText: 'Zona de Inspección',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true, // ✅ Evita overflow del texto
        items: zonas.map<DropdownMenuItem<int>>((zona) {
          return DropdownMenuItem<int>(
            value: zona.value,
            child: Text(
              zona.label,
              overflow: TextOverflow.ellipsis, // ✅ Truncar texto largo
            ),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue != null) {
            ref
                .read(pedeteoStateProvider.notifier)
                .updateFormField('zona_inspeccion', newValue);
          }
        },
      ),
    );
  }

  Widget _buildBloqueDropdown(options, Map<String, dynamic> initialValues) {
    final state = ref.watch(pedeteoStateProvider);
    final bloques = options.bloques;
    final currentValue = state.formData['bloque'] ?? initialValues['bloque'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<int>(
        value: currentValue,
        decoration: const InputDecoration(
          labelText: 'Bloque',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true, // ✅ Evita overflow del texto
        items: bloques.map<DropdownMenuItem<int>>((bloque) {
          return DropdownMenuItem<int>(
            value: bloque.value,
            child: Text(
              bloque.label,
              overflow: TextOverflow.ellipsis, // ✅ Truncar texto largo
            ),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue != null) {
            ref
                .read(pedeteoStateProvider.notifier)
                .updateFormField('bloque', newValue);
          }
        },
      ),
    );
  }
}
