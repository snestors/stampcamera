import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final notifier = ref.read(inventarioBaseProvider.notifier);

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
    final inventariosAsync = ref.watch(inventarioBaseProvider);
    final notifier = ref.read(inventarioBaseProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),

          Expanded(child: _buildResultsList(inventariosAsync, notifier)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Buscar por embarque, marca o modelo...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(inventarioBaseProvider.notifier).clearSearch();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusL)),
          filled: true,
          fillColor: AppColors.surface,
        ),
        onChanged: (value) {
          setState(() {});
          if (value.trim().isEmpty) {
            ref.read(inventarioBaseProvider.notifier).clearSearch();
          } else {
            ref.read(inventarioBaseProvider.notifier).debouncedSearch(value);
          }
        },
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            ref.read(inventarioBaseProvider.notifier).search(value);
            _searchFocusNode.unfocus();
          }
        },
      ),
    );
  }

  Widget _buildResultsList(
    AsyncValue<List<InventarioNave>> inventariosAsync,
    InventarioBaseNotifier notifier,
  ) {
    return inventariosAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando inventarios...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => ConnectionErrorScreen(
        error: error,
        onRetry: () => notifier.refresh(),
      ),
      data: (naves) => _buildDataState(naves, notifier),
    );
  }

  Widget _buildDataState(
    List<InventarioNave> naves,
    InventarioBaseNotifier notifier,
  ) {
    if (naves.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage && !notifier.isSearching;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: naves.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < naves.length) {
            final nave = naves[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildNaveCard(nave),
            );
          }

          return Padding(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNaveCard(InventarioNave nave) {
    final accentColor = nave.isSIC ? AppColors.warning : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToNaveDetail(nave.naveDescargaId),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Accent strip lateral
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Icon(
                              nave.isSIC ? Icons.inventory : Icons.directions_boat,
                              color: accentColor,
                              size: 20,
                            ),
                            SizedBox(width: DesignTokens.spaceS),
                            Expanded(
                              child: Text(
                                nave.naveDescargaNombre,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: DesignTokens.fontSizeL,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),

                        SizedBox(height: DesignTokens.spaceS),

                        // Metadata row
                        Wrap(
                          spacing: DesignTokens.spaceM,
                          runSpacing: DesignTokens.spaceXS,
                          children: [
                            if (nave.naveDescargaPuerto.isNotEmpty)
                              _buildMetaItem(Icons.location_on, nave.naveDescargaPuerto),
                            if (nave.naveDescargaFechaAtraque.isNotEmpty)
                              _buildMetaItem(Icons.calendar_today, nave.naveDescargaFechaAtraque),
                            _buildMetaItem(Icons.inventory_2, '${nave.totalUnidades} unidades'),
                          ],
                        ),

                        SizedBox(height: DesignTokens.spaceS),

                        // Stats badges
                        Wrap(
                          spacing: DesignTokens.spaceS,
                          runSpacing: DesignTokens.spaceXS,
                          children: [
                            if (nave.isFPR && nave.totalDescargadoPuerto > 0)
                              _buildBadge(
                                '${nave.totalDescargadoPuerto} puerto',
                                AppColors.primary,
                              ),
                            if (nave.isSIC && nave.totalDescargadoAlmacen > 0)
                              _buildBadge(
                                '${nave.totalDescargadoAlmacen} almacén',
                                AppColors.warning,
                              ),
                            if (nave.totalDescargadoRecepcion > 0)
                              _buildBadge(
                                '${nave.totalDescargadoRecepcion} recep.',
                                AppColors.success,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        SizedBox(width: DesignTokens.spaceXS),
        Text(
          text,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeXS,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(InventarioBaseNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.inventory_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Sin resultados' : 'No hay inventarios',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No se encontraron inventarios que coincidan con "${_searchController.text}"'
                : 'Aún no hay inventarios registrados',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (isSearching) ...[
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                notifier.clearSearch();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => notifier.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE ACCIÓN
  // ============================================================================

  void _navigateToNaveDetail(int naveId) {
    context.push('/autos/inventario/nave/${naveId.toString()}');
  }

  // ============================================================================
  // MÉTODOS DE FILTROS
  // ============================================================================
}
