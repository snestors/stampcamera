// lib/widgets/autos/registro_vin_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/registro_vin_options.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';

class RegistroVinForm extends ConsumerStatefulWidget {
  final String vin;

  const RegistroVinForm({super.key, required this.vin});

  @override
  ConsumerState<RegistroVinForm> createState() => _RegistroVinFormState();
}

class _RegistroVinFormState extends ConsumerState<RegistroVinForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCondicion;
  int? _selectedZonaInspeccion;
  int? _selectedBloque;
  int? _selectedFila;
  int? _selectedPosicion;
  int? _selectedContenedor;
  String? _fotoVinPath;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ✅ Obtener opciones del provider existente
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
          data: (options) => _buildForm(options),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildForm(RegistroVinOptions options) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 16),

          // Campos del formulario con opciones dinámicas
          _buildFormFields(options),

          const SizedBox(height: 16),

          // Foto VIN
          _buildFotoSection(),

          const SizedBox(height: 24),

          // Botones
          _buildActionButtons(),
        ],
      ),
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
        const Expanded(
          child: Text(
            'Nueva Inspección',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

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
              ? (value) => setState(() => _selectedCondicion = value)
              : null,
          validator: _isFieldRequired(options, 'condicion')
              ? (value) => value == null ? 'Seleccione una condición' : null
              : null,
        ),

        const SizedBox(height: 16),

        // ✅ Zona de Inspección con opciones dinámicas
        DropdownButtonFormField<int>(
          value: _selectedZonaInspeccion,
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

        const SizedBox(height: 16),

        // ✅ Bloque con opciones dinámicas
        if (options.bloques.isNotEmpty) ...[
          DropdownButtonFormField<int>(
            value: _selectedBloque,
            decoration: InputDecoration(
              labelText:
                  'Bloque${_isFieldRequired(options, 'bloque') ? ' *' : ''}',
              border: const OutlineInputBorder(),
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

        // ✅ Campos opcionales en fila
        Row(
          children: [
            // Fila
            if (_isFieldEditable(options, 'fila')) ...[
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText:
                        'Fila${_isFieldRequired(options, 'fila') ? ' *' : ''}',
                    border: const OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText:
                        'Posición${_isFieldRequired(options, 'posicion') ? ' *' : ''}',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _selectedPosicion = int.tryParse(value),
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

        // ✅ Contenedor si hay opciones disponibles
        if (options.contenedoresDisponibles.isNotEmpty) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedContenedor,
            decoration: InputDecoration(
              labelText:
                  'Contenedor${_isFieldRequired(options, 'contenedor') ? ' *' : ''}',
              border: const OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('-- Sin contenedor --'),
              ),
              ...options.contenedoresDisponibles.map((contenedor) {
                return DropdownMenuItem(
                  value: contenedor.id,
                  child: Text(contenedor.nContenedor),
                );
              }),
            ],
            onChanged: _isFieldEditable(options, 'contenedor')
                ? (value) => setState(() => _selectedContenedor = value)
                : null,
            validator: _isFieldRequired(options, 'contenedor')
                ? (value) => value == null ? 'Seleccione un contenedor' : null
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildFotoSection() {
    return ReusableCameraCard(
      title: 'Foto VIN *',
      subtitle: 'Fotografía clara del número VIN del vehículo',
      currentImagePath: _fotoVinPath,
      onImageSelected: (path) => setState(() => _fotoVinPath = path),
      showGalleryOption: true,
      primaryColor: const Color(0xFF00B4D8),
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
              backgroundColor: const Color(0xFF00B4D8),
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
                : const Text('Guardar'),
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
  // SUBMIT FORM
  // ============================================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoVinPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La foto VIN es obligatoria')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(detalleRegistroProvider(widget.vin).notifier);

      final success = await notifier.createRegistroVin(
        condicion: _selectedCondicion!,
        zonaInspeccion: _selectedZonaInspeccion!,
        fotoVin: File(_fotoVinPath!),
        bloque: _selectedBloque,
        fila: _selectedFila,
        posicion: _selectedPosicion,
        contenedorId: _selectedContenedor,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Registro creado exitosamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al crear registro')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
