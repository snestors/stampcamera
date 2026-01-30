// =============================================================================
// TAB DE BALANZAS - TODAS LAS BALANZAS CON BÚSQUEDA E INFINITE SCROLL
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/services/graneles/graneles_service.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
import 'package:stampcamera/widgets/common/fullscreen_image_viewer.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class BalanzasTab extends ConsumerStatefulWidget {
  const BalanzasTab({super.key});

  @override
  ConsumerState<BalanzasTab> createState() => _BalanzasTabState();
}

class _BalanzasTabState extends ConsumerState<BalanzasTab> {
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
      final notifier = ref.read(balanzasListProvider.notifier);

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
    final balanzasAsync = ref.watch(balanzasListProvider);
    final notifier = ref.read(balanzasListProvider.notifier);
    final permissionsAsync = ref.watch(userGranelesPermissionsProvider);
    // Usar el estado del filtro del notifier (server-side)
    final filterPendientes = notifier.filterSinAlmacen;

    // Obtener permisos de balanza
    final permissions = permissionsAsync.valueOrNull ?? UserGranelesPermissions.defaults();
    final canAdd = permissions.balanza.canAdd;
    final canEdit = permissions.balanza.canEdit;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Barra de búsqueda
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por guía, placa o ticket...',
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

          // Lista de balanzas
          Expanded(child: _buildResultsList(balanzasAsync, notifier, canEdit, filterPendientes)),
        ],
      ),
      // Solo mostrar FAB si tiene permiso de agregar
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              heroTag: 'fab_balanza',
              onPressed: () => context.push('/graneles/balanza/crear'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Nueva Balanza',
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

  Widget _buildResultsList(
    AsyncValue<List<Balanza>> balanzasAsync,
    BalanzaNotifier notifier,
    bool canEdit,
    bool filterPendientes,
  ) {
    return balanzasAsync.when(
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
      data: (balanzas) {
        // Ya no se filtra client-side - el filtro es server-side
        return _buildDataState(balanzas, notifier, canEdit, filterPendientes);
      },
    );
  }

  Widget _buildDataState(
    List<Balanza> balanzas,
    BalanzaNotifier notifier,
    bool canEdit,
    bool filterPendientes,
  ) {
    if (balanzas.isEmpty) {
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
        itemCount: balanzas.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < balanzas.length) {
            final balanza = balanzas[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _BalanzaCard(
                balanza: balanza,
                // Solo mostrar botón editar si tiene permiso
                onEdit: canEdit
                    ? () => context.push('/graneles/balanza/editar/${balanza.id}')
                    : null,
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
                    message: 'Cargando más balanzas...',
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

  Widget _buildEmptyState(BalanzaNotifier notifier, bool filterPendientes) {
    final isSearching = _searchController.text.isNotEmpty;
    final permissionsAsync = ref.watch(userGranelesPermissionsProvider);
    final canAdd = permissionsAsync.valueOrNull?.balanza.canAdd ?? false;

    String title;
    String subtitle;
    IconData icon;

    if (isSearching) {
      title = 'Sin resultados';
      subtitle = 'No se encontraron balanzas que coincidan con "${_searchController.text}"';
      icon = Icons.search_off;
    } else if (filterPendientes) {
      title = 'Sin pendientes';
      subtitle = 'Todas las balanzas tienen almacén asignado';
      icon = Icons.check_circle_outline;
    } else {
      title = 'No hay balanzas registradas';
      subtitle = 'Aún no hay registros de balanza';
      icon = Icons.scale_outlined;
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
              text: 'Ver todas',
              icon: Icons.list,
              onPressed: () {
                // Usar filtro server-side
                ref.read(balanzasListProvider.notifier).setFilterSinAlmacen(false);
              },
            ),
          ] else if (canAdd) ...[
            // Solo mostrar botón crear si tiene permiso
            AppButton.primary(
              text: 'Crear primera balanza',
              icon: Icons.add,
              onPressed: () => context.push('/graneles/balanza/crear'),
            ),
          ],
        ],
      ),
    );
  }

}

// =============================================================================
// BALANZA CARD
// =============================================================================

class _BalanzaCard extends StatelessWidget {
  final Balanza balanza;
  final VoidCallback? onEdit;

  const _BalanzaCard({required this.balanza, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
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
            // Info del servicio (código)
            if (balanza.servicioCodigo != null) ...[
              Row(
                children: [
                  Icon(Icons.directions_boat, size: 14, color: AppColors.accent),
                  SizedBox(width: DesignTokens.spaceXS),
                  Expanded(
                    child: Text(
                      balanza.servicioCodigo!,
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
            // Header con guía, ticket y botón editar
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
                      const Icon(Icons.scale, size: 14, color: Colors.white),
                      SizedBox(width: DesignTokens.spaceXS),
                      Text(
                        'Guía: ${balanza.guia}',
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
                Expanded(
                  child: Text(
                    'Ticket: ${balanza.ticketNumero ?? "-"}',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Botón foto
                if (balanza.foto1Url != null)
                  IconButton(
                    onPressed: () => _showPhotoDialog(context, balanza.foto1Url!),
                    icon: Icon(Icons.photo_camera, size: 20, color: AppColors.primary),
                    tooltip: 'Ver foto',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(DesignTokens.spaceXS),
                  ),
                // Botón editar
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, size: 20, color: AppColors.primary),
                    tooltip: 'Editar balanza',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(DesignTokens.spaceXS),
                  ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Placa y almacén
            Row(
              children: [
                Icon(Icons.local_shipping, size: 16, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceS),
                Text(
                  balanza.placaStr ?? 'Sin placa',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.warehouse, size: 14, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceXS),
                Text(
                  balanza.almacen ?? 'Sin almacén',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),

            // Pesos
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceS),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PesoItem(
                    label: 'Bruto',
                    value: numberFormat.format(balanza.pesoBruto),
                    unit: 'TM',
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.neutral,
                  ),
                  _PesoItem(
                    label: 'Tara',
                    value: numberFormat.format(balanza.pesoTara),
                    unit: 'TM',
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: AppColors.neutral,
                  ),
                  _PesoItem(
                    label: 'Neto',
                    value: numberFormat.format(balanza.pesoNeto),
                    unit: 'TM',
                    highlight: true,
                  ),
                  if (balanza.bags != null) ...[
                    Container(
                      height: 30,
                      width: 1,
                      color: AppColors.neutral,
                    ),
                    _PesoItem(
                      label: 'Bags',
                      value: balanza.bags.toString(),
                      unit: '',
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),

            // Tiempos
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.spaceXS),
                Text(
                  'Entrada: ${balanza.fechaEntradaBalanza != null ? timeFormat.format(balanza.fechaEntradaBalanza!) : "-"}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceM),
                Text(
                  'Salida: ${balanza.fechaSalidaBalanza != null ? timeFormat.format(balanza.fechaSalidaBalanza!) : "-"}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Observaciones
            if (balanza.observaciones != null && balanza.observaciones!.isNotEmpty) ...[
              SizedBox(height: DesignTokens.spaceS),
              const Divider(),
              Text(
                balanza.observaciones!,
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
    );
  }

  void _showPhotoDialog(BuildContext context, String url) {
    FullscreenImageViewer.open(
      context,
      imageUrl: url,
      title: 'Foto Balanza',
    );
  }
}

class _PesoItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool highlight;

  const _PesoItem({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: DesignTokens.spaceXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
