import 'package:flutter/material.dart';
import 'package:stampcamera/screens/autos/contenedores/contenedores_tab.dart';
import 'package:stampcamera/screens/autos/pedeteo_screen.dart';
import 'package:stampcamera/screens/autos/inventario/inventario_screen.dart';
import 'package:stampcamera/theme/custom_colors.dart';
import 'package:stampcamera/widgets/pedeteo/queue_badget.dart';
import 'registro_general/registro_screen.dart';

// Importa tus archivos de tema

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
        title: const Text(
          'Autos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
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
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 9,
          ),

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note),
              activeIcon: Icon(Icons.edit_note, size: 26),
              label: 'REGISTRO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions_outlined),
              activeIcon: Icon(Icons.pending_actions, size: 26),
              label: 'PEDETEO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2, size: 26),
              label: 'CONTENEDORES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment, size: 26),
              label: 'INVENTARIOS',
            ),
          ],
        ),
      ),
    );
  }
}
