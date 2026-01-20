import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/widgets/autos/detalle_info_general.dart';
import 'package:stampcamera/widgets/autos/detalle_registros_vin.dart';
import 'package:stampcamera/widgets/autos/detalle_fotos_presentacion.dart';
import 'package:stampcamera/widgets/autos/detalle_danos.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';
import 'package:stampcamera/widgets/common/offline_sync_indicator.dart';

class DetalleRegistroScreen extends ConsumerWidget {
  final String vin;

  const DetalleRegistroScreen({super.key, required this.vin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(detalleRegistroProvider(vin));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        //backgroundColor: AppColors.backgroundLight,
        appBar: _buildAppBar(context, ref, detalleAsync),
        body: Column(
          children: [
            // Banner de sincronizacion offline
            const OfflineSyncBanner(),
            // Contenido principal
            Expanded(
              child: detalleAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, _) =>
                    ConnectionErrorScreen(onRetry: () => _refreshData(context, ref)),
                data: (registro) => _buildTabContent(registro, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // APP BAR CON TABS INTEGRADAS
  // ============================================================================
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue detalleAsync,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Cuadrado sin bordes
      ),
      title: Text(
        vin,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: DesignTokens.fontSizeM,
        ),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: OfflineSyncIndicator(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshData(context, ref),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.primary,
          child: detalleAsync.when(
            loading: () => _buildLoadingTabs(),
            error: (error, stackTrace) => _buildErrorTabs(),
            data: (registro) => _buildTabs(registro),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(DetalleRegistroModel registro) {
    return TabBar(
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: DesignTokens.fontSizeXS * 0.7,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: DesignTokens.fontSizeXS * 0.7,
      ),
      tabs: [
        const Tab(
          icon: Icon(Icons.info_outline, size: DesignTokens.iconXXL),
          text: 'General',
        ),
        Tab(
          child: _buildTabWithBadge(
            icon: Icons.history,
            text: 'Historial',
            count: registro.registrosVin.length,
          ),
        ),
        Tab(
          child: _buildTabWithBadge(
            icon: Icons.photo_library,
            text: 'Fotos',
            count: registro.fotosPresentacion.length,
          ),
        ),
        Tab(
          child: _buildTabWithBadge(
            icon: Icons.warning_outlined,
            text: 'Daños',
            count: registro.danos.length,
            isWarning: registro.danos.isNotEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildTabWithBadge({
    required IconData icon,
    required String text,
    required int count,
    bool isWarning = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: DesignTokens.iconXXL, color: Colors.white),
            const SizedBox(height: 2),
            Text(text),
          ],
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -2,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceXS,
                vertical: DesignTokens.spaceXXS,
              ),
              decoration: BoxDecoration(
                color: isWarning ? AppColors.error : AppColors.secondary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
                border: Border.all(
                  color: Colors.white,
                  width: DesignTokens.borderWidthNormal,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: DesignTokens.iconM,
                minHeight: DesignTokens.iconM,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontSizeM * 0.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingTabs() {
    return const TabBar(
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      tabs: [
        Tab(icon: Icon(Icons.info_outline, size: 16), text: 'General'),
        Tab(icon: Icon(Icons.history, size: 16), text: 'Historial'),
        Tab(icon: Icon(Icons.photo_library, size: 16), text: 'Fotos'),
        Tab(icon: Icon(Icons.warning_outlined, size: 16), text: 'Daños'),
      ],
    );
  }

  Widget _buildErrorTabs() {
    return const TabBar(
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      tabs: [
        Tab(icon: Icon(Icons.info_outline, size: 16), text: 'General'),
        Tab(icon: Icon(Icons.history, size: 16), text: 'Historial'),
        Tab(icon: Icon(Icons.photo_library, size: 16), text: 'Fotos'),
        Tab(icon: Icon(Icons.warning_outlined, size: 16), text: 'Daños'),
      ],
    );
  }

  // ============================================================================
  // CONTENIDO DE TABS
  // ============================================================================
  Widget _buildTabContent(DetalleRegistroModel registro, WidgetRef ref) {
    return TabBarView(
      children: [
        _buildScrollableTab(
          child: DetalleInfoGeneral(r: registro),
          ref: ref,
        ),
        _buildScrollableTab(
          child: DetalleRegistrosVin(items: registro.registrosVin, vin: vin),
          ref: ref,
        ),
        _buildScrollableTab(
          child: DetalleFotosPresentacion(
            items: registro.fotosPresentacion,
            vin: vin,
          ),
          ref: ref,
        ),
        _buildScrollableTab(
          child: DetalleDanos(danos: registro.danos, vin: registro.vin),
          ref: ref,
        ),
      ],
    );
  }

  Widget _buildScrollableTab({required Widget child, required WidgetRef ref}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      physics: const AlwaysScrollableScrollPhysics(),
      child: child,
    );
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================
  void _refreshData(BuildContext context, WidgetRef ref) {
    ref.read(detalleRegistroProvider(vin).notifier).refresh();
    AppSnackBar.info(context, 'Actualizando datos...');
  }
}
