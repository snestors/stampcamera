// ============================================================================
// 📂 lib/screens/autos/registro_general/registro_screen.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';
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
  sinRegistroPuerto,
  sinRecepcion,
  pedeteados,
  conDanos,
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  RegistroFilterType _currentFilter = RegistroFilterType.todos;

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
          // ✅ Barra de búsqueda reutilizable
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

          // ✅ Filtros de estado
          _buildFilterChips(notifier),

          // ✅ Lista de resultados
          Expanded(child: _buildResultsList(registrosAsync, notifier)),
        ],
      ),
    );
  }

  /// Construye los chips de filtro
  Widget _buildFilterChips(RegistroGeneralNotifier notifier) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Todos',
              isSelected: _currentFilter == RegistroFilterType.todos,
              onSelected: () => _onFilterChanged(RegistroFilterType.todos, notifier),
            ),
            SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Con Daños',
              isSelected: _currentFilter == RegistroFilterType.conDanos,
              onSelected: () => _onFilterChanged(RegistroFilterType.conDanos, notifier),
              color: AppColors.error,
            ),
            SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Sin Reg. Puerto',
              isSelected: _currentFilter == RegistroFilterType.sinRegistroPuerto,
              onSelected: () => _onFilterChanged(RegistroFilterType.sinRegistroPuerto, notifier),
              color: AppColors.warning,
            ),
            SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Sin Recepción',
              isSelected: _currentFilter == RegistroFilterType.sinRecepcion,
              onSelected: () => _onFilterChanged(RegistroFilterType.sinRecepcion, notifier),
              color: AppColors.accent,
            ),
            SizedBox(width: DesignTokens.spaceXS),
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
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceXS),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _onFilterChanged(RegistroFilterType filter, RegistroGeneralNotifier notifier) {
    setState(() => _currentFilter = filter);
    _searchController.clear();
    _applyCurrentFilter(notifier);
  }

  void _applyCurrentFilter(RegistroGeneralNotifier notifier) {
    switch (_currentFilter) {
      case RegistroFilterType.todos:
        notifier.clearSearch();
        break;
      case RegistroFilterType.sinRegistroPuerto:
        notifier.searchWithFilters({'sin_registro_puerto': true});
        break;
      case RegistroFilterType.sinRecepcion:
        notifier.searchWithFilters({'sin_recepcion': true});
        break;
      case RegistroFilterType.pedeteados:
        notifier.searchPedeteados();
        break;
      case RegistroFilterType.conDanos:
        notifier.searchWithDanos();
        break;
    }
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

      // ✅ Usar ConnectionErrorScreen para manejo inteligente de errores
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
        padding: EdgeInsets.all(DesignTokens.spaceS),
        itemCount: registros.length + (notifier.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < registros.length) {
            final registro = registros[index];
            return Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
              child: GestureDetector(
                onTap: () => _navigateToDetail(registro.vin),
                child: DetalleRegistroCard(registro: registro),
              ),
            );
          }

          // Indicador de carga al final (sin botón manual)
          return Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
            child: const Center(
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
            style: TextStyle(color: AppColors.textSecondary),
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
