// =============================================================================
// APP SOCKET SERVICE - WebSocket Unificado (ws/app/)
// =============================================================================
//
// Reemplaza el legacy PresenceWebSocketService conectando al endpoint unificado.
// Soporta:
// - Suscripción dinámica a canales (notifications, casos, autos, graneles, presence)
// - Notificaciones en tiempo real
// - Cambios de datos (data_changed) para sincronización
// - Force logout y actualización de permisos
// - Heartbeat y reconexión automática
//
// URL: ws://host/ws/app/?token=<JWT>
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Canales disponibles para suscripción
class AppSocketChannels {
  static const String notifications = 'notifications';
  static const String presence = 'presence';
  static const String casos = 'casos';
  static const String autos = 'autos';
  static const String graneles = 'graneles';
}

/// Evento genérico del WebSocket unificado
class AppSocketEvent {
  final String type;
  final Map<String, dynamic> raw;

  const AppSocketEvent({required this.type, required this.raw});

  // --- Datos de connection_established ---
  int? get userId => raw['user_id'] as int?;
  String? get username => raw['username'] as String?;
  List<String> get subscribedChannels =>
      (raw['subscribed'] as List?)?.cast<String>() ?? [];

  // --- Datos de notification ---
  Map<String, dynamic>? get notificationData =>
      raw['data'] as Map<String, dynamic>?;

  // --- Datos de data_changed ---
  String? get action => raw['action'] as String?;
  String? get model => raw['model'] as String?;
  Map<String, dynamic>? get data => raw['data'] as Map<String, dynamic>?;
  Map<String, dynamic>? get actor => raw['actor'] as Map<String, dynamic>?;
  int? get actorId => actor?['id'] as int?;

  // --- Datos de force_logout ---
  String? get reason => raw['reason'] as String?;
  String? get message => raw['message'] as String?;

  // --- Datos de permissions_updated ---
  Map<String, dynamic>? get permissions =>
      raw['permissions'] as Map<String, dynamic>?;
  List<String>? get grupos =>
      (permissions?['grupos'] as List?)?.cast<String>();
  Map<String, dynamic>? get modulos =>
      permissions?['modulos'] as Map<String, dynamic>?;

  // --- Datos de presence_update ---
  List<Map<String, dynamic>> get presenceUsers =>
      (raw['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // --- Error ---
  String? get errorMessage => raw['message'] as String?;

  @override
  String toString() => 'AppSocketEvent(type: $type)';
}

/// Estado de la conexión WebSocket
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Servicio WebSocket unificado
class AppSocketService {
  static const String _wsBaseUrl = 'wss://www.aygajustadores.com/ws/app/';
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectBaseDelay = Duration(seconds: 5);
  static const int _maxReconnectAttempts = 5;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  String? _accessToken;
  int _reconnectAttempts = 0;
  String _currentRoute = '';
  Set<String> _subscribedChannels = {};

  WsConnectionState _connectionState = WsConnectionState.disconnected;
  WsConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == WsConnectionState.connected;
  Set<String> get subscribedChannels => Set.unmodifiable(_subscribedChannels);

  // Stream controllers
  final _eventController = StreamController<AppSocketEvent>.broadcast();
  final _connectionStateController =
      StreamController<WsConnectionState>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _dataChangedController =
      StreamController<AppSocketEvent>.broadcast();

  Stream<AppSocketEvent> get eventStream => _eventController.stream;
  Stream<WsConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;
  Stream<AppSocketEvent> get onDataChanged => _dataChangedController.stream;

  // ─── Conexión ────────────────────────────────────────────────────────

  Future<void> connect(String accessToken) async {
    if (_connectionState == WsConnectionState.connected ||
        _connectionState == WsConnectionState.connecting) {
      return;
    }

    _accessToken = accessToken;
    _setConnectionState(WsConnectionState.connecting);

    try {
      final uri = Uri.parse('$_wsBaseUrl?token=$accessToken');
      debugPrint('WS: Conectando a ws/app/...');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (_channel != null) {
        _setConnectionState(WsConnectionState.connected);
        _startHeartbeat();
        _reconnectAttempts = 0;
        debugPrint('WS: Conectado a ws/app/');
      }
    } catch (e) {
      debugPrint('WS: Error conectando: $e');
      _setConnectionState(WsConnectionState.error);
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    debugPrint('WS: Desconectando...');
    _stopHeartbeat();
    _cancelReconnect();
    _reconnectAttempts = 0;

    if (_channel != null) {
      await _channel!.sink.close(1000);
      _channel = null;
    }

    _subscribedChannels.clear();
    _setConnectionState(WsConnectionState.disconnected);
  }

  // ─── Envío de mensajes ───────────────────────────────────────────────

  void subscribe(String channel) {
    _send({'type': 'subscribe', 'channel': channel});
  }

  void unsubscribe(String channel) {
    _send({'type': 'unsubscribe', 'channel': channel});
  }

  void updateRoute(String route) {
    _currentRoute = route;
    _send({'type': 'route_change', 'route': route});
  }

  void sendHeartbeat() {
    _send({'type': 'heartbeat'});
  }

  void sendPing() {
    _send({
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ─── Explorador de archivos ──────────────────────────────────────────

  void sendCambiarCarpeta(int carpetaId, String carpetaNombre) {
    _send({
      'type': 'cambiar_carpeta',
      'carpeta_id': carpetaId,
      'carpeta_nombre': carpetaNombre,
    });
  }

  void sendCambiarSeleccion(List<Map<String, dynamic>> seleccion) {
    _send({
      'type': 'cambiar_seleccion',
      'seleccion': seleccion,
    });
  }

  void sendGetUsuarios() {
    _send({'type': 'get_usuarios'});
  }

  // ─── Manejo de mensajes ──────────────────────────────────────────────

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      final event = AppSocketEvent(type: type, raw: data);

      switch (type) {
        case 'connection_established':
          _subscribedChannels = Set<String>.from(data['subscribed'] ?? []);
          if (_currentRoute.isNotEmpty) {
            updateRoute(_currentRoute);
          }
          break;

        case 'subscribed':
        case 'unsubscribed':
          _subscribedChannels = Set<String>.from(data['subscribed'] ?? []);
          break;

        case 'notification':
          final notifData = data['data'] as Map<String, dynamic>?;
          if (notifData != null) {
            _notificationController.add(notifData);
          }
          break;

        case 'data_changed':
          _dataChangedController.add(event);
          break;

        case 'force_logout':
          debugPrint('WS: Force logout - ${data['reason']}');
          _eventController.add(event);
          disconnect();
          return; // No emitir al eventStream otra vez

        case 'permissions_updated':
          break; // Se emite abajo

        case 'heartbeat_ack':
        case 'pong':
          break; // Conexión viva, nada que hacer

        case 'error':
          debugPrint('WS Error: ${data['message']}');
          break;

        // Eventos del explorador de archivos
        case 'usuario_conectado':
        case 'usuario_desconectado':
        case 'usuario_cambio_carpeta':
        case 'usuario_cambio_seleccion':
        case 'archivo_creado':
        case 'archivo_eliminado':
        case 'archivo_movido':
        case 'archivo_restaurado':
        case 'carpeta_creada':
        case 'carpeta_eliminada':
        case 'carpeta_restaurada':
        case 'carpeta_renombrada':
        case 'permisos_actualizados':
        case 'usuarios_lista':
          break; // Se emite abajo
      }

      _eventController.add(event);
    } catch (e) {
      debugPrint('WS: Error parseando mensaje: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('WS: Error: $error');
    _setConnectionState(WsConnectionState.error);
    _eventController.add(AppSocketEvent(
      type: 'error',
      raw: {'message': error.toString()},
    ));
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WS: Conexión cerrada');
    if (_connectionState != WsConnectionState.disconnected) {
      _setConnectionState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  // ─── Internos ────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> data) {
    if (_channel == null || !isConnected) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('WS: Error enviando: $e');
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_accessToken == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WS: Max reconexiones alcanzado');
      _setConnectionState(WsConnectionState.error);
      return;
    }

    _cancelReconnect();
    _setConnectionState(WsConnectionState.reconnecting);

    final delay = _reconnectBaseDelay * (_reconnectAttempts + 1);
    debugPrint(
        'WS: Reconectando en ${delay.inSeconds}s (${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _channel = null;
      _connectionState = WsConnectionState.disconnected;
      connect(_accessToken!);
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _setConnectionState(WsConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
    _notificationController.close();
    _dataChangedController.close();
  }
}
