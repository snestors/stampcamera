// lib/widgets/autos/forms/registro_vin_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/registro_vin_options.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';

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
  Color get primaryColor =>
      isEditMode ? Colors.orange : const Color(0xFF00B4D8);

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
      _selectedContenedor = registro.contenedor?.id;
    }
    // Nota: Para modo crear, los initial_values se manejan en initState después de cargar options
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(registroVinOptionsProvider);

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
        child: optionsAsync.when(
          data: (options) {
            // ✅ Aplicar initial_values solo en modo crear y solo una vez
            if (!isEditMode && !_hasAppliedInitialValues) {
              _applyInitialValues(options);
            }
            return _buildForm(options);
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  // ✅ Agregar esta variable de estado para controlar si ya se aplicaron los valores iniciales:
  bool _hasAppliedInitialValues = false;

  // ✅ Agregar este método para aplicar initial_values:
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

  Widget _buildForm(RegistroVinOptions options) {
    return Column(
      children: [
        // Header fijo
        _buildHeader(),

        const SizedBox(height: 16),

        // ✅ Contenido scrolleable
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
                    _buildFormFields(options),

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

  Widget _buildHeader() {
    return Row(
      children: [
        // ✅ Icono diferente según modo
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEditMode ? Icons.edit : Icons.add,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            formTitle,
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

  // Y actualizar _buildFormFields para incluir el contenedor placeholder:

  Widget _buildFormFields(RegistroVinOptions options) {
    return Column(
      children: [
        // ✅ Condición con opciones dinámicas
        DropdownButtonFormField<String>(
          value: _selectedCondicion,
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
                    if (value?.toUpperCase() != 'ALMACEN') {
                      _selectedContenedor = null;
                    }
                  });
                }
              : null,
          validator: _isFieldRequired(options, 'condicion')
              ? (value) => value == null ? 'Seleccione una condición' : null
              : null,
        ),

        const SizedBox(height: 16),

        // ✅ Zona de Inspección (siempre visible)
        DropdownButtonFormField<int>(
          value: _selectedZonaInspeccion,
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
              color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.anchor, color: Color(0xFF00B4D8), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Campos específicos para zona portuaria',
                    style: TextStyle(
                      color: Color(0xFF00B4D8),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bloque (solo para PUERTO)
          if (options.bloques.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _selectedBloque,
              decoration: InputDecoration(
                labelText:
                    'Bloque${_isFieldRequired(options, 'bloque') ? ' *' : ''}',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(
                  Icons.view_module,
                  color: Color(0xFF00B4D8),
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
                        color: Color(0xFF00B4D8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _selectedFila = int.tryParse(value),
                    validator: _isFieldRequired(options, 'fila')
                        ? (value) {
                            if (value?.isEmpty ?? true)
                              return 'Campo obligatorio';
                            if (int.tryParse(value!) == null)
                              return 'Debe ser un número';
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
                        color: Color(0xFF00B4D8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _selectedPosicion = int.tryParse(value),
                    validator: _isFieldRequired(options, 'posicion')
                        ? (value) {
                            if (value?.isEmpty ?? true)
                              return 'Campo obligatorio';
                            if (int.tryParse(value!) == null)
                              return 'Debe ser un número';
                            return null;
                          }
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],

        // ✅ CAMPOS ESPECÍFICOS PARA ALMACEN (PLACEHOLDER)
        if (_selectedCondicion?.toUpperCase() == 'ALMACEN') ...[
          const SizedBox(height: 16),

          // Banner informativo para ALMACEN
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF059669).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.warehouse, color: Color(0xFF059669), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Campos específicos para zona de almacenamiento',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ✅ CONTENEDOR PLACEHOLDER
          DropdownButtonFormField<int>(
            value: _selectedContenedor,
            decoration: const InputDecoration(
              labelText: 'Contenedor',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory, color: Color(0xFF059669)),
              suffixIcon: Icon(Icons.construction, color: Colors.orange),
            ),
            items: const [
              DropdownMenuItem<int>(
                value: null,
                child: Text('-- En desarrollo --'),
              ),
            ],
            onChanged: null, // ✅ Deshabilitado temporalmente
            validator: null, // ✅ Sin validación por ahora
          ),

          const SizedBox(height: 8),

          // ✅ Mensaje de placeholder
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Funcionalidad de contenedores en desarrollo',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
                  _getCondicionIcon(_selectedCondicion!),
                  color: _getCondicionColor(_selectedCondicion!),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta condición no requiere campos adicionales',
                    style: TextStyle(
                      color: _getCondicionColor(_selectedCondicion!),
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
  // SUBMIT FORM - UNIVERSAL (CREATE O UPDATE)
  // ============================================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ En modo crear, la foto es obligatoria
    if (!isEditMode && _fotoVinPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La foto VIN es obligatoria')),
      );
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
        // ✅ MODO CREACIÓN
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
          // ✅ ÉXITO: Cerrar form y mostrar mensaje de éxito
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? '✅ Registro actualizado exitosamente'
                    : '✅ Registro creado exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // ✅ ERROR GENÉRICO: Mostrar error pero NO cerrar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? '❌ Error al actualizar registro'
                    : '❌ Error al crear registro',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ✅ ERROR ESPECÍFICO (como duplicado): Mostrar mensaje y CERRAR form
      if (mounted) {
        Navigator.pop(context); // ✅ CERRAR FORM
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4), // ✅ Mostrar más tiempo
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ✅ Agregar estos métodos helper al final de la clase:

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
