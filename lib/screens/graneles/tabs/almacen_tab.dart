// =============================================================================
// TAB DE ALMACÉN - TODOS LOS REGISTROS CON BÚSQUEDA E INFINITE SCROLL
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

class AlmacenTab extends ConsumerStatefulWidget {
  const AlmacenTab({super.key});

  @override
  ConsumerState<AlmacenTab> createState() => _AlmacenTabState();
}

class _AlmacenTabState extends ConsumerState<AlmacenTab> {
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
      final notifier = ref.read(almacenListProvider.notifier);

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
    final almacenAsync = ref.watch(almacenListProvider);
    final notifier = ref.read(almacenListProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
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
          Expanded(child: _buildResultsList(almacenAsync, notifier)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_almacen',
        onPressed: () => context.push('/graneles/almacen/crear'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Almacén',
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
    AsyncValue<List<AlmacenGranel>> almacenAsync,
    AlmacenNotifier notifier,
  ) {
    return almacenAsync.when(
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
      data: (registros) => _buildDataState(registros, notifier),
    );
  }

  Widget _buildDataState(
    List<AlmacenGranel> registros,
    AlmacenNotifier notifier,
  ) {
    if (registros.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(DesignTokens.spaceM),
        itemCount: registros.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < registros.length) {
            final almacen = registros[index];
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _AlmacenCard(
                almacen: almacen,
                onEdit: () => context.push('/graneles/almacen/editar/${almacen.id}'),
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

  Widget _buildEmptyState(AlmacenNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.warehouse_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            isSearching ? 'Sin resultados' : 'No hay registros de almacén',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            isSearching
                ? 'No se encontraron registros que coincidan con "${_searchController.text}"'
                : 'Aún no hay registros de almacén',
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
              text: 'Crear primer registro',
              icon: Icons.add,
              onPressed: () => context.push('/graneles/almacen/crear'),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// ALMACÉN CARD
// =============================================================================

class _AlmacenCard extends StatelessWidget {
  final AlmacenGranel almacen;
  final VoidCallback? onEdit;

  const _AlmacenCard({required this.almacen, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');
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
            // Info del servicio
            if (almacen.servicioCodigo != null) ...[
              Row(
                children: [
                  Icon(Icons.directions_boat, size: 14, color: AppColors.accent),
                  SizedBox(width: DesignTokens.spaceXS),
                  Expanded(
                    child: Text(
                      almacen.servicioCodigo!,
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
                      const Icon(Icons.warehouse, size: 14, color: Colors.white),
                      SizedBox(width: DesignTokens.spaceXS),
                      Text(
                        almacen.almacenNombre ?? 'Almacén',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (almacen.guia != null)
                        Text(
                          'Guía: ${almacen.guia}',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeS,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        'Ticket: ${almacen.ticketNumero ?? "-"}',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (almacen.foto1Url != null)
                  IconButton(
                    onPressed: () => _showPhotoDialog(context, almacen.foto1Url!),
                    icon: Icon(Icons.photo_camera, size: 20, color: AppColors.primary),
                    tooltip: 'Ver foto',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(DesignTokens.spaceXS),
                  ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, size: 20, color: AppColors.primary),
                    tooltip: 'Editar registro',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(DesignTokens.spaceXS),
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
                  almacen.placaStr ?? 'Sin placa',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
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
                    value: numberFormat.format(almacen.pesoBruto),
                    unit: 'TM',
                  ),
                  Container(height: 30, width: 1, color: AppColors.neutral),
                  _PesoItem(
                    label: 'Tara',
                    value: numberFormat.format(almacen.pesoTara),
                    unit: 'TM',
                  ),
                  Container(height: 30, width: 1, color: AppColors.neutral),
                  _PesoItem(
                    label: 'Neto',
                    value: numberFormat.format(almacen.pesoNeto),
                    unit: 'TM',
                    highlight: true,
                  ),
                  if (almacen.bags != null) ...[
                    Container(height: 30, width: 1, color: AppColors.neutral),
                    _PesoItem(
                      label: 'Bags',
                      value: almacen.bags.toString(),
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
                  'Entrada: ${almacen.fechaEntradaAlmacen != null ? dateFormat.format(almacen.fechaEntradaAlmacen!) : "-"}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceM),
                Text(
                  'Salida: ${almacen.fechaSalidaAlmacen != null ? dateFormat.format(almacen.fechaSalidaAlmacen!) : "-"}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Observaciones
            if (almacen.observaciones != null && almacen.observaciones!.isNotEmpty) ...[
              SizedBox(height: DesignTokens.spaceS),
              const Divider(),
              Text(
                almacen.observaciones!,
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
                  Text('Foto Almacén', style: TextStyle(fontWeight: FontWeight.bold, fontSize: DesignTokens.fontSizeM)),
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
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, lp) {
                  if (lp == null) return child;
                  return Container(height: 300, color: AppColors.surface, child: const Center(child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, st) => Container(
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
