// ============================================================================
// 🌾 GRANOS PROVIDER - GESTIÓN DE ESTADO DEL MÓDULO GRANOS
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado del módulo de granos
/// Actualmente vacío, se expandirá cuando el módulo esté en desarrollo
class GranosState {
  final bool isLoading;
  final String? error;

  const GranosState({
    this.isLoading = false,
    this.error,
  });

  GranosState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return GranosState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier para el módulo de granos
class GranosNotifier extends StateNotifier<GranosState> {
  GranosNotifier() : super(const GranosState());

  // Métodos a implementar cuando el módulo esté listo:
  // - loadGranos()
  // - createGrano()
  // - updateGrano()
  // - deleteGrano()
  // - searchGranos()

  void reset() {
    state = const GranosState();
  }
}

/// Provider principal del módulo de granos
final granosProvider = StateNotifierProvider<GranosNotifier, GranosState>((ref) {
  return GranosNotifier();
});

/// Provider para verificar si el módulo está disponible
final granosEnabledProvider = Provider<bool>((ref) {
  // Por ahora siempre retorna false (módulo en desarrollo)
  // Cuando esté listo, cambiar a true o leer de configuración remota
  return false;
});
