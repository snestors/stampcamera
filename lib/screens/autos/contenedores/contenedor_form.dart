// screens/autos/contenedores/contenedor_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/providers/autos/contenedor_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';
import 'package:stampcamera/theme/custom_colors.dart';

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

  // Paths de imágenes
  String? _fotoContenedorPath;
  String? _fotoPrecinto1Path;
  String? _fotoPrecinto2Path;
  String? _fotoContenedorVacioPath;

  bool _isLoading = false;

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
      // ✅ CAMBIO: Usar el ID de la nave del objeto
      _selectedNaveId = contenedor.naveDescarga.id;
      _selectedZonaId = contenedor.zonaInspeccion?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(contenedorOptionsProvider);
    final isEdit = widget.contenedor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Contenedor' : 'Nuevo Contenedor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            Container(
              margin: const EdgeInsets.all(AppDimensions.paddingM),
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: optionsAsync.when(
        data: (options) => _buildForm(context, options, isEdit),
        loading: () => _buildLoadingState(context),
        error: (error, _) => _buildErrorState(context, error),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ContenedorOptions options,
    bool isEdit,
  ) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  const SizedBox(height: AppDimensions.paddingL),

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
                    validator: (value) =>
                        value == null ? 'Seleccione una nave' : null,
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Zona de inspección
                  _buildDropdown<int>(
                    context: context,
                    label: 'Zona de Inspección',
                    value: _selectedZonaId,
                    items: options.zonasDisponibles
                        .map(
                          (zona) => DropdownMenuItem(
                            value: zona.id,
                            child: Text(zona.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: _canEditField('zona_inspeccion', options)
                        ? (value) {
                            if (mounted) {
                              setState(() => _selectedZonaId = value);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

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
                  const SizedBox(height: AppDimensions.paddingL),

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

                  const SizedBox(height: AppDimensions.paddingL),

                  // Foto del contenedor
                  ReusableCameraCard(
                    title: 'Foto del Contenedor',
                    subtitle: 'Capture una imagen clara del contenedor',
                    currentImagePath: _fotoContenedorPath,
                    onImageSelected: (path) {
                      if (mounted) {
                        setState(() => _fotoContenedorPath = path);
                      }
                    },
                    primaryColor: AppColors.secondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

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
                  const SizedBox(height: AppDimensions.paddingL),

                  // Precinto 1
                  _buildTextField(
                    context: context,
                    controller: _precinto1Controller,
                    label: 'Precinto 1',
                    hint: 'Ej: CV877664',
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Foto Precinto 1
                  ReusableCameraCard(
                    title: 'Foto Precinto 1',
                    subtitle: 'Capture el primer precinto si existe',
                    currentImagePath: _fotoPrecinto1Path,
                    onImageSelected: (path) {
                      if (mounted) {
                        setState(() => _fotoPrecinto1Path = path);
                      }
                    },
                    primaryColor: AppColors.warning,
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Precinto 2
                  _buildTextField(
                    context: context,
                    controller: _precinto2Controller,
                    label: 'Precinto 2',
                    hint: 'Ej: CV877665',
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Foto Precinto 2
                  ReusableCameraCard(
                    title: 'Foto Precinto 2',
                    subtitle: 'Capture el segundo precinto si existe',
                    currentImagePath: _fotoPrecinto2Path,
                    onImageSelected: (path) {
                      if (mounted) {
                        setState(() => _fotoPrecinto2Path = path);
                      }
                    },
                    primaryColor: AppColors.warning,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

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
                  const SizedBox(height: AppDimensions.paddingL),

                  // Foto Contenedor Vacío
                  ReusableCameraCard(
                    title: 'Foto Contenedor Vacío',
                    subtitle: 'Capture el contenedor una vez esté vacío',
                    currentImagePath: _fotoContenedorVacioPath,
                    onImageSelected: (path) {
                      if (mounted) {
                        setState(() => _fotoContenedorVacioPath = path);
                      }
                    },
                    primaryColor: AppColors.info,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingXXL),
          ],
        ),
      ),
    );
  }

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
        const SizedBox(height: AppDimensions.paddingS),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : AppColors.textLight.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
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
        const SizedBox(height: AppDimensions.paddingS),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : AppColors.textLight.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppDimensions.paddingL),
          Text('Cargando opciones...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
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

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
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
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingL,
                  ),
                  side: const BorderSide(color: AppColors.textSecondary),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingL),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submitForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingL,
                  ),
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
                    : Text(
                        widget.contenedor != null
                            ? 'Actualizar'
                            : 'Crear Contenedor',
                      ),
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

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNaveId == null) {
      _showError(context, 'Debe seleccionar una nave');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;

      if (widget.contenedor != null) {
        // ✅ MODO EDICIÓN: Usar updateContenedor
        success = await ref
            .read(contenedorProvider.notifier)
            .updateContenedor(
              id: widget.contenedor!.id,
              nContenedor: _nContenedorController.text.trim(),
              naveDescarga: _selectedNaveId!,
              zonaInspeccion: _selectedZonaId,
              precinto1: _precinto1Controller.text.trim().isNotEmpty
                  ? _precinto1Controller.text.trim()
                  : null,
              precinto2: _precinto2Controller.text.trim().isNotEmpty
                  ? _precinto2Controller.text.trim()
                  : null,
            );
      } else {
        // ✅ MODO CREACIÓN: Usar createContenedor
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
        Navigator.of(context).pop();
        _showSuccess(
          context,
          widget.contenedor != null
              ? 'Contenedor actualizado exitosamente'
              : 'Contenedor creado exitosamente',
        );
      } else {
        _showError(
          context,
          widget.contenedor != null
              ? 'Error al actualizar el contenedor'
              : 'Error al crear el contenedor',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError(context, 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccess(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    }
  }
}
