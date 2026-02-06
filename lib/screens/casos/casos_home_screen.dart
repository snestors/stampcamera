// =============================================================================
// CASOS HOME SCREEN - Pantalla principal del Explorador de Archivos
// =============================================================================
//
// Nivel 1: Lista de rubros (Maritimo, Terrestre, Carga General...)
// Nivel 2: Carpetas del rubro seleccionado
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/casos/explorador_models.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/providers/casos/explorador_provider.dart';

class CasosHomeScreen extends ConsumerStatefulWidget {
  const CasosHomeScreen({super.key});

  @override
  ConsumerState<CasosHomeScreen> createState() => _CasosHomeScreenState();
}

class _CasosHomeScreenState extends ConsumerState<CasosHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exploradorProvider.notifier).loadCarpetasRaiz();
      // Suscribir al canal 'casos' y notificar ruta
      ref.read(appSocketProvider.notifier).subscribe('casos');
      ref.read(appSocketProvider.notifier).notifyRouteChange('/app/casos');
    });
  }

  @override
  void dispose() {
    // Des-suscribir del canal 'casos' al salir del módulo
    ref.read(appSocketProvider.notifier).unsubscribe('casos');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploradorProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          state.selectedRubro ?? 'Casos y Documentos',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: state.selectedRubro != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(exploradorProvider.notifier).goToInicio();
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              ),
        actions: [
          _buildConnectionIndicator(),
          if (state.selectedRubro != null) ...[
            IconButton(
              icon: Icon(
                state.viewMode == ViewMode.list
                    ? Icons.grid_view
                    : Icons.list,
                size: 22,
              ),
              onPressed: () {
                ref.read(exploradorProvider.notifier).toggleViewMode();
              },
              tooltip: state.viewMode == ViewMode.list
                  ? 'Vista cuadrícula'
                  : 'Vista lista',
            ),
          ],
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildConnectionIndicator() {
    final socketState = ref.watch(appSocketProvider);
    final Color color;
    final String tooltip;

    if (socketState.isConnected) {
      color = AppColors.success;
      tooltip = 'Conectado en tiempo real';
    } else if (socketState.isReconnecting) {
      color = Colors.orange;
      tooltip = 'Reconectando...';
    } else {
      color = Colors.red;
      tooltip = 'Sin conexión';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ExplorerState state) {
    if (state.carpetasState == LoadingState.loading) {
      return const Center(
        child: AppLoadingState(message: 'Cargando casos...'),
      );
    }

    if (state.carpetasState == LoadingState.error) {
      return Center(
        child: AppErrorState(
          message: state.errorMessage ?? 'Error al cargar',
          onRetry: () {
            ref.read(exploradorProvider.notifier).loadCarpetasRaiz();
          },
        ),
      );
    }

    if (state.selectedRubro == null) {
      return _buildRubrosList(state);
    }

    return _buildCarpetasList(state);
  }

  // ─── Nivel 1: Rubros ────────────────────────────────────────────────

  Widget _buildRubrosList(ExplorerState state) {
    if (state.rubros.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.folder_off_outlined,
          title: 'Sin casos',
          subtitle: 'No hay casos disponibles',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(exploradorProvider.notifier).loadCarpetasRaiz(),
      child: ListView.builder(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        itemCount: state.rubros.length,
        itemBuilder: (context, index) {
          final rubro = state.rubros[index];
          return _RubroCard(
            rubro: rubro,
            onTap: () {
              ref.read(exploradorProvider.notifier).selectRubro(rubro.nombre);
            },
          );
        },
      ),
    );
  }

  // ─── Nivel 2: Carpetas del rubro ────────────────────────────────────

  Widget _buildCarpetasList(ExplorerState state) {
    final carpetas = state.carpetasDelRubro;

    if (carpetas.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.folder_open_outlined,
          title: 'Sin carpetas',
          subtitle: 'No hay carpetas en ${state.selectedRubro}',
        ),
      );
    }

    // Filtrar por búsqueda
    final filtered = state.searchQuery.isEmpty
        ? carpetas
        : carpetas.where((c) {
            final q = state.searchQuery.toLowerCase();
            return c.nombre.toLowerCase().contains(q) ||
                (c.casoInfo?.nCaso.toLowerCase().contains(q) ?? false) ||
                (c.casoInfo?.asuntoDetalle?.toLowerCase().contains(q) ??
                    false);
          }).toList();

    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar caso...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                borderSide: BorderSide(color: AppColors.neutral),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                borderSide: BorderSide(color: AppColors.neutral),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
                vertical: DesignTokens.spaceS,
              ),
            ),
            onChanged: (value) {
              ref.read(exploradorProvider.notifier).setSearchQuery(value);
            },
          ),
        ),

        // Contador
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
          child: Row(
            children: [
              Text(
                '${filtered.length} carpeta${filtered.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: DesignTokens.spaceS),

        // Lista
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(exploradorProvider.notifier).loadCarpetasRaiz(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final carpeta = filtered[index];
                return _CarpetaRaizCard(
                  carpeta: carpeta,
                  onTap: () {
                    context.push('/casos/explorador/${carpeta.id}');
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────

class _RubroCard extends StatelessWidget {
  final RubroGroup rubro;
  final VoidCallback onTap;

  const _RubroCard({required this.rubro, required this.onTap});

  IconData _getIcon() {
    final nombre = rubro.nombre.toLowerCase();
    if (nombre.contains('marítimo') || nombre.contains('maritimo')) {
      return Icons.sailing;
    }
    if (nombre.contains('terrestre')) return Icons.local_shipping;
    if (nombre.contains('carga')) return Icons.inventory_2;
    if (nombre.contains('aéreo') || nombre.contains('aereo')) {
      return Icons.flight;
    }
    return Icons.folder_special;
  }

  Color _getColor() {
    final nombre = rubro.nombre.toLowerCase();
    if (nombre.contains('marítimo') || nombre.contains('maritimo')) {
      return AppColors.primary;
    }
    if (nombre.contains('terrestre')) return AppColors.warning;
    if (nombre.contains('carga')) return AppColors.accent;
    if (nombre.contains('aéreo') || nombre.contains('aereo')) {
      return AppColors.info;
    }
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Card(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spaceL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(_getIcon(), color: color, size: 28),
              ),
              SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rubro.nombre,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeRegular,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spaceXS),
                    Text(
                      '${rubro.count} caso${rubro.count != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarpetaRaizCard extends StatelessWidget {
  final Carpeta carpeta;
  final VoidCallback onTap;

  const _CarpetaRaizCard({required this.carpeta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceS),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(
                  Icons.folder,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carpeta.casoInfo?.nCaso ?? carpeta.nombre,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (carpeta.casoInfo?.asuntoDetalle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        carpeta.casoInfo!.asuntoDetalle!,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: DesignTokens.spaceXS),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.folder_open,
                          label: '${carpeta.subcarpetasCount}',
                        ),
                        SizedBox(width: DesignTokens.spaceS),
                        _InfoChip(
                          icon: Icons.insert_drive_file,
                          label: '${carpeta.archivosCount}',
                        ),
                        SizedBox(width: DesignTokens.spaceS),
                        _InfoChip(
                          icon: Icons.data_usage,
                          label: carpeta.totalSizeDisplay,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textLight),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS * 0.9,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
