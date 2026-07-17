import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stampcamera/models/admin/device_request_model.dart';
import 'package:stampcamera/providers/admin/device_requests_provider.dart';
import 'package:stampcamera/providers/app_socket_provider.dart';
import 'package:stampcamera/screens/admin/device_requests_screen.dart';
import 'package:stampcamera/services/app_socket_service.dart';

import '../helpers/device_request_test_utils.dart';

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

  Future<void> pumpScreen(WidgetTester tester, {bool superuser = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRequestServiceProvider.overrideWithValue(fake),
          appSocketServiceProvider.overrideWithValue(socket),
          isSuperuserProvider.overrideWithValue(superuser),
        ],
        child: const MaterialApp(home: DeviceRequestsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('un usuario NO superusuario no accede a la interfaz', (
    tester,
  ) async {
    await pumpScreen(tester, superuser: false);

    expect(find.text('Acceso restringido'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsNothing);
    // Ni siquiera se consulta el backend
    expect(fake.listCalls, 0);
  });

  testWidgets('superusuario ve el listado con estado, usuario y acciones', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(fake.listCalls, 1);
    expect(find.text('Juan Perez'), findsOneWidget);
    expect(find.text('Pendiente admin'), findsOneWidget);
    expect(find.textContaining('Laptop de Juan'), findsOneWidget);
    // Acciones disponibles para pending_admin
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Público'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
    // Banner de desconexión (el socket de test nunca conecta)
    expect(find.textContaining('Sin conexión en tiempo real'), findsOneWidget);
  });

  testWidgets('estado vacío cuando no hay solicitudes', (tester) async {
    fake.requests = [];
    await pumpScreen(tester);

    expect(find.text('Sin solicitudes'), findsOneWidget);
  });

  testWidgets('NO hay polling periódico: 10 minutos sin consultas extra', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(fake.listCalls, 1);

    await tester.pump(const Duration(minutes: 10));
    await tester.pump();

    expect(fake.listCalls, 1);
  });

  testWidgets('un evento WS refresca el listado con una sola consulta', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(fake.listCalls, 1);

    socket.debugHandleMessage(
      jsonEncode({
        'type': 'device_request_changed',
        'action': 'updated',
        'request_id': 1,
        'status': 'approved',
      }),
    );

    await tester.pump(kDeviceRequestsDebounce * 2);
    await tester.pump();

    expect(fake.listCalls, 2);
  });

  testWidgets('rechazar usa confirmación integrada en la tarjeta', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Rechazar'));
    await tester.pump();

    // Confirmación inline, no un diálogo
    expect(find.text('¿Rechazar esta solicitud?'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(fake.rejectCalls, 0);

    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump();

    expect(fake.rejectCalls, 1);
    expect(find.text('Rechazada'), findsOneWidget);
    // Espera el refetch debounced que dispara el patch del listado
    await tester.pump(kDeviceRequestsDebounce * 2);
  });

  testWidgets('cancelar la confirmación no ejecuta la acción', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Público'));
    await tester.pump();
    expect(find.text('¿Aprobar como equipo PÚBLICO?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(fake.approveCalls, 0);
    expect(find.text('¿Aprobar como equipo PÚBLICO?'), findsNothing);
  });

  testWidgets('aprobar como personal envía el scope correcto', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Personal'));
    await tester.pump();
    expect(find.text('¿Aprobar como equipo PERSONAL?'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump();

    expect(fake.approveCalls, 1);
    expect(fake.lastApprovalScope, DeviceApprovalScope.personal);
    expect(find.text('Aprobada'), findsOneWidget);
  });

  testWidgets('buscar por código muestra el resultado inline', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'NSCY-YDQ5');
    await tester.tap(find.text('Buscar'));
    await tester.pump();
    await tester.pump();

    expect(fake.resolveCalls, 1);
    expect(fake.lastResolvedCode, 'NSCY-YDQ5');
    expect(find.text('Resultado de la búsqueda'), findsOneWidget);
  });
}
