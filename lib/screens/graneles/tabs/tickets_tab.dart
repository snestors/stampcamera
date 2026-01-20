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

    return Scaffold(
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
          Expanded(child: _buildResultsList(ticketsAsync, notifier)),
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
      data: (tickets) => _buildDataState(tickets, notifier),
    );
  }

  Widget _buildDataState(
    List<TicketMuelle> tickets,
    TicketMuelleNotifier notifier,
  ) {
    if (tickets.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage && !notifier.isSearching;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(DesignTokens.spaceM),
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

  Widget _buildEmptyState(TicketMuelleNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            isSearching ? 'Sin resultados' : 'No hay tickets registrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            isSearching
                ? 'No se encontraron tickets que coincidan con "${_searchController.text}"'
                : 'Aún no hay tickets de muelle registrados',
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

  void _navigateToCreateTicket() async {
    // Mostrar selector de servicio antes de crear ticket
    final serviciosAsync = ref.read(serviciosGranelesProvider);

    serviciosAsync.when(
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cargando servicios...')),
        );
      },
      error: (error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicios: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      data: (servicios) async {
        if (servicios.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay servicios disponibles'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        // Mostrar bottom sheet para seleccionar servicio
        final servicioSeleccionado = await showModalBottomSheet<ServicioGranel>(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusL),
            ),
          ),
          builder: (context) => _ServicioSelectorSheet(servicios: servicios),
        );

        if (servicioSeleccionado != null && mounted) {
          context.push('/graneles/ticket/crear/${servicioSeleccionado.id}');
        }
      },
    );
  }
}

// =============================================================================
// SELECTOR DE SERVICIO PARA CREAR TICKET
// =============================================================================

class _ServicioSelectorSheet extends StatelessWidget {
  final List<ServicioGranel> servicios;

  const _ServicioSelectorSheet({required this.servicios});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
              child: Row(
                children: [
                  Icon(Icons.directions_boat, color: AppColors.primary),
                  SizedBox(width: DesignTokens.spaceS),
                  Text(
                    'Seleccionar Servicio',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),
            Divider(),
            // Lista de servicios
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.all(DesignTokens.spaceM),
                itemCount: servicios.length,
                itemBuilder: (context, index) {
                  final servicio = servicios[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: DesignTokens.spaceS),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.directions_boat,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        servicio.codigo,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        servicio.naveNombre ?? 'Sin nave asignada',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, servicio),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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

              // Header con número de ticket, estado balanza y botón editar
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
                  SizedBox(width: DesignTokens.spaceS),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceS,
                      vertical: DesignTokens.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: ticket.tieneBalanza
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      ticket.tieneBalanza ? 'CON BALANZA' : 'SIN BALANZA',
                      style: TextStyle(
                        color: ticket.tieneBalanza ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontSizeXS,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Botón editar
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, size: 20, color: AppColors.primary),
                    tooltip: 'Editar ticket',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(DesignTokens.spaceXS),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
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
}
