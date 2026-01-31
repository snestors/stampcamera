// =============================================================================
// PANTALLA DE CREAR/EDITAR ALMACÉN
// =============================================================================
import 'dart:async';
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

class AlmacenCrearScreen extends ConsumerStatefulWidget {
  final int? almacenId;
  final bool isEditMode;

  const AlmacenCrearScreen({super.key})
      : almacenId = null,
        isEditMode = false;

  const AlmacenCrearScreen.edit({super.key, required this.almacenId})
      : isEditMode = true;

  @override
  ConsumerState<AlmacenCrearScreen> createState() => _AlmacenCrearScreenState();
}

class _AlmacenCrearScreenState extends ConsumerState<AlmacenCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pesoBrutoController = TextEditingController();
  final _pesoTaraController = TextEditingController();
  final _pesoNetoController = TextEditingController();
  final _bagsController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _balanzaSearchController = TextEditingController();

  // Balanza seleccionada
  Balanza? _selectedBalanza;
  List<Balanza> _balanzaResults = [];
  bool _isSearchingBalanzas = false;
  Timer? _searchDebounce;

  DateTime _fechaEntradaAlmacen = DateTime.now();
  DateTime _fechaSalidaAlmacen = DateTime.now();
  String? _foto1Path;
  String? _foto2Path;
  String? _existingFoto1Url;
  String? _existingFoto2Url;
  bool _isSubmitting = false;
  bool _isLoadingAlmacen = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.almacenId != null) {
      _loadAlmacenData();
    }
    // Listeners para actualizar la validación reactiva cuando cambian los pesos
    _pesoBrutoController.addListener(_onPesoChanged);
    _pesoTaraController.addListener(_onPesoChanged);
    _pesoNetoController.addListener(_onPesoChanged);
  }

  void _onPesoChanged() {
    // Solo actualizar el estado para que se recalcule la validación
    if (mounted) setState(() {});
  }

  // Getter para validación de peso neto
  bool get _hasPesoNetoError {
    final bruto = double.tryParse(_pesoBrutoController.text) ?? 0;
    final tara = double.tryParse(_pesoTaraController.text) ?? 0;
    final neto = double.tryParse(_pesoNetoController.text) ?? 0;
    if (bruto <= 0 || tara < 0 || neto <= 0) return false;
    final expectedNeto = bruto - tara;
    return (neto - expectedNeto).abs() > 0.001;
  }

  double get _expectedPesoNeto {
    final bruto = double.tryParse(_pesoBrutoController.text) ?? 0;
    final tara = double.tryParse(_pesoTaraController.text) ?? 0;
    return bruto - tara;
  }

  // Getter para validación de fechas
  bool get _hasEntradaAntesSalidaBalanzaError {
    if (widget.isEditMode || _selectedBalanza == null) return false;
    final salidaBalanza = _selectedBalanza!.fechaSalidaBalanza;
    if (salidaBalanza == null) return false;
    return _fechaEntradaAlmacen.isBefore(salidaBalanza);
  }

  bool get _hasEntradaDespuesSalidaError {
    return _fechaEntradaAlmacen.isAfter(_fechaSalidaAlmacen);
  }

  Future<void> _loadAlmacenData() async {
    setState(() => _isLoadingAlmacen = true);
    try {
      final almacen = await ref.read(almacenDetalleProvider(widget.almacenId!).future);
      if (mounted) {
        setState(() {
          _pesoBrutoController.text = almacen.pesoBruto.toStringAsFixed(3);
          _pesoTaraController.text = almacen.pesoTara.toStringAsFixed(3);
          _pesoNetoController.text = almacen.pesoNeto.toStringAsFixed(3);
          _bagsController.text = almacen.bags?.toString() ?? '';
          _observacionesController.text = almacen.observaciones ?? '';
          _fechaEntradaAlmacen = almacen.fechaEntradaAlmacen ?? DateTime.now();
          _fechaSalidaAlmacen = almacen.fechaSalidaAlmacen ?? DateTime.now();
          _existingFoto1Url = almacen.foto1Url;
          _isLoadingAlmacen = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAlmacen = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar almacén: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Buscar balanzas sin almacén
  void _searchBalanzas(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _balanzaResults = [];
        _isSearchingBalanzas = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isSearchingBalanzas = true);
      try {
        final service = ref.read(balanzaServiceProvider);
        final response = await service.getBalanzasSinAlmacen(search: query);
        if (mounted) {
          setState(() {
            _balanzaResults = response.results;
            _isSearchingBalanzas = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearchingBalanzas = false);
        }
      }
    });
  }

  /// Seleccionar una balanza
  void _selectBalanza(Balanza balanza) {
    setState(() {
      _selectedBalanza = balanza;
      _balanzaResults = [];
      _balanzaSearchController.clear();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pesoBrutoController.dispose();
    _pesoTaraController.dispose();
    _pesoNetoController.dispose();
    _bagsController.dispose();
    _observacionesController.dispose();
    _balanzaSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAlmacen) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            'Cargando...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeL,
            ),
          ),
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
          widget.isEditMode ? 'Editar Almacén' : 'Nuevo Almacén',
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
          // Sección: Balanza (solo en creación)
          if (!widget.isEditMode) ...[
            _buildSectionHeader('Balanza', Icons.scale),
            _buildBalanzaSearch(),
            SizedBox(height: DesignTokens.spaceL),
          ],

          // Sección: Tiempos
          _buildSectionHeader('Tiempos de Almacén', Icons.access_time),
          _buildDateTimeFields(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Pesos
          _buildSectionHeader('Pesos (TM)', Icons.scale),
          _buildWeightFields(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Fotos
          _buildSectionHeader('Fotos', Icons.camera_alt),
          _buildPhotoFields(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Observaciones
          _buildSectionHeader('Observaciones', Icons.notes),
          _buildObservacionesField(),
          SizedBox(height: DesignTokens.spaceXL),

          // Botón de guardar
          _buildSubmitButton(),
          // SafeArea inferior + espacio adicional
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

  /// Búsqueda de balanzas sin almacén
  Widget _buildBalanzaSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balanza seleccionada
        if (_selectedBalanza != null) ...[
          Card(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              side: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.scale, color: Colors.white, size: 18),
              ),
              title: Text(
                'Guía: ${_selectedBalanza!.guia}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_selectedBalanza!.placaStr ?? "Sin placa"} • Ticket: ${_selectedBalanza!.ticketNumero ?? "-"}',
                style: TextStyle(fontSize: DesignTokens.fontSizeS),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () {
                  setState(() => _selectedBalanza = null);
                },
              ),
            ),
          ),
        ] else ...[
          // Campo de búsqueda
          TextFormField(
            controller: _balanzaSearchController,
            decoration: InputDecoration(
              labelText: 'Buscar Balanza sin Almacén *',
              hintText: 'Buscar por guía, placa o ticket...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearchingBalanzas
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            onChanged: _searchBalanzas,
            validator: (_) {
              if (_selectedBalanza == null) {
                return 'Debes seleccionar una balanza';
              }
              return null;
            },
          ),
          // Resultados de búsqueda
          if (_balanzaResults.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spaceS),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neutral),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _balanzaResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final balanza = _balanzaResults[index];
                  final numberFormat = NumberFormat('#,##0.000', 'es_PE');
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.scale, size: 20, color: AppColors.primary),
                    title: Text(
                      'Guía: ${balanza.guia}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${balanza.placaStr ?? "Sin placa"} • ${numberFormat.format(balanza.pesoNeto)} TM',
                      style: TextStyle(fontSize: DesignTokens.fontSizeXS),
                    ),
                    onTap: () => _selectBalanza(balanza),
                  );
                },
              ),
            ),
          ],
          // Mensaje cuando no hay resultados
          if (_balanzaSearchController.text.isNotEmpty &&
              _balanzaResults.isEmpty &&
              !_isSearchingBalanzas) ...[
            SizedBox(height: DesignTokens.spaceS),
            Text(
              'No se encontraron balanzas sin almacén',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDateTimeFields() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final hasEntradaError = _hasEntradaAntesSalidaBalanzaError || _hasEntradaDespuesSalidaError;

    return Column(
      children: [
        InkWell(
          onTap: () => _selectDateTime(isEntrada: true),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Entrada a Almacén *',
              prefixIcon: Icon(
                Icons.login,
                color: hasEntradaError ? AppColors.error : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(
                  color: hasEntradaError ? AppColors.error : AppColors.neutral,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(
                  color: hasEntradaError ? AppColors.error : AppColors.neutral,
                ),
              ),
              filled: true,
              fillColor: hasEntradaError
                  ? AppColors.error.withValues(alpha: 0.05)
                  : AppColors.surface,
            ),
            child: Text(
              dateFormat.format(_fechaEntradaAlmacen),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: hasEntradaError ? AppColors.error : null,
              ),
            ),
          ),
        ),
        // Mensaje de error: entrada antes de salida balanza
        if (_hasEntradaAntesSalidaBalanzaError) ...[
          SizedBox(height: DesignTokens.spaceXS),
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.error, size: 14),
              SizedBox(width: DesignTokens.spaceXS),
              Expanded(
                child: Text(
                  'Debe ser posterior a salida balanza: ${dateFormat.format(_selectedBalanza!.fechaSalidaBalanza!.toLocal())}',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: DesignTokens.fontSizeXS,
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: DesignTokens.spaceM),
        InkWell(
          onTap: () => _selectDateTime(isEntrada: false),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Salida de Almacén *',
              prefixIcon: Icon(
                Icons.logout,
                color: _hasEntradaDespuesSalidaError ? AppColors.error : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(
                  color: _hasEntradaDespuesSalidaError ? AppColors.error : AppColors.neutral,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(
                  color: _hasEntradaDespuesSalidaError ? AppColors.error : AppColors.neutral,
                ),
              ),
              filled: true,
              fillColor: _hasEntradaDespuesSalidaError
                  ? AppColors.error.withValues(alpha: 0.05)
                  : AppColors.surface,
            ),
            child: Text(
              dateFormat.format(_fechaSalidaAlmacen),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: _hasEntradaDespuesSalidaError ? AppColors.error : null,
              ),
            ),
          ),
        ),
        // Mensaje de error: entrada después de salida
        if (_hasEntradaDespuesSalidaError) ...[
          SizedBox(height: DesignTokens.spaceXS),
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.error, size: 14),
              SizedBox(width: DesignTokens.spaceXS),
              Expanded(
                child: Text(
                  'La entrada debe ser anterior a la salida',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: DesignTokens.fontSizeXS,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _selectDateTime({required bool isEntrada}) async {
    final initialDate = isEntrada ? _fechaEntradaAlmacen : _fechaSalidaAlmacen;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        initialEntryMode: TimePickerEntryMode.input, // Modo texto, sin dial
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final dateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute,
        );
        setState(() {
          if (isEntrada) {
            _fechaEntradaAlmacen = dateTime;
          } else {
            _fechaSalidaAlmacen = dateTime;
          }
        });
      }
    }
  }

  Widget _buildWeightFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pesoBrutoController,
                decoration: InputDecoration(
                  labelText: 'Peso Bruto *',
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
                controller: _pesoTaraController,
                decoration: InputDecoration(
                  labelText: 'Peso Tara *',
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
                  if (num == null || num < 0) return 'Inválido';
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spaceM),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pesoNetoController,
                decoration: InputDecoration(
                  labelText: 'Peso Neto *',
                  suffixText: 'TM',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    borderSide: BorderSide(
                      color: _hasPesoNetoError ? AppColors.error : AppColors.neutral,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    borderSide: BorderSide(
                      color: _hasPesoNetoError ? AppColors.error : AppColors.neutral,
                    ),
                  ),
                  filled: true,
                  fillColor: _hasPesoNetoError
                      ? AppColors.error.withValues(alpha: 0.05)
                      : AppColors.surface,
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
        ),
        // Mensaje de error cuando peso neto no coincide
        if (_hasPesoNetoError) ...[
          SizedBox(height: DesignTokens.spaceS),
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceS),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    'Peso Neto no coincide. Esperado: ${_expectedPesoNeto.toStringAsFixed(3)} TM',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: FontWeight.w500,
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

  Widget _buildPhotoFields() {
    return Column(
      children: [
        ReusableCameraCard(
          title: 'Foto 1',
          currentImagePath: _foto1Path,
          currentImageUrl: _existingFoto1Url,
          onImageSelected: (path) {
            setState(() => _foto1Path = path);
          },
        ),
        SizedBox(height: DesignTokens.spaceM),
        ReusableCameraCard(
          title: 'Foto 2 (Opcional)',
          currentImagePath: _foto2Path,
          currentImageUrl: _existingFoto2Url,
          onImageSelected: (path) {
            setState(() => _foto2Path = path);
          },
        ),
      ],
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
          : (widget.isEditMode ? 'Actualizar Almacén' : 'Crear Almacén'),
      icon: _isSubmitting ? null : Icons.save,
      onPressed: _isSubmitting ? null : _submitForm,
      isLoading: _isSubmitting,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que entrada almacén sea posterior a salida balanza (solo en creación)
    if (!widget.isEditMode && _selectedBalanza != null) {
      final salidaBalanza = _selectedBalanza!.fechaSalidaBalanza;
      if (salidaBalanza != null && _fechaEntradaAlmacen.isBefore(salidaBalanza)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La entrada a almacén debe ser posterior a la salida de balanza (${DateFormat('dd/MM/yyyy HH:mm').format(salidaBalanza)})',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Validar que entrada sea anterior a salida de almacén
    if (_fechaEntradaAlmacen.isAfter(_fechaSalidaAlmacen)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de entrada debe ser anterior a la de salida'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(almacenServiceProvider);

      if (widget.isEditMode) {
        await service.updateAlmacen(
          almacenId: widget.almacenId!,
          fechaEntradaAlmacen: _fechaEntradaAlmacen,
          fechaSalidaAlmacen: _fechaSalidaAlmacen,
          pesoBruto: double.parse(_pesoBrutoController.text),
          pesoTara: double.parse(_pesoTaraController.text),
          pesoNeto: double.parse(_pesoNetoController.text),
          bags: _bagsController.text.isEmpty ? null : int.parse(_bagsController.text),
          observaciones: _observacionesController.text.trim().isEmpty
              ? null : _observacionesController.text.trim(),
          foto1: _foto1Path != null ? File(_foto1Path!) : null,
          foto2: _foto2Path != null ? File(_foto2Path!) : null,
        );
      } else {
        await service.createAlmacen(
          balanzaId: _selectedBalanza!.id,
          fechaEntradaAlmacen: _fechaEntradaAlmacen,
          fechaSalidaAlmacen: _fechaSalidaAlmacen,
          pesoBruto: double.parse(_pesoBrutoController.text),
          pesoTara: double.parse(_pesoTaraController.text),
          pesoNeto: double.parse(_pesoNetoController.text),
          bags: _bagsController.text.isEmpty ? null : int.parse(_bagsController.text),
          observaciones: _observacionesController.text.trim().isEmpty
              ? null : _observacionesController.text.trim(),
          foto1: _foto1Path != null ? File(_foto1Path!) : null,
          foto2: _foto2Path != null ? File(_foto2Path!) : null,
        );
      }

      // Refrescar lista
      ref.invalidate(almacenListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode
                ? 'Almacén actualizado correctamente'
                : 'Almacén creado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
