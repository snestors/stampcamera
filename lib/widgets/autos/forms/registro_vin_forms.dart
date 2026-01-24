// lib/widgets/autos/forms/registro_vin_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/registro_vin_options.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';
import 'package:stampcamera/core/core.dart';

class RegistroVinForm extends ConsumerStatefulWidget {
  final String vin;
  final RegistroVin? registroVin; // ✅ NULL = Crear, NOT NULL = Editar

  const RegistroVinForm({
    super.key,
    required this.vin,
    this.registroVin, // ✅ Opcional para modo edición
  });

  @override
  ConsumerState<RegistroVinForm> createState() => _RegistroVinFormState();
}

class _RegistroVinFormState extends ConsumerState<RegistroVinForm> {
  final _formKey = GlobalKey<FormState>();

  // ✅ Variables del formulario
  String? _selectedCondicion;
  int? _selectedZonaInspeccion;
  int? _selectedBloque;
  int? _selectedFila;
  int? _selectedPosicion;
  int? _selectedContenedor;
  String? _fotoVinPath;
  bool _isLoading = false;

  // ✅ Helpers para determinar modo
  bool get isEditMode => widget.registroVin != null;
  String get formTitle => isEditMode ? 'Editar Inspección' : 'Nueva Inspección';
  String get submitButtonText => isEditMode ? 'Actualizar' : 'Guardar';
  Color get primaryColor => isEditMode ? Colors.orange : AppColors.primary;

  /// Verifica si el usuario puede ver contenedores (nave SIC o superuser/coordinador)
  bool get _showContenedores {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;
    if (user == null) return false;
    final isSuperuser = user.isSuperuser;
    final isCoordinador = user.groups.contains('COORDINACION AUTOS');
    final asistencia = user.ultimaAsistenciaActiva;
    final naveRubro = asistencia?.naveRubro;
    final naveCategoriaRubro = asistencia?.naveCategoriaRubro;
    return isSuperuser || isCoordinador || (naveCategoriaRubro == 'AUTOS' && naveRubro == 'SIC');
  }

  // ✅ Control de initial_values
  bool _hasAppliedInitialValues = false;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _initializeFormData();
    }
  }

  /// Inicializar form con datos existentes (solo en modo edición)
  void _initializeFormData() {
    if (isEditMode) {
      // ✅ MODO EDITAR: Usar datos del registro existente
      final registro = widget.registroVin!;
      _selectedCondicion = registro.condicion;
      _selectedZonaInspeccion = registro.zonaInspeccion?.id;
      _selectedBloque = registro.bloque?.id;
      _selectedFila = registro.fila;
      _selectedPosicion = registro.posicion;

      // ✅ Inicializar contenedor si existe
      if (registro.contenedor != null) {
        _selectedContenedor = registro.contenedor!.id;
      }
    }
    // Nota: Para modo crear, los initial_values se manejan en initState después de cargar options
  }

  /// Aplicar valores iniciales del backend
  void _applyInitialValues(RegistroVinOptions options) {
    if (_hasAppliedInitialValues) return;

    // Aplicar valores iniciales del backend
    final initialValues = options.initialValues;

    if (initialValues['condicion'] != null) {
      _selectedCondicion = initialValues['condicion'].toString();
    }

    if (initialValues['zona_inspeccion'] != null) {
      _selectedZonaInspeccion = initialValues['zona_inspeccion'];
    }

    // Otros initial_values si existen
    if (initialValues['bloque'] != null) {
      _selectedBloque = initialValues['bloque'];
    }

    if (initialValues['fila'] != null) {
      _selectedFila = initialValues['fila'];
    }

    if (initialValues['posicion'] != null) {
      _selectedPosicion = initialValues['posicion'];
    }

    if (initialValues['contenedor'] != null) {
      _selectedContenedor = initialValues['contenedor'];
    }

    _hasAppliedInitialValues = true;

    // Forzar rebuild para mostrar los valores aplicados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(registroVinOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(formTitle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: optionsAsync.when(
          data: (options) {
            final detalleAsync = ref.watch(detalleRegistroProvider(widget.vin));
            final detalle = detalleAsync.valueOrNull;

            if (!isEditMode && !_hasAppliedInitialValues) {
              _applyInitialValues(options);
            }
            return _buildForm(options, detalle);
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildForm(RegistroVinOptions options, DetalleRegistroModel? detalle) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 20,
              ), // Espacio para los botones
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campos del formulario con opciones dinámicas
                    _buildFormFields(options, detalle),

                    const SizedBox(height: 16),

                    // Foto VIN
                    _buildFotoSection(),

                    const SizedBox(
                      height: 20,
                    ), // Espacio extra antes de los botones
                  ],
                ),
              ),
            ),
          ),
        ),

        // ✅ Botones fijos en la parte inferior
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: _buildActionButtons(),
        ),
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

  Widget _buildErrorState(Object error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 50),
        const Icon(Icons.error, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        const Text('Error al cargar opciones'),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(registroVinOptionsProvider),
          child: const Text('Reintentar'),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildFormFields(
    RegistroVinOptions options,
    DetalleRegistroModel? detalle,
  ) {
    return Column(
      children: [
        // ✅ Condición usando CondicionOption
        DropdownButtonFormField<String>(
          initialValue: _selectedCondicion,
          decoration: InputDecoration(
            labelText:
                'Condición${_isFieldRequired(options, 'condicion') ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          items: options.condiciones.map((condicion) {
            return DropdownMenuItem(
              value: condicion.value,
              child: Text(condicion.label),
            );
          }).toList(),
          onChanged: _isFieldEditable(options, 'condicion')
              ? (value) {
                  setState(() {
                    _selectedCondicion = value;
                    // ✅ Limpiar campos que pueden no ser relevantes para la nueva condición
                    if (value?.toUpperCase() != 'PUERTO') {
                      _selectedBloque = null;
                      _selectedFila = null;
                      _selectedPosicion = null;
                    }
                  });
                }
              : null,
          validator: _isFieldRequired(options, 'condicion')
              ? (value) => value == null ? 'Seleccione una condición' : null
              : null,
        ),

        const SizedBox(height: 16),

        // ✅ Zona de Inspección usando ZonaInspeccionOption
        DropdownButtonFormField<int>(
          initialValue: _selectedZonaInspeccion,
          isExpanded: true,
          decoration: InputDecoration(
            labelText:
                'Zona de Inspección${_isFieldRequired(options, 'zona_inspeccion') ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          items: options.zonasInspeccion.map((zona) {
            return DropdownMenuItem(value: zona.value, child: Text(zona.label));
          }).toList(),
          onChanged: _isFieldEditable(options, 'zona_inspeccion')
              ? (value) => setState(() => _selectedZonaInspeccion = value)
              : null,
          validator: _isFieldRequired(options, 'zona_inspeccion')
              ? (value) => value == null ? 'Seleccione una zona' : null
              : null,
        ),

        // ✅ CAMPOS ESPECÍFICOS PARA PUERTO
        if (_selectedCondicion?.toUpperCase() == 'PUERTO') ...[
          const SizedBox(height: 16),

          // Banner informativo para PUERTO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.anchor, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Campos específicos para zona portuaria',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ✅ Bloque usando BloqueOption
          if (options.bloques.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              initialValue: _selectedBloque,
              decoration: InputDecoration(
                labelText:
                    'Bloque${_isFieldRequired(options, 'bloque') ? ' *' : ''}',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(
                  Icons.view_module,
                  color: AppColors.secondary,
                ),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('-- Seleccionar --'),
                ),
                ...options.bloques.map((bloque) {
                  return DropdownMenuItem(
                    value: bloque.value,
                    child: Text(bloque.label),
                  );
                }),
              ],
              onChanged: _isFieldEditable(options, 'bloque')
                  ? (value) => setState(() => _selectedBloque = value)
                  : null,
              validator: _isFieldRequired(options, 'bloque')
                  ? (value) => value == null ? 'Seleccione un bloque' : null
                  : null,
            ),
            const SizedBox(height: 16),
          ],

          // Fila y Posición en fila (solo para PUERTO)
          Row(
            children: [
              // Fila
              if (_isFieldEditable(options, 'fila')) ...[
                Expanded(
                  child: TextFormField(
                    initialValue: isEditMode ? _selectedFila?.toString() : null,
                    decoration: InputDecoration(
                      labelText:
                          'Fila${_isFieldRequired(options, 'fila') ? ' *' : ''}',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(
                        Icons.table_rows,
                        color: AppColors.secondary,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _selectedFila = int.tryParse(value),
                    validator: _isFieldRequired(options, 'fila')
                        ? (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Campo obligatorio';
                            }
                            if (int.tryParse(value!) == null) {
                              return 'Debe ser un número';
                            }
                            return null;
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Posición
              if (_isFieldEditable(options, 'posicion')) ...[
                Expanded(
                  child: TextFormField(
                    initialValue: isEditMode
                        ? _selectedPosicion?.toString()
                        : null,
                    decoration: InputDecoration(
                      labelText:
                          'Posición${_isFieldRequired(options, 'posicion') ? ' *' : ''}',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(
                        Icons.place,
                        color: AppColors.secondary,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _selectedPosicion = int.tryParse(value),
                    validator: _isFieldRequired(options, 'posicion')
                        ? (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Campo obligatorio';
                            }
                            if (int.tryParse(value!) == null) {
                              return 'Debe ser un número';
                            }
                            return null;
                          }
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],

        // ✅ CAMPOS ESPECÍFICOS PARA NAVE SIC + condición PUERTO/ALMACEN
        if (_showContenedores &&
            (_selectedCondicion?.toUpperCase() == 'PUERTO' ||
             _selectedCondicion?.toUpperCase() == 'ALMACEN')) ...[
          const SizedBox(height: 16),

          // Contenedor - AppSearchDropdown
          AppSearchDropdown<int>(
            label: 'Contenedor',
            hint: 'Buscar contenedor...',
            value: _selectedContenedor,
            isRequired: false,
            prefixIcon: const Icon(Icons.inventory_2, color: Color(0xFF6366F1)),
            options: options.contenedoresDisponibles
                .map((c) => AppSearchDropdownOption<int>(
                      value: c.id,
                      label: c.nContenedor,
                      subtitle: c.naveDescarga,
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedContenedor = value);
            },
          ),
        ],

        // ✅ Mensaje informativo si no hay campos específicos
        if (_selectedCondicion != null &&
            _selectedCondicion!.toUpperCase() != 'PUERTO' &&
            _selectedCondicion!.toUpperCase() != 'ALMACEN') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  VehicleHelpers.getCondicionIcon(_selectedCondicion!),
                  color: VehicleHelpers.getCondicionColor(_selectedCondicion!),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta condición no requiere campos adicionales',
                    style: TextStyle(
                      color: VehicleHelpers.getCondicionColor(
                        _selectedCondicion!,
                      ),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }


  /// Determinar si el contenedor es requerido
  bool _isContenedorRequired() {
    return false;
  }

  // ============================================================================
  // RESTO DE MÉTODOS (SIN CAMBIOS)
  // ============================================================================

  Widget _buildFotoSection() {
    return ReusableCameraCard(
      title: isEditMode ? 'Foto VIN' : 'Foto VIN *',
      subtitle: _buildFotoSubtitle(),
      currentImagePath: _fotoVinPath,
      currentImageUrl: isEditMode && _fotoVinPath == null
          ? widget.registroVin!.fotoVinUrl
          : null,
      thumbnailUrl: isEditMode && _fotoVinPath == null
          ? widget.registroVin!.fotoVinThumbnailUrl
          : null,
      onImageSelected: (path) => setState(() => _fotoVinPath = path),
      showGalleryOption: true,
      primaryColor: primaryColor,
    );
  }

  String _buildFotoSubtitle() {
    if (isEditMode) {
      return _fotoVinPath == null
          ? 'Fotografía actual del VIN (opcional cambiar)'
          : 'Nueva fotografía del VIN seleccionada';
    } else {
      return 'Fotografía clara del número VIN del vehículo';
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(submitButtonText),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPERS PARA PERMISOS DE CAMPOS
  // ============================================================================

  bool _isFieldEditable(RegistroVinOptions options, String fieldName) {
    return options.fieldPermissions[fieldName]?.editable ?? true;
  }

  bool _isFieldRequired(RegistroVinOptions options, String fieldName) {
    return options.fieldPermissions[fieldName]?.required ?? false;
  }

  // ============================================================================
  // DIÁLOGO POST-GUARDADO
  // ============================================================================

  Future<String?> _showPostSaveDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Registro guardado', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: const Text('¿Qué deseas hacer ahora?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, null),
            icon: const Icon(Icons.done),
            label: const Text('Solo guardar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'create_foto'),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Crear foto presentación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SUBMIT FORM - UNIVERSAL (CREATE O UPDATE)
  // ============================================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validación de contenedor requerido
    if (_isContenedorRequired() && _selectedContenedor == null) {
      AppSnackBar.warning(context, 'Seleccione un contenedor para la condición ALMACEN');
      return;
    }

    // ✅ En modo crear, la foto es obligatoria
    if (!isEditMode && _fotoVinPath == null) {
      AppSnackBar.warning(context, 'La foto VIN es obligatoria');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(detalleRegistroProvider(widget.vin).notifier);
      bool success;

      if (isEditMode) {
        // ✅ MODO EDICIÓN
        success = await notifier.updateRegistroVin(
          registroVinId: widget.registroVin!.id,
          condicion: _selectedCondicion,
          zonaInspeccion: _selectedZonaInspeccion,
          fotoVin: _fotoVinPath != null ? File(_fotoVinPath!) : null,
          bloque: _selectedBloque,
          fila: _selectedFila,
          posicion: _selectedPosicion,
          contenedorId: _selectedContenedor,
        );
      } else {
        // MODO CREACION: espera respuesta del backend para asegurar
        // que el registro existe antes de encadenar con foto
        success = await notifier.createRegistroVin(
          condicion: _selectedCondicion!,
          zonaInspeccion: _selectedZonaInspeccion!,
          fotoVin: File(_fotoVinPath!),
          bloque: _selectedBloque,
          fila: _selectedFila,
          posicion: _selectedPosicion,
          contenedorId: _selectedContenedor,
        );
      }

      if (mounted) {
        if (success) {
          if (isEditMode) {
            AppSnackBar.success(context, 'Registro actualizado exitosamente');
            Navigator.pop(context);
          } else {
            // Modo crear: preguntar siguiente acción
            final action = await _showPostSaveDialog();
            if (mounted) {
              Navigator.pop(context, action);
            }
          }
        } else {
          AppSnackBar.error(
            context,
            isEditMode
                ? 'Error al actualizar registro'
                : 'Error al crear registro',
          );
        }
      }
    } catch (e) {
      // ✅ ERROR ESPECÍFICO (como duplicado): Mostrar mensaje y CERRAR form
      if (mounted) {
        Navigator.pop(context); // ✅ CERRAR FORM
        AppSnackBar.error(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
