// =====================================================
// 1. screens/pedeteo_screen.dart (archivo principal simplificado)
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/pedeteo/search_bar_widget.dart';
import 'package:stampcamera/widgets/pedeteo/scanner_widget.dart';
import 'package:stampcamera/widgets/pedeteo/registration_form_widget.dart';
import 'package:stampcamera/widgets/pedeteo/empty_state_widget.dart';

class PedeteoScreen extends ConsumerWidget {
  const PedeteoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pedeteoStateProvider);
    final optionsAsync = ref.watch(pedeteoOptionsProvider);

    // Loading state
    if (optionsAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando opciones...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (optionsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error al cargar opciones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${optionsAsync.error}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(pedeteoOptionsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda
          const PedeteoSearchBar(),

          // Scanner de códigos de barras
          if (state.showScanner) const Expanded(child: PedeteoScannerWidget()),

          // Formulario de registro
          if (state.showForm && !state.showScanner)
            const Expanded(child: PedeteoRegistrationForm()),

          // Estado inicial
          if (!state.showScanner && !state.showForm)
            const Expanded(child: PedeteoEmptyState()),
        ],
      ),
    );
  }
}
