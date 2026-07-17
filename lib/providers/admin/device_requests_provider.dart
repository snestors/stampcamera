// =============================================================================
// DEVICE REQUESTS PROVIDER - Solicitudes de autorización de equipos (admin)
// =============================================================================
//
// Tiempo real vía WebSocket unificado (ws/app/): el evento
// `device_request_changed` es una señal de invalidación. NO hay polling
// periódico; la fuente de verdad siempre es una única consulta REST.
// =============================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/admin/device_request_model.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/services/admin/device_request_service.dart';

/// Ventana de debounce para agrupar eventos WS consecutivos en un solo fetch.
const kDeviceRequestsDebounce = Duration(milliseconds: 200);

/// Servicio REST (inyectable en tests)
final deviceRequestServiceProvider = Provider<DeviceRequestService>((ref) {
  return DeviceRequestService();
});

/// Usuario actual es superusuario (gate de la pantalla admin)
final isSuperuserProvider = Provider<bool>((ref) {
  return ref.watch(
    authProvider.select((state) => state.value?.user?.isSuperuser ?? false),
  );
});

/// Equipos de confianza registrados. Se invalida junto con las solicitudes
/// cuando llega `device_request_changed` (una aprobación crea un equipo).
final equiposConfianzaProvider =
    FutureProvider.autoDispose<List<EquipoConfianza>>((ref) {
      return ref.watch(deviceRequestServiceProvider).listEquipos();
    });

/// Listado administrativo de solicitudes de equipos.
final deviceRequestsProvider =
    AsyncNotifierProvider.autoDispose<
      DeviceRequestsNotifier,
      List<DeviceRequest>
    >(DeviceRequestsNotifier.new);

class DeviceRequestsNotifier
    extends AutoDisposeAsyncNotifier<List<DeviceRequest>> {
  Timer? _debounce;
  StreamSubscription<DeviceRequestChangedEvent>? _changesSub;
  StreamSubscription<dynamic>? _connectionSub;

  DeviceRequestService get _service => ref.read(deviceRequestServiceProvider);

  @override
  Future<List<DeviceRequest>> build() {
    final socket = ref.watch(appSocketServiceProvider);

    // Señal de invalidación en tiempo real (reemplaza cualquier polling)
    _changesSub = socket.onDeviceRequestChanged.listen((_) {
      _scheduleRefresh();
    });

    // Al restablecerse la conexión, recuperar cambios perdidos (una sola vez)
    _connectionSub = socket.eventStream
        .where((event) => event.type == 'connection_established')
        .listen((_) => _scheduleRefresh());

    // Cancela listeners y timers al invalidar/destruir el provider
    // (incluye cierre de sesión: la pantalla se desmonta y autoDispose corre)
    ref.onDispose(() {
      _debounce?.cancel();
      _changesSub?.cancel();
      _connectionSub?.cancel();
    });

    return _service.list();
  }

  /// Agrupa eventos consecutivos y dispara UNA sola consulta REST.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(kDeviceRequestsDebounce, () {
      ref.invalidate(equiposConfianzaProvider);
      ref.invalidateSelf();
    });
  }

  /// Refresh manual (pull-to-refresh)
  Future<void> refresh() {
    ref.invalidate(equiposConfianzaProvider);
    ref.invalidateSelf();
    return future;
  }

  /// Busca una solicitud por código de usuario (ej. NSCY-YDQ5)
  Future<DeviceRequest> resolveCode(String userCode) async {
    final request = await _service.resolveCode(userCode);
    _patch(request);
    return request;
  }

  /// Aprueba una solicitud como equipo personal o público
  Future<DeviceRequest> approve(
    int requestId,
    DeviceApprovalScope scope,
  ) async {
    final updated = await _service.approve(requestId, scope);
    _patch(updated);
    return updated;
  }

  /// Rechaza una solicitud
  Future<DeviceRequest> reject(int requestId) async {
    final updated = await _service.reject(requestId);
    _patch(updated);
    return updated;
  }

  /// Actualiza la solicitud en el listado si ya estaba cargada.
  /// El evento WS que genera la acción refresca igual la lista (debounced).
  void _patch(DeviceRequest updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    final exists = current.any((request) => request.id == updated.id);
    state = AsyncData(
      exists
          ? [
              for (final request in current)
                request.id == updated.id ? updated : request,
            ]
          : [updated, ...current],
    );
  }
}
