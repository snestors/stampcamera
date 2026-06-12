// =====================================================
// screens/pedeteo_screen.dart - Con integración de ConnectionErrorScreen
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/pedeteo/search_bar_widget.dart';
import 'package:stampcamera/widgets/pedeteo/scanner_widget.dart';
import 'package:stampcamera/widgets/pedeteo/registration_form_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

class PedeteoScreen extends ConsumerWidget {
  const PedeteoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedeteoStateProvider);
    final optionsAsync = ref.watch(pedeteoOptionsProvider);

    // Loading state
    if (optionsAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando opciones...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Error state - ConnectionErrorScreen maneja automáticamente todos los tipos de error
    if (optionsAsync.hasError) {
      return ConnectionErrorScreen(
        error: optionsAsync.error!,
        onRetry: () => ref.invalidate(pedeteoOptionsProvider),
      );
    }

    // Estado normal - Contenido principal
    final vinsDisponibles = optionsAsync.value?.vinsDisponibles ?? [];
    final pedeteadosEnSesion = ref.watch(pedeteadosEnSesionProvider);
    final naveFilter = ref.watch(pedeteoNaveFilterProvider);
    final marcaFilter = ref.watch(pedeteoMarcaFilterProvider);
    final modeloFilter = ref.watch(pedeteoModeloFilterProvider);

    // Aplicar filtro local por nave/marca/modelo
    final vinsFiltrados = vinsDisponibles.where((v) {
      final naveOk = naveFilter == null || v.naveDescarga == naveFilter;
      final marcaOk = marcaFilter == null || v.marca == marcaFilter;
      final modeloOk = modeloFilter == null || v.modelo == modeloFilter;
      return naveOk && marcaOk && modeloOk;
    }).toList();

    // Filtrar: pedeteados del servidor + pedeteados en esta sesión
    final vinsPedeteados = vinsFiltrados
        .where((v) => v.pedeteado || pedeteadosEnSesion.contains(v.vin))
        .toList();

    final vinsNoPedeteados = vinsFiltrados
        .where((v) => !v.pedeteado && !pedeteadosEnSesion.contains(v.vin))
        .toList();

    return Column(
      children: [
        // Barra de búsqueda
        const PedeteoSearchBar(),

        // Filtros por nave/marca/modelo + dashboard (solo en vista de lista)
        if (!state.showScanner && !state.showForm) ...[
          _buildFilters(
            ref,
            vinsDisponibles,
            naveFilter,
            marcaFilter,
            modeloFilter,
          ),
          _buildDashboard(
            vinsPedeteados.length,
            vinsNoPedeteados.length,
            hasFilter: naveFilter != null ||
                marcaFilter != null ||
                modeloFilter != null,
          ),
        ],

        // Scanner de códigos de barras
        if (state.showScanner) const Expanded(child: PedeteoScannerWidget()),

        // Formulario de registro
        if (state.showForm && !state.showScanner)
          const Expanded(child: PedeteoRegistrationForm()),

        // Lista de VINs
        if (!state.showScanner && !state.showForm)
          Expanded(
            child: _buildVinsList(
              vinsNoPedeteados,
              vinsPedeteados,
              pedeteadosEnSesion,
            ),
          ),
      ],
    );
  }

  /// Filtros por nave, marca y modelo (sobre los VINs disponibles)
  Widget _buildFilters(
    WidgetRef ref,
    List<RegistroGeneral> vinsDisponibles,
    String? naveFilter,
    String? marcaFilter,
    String? modeloFilter,
  ) {
    // Naves únicas disponibles
    final naves =
        vinsDisponibles
            .map((v) => v.naveDescarga)
            .whereType<String>()
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // Marcas únicas (limitadas a la nave seleccionada si hay)
    final marcas =
        vinsDisponibles
            .where((v) => naveFilter == null || v.naveDescarga == naveFilter)
            .map((v) => v.marca)
            .whereType<String>()
            .where((m) => m.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // Modelos únicos (limitados a nave y marca seleccionadas si hay)
    final modelos =
        vinsDisponibles
            .where((v) => naveFilter == null || v.naveDescarga == naveFilter)
            .where((v) => marcaFilter == null || v.marca == marcaFilter)
            .map((v) => v.modelo)
            .whereType<String>()
            .where((m) => m.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceM,
        DesignTokens.spaceS,
        DesignTokens.spaceM,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              label: 'Nave',
              icon: Icons.directions_boat,
              value: naveFilter,
              options: naves,
              onSelected: (value) {
                ref.read(pedeteoNaveFilterProvider.notifier).state = value;
                // Resetear marca y modelo al cambiar de nave
                ref.read(pedeteoMarcaFilterProvider.notifier).state = null;
                ref.read(pedeteoModeloFilterProvider.notifier).state = null;
              },
            ),
          ),
          const SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: _buildFilterDropdown(
              label: 'Marca',
              icon: Icons.directions_car,
              value: marcaFilter,
              options: marcas,
              onSelected: (value) {
                ref.read(pedeteoMarcaFilterProvider.notifier).state = value;
                // Resetear modelo al cambiar de marca
                ref.read(pedeteoModeloFilterProvider.notifier).state = null;
              },
            ),
          ),
          const SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: _buildFilterDropdown(
              label: 'Modelo',
              icon: Icons.commute,
              value: modeloFilter,
              options: modelos,
              onSelected: (value) {
                ref.read(pedeteoModeloFilterProvider.notifier).state = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> options,
    required void Function(String?) onSelected,
  }) {
    final isActive = value != null;

    return PopupMenuButton<String?>(
      tooltip: 'Filtrar por $label',
      onSelected: (selected) =>
          onSelected(selected == '__todos__' ? null : selected),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: '__todos__',
          child: Text(
            'Todos',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: !isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        ...options.map(
          (option) => PopupMenuItem<String?>(
            value: option,
            child: Text(
              option,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight:
                    option == value ? FontWeight.bold : FontWeight.normal,
                color: option == value ? AppColors.primary : null,
              ),
            ),
          ),
        ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.neutral,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: DesignTokens.iconS,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: DesignTokens.spaceXS),
            Expanded(
              child: Text(
                value ?? label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: DesignTokens.iconS,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de VINs con secciones: pendientes y pedeteados
  Widget _buildVinsList(
    List<RegistroGeneral> noPedeteados,
    List<RegistroGeneral> pedeteados,
    Set<String> pedeteadosEnSesion,
  ) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      children: [
        // Sección: Pendientes
        if (noPedeteados.isNotEmpty) ...[
          _buildSectionHeader(
            'Pendientes',
            noPedeteados.length,
            Icons.pending,
            AppColors.warning,
          ),
          ...noPedeteados.map((v) => _buildVinTile(v, false, false)),
          const SizedBox(height: DesignTokens.spaceL),
        ],

        // Sección: Ya pedeteados
        if (pedeteados.isNotEmpty) ...[
          _buildSectionHeader(
            'Pedeteados',
            pedeteados.length,
            Icons.check_circle,
            AppColors.success,
          ),
          ...pedeteados.map(
            (v) => _buildVinTile(
              v,
              true,
              pedeteadosEnSesion.contains(v.vin), // Marcado en esta sesión
            ),
          ),
        ],

        // Estado vacío si no hay nada
        if (noPedeteados.isEmpty && pedeteados.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No hay VINs disponibles'),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceS),
      child: Row(
        children: [
          Icon(icon, color: color, size: DesignTokens.iconS),
          const SizedBox(width: DesignTokens.spaceXS),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceXS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinTile(
    RegistroGeneral vin,
    bool isPedeteado,
    bool pedeteadoEnSesion,
  ) {
    final color = isPedeteado ? AppColors.success : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceXS),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: isPedeteado
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icono de estado
          Icon(
            isPedeteado ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: DesignTokens.iconS,
          ),
          const SizedBox(width: DesignTokens.spaceS),

          // VIN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vin.vin,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                if (vin.marca != null || vin.modelo != null)
                  Text(
                    '${vin.marca ?? ''} ${vin.modelo ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Badge si fue pedeteado en esta sesión
          if (pedeteadoEnSesion)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: const Text(
                'NUEVO',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS * 0.9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Dashboard: conteos pendientes/pedeteados + barra de avance.
  /// Refleja los filtros de nave/marca/modelo activos.
  Widget _buildDashboard(
    int pedeteados,
    int pendientes, {
    required bool hasFilter,
  }) {
    final total = pedeteados + pendientes;
    final progreso = total > 0 ? pedeteados / total : 0.0;
    final porcentaje = (progreso * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.spaceM,
        DesignTokens.spaceS,
        DesignTokens.spaceM,
        DesignTokens.spaceXS,
      ),
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildDashboardStat(
                Icons.check_circle,
                pedeteados,
                'Pedeteados',
              ),
              _buildStatDivider(),
              _buildDashboardStat(
                Icons.pending_actions,
                pendientes,
                'Pendientes',
              ),
              _buildStatDivider(),
              _buildDashboardStat(
                hasFilter ? Icons.filter_alt : Icons.inventory_2,
                total,
                hasFilter ? 'Filtrados' : 'Total',
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceM),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceS),
              Text(
                '$porcentaje%',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStat(IconData icon, int count, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: DesignTokens.iconM, color: Colors.white),
          const SizedBox(height: DesignTokens.spaceXXS),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}
