// =============================================================================
// PANTALLA DE CREAR/EDITAR BALANZA
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

class BalanzaCrearScreen extends ConsumerStatefulWidget {
  final int? balanzaId;
  final bool isEditMode;

  const BalanzaCrearScreen({super.key})
      : balanzaId = null,
        isEditMode = false;

  const BalanzaCrearScreen.edit({super.key, required this.balanzaId})
      : isEditMode = true;

  @override
  ConsumerState<BalanzaCrearScreen> createState() => _BalanzaCrearScreenState();
}

class _BalanzaCrearScreenState extends ConsumerState<BalanzaCrearScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guiaController = TextEditingController();
  final _pesoBrutoController = TextEditingController();
  final _pesoTaraController = TextEditingController();
  final _pesoNetoController = TextEditingController();
  final _bagsController = TextEditingController();
  final _balanzaEntradaController = TextEditingController();
  final _balanzaSalidaController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _ticketSearchController = TextEditingController();

  // Ticket seleccionado
  TicketMuelle? _selectedTicket;
  List<TicketMuelle> _ticketResults = [];
  bool _isSearchingTickets = false;
  Timer? _searchDebounce;

  // Opciones cargadas desde el servicio del ticket seleccionado
  BalanzaOptions? _loadedOptions;
  bool _isLoadingOptions = false;

  // Precinto (búsqueda)
  final _precintoSearchController = TextEditingController();
  List<OptionItem> _precintoResults = [];
  bool _isSearchingPrecintos = false;
  Timer? _precintoSearchDebounce;
  OptionItem? _selectedPrecinto;

  int? _selectedDistribucionAlmacenId;
  int? _selectedPrecintoId;
  int? _selectedPermisoId;
  DateTime _fechaEntradaBalanza = DateTime.now();
  DateTime _fechaSalidaBalanza = DateTime.now();
  String? _foto1Path;
  String? _foto2Path;
  String? _existingFoto1Url;
  String? _existingFoto2Url;
  bool _isSubmitting = false;
  bool _isLoadingBalanza = false;
  final DateTime _fechaEnvioWp = DateTime.now();

  bool _autoCalculatePesoNeto = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.balanzaId != null) {
      _loadBalanzaData();
    }
    _pesoBrutoController.addListener(_calculatePesoNeto);
    _pesoTaraController.addListener(_calculatePesoNeto);
  }

  void _calculatePesoNeto() {
    if (!_autoCalculatePesoNeto) return;
    final bruto = double.tryParse(_pesoBrutoController.text) ?? 0;
    final tara = double.tryParse(_pesoTaraController.text) ?? 0;
    final neto = bruto - tara;
    if (neto >= 0) {
      _pesoNetoController.text = neto.toStringAsFixed(3);
    }
  }

  Future<void> _loadBalanzaData() async {
    setState(() => _isLoadingBalanza = true);
    try {
      final balanza = await ref.read(balanzaDetalleProvider(widget.balanzaId!).future);
      if (mounted) {
        setState(() {
          _autoCalculatePesoNeto = false;
          _guiaController.text = balanza.guia;
          _pesoBrutoController.text = balanza.pesoBruto.toStringAsFixed(3);
          _pesoTaraController.text = balanza.pesoTara.toStringAsFixed(3);
          _pesoNetoController.text = balanza.pesoNeto.toStringAsFixed(3);
          _bagsController.text = balanza.bags?.toString() ?? '';
          _balanzaEntradaController.text = balanza.balanzaEntrada ?? '';
          _balanzaSalidaController.text = balanza.balanzaSalida ?? '';
          _observacionesController.text = balanza.observaciones ?? '';
          _fechaEntradaBalanza = balanza.fechaEntradaBalanza ?? DateTime.now();
          _fechaSalidaBalanza = balanza.fechaSalidaBalanza ?? DateTime.now();
          _existingFoto1Url = balanza.foto1Url;
          _existingFoto2Url = balanza.foto2Url;
          // Setear IDs para edición
          _selectedDistribucionAlmacenId = balanza.distribucionAlmacenId;
          _selectedPrecintoId = balanza.precintoId;
          _selectedPermisoId = balanza.permisoId;
          // Mostrar precinto actual si existe
          if (balanza.precintoId != null && balanza.precintoStr != null) {
            _selectedPrecinto = OptionItem(
              id: balanza.precintoId!,
              label: balanza.precintoStr!,
            );
          }
          _isLoadingBalanza = false;
        });
        // Cargar opciones del servicio de la balanza
        if (balanza.servicioId != null) {
          _loadOptionsForServicio(balanza.servicioId!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalanza = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar balanza: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Buscar tickets sin balanza
  void _searchTickets(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _ticketResults = [];
        _isSearchingTickets = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isSearchingTickets = true);
      try {
        final service = ref.read(ticketMuelleServiceProvider);
        final response = await service.getTicketsSinBalanza(search: query);
        if (mounted) {
          setState(() {
            _ticketResults = response.results;
            _isSearchingTickets = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearchingTickets = false);
        }
      }
    });
  }

  /// Seleccionar un ticket y cargar sus opciones
  void _selectTicket(TicketMuelle ticket) {
    setState(() {
      _selectedTicket = ticket;
      _ticketResults = [];
      _ticketSearchController.clear();
    });
    // Cargar opciones del servicio del ticket
    if (ticket.servicioId != null) {
      _loadOptionsForServicio(ticket.servicioId!);
    }
  }

  /// Cargar opciones (distribuciones, precintos, permisos) del servicio
  Future<void> _loadOptionsForServicio(int servicioId) async {
    setState(() => _isLoadingOptions = true);
    try {
      final service = ref.read(balanzaServiceProvider);
      final options = await service.getFormOptions(servicioId);
      if (mounted) {
        setState(() {
          _loadedOptions = options;
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar opciones: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Buscar precintos disponibles
  void _searchPrecintos(String query) {
    _precintoSearchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _precintoResults = [];
        _isSearchingPrecintos = false;
      });
      return;
    }
    _precintoSearchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearchingPrecintos = true);
      try {
        final service = ref.read(balanzaServiceProvider);
        final results = await service.buscarPrecintos(search: query);
        if (mounted) {
          setState(() {
            _precintoResults = results;
            _isSearchingPrecintos = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearchingPrecintos = false);
        }
      }
    });
  }

  void _selectPrecinto(OptionItem precinto) {
    setState(() {
      _selectedPrecinto = precinto;
      _selectedPrecintoId = precinto.id;
      _precintoResults = [];
      _precintoSearchController.clear();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _precintoSearchDebounce?.cancel();
    _guiaController.dispose();
    _pesoBrutoController.dispose();
    _pesoTaraController.dispose();
    _pesoNetoController.dispose();
    _bagsController.dispose();
    _balanzaEntradaController.dispose();
    _balanzaSalidaController.dispose();
    _observacionesController.dispose();
    _ticketSearchController.dispose();
    _precintoSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBalanza) {
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
          widget.isEditMode ? 'Editar Balanza' : 'Nueva Balanza',
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
          // Sección: Ticket (solo en creación)
          if (!widget.isEditMode) ...[
            _buildSectionHeader('Ticket de Muelle', Icons.receipt),
            _buildTicketSearch(),
            SizedBox(height: DesignTokens.spaceL),
          ],

          // Sección: Guía
          _buildSectionHeader('Información de Guía', Icons.description),
          _buildGuiaField(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Distribución, Precinto y Permiso
          _buildSectionHeader('Distribución y Seguridad', Icons.warehouse),
          _buildDistribucionAlmacenSelector(),
          SizedBox(height: DesignTokens.spaceM),
          _buildPrecintoPermisoFields(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Entrada (fecha + balanza)
          _buildSectionHeader('Entrada', Icons.login),
          _buildEntradaFields(),
          SizedBox(height: DesignTokens.spaceL),

          // Sección: Salida (fecha + balanza)
          _buildSectionHeader('Salida', Icons.logout),
          _buildSalidaFields(),
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
          SizedBox(height: DesignTokens.spaceL),
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

  /// Búsqueda de tickets sin balanza
  Widget _buildTicketSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ticket seleccionado
        if (_selectedTicket != null) ...[
          Card(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              side: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.receipt, color: Colors.white, size: 18),
              ),
              title: Text(
                'Ticket: ${_selectedTicket!.numeroTicket}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_selectedTicket!.placaStr ?? "Sin placa"} • ${_selectedTicket!.servicioCodigo ?? ""}',
                style: TextStyle(fontSize: DesignTokens.fontSizeS),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () {
                  setState(() {
                    _selectedTicket = null;
                    _loadedOptions = null;
                    _selectedDistribucionAlmacenId = null;
                    _selectedPrecintoId = null;
                    _selectedPermisoId = null;
                  });
                },
              ),
            ),
          ),
        ] else ...[
          // Campo de búsqueda
          TextFormField(
            controller: _ticketSearchController,
            decoration: InputDecoration(
              labelText: 'Buscar Ticket sin Balanza *',
              hintText: 'Buscar por número de ticket o placa...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearchingTickets
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
            onChanged: _searchTickets,
            validator: (_) {
              if (_selectedTicket == null) {
                return 'Debes seleccionar un ticket';
              }
              return null;
            },
          ),
          // Resultados de búsqueda
          if (_ticketResults.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spaceS),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neutral),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _ticketResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ticket = _ticketResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.receipt, size: 20, color: AppColors.primary),
                    title: Text(
                      'Ticket: ${ticket.numeroTicket}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${ticket.placaStr ?? "Sin placa"} • ${ticket.servicioCodigo ?? ""}',
                      style: TextStyle(fontSize: DesignTokens.fontSizeXS),
                    ),
                    onTap: () => _selectTicket(ticket),
                  );
                },
              ),
            ),
          ],
          // Mensaje cuando no hay resultados
          if (_ticketSearchController.text.isNotEmpty &&
              _ticketResults.isEmpty &&
              !_isSearchingTickets) ...[
            SizedBox(height: DesignTokens.spaceS),
            Text(
              'No se encontraron tickets sin balanza',
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

  Widget _buildGuiaField() {
    return TextFormField(
      controller: _guiaController,
      decoration: InputDecoration(
        labelText: 'Número de Guía *',
        hintText: 'Ej: 001234',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La guía es requerida';
        }
        return null;
      },
    );
  }

  Widget _buildDistribucionAlmacenSelector() {
    if (_isLoadingOptions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final distribuciones = _loadedOptions?.distribucionesAlmacen ?? [];

    if (distribuciones.isEmpty && !widget.isEditMode && _selectedTicket == null) {
      return Text(
        'Selecciona un ticket primero para cargar los almacenes disponibles',
        style: TextStyle(
          fontSize: DesignTokens.fontSizeS,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedDistribucionAlmacenId,
      decoration: InputDecoration(
        labelText: 'Almacén de Destino *',
        hintText: 'Seleccionar almacén...',
        prefixIcon: Icon(Icons.warehouse, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: BorderSide(color: AppColors.neutral),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: BorderSide(color: AppColors.neutral),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceM,
          vertical: DesignTokens.spaceM,
        ),
      ),
      style: TextStyle(
        fontSize: DesignTokens.fontSizeS,
        color: AppColors.textPrimary,
      ),
      icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
      isExpanded: true,
      dropdownColor: Colors.white,
      menuMaxHeight: 250,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      items: distribuciones.map((dist) {
        return DropdownMenuItem<int>(
          value: dist.id,
          child: Row(
            children: [
              Icon(Icons.inventory_2, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
              SizedBox(width: DesignTokens.spaceS),
              Expanded(
                child: Text(
                  dist.label,
                  style: TextStyle(fontSize: DesignTokens.fontSizeS),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedDistribucionAlmacenId = value);
      },
      validator: (value) => value == null ? 'Selecciona un almacén' : null,
    );
  }

  Widget _buildEntradaFields() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () => _selectDateTime(isEntrada: true),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha Entrada *',
                prefixIcon: const Icon(Icons.access_time, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceS,
                ),
              ),
              child: Text(
                dateFormat.format(_fechaEntradaBalanza),
                style: TextStyle(fontSize: DesignTokens.fontSizeS),
              ),
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _balanzaEntradaController,
            decoration: InputDecoration(
              labelText: 'Balanza',
              hintText: 'B1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceS,
                vertical: DesignTokens.spaceM,
              ),
            ),
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalidaFields() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () => _selectDateTime(isEntrada: false),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha Salida *',
                prefixIcon: const Icon(Icons.access_time, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceS,
                ),
              ),
              child: Text(
                dateFormat.format(_fechaSalidaBalanza),
                style: TextStyle(fontSize: DesignTokens.fontSizeS),
              ),
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: _balanzaSalidaController,
            decoration: InputDecoration(
              labelText: 'Balanza',
              hintText: 'B2',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceS,
                vertical: DesignTokens.spaceM,
              ),
            ),
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeM,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime({required bool isEntrada}) async {
    final initialDate = isEntrada ? _fechaEntradaBalanza : _fechaSalidaBalanza;

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
            _fechaEntradaBalanza = dateTime;
          } else {
            _fechaSalidaBalanza = dateTime;
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
                  ),
                  filled: true,
                  fillColor: _autoCalculatePesoNeto
                      ? AppColors.surface.withValues(alpha: 0.5)
                      : AppColors.surface,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                ],
                readOnly: _autoCalculatePesoNeto,
                onTap: () {
                  if (_autoCalculatePesoNeto) {
                    setState(() => _autoCalculatePesoNeto = false);
                  }
                },
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
      ],
    );
  }

  Widget _buildPrecintoPermisoFields() {
    final permisos = _loadedOptions?.permisos ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Precinto: búsqueda
        _buildPrecintoSearch(),
        SizedBox(height: DesignTokens.spaceM),
        // Permiso: dropdown (solo si hay permisos cargados)
        if (_isLoadingOptions)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          )
        else if (permisos.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: _selectedPermisoId,
            decoration: InputDecoration(
              labelText: 'Permiso',
              hintText: 'Seleccionar permiso (opcional)...',
              prefixIcon: Icon(Icons.badge, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(color: AppColors.neutral),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(color: AppColors.neutral),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
                vertical: DesignTokens.spaceM,
              ),
            ),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textPrimary,
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            isExpanded: true,
            dropdownColor: Colors.white,
            menuMaxHeight: 250,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            items: [
              DropdownMenuItem<int>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: DesignTokens.spaceS),
                    Text(
                      'Sin permiso',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              ...permisos.map((p) {
                return DropdownMenuItem<int>(
                  value: p.id,
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                      SizedBox(width: DesignTokens.spaceS),
                      Expanded(
                        child: Text(
                          p.label,
                          style: TextStyle(fontSize: DesignTokens.fontSizeS),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _selectedPermisoId = value);
            },
          ),
      ],
    );
  }

  Widget _buildPrecintoSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedPrecinto != null) ...[
          // Precinto seleccionado
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, size: 18, color: AppColors.primary),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    _selectedPrecinto!.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeS,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _selectedPrecinto = null;
                      _selectedPrecintoId = null;
                    });
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ] else ...[
          // Campo de búsqueda
          TextFormField(
            controller: _precintoSearchController,
            decoration: InputDecoration(
              labelText: 'Precinto (opcional)',
              hintText: 'Buscar precinto disponible...',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: _isSearchingPrecintos
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
            onChanged: _searchPrecintos,
          ),
          // Resultados
          if (_precintoResults.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spaceS),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.neutral),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _precintoResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final precinto = _precintoResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.lock, size: 18, color: AppColors.primary),
                    title: Text(
                      precinto.label,
                      style: TextStyle(fontSize: DesignTokens.fontSizeS),
                    ),
                    onTap: () => _selectPrecinto(precinto),
                  );
                },
              ),
            ),
          ],
          if (_precintoSearchController.text.isNotEmpty &&
              _precintoResults.isEmpty &&
              !_isSearchingPrecintos) ...[
            SizedBox(height: DesignTokens.spaceXS),
            Text(
              'No se encontraron precintos disponibles',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPhotoFields() {
    return Column(
      children: [
        ReusableCameraCard(
          title: 'Foto 1 (Requerida)',
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
          : (widget.isEditMode ? 'Actualizar Balanza' : 'Crear Balanza'),
      icon: _isSubmitting ? null : Icons.save,
      onPressed: _isSubmitting ? null : _submitForm,
      isLoading: _isSubmitting,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaEntradaBalanza.isAfter(_fechaSalidaBalanza)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de entrada debe ser anterior a la de salida'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!widget.isEditMode && _foto1Path == null && _existingFoto1Url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La foto 1 es requerida'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(balanzaServiceProvider);

      if (widget.isEditMode) {
        await service.updateBalanza(
          balanzaId: widget.balanzaId!,
          guia: _guiaController.text.trim(),
          distribucionAlmacenId: _selectedDistribucionAlmacenId,
          precintoId: _selectedPrecintoId,
          permisoId: _selectedPermisoId,
          fechaEntradaBalanza: _fechaEntradaBalanza,
          fechaSalidaBalanza: _fechaSalidaBalanza,
          balanzaEntrada: _balanzaEntradaController.text.trim().isEmpty
              ? null : _balanzaEntradaController.text.trim(),
          balanzaSalida: _balanzaSalidaController.text.trim().isEmpty
              ? null : _balanzaSalidaController.text.trim(),
          pesoBruto: double.parse(_pesoBrutoController.text),
          pesoTara: double.parse(_pesoTaraController.text),
          pesoNeto: double.parse(_pesoNetoController.text),
          bags: _bagsController.text.isEmpty ? null : int.parse(_bagsController.text),
          fechaEnvioWp: _fechaEnvioWp,
          observaciones: _observacionesController.text.trim().isEmpty
              ? null : _observacionesController.text.trim(),
          foto1: _foto1Path != null ? File(_foto1Path!) : null,
          foto2: _foto2Path != null ? File(_foto2Path!) : null,
        );
      } else {
        await service.createBalanza(
          guia: _guiaController.text.trim(),
          ticketId: _selectedTicket!.id,
          distribucionAlmacenId: _selectedDistribucionAlmacenId!,
          precintoId: _selectedPrecintoId,
          permisoId: _selectedPermisoId,
          fechaEntradaBalanza: _fechaEntradaBalanza,
          fechaSalidaBalanza: _fechaSalidaBalanza,
          balanzaEntrada: _balanzaEntradaController.text.trim().isEmpty
              ? null : _balanzaEntradaController.text.trim(),
          balanzaSalida: _balanzaSalidaController.text.trim().isEmpty
              ? null : _balanzaSalidaController.text.trim(),
          pesoBruto: double.parse(_pesoBrutoController.text),
          pesoTara: double.parse(_pesoTaraController.text),
          pesoNeto: double.parse(_pesoNetoController.text),
          bags: _bagsController.text.isEmpty ? null : int.parse(_bagsController.text),
          fechaEnvioWp: _fechaEnvioWp,
          observaciones: _observacionesController.text.trim().isEmpty
              ? null : _observacionesController.text.trim(),
          foto1: _foto1Path != null ? File(_foto1Path!) : null,
          foto2: _foto2Path != null ? File(_foto2Path!) : null,
        );
      }

      // Refrescar lista de balanzas
      ref.invalidate(balanzasListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode
                ? 'Balanza actualizada correctamente'
                : 'Balanza creada correctamente'),
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
