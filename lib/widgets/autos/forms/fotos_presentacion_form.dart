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
      height: MediaQuery.of(context).size.height * 0.9, // ✅ 90% de la pantalla
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ✅ Header fijo
          _buildFixedHeader(),

          // ✅ Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: detalleAsync.when(
                data: (detalle) =>
                    _buildScrollableContent(detalle, optionsAsync),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState('Error cargando datos'),
              ),
            ),
          ),

          // ✅ Botones de acción fijos
          _buildFixedActionButtons(),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER FIJO
  // ============================================================================

  Widget _buildFixedHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
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
      ),
    );
  }

  // ============================================================================
  // CONTENIDO SCROLLEABLE
  // ============================================================================

  Widget _buildScrollableContent(
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
      data: (options) => _buildFormContent(options, detalle),
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
  // CONTENIDO DEL FORMULARIO
  // ============================================================================

  Widget _buildFormContent(
    Map<String, dynamic> options,
    DetalleRegistroModel detalle,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildFormFields(options, detalle),
          const SizedBox(height: 16),
          _buildFotoSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFormFields(
    Map<String, dynamic> options,
    DetalleRegistroModel detalle,
  ) {
    final tiposDisponibles =
        options['tipos_disponibles'] as List<dynamic>? ?? [];

    // Crear lista de IdValuePair desde los registros VIN existentes
    final condicionesDisponibles = detalle.registrosVin
        .map(
          (registro) => IdValuePair(id: registro.id, value: registro.condicion),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de la Foto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen de la Foto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ReusableCameraCard(
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
        ),
      ],
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN FIJOS
  // ============================================================================

  Widget _buildFixedActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
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
      ),
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
  // HELPERS PARA COLORES E ÍCONOS (MISMOS MÉTODOS)
  // ============================================================================

  Color _getCondicionColor(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return const Color(0xFF00B4D8);
      case 'RECEPCION':
        return const Color(0xFF8B5CF6);
      case 'ALMACEN':
        return const Color(0xFF059669);
      case 'PDI':
        return const Color(0xFFF59E0B);
      case 'PRE-PDI':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
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
        return const Color(0xFF059669);
      case 'AUTO':
        return const Color(0xFF00B4D8);
      case 'KM':
        return const Color(0xFFF59E0B);
      case 'DR':
        return const Color(0xFFDC2626);
      case 'OTRO':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return Icons.assignment;
      case 'AUTO':
        return Icons.directions_car;
      case 'KM':
        return Icons.speed;
      case 'DR':
        return Icons.report_problem;
      case 'OTRO':
        return Icons.description;
      default:
        return Icons.photo;
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
  // SUBMIT FORM (MISMO MÉTODO)
  // ============================================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isEditMode && _fotoPath == null) {
      _showError('La foto es obligatoria');
      return;
    }

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
        success = await notifier.updateFoto(
          fotoId: widget.fotoId!,
          tipo: _selectedTipo,
          imagen: _fotoPath != null ? File(_fotoPath!) : null,
          nDocumento: nDocumento,
        );
      } else {
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
