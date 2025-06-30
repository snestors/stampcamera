// lib/widgets/autos/forms/foto_presentacion_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';

class FotoPresentacionForm extends ConsumerStatefulWidget {
  final String vin;
  final int? fotoId; // Para modo edición
  final String? tipoInicial;
  final String? nDocumentoInicial;

  const FotoPresentacionForm({
    super.key,
    required this.vin,
    this.fotoId,
    this.tipoInicial,
    this.nDocumentoInicial,
  });

  @override
  ConsumerState<FotoPresentacionForm> createState() =>
      _FotoPresentacionFormState();
}

class _FotoPresentacionFormState extends ConsumerState<FotoPresentacionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nDocumentoController = TextEditingController();

  String? _selectedTipo;
  String? _fotoPath;
  bool _isLoading = false;
  int? _selectedRegistroVinId;
  bool _initialized = false;

  bool get isEditMode => widget.fotoId != null;

  @override
  void initState() {
    super.initState();
    _selectedTipo = widget.tipoInicial;
    _nDocumentoController.text = widget.nDocumentoInicial ?? '';
  }

  @override
  void dispose() {
    _nDocumentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync = ref.watch(detalleRegistroProvider(widget.vin));
    final optionsAsync = ref.watch(fotosOptionsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            detalleAsync.when(
              data: (detalle) =>
                  _buildValidationsAndForm(detalle, optionsAsync),
              loading: () => _buildLoadingState(),
              error: (error, _) => _buildErrorState('Error cargando datos'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // VALIDACIONES Y CONSTRUCCIÓN DEL FORMULARIO
  // ============================================================================

  Widget _buildValidationsAndForm(
    DetalleRegistroModel detalle,
    AsyncValue optionsAsync,
  ) {
    // Validación: Sin RegistrosVin
    if (detalle.registrosVin.isEmpty) {
      return _buildValidationError(
        'Sin Registros VIN',
        'No puedes crear fotos, falta registrar VIN primero',
        icon: Icons.warning,
        buttonText: 'Crear VIN Primero',
        onPressed: () => Navigator.pop(context),
      );
    }

    // Inicializar selección una sola vez
    if (!_initialized) {
      _initializeSelection(detalle);
    }

    return optionsAsync.when(
      data: (options) => _buildForm(options, detalle),
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState('Error cargando tipos de foto'),
    );
  }

  void _initializeSelection(DetalleRegistroModel detalle) {
    if (isEditMode && widget.fotoId != null) {
      // Modo edición: encontrar el registro VIN de la foto actual
      final fotoActual = detalle.fotosPresentacion
          .where((f) => f.id == widget.fotoId)
          .firstOrNull;

      if (fotoActual?.condicion?.id != null) {
        final registroVin = detalle.registrosVin
            .where((r) => r.condicion == fotoActual!.condicion!.value)
            .firstOrNull;

        if (registroVin != null) {
          _selectedRegistroVinId = registroVin.id;
        }
      }
    } else {
      // Modo crear: seleccionar el registro más reciente
      if (detalle.registrosVin.isNotEmpty) {
        final sortedRegistros = List<RegistroVin>.from(detalle.registrosVin);
        sortedRegistros.sort(
          (a, b) => (b.fecha ?? '').compareTo(a.fecha ?? ''),
        );
        _selectedRegistroVinId = sortedRegistros.first.id;
      }
    }

    _initialized = true;
  }

  Widget _buildValidationError(
    String title,
    String message, {
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Icon(icon, size: 48, color: const Color(0xFFDC2626)),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003B5C),
            foregroundColor: Colors.white,
          ),
          child: Text(buttonText),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================================
  // FORMULARIO PRINCIPAL
  // ============================================================================

  Widget _buildForm(
    Map<String, dynamic> options,
    DetalleRegistroModel detalle,
  ) {
    final tiposDisponibles =
        options['tipos_disponibles'] as List<dynamic>? ?? [];

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFormFields(tiposDisponibles, detalle),
          const SizedBox(height: 16),
          _buildFotoSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          isEditMode ? Icons.edit : Icons.add_a_photo,
          color: const Color(0xFF003B5C),
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isEditMode ? 'Editar Foto' : 'Nueva Foto de Presentación',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildFormFields(
    List<dynamic> tiposDisponibles,
    DetalleRegistroModel detalle,
  ) {
    // Crear lista de IdValuePair desde los registros VIN existentes
    final condicionesDisponibles = detalle.registrosVin
        .map(
          (registro) => IdValuePair(id: registro.id, value: registro.condicion),
        )
        .toList();

    return Column(
      children: [
        // Dropdown de condición/registro VIN
        DropdownButtonFormField<int>(
          value: _selectedRegistroVinId,
          decoration: const InputDecoration(
            labelText: 'Condición *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timeline),
            helperText: 'Selecciona la condición del registro VIN',
          ),
          items: condicionesDisponibles.map<DropdownMenuItem<int>>((condicion) {
            return DropdownMenuItem<int>(
              value: condicion.id,
              child: Row(
                children: [
                  Icon(
                    _getCondicionIcon(condicion.value),
                    size: 18,
                    color: _getCondicionColor(condicion.value),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    condicion.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedRegistroVinId = value),
          validator: (value) =>
              value == null ? 'Seleccione una condición' : null,
        ),

        const SizedBox(height: 16),

        // Dropdown de tipo
        DropdownButtonFormField<String>(
          value: _selectedTipo,
          decoration: const InputDecoration(
            labelText: 'Tipo de Foto *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: tiposDisponibles.map<DropdownMenuItem<String>>((tipo) {
            return DropdownMenuItem(
              value: tipo['value'],
              child: Row(
                children: [
                  Icon(
                    _getTipoIcon(tipo['value']),
                    size: 16,
                    color: _getTipoColor(tipo['value']),
                  ),
                  const SizedBox(width: 8),
                  Text(tipo['label']),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedTipo = value),
          validator: (value) =>
              value == null ? 'Seleccione un tipo de foto' : null,
        ),

        const SizedBox(height: 16),

        // N° Documento
        TextFormField(
          controller: _nDocumentoController,
          decoration: const InputDecoration(
            labelText: 'N° Documento',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Ej: DOC-001, TARJA-123',
          ),
        ),
      ],
    );
  }

  Widget _buildFotoSection() {
    return ReusableCameraCard(
      title: 'Foto *',
      subtitle: _selectedTipo != null
          ? 'Fotografía ${_getTipoLabel(_selectedTipo!)}'
          : 'Selecciona un tipo de foto primero',
      currentImagePath: _fotoPath,
      onImageSelected: (path) => setState(() => _fotoPath = path),
      showGalleryOption: true,
      primaryColor: _selectedTipo != null
          ? _getTipoColor(_selectedTipo!)
          : const Color(0xFF00B4D8),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedTipo != null
                  ? _getTipoColor(_selectedTipo!)
                  : const Color(0xFF00B4D8),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEditMode ? 'Actualizar' : 'Guardar'),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ESTADOS DE CARGA Y ERROR
  // ============================================================================

  Widget _buildLoadingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 100),
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Cargando tipos de foto...'),
        SizedBox(height: 100),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 50),
        const Icon(Icons.error, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(message),
        const SizedBox(height: 8),
        const Text(
          'Verifique su conexión a internet',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(fotosOptionsProvider),
          child: const Text('Reintentar'),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  // ============================================================================
  // HELPERS PARA COLORES E ÍCONOS
  // ============================================================================

  Color _getCondicionColor(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return const Color(0xFF00B4D8); // Azul
      case 'RECEPCION':
        return const Color(0xFF8B5CF6); // Púrpura
      case 'ALMACEN':
        return const Color(0xFF059669); // Verde
      case 'PDI':
        return const Color(0xFFF59E0B); // Naranja
      case 'PRE-PDI':
        return const Color(0xFFEF4444); // Rojo
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }

  IconData _getCondicionIcon(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return Icons.anchor;
      case 'RECEPCION':
        return Icons.login;
      case 'ALMACEN':
        return Icons.warehouse;
      case 'PDI':
        return Icons.build_circle;
      case 'PRE-PDI':
        return Icons.search;
      default:
        return Icons.location_on;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return const Color(0xFF059669); // Verde - documento oficial
      case 'AUTO':
        return const Color(0xFF00B4D8); // Azul - foto del vehículo
      case 'KM':
        return const Color(0xFFF59E0B); // Naranja - kilometraje
      case 'DR':
        return const Color(0xFFDC2626); // Rojo - damage report
      case 'OTRO':
        return const Color(0xFF8B5CF6); // Púrpura - otros documentos
      default:
        return const Color(0xFF6B7280); // Gris - desconocido
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return Icons.assignment; // Documento/tarja
      case 'AUTO':
        return Icons.directions_car; // Vehículo
      case 'KM':
        return Icons.speed; // Velocímetro para KM
      case 'DR':
        return Icons.report_problem; // Reporte de daños
      case 'OTRO':
        return Icons.description; // Documento genérico
      default:
        return Icons.photo; // Foto genérica
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return 'de Tarja/Documento';
      case 'AUTO':
        return 'del Vehículo';
      case 'KM':
        return 'de Kilometraje';
      case 'DR':
        return 'de Damage Report';
      case 'OTRO':
        return 'de Otros Documentos';
      default:
        return tipo;
    }
  }

  // ============================================================================
  // SUBMIT FORM
  // ============================================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar foto solo en modo crear o si se cambió
    if (!isEditMode && _fotoPath == null) {
      _showError('La foto es obligatoria');
      return;
    }

    // Validar que se haya seleccionado un registro VIN
    if (_selectedRegistroVinId == null) {
      _showError('Seleccione una condición');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(detalleRegistroProvider(widget.vin).notifier);
      bool success = false;

      final nDocumento = _nDocumentoController.text.trim().isEmpty
          ? null
          : _nDocumentoController.text.trim();

      if (isEditMode) {
        // Modo edición
        success = await notifier.updateFoto(
          fotoId: widget.fotoId!,
          tipo: _selectedTipo,
          imagen: _fotoPath != null ? File(_fotoPath!) : null,
          nDocumento: nDocumento,
        );
      } else {
        // Modo crear - usar registro VIN seleccionado específicamente
        success = await notifier.addFoto(
          registroVinId: _selectedRegistroVinId!,
          tipo: _selectedTipo!,
          imagen: File(_fotoPath!),
          nDocumento: nDocumento,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          _showSuccess(
            isEditMode
                ? '✅ Foto actualizada exitosamente'
                : '✅ Foto agregada exitosamente',
          );
        } else {
          _showError(
            '❌ Error al ${isEditMode ? 'actualizar' : 'agregar'} foto',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('❌ Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
