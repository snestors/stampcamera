// =====================================================
// 5. widgets/pedeteo/empty_state_widget.dart
// =====================================================
import 'package:flutter/material.dart';

class PedeteoEmptyState extends StatelessWidget {
  const PedeteoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Busca por VIN o Serie',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'También puedes usar el scanner de código de barras',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
