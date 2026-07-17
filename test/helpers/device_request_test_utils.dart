import 'package:stampcamera/models/admin/device_request_model.dart';
import 'package:stampcamera/services/admin/device_request_service.dart';

/// Fábrica de solicitudes para tests
DeviceRequest makeRequest({
  int id = 1,
  String username = 'jperez',
  String userFullName = 'Juan Perez',
  String deviceName = 'Laptop de Juan',
  String clientType = 'api',
  DeviceRequestStatus status = DeviceRequestStatus.pendingAdmin,
  DeviceApprovalScope? approvalScope,
  String? resolvedByUsername,
}) {
  return DeviceRequest(
    id: id,
    username: username,
    userFullName: userFullName,
    deviceId: 'device-$id',
    deviceName: deviceName,
    clientType: clientType,
    status: status,
    statusRaw: status.wire,
    approvalScope: approvalScope,
    resolvedByUsername: resolvedByUsername,
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    createdAt: DateTime.now(),
  );
}

/// Fake del servicio REST con contadores de llamadas
class FakeDeviceRequestService implements DeviceRequestService {
  FakeDeviceRequestService({
    List<DeviceRequest>? requests,
    List<EquipoConfianza>? equipos,
  }) : requests = requests ?? [],
       equipos = equipos ?? [];

  List<DeviceRequest> requests;
  List<EquipoConfianza> equipos;

  int listCalls = 0;
  int equiposCalls = 0;
  int resolveCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;
  String? lastResolvedCode;
  DeviceApprovalScope? lastApprovalScope;

  @override
  Future<List<DeviceRequest>> list() async {
    listCalls++;
    return List.of(requests);
  }

  @override
  Future<List<EquipoConfianza>> listEquipos() async {
    equiposCalls++;
    return List.of(equipos);
  }

  @override
  Future<DeviceRequest> resolveCode(String userCode) async {
    resolveCalls++;
    lastResolvedCode = userCode;
    return requests.first;
  }

  @override
  Future<DeviceRequest> approve(
    int requestId,
    DeviceApprovalScope scope,
  ) async {
    approveCalls++;
    lastApprovalScope = scope;
    return makeRequest(
      id: requestId,
      status: DeviceRequestStatus.approved,
      approvalScope: scope,
      resolvedByUsername: 'admin',
    );
  }

  @override
  Future<DeviceRequest> reject(int requestId) async {
    rejectCalls++;
    return makeRequest(
      id: requestId,
      status: DeviceRequestStatus.rejected,
      resolvedByUsername: 'admin',
    );
  }
}
