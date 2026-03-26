// =============================================================================
// FORMULARIO UNIFICADO DE VIAJE — 3 PASOS (MUELLE, BALANZA, ALMACEN)
// =============================================================================
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/services/graneles/graneles_service.dart';
import 'package:stampcamera/services/http_service.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

// =============================================================================
// VIAJE FORM SCREEN — Widget principal
// =============================================================================

class ViajeFormScreen extends ConsumerStatefulWidget {
  final int? servicioId;
  final int? ticketId;
  final bool isEditMode;
  final int? initialStep; // 1=muelle, 2=balanza, 3=almacén

  /// Crear nuevo viaje (opcionalmente con servicio preseleccionado)
  const ViajeFormScreen({super.key, this.servicioId})
      : ticketId = null,
        isEditMode = false,
        initialStep = null;

  /// Editar viaje existente (opcionalmente abrir en paso específico)
  const ViajeFormScreen.edit({super.key, required this.ticketId, this.initialStep})
      : servicioId = null,
        isEditMode = true;

  @override
  ConsumerState<ViajeFormScreen> createState() => _ViajeFormScreenState();
}

class _ViajeFormScreenState extends ConsumerState<ViajeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─── Paso actual ───
  int _currentStep = 0;

  // ─── Estado de carga ───
  bool _isLoadingTicket = false;
  bool _isSubmitting = false;
  int? _effectiveServicioId;

  // ─── IDs para edicion (sub-modelos existentes) ───
  int? _editTicketId;
  int? _editBalanzaId;
  int? _editAlmacenId;

  // ─── Servicios ───
  final TicketMuelleService _ticketService = TicketMuelleService();
  final HttpService _http = HttpService();

  // =========================================================================
  // PASO 1: MUELLE — State
  // =========================================================================
  final _numeroTicketController = TextEditingController();
  final _muelleObservacionesController = TextEditingController();
  final _placaSearchController = TextEditingController();
  final _transporteSearchController = TextEditingController();

  Timer? _placaDebounce;
  Timer? _transporteDebounce;

  List<OptionItem> _placaResults = [];
  List<OptionItem> _transporteResults = [];
  bool _isSearchingPlaca = false;
  bool _isSearchingTransporte = false;

  int? _selectedBlId;
  int? _selectedDistribucionId;
  int? _selectedPlacaId;
  int? _selectedTransporteId;
  DateTime _inicioDescarga = nowLima();
  DateTime _finDescarga = nowLima();
  String? _muelleFotoPath;
  String? _existingMuelleFotoUrl;

  // =========================================================================
  // PASO 2: BALANZA — State
  // =========================================================================
  final _guiaController = TextEditingController();
  final _balanzaPesoBrutoController = TextEditingController();
  final _balanzaPesoTaraController = TextEditingController();
  final _balanzaPesoNetoController = TextEditingController();
  final _balanzaBagsController = TextEditingController();
  final _balanzaEntradaStrController = TextEditingController();
  final _balanzaSalidaStrController = TextEditingController();
  final _balanzaObservacionesController = TextEditingController();
  final _precintoSearchController = TextEditingController();

  Timer? _precintoDebounce;
  List<OptionItem> _precintoResults = [];
  bool _isSearchingPrecintos = false;
  OptionItem? _selectedPrecinto;

  int? _selectedDistribucionAlmacenId;
  int? _selectedPrecintoId;
  int? _selectedPermisoId;
  DateTime _fechaEntradaBalanza = nowLima();
  DateTime _fechaSalidaBalanza = nowLima();
  DateTime _fechaEnvioWp = nowLima();
  String? _balanzaFoto1Path;
  String? _balanzaFoto2Path;
  String? _existingBalanzaFoto1Url;
  String? _existingBalanzaFoto2Url;

  // Nota: distribuciones_almacen y permisos vienen anidados en cada BlOption
  // desde TicketMuelleOptions, no necesitan carga separada.

  // =========================================================================
  // PASO 3: ALMACEN — State
  // =========================================================================
  final _almacenPesoBrutoController = TextEditingController();
  final _almacenPesoTaraController = TextEditingController();
  final _almacenPesoNetoController = TextEditingController();
  final _almacenBagsController = TextEditingController();
  final _almacenObservacionesController = TextEditingController();

  DateTime _fechaEntradaAlmacen = nowLima();
  DateTime _fechaSalidaAlmacen = nowLima();
  String? _almacenFoto1Path;
  String? _almacenFoto2Path;
  String? _existingAlmacenFoto1Url;
  String? _existingAlmacenFoto2Url;

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  @override
  void initState() {
    super.initState();
    _effectiveServicioId = widget.servicioId;

    // Listeners para validacion reactiva de pesos
    _balanzaPesoBrutoController.addListener(_onStateChanged);
    _balanzaPesoTaraController.addListener(_onStateChanged);
    _balanzaPesoNetoController.addListener(_onStateChanged);
    _almacenPesoBrutoController.addListener(_onStateChanged);
    _almacenPesoTaraController.addListener(_onStateChanged);
    _almacenPesoNetoController.addListener(_onStateChanged);

    if (widget.isEditMode && widget.ticketId != null) {
      _loadTicketData();
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _numeroTicketController.dispose();
    _muelleObservacionesController.dispose();
    _placaSearchController.dispose();
    _transporteSearchController.dispose();
    _placaDebounce?.cancel();
    _transporteDebounce?.cancel();

    _guiaController.dispose();
    _balanzaPesoBrutoController.dispose();
    _balanzaPesoTaraController.dispose();
    _balanzaPesoNetoController.dispose();
    _balanzaBagsController.dispose();
    _balanzaEntradaStrController.dispose();
    _balanzaSalidaStrController.dispose();
    _balanzaObservacionesController.dispose();
    _precintoSearchController.dispose();
    _precintoDebounce?.cancel();

    _almacenPesoBrutoController.dispose();
    _almacenPesoTaraController.dispose();
    _almacenPesoNetoController.dispose();
    _almacenBagsController.dispose();
    _almacenObservacionesController.dispose();
    super.dispose();
  }

  // =========================================================================
  // CARGA DE DATOS (edicion)
  // =========================================================================

  Future<void> _loadTicketData() async {
    setState(() => _isLoadingTicket = true);
    try {
      final ticket = await ref.read(ticketMuelleDetalleProvider(widget.ticketId!).future);
      if (!mounted) return;

      _editTicketId = ticket.id;
      _effectiveServicioId = ticket.servicioId;

      // Muelle
      _numeroTicketController.text = ticket.numeroTicket;
      _muelleObservacionesController.text = ticket.observaciones ?? '';
      _inicioDescarga = ticket.inicioDescarga != null ? toLima(ticket.inicioDescarga!) : nowLima();
      _finDescarga = ticket.finDescarga != null ? toLima(ticket.finDescarga!) : nowLima();
      _existingMuelleFotoUrl = ticket.fotoUrl;
      _selectedBlId = ticket.blId;
      _selectedDistribucionId = ticket.distribucionId;
      _selectedPlacaId = ticket.placaId;
      _selectedTransporteId = ticket.transporteId;
      if (ticket.placaStr != null) _placaSearchController.text = ticket.placaStr!;
      if (ticket.transporteNombre != null) _transporteSearchController.text = ticket.transporteNombre!;

      // Balanza (si existe)
      if (ticket.balanzaData != null) {
        final b = ticket.balanzaData!;
        _editBalanzaId = b.id;
        _guiaController.text = b.guia;
        _balanzaPesoBrutoController.text = b.pesoBruto > 0 ? b.pesoBruto.toStringAsFixed(3) : '';
        _balanzaPesoTaraController.text = b.pesoTara > 0 ? b.pesoTara.toStringAsFixed(3) : '';
        _balanzaPesoNetoController.text = b.pesoNeto > 0 ? b.pesoNeto.toStringAsFixed(3) : '';
        _balanzaBagsController.text = b.bags?.toString() ?? '';
        _balanzaEntradaStrController.text = b.balanzaEntrada ?? '';
        _balanzaSalidaStrController.text = b.balanzaSalida ?? '';
        _balanzaObservacionesController.text = b.observaciones ?? '';
        _fechaEntradaBalanza = b.fechaEntradaBalanza != null ? toLima(b.fechaEntradaBalanza!) : nowLima();
        _fechaSalidaBalanza = b.fechaSalidaBalanza != null ? toLima(b.fechaSalidaBalanza!) : nowLima();
        _existingBalanzaFoto1Url = b.foto1Url;
        _existingBalanzaFoto2Url = b.foto2Url;
        _selectedDistribucionAlmacenId = b.distribucionAlmacenId;
        _selectedPrecintoId = b.precintoId;
        _selectedPermisoId = b.permisoId;
        if (b.precintoId != null && b.precinto != null) {
          _selectedPrecinto = OptionItem(id: b.precintoId!, label: b.precinto!);
        }
      }

      // Almacen (si existe)
      if (ticket.almacenData != null) {
        final a = ticket.almacenData!;
        _editAlmacenId = a.id;
        _almacenPesoBrutoController.text = a.pesoBruto > 0 ? a.pesoBruto.toStringAsFixed(3) : '';
        _almacenPesoTaraController.text = a.pesoTara > 0 ? a.pesoTara.toStringAsFixed(3) : '';
        _almacenPesoNetoController.text = a.pesoNeto > 0 ? a.pesoNeto.toStringAsFixed(3) : '';
        _almacenBagsController.text = a.bags?.toString() ?? '';
        _almacenObservacionesController.text = a.observaciones ?? '';
        _fechaEntradaAlmacen = a.fechaEntradaAlmacen != null ? toLima(a.fechaEntradaAlmacen!) : nowLima();
        _fechaSalidaAlmacen = a.fechaSalidaAlmacen != null ? toLima(a.fechaSalidaAlmacen!) : nowLima();
        _existingAlmacenFoto1Url = a.foto1Url;
        _existingAlmacenFoto2Url = a.foto2Url;
      }

      // Determinar paso inicial: prioridad al parámetro, luego estado
      if (widget.initialStep != null) {
        _currentStep = (widget.initialStep! - 1).clamp(0, 2);
      } else if (ticket.estado == 'pendiente_almacen') {
        _currentStep = 2;
      } else if (ticket.estado == 'pendiente_balanza') {
        _currentStep = 1;
      } else {
        _currentStep = 0;
      }

      setState(() => _isLoadingTicket = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTicket = false);
        AppSnackBar.error(context, 'Error al cargar ticket: $e');
      }
    }
  }

  // distribuciones_almacen y permisos ahora vienen anidados en cada BlOption
  // desde options_form/, no necesitan carga separada.

  // =========================================================================
  // VALIDACIONES
  // =========================================================================

  bool get _hasMuelleTimeError =>
      _inicioDescarga.isAfter(_finDescarga) || _inicioDescarga.isAtSameMomentAs(_finDescarga);

  bool get _hasBalanzaTimeError =>
      _fechaEntradaBalanza.isAfter(_fechaSalidaBalanza) ||
      _fechaEntradaBalanza.isAtSameMomentAs(_fechaSalidaBalanza);

  bool get _hasAlmacenTimeError =>
      _fechaEntradaAlmacen.isAfter(_fechaSalidaAlmacen) ||
      _fechaEntradaAlmacen.isAtSameMomentAs(_fechaSalidaAlmacen);

  bool _hasPesoNetoError(TextEditingController bruto, TextEditingController tara, TextEditingController neto) {
    final b = double.tryParse(bruto.text) ?? 0;
    final t = double.tryParse(tara.text) ?? 0;
    final n = double.tryParse(neto.text) ?? 0;
    if (b <= 0 || t < 0 || n <= 0) return false;
    return (n - (b - t)).abs() > 0.001;
  }

  double _expectedPesoNeto(TextEditingController bruto, TextEditingController tara) {
    return (double.tryParse(bruto.text) ?? 0) - (double.tryParse(tara.text) ?? 0);
  }

  /// Hay datos de balanza ingresados?
  bool get _hasBalanzaData {
    return _guiaController.text.trim().isNotEmpty ||
        _balanzaPesoBrutoController.text.trim().isNotEmpty ||
        _balanzaPesoTaraController.text.trim().isNotEmpty ||
        _balanzaPesoNetoController.text.trim().isNotEmpty ||
        _selectedDistribucionAlmacenId != null ||
        _selectedPrecintoId != null ||
        _selectedPermisoId != null ||
        _balanzaFoto1Path != null ||
        _existingBalanzaFoto1Url != null ||
        _editBalanzaId != null;
  }

  /// Hay datos de almacen ingresados?
  bool get _hasAlmacenData {
    return _almacenPesoBrutoController.text.trim().isNotEmpty ||
        _almacenPesoTaraController.text.trim().isNotEmpty ||
        _almacenPesoNetoController.text.trim().isNotEmpty ||
        _almacenFoto1Path != null ||
        _existingAlmacenFoto1Url != null ||
        _editAlmacenId != null;
  }

  /// Verificar si un paso tiene errores
  bool _stepHasErrors(int step) {
    switch (step) {
      case 0: // Muelle
        return _hasMuelleTimeError ||
            _numeroTicketController.text.trim().isEmpty ||
            _selectedBlId == null;
      case 1: // Balanza
        if (!_hasBalanzaData) return false;
        return _hasBalanzaTimeError ||
            _hasPesoNetoError(_balanzaPesoBrutoController, _balanzaPesoTaraController, _balanzaPesoNetoController);
      case 2: // Almacen
        if (!_hasAlmacenData) return false;
        return _hasAlmacenTimeError ||
            _hasPesoNetoError(_almacenPesoBrutoController, _almacenPesoTaraController, _almacenPesoNetoController);
      default:
        return false;
    }
  }

  /// Verificar si un paso tiene datos completados
  bool _stepIsComplete(int step) {
    switch (step) {
      case 0:
        return _numeroTicketController.text.trim().isNotEmpty &&
            _selectedBlId != null &&
            (_muelleFotoPath != null || _existingMuelleFotoUrl != null);
      case 1:
        return _hasBalanzaData &&
            _guiaController.text.trim().isNotEmpty &&
            _balanzaPesoBrutoController.text.trim().isNotEmpty;
      case 2:
        return _hasAlmacenData &&
            _almacenPesoBrutoController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  // =========================================================================
  // SEARCH HANDLERS
  // =========================================================================

  void _onPlacaSearchChanged(String query) {
    _placaDebounce?.cancel();
    _placaDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 2) {
        setState(() { _placaResults = []; _isSearchingPlaca = false; });
        return;
      }
      setState(() => _isSearchingPlaca = true);
      try {
        final results = await _ticketService.searchPlacas(query);
        if (mounted) setState(() { _placaResults = results; _isSearchingPlaca = false; });
      } catch (_) {
        if (mounted) setState(() => _isSearchingPlaca = false);
      }
    });
  }

  void _onTransporteSearchChanged(String query) {
    _transporteDebounce?.cancel();
    _transporteDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 2) {
        setState(() { _transporteResults = []; _isSearchingTransporte = false; });
        return;
      }
      setState(() => _isSearchingTransporte = true);
      try {
        final results = await _ticketService.searchTransportes(query);
        if (mounted) setState(() { _transporteResults = results; _isSearchingTransporte = false; });
      } catch (_) {
        if (mounted) setState(() => _isSearchingTransporte = false);
      }
    });
  }

  void _onPrecintoSearchChanged(String query) {
    _precintoDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _precintoResults = []; _isSearchingPrecintos = false; });
      return;
    }
    _precintoDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearchingPrecintos = true);
      try {
        final service = ref.read(balanzaServiceProvider);
        final results = await service.buscarPrecintos(search: query);
        if (mounted) setState(() { _precintoResults = results; _isSearchingPrecintos = false; });
      } catch (_) {
        if (mounted) setState(() => _isSearchingPrecintos = false);
      }
    });
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTicket) {
      return Scaffold(
        appBar: _buildAppBar('Cargando...'),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final asistenciaAsync = ref.watch(asistenciaActivaProvider);
    final embarqueId = asistenciaAsync.valueOrNull?.asistencia?.nave?.id;

    final optionsParams = TicketFormOptionsParams(
      servicioId: _effectiveServicioId,
      ticketId: widget.isEditMode ? widget.ticketId : null,
      embarqueId: embarqueId,
    );
    final optionsAsync = ref.watch(ticketMuelleOptionsFlexProvider(optionsParams));

    return Scaffold(
      appBar: _buildAppBar(widget.isEditMode ? 'Editar Viaje' : 'Nuevo Viaje'),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => ConnectionErrorScreen(
          error: error,
          onRetry: () => ref.invalidate(ticketMuelleOptionsFlexProvider(optionsParams)),
        ),
        data: (options) => _buildContent(options),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: DesignTokens.fontSizeL)),
    );
  }

  Widget _buildContent(TicketMuelleOptions options) {
    return Column(
      children: [
        // Stepper header
        _buildStepperHeader(),
        // Step content
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              child: _buildStepContent(options),
            ),
          ),
        ),
        // Bottom navigation
        _buildBottomBar(),
      ],
    );
  }

  // =========================================================================
  // STEPPER HEADER
  // =========================================================================

  Widget _buildStepperHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM, vertical: DesignTokens.spaceS),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildStepButton(0, Icons.anchor, 'Muelle'),
          SizedBox(width: DesignTokens.spaceS),
          _buildStepButton(1, Icons.scale, 'Balanza'),
          SizedBox(width: DesignTokens.spaceS),
          _buildStepButton(2, Icons.warehouse, 'Almacen'),
        ],
      ),
    );
  }

  Widget _buildStepButton(int step, IconData icon, String label) {
    final isActive = _currentStep == step;
    final isComplete = _stepIsComplete(step);
    final hasErrors = _stepHasErrors(step);

    Color bgColor;
    Color fgColor;
    if (isActive) {
      bgColor = AppColors.primary;
      fgColor = Colors.white;
    } else if (isComplete && !hasErrors) {
      bgColor = AppColors.success;
      fgColor = Colors.white;
    } else {
      bgColor = AppColors.neutral.withValues(alpha: 0.3);
      fgColor = AppColors.textSecondary;
    }

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              onTap: () => setState(() => _currentStep = step),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isComplete && !isActive)
                      Icon(Icons.check, size: 16, color: fgColor)
                    else
                      Icon(icon, size: 16, color: fgColor),
                    SizedBox(width: DesignTokens.spaceXS),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasErrors)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // BOTTOM BAR
  // =========================================================================

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spaceM,
        DesignTokens.spaceS,
        DesignTokens.spaceM,
        DesignTokens.spaceS + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: DesignTokens.spaceS),
          if (_currentStep < 2)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep++),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Siguiente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
                ),
              ),
            ),
          if (_currentStep < 2) SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSubmitting ? 'Guardando...' : 'Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP CONTENT ROUTER
  // =========================================================================

  Widget _buildStepContent(TicketMuelleOptions options) {
    switch (_currentStep) {
      case 0:
        return _buildMuelleStep(options);
      case 1:
        return _buildBalanzaStep(options);
      case 2:
        return _buildAlmacenStep(options);
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // PASO 1: MUELLE
  // =========================================================================

  Widget _buildMuelleStep(TicketMuelleOptions options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(icon: Icons.receipt, title: 'Datos del Ticket'),
        SizedBox(height: DesignTokens.spaceS),

        // N° Ticket
        TextFormField(
          controller: _numeroTicketController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'N\u00B0 Ticket *',
            hintText: 'Ingrese el numero de ticket',
            prefixIcon: const Icon(Icons.tag),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'El numero de ticket es requerido';
            if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo se permiten numeros';
            return null;
          },
        ),
        SizedBox(height: DesignTokens.spaceM),

        // BL
        _buildDropdown<int>(
          label: 'BL *',
          hint: 'Seleccionar BL',
          icon: Icons.description,
          initialValue: _selectedBlId,
          items: options.bls.map((e) => DropdownMenuItem(value: e.id, child: Text(e.label))).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBlId = value;
              _selectedDistribucionId = null;
              // Resetear opciones de balanza al cambiar BL
              _selectedDistribucionAlmacenId = null;
              _selectedPermisoId = null;
            });
          },
          validator: (value) => value == null ? 'Seleccione un BL' : null,
        ),
        SizedBox(height: DesignTokens.spaceM),

        // Bodega (distribucion filtrada por BL)
        Builder(builder: (context) {
          final selectedBl = _selectedBlId != null
              ? options.bls.where((bl) => bl.id == _selectedBlId).firstOrNull
              : null;
          final distribuciones = selectedBl?.distribuciones ?? [];

          return _buildDropdown<int>(
            label: 'Bodega',
            hint: _selectedBlId == null ? 'Primero seleccione un BL' : 'Seleccionar bodega',
            icon: Icons.warehouse,
            initialValue: _selectedDistribucionId,
            items: distribuciones.map((e) => DropdownMenuItem(value: e.id, child: Text(e.label))).toList(),
            onChanged: _selectedBlId == null ? null : (value) => setState(() => _selectedDistribucionId = value),
          );
        }),
        SizedBox(height: DesignTokens.spaceL),

        // Vehiculo y Transporte
        AppSectionHeader(icon: Icons.local_shipping, title: 'Vehiculo y Transporte'),
        SizedBox(height: DesignTokens.spaceS),
        _buildAsyncSearchField(
          label: 'Placa',
          hint: 'Buscar placa (min. 2 caracteres)',
          icon: Icons.directions_car,
          controller: _placaSearchController,
          results: _placaResults,
          isSearching: _isSearchingPlaca,
          selectedId: _selectedPlacaId,
          onSearchChanged: _onPlacaSearchChanged,
          onSelected: (item) => setState(() { _selectedPlacaId = item.id; _placaResults = []; }),
          onClear: () => setState(() { _selectedPlacaId = null; _placaSearchController.clear(); }),
        ),
        SizedBox(height: DesignTokens.spaceM),
        _buildAsyncSearchField(
          label: 'Empresa de Transporte',
          hint: 'Buscar por RUC o nombre (min. 2 caracteres)',
          icon: Icons.business,
          controller: _transporteSearchController,
          results: _transporteResults,
          isSearching: _isSearchingTransporte,
          selectedId: _selectedTransporteId,
          onSearchChanged: _onTransporteSearchChanged,
          onSelected: (item) => setState(() { _selectedTransporteId = item.id; _transporteResults = []; }),
          onClear: () => setState(() { _selectedTransporteId = null; _transporteSearchController.clear(); }),
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Tiempos
        AppSectionHeader(icon: Icons.access_time, title: 'Tiempos de Cargio'),
        SizedBox(height: DesignTokens.spaceS),
        Row(
          children: [
            Expanded(child: _buildDateTimePicker(label: 'Inicio *', value: _inicioDescarga, onChanged: (v) => setState(() => _inicioDescarga = v))),
            SizedBox(width: DesignTokens.spaceM),
            Expanded(child: _buildDateTimePicker(label: 'Fin *', value: _finDescarga, onChanged: (v) => setState(() => _finDescarga = v), hasError: _hasMuelleTimeError)),
          ],
        ),
        if (_hasMuelleTimeError)
          _buildTimeError('El fin de cargio debe ser mayor que el inicio'),
        SizedBox(height: DesignTokens.spaceL),

        // Observaciones
        AppSectionHeader(icon: Icons.notes, title: 'Observaciones'),
        SizedBox(height: DesignTokens.spaceS),
        TextFormField(
          controller: _muelleObservacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ingrese observaciones (opcional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Foto
        ReusableCameraCard(
          title: 'Foto del Ticket',
          subtitle: 'Captura la evidencia del ticket de muelle',
          currentImagePath: _muelleFotoPath,
          currentImageUrl: _existingMuelleFotoUrl,
          onImageSelected: (path) => setState(() { _muelleFotoPath = path; _existingMuelleFotoUrl = null; }),
          showGalleryOption: true,
          cameraResolution: CameraResolution.high,
          primaryColor: AppColors.primary,
        ),
        SizedBox(height: DesignTokens.spaceXL),
      ],
    );
  }

  // =========================================================================
  // PASO 2: BALANZA
  // =========================================================================

  Widget _buildBalanzaStep(TicketMuelleOptions options) {
    // Obtener distribuciones_almacen y permisos del BL seleccionado
    final selectedBl = _selectedBlId != null
        ? options.bls.where((bl) => bl.id == _selectedBlId).firstOrNull
        : null;
    final distribuciones = selectedBl?.distribucionesAlmacen ?? [];
    final permisos = selectedBl?.permisos ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guia
        AppSectionHeader(icon: Icons.description, title: 'Informacion de Guia'),
        SizedBox(height: DesignTokens.spaceS),
        TextFormField(
          controller: _guiaController,
          decoration: InputDecoration(
            labelText: 'Guia',
            hintText: 'Ej: 001234',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Almacen destino y seguridad
        AppSectionHeader(icon: Icons.warehouse, title: 'Distribucion y Seguridad'),
        SizedBox(height: DesignTokens.spaceS),

        ...[
          // Almacen destino
          if (distribuciones.isNotEmpty) ...[
            Builder(builder: (_) {
              final validValue = distribuciones.any((d) => d.id == _selectedDistribucionAlmacenId)
                  ? _selectedDistribucionAlmacenId
                  : null;
              return DropdownButtonFormField<int>(
                key: ValueKey('dist_almacen_$validValue'),
                initialValue: validValue,
                decoration: InputDecoration(
                  labelText: 'Almacen Destino',
                  hintText: 'Seleccionar almacen...',
                  prefixIcon: Icon(Icons.warehouse, color: AppColors.primary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                isExpanded: true,
                items: distribuciones.map((dist) => DropdownMenuItem<int>(
                  value: dist.id,
                  child: Text(dist.label, style: TextStyle(fontSize: DesignTokens.fontSizeS), overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (value) => setState(() => _selectedDistribucionAlmacenId = value),
              );
            }),
            SizedBox(height: DesignTokens.spaceM),
          ] else if (_selectedBlId == null) ...[
            Text(
              'Seleccione un BL en el paso 1 para cargar los almacenes',
              style: TextStyle(fontSize: DesignTokens.fontSizeS, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: DesignTokens.spaceM),
          ] else ...[
            Text(
              'No hay almacenes configurados para el BL seleccionado',
              style: TextStyle(fontSize: DesignTokens.fontSizeS, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: DesignTokens.spaceM),
          ],

          // Precinto (busqueda async)
          _buildPrecintoSearch(),
          SizedBox(height: DesignTokens.spaceM),

          // Permiso
          if (permisos.isNotEmpty) ...[
            Builder(builder: (_) {
              final validPermisoId = _selectedPermisoId == null || permisos.any((p) => p.id == _selectedPermisoId)
                  ? _selectedPermisoId : null;
              return DropdownButtonFormField<int>(
                key: ValueKey('permiso_$validPermisoId'),
                initialValue: validPermisoId,
                decoration: InputDecoration(
                  labelText: 'Permiso',
                  hintText: 'Seleccionar permiso (opcional)...',
                  prefixIcon: Icon(Icons.badge, color: AppColors.primary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                isExpanded: true,
                items: [
                  DropdownMenuItem<int>(value: null, child: Text('Sin permiso', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
                  ...permisos.map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.label, style: TextStyle(fontSize: DesignTokens.fontSizeS)))),
                ],
                onChanged: (value) => setState(() => _selectedPermisoId = value),
              );
            }),
          ],
        ],
        SizedBox(height: DesignTokens.spaceL),

        // Entrada (fecha + balanza string)
        AppSectionHeader(icon: Icons.login, title: 'Entrada'),
        SizedBox(height: DesignTokens.spaceS),
        _buildBalanzaDateTimeRow(
          label: 'Fecha Entrada',
          value: _fechaEntradaBalanza,
          onChanged: (v) => setState(() => _fechaEntradaBalanza = v),
          balanzaController: _balanzaEntradaStrController,
          balanzaHint: 'B1',
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Salida (fecha + balanza string)
        AppSectionHeader(icon: Icons.logout, title: 'Salida'),
        SizedBox(height: DesignTokens.spaceS),
        _buildBalanzaDateTimeRow(
          label: 'Fecha Salida',
          value: _fechaSalidaBalanza,
          onChanged: (v) => setState(() => _fechaSalidaBalanza = v),
          balanzaController: _balanzaSalidaStrController,
          balanzaHint: 'B2',
          hasError: _hasBalanzaTimeError,
        ),
        if (_hasBalanzaTimeError)
          _buildTimeError('La fecha de salida debe ser mayor que la de entrada'),
        SizedBox(height: DesignTokens.spaceL),

        // Pesos
        AppSectionHeader(icon: Icons.scale, title: 'Pesos (TM)'),
        SizedBox(height: DesignTokens.spaceS),
        _buildWeightFields(
          brutoController: _balanzaPesoBrutoController,
          taraController: _balanzaPesoTaraController,
          netoController: _balanzaPesoNetoController,
          bagsController: _balanzaBagsController,
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Fecha envio WP
        AppSectionHeader(icon: Icons.send, title: 'Envio WhatsApp'),
        SizedBox(height: DesignTokens.spaceS),
        _buildDateTimePicker(label: 'Fecha Envio WP', value: _fechaEnvioWp, onChanged: (v) => setState(() => _fechaEnvioWp = v)),
        SizedBox(height: DesignTokens.spaceL),

        // Fotos
        AppSectionHeader(icon: Icons.camera_alt, title: 'Fotos'),
        SizedBox(height: DesignTokens.spaceS),
        ReusableCameraCard(
          title: 'Foto 1',
          currentImagePath: _balanzaFoto1Path,
          currentImageUrl: _existingBalanzaFoto1Url,
          onImageSelected: (path) => setState(() => _balanzaFoto1Path = path),
        ),
        SizedBox(height: DesignTokens.spaceM),
        ReusableCameraCard(
          title: 'Foto 2 (Opcional)',
          currentImagePath: _balanzaFoto2Path,
          currentImageUrl: _existingBalanzaFoto2Url,
          onImageSelected: (path) => setState(() => _balanzaFoto2Path = path),
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Observaciones
        AppSectionHeader(icon: Icons.notes, title: 'Observaciones'),
        SizedBox(height: DesignTokens.spaceS),
        TextFormField(
          controller: _balanzaObservacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Notas adicionales...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        SizedBox(height: DesignTokens.spaceXL),
      ],
    );
  }

  // =========================================================================
  // PASO 3: ALMACEN
  // =========================================================================

  Widget _buildAlmacenStep(TicketMuelleOptions options) {
    // Info almacen destino (solo lectura, del paso 2) — del BL seleccionado
    final selectedBl = _selectedBlId != null
        ? options.bls.where((bl) => bl.id == _selectedBlId).firstOrNull
        : null;
    final almacenLabel = _selectedDistribucionAlmacenId != null
        ? (selectedBl?.distribucionesAlmacen ?? [])
            .where((d) => d.id == _selectedDistribucionAlmacenId)
            .firstOrNull?.label
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge de almacen destino
        if (almacenLabel != null) ...[
          AppSectionHeader(icon: Icons.warehouse, title: 'Almacen Destino'),
          SizedBox(height: DesignTokens.spaceS),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.warehouse, color: AppColors.primary, size: 20),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    almacenLabel,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: DesignTokens.fontSizeS, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
        ],

        // Tiempos
        AppSectionHeader(icon: Icons.access_time, title: 'Tiempos de Almacen'),
        SizedBox(height: DesignTokens.spaceS),
        Row(
          children: [
            Expanded(child: _buildDateTimePicker(label: 'Entrada *', value: _fechaEntradaAlmacen, onChanged: (v) => setState(() => _fechaEntradaAlmacen = v))),
            SizedBox(width: DesignTokens.spaceM),
            Expanded(child: _buildDateTimePicker(label: 'Salida *', value: _fechaSalidaAlmacen, onChanged: (v) => setState(() => _fechaSalidaAlmacen = v), hasError: _hasAlmacenTimeError)),
          ],
        ),
        if (_hasAlmacenTimeError)
          _buildTimeError('La entrada debe ser anterior a la salida'),
        SizedBox(height: DesignTokens.spaceL),

        // Pesos
        AppSectionHeader(icon: Icons.scale, title: 'Pesos (TM)'),
        SizedBox(height: DesignTokens.spaceS),
        _buildWeightFields(
          brutoController: _almacenPesoBrutoController,
          taraController: _almacenPesoTaraController,
          netoController: _almacenPesoNetoController,
          bagsController: _almacenBagsController,
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Fotos
        AppSectionHeader(icon: Icons.camera_alt, title: 'Fotos'),
        SizedBox(height: DesignTokens.spaceS),
        ReusableCameraCard(
          title: 'Foto 1',
          currentImagePath: _almacenFoto1Path,
          currentImageUrl: _existingAlmacenFoto1Url,
          onImageSelected: (path) => setState(() => _almacenFoto1Path = path),
        ),
        SizedBox(height: DesignTokens.spaceM),
        ReusableCameraCard(
          title: 'Foto 2 (Opcional)',
          currentImagePath: _almacenFoto2Path,
          currentImageUrl: _existingAlmacenFoto2Url,
          onImageSelected: (path) => setState(() => _almacenFoto2Path = path),
        ),
        SizedBox(height: DesignTokens.spaceL),

        // Observaciones
        AppSectionHeader(icon: Icons.notes, title: 'Observaciones'),
        SizedBox(height: DesignTokens.spaceS),
        TextFormField(
          controller: _almacenObservacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Notas adicionales...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
            filled: true,
            fillColor: AppColors.surface,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        SizedBox(height: DesignTokens.spaceXL),
      ],
    );
  }

  // =========================================================================
  // WIDGETS COMPARTIDOS
  // =========================================================================

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? initialValue,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) {
    final isDisabled = onChanged == null;
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
        filled: true,
        fillColor: isDisabled ? AppColors.neutral.withValues(alpha: 0.3) : AppColors.surface,
      ),
      style: TextStyle(
        fontSize: DesignTokens.fontSizeS,
        color: isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      isExpanded: true,
    );
  }

  Widget _buildAsyncSearchField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required List<OptionItem> results,
    required bool isSearching,
    required int? selectedId,
    required void Function(String) onSearchChanged,
    required void Function(OptionItem) onSelected,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: selectedId != null
                ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear)
                : isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      )
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
            filled: true,
            fillColor: selectedId != null ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
          ),
          readOnly: selectedId != null,
        ),
        if (results.isNotEmpty && selectedId == null)
          Container(
            margin: EdgeInsets.only(top: DesignTokens.spaceXS),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(color: AppColors.neutral),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];
                return ListTile(
                  dense: true,
                  title: Text(item.label, style: TextStyle(fontSize: DesignTokens.fontSizeS)),
                  onTap: () {
                    controller.text = item.label;
                    onSelected(item);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPrecintoSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedPrecinto != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM, vertical: DesignTokens.spaceS),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, size: 18, color: AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(child: Text(_selectedPrecinto!.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: DesignTokens.fontSizeS))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: () => setState(() { _selectedPrecinto = null; _selectedPrecintoId = null; }),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: _precintoSearchController,
            decoration: InputDecoration(
              labelText: 'Precinto (opcional)',
              hintText: 'Buscar precinto disponible...',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: _isSearchingPrecintos
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
              filled: true,
              fillColor: AppColors.surface,
            ),
            onChanged: _onPrecintoSearchChanged,
          ),
          if (_precintoResults.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: DesignTokens.spaceS),
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neutral),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _precintoResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final precinto = _precintoResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.lock, size: 18, color: AppColors.primary),
                    title: Text(precinto.label, style: TextStyle(fontSize: DesignTokens.fontSizeS)),
                    onTap: () => setState(() {
                      _selectedPrecinto = precinto;
                      _selectedPrecintoId = precinto.id;
                      _precintoResults = [];
                      _precintoSearchController.clear();
                    }),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    bool hasError = false,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: nowLima().subtract(const Duration(days: 30)),
          lastDate: nowLima().add(const Duration(days: 1)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
            initialEntryMode: TimePickerEntryMode.input,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
          if (time != null) {
            onChanged(makeLima(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      },
      child: Builder(builder: (context) {
        final display = toLima(value);
        return Container(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          decoration: BoxDecoration(
            color: hasError ? AppColors.error.withValues(alpha: 0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: hasError ? AppColors.error : AppColors.neutral, width: hasError ? 1.5 : 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: DesignTokens.fontSizeXS, color: hasError ? AppColors.error : AppColors.textSecondary)),
              SizedBox(height: DesignTokens.spaceXS),
              Row(children: [
                Icon(Icons.calendar_today, size: 16, color: hasError ? AppColors.error : AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Text('${display.day}/${display.month}/${display.year}', style: TextStyle(fontSize: DesignTokens.fontSizeS, fontWeight: FontWeight.w600, color: hasError ? AppColors.error : null)),
              ]),
              SizedBox(height: DesignTokens.spaceXS),
              Row(children: [
                Icon(Icons.access_time, size: 16, color: hasError ? AppColors.error : AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Text('${display.hour.toString().padLeft(2, '0')}:${display.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: DesignTokens.fontSizeS, fontWeight: FontWeight.w600, color: hasError ? AppColors.error : null)),
              ]),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBalanzaDateTimeRow({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
    required TextEditingController balanzaController,
    required String balanzaHint,
    bool hasError = false,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2020),
                lastDate: nowLima().add(const Duration(days: 1)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(toLima(value)),
                  initialEntryMode: TimePickerEntryMode.input,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (time != null) {
                  onChanged(makeLima(date.year, date.month, date.day, time.hour, time.minute));
                }
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '$label *',
                labelStyle: hasError ? TextStyle(color: AppColors.error) : null,
                prefixIcon: Icon(Icons.access_time, size: 20, color: hasError ? AppColors.error : null),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.neutral),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.neutral, width: hasError ? 1.5 : 1.0),
                ),
                filled: true,
                fillColor: hasError ? AppColors.error.withValues(alpha: 0.05) : AppColors.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS, vertical: DesignTokens.spaceS),
              ),
              child: Text(
                dateFormat.format(toLima(value)),
                style: TextStyle(fontSize: DesignTokens.fontSizeS, color: hasError ? AppColors.error : null),
              ),
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: balanzaController,
            decoration: InputDecoration(
              labelText: 'Balanza',
              hintText: balanzaHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS, vertical: DesignTokens.spaceM),
            ),
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: DesignTokens.fontSizeM),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightFields({
    required TextEditingController brutoController,
    required TextEditingController taraController,
    required TextEditingController netoController,
    required TextEditingController bagsController,
  }) {
    final hasNetoError = _hasPesoNetoError(brutoController, taraController, netoController);
    final expected = _expectedPesoNeto(brutoController, taraController);

    return Column(
      children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: brutoController,
              decoration: InputDecoration(
                labelText: 'P. Bruto',
                suffixText: 'TM',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))],
            ),
          ),
          SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: TextFormField(
              controller: taraController,
              decoration: InputDecoration(
                labelText: 'P. Tara',
                suffixText: 'TM',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))],
            ),
          ),
        ]),
        SizedBox(height: DesignTokens.spaceM),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: netoController,
              decoration: InputDecoration(
                labelText: 'P. Neto',
                suffixText: 'TM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  borderSide: BorderSide(color: hasNetoError ? AppColors.error : AppColors.neutral),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  borderSide: BorderSide(color: hasNetoError ? AppColors.error : AppColors.neutral),
                ),
                filled: true,
                fillColor: hasNetoError ? AppColors.error.withValues(alpha: 0.05) : AppColors.surface,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))],
            ),
          ),
          SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: TextFormField(
              controller: bagsController,
              decoration: InputDecoration(
                labelText: 'Bags',
                hintText: 'Opcional',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusM)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ]),
        if (hasNetoError) ...[
          SizedBox(height: DesignTokens.spaceS),
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceS),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber, color: AppColors.error, size: 18),
              SizedBox(width: DesignTokens.spaceS),
              Expanded(
                child: Text(
                  'Peso Neto no coincide. Esperado: ${expected.toStringAsFixed(3)} TM',
                  style: TextStyle(color: AppColors.error, fontSize: DesignTokens.fontSizeS, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeError(String message) {
    return Padding(
      padding: EdgeInsets.only(top: DesignTokens.spaceXS),
      child: Row(children: [
        Icon(Icons.error_outline, size: 14, color: AppColors.error),
        SizedBox(width: DesignTokens.spaceXS),
        Expanded(child: Text(message, style: TextStyle(color: AppColors.error, fontSize: DesignTokens.fontSizeXS))),
      ]),
    );
  }

  // =========================================================================
  // SUBMIT — Enviar todo al backend
  // =========================================================================

  Future<void> _submitForm() async {
    // Validar paso 1 (muelle) siempre requerido
    if (_numeroTicketController.text.trim().isEmpty) {
      AppSnackBar.error(context, 'El numero de ticket es requerido');
      setState(() => _currentStep = 0);
      return;
    }
    if (_selectedBlId == null) {
      AppSnackBar.error(context, 'Debe seleccionar un BL');
      setState(() => _currentStep = 0);
      return;
    }
    if (_hasMuelleTimeError) {
      AppSnackBar.error(context, 'El fin de cargio debe ser mayor que el inicio');
      setState(() => _currentStep = 0);
      return;
    }
    if (!widget.isEditMode && _muelleFotoPath == null && _existingMuelleFotoUrl == null) {
      AppSnackBar.error(context, 'La foto del ticket es requerida');
      setState(() => _currentStep = 0);
      return;
    }

    // Validar balanza si tiene datos
    if (_hasBalanzaData) {
      if (_hasBalanzaTimeError) {
        AppSnackBar.error(context, 'Balanza: la fecha de salida debe ser mayor que la de entrada');
        setState(() => _currentStep = 1);
        return;
      }
      if (_hasPesoNetoError(_balanzaPesoBrutoController, _balanzaPesoTaraController, _balanzaPesoNetoController)) {
        AppSnackBar.error(context, 'Balanza: el peso neto no coincide con bruto - tara');
        setState(() => _currentStep = 1);
        return;
      }
    }

    // Validar almacen si tiene datos
    if (_hasAlmacenData) {
      if (_hasAlmacenTimeError) {
        AppSnackBar.error(context, 'Almacen: la entrada debe ser anterior a la salida');
        setState(() => _currentStep = 2);
        return;
      }
      if (_hasPesoNetoError(_almacenPesoBrutoController, _almacenPesoTaraController, _almacenPesoNetoController)) {
        AppSnackBar.error(context, 'Almacen: el peso neto no coincide con bruto - tara');
        setState(() => _currentStep = 2);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Construir FormData multipart
      final Map<String, dynamic> fields = {};

      // ── Campos Muelle (sin prefijo) ──
      fields['numero_ticket'] = _numeroTicketController.text.trim();
      fields['bl'] = _selectedBlId.toString();
      if (_selectedDistribucionId != null) fields['distribucion'] = _selectedDistribucionId.toString();
      if (_selectedPlacaId != null) fields['placa'] = _selectedPlacaId.toString();
      if (_selectedTransporteId != null) fields['transporte'] = _selectedTransporteId.toString();
      fields['inicio_descarga'] = _inicioDescarga.toIso8601String();
      fields['fin_descarga'] = _finDescarga.toIso8601String();
      if (_muelleObservacionesController.text.trim().isNotEmpty) {
        fields['observaciones'] = _muelleObservacionesController.text.trim();
      }

      // ── Campos Balanza (prefijo balanza_) ──
      if (_hasBalanzaData) {
        if (_editBalanzaId != null) fields['balanza_id'] = _editBalanzaId.toString();
        if (_guiaController.text.trim().isNotEmpty) fields['balanza_guia'] = _guiaController.text.trim();
        if (_selectedDistribucionAlmacenId != null) fields['balanza_distribucion_almacen'] = _selectedDistribucionAlmacenId.toString();
        if (_selectedPrecintoId != null) fields['balanza_precinto'] = _selectedPrecintoId.toString();
        if (_selectedPermisoId != null) fields['balanza_permiso'] = _selectedPermisoId.toString();
        fields['balanza_fecha_entrada'] = _fechaEntradaBalanza.toIso8601String();
        fields['balanza_fecha_salida'] = _fechaSalidaBalanza.toIso8601String();
        if (_balanzaEntradaStrController.text.trim().isNotEmpty) fields['balanza_entrada'] = _balanzaEntradaStrController.text.trim();
        if (_balanzaSalidaStrController.text.trim().isNotEmpty) fields['balanza_salida'] = _balanzaSalidaStrController.text.trim();
        if (_balanzaPesoBrutoController.text.trim().isNotEmpty) fields['balanza_peso_bruto'] = _balanzaPesoBrutoController.text.trim();
        if (_balanzaPesoTaraController.text.trim().isNotEmpty) fields['balanza_peso_tara'] = _balanzaPesoTaraController.text.trim();
        if (_balanzaPesoNetoController.text.trim().isNotEmpty) fields['balanza_peso_neto'] = _balanzaPesoNetoController.text.trim();
        if (_balanzaBagsController.text.trim().isNotEmpty) fields['balanza_bags'] = _balanzaBagsController.text.trim();
        fields['balanza_fecha_envio_wp'] = _fechaEnvioWp.toIso8601String();
        if (_balanzaObservacionesController.text.trim().isNotEmpty) fields['balanza_observaciones'] = _balanzaObservacionesController.text.trim();
      }

      // ── Campos Almacen (prefijo almacen_) ──
      if (_hasAlmacenData) {
        if (_editAlmacenId != null) fields['almacen_id'] = _editAlmacenId.toString();
        fields['almacen_fecha_entrada'] = _fechaEntradaAlmacen.toIso8601String();
        fields['almacen_fecha_salida'] = _fechaSalidaAlmacen.toIso8601String();
        if (_almacenPesoBrutoController.text.trim().isNotEmpty) fields['almacen_peso_bruto'] = _almacenPesoBrutoController.text.trim();
        if (_almacenPesoTaraController.text.trim().isNotEmpty) fields['almacen_peso_tara'] = _almacenPesoTaraController.text.trim();
        if (_almacenPesoNetoController.text.trim().isNotEmpty) fields['almacen_peso_neto'] = _almacenPesoNetoController.text.trim();
        if (_almacenBagsController.text.trim().isNotEmpty) fields['almacen_bags'] = _almacenBagsController.text.trim();
        if (_almacenObservacionesController.text.trim().isNotEmpty) fields['almacen_observaciones'] = _almacenObservacionesController.text.trim();
      }

      final formData = FormData.fromMap(fields);

      // ── Fotos ──
      if (_muelleFotoPath != null) {
        formData.files.add(MapEntry('foto', await MultipartFile.fromFile(_muelleFotoPath!, filename: 'muelle_${DateTime.now().millisecondsSinceEpoch}.jpg')));
      }
      if (_hasBalanzaData) {
        if (_balanzaFoto1Path != null) {
          formData.files.add(MapEntry('balanza_foto1', await MultipartFile.fromFile(_balanzaFoto1Path!, filename: 'balanza1_${DateTime.now().millisecondsSinceEpoch}.jpg')));
        }
        if (_balanzaFoto2Path != null) {
          formData.files.add(MapEntry('balanza_foto2', await MultipartFile.fromFile(_balanzaFoto2Path!, filename: 'balanza2_${DateTime.now().millisecondsSinceEpoch}.jpg')));
        }
      }
      if (_hasAlmacenData) {
        if (_almacenFoto1Path != null) {
          formData.files.add(MapEntry('almacen_foto1', await MultipartFile.fromFile(_almacenFoto1Path!, filename: 'almacen1_${DateTime.now().millisecondsSinceEpoch}.jpg')));
        }
        if (_almacenFoto2Path != null) {
          formData.files.add(MapEntry('almacen_foto2', await MultipartFile.fromFile(_almacenFoto2Path!, filename: 'almacen2_${DateTime.now().millisecondsSinceEpoch}.jpg')));
        }
      }

      // ── Enviar ──
      const endpoint = '/api/v1/graneles/tickets-muelle/';
      if (widget.isEditMode && _editTicketId != null) {
        await _http.dio.patch('$endpoint$_editTicketId/', data: formData);
      } else {
        await _http.dio.post(endpoint, data: formData);
      }

      // Refrescar providers
      ref.invalidate(ticketsMuelleProvider);

      if (mounted) {
        AppSnackBar.success(context, widget.isEditMode ? 'Viaje actualizado correctamente' : 'Viaje creado correctamente');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = _parseBackendError(e);
        AppSnackBar.error(context, errorMessage, duration: const Duration(seconds: 5));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // =========================================================================
  // ERROR PARSING
  // =========================================================================

  String _parseBackendError(dynamic error) {
    String errorStr = error.toString();

    if (error is DioException) {
      final response = error.response;
      if (response != null && response.data != null) {
        final data = response.data;
        if (data is Map) {
          final errorMessages = <String>[];
          data.forEach((key, value) {
            if (value is Map) {
              // Nested errors (muelle: {field: [error]}, balanza: {field: [error]})
              value.forEach((subKey, subValue) {
                if (subValue is List && subValue.isNotEmpty) {
                  errorMessages.add('${_translateFieldName(subKey.toString())}: ${subValue.first}');
                } else if (subValue is String) {
                  errorMessages.add('${_translateFieldName(subKey.toString())}: $subValue');
                }
              });
            } else if (value is List && value.isNotEmpty) {
              errorMessages.add('${_translateFieldName(key.toString())}: ${value.first}');
            } else if (value is String) {
              errorMessages.add('${_translateFieldName(key.toString())}: $value');
            }
          });
          if (errorMessages.isNotEmpty) return errorMessages.join('\n');
        } else if (data is String) {
          errorStr = data;
        }
      }
    }

    return errorStr
        .replaceAll('Exception: ', '')
        .replaceAll('DioException [bad response]: ', '')
        .replaceAll('DioException: ', '');
  }

  String _translateFieldName(String field) {
    const fieldNames = {
      'numero_ticket': 'N\u00B0 Ticket',
      'fin_descarga': 'Fin de cargio',
      'inicio_descarga': 'Inicio de cargio',
      'bl': 'BL',
      'distribucion': 'Bodega',
      'placa': 'Placa',
      'transporte': 'Transporte',
      'observaciones': 'Observaciones',
      'foto': 'Foto',
      'guia': 'Guia',
      'peso_bruto': 'Peso Bruto',
      'peso_tara': 'Peso Tara',
      'peso_neto': 'Peso Neto',
      'distribucion_almacen': 'Almacen Destino',
      'precinto': 'Precinto',
      'permiso': 'Permiso',
      'fecha_entrada_balanza': 'Entrada Balanza',
      'fecha_salida_balanza': 'Salida Balanza',
      'fecha_entrada_almacen': 'Entrada Almacen',
      'fecha_salida_almacen': 'Salida Almacen',
      'non_field_errors': 'Error',
      'detail': 'Error',
    };
    return fieldNames[field] ?? field;
  }
}
