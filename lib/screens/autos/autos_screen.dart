import 'package:flutter/material.dart';
import 'registro_screen.dart';
import 'pedeteo_screen.dart';

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
      appBar: AppBar(title: const Text('Autos')),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          RegistroScreen(),
          PedeteoScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'REGISTRO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'PEDETEO',
          ),
        ],
      ),
    );
  }
}
