// =============================================================================
// TAB DE SILOS - TODOS LOS SILOS CON BÚSQUEDA E INFINITE SCROLL
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class SilosTab extends ConsumerStatefulWidget {
  const SilosTab({super.key});

  @override
  ConsumerState<SilosTab> createState() => _SilosTabState();
}

class _SilosTabState extends ConsumerState<SilosTab> {
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
      final notifier = ref.read(silosListProvider.notifier);

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!notifier.isLoadingMore && notifier.hasNextPage) {
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
    final silosAsync = ref.watch(silosListProvider);
    final notifier = ref.read(silosListProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Barra de búsqueda
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por producto o número...',
            showScannerButton: false,
            onChanged: (value) {
              if (value.trim().isEmpty) {
                notifier.clearSearch();
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
              notifier.clearSearch();
              _searchFocusNode.unfocus();
            },
          ),

          // Lista de silos
          Expanded(child: _buildResultsList(silosAsync, notifier)),
        ],
      ),
      // TODO: Agregar FAB para crear silos cuando se implemente el formulario
      // floatingActionButton: FloatingActionButton.extended(
      //   heroTag: 'fab_silos',
      //   onPressed: () => _navigateToCreateSilos(),
      //   backgroundColor: AppColors.primary,
      //   icon: const Icon(Icons.add, color: Colors.white),
      //   label: Text('Nuevo Silo', ...),
      // ),
    );
  }

  Widget _buildResultsList(
    AsyncValue<List<Silos>> silosAsync,
    SilosNotifier notifier,
  ) {
    return silosAsync.when(
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
      data: (silos) => _buildDataState(silos, notifier),
    );
  }

  Widget _buildDataState(
    List<Silos> silos,
    SilosNotifier notifier,
  ) {
    if (silos.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(DesignTokens.spaceM),
        itemCount: silos.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < silos.length) {
            final silo = silos[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _SiloCard(silo: silo),
            );
          }

          return Container(
            padding: EdgeInsets.all(DesignTokens.spaceL),
            alignment: Alignment.center,
            child: Column(
              children: [
                if (notifier.isLoadingMore) ...[
                  AppLoadingState.circular(
                    message: 'Cargando más registros...',
                  ),
                ] else ...[
                  AppButton.ghost(
                    text: 'Cargar más',
                    icon: Icons.expand_more,
                    onPressed: () => notifier.loadMore(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(SilosNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.storage_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            isSearching ? 'Sin resultados' : 'No hay registros de silos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            isSearching
                ? 'No se encontraron silos que coincidan con "${_searchController.text}"'
                : 'Aún no hay registros de silos',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: DesignTokens.spaceL),
          if (isSearching) ...[
            AppButton.secondary(
              text: 'Limpiar búsqueda',
              icon: Icons.clear,
              onPressed: () {
                _searchController.clear();
                notifier.clearSearch();
              },
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SILO CARD
// =============================================================================

class _SiloCard extends StatelessWidget {
  final Silos silo;

  const _SiloCard({required this.silo});

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat('#,##0.000', 'es_PE');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con número de silo
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceS,
                    vertical: DesignTokens.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storage, size: 14, color: Colors.white),
                      SizedBox(width: DesignTokens.spaceXS),
                      Text(
                        'N° ${silo.numeroSilo ?? "-"}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: DesignTokens.fontSizeS,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Producto
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    silo.productoNombre ?? 'Sin producto',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Peso y bags
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceS),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Peso',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spaceXS),
                      Text(
                        silo.peso != null ? numberFormat.format(silo.peso!) : '-',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeM,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'TM',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (silo.bags != null) ...[
                    Container(
                      height: 40,
                      width: 1,
                      color: AppColors.neutral,
                    ),
                    Column(
                      children: [
                        Text(
                          'Bags',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          silo.bags.toString(),
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          'unidades',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),

            // Fecha y hora
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceXS),
                Text(
                  silo.fechaHora != null
                      ? dateTimeFormat.format(silo.fechaHora!)
                      : 'Sin fecha',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
