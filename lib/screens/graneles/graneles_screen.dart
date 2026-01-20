// =============================================================================
// PANTALLA PRINCIPAL DE GRANELES
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/screens/graneles/tabs/servicios_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/tickets_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/balanzas_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/silos_tab.dart';

class GranelesScreen extends ConsumerStatefulWidget {
  const GranelesScreen({super.key});

  @override
  ConsumerState<GranelesScreen> createState() => _GranelesScreenState();
}

class _GranelesScreenState extends ConsumerState<GranelesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicioSeleccionado = ref.watch(servicioSeleccionadoProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Graneles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: DesignTokens.fontSizeXS,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: DesignTokens.fontSizeXS,
              ),
              tabs: const [
                Tab(text: 'SERVICIOS', icon: Icon(Icons.list_alt, size: 18)),
                Tab(text: 'TICKETS', icon: Icon(Icons.receipt_long, size: 18)),
                Tab(text: 'BALANZAS', icon: Icon(Icons.scale, size: 18)),
                Tab(text: 'SILOS', icon: Icon(Icons.storage, size: 18)),
              ],
            ),
          ),
        ),
        actions: [
          if (servicioSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Invalidar providers del servicio seleccionado
                ref.read(ticketsMuelleProvider.notifier).refresh();
                ref.invalidate(balanzasProvider(servicioSeleccionado.id));
                ref.invalidate(silosProvider(servicioSeleccionado.id));
              },
              tooltip: 'Actualizar datos',
            ),
        ],
      ),
      body: Column(
        children: [
          // Chip del servicio seleccionado
          if (servicioSeleccionado != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
                vertical: DesignTokens.spaceS,
              ),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.directions_boat, size: 16, color: AppColors.primary),
                  SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Text(
                      '${servicioSeleccionado.codigo} - ${servicioSeleccionado.naveNombre ?? "Sin nave"}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      ref.read(servicioSeleccionadoProvider.notifier).state = null;
                      _tabController.animateTo(0);
                    },
                    tooltip: 'Cambiar servicio',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const ServiciosTab(),
                const TicketsTab(),
                BalanzasTab(servicioId: servicioSeleccionado?.id),
                SilosTab(servicioId: servicioSeleccionado?.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
