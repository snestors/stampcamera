// =============================================================================
// PRESENCE PROVIDER - Maneja la conexión WebSocket de presencia
// =============================================================================
//
// Este provider integra el servicio de WebSocket con Riverpod para:
// - Conectar automáticamente después del login
// - Desconectar en logout
// - Propagar eventos de force_logout, permissions_updated, asistencia_changed
// - Manejar reconexión automática
//
// Eventos manejados:
// - force_logout: Cierra sesión del usuario
// - permissions_updated: Refresca permisos del usuario
// - asistencia_changed: Actualiza estado de asistencia
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/presence_websocket_service.dart';
import 'package:stampcamera/services/storage_health_service.dart';

/// Estado del provider de presencia
class PresenceState {
  final WebSocketConnectionState connectionState;
  final String? lastError;
  final DateTime? connectedAt;
  final String? currentRoute;

  const PresenceState({
    this.connectionState = WebSocketConnectionState.disconnected,
    this.lastError,
    this.connectedAt,
    this.currentRoute,
  });

  PresenceState copyWith({
    WebSocketConnectionState? connectionState,
    String? lastError,
    DateTime? connectedAt,
    String? currentRoute,
  }) {
    return PresenceState(
      connectionState: connectionState ?? this.connectionState,
      lastError: lastError,
      connectedAt: connectedAt ?? this.connectedAt,
      currentRoute: currentRoute ?? this.currentRoute,
    );
  }

  bool get isConnected => connectionState == WebSocketConnectionState.connected;
  bool get isReconnecting => connectionState == WebSocketConnectionState.reconnecting;
  bool get hasError => connectionState == WebSocketConnectionState.error;
}

/// Provider global del servicio de presencia
final presenceServiceProvider = Provider<PresenceWebSocketService>((ref) {
  final service = PresenceWebSocketService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider del estado de presencia
final presenceProvider = StateNotifierProvider<PresenceNotifier, PresenceState>((ref) {
  return PresenceNotifier(ref);
});

/// Stream de eventos de presencia
final presenceEventsProvider = StreamProvider<PresenceEvent>((ref) {
  final service = ref.watch(presenceServiceProvider);
  return service.eventStream;
});

/// Notifier para el estado de presencia
class PresenceNotifier extends StateNotifier<PresenceState> {
  final Ref _ref;
  final _storage = appSecureStorage;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;
  StreamSubscription<PresenceEvent>? _eventSubscription;

  PresenceNotifier(this._ref) : super(const PresenceState()) {
    _init();
  }

  PresenceWebSocketService get _service => _ref.read(presenceServiceProvider);

  void _init() {
    // Escuchar cambios de estado de conexión
    _connectionSubscription = _service.connectionStateStream.listen((connectionState) {
      state = state.copyWith(
        connectionState: connectionState,
        connectedAt: connectionState == WebSocketConnectionState.connected
            ? DateTime.now()
            : state.connectedAt,
      );
    });

    // Escuchar eventos de presencia
    _eventSubscription = _service.eventStream.listen(_handleEvent);
  }

  /// Conectar al WebSocket
  Future<void> connect() async {
    try {
      final accessToken = await _storage.read(key: 'access');
      if (accessToken == null) {
        debugPrint('⚠️ Presence: No hay token, no se conectará');
        return;
      }

      await _service.connect(accessToken);
    } catch (e) {
      debugPrint('❌ Presence: Error conectando: $e');
      state = state.copyWith(
        connectionState: WebSocketConnectionState.error,
        lastError: e.toString(),
      );
    }
  }

  /// Desconectar del WebSocket
  Future<void> disconnect() async {
    await _service.disconnect();
    state = const PresenceState();
  }

  /// Notificar cambio de ruta
  void notifyRouteChange(String route) {
    if (_service.isConnected) {
      _service.sendRouteChange(route);
      state = state.copyWith(currentRoute: route);
    }
  }

  /// Manejar eventos del WebSocket
  void _handleEvent(PresenceEvent event) {
    debugPrint('📨 Presence: Evento recibido: ${event.type}');

    switch (event.type) {
      case PresenceEventType.forceLogout:
        _handleForceLogout(event);
        break;

      case PresenceEventType.permissionsUpdated:
        _handlePermissionsUpdated(event);
        break;

      case PresenceEventType.asistenciaChanged:
        _handleAsistenciaChanged(event);
        break;

      case PresenceEventType.error:
        state = state.copyWith(lastError: event.message);
        break;

      default:
        // connected, disconnected, heartbeat_ack, pong - ya manejados por connectionState
        break;
    }
  }

  /// Manejar force_logout
  void _handleForceLogout(PresenceEvent event) {
    debugPrint('🚪 Presence: Force logout - ${event.reason}: ${event.message}');

    // El logout se manejará desde el auth_provider que escucha este evento
    // Solo emitimos un log aquí, el auth_provider reaccionará
  }

  /// Manejar permissions_updated
  void _handlePermissionsUpdated(PresenceEvent event) {
    debugPrint('🔐 Presence: Permisos actualizados - grupos: ${event.grupos}');

    // Notificar que los permisos cambiaron
    // El auth_provider debería refrescar los datos del usuario
  }

  /// Manejar asistencia_changed
  void _handleAsistenciaChanged(PresenceEvent event) {
    debugPrint('📋 Presence: Asistencia cambió');

    // Notificar que la asistencia cambió
    // Los providers de asistencia deberían refrescarse
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// =============================================================================
// HOOKS PARA INTEGRAR CON OTROS PROVIDERS
// =============================================================================

/// Provider que escucha eventos de force_logout
/// Usar en auth_provider o donde se maneje el logout
final forceLogoutEventsProvider = StreamProvider<PresenceEvent>((ref) {
  final service = ref.watch(presenceServiceProvider);
  return service.eventStream
      .where((event) => event.type == PresenceEventType.forceLogout);
});

/// Provider que escucha eventos de permisos actualizados
final permissionsUpdatedEventsProvider = StreamProvider<PresenceEvent>((ref) {
  final service = ref.watch(presenceServiceProvider);
  return service.eventStream
      .where((event) => event.type == PresenceEventType.permissionsUpdated);
});

/// Provider que escucha eventos de asistencia cambiada
final asistenciaChangedEventsProvider = StreamProvider<PresenceEvent>((ref) {
  final service = ref.watch(presenceServiceProvider);
  return service.eventStream
      .where((event) => event.type == PresenceEventType.asistenciaChanged);
});
