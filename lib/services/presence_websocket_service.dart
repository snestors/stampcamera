// =============================================================================
// PRESENCE WEBSOCKET SERVICE - Conexión WebSocket para Presencia y Seguridad
// =============================================================================
//
// Este servicio maneja la conexión WebSocket con el backend para:
// - Tracking de usuarios conectados (ruta actual)
// - Force logout cuando usuario es desactivado
// - Actualización de permisos en tiempo real
// - Cambios de asistencia
//
// URL: ws://host/ws/presencia/?token=<JWT>
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Eventos que el WebSocket puede enviar
enum PresenceEventType {
  connected,
  disconnected,
  forceLogout,
  permissionsUpdated,
  asistenciaChanged,
  heartbeatAck,
  pong,
  error,
}

/// Modelo para eventos de presencia
class PresenceEvent {
  final PresenceEventType type;
  final String? reason;
  final String? message;
  final Map<String, dynamic>? data;
  final List<String>? grupos;
  final Map<String, dynamic>? modulos;
  final Map<String, dynamic>? asistencia;

  const PresenceEvent({
    required this.type,
    this.reason,
    this.message,
    this.data,
    this.grupos,
    this.modulos,
    this.asistencia,
  });

  factory PresenceEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';

    PresenceEventType type;
    switch (typeStr) {
      case 'connected':
        type = PresenceEventType.connected;
        break;
      case 'force_logout':
        type = PresenceEventType.forceLogout;
        break;
      case 'permissions_updated':
        type = PresenceEventType.permissionsUpdated;
        break;
      case 'asistencia_changed':
        type = PresenceEventType.asistenciaChanged;
        break;
      case 'heartbeat_ack':
        type = PresenceEventType.heartbeatAck;
        break;
      case 'pong':
        type = PresenceEventType.pong;
        break;
      default:
        type = PresenceEventType.error;
    }

    return PresenceEvent(
      type: type,
      reason: json['reason'] as String?,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      grupos: json['grupos'] != null
          ? List<String>.from(json['grupos'])
          : null,
      modulos: json['modulos'] as Map<String, dynamic>?,
      asistencia: json['asistencia'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'PresenceEvent(type: $type, message: $message)';
}

/// Estado de la conexión WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Servicio de WebSocket para presencia
class PresenceWebSocketService {
  static const String _wsBaseUrl = 'wss://www.aygajustadores.com/ws/presencia/';
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const int _maxReconnectAttempts = 5;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  String? _accessToken;
  String? _currentRoute;
  int _reconnectAttempts = 0;

  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  WebSocketConnectionState get connectionState => _connectionState;

  // Stream controller para eventos
  final _eventController = StreamController<PresenceEvent>.broadcast();
  Stream<PresenceEvent> get eventStream => _eventController.stream;

  // Stream controller para estado de conexión
  final _connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
  Stream<WebSocketConnectionState> get connectionStateStream => _connectionStateController.stream;

  /// Conectar al WebSocket
  Future<void> connect(String accessToken) async {
    if (_connectionState == WebSocketConnectionState.connected ||
        _connectionState == WebSocketConnectionState.connecting) {
      debugPrint('🔌 WS: Ya conectado o conectando, ignorando');
      return;
    }

    _accessToken = accessToken;
    _setConnectionState(WebSocketConnectionState.connecting);

    try {
      final uri = Uri.parse('$_wsBaseUrl?token=$accessToken');
      debugPrint('🔌 WS: Conectando a $uri');

      _channel = WebSocketChannel.connect(uri);

      // Escuchar mensajes
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Esperar un poco y verificar conexión
      await Future.delayed(const Duration(milliseconds: 500));

      if (_channel != null) {
        _setConnectionState(WebSocketConnectionState.connected);
        _startHeartbeat();
        _reconnectAttempts = 0;
        debugPrint('✅ WS: Conectado exitosamente');
      }
    } catch (e) {
      debugPrint('❌ WS: Error conectando: $e');
      _setConnectionState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Desconectar del WebSocket
  Future<void> disconnect() async {
    debugPrint('🔌 WS: Desconectando...');
    _stopHeartbeat();
    _cancelReconnect();
    _reconnectAttempts = 0;

    if (_channel != null) {
      await _channel!.sink.close(1000); // Normal closure
      _channel = null;
    }

    _setConnectionState(WebSocketConnectionState.disconnected);
    debugPrint('🔌 WS: Desconectado');
  }

  /// Enviar heartbeat
  void sendHeartbeat() {
    _send({'type': 'heartbeat'});
  }

  /// Enviar cambio de ruta
  void sendRouteChange(String route) {
    _currentRoute = route;
    _send({'type': 'route_change', 'route': route});
  }

  /// Enviar ping
  void sendPing() {
    _send({'type': 'ping'});
  }

  /// Enviar mensaje genérico
  void _send(Map<String, dynamic> data) {
    if (_channel == null || _connectionState != WebSocketConnectionState.connected) {
      debugPrint('⚠️ WS: No conectado, no se puede enviar mensaje');
      return;
    }

    try {
      final jsonStr = jsonEncode(data);
      _channel!.sink.add(jsonStr);
    } catch (e) {
      debugPrint('❌ WS: Error enviando mensaje: $e');
    }
  }

  /// Manejar mensaje recibido
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final event = PresenceEvent.fromJson(data);

      debugPrint('📨 WS: Evento recibido: ${event.type}');

      // Emitir evento
      _eventController.add(event);

      // Si es force_logout, desconectar
      if (event.type == PresenceEventType.forceLogout) {
        debugPrint('🚪 WS: Force logout recibido - ${event.reason}');
        disconnect();
      }
    } catch (e) {
      debugPrint('❌ WS: Error parseando mensaje: $e');
    }
  }

  /// Manejar error
  void _onError(dynamic error) {
    debugPrint('❌ WS: Error: $error');
    _setConnectionState(WebSocketConnectionState.error);
    _eventController.add(PresenceEvent(
      type: PresenceEventType.error,
      message: error.toString(),
    ));
    _scheduleReconnect();
  }

  /// Manejar cierre de conexión
  void _onDone() {
    debugPrint('🔌 WS: Conexión cerrada');

    if (_connectionState != WebSocketConnectionState.disconnected) {
      _setConnectionState(WebSocketConnectionState.disconnected);
      _eventController.add(const PresenceEvent(
        type: PresenceEventType.disconnected,
      ));
      _scheduleReconnect();
    }
  }

  /// Iniciar heartbeat
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      sendHeartbeat();
    });
  }

  /// Detener heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Programar reconexión
  void _scheduleReconnect() {
    if (_accessToken == null) {
      debugPrint('⚠️ WS: No hay token, no se reconectará');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ WS: Máximo de intentos de reconexión alcanzado');
      _setConnectionState(WebSocketConnectionState.error);
      return;
    }

    _cancelReconnect();
    _setConnectionState(WebSocketConnectionState.reconnecting);

    final delay = _reconnectDelay * (_reconnectAttempts + 1);
    debugPrint('🔄 WS: Reconectando en ${delay.inSeconds}s (intento ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect(_accessToken!);
    });
  }

  /// Cancelar reconexión programada
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Actualizar estado de conexión
  void _setConnectionState(WebSocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }

  /// Resetear intentos de reconexión
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Verificar si está conectado
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

  /// Cerrar recursos
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}
