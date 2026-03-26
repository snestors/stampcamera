// =============================================================================
// PANTALLA DE CREAR/EDITAR PARALIZACION
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class ParalizacionFormScreen extends ConsumerStatefulWidget {
  final int? paralizacionId;
  final bool isEditMode;

  const ParalizacionFormScreen({super.key})
      : paralizacionId = null,
        isEditMode = false;

  const ParalizacionFormScreen.edit({super.key, required this.paralizacionId})
      : isEditMode = true;

  @override
  ConsumerState<ParalizacionFormScreen> createState() => _ParalizacionFormScreenState();
}

class _ParalizacionFormScreenState extends ConsumerState<ParalizacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionController = TextEditingController();

  int? _selectedServicioId;
  int? _selectedMotivoId;
  String? _selectedBodega;
  DateTime _inicio = nowLima();
  DateTime? _fin;
  bool _isSubmitting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.paralizacionId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final p = await ref.read(paralizacionesServiceProvider).retrieve(widget.paralizacionId!);
      if (mounted) {
        setState(() {
          _selectedServicioId = p.servicioId;
          _selectedMotivoId = p.motivoId;
          _selectedBodega = p.bodega;
          _inicio = p.inicio != null ? toLima(p.inicio!) : nowLima();
          _fin = p.fin != null ? toLima(p.fin!) : null;
          _observacionController.text = p.observacion ?? '';
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
    _observacionController.dispose();
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

    final optionsAsync = ref.watch(paralizacionOptionsProvider(_selectedServicioId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.isEditMode ? 'Editar Paralizacion' : 'Nueva Paralizacion',
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
          onRetry: () => ref.invalidate(paralizacionOptionsProvider(_selectedServicioId)),
        ),
        data: (options) => _buildForm(options),
      ),
    );
  }

  Widget _buildForm(ParalizacionOptions options) {
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

          // Bodega
          AppSectionHeader(icon: Icons.warehouse, title: 'Bodega'),
          SizedBox(height: DesignTokens.spaceS),
          _buildBodegaSelector(options.bodegas),
          SizedBox(height: DesignTokens.spaceL),

          // Motivo
          AppSectionHeader(icon: Icons.report_problem_outlined, title: 'Motivo'),
          SizedBox(height: DesignTokens.spaceS),
          _buildMotivoSelector(options.motivos),
          SizedBox(height: DesignTokens.spaceL),

          // Inicio
          AppSectionHeader(icon: Icons.play_arrow, title: 'Inicio'),
          SizedBox(height: DesignTokens.spaceS),
          _buildDateTimeField(
            label: 'Fecha y hora de inicio',
            value: _inicio,
            onChanged: (dt) => setState(() => _inicio = dt),
          ),
          SizedBox(height: DesignTokens.spaceL),

          // Fin (opcional)
          AppSectionHeader(icon: Icons.stop, title: 'Fin (opcional)'),
          SizedBox(height: DesignTokens.spaceS),
          _buildDateTimeField(
            label: 'Fecha y hora de fin',
            value: _fin,
            isOptional: true,
            onChanged: (dt) => setState(() => _fin = dt),
          ),
          SizedBox(height: DesignTokens.spaceL),

          // Observacion
          AppSectionHeader(icon: Icons.notes, title: 'Observacion'),
          SizedBox(height: DesignTokens.spaceS),
          TextFormField(
            controller: _observacionController,
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
      onChanged: (v) => setState(() => _selectedServicioId = v),
      validator: (v) => v == null ? 'Selecciona un servicio' : null,
    );
  }

  Widget _buildBodegaSelector(List<String> bodegas) {
    if (bodegas.isEmpty) {
      return TextFormField(
        initialValue: _selectedBodega,
        decoration: InputDecoration(
          labelText: 'Bodega *',
          hintText: 'Ej: BODEGA 1',
          prefixIcon: Icon(Icons.warehouse, color: AppColors.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        onChanged: (v) => _selectedBodega = v,
        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa una bodega' : null,
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedBodega != null && bodegas.contains(_selectedBodega) ? _selectedBodega : null,
      decoration: InputDecoration(
        labelText: 'Bodega *',
        hintText: 'Seleccionar bodega...',
        prefixIcon: Icon(Icons.warehouse, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: bodegas.map((b) {
        return DropdownMenuItem<String>(
          value: b,
          child: Text(b, style: TextStyle(fontSize: DesignTokens.fontSizeS)),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedBodega = v),
      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona una bodega' : null,
    );
  }

  Widget _buildMotivoSelector(List<OptionItem> motivos) {
    if (motivos.isEmpty) {
      return _buildWarningBox('No hay motivos disponibles');
    }

    return DropdownButtonFormField<int>(
      value: _selectedMotivoId,
      decoration: InputDecoration(
        labelText: 'Motivo *',
        hintText: 'Seleccionar motivo...',
        prefixIcon: Icon(Icons.report_problem_outlined, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      isExpanded: true,
      items: motivos.map((m) {
        return DropdownMenuItem<int>(
          value: m.id,
          child: Text(
            m.label,
            style: TextStyle(fontSize: DesignTokens.fontSizeS),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedMotivoId = v),
      validator: (v) => v == null ? 'Selecciona un motivo' : null,
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
    bool isOptional = false,
  }) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? nowLima(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date == null) return;

        if (!mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: value != null
              ? TimeOfDay.fromDateTime(value)
              : TimeOfDay.now(),
        );
        if (time == null) return;

        final combined = makeLima(date.year, date.month, date.day, time.hour, time.minute);
        onChanged(combined);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label + (isOptional ? '' : ' *'),
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
          suffixIcon: isOptional && value != null
              ? IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: () => onChanged(nowLima()), // Reset
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          value != null ? dateTimeFormat.format(value) : 'Seleccionar...',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: value != null ? null : AppColors.textSecondary,
          ),
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
                  : 'Crear Paralizacion',
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
    if (_selectedBodega == null || _selectedBodega!.isEmpty) {
      AppSnackBar.error(context, 'Selecciona una bodega');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        if (_selectedServicioId != null) 'servicio': _selectedServicioId,
        'bodega': _selectedBodega,
        if (_selectedMotivoId != null) 'motivo': _selectedMotivoId,
        'inicio': makeLima(_inicio.year, _inicio.month, _inicio.day, _inicio.hour, _inicio.minute).toUtc().toIso8601String(),
        if (_fin != null)
          'fin': makeLima(_fin!.year, _fin!.month, _fin!.day, _fin!.hour, _fin!.minute).toUtc().toIso8601String(),
        if (_observacionController.text.isNotEmpty)
          'observacion': _observacionController.text,
      };

      final service = ref.read(paralizacionesServiceProvider);

      if (widget.isEditMode) {
        await service.partialUpdate(widget.paralizacionId!, data);
      } else {
        await service.create(data);
      }

      // Refresh list
      ref.read(paralizacionesListProvider.notifier).refresh();

      if (mounted) {
        AppSnackBar.success(
          context,
          widget.isEditMode ? 'Paralizacion actualizada' : 'Paralizacion creada',
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
