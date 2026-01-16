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
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: detalleAsync.when(
                data: (detalle) => _buildContent(detalle, optionsAsync),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState('Error cargando datos'),
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER FIJO
  // ============================================================================
  Widget _buildHeader() {
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
  // CONTENIDO PRINCIPAL
  // ============================================================================
  Widget _buildContent(DetalleRegistroModel detalle, AsyncValue optionsAsync) {
    if (detalle.registrosVin.isEmpty) {
      return _buildValidationError(
        'Sin Registros VIN',
        'No puedes crear fotos, falta registrar VIN primero',
        icon: Icons.warning,
        buttonText: 'Crear VIN Primero',
        onPressed: () => Navigator.pop(context),
      );
    }

    if (!_initialized) {
      _initializeSelection(detalle);
    }

    return optionsAsync.when(
      data: (options) => _buildForm(options, detalle),
      loading: () => _buildLoadingState(),
      error: (error, _) => _buildErrorState('Error cargando tipos de foto'),
    );
  }

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================
  void _initializeSelection(DetalleRegistroModel detalle) {
    if (isEditMode && widget.fotoId != null) {
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
    }
    // En modo crear, la autoselección se maneja en _buildCondicionField

    _initialized = true;
  }

  // ============================================================================
  // FORMULARIO
  // ============================================================================
  Widget _buildForm(
    Map<String, dynamic> options,
    DetalleRegistroModel detalle,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildPermissionValidation(options),
          _buildFormFields(options, detalle),
          const SizedBox(height: 16),
          _buildFotoSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================================
  // VALIDACIÓN DE PERMISOS
  // ============================================================================
  Widget _buildPermissionValidation(Map<String, dynamic> options) {
    final fieldPermissions =
        options['field_permissions'] as Map<String, dynamic>?;
    final initialValues = options['initial_values'] as Map<String, dynamic>?;

    if (fieldPermissions == null) return const SizedBox.shrink();

    final condicionPermissions =
        fieldPermissions['condicion'] as Map<String, dynamic>?;
    final isCondicionEditable = condicionPermissions?['editable'] ?? true;
    final initialCondicion = initialValues?['condicion']?.toString();

    // Si no es editable y no hay valor inicial
    if (!isCondicionEditable &&
        (initialCondicion == null || initialCondicion.isEmpty)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.block, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text(
              'Sin permisos para crear fotos',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'No tienes una condición asignada para crear nuevas fotos de presentación.',
              style: TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si condición fija (no editable pero hay un valor inicial)
    if (!isCondicionEditable &&
        initialCondicion != null &&
        initialCondicion.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getCondicionColor(initialCondicion).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getCondicionColor(initialCondicion).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock,
              color: _getCondicionColor(initialCondicion),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Condición fija: $initialCondicion',
                style: TextStyle(
                  color: _getCondicionColor(initialCondicion),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================================
  // CAMPOS DEL FORMULARIO
  // ============================================================================
  Widget _buildFormFields(
    Map<String, dynamic> options,
    DetalleRegistroModel detalle,
  ) {
    final fieldPermissions =
        options['field_permissions'] as Map<String, dynamic>?;
    final initialValues = options['initial_values'] as Map<String, dynamic>?;
    final condicionPermissions =
        fieldPermissions?['condicion'] as Map<String, dynamic>?;
    final isCondicionEditable = condicionPermissions?['editable'] ?? true;
    final initialCondicion = initialValues?['condicion']?.toString();

    // Filtrar condiciones disponibles según permisos
    List<IdValuePair> condicionesDisponibles = detalle.registrosVin
        .map(
          (registro) => IdValuePair(id: registro.id, value: registro.condicion),
        )
        .toList();

    // Aplicar filtros según permisos
    if (!isCondicionEditable) {
      if (initialCondicion != null && initialCondicion.isNotEmpty) {
        condicionesDisponibles = condicionesDisponibles
            .where((condicion) => condicion.value == initialCondicion)
            .toList();
      } else {
        condicionesDisponibles = [];
      }
    }

    // Autoselección estricta para modo crear
    if (!isEditMode &&
        initialCondicion != null &&
        initialCondicion.isNotEmpty &&
        _selectedRegistroVinId == null &&
        condicionesDisponibles.isNotEmpty) {
      final registroCoincidente = condicionesDisponibles
          .where((registro) => registro.value == initialCondicion)
          .firstOrNull;

      if (registroCoincidente != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedRegistroVinId == null) {
            setState(() {
              _selectedRegistroVinId = registroCoincidente.id;
            });
          }
        });
      }
    }

    final tiposDisponibles =
        options['tipos_disponibles'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de la Foto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Campo Condición/Registro VIN
        DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: _selectedRegistroVinId,
          decoration: InputDecoration(
            labelText: 'Condición *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.timeline),
            helperText: 'Selecciona la condición del registro VIN',
            suffixIcon: !isCondicionEditable
                ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                : null,
          ),
          items: condicionesDisponibles.isNotEmpty
              ? condicionesDisponibles.map<DropdownMenuItem<int>>((condicion) {
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
                }).toList()
              : null,
          onChanged: isCondicionEditable && condicionesDisponibles.isNotEmpty
              ? (value) => setState(() => _selectedRegistroVinId = value)
              : null,
          validator: (value) =>
              value == null ? 'Seleccione una condición' : null,
          disabledHint: condicionesDisponibles.isEmpty
              ? const Text(
                  'Sin condiciones disponibles',
                  style: TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
        ),

        // Mensaje de error para condición
        _buildCondicionErrorMessage(options),

        const SizedBox(height: 16),

        // Campo Tipo de Foto
        DropdownButtonFormField<String>(
          initialValue: _selectedTipo,
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

        // Campo N° Documento
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

  Widget _buildCondicionErrorMessage(Map<String, dynamic> options) {
    final fieldPermissions =
        options['field_permissions'] as Map<String, dynamic>?;
    final initialValues = options['initial_values'] as Map<String, dynamic>?;
    final condicionPermissions =
        fieldPermissions?['condicion'] as Map<String, dynamic>?;
    final isCondicionEditable = condicionPermissions?['editable'] ?? true;
    final initialCondicion = initialValues?['condicion']?.toString();

    if (!isCondicionEditable &&
        initialCondicion != null &&
        initialCondicion.isNotEmpty &&
        _selectedRegistroVinId == null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No se puede crear foto: No existe un registro VIN con condición "$initialCondicion" para este vehículo.',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================================
  // SECCIÓN DE FOTO
  // ============================================================================
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
          cameraResolution: CameraResolution.veryHigh,
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
  // BOTONES DE ACCIÓN
  // ============================================================================
  Widget _buildActionButtons() {
    final optionsAsync = ref.watch(fotosOptionsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: optionsAsync.when(
        data: (options) => _buildActionButtonsContent(options),
        loading: () => _buildDisabledButtons(),
        error: (error, stackTrace) => _buildDisabledButtons(),
      ),
    );
  }

  Widget _buildActionButtonsContent(Map<String, dynamic> options) {
    final canSave = _canSubmit(options);

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
            onPressed: (_isLoading || !canSave) ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: canSave && _selectedTipo != null
                  ? _getTipoColor(_selectedTipo!)
                  : (canSave ? const Color(0xFF00B4D8) : Colors.grey),
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
                : Text(_submitButtonText(options)),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Cargar...'),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // VALIDACIÓN Y SUBMIT
  // ============================================================================
  bool _canSubmit(Map<String, dynamic> options) {
    // Validaciones básicas
    if (_selectedTipo == null || _selectedRegistroVinId == null) {
      return false;
    }

    if (!isEditMode && _fotoPath == null) {
      return false;
    }

    // Validación de permisos de condición
    final fieldPermissions =
        options['field_permissions'] as Map<String, dynamic>?;
    final initialValues = options['initial_values'] as Map<String, dynamic>?;
    final condicionPermissions =
        fieldPermissions?['condicion'] as Map<String, dynamic>?;
    final isCondicionEditable = condicionPermissions?['editable'] ?? true;
    final initialCondicion = initialValues?['condicion']?.toString();

    if (!isCondicionEditable &&
        initialCondicion != null &&
        initialCondicion.isNotEmpty &&
        _selectedRegistroVinId == null) {
      return false;
    }

    return true;
  }

  String _submitButtonText(Map<String, dynamic> options) {
    if (_isLoading) return '...';
    if (isEditMode) return 'Actualizar';

    if (!_canSubmit(options)) {
      final fieldPermissions =
          options['field_permissions'] as Map<String, dynamic>?;
      final condicionPermissions =
          fieldPermissions?['condicion'] as Map<String, dynamic>?;
      final isCondicionEditable = condicionPermissions?['editable'] ?? true;

      if (!isCondicionEditable && _selectedRegistroVinId == null) {
        return 'Sin condición válida';
      }
      return 'Datos incompletos';
    }

    return 'Guardar';
  }

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

  // ============================================================================
  // ESTADOS DE ERROR Y CARGA
  // ============================================================================
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
  // MENSAJES
  // ============================================================================
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

  // ============================================================================
  // HELPERS PARA COLORES E ÍCONOS
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
}

// ============================================================================
// CLASE AUXILIAR PARA ID-VALUE PAIRS
// ============================================================================
class IdValuePair {
  final int id;
  final String value;

  IdValuePair({required this.id, required this.value});
}
