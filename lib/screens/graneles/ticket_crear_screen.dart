// =============================================================================
// PANTALLA DE CREAR/EDITAR TICKET MUELLE
// =============================================================================
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/services/graneles/graneles_service.dart';
import 'package:stampcamera/widgets/common/reusable_camera_card.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class TicketCrearScreen extends ConsumerStatefulWidget {
  final int? servicioId;
  final int? ticketId;
  final bool isEditMode;

  /// Constructor para crear nuevo ticket
  /// - [servicioId] es opcional - si no se proporciona, se mostrarán BLs de todas las naves en operación
  const TicketCrearScreen({super.key, this.servicioId})
      : ticketId = null,
        isEditMode = false;

  /// Constructor para editar ticket existente
  const TicketCrearScreen.edit({super.key, required this.ticketId})
      : servicioId = null,
        isEditMode = true;

  @override
  ConsumerState<TicketCrearScreen> createState() => _TicketCrearScreenState();
}

class _TicketCrearScreenState extends ConsumerState<TicketCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroTicketController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Service for search endpoints
  final TicketMuelleService _ticketService = TicketMuelleService();

  // Search field controllers
  final _placaSearchController = TextEditingController();
  final _transporteSearchController = TextEditingController();

  // Debounce timers for search
  Timer? _placaDebounce;
  Timer? _transporteDebounce;

  // Search results
  List<OptionItem> _placaResults = [];
  List<OptionItem> _transporteResults = [];

  // Loading states for search
  bool _isSearchingPlaca = false;
  bool _isSearchingTransporte = false;

  int? _selectedBlId;
  int? _selectedDistribucionId;
  int? _selectedPlacaId;
  int? _selectedTransporteId;
  DateTime _inicioDescarga = DateTime.now();
  DateTime _finDescarga = DateTime.now();
  String? _fotoPath;  // Path de foto local (nueva)
  String? _existingFotoUrl;  // URL de foto existente (edición)
  bool _isSubmitting = false;
  bool _isLoadingTicket = false;
  int? _effectiveServicioId;

  @override
  void initState() {
    super.initState();
    _effectiveServicioId = widget.servicioId;
    if (widget.isEditMode && widget.ticketId != null) {
      _loadTicketData();
    }
  }

  Future<void> _loadTicketData() async {
    setState(() => _isLoadingTicket = true);
    try {
      final ticket = await ref.read(ticketMuelleDetalleProvider(widget.ticketId!).future);
      if (mounted) {
        setState(() {
          _numeroTicketController.text = ticket.numeroTicket;
          _observacionesController.text = ticket.observaciones ?? '';
          _inicioDescarga = ticket.inicioDescarga ?? DateTime.now();
          _finDescarga = ticket.finDescarga ?? DateTime.now();
          _existingFotoUrl = ticket.fotoUrl;
          _effectiveServicioId = ticket.servicioId;

          // Load IDs for dropdowns and search fields
          _selectedBlId = ticket.blId;
          _selectedDistribucionId = ticket.distribucionId;
          _selectedPlacaId = ticket.placaId;
          _selectedTransporteId = ticket.transporteId;

          // Load labels for search fields
          if (ticket.placaStr != null) {
            _placaSearchController.text = ticket.placaStr!;
          }
          if (ticket.transporteNombre != null) {
            _transporteSearchController.text = ticket.transporteNombre!;
          }

          _isLoadingTicket = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTicket = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _numeroTicketController.dispose();
    _observacionesController.dispose();
    _placaSearchController.dispose();
    _transporteSearchController.dispose();
    _placaDebounce?.cancel();
    _transporteDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTicket) {
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

    // Obtener embarqueId de la asistencia activa para filtrar BLs
    final asistenciaAsync = ref.watch(asistenciaActivaProvider);
    final embarqueId = asistenciaAsync.valueOrNull?.asistencia?.nave?.id;

    // Usar el provider flexible que funciona con o sin servicioId
    final optionsParams = TicketFormOptionsParams(
      servicioId: _effectiveServicioId,
      ticketId: widget.isEditMode ? widget.ticketId : null,
      embarqueId: embarqueId,  // Filtrar BLs por la nave de la asistencia
    );
    final optionsAsync = ref.watch(ticketMuelleOptionsFlexProvider(optionsParams));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.isEditMode ? 'Editar Ticket' : 'Nuevo Ticket Muelle',
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
          onRetry: () => ref.invalidate(ticketMuelleOptionsFlexProvider(optionsParams)),
        ),
        data: (options) => _buildForm(options),
      ),
    );
  }

  Widget _buildForm(TicketMuelleOptions options) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Número de ticket
            _buildSectionTitle('Datos del Ticket', Icons.receipt),
            SizedBox(height: DesignTokens.spaceS),
            TextFormField(
              controller: _numeroTicketController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de Ticket *',
                hintText: 'Ingrese el número de ticket',
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El número de ticket es requerido';
                }
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return 'Solo se permiten números';
                }
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
              items: options.bls.map((e) => DropdownMenuItem(
                value: e.id,
                child: Text(e.label),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBlId = value;
                  // Limpiar bodega si cambia el BL
                  _selectedDistribucionId = null;
                });
              },
              validator: (value) => value == null ? 'Seleccione un BL' : null,
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Distribución (Bodega) - filtrada por el producto del BL seleccionado
            Builder(builder: (context) {
              // Obtener el productoId del BL seleccionado
              final selectedBl = _selectedBlId != null
                  ? options.bls.where((bl) => bl.id == _selectedBlId).firstOrNull
                  : null;
              final productoId = selectedBl?.productoId;

              // Filtrar distribuciones por producto del BL
              final filteredDistribuciones = productoId != null
                  ? options.distribuciones.where((d) => d.productoId == productoId).toList()
                  : options.distribuciones;

              return _buildDropdown<int>(
                label: 'Bodega *',
                hint: _selectedBlId == null
                    ? 'Primero seleccione un BL'
                    : 'Seleccionar bodega',
                icon: Icons.warehouse,
                initialValue: _selectedDistribucionId,
                items: filteredDistribuciones.map((e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.label),
                )).toList(),
                onChanged: _selectedBlId == null
                    ? null  // Deshabilitar si no hay BL seleccionado
                    : (value) => setState(() => _selectedDistribucionId = value),
                validator: (value) => value == null ? 'Seleccione una bodega' : null,
              );
            }),
            SizedBox(height: DesignTokens.spaceL),

            // Vehículo y Transporte
            _buildSectionTitle('Vehículo y Transporte', Icons.local_shipping),
            SizedBox(height: DesignTokens.spaceS),
            _buildAsyncSearchField(
              label: 'Placa',
              hint: 'Buscar placa (mín. 2 caracteres)',
              icon: Icons.directions_car,
              controller: _placaSearchController,
              results: _placaResults,
              isSearching: _isSearchingPlaca,
              selectedId: _selectedPlacaId,
              onSearchChanged: _onPlacaSearchChanged,
              onSelected: (item) => setState(() => _selectedPlacaId = item.id),
              onClear: () => setState(() => _selectedPlacaId = null),
            ),
            SizedBox(height: DesignTokens.spaceM),
            _buildAsyncSearchField(
              label: 'Empresa de Transporte',
              hint: 'Buscar por RUC o nombre (mín. 2 caracteres)',
              icon: Icons.business,
              controller: _transporteSearchController,
              results: _transporteResults,
              isSearching: _isSearchingTransporte,
              selectedId: _selectedTransporteId,
              onSearchChanged: _onTransporteSearchChanged,
              onSelected: (item) => setState(() => _selectedTransporteId = item.id),
              onClear: () => setState(() => _selectedTransporteId = null),
            ),
            SizedBox(height: DesignTokens.spaceL),

            // Tiempos
            _buildSectionTitle('Tiempos de Descarga', Icons.access_time),
            SizedBox(height: DesignTokens.spaceS),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'Inicio *',
                    value: _inicioDescarga,
                    onChanged: (value) => setState(() => _inicioDescarga = value),
                  ),
                ),
                SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: _buildDateTimePicker(
                    label: 'Fin *',
                    value: _finDescarga,
                    onChanged: (value) => setState(() => _finDescarga = value),
                    hasError: _inicioDescarga.isAfter(_finDescarga) || _inicioDescarga.isAtSameMomentAs(_finDescarga),
                  ),
                ),
              ],
            ),
            // Mostrar error de tiempo si inicio >= fin
            if (_inicioDescarga.isAfter(_finDescarga) || _inicioDescarga.isAtSameMomentAs(_finDescarga))
              Padding(
                padding: EdgeInsets.only(top: DesignTokens.spaceXS),
                child: Text(
                  'El fin de cargío debe ser mayor que el inicio',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: DesignTokens.fontSizeXS,
                  ),
                ),
              ),
            SizedBox(height: DesignTokens.spaceL),

            // Observaciones
            _buildSectionTitle('Observaciones', Icons.notes),
            SizedBox(height: DesignTokens.spaceS),
            TextFormField(
              controller: _observacionesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ingrese observaciones (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            SizedBox(height: DesignTokens.spaceL),

            // Foto
            ReusableCameraCard(
              title: 'Foto del Ticket',
              subtitle: 'Captura la evidencia del ticket de muelle',
              currentImagePath: _fotoPath,
              currentImageUrl: _existingFotoUrl,
              onImageSelected: (path) => setState(() {
                _fotoPath = path;
                _existingFotoUrl = null; // Clear existing URL when new photo taken
              }),
              showGalleryOption: true,
              cameraResolution: CameraResolution.high,
              primaryColor: AppColors.primary,
            ),
            SizedBox(height: DesignTokens.spaceXL),

            // Botón de envío
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
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
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSubmitting
                      ? 'Guardando...'
                      : (widget.isEditMode ? 'Actualizar Ticket' : 'Guardar Ticket'),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // SafeArea inferior + espacio adicional
            SizedBox(height: DesignTokens.spaceXL + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
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
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? initialValue,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,  // Nullable para poder deshabilitar
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
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

  // ===========================================================================
  // ASYNC SEARCH FIELD METHODS
  // ===========================================================================

  void _onPlacaSearchChanged(String query) {
    _placaDebounce?.cancel();
    _placaDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 2) {
        setState(() {
          _placaResults = [];
          _isSearchingPlaca = false;
        });
        return;
      }
      setState(() => _isSearchingPlaca = true);
      try {
        final results = await _ticketService.searchPlacas(query);
        if (mounted) {
          setState(() {
            _placaResults = results;
            _isSearchingPlaca = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearchingPlaca = false);
      }
    });
  }

  void _onTransporteSearchChanged(String query) {
    _transporteDebounce?.cancel();
    _transporteDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length < 2) {
        setState(() {
          _transporteResults = [];
          _isSearchingTransporte = false;
        });
        return;
      }
      setState(() => _isSearchingTransporte = true);
      try {
        final results = await _ticketService.searchTransportes(query);
        if (mounted) {
          setState(() {
            _transporteResults = results;
            _isSearchingTransporte = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearchingTransporte = false);
      }
    });
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
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onClear();
                    },
                  )
                : isSearching
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
            fillColor: selectedId != null
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.surface,
          ),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: AppColors.textPrimary,
          ),
          readOnly: selectedId != null,
        ),
        if (results.isNotEmpty && selectedId == null)
          Container(
            margin: EdgeInsets.only(top: DesignTokens.spaceXS),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(color: AppColors.neutral),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    item.label,
                    style: TextStyle(fontSize: DesignTokens.fontSizeS),
                  ),
                  onTap: () {
                    controller.text = item.label;
                    onSelected(item);
                    setState(() {
                      // Clear results after selection
                      _placaResults = [];
                      _transporteResults = [];
                    });
                  },
                );
              },
            ),
          ),
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
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
            initialEntryMode: TimePickerEntryMode.input, // Modo texto, sin dial
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              );
            },
          );
          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        decoration: BoxDecoration(
          color: hasError ? AppColors.error.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: hasError ? AppColors.error : AppColors.neutral,
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                color: hasError ? AppColors.error : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: DesignTokens.spaceXS),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: hasError ? AppColors.error : AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Text(
                  '${value.day}/${value.month}/${value.year}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: hasError ? AppColors.error : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceXS),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: hasError ? AppColors.error : AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Text(
                  '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: hasError ? AppColors.error : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar tiempo antes de enviar
    if (_inicioDescarga.isAfter(_finDescarga) || _inicioDescarga.isAtSameMomentAs(_finDescarga)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El fin de cargío debe ser mayor que el inicio'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // En modo edición, solo validamos campos opcionales si fueron modificados
    // En modo creación, BL y Distribución son requeridos
    if (!widget.isEditMode && (_selectedBlId == null || _selectedDistribucionId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete los campos requeridos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final File? fotoFile = _fotoPath != null ? File(_fotoPath!) : null;

      if (widget.isEditMode && widget.ticketId != null) {
        // Modo edición - actualizar ticket existente
        await ref.read(ticketsMuelleProvider.notifier).updateTicket(
          ticketId: widget.ticketId!,
          numeroTicket: _numeroTicketController.text,
          blId: _selectedBlId,
          distribucionId: _selectedDistribucionId,
          placaId: _selectedPlacaId,
          transporteId: _selectedTransporteId,
          inicioDescarga: _inicioDescarga,
          finDescarga: _finDescarga,
          observaciones: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
          foto: fotoFile,
        );
      } else {
        // Modo creación - crear nuevo ticket
        await ref.read(ticketsMuelleProvider.notifier).createTicket(
          numeroTicket: _numeroTicketController.text,
          blId: _selectedBlId!,
          distribucionId: _selectedDistribucionId!,
          placaId: _selectedPlacaId,
          transporteId: _selectedTransporteId,
          inicioDescarga: _inicioDescarga,
          finDescarga: _finDescarga,
          observaciones: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
          foto: fotoFile,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode
                ? 'Ticket actualizado correctamente'
                : 'Ticket creado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        // Parsear errores de validación del backend
        final errorMessage = _parseBackendError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Parsea errores del backend para mostrar mensajes amigables
  String _parseBackendError(dynamic error) {
    String errorStr = error.toString();

    // Si es DioException, extraer el response data
    if (error.runtimeType.toString().contains('DioException')) {
      try {
        final response = error.response;
        if (response != null && response.data != null) {
          final data = response.data;
          if (data is Map) {
            // Buscar campos de error comunes
            final errorMessages = <String>[];

            data.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                final fieldName = _translateFieldName(key.toString());
                errorMessages.add('$fieldName: ${value.first}');
              } else if (value is String) {
                final fieldName = _translateFieldName(key.toString());
                errorMessages.add('$fieldName: $value');
              }
            });

            if (errorMessages.isNotEmpty) {
              return errorMessages.join('\n');
            }
          } else if (data is String) {
            errorStr = data;
          }
        }
      } catch (_) {
        // Si falla, continuar con el string del error
      }
    }

    // Errores comunes de validación del backend (fallback con string)
    if (errorStr.contains('numero_ticket') && errorStr.contains('Ya existe')) {
      return 'Ya existe un ticket con este número para el servicio actual';
    }
    if (errorStr.contains('fin_descarga') && errorStr.contains('mayor')) {
      return 'El fin de cargío debe ser mayor que el inicio';
    }
    if (errorStr.contains('unique') || errorStr.contains('already exists')) {
      return 'Ya existe un registro con estos datos';
    }

    // Intentar extraer mensaje de campo específico del JSON de error
    final fieldPattern = RegExp(r'[\x27"](\w+)[\x27"]\s*:\s*\[?\s*[\x27"]([^\x27"\]]+)');
    final match = fieldPattern.firstMatch(errorStr);
    if (match != null) {
      final field = match.group(1);
      final message = match.group(2);
      if (field != null && message != null) {
        final displayField = _translateFieldName(field);
        return '$displayField: $message';
      }
    }

    // Limpiar prefijos comunes
    return errorStr
        .replaceAll('Exception: ', '')
        .replaceAll('DioException [bad response]: ', '')
        .replaceAll('DioException: ', '');
  }

  /// Traduce nombres de campos del backend a español
  String _translateFieldName(String field) {
    const fieldNames = {
      'numero_ticket': 'Número de ticket',
      'fin_descarga': 'Fin de cargío',
      'inicio_descarga': 'Inicio de cargío',
      'bl': 'BL',
      'distribucion': 'Bodega',
      'placa': 'Placa',
      'transporte': 'Transporte',
      'observaciones': 'Observaciones',
      'foto': 'Foto',
      'non_field_errors': 'Error',
      'detail': 'Error',
    };
    return fieldNames[field] ?? field;
  }
}
