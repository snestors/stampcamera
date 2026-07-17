import 'package:flutter_test/flutter_test.dart';
import 'package:stampcamera/models/admin/device_request_model.dart';

void main() {
  group('DeviceRequestChangedEvent.tryParse', () {
    test('parsea un payload válido', () {
      final event = DeviceRequestChangedEvent.tryParse({
        'type': 'device_request_changed',
        'action': 'created',
        'request_id': 123,
        'status': 'pending_admin',
      });

      expect(event, isNotNull);
      expect(event!.action, DeviceRequestAction.created);
      expect(event.requestId, 123);
      expect(event.status, DeviceRequestStatus.pendingAdmin);
    });

    test('parsea todos los estados y acciones del contrato', () {
      const statuses = [
        'pending_otp',
        'pending_admin',
        'approved',
        'rejected',
        'consumed',
        'expired',
      ];
      for (final status in statuses) {
        for (final action in ['created', 'updated']) {
          final event = DeviceRequestChangedEvent.tryParse({
            'type': 'device_request_changed',
            'action': action,
            'request_id': 1,
            'status': status,
          });
          expect(event, isNotNull, reason: 'status=$status action=$action');
          expect(event!.status.wire, status);
          expect(event.action.wire, action);
        }
      }
    });

    test('rechaza tipo de evento distinto', () {
      final event = DeviceRequestChangedEvent.tryParse({
        'type': 'data_changed',
        'action': 'created',
        'request_id': 1,
        'status': 'approved',
      });
      expect(event, isNull);
    });

    test('rechaza action desconocida', () {
      final event = DeviceRequestChangedEvent.tryParse({
        'type': 'device_request_changed',
        'action': 'deleted',
        'request_id': 1,
        'status': 'approved',
      });
      expect(event, isNull);
    });

    test('rechaza status desconocido', () {
      final event = DeviceRequestChangedEvent.tryParse({
        'type': 'device_request_changed',
        'action': 'created',
        'request_id': 1,
        'status': 'weird_status',
      });
      expect(event, isNull);
    });

    test('rechaza request_id que no sea entero', () {
      for (final badId in ['123', 1.5, null, true]) {
        final event = DeviceRequestChangedEvent.tryParse({
          'type': 'device_request_changed',
          'action': 'created',
          'request_id': badId,
          'status': 'approved',
        });
        expect(event, isNull, reason: 'request_id=$badId');
      }
    });

    test('rechaza payloads con tipos incorrectos sin lanzar', () {
      final event = DeviceRequestChangedEvent.tryParse({
        'type': 'device_request_changed',
        'action': 42,
        'request_id': {},
        'status': ['approved'],
      });
      expect(event, isNull);
    });
  });

  group('DeviceRequest.fromJson', () {
    test('parsea la respuesta del serializer del backend', () {
      final request = DeviceRequest.fromJson({
        'id': 7,
        'username': 'jperez',
        'user_full_name': 'Juan Perez',
        'device_id': 'abc-123',
        'device_name': 'Laptop',
        'client_type': 'api',
        'status': 'pending_admin',
        'approval_scope': null,
        'resolved_by_username': null,
        'resolved_at': null,
        'attempts': 2,
        'ip_address': '10.0.0.1',
        'user_agent': 'okhttp',
        'expires_at': '2026-07-17T12:00:00Z',
        'created_at': '2026-07-17T11:50:00Z',
        'consumed_at': null,
      });

      expect(request.id, 7);
      expect(request.status, DeviceRequestStatus.pendingAdmin);
      expect(request.isPendingAdmin, isTrue);
      expect(request.displayUser, 'Juan Perez');
      expect(request.displayDevice, 'Laptop');
      expect(request.expiresAt, isNotNull);
      expect(request.statusLabel, 'Pendiente admin');
    });

    test('tolera un status nuevo del backend sin romper', () {
      final request = DeviceRequest.fromJson({
        'id': 8,
        'username': 'ana',
        'status': 'algo_nuevo',
      });

      expect(request.status, isNull);
      expect(request.statusLabel, 'algo_nuevo');
      expect(request.isPendingAdmin, isFalse);
    });

    test('parsea approval_scope cuando viene resuelta', () {
      final request = DeviceRequest.fromJson({
        'id': 9,
        'username': 'ana',
        'status': 'approved',
        'approval_scope': 'public',
        'resolved_by_username': 'admin',
      });

      expect(request.approvalScope, DeviceApprovalScope.public);
      expect(request.resolvedByUsername, 'admin');
    });
  });
}
