import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stampcamera/models/admin/device_request_model.dart';
import 'package:stampcamera/services/app_socket_service.dart';

void main() {
  late AppSocketService socket;

  setUp(() {
    socket = AppSocketService();
  });

  tearDown(() {
    socket.dispose();
  });

  group('AppSocketService.onDeviceRequestChanged', () {
    test('emite el evento tipado ante un payload válido', () async {
      final events = <DeviceRequestChangedEvent>[];
      final sub = socket.onDeviceRequestChanged.listen(events.add);

      socket.debugHandleMessage(
        jsonEncode({
          'type': 'device_request_changed',
          'action': 'created',
          'request_id': 123,
          'status': 'pending_admin',
        }),
      );

      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.first.requestId, 123);
      expect(events.first.action, DeviceRequestAction.created);
      expect(events.first.status, DeviceRequestStatus.pendingAdmin);

      await sub.cancel();
    });

    test('descarta payloads inválidos sin emitir ni lanzar', () async {
      final events = <DeviceRequestChangedEvent>[];
      final sub = socket.onDeviceRequestChanged.listen(events.add);

      // Acción desconocida
      socket.debugHandleMessage(
        jsonEncode({
          'type': 'device_request_changed',
          'action': 'destroyed',
          'request_id': 1,
          'status': 'approved',
        }),
      );
      // request_id como string
      socket.debugHandleMessage(
        jsonEncode({
          'type': 'device_request_changed',
          'action': 'updated',
          'request_id': '1',
          'status': 'approved',
        }),
      );
      // No es JSON
      socket.debugHandleMessage('no soy json');

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);

      await sub.cancel();
    });

    test('otros tipos de evento no llegan al stream de solicitudes', () async {
      final events = <DeviceRequestChangedEvent>[];
      final sub = socket.onDeviceRequestChanged.listen(events.add);

      socket.debugHandleMessage(
        jsonEncode({
          'type': 'data_changed',
          'action': 'created',
          'request_id': 5,
          'status': 'approved',
        }),
      );

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);

      await sub.cancel();
    });
  });
}
