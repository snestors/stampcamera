// ============================================================================
// lib/screens/autos/registro_general/resumen_registros_screen.dart
//
// Lista de registros VIN individuales, ordenada del más reciente al más
// antiguo. Muestra VIN, fecha y hora (con minutos) del registro y quién lo
// registró. Filtros: usuario registrador y condición.
// Se accede desde el botón del AppBar en el módulo Autos (tab REGISTRO).
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/core/helpers/debouncer.dart';
import 'package:stampcamera/models/autos/registro_vin_list_model.dart';
import 'package:stampcamera/providers/autos/registro_vin_list_provider.dart';
import 'package:stampcamera/widgets/vin_scanner_screen.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class ResumenRegistrosScreen extends ConsumerStatefulWidget {
  const ResumenRegistrosScreen({super.key});

  @override
  ConsumerState<ResumenRegistrosScreen> createState() =>
      _ResumenRegistrosScreenState();
}

class _ResumenRegistrosScreenState
    extends ConsumerState<ResumenRegistrosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final Debouncer _debouncer = Debouncer();

  // Filtro por condición del registro
  String? _filtroCondicion;

  // Filtro por usuario registrador
  int? _filtroUsuarioId;
  String? _filtroUsuarioNombre;

  static const _condiciones = <String, String>{
    'PUERTO': 'Puerto',
    'RECEPCION': 'Recepción',
    'ALMACEN': 'Almacén',
    'PDI': 'PDI',
    'PRE-PDI': 'Pre-PDI',
  };

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final notifier = ref.read(registroVinListProvider.notifier);

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!notifier.isLoadingMore &&
            notifier.hasNextPage &&
            !notifier.isSearching) {
          notifier.loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrosAsync = ref.watch(registroVinListProvider);
    final notifier = ref.read(registroVinListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Registros VIN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refresh(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda reutilizable
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por VIN o Serie...',
            onChanged: (value) => _debouncer.run(_applyFilters),
            onSubmitted: (value) {
              _applyFilters();
              _searchFocusNode.unfocus();
            },
            onClear: () {
              _applyFilters();
              _searchFocusNode.unfocus();
            },
            onScannerPressed: _openScanner,
            scannerTooltip: 'Escanear código VIN',
          ),

          // Filtros: usuario registrador + condición
          _buildFilterChips(),

          // Contador de unidades/registros
          _buildCountBar(registrosAsync, notifier),

          // Lista de resultados
          Expanded(child: _buildResultsList(registrosAsync, notifier)),
        ],
      ),
    );
  }

  // ============================================================================
  // FILTROS
  // ============================================================================

  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      filters['search'] = query;
    }
    if (_filtroUsuarioId != null) {
      filters['create_by'] = _filtroUsuarioId;
    }
    if (_filtroCondicion != null) {
      filters['condicion'] = _filtroCondicion;
    }

    return filters;
  }

  void _applyFilters() {
    if (!mounted) return;
    final notifier = ref.read(registroVinListProvider.notifier);
    final filters = _buildFilters();
    if (filters.isEmpty) {
      notifier.clearSearch();
    } else {
      notifier.searchWithFilters(filters);
    }
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Chip de usuario registrador
            _buildUsuarioChip(),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Todos',
              isSelected: _filtroCondicion == null,
              onSelected: () => _onCondicionChanged(null),
            ),
            ..._condiciones.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: DesignTokens.spaceXS),
                child: _buildFilterChip(
                  label: entry.value,
                  isSelected: _filtroCondicion == entry.key,
                  onSelected: () => _onCondicionChanged(entry.key),
                  color: VehicleHelpers.getCondicionColor(entry.key),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuarioChip() {
    final hasUsuario = _filtroUsuarioId != null;
    return GestureDetector(
      onTap: _showUsuarioSelector,
      child: Chip(
        avatar: Icon(
          Icons.person,
          size: 16,
          color: hasUsuario ? Colors.white : AppColors.primary,
        ),
        label: Text(
          hasUsuario ? _filtroUsuarioNombre! : 'Usuario',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: hasUsuario ? Colors.white : AppColors.primary,
            fontWeight: hasUsuario ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: hasUsuario
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.1),
        deleteIcon: hasUsuario
            ? const Icon(Icons.close, size: 16, color: Colors.white)
            : null,
        onDeleted: hasUsuario
            ? () {
                setState(() {
                  _filtroUsuarioId = null;
                  _filtroUsuarioNombre = null;
                });
                _applyFilters();
              }
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(
            color: hasUsuario
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXS),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeXS,
          color: isSelected ? Colors.white : chipColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: chipColor.withValues(alpha: 0.1),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXS),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _onCondicionChanged(String? condicion) {
    setState(() => _filtroCondicion = condicion);
    _applyFilters();
  }

  /// Barra con el total de unidades/registros del filtro actual.
  /// Con filtro de condición el conteo equivale a unidades (1 registro por
  /// unidad y condición); sin filtro son registros (una unidad puede tener
  /// más de uno).
  Widget _buildCountBar(
    AsyncValue<List<RegistroVinListItem>> registrosAsync,
    RegistroVinListNotifier notifier,
  ) {
    final count = notifier.totalCount;
    if (count == null || !registrosAsync.hasValue) {
      return const SizedBox.shrink();
    }

    final String label;
    if (_filtroCondicion != null) {
      final condicionLabel = _condiciones[_filtroCondicion] ?? _filtroCondicion!;
      label = count == 1
          ? '1 unidad en $condicionLabel'
          : '$count unidades en $condicionLabel';
    } else {
      label = count == 1 ? '1 registro' : '$count registros';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car,
            size: DesignTokens.iconS,
            color: AppColors.primary,
          ),
          const SizedBox(width: DesignTokens.spaceXS),
          Text(
            label,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTTOM SHEET SELECTOR DE USUARIO REGISTRADOR
  // ============================================================================

  void _showUsuarioSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        // Evita que el teclado tape el buscador
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _UsuarioSearchSheet(
          onSelected: (id, nombre) {
            setState(() {
              _filtroUsuarioId = id;
              _filtroUsuarioNombre = nombre;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  // ============================================================================
  // LISTA DE RESULTADOS
  // ============================================================================

  Widget _buildResultsList(
    AsyncValue<List<RegistroVinListItem>> registrosAsync,
    RegistroVinListNotifier notifier,
  ) {
    return registrosAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stackTrace) => ConnectionErrorScreen(
        error: error,
        onRetry: () => notifier.refresh(),
      ),
      data: (registros) => _buildDataState(registros, notifier),
    );
  }

  Widget _buildDataState(
    List<RegistroVinListItem> registros,
    RegistroVinListNotifier notifier,
  ) {
    if (registros.isEmpty) {
      return _buildEmptyState(notifier);
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          DesignTokens.spaceS,
          DesignTokens.spaceS,
          DesignTokens.spaceS,
          DesignTokens.spaceS + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: registros.length + (notifier.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < registros.length) {
            final registro = registros[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spaceXS,
              ),
              child: _RegistroVinCard(
                registro: registro,
                onTap: () => _navigateToDetail(registro.vinNumero),
              ),
            );
          }

          // Indicador de carga al final
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(RegistroVinListNotifier notifier) {
    final hasFilters = _buildFilters().isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'Sin resultados' : 'No hay registros',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'No se encontraron registros con los filtros actuales'
                : 'Aún no hay registros disponibles',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (hasFilters) ...[
            AppButton.secondary(
              text: 'Limpiar filtros',
              icon: Icons.clear,
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _filtroCondicion = null;
                  _filtroUsuarioId = null;
                  _filtroUsuarioNombre = null;
                });
                notifier.clearSearch();
              },
            ),
          ] else ...[
            AppButton.primary(
              text: 'Actualizar',
              icon: Icons.refresh,
              onPressed: () => notifier.refresh(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE ACCIÓN
  // ============================================================================

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VinScannerScreen(
          onScanned: (vin) {
            _searchController.text = vin;
            _applyFilters();
            _searchFocusNode.unfocus();
          },
        ),
      ),
    );
  }

  void _navigateToDetail(String vin) {
    context.push('/autos/detalle/$vin');
  }
}

// =============================================================================
// CARD: Registro VIN individual
// =============================================================================

class _RegistroVinCard extends StatelessWidget {
  final RegistroVinListItem registro;
  final VoidCallback onTap;

  const _RegistroVinCard({required this.registro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final condicionColor = VehicleHelpers.getCondicionColor(
      registro.condicion,
    );
    final marcaModelo = '${registro.marca} ${registro.modelo}'.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: AppColors.neutral),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de condición
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: condicionColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceS),

              // VIN + usuario registrador + condición/nave
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registro.vinNumero,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (registro.createBy != null &&
                        registro.createBy!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              registro.createBy!,
                              style: const TextStyle(
                                fontSize: DesignTokens.fontSizeXS,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: DesignTokens.spaceXXS),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceXS,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: condicionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusS,
                            ),
                          ),
                          child: Text(
                            registro.condicion,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeXS * 0.9,
                              fontWeight: FontWeight.bold,
                              color: condicionColor,
                            ),
                          ),
                        ),
                        if (registro.nave != null &&
                            registro.nave!.isNotEmpty) ...[
                          const SizedBox(width: DesignTokens.spaceXS),
                          Flexible(
                            child: Text(
                              registro.nave!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: DesignTokens.fontSizeXS * 0.9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Marca/modelo + fecha + hora
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (marcaModelo.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        marcaModelo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  Text(
                    registro.fecha,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    registro.hora,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BOTTOM SHEET: Selector de usuario registrador
// =============================================================================

class _UsuarioSearchSheet extends ConsumerStatefulWidget {
  final void Function(int id, String nombre) onSelected;
  const _UsuarioSearchSheet({required this.onSelected});

  @override
  ConsumerState<_UsuarioSearchSheet> createState() =>
      _UsuarioSearchSheetState();
}

class _UsuarioSearchSheetState extends ConsumerState<_UsuarioSearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuariosAsync = ref.watch(usuariosRegistradoresProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXXXL),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: DesignTokens.spaceS),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(DesignTokens.spaceXXS),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceL),

            // Header con gradiente
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingPage,
              ),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spacingCard),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.spaceM),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusL),
                      ),
                      child: const Icon(
                        Icons.person_search,
                        color: Colors.white,
                        size: DesignTokens.iconXXL,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingCard),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filtrar por usuario',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeM,
                              fontWeight: DesignTokens.fontWeightBold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spaceXXS),
                          Text(
                            'Selecciona quién hizo el registro',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeXS,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: DesignTokens.spacingCard),

            // Campo de búsqueda local
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingPage,
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Buscar usuario...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon:
                      const Icon(Icons.search, size: DesignTokens.iconXL),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: DesignTokens.iconXL,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusButton),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusButton),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusButton),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: DesignTokens.borderWidthThick,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: DesignTokens.inputPadding,
                ),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
            ),

            const SizedBox(height: DesignTokens.spaceM),

            // Resultados
            Expanded(
              child: usuariosAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: DesignTokens.iconHuge,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: DesignTokens.spaceL),
                      const Text(
                        'No se pudo cargar la lista de usuarios',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: DesignTokens.fontSizeS,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceM),
                      AppButton.secondary(
                        text: 'Reintentar',
                        icon: Icons.refresh,
                        onPressed: () =>
                            ref.invalidate(usuariosRegistradoresProvider),
                      ),
                    ],
                  ),
                ),
                data: (usuarios) {
                  final filtrados = _query.isEmpty
                      ? usuarios
                      : usuarios
                          .where(
                            (u) => u.nombre.toLowerCase().contains(_query),
                          )
                          .toList();

                  if (filtrados.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron usuarios',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: DesignTokens.fontSizeS,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: DesignTokens.spaceM,
                      right: DesignTokens.spaceM,
                      bottom: MediaQuery.of(context).viewPadding.bottom,
                    ),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final usuario = filtrados[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.spaceXXS,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSelected(usuario.id, usuario.nombre);
                            },
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusL),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacingCard,
                                vertical: DesignTokens.spaceM,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(DesignTokens.radiusL),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      DesignTokens.spaceS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusS,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.secondary,
                                      size: DesignTokens.iconXL,
                                    ),
                                  ),
                                  const SizedBox(width: DesignTokens.spaceM),
                                  Expanded(
                                    child: Text(
                                      usuario.nombre,
                                      style: const TextStyle(
                                        fontSize: DesignTokens.fontSizeS,
                                        fontWeight:
                                            DesignTokens.fontWeightSemiBold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textLight,
                                    size: DesignTokens.iconXL,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
