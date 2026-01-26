// =============================================================================
// TAB DE BALANZAS - TODAS LAS BALANZAS CON BÚSQUEDA E INFINITE SCROLL
// =============================================================================
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
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
    final balanzasAsync = ref.watch(balanzasListProvider);
    final notifier = ref.read(balanzasListProvider.notifier);

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
          Expanded(child: _buildResultsList(balanzasAsync, notifier)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }

  Widget _buildResultsList(
    AsyncValue<List<Balanza>> balanzasAsync,
    BalanzaNotifier notifier,
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
      data: (balanzas) => _buildDataState(balanzas, notifier),
    );
  }

  Widget _buildDataState(
    List<Balanza> balanzas,
    BalanzaNotifier notifier,
  ) {
    if (balanzas.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(DesignTokens.spaceM),
        itemCount: balanzas.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < balanzas.length) {
            final balanza = balanzas[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _BalanzaCard(
                balanza: balanza,
                onEdit: () => context.push('/graneles/balanza/editar/${balanza.id}'),
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

  Widget _buildEmptyState(BalanzaNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.scale_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            isSearching ? 'Sin resultados' : 'No hay balanzas registradas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            isSearching
                ? 'No se encontraron balanzas que coincidan con "${_searchController.text}"'
                : 'Aún no hay registros de balanza',
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
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.all(DesignTokens.spaceM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              child: Row(
                children: [
                  Icon(Icons.photo_camera, color: AppColors.primary),
                  SizedBox(width: DesignTokens.spaceS),
                  Text('Foto Balanza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: DesignTokens.fontSizeM)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(DesignTokens.radiusL),
                bottomRight: Radius.circular(DesignTokens.radiusL),
              ),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: AppColors.surface,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: AppColors.surface,
                  child: Center(child: Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
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
