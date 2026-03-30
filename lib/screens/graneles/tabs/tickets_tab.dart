// =============================================================================
// TAB DE VIAJES (TICKETS DE MUELLE) - CON FILTROS DE ESTADO Y BÚSQUEDA
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
import 'package:stampcamera/widgets/common/fullscreen_image_viewer.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

/// Tipos de filtro disponibles para Viajes
enum ViajeFilterType {
  todos,
  pendienteBalanza,
  pendienteAlmacen,
  completos,
}

class TicketsTab extends ConsumerStatefulWidget {
  const TicketsTab({super.key});

  @override
  ConsumerState<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends ConsumerState<TicketsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  ViajeFilterType _currentFilter = ViajeFilterType.todos;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();

    // Cargar TODOS los tickets (sin filtro de servicio)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ticketsMuelleProvider.notifier).setServicioId(null);
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final notifier = ref.read(ticketsMuelleProvider.notifier);

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Solo cargar más si no está buscando activamente y hay más páginas
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
    final ticketsAsync = ref.watch(ticketsMuelleProvider);
    final notifier = ref.read(ticketsMuelleProvider.notifier);
    final permissionsAsync = ref.watch(userGranelesPermissionsProvider);
    final canAdd = permissionsAsync.valueOrNull?.muelle.canAdd ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Barra de busqueda
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por ticket o placa...',
            showScannerButton: false,
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
          ),

          // Filtros de estado (chips horizontales)
          _buildFilterChips(notifier),

          // Lista de viajes
          Expanded(child: _buildResultsList(ticketsAsync, notifier)),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateTicket(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nuevo Viaje',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: DesignTokens.fontSizeS,
                ),
              ),
            )
          : null,
    );
  }

  // ===========================================================================
  // FILTER CHIPS
  // ===========================================================================

  Widget _buildFilterChips(TicketMuelleNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Todos',
              isSelected: _currentFilter == ViajeFilterType.todos,
              onSelected: () => _onFilterChanged(ViajeFilterType.todos, notifier),
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Pend. Balanza',
              isSelected: _currentFilter == ViajeFilterType.pendienteBalanza,
              onSelected: () => _onFilterChanged(ViajeFilterType.pendienteBalanza, notifier),
              color: AppColors.warning,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Pend. Almacen',
              isSelected: _currentFilter == ViajeFilterType.pendienteAlmacen,
              onSelected: () => _onFilterChanged(ViajeFilterType.pendienteAlmacen, notifier),
              color: AppColors.accent,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            _buildFilterChip(
              label: 'Completos',
              isSelected: _currentFilter == ViajeFilterType.completos,
              onSelected: () => _onFilterChanged(ViajeFilterType.completos, notifier),
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
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXS),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _onFilterChanged(ViajeFilterType filter, TicketMuelleNotifier notifier) {
    setState(() => _currentFilter = filter);
    _searchController.clear();
    _applyCurrentFilter(notifier);
  }

  void _applyCurrentFilter(TicketMuelleNotifier notifier) {
    switch (_currentFilter) {
      case ViajeFilterType.todos:
        notifier.setFilterEstado(null);
        break;
      case ViajeFilterType.pendienteBalanza:
        notifier.setFilterEstado('pendiente_balanza');
        break;
      case ViajeFilterType.pendienteAlmacen:
        notifier.setFilterEstado('pendiente_almacen');
        break;
      case ViajeFilterType.completos:
        notifier.setFilterEstado('completo');
        break;
    }
  }

  // ===========================================================================
  // LISTA
  // ===========================================================================

  Widget _buildResultsList(
    AsyncValue<List<TicketMuelle>> ticketsAsync,
    TicketMuelleNotifier notifier,
  ) {
    return ticketsAsync.when(
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
      data: (tickets) {
        return _buildDataState(tickets, notifier);
      },
    );
  }

  Widget _buildDataState(
    List<TicketMuelle> tickets,
    TicketMuelleNotifier notifier,
  ) {
    if (tickets.isEmpty) {
      return _buildEmptyState(notifier);
    }

    // Con filtro server-side, el infinite scroll funciona con o sin filtro
    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        // Padding extra abajo para el FAB (80px)
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spaceM,
          DesignTokens.spaceM,
          DesignTokens.spaceM,
          DesignTokens.spaceM + 80,
        ),
        itemCount: tickets.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < tickets.length) {
            final ticket = tickets[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _TicketCard(
                ticket: ticket,
                onTap: () => _navigateToDetail(ticket.id),
                onEdit: () => _navigateToEditTicket(ticket.id),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(DesignTokens.spaceL),
            alignment: Alignment.center,
            child: Column(
              children: [
                if (notifier.isLoadingMore) ...[
                  AppLoadingState.circular(
                    message: 'Cargando mas viajes...',
                  ),
                ] else ...[
                  AppButton.ghost(
                    text: 'Cargar mas',
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

  Widget _buildEmptyState(TicketMuelleNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    String title;
    String subtitle;
    IconData icon;

    if (isSearching) {
      title = 'Sin resultados';
      subtitle = 'No se encontraron viajes que coincidan con "${_searchController.text}"';
      icon = Icons.search_off;
    } else if (_currentFilter == ViajeFilterType.pendienteBalanza) {
      title = 'Sin pendientes';
      subtitle = 'Todos los viajes tienen balanza asignada';
      icon = Icons.check_circle_outline;
    } else if (_currentFilter == ViajeFilterType.pendienteAlmacen) {
      title = 'Sin pendientes';
      subtitle = 'Todos los viajes con balanza tienen almacen asignado';
      icon = Icons.check_circle_outline;
    } else if (_currentFilter == ViajeFilterType.completos) {
      title = 'Sin viajes completos';
      subtitle = 'Aun no hay viajes con balanza y almacen registrados';
      icon = Icons.hourglass_empty;
    } else {
      title = 'No hay viajes registrados';
      subtitle = 'Aun no hay viajes de muelle registrados';
      icon = Icons.receipt_long_outlined;
    }

    Widget? action;
    if (isSearching) {
      action = AppButton.secondary(
        text: 'Limpiar busqueda',
        icon: Icons.clear,
        onPressed: () {
          _searchController.clear();
          _applyCurrentFilter(notifier);
        },
      );
    } else if (_currentFilter != ViajeFilterType.todos) {
      action = AppButton.secondary(
        text: 'Ver todos',
        icon: Icons.list,
        onPressed: () {
          _onFilterChanged(ViajeFilterType.todos, notifier);
        },
      );
    } else {
      action = AppButton.primary(
        text: 'Crear primer viaje',
        icon: Icons.add,
        onPressed: () => _navigateToCreateTicket(),
      );
    }

    return Center(
      child: AppEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        color: (_currentFilter == ViajeFilterType.pendienteBalanza ||
                _currentFilter == ViajeFilterType.pendienteAlmacen ||
                _currentFilter == ViajeFilterType.completos) &&
                !isSearching
            ? AppColors.success
            : null,
        action: action,
      ),
    );
  }

  void _navigateToDetail(int ticketId) {
    context.push('/graneles/ticket/$ticketId');
  }

  void _navigateToEditTicket(int ticketId) {
    context.push('/graneles/ticket/editar/$ticketId');
  }

  void _navigateToCreateTicket() {
    // Navegar al formulario unificado de viaje (3 pasos)
    context.push('/graneles/viaje/crear');
  }
}

// =============================================================================
// TICKET CARD
// =============================================================================

class _TicketCard extends StatelessWidget {
  final TicketMuelle ticket;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _TicketCard({
    required this.ticket,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return AppCard.elevated(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Servicio info (codigo y nave)
              if (ticket.servicioCodigo != null) ...[
                Row(
                  children: [
                    const Icon(Icons.directions_boat, size: 14, color: AppColors.accent),
                    const SizedBox(width: DesignTokens.spaceXS),
                    Expanded(
                      child: Text(
                        '${ticket.servicioCodigo}${ticket.servicioNave != null ? ' - ${ticket.servicioNave}' : ''}',
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceS),
              ],

              // Header con numero de ticket y botones
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
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
                        const Icon(Icons.receipt, size: 14, color: Colors.white),
                        const SizedBox(width: DesignTokens.spaceXS),
                        Text(
                          ticket.numeroTicket,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: DesignTokens.fontSizeS,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Boton foto
                  if (ticket.fotoUrl != null)
                    IconButton(
                      onPressed: () => _showPhotoDialog(context, ticket.fotoUrl!),
                      icon: const Icon(Icons.photo_camera, size: 20, color: AppColors.primary),
                      tooltip: 'Ver foto',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(DesignTokens.spaceXS),
                    ),
                  const SizedBox(width: DesignTokens.spaceXS),
                  // Boton editar
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                    tooltip: 'Editar viaje',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(DesignTokens.spaceXS),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceXS),
              // Status badges (balanza y almacen)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ticket.estado == 'completo'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : ticket.estado == 'pendiente_almacen'
                              ? AppColors.info.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      ticket.estado == 'completo'
                          ? 'Completo'
                          : ticket.estado == 'pendiente_almacen'
                              ? 'Pend. Almacén'
                              : 'Pend. Balanza',
                      style: TextStyle(
                        color: ticket.estado == 'completo'
                            ? AppColors.success
                            : ticket.estado == 'pendiente_almacen'
                                ? AppColors.info
                                : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeXS,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceM),

              // Placa
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: DesignTokens.spaceS),
                  Text(
                    ticket.placaStr ?? 'Sin placa',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceS),

              // Producto y BL
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: DesignTokens.spaceXS),
                        Expanded(
                          child: Text(
                            ticket.productoNombre ?? 'Sin producto',
                            style: const TextStyle(
                              fontSize: DesignTokens.fontSizeS,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceS),
                  Text(
                    'BL: ${ticket.blStr ?? "-"}',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceS),

              // Bodega y tiempos
              Row(
                children: [
                  const Icon(Icons.warehouse, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    ticket.bodega ?? 'Sin bodega',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    ticket.inicioDescarga != null
                        ? '${timeFormat.format(toLima(ticket.inicioDescarga!))} - ${ticket.finDescarga != null ? timeFormat.format(toLima(ticket.finDescarga!)) : "?"}'
                        : 'Sin horario',
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (ticket.tiempoCargio != null) ...[
                    const SizedBox(width: DesignTokens.spaceS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        ticket.tiempoCargio!,
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Observaciones
              if (ticket.observaciones != null && ticket.observaciones!.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.spaceS),
                const Divider(),
                Text(
                  ticket.observaciones!,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
    );
  }

  void _showPhotoDialog(BuildContext context, String url) {
    FullscreenImageViewer.open(
      context,
      imageUrl: url,
      title: 'Foto Ticket',
    );
  }
}
