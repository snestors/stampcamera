// screens/autos/contenedores/contenedor_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/providers/autos/contenedor_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';
import 'package:stampcamera/core/core.dart';

class ContenedorForm extends ConsumerStatefulWidget {
  final ContenedorModel? contenedor; // null = crear, no null = editar

  const ContenedorForm({super.key, this.contenedor});

  @override
  ConsumerState<ContenedorForm> createState() => _ContenedorFormState();
}

class _ContenedorFormState extends ConsumerState<ContenedorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nContenedorController = TextEditingController();
  final _precinto1Controller = TextEditingController();
  final _precinto2Controller = TextEditingController();

  int? _selectedNaveId;
  int? _selectedZonaId;

  // Paths de imágenes NUEVAS
  String? _fotoContenedorPath;
  String? _fotoPrecinto1Path;
  String? _fotoPrecinto2Path;
  String? _fotoContenedorVacioPath;

  // ✅ NUEVO: Flags para eliminar fotos existentes
  bool _removeFotoContenedor = false;
  bool _removeFotoPrecinto1 = false;
  bool _removeFotoPrecinto2 = false;
  bool _removeFotoContenedorVacio = false;

  bool _isLoading = false;

  bool get isEditMode => widget.contenedor != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nContenedorController.dispose();
    _precinto1Controller.dispose();
    _precinto2Controller.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.contenedor != null) {
      // Modo edición
      final contenedor = widget.contenedor!;
      _nContenedorController.text = contenedor.nContenedor;
      _precinto1Controller.text = contenedor.precinto1 ?? '';
      _precinto2Controller.text = contenedor.precinto2 ?? '';
      _selectedNaveId = contenedor.naveDescarga.id;
      _selectedZonaId = contenedor.zonaInspeccion?.id;
    }
  }

  void _initializeWithOptions(ContenedorOptions options) {
    // Solo aplicar initial_values si estamos creando (no editando)
    if (widget.contenedor == null &&
        options.initialValues.isNotEmpty &&
        mounted) {
      // Aplicar valores iniciales para nave_descarga
      if (options.initialValues.containsKey('nave_descarga')) {
        final naveId = options.initialValues['nave_descarga'] as int?;
        if (naveId != null && _selectedNaveId == null) {
          if (mounted) {
            setState(() {
              _selectedNaveId = naveId;
            });
          }
        }
      }

      // Aplicar valores iniciales para zona_inspeccion
      if (options.initialValues.containsKey('zona_inspeccion')) {
        final zonaId = options.initialValues['zona_inspeccion'] as int?;
        if (zonaId != null && _selectedZonaId == null) {
          if (mounted) {
            setState(() {
              _selectedZonaId = zonaId;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(contenedorOptionsProvider);

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
              child: optionsAsync.when(
                data: (options) {
                  // Inicializar valores una sola vez cuando las opciones están disponibles
                  if (widget.contenedor == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _initializeWithOptions(options);
                      }
                    });
                  }
                  return _buildForm(context, options);
                },
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error),
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
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditMode ? 'Editar Contenedor' : 'Nuevo Contenedor',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, ContenedorOptions options) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // SECCIÓN 1: NAVE Y ZONA
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  icon: Icons.directions_boat,
                  title: 'Nave y Zona',
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: DesignTokens.spaceL),

                // Nave de descarga
                _buildDropdown<int>(
                  context: context,
                  label: 'Nave de Descarga *',
                  value: _selectedNaveId,
                  items: options.navesDisponibles
                      .map(
                        (nave) => DropdownMenuItem(
                          value: nave.id,
                          child: Text(
                            nave.nombre,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _canEditField('nave_descarga', options)
                      ? (value) {
                          if (mounted) {
                            setState(() => _selectedNaveId = value);
                          }
                        }
                      : null,
                  validator: _fieldRequired('nave_descarga', options)
                      ? (value) => value == null ? 'Seleccione una nave' : null
                      : null,
                ),

                const SizedBox(height: DesignTokens.spaceL),

                // Zona de inspección
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<int>(
                        context: context,
                        label: _fieldRequired('zona_inspeccion', options)
                            ? 'Zona de Inspección *'
                            : 'Zona de Inspección',
                        value: _selectedZonaId,
                        items: [
                          // ✅ NUEVO: Opción para limpiar zona
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text(
                              'Sin zona asignada',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          ...options.zonasDisponibles.map(
                            (zona) => DropdownMenuItem(
                              value: zona.id,
                              child: Text(
                                zona.nombre,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: _canEditField('zona_inspeccion', options)
                            ? (value) {
                                if (mounted) {
                                  setState(() => _selectedZonaId = value);
                                }
                              }
                            : null,
                        validator: _fieldRequired('zona_inspeccion', options)
                            ? (value) =>
                                  value == null ? 'Seleccione una zona' : null
                            : null,
                      ),
                    ),

                    // ✅ NUEVO: Botón para limpiar zona (solo en edición)
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spaceL),

          // SECCIÓN 2: NÚMERO DE CONTENEDOR Y FOTO
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  icon: Icons.inventory_2,
                  title: 'Información del Contenedor',
                  iconColor: AppColors.secondary,
                ),
                const SizedBox(height: DesignTokens.spaceL),

                // Número de contenedor
                _buildTextField(
                  context: context,
                  controller: _nContenedorController,
                  label: 'Número de Contenedor *',
                  hint: 'Ej: TCLU1234567',
                  enabled: _canEditField('n_contenedor', options),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Este campo es requerido';
                    }
                    if (value!.length < 10) {
                      return 'Debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: DesignTokens.spaceL),

                // Foto del contenedor CON opción de eliminar
                _buildCameraCardWithRemove(
                  title: 'Foto del Contenedor',
                  subtitle: 'Capture una imagen clara del contenedor',
                  currentImagePath: _fotoContenedorPath,
                  currentImageUrl: _getValidUrl(
                    widget.contenedor?.fotoContenedorUrl,
                  ),
                  thumbnailUrl: _getValidUrl(
                    widget.contenedor?.imagenThumbnailUrl,
                  ),
                  removeFlag: _removeFotoContenedor,
                  onImageSelected: (path) {
                    setState(() {
                      _fotoContenedorPath = path;
                      _removeFotoContenedor =
                          false; // Reset flag si se toma nueva foto
                    });
                  },
                  onRemoveToggle: (remove) {
                    setState(() {
                      _removeFotoContenedor = remove;
                      if (remove)
                        _fotoContenedorPath = null; // Limpiar nueva foto
                    });
                  },
                  primaryColor: AppColors.secondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spaceL),

          // SECCIÓN 3: PRECINTOS Y FOTOS
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  icon: Icons.lock_outline,
                  title: 'Precintos',
                  iconColor: AppColors.warning,
                ),
                const SizedBox(height: DesignTokens.spaceL),

                // Precinto 1 CON botón limpiar
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        context: context,
                        controller: _precinto1Controller,
                        label: 'Precinto 1',
                        hint: 'Ej: CV877664',
                      ),
                    ),
                    if (isEditMode && _precinto1Controller.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() => _precinto1Controller.clear());
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Limpiar precinto 1',
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: DesignTokens.spaceL),

                // Foto Precinto 1 CON opción de eliminar
                _buildCameraCardWithRemove(
                  title: 'Foto Precinto 1',
                  subtitle: 'Capture el primer precinto si existe',
                  currentImagePath: _fotoPrecinto1Path,
                  currentImageUrl: _getValidUrl(
                    widget.contenedor?.fotoPrecinto1Url,
                  ),
                  thumbnailUrl: _getValidUrl(
                    widget.contenedor?.imagenThumbnailPrecintoUrl,
                  ),
                  removeFlag: _removeFotoPrecinto1,
                  onImageSelected: (path) {
                    setState(() {
                      _fotoPrecinto1Path = path;
                      _removeFotoPrecinto1 = false;
                    });
                  },
                  onRemoveToggle: (remove) {
                    setState(() {
                      _removeFotoPrecinto1 = remove;
                      if (remove) _fotoPrecinto1Path = null;
                    });
                  },
                  primaryColor: AppColors.warning,
                ),

                const SizedBox(height: DesignTokens.spaceL),

                // Precinto 2 CON botón limpiar
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        context: context,
                        controller: _precinto2Controller,
                        label: 'Precinto 2',
                        hint: 'Ej: CV877665',
                      ),
                    ),
                    if (isEditMode && _precinto2Controller.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() => _precinto2Controller.clear());
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Limpiar precinto 2',
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: DesignTokens.spaceL),

                // Foto Precinto 2 CON opción de eliminar
                _buildCameraCardWithRemove(
                  title: 'Foto Precinto 2',
                  subtitle: 'Capture el segundo precinto si existe',
                  currentImagePath: _fotoPrecinto2Path,
                  currentImageUrl: _getValidUrl(
                    widget.contenedor?.fotoPrecinto2Url,
                  ),
                  thumbnailUrl: _getValidUrl(
                    widget.contenedor?.imagenThumbnailPrecinto2Url,
                  ),
                  removeFlag: _removeFotoPrecinto2,
                  onImageSelected: (path) {
                    setState(() {
                      _fotoPrecinto2Path = path;
                      _removeFotoPrecinto2 = false;
                    });
                  },
                  onRemoveToggle: (remove) {
                    setState(() {
                      _removeFotoPrecinto2 = remove;
                      if (remove) _fotoPrecinto2Path = null;
                    });
                  },
                  primaryColor: AppColors.warning,
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spaceL),

          // SECCIÓN 4: CONTENEDOR VACÍO
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  icon: Icons.view_in_ar,
                  title: 'Contenedor Vacío',
                  iconColor: AppColors.info,
                ),
                const SizedBox(height: DesignTokens.spaceL),

                // Foto Contenedor Vacío CON opción de eliminar
                _buildCameraCardWithRemove(
                  title: 'Foto Contenedor Vacío',
                  subtitle: 'Capture el contenedor una vez esté vacío',
                  currentImagePath: _fotoContenedorVacioPath,
                  currentImageUrl: _getValidUrl(
                    widget.contenedor?.fotoContenedorVacioUrl,
                  ),
                  thumbnailUrl: _getValidUrl(
                    widget.contenedor?.imagenThumbnailContenedorVacioUrl,
                  ),
                  removeFlag: _removeFotoContenedorVacio,
                  onImageSelected: (path) {
                    setState(() {
                      _fotoContenedorVacioPath = path;
                      _removeFotoContenedorVacio = false;
                    });
                  },
                  onRemoveToggle: (remove) {
                    setState(() {
                      _removeFotoContenedorVacio = remove;
                      if (remove) _fotoContenedorVacioPath = null;
                    });
                  },
                  primaryColor: AppColors.info,
                ),
              ],
            ),
          ),

          SizedBox(height: DesignTokens.spaceXXL),
        ],
      ),
    );
  }

  // ✅ NUEVO: Widget para cámara CON opción de eliminar (solo en edición)
  Widget _buildCameraCardWithRemove({
    required String title,
    required String subtitle,
    required String? currentImagePath,
    required String? currentImageUrl,
    required String? thumbnailUrl,
    required bool removeFlag,
    required Function(String) onImageSelected,
    required Function(bool) onRemoveToggle,
    required Color primaryColor,
  }) {
    // Si está marcado para eliminar, mostrar estado de eliminación
    if (removeFlag && isEditMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$title - Será eliminada',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onRemoveToggle(false),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ReusableCameraCard(
          title: title,
          subtitle: subtitle,
          currentImagePath: currentImagePath,
          currentImageUrl: currentImageUrl,
          thumbnailUrl: thumbnailUrl,
          onImageSelected: onImageSelected,
          primaryColor: primaryColor,
        ),
        // ✅ Botón para eliminar foto existente (solo en modo edición)
        if (isEditMode && currentImageUrl != null && !removeFlag)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => onRemoveToggle(true),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Eliminar foto existente'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  // Resto de widgets auxiliares (sin cambios)...
  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceS),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : AppColors.textLight.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceL,
              vertical: DesignTokens.spaceM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) {
    final enabled = onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceS),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : AppColors.textLight.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceL,
              vertical: DesignTokens.spaceM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: DesignTokens.spaceL),
          Text('Cargando opciones...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: AppEmptyState(
        icon: Icons.error_outline,
        title: 'Error al cargar',
        subtitle: error.toString(),
        color: AppColors.error,
        action: ElevatedButton.icon(
          onPressed: () => ref.invalidate(contenedorOptionsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN FIJOS EN LA PARTE INFERIOR
  // ============================================================================
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.textSecondary),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditMode ? 'Actualizar' : 'Crear Contenedor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares
  bool _canEditField(String fieldName, ContenedorOptions options) {
    return options.fieldPermissions[fieldName]?.editable ?? true;
  }

  bool _fieldRequired(String fieldName, ContenedorOptions options) {
    return options.fieldPermissions[fieldName]?.required ?? false;
  }

  String? _getValidUrl(String? url) {
    if (url == null || url.isEmpty || url.trim().isEmpty) {
      return null;
    }
    return url;
  }

  // ============================================================================
  // ✅ SUBMIT MEJORADO - Usa updateContenedorWithFiles
  // ============================================================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar nave_descarga solo si es requerido
    final optionsAsync = ref.read(contenedorOptionsProvider);
    if (optionsAsync.hasValue) {
      final options = optionsAsync.value!;
      if (_fieldRequired('nave_descarga', options) && _selectedNaveId == null) {
        _showError('Debe seleccionar una nave');
        return;
      }
      if (_fieldRequired('zona_inspeccion', options) &&
          _selectedZonaId == null) {
        _showError('Debe seleccionar una zona de inspección');
        return;
      }
    } else if (_selectedNaveId == null) {
      // Fallback si no hay opciones disponibles
      _showError('Debe seleccionar una nave');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;

      if (widget.contenedor != null) {
        // ✅ MODO EDICIÓN - Usar updateContenedorWithFiles
        success = await ref
            .read(contenedorProvider.notifier)
            .updateContenedorWithFiles(
              id: widget.contenedor!.id,
              nContenedor: _nContenedorController.text.trim(),
              naveDescarga: _selectedNaveId!,
              zonaInspeccion: _selectedZonaId, // null limpiará la zona
              precinto1: _precinto1Controller.text.trim().isNotEmpty
                  ? _precinto1Controller.text.trim()
                  : '', // String vacío limpiará el precinto
              precinto2: _precinto2Controller.text.trim().isNotEmpty
                  ? _precinto2Controller.text.trim()
                  : '', // String vacío limpiará el precinto
              // ✅ Nuevas fotos (si las hay)
              fotoContenedorPath: _fotoContenedorPath,
              fotoPrecinto1Path: _fotoPrecinto1Path,
              fotoPrecinto2Path: _fotoPrecinto2Path,
              fotoContenedorVacioPath: _fotoContenedorVacioPath,

              // ✅ Flags para eliminar fotos existentes
              removeFotoContenedor: _removeFotoContenedor,
              removeFotoPrecinto1: _removeFotoPrecinto1,
              removeFotoPrecinto2: _removeFotoPrecinto2,
              removeFotoContenedorVacio: _removeFotoContenedorVacio,
            );
      } else {
        // ✅ MODO CREACIÓN - Usar createContenedor (sin cambios)
        success = await ref
            .read(contenedorProvider.notifier)
            .createContenedor(
              nContenedor: _nContenedorController.text.trim(),
              naveDescarga: _selectedNaveId!,
              zonaInspeccion: _selectedZonaId,
              fotoContenedorPath: _fotoContenedorPath,
              precinto1: _precinto1Controller.text.trim().isNotEmpty
                  ? _precinto1Controller.text.trim()
                  : null,
              fotoPrecinto1Path: _fotoPrecinto1Path,
              precinto2: _precinto2Controller.text.trim().isNotEmpty
                  ? _precinto2Controller.text.trim()
                  : null,
              fotoPrecinto2Path: _fotoPrecinto2Path,
              fotoContenedorVacioPath: _fotoContenedorVacioPath,
            );
      }

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        _showSuccess(
          isEditMode
              ? 'Contenedor actualizado exitosamente'
              : 'Contenedor creado exitosamente',
        );
      } else {
        _showError(
          isEditMode
              ? 'Error al actualizar el contenedor'
              : 'Error al crear el contenedor',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    }
  }
}
