// lib/providers/session_manager_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/providers/autos/pedeteo_provider.dart';
import 'package:stampcamera/providers/autos/registro_detalle_provider.dart';
import 'package:stampcamera/providers/autos/registro_general_provider.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/providers/autos/contenedor_provider.dart';
// import 'package:stampcamera/providers/camera_provider.dart';       // Comentado hasta verificar
// import 'package:stampcamera/providers/biometric_provider.dart';    // Comentado hasta verificar

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

  /// Limpiar providers al iniciar asistencia
  void onStartAssistance(WidgetRef ref) {
    // Limpiar solo providers relacionados con asistencia y trabajo diario
    ref.invalidate(asistenciasDiariasProvider);
    ref.invalidate(asistenciaFormOptionsProvider);
    ref.invalidate(asistenciaStatusProvider);
    
    // Limpiar datos de trabajo del día anterior
    ref.invalidate(registroGeneralProvider);
    ref.invalidate(contenedorProvider);
    // NOTA: queueStateProvider se mantiene entre inicios de asistencia
    
    // Mantener configuraciones y caché de opciones
    // NO limpiar: *OptionsProvider, configuraciones de usuario, etc.
  }

  /// Limpiar providers al cerrar asistencia
  void onEndAssistance(WidgetRef ref) {
    // Limpiar todos los datos de trabajo
    ref.invalidate(asistenciasDiariasProvider);
    ref.invalidate(asistenciaStatusProvider);
    ref.invalidate(registroGeneralProvider);
    ref.invalidate(contenedorProvider);
    // NOTA: queueStateProvider se mantiene entre cierres de asistencia
    
    // Limpiar datos temporales pero mantener configuraciones
    // ref.invalidate(cameraProvider);        // Comentado hasta verificar si existe
    
    // Mantener: opciones, configuraciones, autenticación
  }

  /// 🔥 CLAVE: Invalida TODOS los providers relacionados con datos de usuario
  void _clearAllUserRelatedProviders(WidgetRef ref) {
    // ============================================================================
    // PROVIDERS DE ASISTENCIA
    // ============================================================================
    ref.invalidate(asistenciasDiariasProvider);
    ref.invalidate(asistenciaFormOptionsProvider);
    ref.invalidate(asistenciaStatusProvider);

    // ============================================================================
    // PROVIDERS DE AUTOS - REGISTRO GENERAL
    // ============================================================================
    ref.invalidate(registroGeneralProvider);
    ref.invalidate(registroVinOptionsProvider);
    
    // ============================================================================
    // PROVIDERS DE AUTOS - PEDETEO
    // ============================================================================
    ref.invalidate(pedeteoOptionsProvider);
    ref.invalidate(pedeteoStateProvider);

    // ============================================================================
    // PROVIDERS DE AUTOS - REGISTRO DETALLE
    // ============================================================================
    ref.invalidate(detalleRegistroProvider);
    ref.invalidate(fotosOptionsProvider);
    ref.invalidate(danosOptionsProvider);

    // ============================================================================
    // PROVIDERS DE AUTOS - INVENTARIO
    // ============================================================================
    ref.invalidate(inventarioBaseProvider);
    ref.invalidate(inventarioDetalleProvider);
    ref.invalidate(inventarioImageProvider);
    ref.invalidate(inventarioFormProvider);
    ref.invalidate(inventarioStatsProvider);

    // ============================================================================
    // PROVIDERS DE AUTOS - CONTENEDORES
    // ============================================================================
    ref.invalidate(contenedorProvider);
    ref.invalidate(contenedorDetalleProvider);
    ref.invalidate(contenedorOptionsProvider);

    // ============================================================================
    // PROVIDERS DE AUTOS - QUEUE STATE
    // ============================================================================
    // NOTA: queueStateProvider NO se invalida - mantiene estado entre sesiones
    // ref.invalidate(queueStateProvider);

    // ============================================================================
    // PROVIDERS GENERALES CON DATOS DE USUARIO
    // ============================================================================
    // ref.invalidate(cameraProvider);        // Comentado hasta verificar si existe
    // ref.invalidate(biometricProvider);     // Comentado hasta verificar si existe
    // NOTA: NO limpiar themeProvider ni connectivityProvider (configuraciones globales)

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
