// =============================================================================
// TAB DE PARALIZACIONES — Placeholder
// TODO: Implementar cuando existan modelos, servicios y providers para
//       paralizaciones. API esperada: /api/v1/graneles/paralizaciones/
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';

class ParalizacionesTab extends ConsumerWidget {
  const ParalizacionesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AppEmptyState(
          icon: Icons.pause_circle_outline,
          title: 'Paralizaciones',
          subtitle: 'Proximamente - Este modulo esta en desarrollo',
        ),
      ),
    );
  }
}
