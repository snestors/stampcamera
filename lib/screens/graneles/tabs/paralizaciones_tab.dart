// =============================================================================
// TAB DE PARALIZACIONES - CON BUSQUEDA E INFINITE SCROLL
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

class ParalizacionesTab extends ConsumerStatefulWidget {
  const ParalizacionesTab({super.key});

  @override
  ConsumerState<ParalizacionesTab> createState() => _ParalizacionesTabState();
}

class _ParalizacionesTabState extends ConsumerState<ParalizacionesTab> {
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
      final notifier = ref.read(paralizacionesListProvider.notifier);

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
    final listAsync = ref.watch(paralizacionesListProvider);
    final notifier = ref.read(paralizacionesListProvider.notifier);
    final permissionsAsync = ref.watch(userGranelesPermissionsProvider);
    final canAdd = permissionsAsync.valueOrNull?.paralizaciones.canAdd ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por bodega, motivo...',
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
          Expanded(child: _buildResultsList(listAsync, notifier)),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              heroTag: 'fab_paralizaciones',
              onPressed: () => context.push('/graneles/paralizacion/crear'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nueva Paralizacion',
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
    AsyncValue<List<Paralizacion>> listAsync,
    ParalizacionesNotifier notifier,
  ) {
    return listAsync.when(
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
      data: (items) => _buildDataState(items, notifier),
    );
  }

  Widget _buildDataState(
    List<Paralizacion> items,
    ParalizacionesNotifier notifier,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spaceM,
          DesignTokens.spaceM,
          DesignTokens.spaceM,
          DesignTokens.spaceM + 80,
        ),
        itemCount: items.length + (showLoadMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < items.length) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _ParalizacionCard(
                paralizacion: item,
                onTap: () => _showDetailSheet(item),
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
                    message: 'Cargando mas registros...',
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

  Widget _buildEmptyState(ParalizacionesNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: AppEmptyState(
        icon: isSearching ? Icons.search_off : Icons.pause_circle_outline,
        title: isSearching ? 'Sin resultados' : 'No hay paralizaciones',
        subtitle: isSearching
            ? 'No se encontraron paralizaciones que coincidan con "${_searchController.text}"'
            : 'Aun no hay paralizaciones registradas',
        action: isSearching
            ? AppButton.secondary(
                text: 'Limpiar busqueda',
                icon: Icons.clear,
                onPressed: () {
                  _searchController.clear();
                  notifier.clearSearch();
                },
              )
            : null,
      ),
    );
  }

  void _showDetailSheet(Paralizacion p) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final permissionsAsync = ref.read(userGranelesPermissionsProvider);
    final canEdit = permissionsAsync.valueOrNull?.paralizaciones.canEdit ?? false;
    final canDelete = permissionsAsync.valueOrNull?.paralizaciones.canDelete ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(DesignTokens.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spaceM),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Titulo
              const Row(
                children: [
                  Icon(Icons.pause_circle_outline, color: AppColors.primary),
                  SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Text(
                      'Paralizacion',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceM),

              // Servicio
              if (p.servicioCodigo != null) ...[
                _detailRow(Icons.directions_boat, 'Servicio',
                    '${p.servicioCodigo}${p.naveNombre != null ? ' - ${p.naveNombre}' : ''}'),
                const SizedBox(height: DesignTokens.spaceS),
              ],

              _detailRow(Icons.warehouse, 'Bodega', p.bodega),
              const SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.report_problem_outlined, 'Motivo', p.motivoStr ?? '-'),
              const SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.play_arrow, 'Inicio',
                  p.inicio != null ? dateTimeFormat.format(toLima(p.inicio!)) : '-'),
              const SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.stop, 'Fin',
                  p.fin != null ? dateTimeFormat.format(toLima(p.fin!)) : '-'),
              const SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.timer_outlined, 'Duracion', p.duracion ?? '-'),
              const SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.schedule, 'Jornada', p.jornadaStr ?? '-'),

              if (p.observacion != null && p.observacion!.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.spaceS),
                _detailRow(Icons.notes, 'Observacion', p.observacion!),
              ],

              if (p.createByNombre != null) ...[
                const SizedBox(height: DesignTokens.spaceM),
                const Divider(),
                const SizedBox(height: DesignTokens.spaceS),
                Text(
                  'Creado por: ${p.createByNombre}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (p.createAt != null)
                  Text(
                    dateTimeFormat.format(toLima(p.createAt!)),
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],

              // Botones de accion
              if (canEdit || canDelete) ...[
                const SizedBox(height: DesignTokens.spaceL),
                Row(
                  children: [
                    if (canEdit)
                      Expanded(
                        child: AppButton.primary(
                          text: 'Editar',
                          icon: Icons.edit,
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/graneles/paralizacion/editar/${p.id}');
                          },
                        ),
                      ),
                    if (canEdit && canDelete) const SizedBox(width: DesignTokens.spaceS),
                    if (canDelete)
                      Expanded(
                        child: AppButton.secondary(
                          text: 'Eliminar',
                          icon: Icons.delete_outline,
                          onPressed: () => _confirmDelete(ctx, p),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: DesignTokens.spaceS),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext ctx, Paralizacion p) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar paralizacion'),
        content: Text('Desea eliminar la paralizacion de bodega "${p.bodega}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              Navigator.pop(ctx);
              final success = await ref
                  .read(paralizacionesListProvider.notifier)
                  .deleteItem(p.id);
              if (mounted) {
                if (success) {
                  AppSnackBar.success(context, 'Paralizacion eliminada');
                } else {
                  AppSnackBar.error(context, 'Error al eliminar');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PARALIZACION CARD
// =============================================================================

class _ParalizacionCard extends ConsumerWidget {
  final Paralizacion paralizacion;
  final VoidCallback onTap;

  const _ParalizacionCard({
    required this.paralizacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AppCard.elevated(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Servicio info
          if (paralizacion.servicioCodigo != null) ...[
            Row(
              children: [
                const Icon(Icons.directions_boat, size: 14, color: AppColors.accent),
                const SizedBox(width: DesignTokens.spaceXS),
                Expanded(
                  child: Text(
                    '${paralizacion.servicioCodigo}${paralizacion.naveNombre != null ? ' - ${paralizacion.naveNombre}' : ''}',
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

          // Bodega badge + motivo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warehouse, size: 14, color: Colors.white),
                    const SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      paralizacion.bodega,
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
              if (paralizacion.jornadaStr != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    paralizacion.jornadaStr!,
                    style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize: DesignTokens.fontSizeXS,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceS),

          // Motivo
          Row(
            children: [
              const Icon(Icons.report_problem_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: DesignTokens.spaceXS),
              Expanded(
                child: Text(
                  paralizacion.motivoStr ?? 'Sin motivo',
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceS),

          // Inicio/Fin y duracion
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: DesignTokens.spaceXS),
              Text(
                paralizacion.inicio != null
                    ? dateTimeFormat.format(toLima(paralizacion.inicio!))
                    : '-',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              const Text(
                ' - ',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                paralizacion.fin != null
                    ? dateTimeFormat.format(toLima(paralizacion.fin!))
                    : '?',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              if (paralizacion.duracion != null) ...[
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
                    paralizacion.duracion!,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Observacion
          if (paralizacion.observacion != null && paralizacion.observacion!.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spaceS),
            const Divider(),
            Text(
              paralizacion.observacion!,
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
}
