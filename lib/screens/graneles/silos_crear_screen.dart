// =============================================================================
// PANTALLA DE CREAR/EDITAR SILOS
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';

class SilosCrearScreen extends ConsumerStatefulWidget {
  final int? siloId;
  final bool isEditMode;

  const SilosCrearScreen({super.key})
      : siloId = null,
        isEditMode = false;

  const SilosCrearScreen.edit({super.key, required this.siloId})
      : isEditMode = true;

  @override
  ConsumerState<SilosCrearScreen> createState() => _SilosCrearScreenState();
}

class _SilosCrearScreenState extends ConsumerState<SilosCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroSiloController = TextEditingController();
  final _pesoController = TextEditingController();
  final _bagsController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Servicio y producto seleccionados
  int? _selectedServicioId;
  int? _selectedProductoId;
  List<ServicioGranel> _servicios = [];
  List<ProductoGranel> _productosDelServicio = [];
  bool _isLoadingServicios = true;

  DateTime _fechaHora = DateTime.now();
  String? _fotoPath;
  String? _existingFotoUrl;
  bool _isSubmitting = false;
  bool _isLoadingSilo = false;

  @override
  void initState() {
    super.initState();
    _loadServicios();
    if (widget.isEditMode && widget.siloId != null) {
      _loadSiloData();
    }
  }

  Future<void> _loadServicios() async {
    try {
      final service = ref.read(serviciosGranelesServiceProvider);
      final response = await service.list(queryParameters: {'cierre_servicio': false});
      if (mounted) {
        setState(() {
          _servicios = response.results;
          _isLoadingServicios = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingServicios = false);
        AppSnackBar.error(context, 'Error al cargar servicios: $e');
      }
    }
  }

  void _onServicioChanged(int? servicioId) {
    setState(() {
      _selectedServicioId = servicioId;
      _selectedProductoId = null;
      if (servicioId != null) {
        final servicio = _servicios.firstWhere((s) => s.id == servicioId);
        _productosDelServicio = servicio.productos;
      } else {
        _productosDelServicio = [];
      }
    });
  }

  Future<void> _loadSiloData() async {
    setState(() => _isLoadingSilo = true);
    try {
      final silo = await ref.read(silosServiceProvider).retrieve(widget.siloId!);
      if (mounted) {
        setState(() {
          _numeroSiloController.text = silo.numeroSilo?.toString() ?? '';
          _pesoController.text = silo.peso?.toStringAsFixed(3) ?? '';
          _bagsController.text = silo.bags?.toString() ?? '';
          _fechaHora = silo.fechaHora ?? DateTime.now();
          _existingFotoUrl = silo.fotoUrl;
          _isLoadingSilo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSilo = false);
        AppSnackBar.error(context, 'Error al cargar silo: $e');
      }
    }
  }

  @override
  void dispose() {
    _numeroSiloController.dispose();
    _pesoController.dispose();
    _bagsController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSilo) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Cargando...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.isEditMode ? 'Editar Silo' : 'Nuevo Registro de Silo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        children: [
          // Sección: Servicio (solo en creación)
          if (!widget.isEditMode) ...[
            _buildSectionHeader('Servicio', Icons.directions_boat),
            _buildServicioSelector(),
            SizedBox(height: DesignTokens.spaceL),

            // Sección: Producto
            _buildSectionHeader('Producto', Icons.inventory_2),
            _buildProductoSelector(),
            SizedBox(height: DesignTokens.spaceL),
          ],

          // Sección: Número de Silo/Camión
          _buildSectionHeader('Identificación', Icons.tag),
          _buildNumeroSiloField(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Fecha y hora
          _buildSectionHeader('Fecha y Hora', Icons.schedule),
          _buildFechaHoraField(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Pesos
          _buildSectionHeader('Peso y Cantidad', Icons.scale),
          _buildWeightFields(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Foto
          _buildSectionHeader('Foto', Icons.camera_alt),
          _buildPhotoField(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Observaciones
          _buildSectionHeader('Observaciones', Icons.notes),
          _buildObservacionesField(),
          SizedBox(height: DesignTokens.spaceXL),

          // Botón de guardar
          _buildSubmitButton(),
          SizedBox(height: DesignTokens.spaceL + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          SizedBox(width: DesignTokens.spaceS),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicioSelector() {
    if (_isLoadingServicios) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_servicios.isEmpty) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            SizedBox(width: DesignTokens.spaceS),
            Expanded(
              child: Text(
                'No hay servicios activos disponibles',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedServicioId,
      decoration: InputDecoration(
        labelText: 'Servicio *',
        hintText: 'Seleccionar servicio...',
        prefixIcon: Icon(Icons.directions_boat, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: _servicios.map((servicio) {
        return DropdownMenuItem<int>(
          value: servicio.id,
          child: Text(
            '${servicio.codigo} - ${servicio.naveNombre ?? "Sin nave"}',
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onServicioChanged,
      validator: (value) => value == null ? 'Selecciona un servicio' : null,
    );
  }

  Widget _buildProductoSelector() {
    if (_selectedServicioId == null) {
      return Text(
        'Selecciona un servicio primero',
        style: TextStyle(
          fontSize: DesignTokens.fontSizeS,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (_productosDelServicio.isEmpty) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Text(
          'El servicio no tiene productos configurados',
          style: TextStyle(color: AppColors.warning),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedProductoId,
      decoration: InputDecoration(
        labelText: 'Producto *',
        hintText: 'Seleccionar producto...',
        prefixIcon: Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: _productosDelServicio.map((producto) {
        return DropdownMenuItem<int>(
          value: producto.id,
          child: Text(
            producto.producto,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedProductoId = value),
      validator: (value) => value == null ? 'Selecciona un producto' : null,
    );
  }

  Widget _buildNumeroSiloField() {
    return TextFormField(
      controller: _numeroSiloController,
      decoration: InputDecoration(
        labelText: 'Número de Silo/Camión *',
        hintText: 'Ej: 1, 2, 3...',
        prefixIcon: const Icon(Icons.tag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El número es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildFechaHoraField() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return InkWell(
      onTap: _selectDateTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha y Hora *',
          prefixIcon: const Icon(Icons.access_time, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          dateFormat.format(_fechaHora),
          style: TextStyle(fontSize: DesignTokens.fontSizeS),
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaHora),
        initialEntryMode: TimePickerEntryMode.input,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _fechaHora = DateTime(
            date.year, date.month, date.day, time.hour, time.minute,
          );
        });
      }
    }
  }

  Widget _buildWeightFields() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _pesoController,
            decoration: InputDecoration(
              labelText: 'Peso (TM) *',
              hintText: '0.000',
              suffixText: 'TM',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Requerido';
              final num = double.tryParse(value);
              if (num == null || num <= 0) return 'Inválido';
              return null;
            },
          ),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          child: TextFormField(
            controller: _bagsController,
            decoration: InputDecoration(
              labelText: 'Bags',
              hintText: 'Opcional',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoField() {
    return ReusableCameraCard(
      title: 'Foto del Silo',
      currentImagePath: _fotoPath,
      currentImageUrl: _existingFotoUrl,
      onImageSelected: (path) {
        setState(() => _fotoPath = path);
      },
    );
  }

  Widget _buildObservacionesField() {
    return TextFormField(
      controller: _observacionesController,
      decoration: InputDecoration(
        labelText: 'Observaciones',
        hintText: 'Notas adicionales...',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildSubmitButton() {
    return AppButton.primary(
      text: _isSubmitting
          ? 'Guardando...'
          : (widget.isEditMode ? 'Actualizar Silo' : 'Crear Registro'),
      icon: _isSubmitting ? null : Icons.save,
      onPressed: _isSubmitting ? null : _submitForm,
      isLoading: _isSubmitting,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(silosServiceProvider);

      final data = <String, dynamic>{
        'n_camion': int.parse(_numeroSiloController.text),
        'cantidad': double.parse(_pesoController.text),
        'fecha_pesaje': _fechaHora.toIso8601String(),
      };

      if (!widget.isEditMode) {
        data['servicio'] = _selectedServicioId;
        data['producto'] = _selectedProductoId;
      }

      if (_bagsController.text.isNotEmpty) {
        data['bags'] = int.parse(_bagsController.text);
      }

      if (_observacionesController.text.trim().isNotEmpty) {
        data['observaciones'] = _observacionesController.text.trim();
      }

      if (widget.isEditMode) {
        if (_fotoPath != null) {
          await service.updateWithFiles(
            widget.siloId!,
            data,
            {'foto': _fotoPath!},
          );
        } else {
          await service.partialUpdate(widget.siloId!, data);
        }
      } else {
        if (_fotoPath != null) {
          await service.createWithFiles(data, {'foto': _fotoPath!});
        } else {
          await service.create(data);
        }
      }

      // Refrescar lista de silos
      ref.invalidate(silosListProvider);

      if (mounted) {
        AppSnackBar.success(
          context,
          widget.isEditMode
              ? 'Silo actualizado correctamente'
              : 'Silo creado correctamente',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackBar.error(context, 'Error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }
}
