// =====================================================
// screens/pedeteo_screen.dart - Con integración de ConnectionErrorScreen
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/widgets/pedeteo/search_bar_widget.dart';
import 'package:stampcamera/widgets/pedeteo/scanner_widget.dart';
import 'package:stampcamera/widgets/pedeteo/registration_form_widget.dart';
import 'package:stampcamera/widgets/pedeteo/empty_state_widget.dart';
import 'package:stampcamera/widgets/connection_error_screen.dart';

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

    // Error state - ConnectionErrorScreen maneja automáticamente todos los tipos de error
    if (optionsAsync.hasError) {
      return ConnectionErrorScreen(
        error: optionsAsync.error!,
        onRetry: () => ref.invalidate(pedeteoOptionsProvider),
      );
    }

    // Estado normal - Contenido principal
    return Column(
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
    );
  }
}
