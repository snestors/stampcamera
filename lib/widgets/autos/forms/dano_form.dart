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
  int? _selectedFotoPresentacion; // ✅ NUEVO: ID de la foto de presentación
  bool _relevante = false;

  // Gestión de imágenes
  List<String?> _imagenesPaths =
      []; // Lista de paths/URLs (nulls para cards vacíos)
  List<DanoImagen> _imagenesOriginales = []; // Imágenes originales con ID y URL

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
  // CAMPO DE FOTO DE PRESENTACIÓN (DOCUMENTO)
  // ============================================================================

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
              mainAxisSize: MainAxisSize.min, // ✅ Evita overflow
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
                  fit: FlexFit.loose, // ✅ Se ajusta sin forzar expansión
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
                      const SizedBox(
                        width: 8,
                      ), // ✅ Espaciado entre tipo y documento
                      Text(
                        '- ${foto.nDocumento!}', // ✅ Añadir bullet point para separar visualmente
                        style: const TextStyle(
                          fontSize: 15, // ✅ Mismo tamaño que el tipo (era 11)
                          // ✅ Color verde para destacar
                          fontWeight: FontWeight.w600, // ✅ Un poco más bold
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
        'No puedes crear daños, falta registrar VIN primero',
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
      error: (error, _) => _buildErrorState('Error cargando opciones'),
    );
  }

  void _initializeSelection(DetalleRegistroModel detalle) {
    if (isEditMode && widget.danoId != null) {
      // ✅ MODO EDICIÓN: Buscar el daño actual y precargar valores
      final danoActual = detalle.danos.firstWhere(
        (d) => d.id == widget.danoId,
        orElse: () => throw Exception('Daño no encontrado'),
      );

      // Precargar campos del formulario
      _selectedTipoDano = danoActual.tipoDano.id;
      _selectedAreaDano = danoActual.areaDano.id;
      _selectedSeveridad = danoActual.severidad.id;
      _selectedZonas = danoActual.zonas.map((z) => z.id).toList();
      _selectedResponsabilidad = danoActual.responsabilidad?.id;
      _selectedFotoPresentacion = danoActual.nDocumento?.id; // ✅ NUEVO
      _relevante = danoActual.relevante;
      _descripcionController.text = danoActual.descripcion ?? '';

      // Buscar el registro VIN asociado
      if (danoActual.condicion?.id != null) {
        final registroVin = detalle.registrosVin.firstWhere(
          (r) => r.condicion == danoActual.condicion!.value,
          orElse: () => detalle.registrosVin.first,
        );
        _selectedRegistroVinId = registroVin.id;
      } else {
        _selectedRegistroVinId = detalle.registrosVin.first.id;
      }

      // ✅ Precargar imágenes existentes con ID y URL
      _imagenesOriginales = danoActual.imagenes.toList();
      _imagenesPaths = _imagenesOriginales
          .map((img) => img.imagenUrl!)
          .cast<String?>()
          .toList();

      // Si no hay imágenes, agregar un card vacío
      if (_imagenesPaths.isEmpty) {
        _imagenesPaths.add(null);
      }
    } else {
      // ✅ MODO CREAR: seleccionar el registro más reciente
      if (detalle.registrosVin.isNotEmpty) {
        final sortedRegistros = List<RegistroVin>.from(detalle.registrosVin);
        sortedRegistros.sort(
          (a, b) => (b.fecha ?? '').compareTo(a.fecha ?? ''),
        );
        _selectedRegistroVinId = sortedRegistros.first.id;
      }

      // Agregar un card vacío por defecto
      _imagenesPaths.add(null);
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
          _buildCondicionField(detalle),
          const SizedBox(height: 16),
          _buildCamposRequeridos(options),
          const SizedBox(height: 16),
          _buildCamposOpcionales(
            options,
            detalle,
          ), // ✅ Pasar detalle como parámetro
          const SizedBox(height: 16),
          _buildImagenesSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCondicionField(DetalleRegistroModel detalle) {
    final condicionesDisponibles = detalle.registrosVin
        .map(
          (registro) => IdValuePair(id: registro.id, value: registro.condicion),
        )
        .toList();

    return DropdownButtonFormField<int>(
      value: _selectedRegistroVinId,
      decoration: const InputDecoration(
        labelText: 'Condición *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.timeline),
        helperText: 'Selecciona el registro VIN al que pertenece el daño',
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
      validator: (value) => value == null ? 'Seleccione una condición' : null,
    );
  }

  Widget _buildCamposRequeridos(Map<String, dynamic> options) {
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

        // Tipo de Daño
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

        // Área de Daño
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

        // Severidad
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

  Widget _buildCamposOpcionales(
    Map<String, dynamic> options,
    DetalleRegistroModel detalle, // ✅ Agregar detalle como parámetro
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

        // Zonas (Múltiple selección)
        _buildMultiSelectField(
          'Zonas',
          zonasDano,
          _selectedZonas,
          Icons.grid_view,
          (values) => setState(() => _selectedZonas = values),
        ),
        const SizedBox(height: 12),

        // Foto de Presentación (Documento)
        _buildFotoPresentacionField(detalle),
        const SizedBox(height: 12),

        // Responsabilidad
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

        // Descripción
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

        // Relevante
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
  // SECCIÓN DE IMÁGENES MEJORADA
  // ============================================================================

  Widget _buildImagenesSection() {
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

        // ✅ Lista de ReusableCameraCard
        ..._buildCameraCardsList(),
      ],
    );
  }

  List<Widget> _buildCameraCardsList() {
    List<Widget> widgets = [];

    // Si no hay cards, agregar uno vacío por defecto (solo en modo crear)
    if (_imagenesPaths.isEmpty && !isEditMode) {
      _imagenesPaths.add(null);
    }

    // Renderizar cada ReusableCameraCard
    for (int i = 0; i < _imagenesPaths.length; i++) {
      final isNetworkImage =
          _imagenesPaths[i] != null && _imagenesPaths[i]!.startsWith('http');

      widgets.add(
        ReusableCameraCard(
          title: 'Foto ${i + 1} del Daño',
          subtitle: _imagenesPaths[i] == null
              ? 'Toma o selecciona una imagen del daño'
              : 'Documenta el daño encontrado',
          // ✅ Soporte para imágenes existentes (URLs) e imágenes nuevas (paths)
          currentImagePath: isNetworkImage ? null : _imagenesPaths[i],
          currentImageUrl: isNetworkImage ? _imagenesPaths[i] : null,
          onImageSelected: (path) {
            setState(() {
              _imagenesPaths[i] = path; // Reemplazar con nueva imagen local
            });
          },
          showGalleryOption: true,
          primaryColor: const Color(0xFFDC2626),
        ),
      );

      widgets.add(const SizedBox(height: 12));

      // Botón eliminar solo si la foto ya tiene imagen
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
      } else {
        widgets.add(const SizedBox(height: 4));
      }
    }

    // Botón "Agregar Otra Foto" (siempre al final)
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

  void _agregarNuevaFoto() {
    setState(() {
      _imagenesPaths.add(null); // Agregar un card vacío
    });
  }

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
                // En modo crear: Si no quedan fotos, agregar un card vacío
                // En modo editar: Permitir eliminar todas las fotos
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
  // SUBMIT FORM
  // ============================================================================

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
        // ✅ MODO EDICIÓN
        final nuevasImagenes = _getNewImages();
        final imagenesEliminadas = _getRemovedImageIds();

        success = await notifier.updateDano(
          danoId: widget.danoId!,
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
          removedImageIds: imagenesEliminadas, // ✅ Cambio: ahora son IDs
          nDocumento:
              _selectedFotoPresentacion, // ✅ NUEVO: Foto de presentación
        );
      } else {
        // ✅ MODO CREAR
        success = await notifier.createDanoWithImages(
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
          nDocumento:
              _selectedFotoPresentacion, // ✅ NUEVO: Foto de presentación
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
    // Para modo crear: solo paths locales válidos
    if (isEditMode) return null;

    final validPaths = _imagenesPaths
        .where((path) => path != null && !path.startsWith('http'))
        .toList();

    if (validPaths.isEmpty) return null;

    return validPaths.map((path) => File(path!)).toList();
  }

  List<File>? _getNewImages() {
    // Para modo editar: solo paths locales que no son URLs originales
    if (!isEditMode) return null;

    final nuevasImagenes = <File>[];
    for (final imagePath in _imagenesPaths) {
      if (imagePath != null && !imagePath.startsWith('http')) {
        // Verificar que no sea una URL original (comparando con las URLs originales)
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
    // Para modo editar: IDs de imágenes originales que ya no están en la lista actual
    if (!isEditMode) return null;

    final eliminadas = <int>[];

    // Comparar las URLs originales con las actuales
    for (final imagenOriginal in _imagenesOriginales) {
      final urlOriginal = imagenOriginal.imagenUrl!;
      if (!_imagenesPaths.contains(urlOriginal)) {
        eliminadas.add(imagenOriginal.id);
      }
    }

    return eliminadas.isEmpty ? null : eliminadas;
  }

  // ============================================================================
  // MÉTODOS DE VALIDACIÓN PARA UI
  // ============================================================================

  /// Verifica si el formulario está listo para enviar
  bool get _canSubmit {
    // Campos requeridos básicos
    if (_selectedRegistroVinId == null ||
        _selectedTipoDano == null ||
        _selectedAreaDano == null ||
        _selectedSeveridad == null) {
      return false;
    }

    // En modo crear, al menos debe tener una imagen válida o permitir sin imágenes
    // En modo editar, puede no tener imágenes
    return true;
  }

  /// Obtiene el texto del botón de submit
  String get _submitButtonText {
    if (_isLoading) return '...';
    if (isEditMode) return 'Actualizar Daño';

    final imageCount = _getValidImages()?.length ?? 0;
    return imageCount > 0
        ? 'Crear Daño ($imageCount foto${imageCount != 1 ? 's' : ''})'
        : 'Crear Daño';
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
  // ESTADOS DE CARGA Y ERROR
  // ============================================================================

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
  // MÉTODOS DE INTERACCIÓN
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
    if (severidad.contains('LEVE')) return const Color(0xFF059669); // Verde
    if (severidad.contains('MEDIO')) return const Color(0xFFF59E0B); // Naranja
    if (severidad.contains('GRAVE')) return const Color(0xFFDC2626); // Rojo
    if (severidad.contains('FALTANTE'))
      return const Color(0xFF8B5CF6); // Púrpura
    if (severidad.contains('CERO')) return const Color(0xFF6B7280); // Gris
    return const Color(0xFF6B7280);
  }

  // ============================================================================
  // HELPERS PARA FOTOS DE PRESENTACIÓN
  // ============================================================================

  Color _getFotoTipoColor(String tipo) {
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

  IconData _getFotoTipoIcon(String tipo) {
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
