import 'package:flutter/material.dart';
import 'package:stampcamera/screens/autos/contenedores/contenedores_tab.dart';
import 'package:stampcamera/screens/autos/pedeteo_screen.dart';
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
      appBar: AppBar(title: const Text('Autos'), actions: [QueueBadge()]),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [RegistroScreen(), PedeteoScreen(), ContenedoresTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'REGISTRO'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'PEDETEO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'CONTENEDORES',
          ),
        ],
      ),
    );
  }
}
