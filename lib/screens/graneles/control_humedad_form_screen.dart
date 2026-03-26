// =============================================================================
// PANTALLA DE CREAR/EDITAR CONTROL HUMEDAD/TEMPERATURA
// =============================================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class ControlHumedadFormScreen extends ConsumerStatefulWidget {
  final int? controlId;
  final bool isEditMode;

  const ControlHumedadFormScreen({super.key})
      : controlId = null,
        isEditMode = false;

  const ControlHumedadFormScreen.edit({super.key, required this.controlId})
      : isEditMode = true;

  @override
  ConsumerState<ControlHumedadFormScreen> createState() => _ControlHumedadFormScreenState();
}

class _ControlHumedadFormScreenState extends ConsumerState<ControlHumedadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _temperaturaController = TextEditingController();
  final _humedadController = TextEditingController();
  final _observacionesController = TextEditingController();

  int? _selectedServicioId;
  int? _selectedDistribucionId;
  int? _selectedJornadaId;
  DateTime _horaMuestra = nowLima();
  String? _fotoTemperaturaPath;
  String? _fotoHumedadPath;
  String? _fotoExtraPath;
  String? _existingFotoTemperaturaUrl;
  String? _existingFotoHumedadUrl;
  String? _existingFotoExtraUrl;
  bool _isSubmitting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.controlId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final c = await ref.read(controlHumedadServiceProvider).retrieve(widget.controlId!);
      if (mounted) {
        setState(() {
          _selectedServicioId = c.servicioId;
          _selectedDistribucionId = c.distribucionId;
          _selectedJornadaId = c.jornadaId;
          _horaMuestra = c.horaMuestra != null ? toLima(c.horaMuestra!) : nowLima();
          _temperaturaController.text = c.temperatura?.toStringAsFixed(1) ?? '';
          _humedadController.text = c.humedad?.toStringAsFixed(1) ?? '';
          _observacionesController.text = c.observaciones ?? '';
          _existingFotoTemperaturaUrl = c.fotoTemperaturaUrl;
          _existingFotoHumedadUrl = c.fotoHumedadUrl;
          _existingFotoExtraUrl = c.fotoExtraUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.error(context, 'Error al cargar: $e');
      }
    }
  }

  @override
  void dispose() {
    _temperaturaController.dispose();
    _humedadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    final optionsAsync = ref.watch(controlHumedadOptionsProvider(_selectedServicioId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.isEditMode ? 'Editar Control' : 'Nuevo Control Temp/Humedad',
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
          onRetry: () => ref.invalidate(controlHumedadOptionsProvider(_selectedServicioId)),
        ),
        data: (options) => _buildForm(options),
      ),
    );
  }

  Widget _buildForm(ControlHumedadOptions options) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        children: [
          // Servicio
          if (options.servicios.isNotEmpty) ...[
            AppSectionHeader(icon: Icons.directions_boat, title: 'Servicio'),
            SizedBox(height: DesignTokens.spaceS),
            _buildServicioSelector(options.servicios),
            SizedBox(height: DesignTokens.spaceL),
          ],

          // Distribucion
          AppSectionHeader(icon: Icons.category, title: 'Distribucion'),
          SizedBox(height: DesignTokens.spaceS),
          _buildDropdown(
            value: _selectedDistribucionId,
            items: options.distribuciones,
            label: 'Distribucion *',
            hint: 'Seleccionar distribucion...',
            icon: Icons.category,
            onChanged: (v) => setState(() => _selectedDistribucionId = v),
            validator: (v) => v == null ? 'Selecciona una distribucion' : null,
          ),
          SizedBox(height: DesignTokens.spaceL),

          // Jornada
          AppSectionHeader(icon: Icons.schedule, title: 'Jornada'),
          SizedBox(height: DesignTokens.spaceS),
          _buildDropdown(
            value: _selectedJornadaId,
            items: options.jornadas,
            label: 'Jornada *',
            hint: 'Seleccionar jornada...',
            icon: Icons.schedule,
            onChanged: (v) => setState(() => _selectedJornadaId = v),
            validator: (v) => v == null ? 'Selecciona una jornada' : null,
          ),
          SizedBox(height: DesignTokens.spaceL),

          // Hora muestra
          AppSectionHeader(icon: Icons.access_time, title: 'Hora de Muestra'),
          SizedBox(height: DesignTokens.spaceS),
          _buildDateTimeField(),
          SizedBox(height: DesignTokens.spaceL),

          // Temperatura y Humedad
          AppSectionHeader(icon: Icons.thermostat, title: 'Temperatura y Humedad'),
          SizedBox(height: DesignTokens.spaceS),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _temperaturaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Temperatura (C) *',
                    prefixIcon: Icon(Icons.thermostat, color: AppColors.error, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: TextFormField(
                  controller: _humedadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Humedad (%) *',
                    prefixIcon: Icon(Icons.water_drop, color: AppColors.info, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceL),

          // Fotos
          AppSectionHeader(icon: Icons.camera_alt, title: 'Fotos'),
          SizedBox(height: DesignTokens.spaceS),
          _buildPhotoSection(),
          SizedBox(height: DesignTokens.spaceL),

          // Observaciones
          AppSectionHeader(icon: Icons.notes, title: 'Observaciones'),
          SizedBox(height: DesignTokens.spaceS),
          TextFormField(
            controller: _observacionesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Observaciones adicionales...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),

          // Submit
          _buildSubmitButton(),
          SizedBox(height: DesignTokens.spaceL + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildServicioSelector(List<OptionItem> servicios) {
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
      items: servicios.map((s) {
        return DropdownMenuItem<int>(
          value: s.id,
          child: Text(
            s.label,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) {
        setState(() {
          _selectedServicioId = v;
          // Reset dependent selectors
          _selectedDistribucionId = null;
          _selectedJornadaId = null;
        });
        // Re-fetch options for new servicio
        ref.invalidate(controlHumedadOptionsProvider(v));
      },
      validator: (v) => v == null ? 'Selecciona un servicio' : null,
    );
  }

  Widget _buildDropdown({
    required int? value,
    required List<OptionItem> items,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<int?> onChanged,
    String? Function(int?)? validator,
  }) {
    if (items.isEmpty) {
      return _buildWarningBox('No hay opciones disponibles');
    }

    return DropdownButtonFormField<int>(
      value: value != null && items.any((i) => i.id == value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item.id,
          child: Text(
            item.label,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDateTimeField() {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _horaMuestra,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date == null) return;

        if (!mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_horaMuestra),
        );
        if (time == null) return;

        setState(() {
          _horaMuestra = makeLima(date.year, date.month, date.day, time.hour, time.minute);
        });
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hora de muestra *',
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          dateTimeFormat.format(_horaMuestra),
          style: TextStyle(fontSize: DesignTokens.fontSizeS),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        // Foto temperatura
        ReusableCameraCard(
          title: 'Foto Temperatura',
          currentImagePath: _fotoTemperaturaPath,
          currentImageUrl: _existingFotoTemperaturaUrl,
          onImageSelected: (path) => setState(() => _fotoTemperaturaPath = path),
        ),
        SizedBox(height: DesignTokens.spaceS),

        // Foto humedad
        ReusableCameraCard(
          title: 'Foto Humedad',
          currentImagePath: _fotoHumedadPath,
          currentImageUrl: _existingFotoHumedadUrl,
          onImageSelected: (path) => setState(() => _fotoHumedadPath = path),
        ),
        SizedBox(height: DesignTokens.spaceS),

        // Foto extra
        ReusableCameraCard(
          title: 'Foto Extra (opcional)',
          currentImagePath: _fotoExtraPath,
          currentImageUrl: _existingFotoExtraUrl,
          onImageSelected: (path) => setState(() => _fotoExtraPath = path),
        ),
      ],
    );
  }

  Widget _buildWarningBox(String text) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
          SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(widget.isEditMode ? Icons.save : Icons.add),
        label: Text(
          _isSubmitting
              ? 'Guardando...'
              : widget.isEditMode
                  ? 'Guardar Cambios'
                  : 'Crear Registro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeM,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(controlHumedadServiceProvider);
      final temperatura = double.tryParse(_temperaturaController.text) ?? 0;
      final humedad = double.tryParse(_humedadController.text) ?? 0;

      if (widget.isEditMode) {
        await service.updateControlHumedad(
          controlId: widget.controlId!,
          servicioId: _selectedServicioId,
          distribucionId: _selectedDistribucionId,
          jornadaId: _selectedJornadaId,
          horaMuestra: makeLima(
            _horaMuestra.year, _horaMuestra.month, _horaMuestra.day,
            _horaMuestra.hour, _horaMuestra.minute,
          ),
          temperatura: temperatura,
          humedad: humedad,
          observaciones: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
          fotoTemperatura: _fotoTemperaturaPath != null ? File(_fotoTemperaturaPath!) : null,
          fotoHumedad: _fotoHumedadPath != null ? File(_fotoHumedadPath!) : null,
          fotoExtra: _fotoExtraPath != null ? File(_fotoExtraPath!) : null,
        );
      } else {
        if (_selectedServicioId == null) {
          AppSnackBar.error(context, 'Selecciona un servicio');
          setState(() => _isSubmitting = false);
          return;
        }
        if (_selectedDistribucionId == null) {
          AppSnackBar.error(context, 'Selecciona una distribucion');
          setState(() => _isSubmitting = false);
          return;
        }
        if (_selectedJornadaId == null) {
          AppSnackBar.error(context, 'Selecciona una jornada');
          setState(() => _isSubmitting = false);
          return;
        }

        await service.createControlHumedad(
          servicioId: _selectedServicioId!,
          distribucionId: _selectedDistribucionId!,
          jornadaId: _selectedJornadaId!,
          horaMuestra: makeLima(
            _horaMuestra.year, _horaMuestra.month, _horaMuestra.day,
            _horaMuestra.hour, _horaMuestra.minute,
          ),
          temperatura: temperatura,
          humedad: humedad,
          observaciones: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
          fotoTemperatura: _fotoTemperaturaPath != null ? File(_fotoTemperaturaPath!) : null,
          fotoHumedad: _fotoHumedadPath != null ? File(_fotoHumedadPath!) : null,
          fotoExtra: _fotoExtraPath != null ? File(_fotoExtraPath!) : null,
        );
      }

      // Refresh list
      ref.read(controlHumedadListProvider.notifier).refresh();

      if (mounted) {
        AppSnackBar.success(
          context,
          widget.isEditMode ? 'Registro actualizado' : 'Registro creado',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
