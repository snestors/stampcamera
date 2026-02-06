// =============================================================================
// APP SOCKET PROVIDER - Provider Riverpod para WebSocket Unificado
// =============================================================================
//
// Reemplaza presence_provider.dart integrando el AppSocketService con Riverpod.
// Mantiene compatibilidad con los streams existentes de force_logout,
// permissions_updated y asistencia_changed.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/app_socket_service.dart';
import 'package:stampcamera/services/storage_health_service.dart';

/// Estado del provider de socket
class AppSocketState {
  final WsConnectionState connectionState;
  final Set<String> subscribedChannels;
  final String? lastError;
  final DateTime? connectedAt;
  final String? currentRoute;

  const AppSocketState({
    this.connectionState = WsConnectionState.disconnected,
    this.subscribedChannels = const {},
    this.lastError,
    this.connectedAt,
    this.currentRoute,
  });

  AppSocketState copyWith({
    WsConnectionState? connectionState,
    Set<String>? subscribedChannels,
    String? lastError,
    DateTime? connectedAt,
    String? currentRoute,
  }) {
    return AppSocketState(
      connectionState: connectionState ?? this.connectionState,
      subscribedChannels: subscribedChannels ?? this.subscribedChannels,
      lastError: lastError,
      connectedAt: connectedAt ?? this.connectedAt,
      currentRoute: currentRoute ?? this.currentRoute,
    );
  }

  bool get isConnected => connectionState == WsConnectionState.connected;
  bool get isReconnecting => connectionState == WsConnectionState.reconnecting;
  bool get hasError => connectionState == WsConnectionState.error;
}

/// Provider global del servicio de socket
final appSocketServiceProvider = Provider<AppSocketService>((ref) {
  final service = AppSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider del estado de socket
final appSocketProvider =
    StateNotifierProvider<AppSocketNotifier, AppSocketState>((ref) {
  return AppSocketNotifier(ref);
});

/// Stream de conexión
final socketConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(appSocketServiceProvider);
  return service.connectionStateStream
      .map((state) => state == WsConnectionState.connected);
});

/// Stream de notificaciones
final wsNotificationsProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(appSocketServiceProvider);
  return service.onNotification;
});

/// Stream de cambios de datos
final wsDataChangedProvider = StreamProvider<AppSocketEvent>((ref) {
  final service = ref.watch(appSocketServiceProvider);
  return service.onDataChanged;
});

/// Stream de force logout
final wsForceLogoutProvider = StreamProvider<AppSocketEvent>((ref) {
  final service = ref.watch(appSocketServiceProvider);
  return service.eventStream
      .where((event) => event.type == 'force_logout');
});

/// Stream de permisos actualizados
final wsPermissionsUpdatedProvider = StreamProvider<AppSocketEvent>((ref) {
  final service = ref.watch(appSocketServiceProvider);
  return service.eventStream
      .where((event) => event.type == 'permissions_updated');
});

/// Stream de asistencia cambiada
final wsAsistenciaChangedProvider = StreamProvider<AppSocketEvent>((ref) {
  final service = ref.watch(appSocketServiceProvider);
  return service.eventStream
      .where((event) => event.type == 'asistencia_changed');
});

/// Stream filtrado de eventos del explorador de archivos
final wsExploradorEventsProvider = StreamProvider<AppSocketEvent>((ref) {
  final service = ref.watch(appSocketServiceProvider);
  const exploradorTypes = {
    'usuario_conectado',
    'usuario_desconectado',
    'usuario_cambio_carpeta',
    'usuario_cambio_seleccion',
    'archivo_creado',
    'archivo_eliminado',
    'archivo_movido',
    'archivo_restaurado',
    'carpeta_creada',
    'carpeta_eliminada',
    'carpeta_restaurada',
    'carpeta_renombrada',
    'permisos_actualizados',
    'usuarios_lista',
  };
  return service.eventStream
      .where((event) => exploradorTypes.contains(event.type));
});

/// Notifier para el estado de socket
class AppSocketNotifier extends StateNotifier<AppSocketState> {
  final Ref _ref;
  final _storage = appSecureStorage;
  StreamSubscription<WsConnectionState>? _connectionSub;
  StreamSubscription<AppSocketEvent>? _eventSub;

  AppSocketNotifier(this._ref) : super(const AppSocketState()) {
    _init();
  }

  AppSocketService get _service => _ref.read(appSocketServiceProvider);

  void _init() {
    _connectionSub = _service.connectionStateStream.listen((wsState) {
      state = state.copyWith(
        connectionState: wsState,
        subscribedChannels: _service.subscribedChannels,
        connectedAt: wsState == WsConnectionState.connected
            ? DateTime.now()
            : state.connectedAt,
      );
    });

    _eventSub = _service.eventStream.listen(_handleEvent);
  }

  /// Conectar al WebSocket
  Future<void> connect() async {
    try {
      final accessToken = await _storage.read(key: 'access');
      if (accessToken == null) {
        debugPrint('AppSocket: No hay token, no se conectara');
        return;
      }
      await _service.connect(accessToken);
    } catch (e) {
      debugPrint('AppSocket: Error conectando: $e');
      state = state.copyWith(
        connectionState: WsConnectionState.error,
        lastError: e.toString(),
      );
    }
  }

  /// Desconectar
  Future<void> disconnect() async {
    await _service.disconnect();
    state = const AppSocketState();
  }

  /// Notificar cambio de ruta (auto-suscripción)
  void notifyRouteChange(String route) {
    if (_service.isConnected) {
      _service.updateRoute(route);
      state = state.copyWith(currentRoute: route);
    }
  }

  /// Suscribirse a un canal manualmente
  void subscribe(String channel) {
    _service.subscribe(channel);
  }

  /// Des-suscribirse de un canal
  void unsubscribe(String channel) {
    _service.unsubscribe(channel);
  }

  void _handleEvent(AppSocketEvent event) {
    switch (event.type) {
      case 'connection_established':
        state = state.copyWith(
          subscribedChannels: event.subscribedChannels.toSet(),
        );
        break;

      case 'subscribed':
      case 'unsubscribed':
        state = state.copyWith(
          subscribedChannels: _service.subscribedChannels,
        );
        break;

      case 'force_logout':
        debugPrint('AppSocket: Force logout - ${event.reason}');
        break;

      case 'permissions_updated':
        debugPrint('AppSocket: Permisos actualizados');
        break;

      case 'error':
        state = state.copyWith(lastError: event.errorMessage);
        break;
    }
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }
}
