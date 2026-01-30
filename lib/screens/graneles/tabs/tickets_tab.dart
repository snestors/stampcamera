// =============================================================================
// TAB DE TICKETS DE MUELLE - TODOS LOS TICKETS CON BÚSQUEDA E INFINITE SCROLL
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

class TicketsTab extends ConsumerStatefulWidget {
  const TicketsTab({super.key});

  @override
  ConsumerState<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends ConsumerState<TicketsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

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
    // Usar el estado del filtro del notifier (server-side)
    final filterPendientes = notifier.filterSinBalanza;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Barra de búsqueda
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por ticket o placa...',
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

          // Lista de tickets
          Expanded(child: _buildResultsList(ticketsAsync, notifier, filterPendientes)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTicket(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Ticket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeS,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(
    AsyncValue<List<TicketMuelle>> ticketsAsync,
    TicketMuelleNotifier notifier,
    bool filterPendientes,
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
        // Ya no se filtra client-side - el filtro es server-side
        return _buildDataState(tickets, notifier, filterPendientes);
      },
    );
  }

  Widget _buildDataState(
    List<TicketMuelle> tickets,
    TicketMuelleNotifier notifier,
    bool filterPendientes,
  ) {
    if (tickets.isEmpty) {
      return _buildEmptyState(notifier, filterPendientes);
    }

    // Con filtro server-side, el infinite scroll funciona con o sin filtro
    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        // Padding extra abajo para el FAB (80px)
        padding: EdgeInsets.fromLTRB(
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
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _TicketCard(
                ticket: ticket,
                onTap: () => _navigateToDetail(ticket.id),
                onEdit: () => _navigateToEditTicket(ticket.id),
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
                    message: 'Cargando más tickets...',
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

  Widget _buildEmptyState(TicketMuelleNotifier notifier, bool filterPendientes) {
    final isSearching = _searchController.text.isNotEmpty;

    String title;
    String subtitle;
    IconData icon;

    if (isSearching) {
      title = 'Sin resultados';
      subtitle = 'No se encontraron tickets que coincidan con "${_searchController.text}"';
      icon = Icons.search_off;
    } else if (filterPendientes) {
      title = 'Sin pendientes';
      subtitle = 'Todos los tickets tienen balanza asignada';
      icon = Icons.check_circle_outline;
    } else {
      title = 'No hay tickets registrados';
      subtitle = 'Aún no hay tickets de muelle registrados';
      icon = Icons.receipt_long_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: filterPendientes && !isSearching ? AppColors.success : Colors.grey[400],
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            subtitle,
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
          ] else if (filterPendientes) ...[
            AppButton.secondary(
              text: 'Ver todos',
              icon: Icons.list,
              onPressed: () {
                // Usar filtro server-side
                ref.read(ticketsMuelleProvider.notifier).setFilterSinBalanza(false);
              },
            ),
          ] else ...[
            AppButton.primary(
              text: 'Crear primer ticket',
              icon: Icons.add,
              onPressed: () => _navigateToCreateTicket(),
            ),
          ],
        ],
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
    // Navegar directamente a crear ticket - el formulario mostrará BLs de naves en operación
    context.push('/graneles/ticket/crear');
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

    return Card(
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
              // Servicio info (código y nave)
              if (ticket.servicioCodigo != null) ...[
                Row(
                  children: [
                    Icon(Icons.directions_boat, size: 14, color: AppColors.accent),
                    SizedBox(width: DesignTokens.spaceXS),
                    Expanded(
                      child: Text(
                        '${ticket.servicioCodigo}${ticket.servicioNave != null ? ' - ${ticket.servicioNave}' : ''}',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),
              ],

              // Header con número de ticket y botones
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
                        const Icon(Icons.receipt, size: 14, color: Colors.white),
                        SizedBox(width: DesignTokens.spaceXS),
                        Text(
                          ticket.numeroTicket,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: DesignTokens.fontSizeS,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Botón foto
                  if (ticket.fotoUrl != null)
                    IconButton(
                      onPressed: () => _showPhotoDialog(context, ticket.fotoUrl!),
                      icon: Icon(Icons.photo_camera, size: 20, color: AppColors.primary),
                      tooltip: 'Ver foto',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(DesignTokens.spaceXS),
                    ),
                  SizedBox(width: DesignTokens.spaceXS),
                  // Botón editar
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, size: 20, color: AppColors.primary),
                    tooltip: 'Editar ticket',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(DesignTokens.spaceXS),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceXS),
              // Status badges (balanza y almacén)
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ticket.tieneBalanza
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      ticket.tieneBalanza ? 'Con Balanza' : 'Sin Balanza',
                      style: TextStyle(
                        color: ticket.tieneBalanza ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: DesignTokens.fontSizeXS,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceM),

              // Placa
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: DesignTokens.spaceS),
                  Text(
                    ticket.placaStr ?? 'Sin placa',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceS),

              // Producto y BL
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: DesignTokens.spaceXS),
                        Expanded(
                          child: Text(
                            ticket.productoNombre ?? 'Sin producto',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeS,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: DesignTokens.spaceS),
                  Text(
                    'BL: ${ticket.blStr ?? "-"}',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceS),

              // Bodega y tiempos
              Row(
                children: [
                  Icon(Icons.warehouse, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    ticket.bodega ?? 'Sin bodega',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: DesignTokens.spaceXS),
                  Text(
                    ticket.inicioDescarga != null
                        ? '${timeFormat.format(ticket.inicioDescarga!)} - ${ticket.finDescarga != null ? timeFormat.format(ticket.finDescarga!) : "?"}'
                        : 'Sin horario',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (ticket.tiempoCargio != null) ...[
                    SizedBox(width: DesignTokens.spaceS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        ticket.tiempoCargio!,
                        style: TextStyle(
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
                SizedBox(height: DesignTokens.spaceS),
                const Divider(),
                Text(
                  ticket.observaciones!,
                  style: TextStyle(
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
        ),
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
