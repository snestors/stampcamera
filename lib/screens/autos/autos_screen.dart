import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/screens/autos/contenedores/contenedores_tab.dart';
import 'package:stampcamera/screens/autos/pedeteo_screen.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_screen.dart';
import 'package:stampcamera/widgets/pedeteo/queue_badget.dart';
import 'registro_general/registro_screen.dart';

/// Configuración de un tab dentro del módulo Autos
class _TabConfig {
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const _TabConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

class AutosScreen extends ConsumerStatefulWidget {
  const AutosScreen({super.key});

  @override
  ConsumerState<AutosScreen> createState() => _AutosScreenState();
}

class _AutosScreenState extends ConsumerState<AutosScreen> {
  PageController? _pageController;
  int _currentIndex = 0;

  /// Obtiene los tabs disponibles según los permisos del usuario
  List<_TabConfig> _getAvailableTabs() {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;
    final asistencia = user?.ultimaAsistenciaActiva;

    // Datos de la asistencia activa
    final zonaTipo = asistencia?.zonaTrabajoTipo;
    final naveRubro = asistencia?.naveRubro;
    final naveCategoriaRubro = asistencia?.naveCategoriaRubro;
    final tieneNaveAutos = naveCategoriaRubro == 'AUTOS';
    final isSuperuser = user?.isSuperuser ?? false;
    final isCoordinadorAutos = user?.groups.contains('COORDINACION AUTOS') ?? false;

    // Caso especial: Recepción = zona ALMACEN sin nave (NO incluye ALMACEN-PDI)
    // ALMACEN-PDI es solo para registro
    final esRecepcion = zonaTipo == 'ALMACEN' && naveCategoriaRubro == null;

    final tabs = <_TabConfig>[];

    // REGISTRO - Siempre disponible
    tabs.add(const _TabConfig(
      id: 'registro',
      label: 'REGISTRO',
      icon: Icons.edit_note,
      activeIcon: Icons.edit_note,
      screen: RegistroScreen(),
    ));

    // PEDETEO - Solo si rubro = FPR y zona = PUERTO (o superuser/coordinador)
    if (isSuperuser || isCoordinadorAutos || (naveRubro == 'FPR' && zonaTipo == 'PUERTO')) {
      tabs.add(const _TabConfig(
        id: 'pedeteo',
        label: 'PEDETEO',
        icon: Icons.pending_actions_outlined,
        activeIcon: Icons.pending_actions,
        screen: PedeteoScreen(),
      ));
    }

    // CONTENEDORES - Solo si tiene nave AUTOS activa (o superuser/coordinador)
    // En recepción (ALMACEN sin nave) NO se muestra contenedores
    if (isSuperuser || isCoordinadorAutos || tieneNaveAutos) {
      tabs.add(const _TabConfig(
        id: 'contenedores',
        label: 'CONTENEDORES',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        screen: ContenedoresTab(),
      ));
    }

    // INVENTARIOS - Disponible si tiene nave AUTOS o está en recepción (o superuser/coordinador)
    if (isSuperuser || isCoordinadorAutos || tieneNaveAutos || esRecepcion) {
      tabs.add(const _TabConfig(
        id: 'inventario',
        label: 'INVENTARIOS',
        icon: Icons.assessment_outlined,
        activeIcon: Icons.assessment,
        screen: InventarioScreen(),
      ));
    }

    return tabs;
  }

  void _onNavTapped(int index) {
    final tabs = _getAvailableTabs();
    if (index >= tabs.length) return;

    setState(() => _currentIndex = index);
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getAvailableTabs();

    // Recrear PageController si es necesario
    _pageController ??= PageController();

    // Asegurar que el índice actual sea válido
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    // Encontrar si el tab actual es pedeteo para mostrar el botón de refresh
    final currentTabId = tabs.isNotEmpty ? tabs[_currentIndex].id : '';

    // Si solo hay 1 tab, mostrar directamente sin BottomNavigationBar
    if (tabs.length == 1) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            'Autos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontSizeL,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: DesignTokens.spaceL),
              child: QueueBadge(),
            ),
          ],
        ),
        body: tabs.first.screen,
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Autos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeL,
          ),
        ),
        actions: [
          // Botón de refresh solo en pestaña de Pedeteo
          if (currentTabId == 'pedeteo')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(pedeteoOptionsProvider),
              tooltip: 'Actualizar opciones',
            ),
          Padding(
            padding: EdgeInsets.only(right: DesignTokens.spaceL),
            child: QueueBadge(),
          ),
        ],
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: tabs.map((tab) => tab.screen).toList(),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeXS * 0.8,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: DesignTokens.fontSizeXS * 0.75,
          ),
          items: tabs.map((tab) => BottomNavigationBarItem(
            icon: Icon(tab.icon),
            activeIcon: Icon(tab.activeIcon, size: DesignTokens.iconL),
            label: tab.label,
          )).toList(),
        ),
      ),
    );
  }
}
