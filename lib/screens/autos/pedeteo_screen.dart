import 'package:flutter/material.dart';

class PedeteoScreen extends StatelessWidget {
  const PedeteoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'PEDETEO está en elaboración...',
        style: TextStyle(fontSize: 18, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}
