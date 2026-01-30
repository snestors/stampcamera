// =============================================================================
// PANTALLA PRINCIPAL DE GRANELES
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/graneles/graneles_provider.dart';
import 'package:stampcamera/services/graneles/graneles_service.dart';
import 'package:stampcamera/screens/graneles/tabs/servicios_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/tickets_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/balanzas_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/almacen_tab.dart';
import 'package:stampcamera/screens/graneles/tabs/silos_tab.dart';

/// Definición de tab con su configuración
class _TabConfig {
  final String key;
  final String label;
  final IconData icon;
  final Widget tab;

  const _TabConfig({
    required this.key,
    required this.label,
    required this.icon,
    required this.tab,
  });
}

class GranelesScreen extends ConsumerStatefulWidget {
  const GranelesScreen({super.key});

  @override
  ConsumerState<GranelesScreen> createState() => _GranelesScreenState();
}

class _GranelesScreenState extends ConsumerState<GranelesScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<_TabConfig> _visibleTabs = [];
  int _lastTabCount = 0;
  int _currentTabIndex = 0;

  /// Configuración completa de todos los tabs
  static const List<_TabConfig> _allTabs = [
    _TabConfig(
      key: 'servicios',
      label: 'Servicios',
      icon: Icons.list_alt,
      tab: ServiciosTab(),
    ),
    _TabConfig(
      key: 'muelle',
      label: 'Tickets',
      icon: Icons.receipt_long,
      tab: TicketsTab(),
    ),
    _TabConfig(
      key: 'balanza',
      label: 'Balanzas',
      icon: Icons.scale,
      tab: BalanzasTab(),
    ),
    _TabConfig(
      key: 'almacen',
      label: 'Almacén',
      icon: Icons.warehouse,
      tab: AlmacenTab(),
    ),
    _TabConfig(
      key: 'silos',
      label: 'Silos',
      icon: Icons.storage,
      tab: SilosTab(),
    ),
  ];

  void _updateTabs(UserGranelesPermissions permissions) {
    final visibleKeys = permissions.visibleTabs;
    final newVisibleTabs = _allTabs
        .where((tab) => visibleKeys.contains(tab.key))
        .toList();

    // Solo actualizar si cambió la cantidad de tabs
    if (newVisibleTabs.length != _lastTabCount) {
      _lastTabCount = newVisibleTabs.length;
      _visibleTabs = newVisibleTabs;

      // Disponer el controller anterior si existe
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();
      _tabController = null;

      if (_visibleTabs.isNotEmpty) {
        _tabController = TabController(
          length: _visibleTabs.length,
          vsync: this,
        );
        _tabController!.addListener(_onTabChanged);
      }
    }
  }

  void _onTabChanged() {
    if (_tabController != null && _currentTabIndex != _tabController!.index) {
      setState(() {
        _currentTabIndex = _tabController!.index;
      });
    }
  }

  /// Obtener el key del tab actual
  String? get _currentTabKey {
    if (_visibleTabs.isEmpty || _currentTabIndex >= _visibleTabs.length) {
      return null;
    }
    return _visibleTabs[_currentTabIndex].key;
  }

  /// Verificar si el tab actual tiene filtro de pendientes
  bool get _showPendingFilter {
    final key = _currentTabKey;
    return key == 'muelle' || key == 'balanza';
  }

  /// Obtener estado del filtro actual
  bool get _isPendingFilterActive {
    final key = _currentTabKey;
    if (key == 'muelle') {
      return ref.read(ticketsMuelleProvider.notifier).filterSinBalanza;
    } else if (key == 'balanza') {
      return ref.read(balanzasListProvider.notifier).filterSinAlmacen;
    }
    return false;
  }

  /// Toggle filtro de pendientes
  void _togglePendingFilter() {
    final key = _currentTabKey;
    if (key == 'muelle') {
      final notifier = ref.read(ticketsMuelleProvider.notifier);
      notifier.setFilterSinBalanza(!notifier.filterSinBalanza);
    } else if (key == 'balanza') {
      final notifier = ref.read(balanzasListProvider.notifier);
      notifier.setFilterSinAlmacen(!notifier.filterSinAlmacen);
    }
    setState(() {}); // Refresh UI
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(userGranelesPermissionsProvider);

    return permissionsAsync.when(
      loading: () => Scaffold(
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
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => _buildWithPermissions(
        UserGranelesPermissions.defaults(),
      ),
      data: (permissions) => _buildWithPermissions(permissions),
    );
  }

  Widget _buildWithPermissions(UserGranelesPermissions permissions) {
    // Actualizar tabs según permisos
    _updateTabs(permissions);

    // Si no hay tabs visibles, mostrar mensaje
    if (_visibleTabs.isEmpty || _tabController == null) {
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
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin acceso',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No tienes permisos para ver este módulo.\nContacta a tu coordinador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              'Graneles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: DesignTokens.fontSizeL,
              ),
            ),
            // Mostrar indicador de zona/rol si está disponible
            if (permissions.zonaTipo != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  permissions.zonaTipo!,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Botón de filtro pendientes (solo en tabs de tickets y balanzas)
          if (_showPendingFilter)
            IconButton(
              onPressed: _togglePendingFilter,
              icon: Icon(
                _isPendingFilterActive
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                color: _isPendingFilterActive ? Colors.amber : Colors.white,
              ),
              tooltip: _isPendingFilterActive
                  ? 'Mostrando solo pendientes'
                  : 'Filtrar pendientes',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _visibleTabs.map((tab) => tab.tab).toList(),
      ),
      bottomNavigationBar: Material(
        color: AppColors.primary,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: DesignTokens.fontSizeXS,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: DesignTokens.fontSizeXS,
              ),
              tabs: _visibleTabs
                  .map((tab) => Tab(
                        text: tab.label,
                        icon: Icon(tab.icon, size: 20),
                        iconMargin: const EdgeInsets.only(bottom: 2),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
