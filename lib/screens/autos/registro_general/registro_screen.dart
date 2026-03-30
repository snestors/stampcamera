// ============================================================================
// lib/screens/autos/registro_general/registro_screen.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';
import 'package:stampcamera/services/http_service.dart';
import 'package:stampcamera/widgets/autos/card_detalle_registro_vin.dart';
import 'package:stampcamera/widgets/vin_scanner_screen.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

/// Tipos de filtro disponibles
enum RegistroFilterType {
  todos,
  conDanos,
  sinRegistroPuerto,
  conRecepcion,
  sinRecepcion,
  pedeteados,
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  RegistroFilterType _currentFilter = RegistroFilterType.todos;

  // Filtro de nave
  int? _filtroNaveId;
  String? _filtroNaveLabel;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final notifier = ref.read(registroGeneralProvider.notifier);

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
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrosAsync = ref.watch(registroGeneralProvider);
    final notifier = ref.read(registroGeneralProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda reutilizable
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por VIN o Serie...',
            onChanged: (value) {
              if (value.trim().isEmpty) {
                _applyCurrentFilter(notifier);
              } else {
                notifier.debouncedSearch(value);
              }
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                notifier.search(value);
                _searchFocusNode.unfocus();
              }
            },
            onClear: () {
              _applyCurrentFilter(notifier);
              _searchFocusNode.unfocus();
            },
            onScannerPressed: () => _openScanner(notifier),
            scannerTooltip: 'Escanear código VIN',
          ),

          // Filtros de estado + nave
          _buildFilterChips(notifier),

          // Lista de resultados
          Expanded(child: _buildResultsList(registrosAsync, notifier)),
        ],
      ),
    );
  }

  /// Construye los chips de filtro
  Widget _buildFilterChips(RegistroGeneralNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Chip de nave (filtro especial)
            _buildNaveChip(notifier),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Todos',
              isSelected: _currentFilter == RegistroFilterType.todos,
              onSelected: () => _onFilterChanged(RegistroFilterType.todos, notifier),
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Con Daños',
              isSelected: _currentFilter == RegistroFilterType.conDanos,
              onSelected: () => _onFilterChanged(RegistroFilterType.conDanos, notifier),
              color: AppColors.error,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Sin Reg. Puerto',
              isSelected: _currentFilter == RegistroFilterType.sinRegistroPuerto,
              onSelected: () => _onFilterChanged(RegistroFilterType.sinRegistroPuerto, notifier),
              color: AppColors.warning,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Con Recepción',
              isSelected: _currentFilter == RegistroFilterType.conRecepcion,
              onSelected: () => _onFilterChanged(RegistroFilterType.conRecepcion, notifier),
              color: AppColors.recepcion,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Sin Recepción',
              isSelected: _currentFilter == RegistroFilterType.sinRecepcion,
              onSelected: () => _onFilterChanged(RegistroFilterType.sinRecepcion, notifier),
              color: AppColors.accent,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Pedeteados',
              isSelected: _currentFilter == RegistroFilterType.pedeteados,
              onSelected: () => _onFilterChanged(RegistroFilterType.pedeteados, notifier),
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNaveChip(RegistroGeneralNotifier notifier) {
    final hasNave = _filtroNaveId != null;
    return GestureDetector(
      onTap: () => _showNaveSelector(notifier),
      child: Chip(
        avatar: Icon(
          Icons.directions_boat,
          size: 16,
          color: hasNave ? Colors.white : AppColors.primary,
        ),
        label: Text(
          hasNave ? _filtroNaveLabel! : 'Nave',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: hasNave ? Colors.white : AppColors.primary,
            fontWeight: hasNave ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: hasNave ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
        deleteIcon: hasNave
            ? const Icon(Icons.close, size: 16, color: Colors.white)
            : null,
        onDeleted: hasNave
            ? () {
                setState(() {
                  _filtroNaveId = null;
                  _filtroNaveLabel = null;
                });
                _applyCurrentFilter(notifier);
              }
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(
            color: hasNave ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
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

  void _onFilterChanged(RegistroFilterType filter, RegistroGeneralNotifier notifier) {
    setState(() => _currentFilter = filter);
    _searchController.clear();
    _applyCurrentFilter(notifier);
  }

  Map<String, dynamic> _buildFilters() {
    final filters = <String, dynamic>{};

    // Filtro de nave (se combina con cualquier filtro de estado)
    if (_filtroNaveId != null) {
      filters['nave_descarga_id'] = _filtroNaveId;
    }

    // Filtro de estado
    switch (_currentFilter) {
      case RegistroFilterType.todos:
        break;
      case RegistroFilterType.sinRegistroPuerto:
        filters['sin_registro_puerto'] = true;
        break;
      case RegistroFilterType.conRecepcion:
        filters['con_recepcion'] = true;
        break;
      case RegistroFilterType.sinRecepcion:
        filters['sin_recepcion'] = true;
        break;
      case RegistroFilterType.pedeteados:
        filters['pedeteado'] = true;
        break;
      case RegistroFilterType.conDanos:
        filters['danos'] = true;
        break;
    }

    return filters;
  }

  void _applyCurrentFilter(RegistroGeneralNotifier notifier) {
    final filters = _buildFilters();
    if (filters.isEmpty) {
      notifier.clearSearch();
    } else {
      notifier.searchWithFilters(filters);
    }
  }

  // ============================================================================
  // BOTTOM SHEET SELECTOR DE NAVE
  // ============================================================================

  void _showNaveSelector(RegistroGeneralNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NaveSearchSheet(
        onSelected: (id, label) {
          setState(() {
            _filtroNaveId = id;
            _filtroNaveLabel = label;
          });
          _applyCurrentFilter(notifier);
        },
      ),
    );
  }

  // ============================================================================
  // MÉTODOS PRIVADOS PARA EL UI
  // ============================================================================

  Widget _buildResultsList(
    AsyncValue<List<RegistroGeneral>> registrosAsync,
    RegistroGeneralNotifier notifier,
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
    List<RegistroGeneral> registros,
    RegistroGeneralNotifier notifier,
  ) {
    if (registros.isEmpty) {
      return _buildEmptyState(notifier);
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(DesignTokens.spaceS),
        itemCount: registros.length + (notifier.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < registros.length) {
            final registro = registros[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
              child: GestureDetector(
                onTap: () => _navigateToDetail(registro.vin),
                child: DetalleRegistroCard(registro: registro),
              ),
            );
          }

          // Indicador de carga al final (sin botón manual)
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

  Widget _buildEmptyState(RegistroGeneralNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Sin resultados' : 'No hay registros',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron registros que coincidan con "${_searchController.text}"'
                : 'Aún no hay registros disponibles',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (isSearching) ...[
            AppButton.secondary(
              text: 'Limpiar búsqueda',
              icon: Icons.clear,
              onPressed: () {
                _searchController.clear();
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

  void _openScanner(RegistroGeneralNotifier notifier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VinScannerScreen(
          onScanned: (vin) {
            _searchController.text = vin;
            notifier.search(vin);
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
// BOTTOM SHEET: Buscador de naves
// =============================================================================

class _NaveSearchSheet extends StatefulWidget {
  final void Function(int id, String label) onSelected;
  const _NaveSearchSheet({required this.onSelected});

  @override
  State<_NaveSearchSheet> createState() => _NaveSearchSheetState();
}

class _NaveSearchSheetState extends State<_NaveSearchSheet> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;

  List<Map<String, dynamic>> _parseNaves(List<dynamic> data) {
    return data.map((n) {
      final id = n['id'] as int;
      final buque = n['nombre_buque']?['nombre_buque'] ?? '?';
      final puerto = n['puerto']?['puerto'] ?? '';
      final estatus = n['estatus_display'] ?? '';
      final codigo = 'OP-${id.toString().padLeft(4, '0')}';
      return {
        'id': id,
        'buque': buque,
        'label': '$codigo - M.N $buque',
        'detalle': '$puerto  ·  $estatus',
      };
    }).toList();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{'categoria': 'AUTOS', 'limit': 15};
      if (query.trim().isNotEmpty) params['search'] = query;
      final response = await HttpService().dio.get(
        'api/v1/berthings/',
        queryParameters: params,
      );
      setState(() {
        _results = _parseNaves(response.data['results'] as List);
        _searched = true;
      });
    } catch (_) {
      setState(() {
        _results = [];
        _searched = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _search(''));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            // Header con gradiente (como modal_entrada)
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
                        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                      ),
                      child: const Icon(
                        Icons.directions_boat,
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
                            'Filtrar por nave',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeM,
                              fontWeight: DesignTokens.fontWeightBold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spaceXXS),
                          Text(
                            'Selecciona la nave de descarga',
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

            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingPage,
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre de buque...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, size: DesignTokens.iconXL),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: DesignTokens.iconXL),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: DesignTokens.borderWidthThick,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: DesignTokens.inputPadding,
                ),
                onChanged: _search,
              ),
            ),

            const SizedBox(height: DesignTokens.spaceM),

            // Resultados
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searched ? Icons.search_off : Icons.directions_boat_outlined,
                                size: DesignTokens.iconHuge,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: DesignTokens.spaceL),
                              Text(
                                _searched ? 'No se encontraron naves' : 'Escribe para buscar',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: DesignTokens.fontSizeS,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceM,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final nave = _results[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: DesignTokens.spaceXXS,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onSelected(
                                      nave['id'] as int,
                                      nave['label'] as String,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusL,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: DesignTokens.spacingCard,
                                      vertical: DesignTokens.spaceM,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusL,
                                      ),
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
                                            Icons.directions_boat_outlined,
                                            color: AppColors.secondary,
                                            size: DesignTokens.iconXL,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: DesignTokens.spaceM,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nave['label'] as String,
                                                style: const TextStyle(
                                                  fontSize:
                                                      DesignTokens.fontSizeS,
                                                  fontWeight: DesignTokens
                                                      .fontWeightSemiBold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: DesignTokens.spaceXXS,
                                              ),
                                              Text(
                                                nave['detalle'] as String,
                                                style: const TextStyle(
                                                  fontSize:
                                                      DesignTokens.fontSizeXS,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
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
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
