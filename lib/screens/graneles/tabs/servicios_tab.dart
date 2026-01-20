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

class ServiciosTab extends ConsumerStatefulWidget {
  const ServiciosTab({super.key});

  @override
  ConsumerState<ServiciosTab> createState() => _ServiciosTabState();
}

class _ServiciosTabState extends ConsumerState<ServiciosTab> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Cargar más cuando estamos cerca del final
      final notifier = ref.read(serviciosGranelesProvider.notifier);
      if (notifier.hasNextPage && !notifier.isLoadingMore) {
        notifier.loadMore();
      }
    }
  }

  List<ServicioGranel> _filterServicios(List<ServicioGranel> servicios) {
    if (_searchQuery.isEmpty) return servicios;

    final query = _searchQuery.toLowerCase();
    return servicios.where((s) {
      return s.codigo.toLowerCase().contains(query) ||
          (s.naveNombre?.toLowerCase().contains(query) ?? false) ||
          (s.consignatarioNombre?.toLowerCase().contains(query) ?? false) ||
          (s.puerto?.toLowerCase().contains(query) ?? false) ||
          s.productos.any((p) => p.producto.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final serviciosAsync = ref.watch(serviciosGranelesProvider);

    return serviciosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceL),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
            ),
            SizedBox(height: DesignTokens.spaceM),
            Text(
              'Error al cargar servicios',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: DesignTokens.spaceS),
            Text(
              'Verifica tu conexión e intenta nuevamente',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: DesignTokens.spaceL),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(serviciosGranelesProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceL,
                  vertical: DesignTokens.spaceS,
                ),
              ),
            ),
          ],
        ),
      ),
      data: (servicios) {
        if (servicios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_boat_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: DesignTokens.spaceM),
                Text(
                  'No hay servicios disponibles',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: DesignTokens.spaceS),
                Text(
                  'Marca asistencia en una nave de graneles',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final filteredServicios = _filterServicios(servicios);

        return Column(
          children: [
            // Barra de búsqueda
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Buscar por nave, código, consignatario...',
                  hintStyle: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceM,
                    vertical: DesignTokens.spaceS,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                style: TextStyle(fontSize: DesignTokens.fontSizeS),
              ),
            ),

            // Contador de resultados
            if (_searchQuery.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Text(
                  '${filteredServicios.length} de ${servicios.length} servicios',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Lista de servicios
            Expanded(
              child: filteredServicios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: DesignTokens.spaceM),
                          Text(
                            'Sin resultados para "$_searchQuery"',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeM,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await ref.read(serviciosGranelesProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(DesignTokens.spaceM),
                        itemCount: filteredServicios.length + 1,
                        itemBuilder: (context, index) {
                          // Indicador de carga al final
                          if (index == filteredServicios.length) {
                            final notifier = ref.read(serviciosGranelesProvider.notifier);
                            if (notifier.isLoadingMore) {
                              return Padding(
                                padding: EdgeInsets.all(DesignTokens.spaceM),
                                child: const Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              );
                            }
                            if (notifier.hasNextPage && _searchQuery.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.all(DesignTokens.spaceM),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () => notifier.loadMore(),
                                    icon: const Icon(Icons.expand_more),
                                    label: const Text('Cargar más'),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final servicio = filteredServicios[index];
                          return _ServicioCard(
                            servicio: servicio,
                            searchQuery: _searchQuery,
                            onTap: () {
                              context.push('/graneles/servicio/${servicio.id}/dashboard');
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ServicioCard extends StatelessWidget {
  final ServicioGranel servicio;
  final VoidCallback onTap;
  final String searchQuery;

  const _ServicioCard({
    required this.servicio,
    required this.onTap,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con gradiente
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusL),
                    topRight: Radius.circular(DesignTokens.radiusL),
                  ),
                ),
                child: Row(
                  children: [
                    // Icono de nave
                    Container(
                      padding: EdgeInsets.all(DesignTokens.spaceS),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                      child: const Icon(
                        Icons.directions_boat,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceM),
                    // Nombre de nave y código
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio.naveNombre ?? 'Sin nave',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeM,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: DesignTokens.spaceXS),
                          Text(
                            servicio.codigo,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeS,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Estado y tickets
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (servicio.cierreServicio)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceS,
                              vertical: DesignTokens.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                            ),
                            child: Text(
                              'CERRADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: DesignTokens.fontSizeXS,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceS,
                              vertical: DesignTokens.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                            ),
                            child: Text(
                              'ACTIVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: DesignTokens.fontSizeXS,
                              ),
                            ),
                          ),
                        SizedBox(height: DesignTokens.spaceXS),
                        Text(
                          '${servicio.totalTickets} tickets',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido
              Padding(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info row: Consignatario
                    _InfoRow(
                      icon: Icons.business,
                      label: 'Consignatario',
                      value: servicio.consignatarioNombre ?? 'Sin consignatario',
                    ),
                    SizedBox(height: DesignTokens.spaceS),

                    // Info row: Puerto y fecha
                    Row(
                      children: [
                        Expanded(
                          child: _InfoRow(
                            icon: Icons.location_on,
                            label: 'Puerto',
                            value: servicio.puerto ?? 'Sin puerto',
                          ),
                        ),
                        Expanded(
                          child: _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Atraque',
                            value: servicio.fechaAtraque != null
                                ? dateFormat.format(servicio.fechaAtraque!)
                                : 'Sin fecha',
                          ),
                        ),
                      ],
                    ),

                    // Productos
                    if (servicio.productos.isNotEmpty) ...[
                      SizedBox(height: DesignTokens.spaceM),
                      Divider(color: AppColors.neutral.withValues(alpha: 0.3)),
                      SizedBox(height: DesignTokens.spaceS),
                      Row(
                        children: [
                          Icon(
                            Icons.grain,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: DesignTokens.spaceXS),
                          Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeXS,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: DesignTokens.spaceS),
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
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
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

              // Footer con acción
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(DesignTokens.radiusL),
                    bottomRight: Radius.circular(DesignTokens.radiusL),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver Dashboard',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        SizedBox(width: DesignTokens.spaceXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
