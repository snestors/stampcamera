// lib/widgets/autos/forms/dano_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';

class DanoForm extends ConsumerStatefulWidget {
  final String vin;
  final int? danoId; // Para modo edición

  const DanoForm({super.key, required this.vin, this.danoId});

  @override
  ConsumerState<DanoForm> createState() => _DanoFormState();
}

class _DanoFormState extends ConsumerState<DanoForm> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();

  // Campos requeridos
  int? _selectedRegistroVinId;
  int? _selectedTipoDano;
  int? _selectedAreaDano;
  int? _selectedSeveridad;

  // Campos opcionales
  List<int> _selectedZonas = [];
  int? _selectedResponsabilidad;
  int? _selectedFotoPresentacion;
  bool _relevante = false;

  // Gestión de imágenes
  List<String?> _imagenesPaths = [];
  List<DanoImagen> _imagenesOriginales = [];

  // Estado
  bool _isLoading = false;
  bool _initialized = false;

  bool get isEditMode => widget.danoId != null;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync = ref.watch(detalleRegistroProvider(widget.vin));
    final optionsAsync = ref.watch(danosOptionsProvider);

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
            isEditMode ? Icons.edit : Icons.add_circle_outline,
            color: const Color(0xFFDC2626),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditMode ? 'Editar Daño' : 'Nuevo Daño',
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
        'No puedes crear daños, falta registrar VIN primero',
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
      error: (error, _) => _buildErrorState('Error cargando opciones'),
    );
  }

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================
  void _initializeSelection(DetalleRegistroModel detalle) {
    if (isEditMode && widget.danoId != null) {
      final danoActual = detalle.danos.firstWhere(
        (d) => d.id == widget.danoId,
        orElse: () => throw Exception('Daño no encontrado'),
      );

      _selectedTipoDano = danoActual.tipoDano.id;
      _selectedAreaDano = danoActual.areaDano.id;
      _selectedSeveridad = danoActual.severidad.id;
      _selectedZonas = danoActual.zonas.map((z) => z.id).toList();
      _selectedResponsabilidad = danoActual.responsabilidad?.id;
      _selectedFotoPresentacion = danoActual.nDocumento?.id;
      _relevante = danoActual.relevante;
      _descripcionController.text = danoActual.descripcion ?? '';

      if (danoActual.condicion?.id != null) {
        final registroVin = detalle.registrosVin.firstWhere(
          (r) => r.condicion == danoActual.condicion!.value,
          orElse: () => detalle.registrosVin.first,
        );
        _selectedRegistroVinId = registroVin.id;
      } else {
        _selectedRegistroVinId = detalle.registrosVin.first.id;
      }

      _imagenesOriginales = danoActual.imagenes.toList();
      _imagenesPaths = _imagenesOriginales
          .map((img) => img.imagenUrl!)
          .cast<String?>()
          .toList();

      if (_imagenesPaths.isEmpty) {
        _imagenesPaths.add(null);
      }
    } else {
      // Modo crear: La autoselección se maneja en _buildCondicionField
      _imagenesPaths.add(null);
    }

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
          _buildCondicionField(detalle, options),
          _buildCondicionErrorMessage(options),
          const SizedBox(height: 16),
          _buildRequiredFields(options),
          const SizedBox(height: 16),
          _buildOptionalFields(options, detalle),
          const SizedBox(height: 16),
          _buildImagesSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================================
  // CAMPO CONDICIÓN
  // ============================================================================
  Widget _buildCondicionField(
    DetalleRegistroModel detalle,
    Map<String, dynamic> options,
  ) {
    final condicionesDisponibles = detalle.registrosVin
        .map(
          (registro) => IdValuePair(id: registro.id, value: registro.condicion),
        )
        .toList();

    final fieldPermissions =
        options['field_permissions'] as Map<String, dynamic>?;
    final initialValues = options['initial_values'] as Map<String, dynamic>?;
    final condicionPermissions =
        fieldPermissions?['condicion'] as Map<String, dynamic>?;
    final isCondicionEditable = condicionPermissions?['editable'] ?? true;
    final initialCondicion = initialValues?['condicion']?.toString();

    // Filtrar condiciones según permisos
    List<IdValuePair> condicionesFiltradas = [...condicionesDisponibles];

    if (!isCondicionEditable) {
      if (initialCondicion != null && initialCondicion.isNotEmpty) {
        condicionesFiltradas = condicionesDisponibles
            .where((condicion) => condicion.value == initialCondicion)
            .toList();
      } else {
        condicionesFiltradas = [];
      }
    }

    // Autoselección estricta
    if (initialCondicion != null &&
        initialCondicion.isNotEmpty &&
        _selectedRegistroVinId == null &&
        condicionesFiltradas.isNotEmpty) {
      final registroCoincidente = condicionesFiltradas
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

    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: _selectedRegistroVinId,
      decoration: InputDecoration(
        labelText: 'Condición *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.timeline),
        helperText: 'Selecciona el registro VIN al que pertenece el daño',
        suffixIcon: !isCondicionEditable
            ? const Icon(Icons.lock, size: 16, color: Colors.grey)
            : null,
      ),
      items: condicionesFiltradas.isNotEmpty
          ? condicionesFiltradas.map<DropdownMenuItem<int>>((condicion) {
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
      onChanged: isCondicionEditable && condicionesFiltradas.isNotEmpty
          ? (value) => setState(() => _selectedRegistroVinId = value)
          : null,
      validator: (value) => value == null ? 'Seleccione una condición' : null,
      disabledHint: condicionesFiltradas.isEmpty
          ? const Text(
              'Sin condiciones disponibles',
              style: TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            )
          : null,
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
        margin: const EdgeInsets.only(top: 8, bottom: 16),
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
                'No se puede crear daño: No existe un registro VIN con condición "$initialCondicion" para este vehículo.',
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
  // CAMPOS REQUERIDOS
  // ============================================================================
  Widget _buildRequiredFields(Map<String, dynamic> options) {
    final tiposDano = options['tipos_dano'] as List<dynamic>? ?? [];
    final areasDano = options['areas_dano'] as List<dynamic>? ?? [];
    final severidades = options['severidades'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Campos Requeridos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<int>(
          isExpanded: true,
          value: _selectedTipoDano,
          decoration: const InputDecoration(
            labelText: 'Tipo de Daño *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.report_problem, color: Color(0xFFDC2626)),
          ),
          items: tiposDano.map<DropdownMenuItem<int>>((tipo) {
            return DropdownMenuItem(
              value: tipo['value'],
              child: Text(tipo['label'], style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedTipoDano = value),
          validator: (value) =>
              value == null ? 'Seleccione el tipo de daño' : null,
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<int>(
          isExpanded: true,
          value: _selectedAreaDano,
          decoration: const InputDecoration(
            labelText: 'Área de Daño *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on, color: Color(0xFF059669)),
          ),
          items: areasDano.map<DropdownMenuItem<int>>((area) {
            return DropdownMenuItem(
              value: area['value'],
              child: Text(area['label'], style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedAreaDano = value),
          validator: (value) =>
              value == null ? 'Seleccione el área de daño' : null,
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<int>(
          value: _selectedSeveridad,
          decoration: const InputDecoration(
            labelText: 'Severidad *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.priority_high, color: Color(0xFFF59E0B)),
          ),
          items: severidades.map<DropdownMenuItem<int>>((severidad) {
            return DropdownMenuItem(
              value: severidad['value'],
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getSeveridadColor(severidad['label']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    severidad['label'],
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedSeveridad = value),
          validator: (value) =>
              value == null ? 'Seleccione la severidad' : null,
        ),
      ],
    );
  }

  // ============================================================================
  // CAMPOS OPCIONALES
  // ============================================================================
  Widget _buildOptionalFields(
    Map<String, dynamic> options,
    DetalleRegistroModel detalle,
  ) {
    final zonasDano = options['zonas_danos'] as List<dynamic>? ?? [];
    final responsabilidades =
        options['responsabilidades'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Campos Opcionales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        _buildMultiSelectField(
          'Zonas',
          zonasDano,
          _selectedZonas,
          Icons.grid_view,
          (values) => setState(() => _selectedZonas = values),
        ),

        const SizedBox(height: 12),

        _buildFotoPresentacionField(detalle),

        const SizedBox(height: 12),

        DropdownButtonFormField<int>(
          value: _selectedResponsabilidad,
          decoration: const InputDecoration(
            labelText: 'Responsabilidad',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          items: responsabilidades.map<DropdownMenuItem<int>>((resp) {
            return DropdownMenuItem(
              value: resp['value'],
              child: Text(resp['label']),
            );
          }).toList(),
          onChanged: (value) =>
              setState(() => _selectedResponsabilidad = value),
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Describe el daño en detalle...',
          ),
          maxLines: 3,
        ),

        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Marcar como relevante'),
          subtitle: const Text('El daño es significativo para la inspección'),
          value: _relevante,
          onChanged: (value) => setState(() => _relevante = value),
          activeColor: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  Widget _buildFotoPresentacionField(DetalleRegistroModel detalle) {
    final fotosDisponibles = detalle.fotosPresentacion
        .where((foto) => foto.nDocumento != null && foto.nDocumento!.isNotEmpty)
        .toList();

    return DropdownButtonFormField<int>(
      value: _selectedFotoPresentacion,
      decoration: const InputDecoration(
        labelText: 'Documento de Referencia',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.photo_library, color: Color(0xFF8B5CF6)),
        helperText: 'Asocia una foto/documento existente al daño (opcional)',
      ),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text(
            'Sin documento asociado',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ...fotosDisponibles.map<DropdownMenuItem<int>>((foto) {
          return DropdownMenuItem<int>(
            value: foto.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getFotoTipoColor(foto.tipo).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _getFotoTipoIcon(foto.tipo),
                    size: 16,
                    color: _getFotoTipoColor(foto.tipo),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getFotoTipoLabel(foto.tipo),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '- ${foto.nDocumento!}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) => setState(() => _selectedFotoPresentacion = value),
    );
  }

  Widget _buildMultiSelectField(
    String label,
    List<dynamic> options,
    List<int> selectedValues,
    IconData icon,
    Function(List<int>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              _showMultiSelectDialog(label, options, selectedValues, onChanged),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(icon),
            ),
            child: Text(
              selectedValues.isEmpty
                  ? 'Seleccionar ${label.toLowerCase()}'
                  : '${selectedValues.length} ${label.toLowerCase()} seleccionadas',
              style: TextStyle(
                color: selectedValues.isEmpty ? Colors.grey[600] : null,
              ),
            ),
          ),
        ),
        if (selectedValues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: selectedValues.map((id) {
              final option = options.firstWhere((opt) => opt['value'] == id);
              return Chip(
                label: Text(
                  option['label'],
                  style: const TextStyle(fontSize: 12),
                ),
                onDeleted: () {
                  final newValues = List<int>.from(selectedValues);
                  newValues.remove(id);
                  onChanged(newValues);
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // SECCIÓN DE IMÁGENES
  // ============================================================================
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_camera, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            const Text(
              'Imágenes del Daño',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_imagenesPaths.where((path) => path != null).length} foto${_imagenesPaths.where((path) => path != null).length != 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._buildCameraCards(),
      ],
    );
  }

  List<Widget> _buildCameraCards() {
    List<Widget> widgets = [];

    if (_imagenesPaths.isEmpty && !isEditMode) {
      _imagenesPaths.add(null);
    }

    for (int i = 0; i < _imagenesPaths.length; i++) {
      final isNetworkImage =
          _imagenesPaths[i] != null && _imagenesPaths[i]!.startsWith('http');

      widgets.add(
        ReusableCameraCard(
          title: 'Foto ${i + 1} del Daño',
          subtitle: _imagenesPaths[i] == null
              ? 'Toma o selecciona una imagen del daño'
              : 'Documenta el daño encontrado',
          currentImagePath: isNetworkImage ? null : _imagenesPaths[i],
          currentImageUrl: isNetworkImage ? _imagenesPaths[i] : null,
          onImageSelected: (path) => setState(() => _imagenesPaths[i] = path),
          showGalleryOption: true,
          primaryColor: const Color(0xFFDC2626),
        ),
      );

      widgets.add(const SizedBox(height: 12));

      if (_imagenesPaths[i] != null) {
        widgets.add(
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _eliminarImagen(i),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Eliminar Foto ${i + 1}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 16));
      }
    }

    widgets.add(
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _agregarNuevaFoto,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Agregar Otra Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );

    return widgets;
  }

  void _agregarNuevaFoto() => setState(() => _imagenesPaths.add(null));

  void _eliminarImagen(int index) {
    final imagePath = _imagenesPaths[index];
    final isNetworkImage = imagePath?.startsWith('http') ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Estás seguro de eliminar la Foto ${index + 1}?'),
            if (isNetworkImage) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta imagen se eliminará permanentemente del servidor.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _imagenesPaths.removeAt(index);
                if (_imagenesPaths.isEmpty && !isEditMode) {
                  _imagenesPaths.add(null);
                }
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN
  // ============================================================================
  Widget _buildActionButtons() {
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
              onPressed: (_isLoading || !_canSubmit) ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                disabledBackgroundColor: Colors.grey[300],
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
                  : Text(_submitButtonText),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // VALIDACIÓN Y SUBMIT
  // ============================================================================
  bool get _canSubmit {
    if (_selectedRegistroVinId == null ||
        _selectedTipoDano == null ||
        _selectedAreaDano == null ||
        _selectedSeveridad == null) {
      return false;
    }

    if (!isEditMode) {
      final options = ref.read(danosOptionsProvider).valueOrNull;
      if (options != null) {
        final fieldPermissions =
            options['field_permissions'] as Map<String, dynamic>?;
        final initialValues =
            options['initial_values'] as Map<String, dynamic>?;
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
      }
    }

    return true;
  }

  String get _submitButtonText {
    if (_isLoading) return '...';
    if (isEditMode) return 'Actualizar Daño';

    if (!_canSubmit && _selectedRegistroVinId == null) {
      final options = ref.read(danosOptionsProvider).valueOrNull;
      if (options != null) {
        final fieldPermissions =
            options['field_permissions'] as Map<String, dynamic>?;
        final condicionPermissions =
            fieldPermissions?['condicion'] as Map<String, dynamic>?;
        final isCondicionEditable = condicionPermissions?['editable'] ?? true;

        if (!isCondicionEditable) {
          return 'Sin condición válida';
        }
      }
      return 'Datos incompletos';
    }

    final imageCount = _getValidImages()?.length ?? 0;
    return imageCount > 0
        ? 'Crear Daño ($imageCount foto${imageCount != 1 ? 's' : ''})'
        : 'Crear Daño';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRegistroVinId == null) {
      _showError('Seleccione una condición');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(detalleRegistroProvider(widget.vin).notifier);
      bool success = false;

      if (isEditMode) {
        final nuevasImagenes = _getNewImages();
        final imagenesEliminadas = _getRemovedImageIds();

        success = await notifier.updateDano(
          danoId: widget.danoId!,
          registroVinId: _selectedRegistroVinId,
          tipoDano: _selectedTipoDano,
          areaDano: _selectedAreaDano,
          severidad: _selectedSeveridad,
          zonas: _selectedZonas.isEmpty ? null : _selectedZonas,
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          responsabilidad: _selectedResponsabilidad,
          relevante: _relevante,
          newImages: nuevasImagenes,
          removedImageIds: imagenesEliminadas,
          nDocumento: _selectedFotoPresentacion,
        );
      } else {
        success = await notifier.createDanoWithImages(
          registroVinId: _selectedRegistroVinId,
          tipoDano: _selectedTipoDano!,
          areaDano: _selectedAreaDano!,
          severidad: _selectedSeveridad!,
          zonas: _selectedZonas.isEmpty ? null : _selectedZonas,
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          responsabilidad: _selectedResponsabilidad,
          relevante: _relevante,
          imagenes: _getValidImages(),
          nDocumento: _selectedFotoPresentacion,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          _showSuccess(
            isEditMode
                ? '✅ Daño actualizado exitosamente'
                : '✅ Daño creado exitosamente',
          );
        } else {
          _showError(
            '❌ Error al ${isEditMode ? 'actualizar' : 'crear'} el daño',
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
  // HELPERS PARA GESTIÓN DE IMÁGENES
  // ============================================================================
  List<File>? _getValidImages() {
    if (isEditMode) return null;

    final validPaths = _imagenesPaths
        .where((path) => path != null && !path.startsWith('http'))
        .toList();

    if (validPaths.isEmpty) return null;
    return validPaths.map((path) => File(path!)).toList();
  }

  List<File>? _getNewImages() {
    if (!isEditMode) return null;

    final nuevasImagenes = <File>[];
    for (final imagePath in _imagenesPaths) {
      if (imagePath != null && !imagePath.startsWith('http')) {
        final esImagenOriginal = _imagenesOriginales.any(
          (img) => img.imagenUrl == imagePath,
        );
        if (!esImagenOriginal) {
          nuevasImagenes.add(File(imagePath));
        }
      }
    }

    return nuevasImagenes.isEmpty ? null : nuevasImagenes;
  }

  List<int>? _getRemovedImageIds() {
    if (!isEditMode) return null;

    final eliminadas = <int>[];
    for (final imagenOriginal in _imagenesOriginales) {
      final urlOriginal = imagenOriginal.imagenUrl!;
      if (!_imagenesPaths.contains(urlOriginal)) {
        eliminadas.add(imagenOriginal.id);
      }
    }

    return eliminadas.isEmpty ? null : eliminadas;
  }

  // ============================================================================
  // DIÁLOGOS Y MENSAJES
  // ============================================================================
  void _showMultiSelectDialog(
    String title,
    List<dynamic> options,
    List<int> selectedValues,
    Function(List<int>) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar $title'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedValues.contains(option['value']);

              return CheckboxListTile(
                title: Text(option['label']),
                value: isSelected,
                onChanged: (checked) {
                  final newValues = List<int>.from(selectedValues);
                  if (checked == true) {
                    newValues.add(option['value']);
                  } else {
                    newValues.remove(option['value']);
                  }
                  onChanged(newValues);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
        Text('Cargando opciones...'),
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
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(danosOptionsProvider),
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

  Color _getSeveridadColor(String severidad) {
    if (severidad.contains('LEVE')) return const Color(0xFF059669);
    if (severidad.contains('MEDIO')) return const Color(0xFFF59E0B);
    if (severidad.contains('GRAVE')) return const Color(0xFFDC2626);
    if (severidad.contains('FALTANTE')) return const Color(0xFF8B5CF6);
    if (severidad.contains('CERO')) return const Color(0xFF6B7280);
    return const Color(0xFF6B7280);
  }

  Color _getFotoTipoColor(String tipo) {
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

  IconData _getFotoTipoIcon(String tipo) {
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

  String _getFotoTipoLabel(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'TARJA':
        return 'Tarja/Documento';
      case 'AUTO':
        return 'Foto del Vehículo';
      case 'KM':
        return 'Kilometraje';
      case 'DR':
        return 'Damage Report';
      case 'OTRO':
        return 'Otros Documentos';
      default:
        return tipo;
    }
  }
}
