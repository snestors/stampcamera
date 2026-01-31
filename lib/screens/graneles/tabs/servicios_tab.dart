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
// SERVICIO CARD - Diseño compacto y limpio
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
      elevation: 1,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: servicio.cierreServicio
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con color de fondo
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
                vertical: DesignTokens.spaceS,
              ),
              decoration: BoxDecoration(
                color: servicio.cierreServicio
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(DesignTokens.radiusM),
                  topRight: Radius.circular(DesignTokens.radiusM),
                ),
              ),
              child: Row(
                children: [
                  // Código
                  Text(
                    servicio.codigo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: DesignTokens.fontSizeM,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spaceS),
                  // Estado badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: servicio.cierreServicio
                          ? AppColors.success
                          : AppColors.warning,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      servicio.cierreServicio ? 'CERRADO' : 'ACTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Tickets count
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 12, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          '${servicio.totalTickets}',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: DesignTokens.spaceXS),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),

            // Contenido principal
            Padding(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nave (título principal)
                  Text(
                    servicio.naveNombre ?? 'Sin nave',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: DesignTokens.spaceXS),

                  // Consignatario
                  Text(
                    servicio.consignatarioNombre ?? 'Sin consignatario',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: DesignTokens.spaceS),

                  // Puerto y fecha en fila
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          servicio.puerto ?? 'Sin puerto',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spaceM),
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        servicio.fechaAtraque != null
                            ? dateFormat.format(servicio.fechaAtraque!.toLocal())
                            : 'Sin fecha',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Productos (chips compactos)
                  if (servicio.productos.isNotEmpty) ...[
                    SizedBox(height: DesignTokens.spaceS),
                    Wrap(
                      spacing: DesignTokens.spaceXS,
                      runSpacing: DesignTokens.spaceXS,
                      children: servicio.productos.take(3).map((p) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                          ),
                          child: Text(
                            '${p.producto} ${p.cantidad} TM',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // Indicador si hay más productos
                    if (servicio.productos.length > 3)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '+${servicio.productos.length - 3} más',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
