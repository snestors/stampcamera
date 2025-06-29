// lib/widgets/autos/foto_presentacion_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';

class FotoPresentacionForm extends ConsumerStatefulWidget {
  final String vin;

  const FotoPresentacionForm({super.key, required this.vin});

  @override
  ConsumerState<FotoPresentacionForm> createState() =>
      _FotoPresentacionFormState();
}

class _FotoPresentacionFormState extends ConsumerState<FotoPresentacionForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTipo;
  String? _nDocumento;
  String? _fotoPath;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ✅ Obtener opciones del provider existente
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
        child: optionsAsync.when(
          data: (options) => _buildForm(options),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildForm(Map<String, dynamic> options) {
    final tiposDisponibles =
        options['tipos_disponibles'] as List<dynamic>? ?? [];

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 16),

          // Campos del formulario
          _buildFormFields(tiposDisponibles),

          const SizedBox(height: 16),

          // Foto
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
        Text('Cargando tipos de foto...'),
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
        const Text('Error al cargar tipos de foto'),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Nueva Foto de Presentación',
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

  Widget _buildFormFields(List<dynamic> tiposDisponibles) {
    return Column(
      children: [
        // ✅ Tipo con opciones dinámicas
        DropdownButtonFormField<String>(
          value: _selectedTipo,
          decoration: const InputDecoration(
            labelText: 'Tipo de Foto *',
            border: OutlineInputBorder(),
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

        // N° Documento (opcional)
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'N° Documento',
            border: OutlineInputBorder(),
            hintText: 'Ej: DOC-001, TARJA-123',
          ),
          onChanged: (value) =>
              _nDocumento = value.trim().isEmpty ? null : value.trim(),
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
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPERS PARA COLORES E ÍCONOS POR TIPO
  // ============================================================================

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

    if (_fotoPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('La foto es obligatoria')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(detalleRegistroProvider(widget.vin).notifier);

      final success = await notifier.addFoto(
        tipo: _selectedTipo!,
        imagen: File(_fotoPath!),
        nDocumento: _nDocumento,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Foto agregada exitosamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al agregar foto')),
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
