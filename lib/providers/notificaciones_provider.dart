import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/notificacion_model.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/services/app_socket_service.dart';
import 'package:stampcamera/services/notificaciones_service.dart';

/// Bandeja de notificaciones del usuario (efímera, espejo de la web):
/// carga inicial por REST y nuevas en vivo por el WS `ws/app/`.
/// "Marcar como leída" elimina la notificación en el servidor.
class NotificacionesState {
  final List<NotificacionModel> items;
  final bool loading;
  final String? error;

  const NotificacionesState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  int get unreadCount => items.length;

  NotificacionesState copyWith({
    List<NotificacionModel>? items,
    bool? loading,
    String? error,
  }) {
    return NotificacionesState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class NotificacionesNotifier extends StateNotifier<NotificacionesState> {
  NotificacionesNotifier(this._ref) : super(const NotificacionesState()) {
    _init();
  }

  final Ref _ref;
  final _service = NotificacionesService();
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  StreamSubscription<WsConnectionState>? _connSub;

  void _init() {
    final socket = _ref.read(appSocketServiceProvider);

    _wsSub = socket.onNotification.listen(_onWsNotification);

    // Al (re)conectar el WS, re-sincronizar: pudieron llegar notificaciones
    // mientras no había conexión en vivo.
    _connSub = socket.connectionStateStream.listen((wsState) {
      if (wsState == WsConnectionState.connected) load();
    });

    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final items = await _service.fetch();
      if (!mounted) return;
      state = NotificacionesState(items: items);
    } catch (e) {
      debugPrint('Notificaciones: error cargando: $e');
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void _onWsNotification(Map<String, dynamic> data) {
    final notif = NotificacionModel.fromWs(data);
    if (notif.esRuidoAutomatico) return;
    if (notif.id != 0 && state.items.any((n) => n.id == notif.id)) return;
    state = state.copyWith(items: [notif, ...state.items]);
  }

  /// Optimista: se quita de la lista de inmediato. Si el POST falla no se
  /// restaura — la bandeja es efímera y la siguiente carga la traería.
  Future<void> markAsRead(int id) async {
    state = state.copyWith(
      items: state.items.where((n) => n.id != id).toList(),
    );
    try {
      await _service.markAsRead(id);
    } catch (e) {
      debugPrint('Notificaciones: error marcando leída #$id: $e');
    }
  }

  Future<void> markAllAsRead() async {
    state = state.copyWith(items: []);
    try {
      await _service.markAllAsRead();
    } catch (e) {
      debugPrint('Notificaciones: error marcando todas leídas: $e');
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

final notificacionesProvider =
    StateNotifierProvider<NotificacionesNotifier, NotificacionesState>(
  (ref) => NotificacionesNotifier(ref),
);

/// Cantidad de no-leídas para el badge de la campanita.
final notificacionesUnreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificacionesProvider).unreadCount,
);
