// =============================================================================
// TAB DE CONTROL DE TEMPERATURA/HUMEDAD - CON BUSQUEDA E INFINITE SCROLL
// =============================================================================
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';
import 'package:stampcamera/widgets/common/fullscreen_image_viewer.dart';
import 'package:stampcamera/widgets/common/search_bar_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class ControlTemperaturaTab extends ConsumerStatefulWidget {
  const ControlTemperaturaTab({super.key});

  @override
  ConsumerState<ControlTemperaturaTab> createState() => _ControlTemperaturaTabState();
}

class _ControlTemperaturaTabState extends ConsumerState<ControlTemperaturaTab> {
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
      final notifier = ref.read(controlHumedadListProvider.notifier);

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
    final listAsync = ref.watch(controlHumedadListProvider);
    final notifier = ref.read(controlHumedadListProvider.notifier);
    final permissionsAsync = ref.watch(userGranelesPermissionsProvider);
    final canAdd = permissionsAsync.valueOrNull?.controlHumedad.canAdd ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Buscar por distribucion, jornada...',
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
              heroTag: 'fab_control_humedad',
              onPressed: () => context.push('/graneles/control-humedad/crear'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Nuevo Registro',
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
    AsyncValue<List<ControlHumedad>> listAsync,
    ControlHumedadNotifier notifier,
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
    List<ControlHumedad> items,
    ControlHumedadNotifier notifier,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(notifier);
    }

    final showLoadMoreIndicator = notifier.hasNextPage;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
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
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: _ControlHumedadCard(
                control: item,
                onTap: () => _showDetailSheet(item),
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

  Widget _buildEmptyState(ControlHumedadNotifier notifier) {
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: AppEmptyState(
        icon: isSearching ? Icons.search_off : Icons.thermostat_outlined,
        title: isSearching ? 'Sin resultados' : 'No hay registros',
        subtitle: isSearching
            ? 'No se encontraron registros que coincidan con "${_searchController.text}"'
            : 'Aun no hay registros de control de temperatura/humedad',
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

  void _showDetailSheet(ControlHumedad c) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final permissionsAsync = ref.read(userGranelesPermissionsProvider);
    final canEdit = permissionsAsync.valueOrNull?.controlHumedad.canEdit ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(DesignTokens.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Titulo
              Row(
                children: [
                  Icon(Icons.thermostat, color: AppColors.primary),
                  SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Text(
                      'Control Temperatura / Humedad',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceM),

              // Servicio
              if (c.servicioCodigo != null) ...[
                _detailRow(Icons.directions_boat, 'Servicio',
                    '${c.servicioCodigo}${c.naveNombre != null ? ' - ${c.naveNombre}' : ''}'),
                SizedBox(height: DesignTokens.spaceS),
              ],

              _detailRow(Icons.category, 'Distribucion', c.distribucionStr ?? '-'),
              SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.schedule, 'Jornada', c.jornadaStr ?? '-'),
              SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.access_time, 'Hora muestra',
                  c.horaMuestra != null ? dateTimeFormat.format(toLima(c.horaMuestra!)) : '-'),
              SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.thermostat, 'Temperatura',
                  c.temperatura != null ? '${c.temperatura!.toStringAsFixed(1)} C' : '-'),
              SizedBox(height: DesignTokens.spaceS),
              _detailRow(Icons.water_drop, 'Humedad',
                  c.humedad != null ? '${c.humedad!.toStringAsFixed(1)} %' : '-'),

              if (c.observaciones != null && c.observaciones!.isNotEmpty) ...[
                SizedBox(height: DesignTokens.spaceS),
                _detailRow(Icons.notes, 'Observaciones', c.observaciones!),
              ],

              // Fotos
              if (c.fotoTemperaturaUrl != null || c.fotoHumedadUrl != null || c.fotoExtraUrl != null) ...[
                SizedBox(height: DesignTokens.spaceM),
                const Divider(),
                SizedBox(height: DesignTokens.spaceS),
                Text(
                  'Fotos',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: DesignTokens.spaceS),
                Wrap(
                  spacing: DesignTokens.spaceS,
                  runSpacing: DesignTokens.spaceS,
                  children: [
                    if (c.fotoTemperaturaUrl != null)
                      _photoThumb(context, c.fotoTemperaturaUrl!, 'Temperatura'),
                    if (c.fotoHumedadUrl != null)
                      _photoThumb(context, c.fotoHumedadUrl!, 'Humedad'),
                    if (c.fotoExtraUrl != null)
                      _photoThumb(context, c.fotoExtraUrl!, 'Extra'),
                  ],
                ),
              ],

              if (c.createByNombre != null) ...[
                SizedBox(height: DesignTokens.spaceM),
                const Divider(),
                SizedBox(height: DesignTokens.spaceS),
                Text(
                  'Creado por: ${c.createByNombre}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (c.createAt != null)
                  Text(
                    dateTimeFormat.format(toLima(c.createAt!)),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],

              // Boton editar
              if (canEdit) ...[
                SizedBox(height: DesignTokens.spaceL),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    text: 'Editar',
                    icon: Icons.edit,
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/graneles/control-humedad/editar/${c.id}');
                    },
                  ),
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
        SizedBox(width: DesignTokens.spaceS),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoThumb(BuildContext context, String url, String title) {
    return GestureDetector(
      onTap: () => FullscreenImageViewer.open(context, imageUrl: url, title: title),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 80,
            height: 80,
            color: AppColors.surface,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 80,
            height: 80,
            color: AppColors.surface,
            child: Icon(Icons.broken_image, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CONTROL HUMEDAD CARD
// =============================================================================

class _ControlHumedadCard extends ConsumerWidget {
  final ControlHumedad control;
  final VoidCallback onTap;

  const _ControlHumedadCard({
    required this.control,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final hasFotos = control.fotoTemperaturaUrl != null ||
        control.fotoHumedadUrl != null ||
        control.fotoExtraUrl != null;

    return AppCard.elevated(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail de la primera foto disponible
          if (hasFotos) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              child: CachedNetworkImage(
                imageUrl: control.fotoTemperaturaUrl ??
                    control.fotoHumedadUrl ??
                    control.fotoExtraUrl!,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.surface,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.surface,
                  child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spaceM),
          ],

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Servicio
                if (control.servicioCodigo != null) ...[
                  Row(
                    children: [
                      Icon(Icons.directions_boat, size: 14, color: AppColors.accent),
                      SizedBox(width: DesignTokens.spaceXS),
                      Expanded(
                        child: Text(
                          '${control.servicioCodigo}${control.naveNombre != null ? ' - ${control.naveNombre}' : ''}',
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
                  SizedBox(height: DesignTokens.spaceXS),
                ],

                // Distribucion + Jornada
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        control.distribucionStr ?? 'Sin distribucion',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (control.jornadaStr != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                        child: Text(
                          control.jornadaStr!,
                          style: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                            fontSize: DesignTokens.fontSizeXS,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),

                // Temperatura y Humedad badges
                Row(
                  children: [
                    // Temperatura
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceS,
                        vertical: DesignTokens.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.thermostat, size: 14, color: AppColors.error),
                          SizedBox(width: DesignTokens.spaceXS),
                          Text(
                            control.temperatura != null
                                ? '${control.temperatura!.toStringAsFixed(1)} C'
                                : '- C',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeS,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    // Humedad
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceS,
                        vertical: DesignTokens.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop, size: 14, color: AppColors.info),
                          SizedBox(width: DesignTokens.spaceXS),
                          Text(
                            control.humedad != null
                                ? '${control.humedad!.toStringAsFixed(1)} %'
                                : '- %',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeS,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS),

                // Hora muestra
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                    SizedBox(width: DesignTokens.spaceXS),
                    Text(
                      control.horaMuestra != null
                          ? dateTimeFormat.format(toLima(control.horaMuestra!))
                          : 'Sin hora',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
