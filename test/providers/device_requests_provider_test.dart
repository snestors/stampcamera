import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stampcamera/models/admin/device_request_model.dart';
import 'package:stampcamera/providers/admin/device_requests_provider.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/services/app_socket_service.dart';

import '../helpers/device_request_test_utils.dart';

/// Margen sobre kDeviceRequestsDebounce para esperar el refetch agrupado
final _debounceWait =
    kDeviceRequestsDebounce + const Duration(milliseconds: 150);

String _changedEvent({int requestId = 1, String status = 'pending_admin'}) {
  return jsonEncode({
    'type': 'device_request_changed',
    'action': 'created',
    'request_id': requestId,
    'status': status,
  });
}

void main() {
  late FakeDeviceRequestService fake;
  late AppSocketService socket;

  setUp(() {
    fake = FakeDeviceRequestService(requests: [makeRequest()]);
    socket = AppSocketService();
  });

  tearDown(() {
    socket.dispose();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        deviceRequestServiceProvider.overrideWithValue(fake),
        appSocketServiceProvider.overrideWithValue(socket),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('carga inicial: una sola consulta REST al abrir', () async {
    final container = createContainer();
    container.listen(deviceRequestsProvider, (_, _) {});

    final requests = await container.read(deviceRequestsProvider.future);

    expect(requests, hasLength(1));
    expect(fake.listCalls, 1);
  });

  test('un evento WS invalida solicitudes Y equipos de confianza', () async {
    final container = createContainer();
    container.listen(deviceRequestsProvider, (_, _) {});
    container.listen(equiposConfianzaProvider, (_, _) {});

    await container.read(deviceRequestsProvider.future);
    await container.read(equiposConfianzaProvider.future);
    expect(fake.listCalls, 1);
    expect(fake.equiposCalls, 1);

    socket.debugHandleMessage(_changedEvent());
    await Future<void>.delayed(_debounceWait);
    await container.read(deviceRequestsProvider.future);
    await container.read(equiposConfianzaProvider.future);

    expect(fake.listCalls, 2);
    expect(fake.equiposCalls, 2);
  });

  test(
    'eventos consecutivos se agrupan en UNA sola consulta (debounce)',
    () async {
      final container = createContainer();
      container.listen(deviceRequestsProvider, (_, _) {});

      await container.read(deviceRequestsProvider.future);
      expect(fake.listCalls, 1);

      for (var i = 0; i < 5; i++) {
        socket.debugHandleMessage(_changedEvent(requestId: i + 1));
      }
      await Future<void>.delayed(_debounceWait);
      await container.read(deviceRequestsProvider.future);

      expect(fake.listCalls, 2);
    },
  );

  test('payloads inválidos no disparan ninguna consulta', () async {
    final container = createContainer();
    container.listen(deviceRequestsProvider, (_, _) {});

    await container.read(deviceRequestsProvider.future);

    socket.debugHandleMessage(
      jsonEncode({
        'type': 'device_request_changed',
        'action': 'boom',
        'request_id': 'x',
        'status': 'nope',
      }),
    );
    socket.debugHandleMessage('basura');
    await Future<void>.delayed(_debounceWait);

    expect(fake.listCalls, 1);
  });

  test(
    'connection_established refresca una vez (recupera cambios perdidos)',
    () async {
      final container = createContainer();
      container.listen(deviceRequestsProvider, (_, _) {});

      await container.read(deviceRequestsProvider.future);
      expect(fake.listCalls, 1);

      socket.debugHandleMessage(
        jsonEncode({
          'type': 'connection_established',
          'user_id': 1,
          'subscribed': <String>[],
        }),
      );
      await Future<void>.delayed(_debounceWait);
      await container.read(deviceRequestsProvider.future);

      expect(fake.listCalls, 2);
    },
  );

  test('sin eventos WS no hay polling: el contador no se mueve', () async {
    final container = createContainer();
    container.listen(deviceRequestsProvider, (_, _) {});

    await container.read(deviceRequestsProvider.future);
    await Future<void>.delayed(const Duration(seconds: 2));

    expect(fake.listCalls, 1);
  });

  test('destruir el provider cancela los listeners del WS', () async {
    final container = createContainer();
    final sub = container.listen(deviceRequestsProvider, (_, _) {});

    await container.read(deviceRequestsProvider.future);
    expect(fake.listCalls, 1);

    // Al soltar el último listener, autoDispose destruye el provider
    sub.close();
    await container.pump();

    socket.debugHandleMessage(_changedEvent());
    await Future<void>.delayed(_debounceWait);

    expect(fake.listCalls, 1);
  });

  test(
    'cerrar el contenedor (fin de sesión) cancela listeners sin errores',
    () async {
      final container = ProviderContainer(
        overrides: [
          deviceRequestServiceProvider.overrideWithValue(fake),
          appSocketServiceProvider.overrideWithValue(socket),
        ],
      );
      container.listen(deviceRequestsProvider, (_, _) {});
      await container.read(deviceRequestsProvider.future);

      container.dispose();

      // El evento posterior no debe disparar consultas ni lanzar
      socket.debugHandleMessage(_changedEvent());
      await Future<void>.delayed(_debounceWait);

      expect(fake.listCalls, 1);
    },
  );

  test('approve actualiza la solicitud en el listado', () async {
    final container = createContainer();
    container.listen(deviceRequestsProvider, (_, _) {});
    await container.read(deviceRequestsProvider.future);

    final updated = await container
        .read(deviceRequestsProvider.notifier)
        .approve(1, DeviceApprovalScope.personal);

    expect(updated.status, DeviceRequestStatus.approved);
    expect(fake.approveCalls, 1);
    expect(fake.lastApprovalScope, DeviceApprovalScope.personal);

    final current = container.read(deviceRequestsProvider).value!;
    expect(current.single.status, DeviceRequestStatus.approved);
  });

  test('reject actualiza la solicitud en el listado', () async {
    final container = createContainer();
    container.listen(deviceRequestsProvider, (_, _) {});
    await container.read(deviceRequestsProvider.future);

    await container.read(deviceRequestsProvider.notifier).reject(1);

    expect(fake.rejectCalls, 1);
    final current = container.read(deviceRequestsProvider).value!;
    expect(current.single.status, DeviceRequestStatus.rejected);
  });
}
