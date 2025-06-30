// lib/providers/session_manager_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';

class SessionManager extends StateNotifier<String?> {
  SessionManager() : super(null);

  String? _currentUserId;

  String? get currentUserId => _currentUserId;

  /// Cambiar sesión y limpiar providers
  void changeSession(String newUserId, WidgetRef ref) {
    final previousUserId = _currentUserId;
    _currentUserId = newUserId;
    state = newUserId;

    // Solo limpiar si realmente cambió el usuario
    if (previousUserId != null && previousUserId != newUserId) {
      _clearAllUserRelatedProviders(ref);
    }
  }

  /// Limpiar sesión actual
  void clearSession(WidgetRef ref) {
    _currentUserId = null;
    state = null;
    _clearAllUserRelatedProviders(ref);
  }

  /// 🔥 CLAVE: Invalida TODOS los providers relacionados con datos de usuario
  void _clearAllUserRelatedProviders(WidgetRef ref) {
    // Invalidar providers de asistencia
    ref.invalidate(asistenciasDiariasProvider);
    ref.invalidate(asistenciaFormOptionsProvider);
    ref.invalidate(asistenciaStatusProvider);

    // ============================================================================
    // PROVIDERS DE AUTOS - REGISTRO GENERAL
    // ============================================================================
    ref.invalidate(registroGeneralProvider);
    ref.invalidate(registroVinOptionsProvider);
    // ============================================================================
    // PROVIDERS DE AUTOS - PEDETEO (TODOS LOS RELACIONADOS)
    // ============================================================================
    ref.invalidate(pedeteoOptionsProvider);
    ref.invalidate(pedeteoStateProvider);

    // Invalidar otros providers de datos de usuario
    // ref.invalidate(perfilUsuarioProvider);
    // ref.invalidate(configuracionUsuarioProvider);
    // ref.invalidate(historialProvider);
    // ... agregar todos los providers que contengan datos específicos del usuario

    // Limpiar cualquier caché local
    _clearLocalCaches();
  }

  void _clearLocalCaches() {
    // Limpiar cachés estáticos si los tienes
    // AsistenciasNotifier._cache.clear();
  }
}

final sessionManagerProvider = StateNotifierProvider<SessionManager, String?>(
  (ref) => SessionManager(),
);
