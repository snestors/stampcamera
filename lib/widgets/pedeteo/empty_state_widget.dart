// =====================================================
// 5. widgets/pedeteo/empty_state_widget.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:stampcamera/core/widgets/common/app_empty_state.dart';

/// Legacy wrapper — delegates to the core [AppEmptyState] widget.
class PedeteoEmptyState extends StatelessWidget {
  const PedeteoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppEmptyState(
        icon: Icons.search,
        title: 'Busca por VIN o Serie',
        subtitle: 'También puedes usar el scanner de código de barras',
      ),
    );
  }
}
