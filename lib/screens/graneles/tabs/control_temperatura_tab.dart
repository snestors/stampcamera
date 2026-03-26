// =============================================================================
// TAB DE CONTROL DE TEMPERATURA — Placeholder
// TODO: Implementar cuando existan modelos, servicios y providers para
//       control de humedad/temperatura. API esperada: /api/v1/graneles/control-humedad/
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/core.dart';

class ControlTemperaturaTab extends ConsumerWidget {
  const ControlTemperaturaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AppEmptyState(
          icon: Icons.thermostat_outlined,
          title: 'Control de Temperatura',
          subtitle: 'Proximamente - Este modulo esta en desarrollo',
        ),
      ),
    );
  }
}
