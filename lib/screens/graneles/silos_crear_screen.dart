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
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

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
  final _numeroCamionController = TextEditingController();
  final _pesoController = TextEditingController();
  final _bagsController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Selecciones del formulario
  int? _selectedBlId;
  int? _selectedDistribucionId;
  int? _selectedJornadaId;

  // Datos cargados (distribuciones y jornadas se cargan al seleccionar BL)
  List<OptionItem> _distribuciones = [];
  List<OptionItem> _jornadas = [];

  bool _isLoadingOptions = false;

  DateTime _fechaHora = DateTime.now();
  String? _fotoPath;
  String? _existingFotoUrl;
  bool _isSubmitting = false;
  bool _isLoadingSilo = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.siloId != null) {
      _loadSiloData();
    }
  }

  /// Cuando cambia el BL, cargar distribuciones y jornadas
  Future<void> _onBlChanged(int? blId) async {
    setState(() {
      _selectedBlId = blId;
      _selectedDistribucionId = null;
      _selectedJornadaId = null;
      _distribuciones = [];
      _jornadas = [];
    });

    if (blId != null) {
      await _loadOptionsForBl(blId);
    }
  }

  /// Cargar distribuciones y jornadas para un BL específico
  Future<void> _loadOptionsForBl(int blId) async {
    setState(() => _isLoadingOptions = true);
    try {
      final service = ref.read(silosServiceProvider);
      final options = await service.getFormOptions(blId: blId);
      if (mounted) {
        setState(() {
          _distribuciones = options.distribuciones;
          _jornadas = options.jornadas;
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
        AppSnackBar.error(context, 'Error al cargar opciones: $e');
      }
    }
  }

  Future<void> _loadSiloData() async {
    setState(() => _isLoadingSilo = true);
    try {
      final silo = await ref.read(silosServiceProvider).retrieve(widget.siloId!);
      if (mounted) {
        setState(() {
          _numeroCamionController.text = silo.numeroSilo?.toString() ?? '';
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
    _numeroCamionController.dispose();
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

    // Obtener embarqueId de la asistencia activa para filtrar BLs
    final asistenciaAsync = ref.watch(asistenciaActivaProvider);
    final embarqueId = asistenciaAsync.valueOrNull?.asistencia?.nave?.id;

    // Cargar BLs (solo inicial, sin bl_id)
    final optionsParams = SilosFormOptionsParams(embarqueId: embarqueId);
    final optionsAsync = ref.watch(silosOptionsProvider(optionsParams));

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
      body: optionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => ConnectionErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(silosOptionsProvider(optionsParams)),
        ),
        data: (options) => _buildForm(options),
      ),
    );
  }

  Widget _buildForm(SilosOptions options) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        children: [
          // Solo mostrar selectores en modo creación
          if (!widget.isEditMode) ...[
            // Sección: BL
            _buildSectionHeader('BL', Icons.description),
            _buildBlSelector(options.bls),
            SizedBox(height: DesignTokens.spaceL),

            // Sección: Distribución
            _buildSectionHeader('Distribución / Bodega', Icons.warehouse),
            _buildDistribucionSelector(),
            SizedBox(height: DesignTokens.spaceL),

            // Sección: Jornada
            _buildSectionHeader('Jornada', Icons.schedule),
            _buildJornadaSelector(),
            SizedBox(height: DesignTokens.spaceL),
          ],

          // Sección: N° Camión/Ticket
          _buildSectionHeader('N° Camión / Ticket', Icons.tag),
          _buildNumeroCamionField(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Fecha y hora
          _buildSectionHeader('Fecha y Hora de Pesaje', Icons.access_time),
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

  Widget _buildBlSelector(List<OptionItem> bls) {
    if (bls.isEmpty) {
      return _buildWarningBox('No hay BLs disponibles para tu asistencia actual');
    }

    return DropdownButtonFormField<int>(
      value: _selectedBlId,
      decoration: InputDecoration(
        labelText: 'BL *',
        hintText: 'Seleccionar BL...',
        prefixIcon: Icon(Icons.description, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: bls.map((bl) {
        return DropdownMenuItem<int>(
          value: bl.id,
          child: Text(
            bl.label,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onBlChanged,
      validator: (value) => value == null ? 'Selecciona un BL' : null,
    );
  }

  Widget _buildDistribucionSelector() {
    if (_selectedBlId == null) {
      return _buildDisabledText('Selecciona un BL primero');
    }

    if (_isLoadingOptions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_distribuciones.isEmpty) {
      return _buildWarningBox('No hay distribuciones para este BL');
    }

    return DropdownButtonFormField<int>(
      value: _selectedDistribucionId,
      decoration: InputDecoration(
        labelText: 'Distribución / Bodega *',
        hintText: 'Seleccionar distribución...',
        prefixIcon: Icon(Icons.warehouse, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: _distribuciones.map((dist) {
        return DropdownMenuItem<int>(
          value: dist.id,
          child: Text(
            dist.label,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedDistribucionId = value),
      validator: (value) => value == null ? 'Selecciona una distribución' : null,
    );
  }

  Widget _buildJornadaSelector() {
    if (_selectedBlId == null) {
      return _buildDisabledText('Selecciona un BL primero');
    }

    if (_isLoadingOptions) {
      return const SizedBox.shrink(); // Ya hay loading en distribución
    }

    if (_jornadas.isEmpty) {
      return _buildWarningBox('No hay jornadas disponibles para esta nave');
    }

    return DropdownButtonFormField<int>(
      value: _selectedJornadaId,
      decoration: InputDecoration(
        labelText: 'Jornada *',
        hintText: 'Seleccionar jornada...',
        prefixIcon: Icon(Icons.schedule, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: _jornadas.map((jornada) {
        return DropdownMenuItem<int>(
          value: jornada.id,
          child: Text(
            jornada.label,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedJornadaId = value),
      validator: (value) => value == null ? 'Selecciona una jornada' : null,
    );
  }

  Widget _buildDisabledText(String text) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.neutral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: AppColors.neutral),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeS,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildWarningBox(String text) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
          SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.warning, fontSize: DesignTokens.fontSizeS),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumeroCamionField() {
    return TextFormField(
      controller: _numeroCamionController,
      decoration: InputDecoration(
        labelText: 'N° Camión / Ticket *',
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
        'n_camion': int.parse(_numeroCamionController.text),
        'cantidad': double.parse(_pesoController.text),
        'fecha_pesaje': _fechaHora.toIso8601String(),
      };

      if (!widget.isEditMode) {
        data['distribucion'] = _selectedDistribucionId;
        data['bl'] = _selectedBlId;
        data['jornada'] = _selectedJornadaId;
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
