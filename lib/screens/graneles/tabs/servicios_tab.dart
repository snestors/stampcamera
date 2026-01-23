// =============================================================================
// TAB DE SERVICIOS DE GRANELES
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class ServiciosTab extends ConsumerStatefulWidget {
  const ServiciosTab({super.key});

  @override
  ConsumerState<ServiciosTab> createState() => _ServiciosTabState();
}

class _ServiciosTabState extends ConsumerState<ServiciosTab> {
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
      final notifier = ref.read(serviciosGranelesProvider.notifier);

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
    final serviciosAsync = ref.watch(serviciosGranelesProvider);
    final notifier = ref.read(serviciosGranelesProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por nave, código, consignatario...',
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
          Expanded(child: _buildResultsList(serviciosAsync, notifier)),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    AsyncValue<List<ServicioGranel>> serviciosAsync,
    ServiciosGranelesNotifier notifier,
  ) {
    return serviciosAsync.when(
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
      data: (servicios) => _buildDataState(servicios, notifier),
    );
  }

  Widget _buildDataState(
    List<ServicioGranel> servicios,
    ServiciosGranelesNotifier notifier,
  ) {
    if (servicios.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(DesignTokens.spaceM),
        itemCount: servicios.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < servicios.length) {
            final servicio = servicios[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _ServicioCard(
                servicio: servicio,
                onTap: () {
                  context.push('/graneles/servicio/${servicio.id}/dashboard');
                },
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(DesignTokens.spaceL),
            alignment: Alignment.center,
            child: Column(
              children: [
                if (notifier.isLoadingMore) ...[
                  AppLoadingState.circular(
                    message: 'Cargando más servicios...',
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

  Widget _buildEmptyState(ServiciosGranelesNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.directions_boat_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            isSearching ? 'Sin resultados' : 'No hay servicios disponibles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            isSearching
                ? 'No se encontraron servicios que coincidan con "${_searchController.text}"'
                : 'Marca asistencia en una nave de graneles',
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
// SERVICIO CARD
// =============================================================================

class _ServicioCard extends StatelessWidget {
  final ServicioGranel servicio;
  final VoidCallback onTap;

  const _ServicioCard({
    required this.servicio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: código, nave y estado
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
                        const Icon(Icons.directions_boat, size: 14, color: Colors.white),
                        SizedBox(width: DesignTokens.spaceXS),
                        Text(
                          servicio.codigo,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: DesignTokens.fontSizeS,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: DesignTokens.spaceS),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: DesignTokens.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: servicio.cierreServicio
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      servicio.cierreServicio ? 'CERRADO' : 'ACTIVO',
                      style: TextStyle(
                        color: servicio.cierreServicio ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontSizeXS,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${servicio.totalTickets} tickets',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spaceXS),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceM),

              // Nave
              Row(
                children: [
                  Icon(Icons.directions_boat_filled, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Text(
                      servicio.naveNombre ?? 'Sin nave',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceS),

              // Consignatario
              Row(
                children: [
                  Icon(Icons.business, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Text(
                      servicio.consignatarioNombre ?? 'Sin consignatario',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceS),

              // Puerto y fecha
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    servicio.puerto ?? 'Sin puerto',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    servicio.fechaAtraque != null
                        ? dateFormat.format(servicio.fechaAtraque!)
                        : 'Sin fecha',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Productos
              if (servicio.productos.isNotEmpty) ...[
                SizedBox(height: DesignTokens.spaceS),
                const Divider(),
                SizedBox(height: DesignTokens.spaceXS),
                Wrap(
                  spacing: DesignTokens.spaceS,
                  runSpacing: DesignTokens.spaceXS,
                  children: servicio.productos.map((p) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceS,
                        vertical: DesignTokens.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        '${p.producto} (${p.cantidad} TM)',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
