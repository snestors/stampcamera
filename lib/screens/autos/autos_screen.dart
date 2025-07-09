import 'package:flutter/material.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/screens/autos/contenedores/contenedores_tab.dart';
import 'package:stampcamera/screens/autos/pedeteo_screen.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_screen.dart';
import 'package:stampcamera/widgets/pedeteo/queue_badget.dart';
import 'registro_general/registro_screen.dart';

class AutosScreen extends StatefulWidget {
  const AutosScreen({super.key});

  @override
  State<AutosScreen> createState() => _AutosScreenState();
}

class _AutosScreenState extends State<AutosScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onNavTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar corporativo usando tu guía de estilos
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

      // Fondo corporativo
      backgroundColor: AppColors.backgroundLight,

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.02),
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: const [
            RegistroScreen(),
            PedeteoScreen(),
            ContenedoresTab(),
            InventarioScreen(),
          ],
        ),
      ),

      // BottomNavigationBar corporativo
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

          // Colores corporativos
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,

          // Estilo de labels
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DesignTokens.fontSizeXS * 0.8,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: DesignTokens.fontSizeXS * 0.75,
          ),

          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.edit_note),
              activeIcon: Icon(Icons.edit_note, size: DesignTokens.iconL),
              label: 'REGISTRO',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pending_actions_outlined),
              activeIcon: Icon(Icons.pending_actions, size: DesignTokens.iconL),
              label: 'PEDETEO',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2, size: DesignTokens.iconL),
              label: 'CONTENEDORES',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment, size: DesignTokens.iconL),
              label: 'INVENTARIOS',
            ),
          ],
        ),
      ),
    );
  }
}
