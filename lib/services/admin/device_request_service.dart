// =============================================================================
// DEVICE REQUEST SERVICE - Solicitudes de autorización de equipos (admin)
// =============================================================================
//
// Endpoints solo para superusuarios. JWT y X-Device-ID los inyecta el
// interceptor de HttpService; los tokens viven en flutter_secure_storage.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:stampcamera/models/admin/device_request_model.dart';
import 'package:stampcamera/services/http_service.dart';

class DeviceRequestService {
  DeviceRequestService({Dio? dio}) : _dio = dio ?? HttpService().dio;

  final Dio _dio;

  static const _requestsPath = 'api/v1/admin/device-requests/';
  static const _equiposPath = 'api/v1/admin/equipos-confianza/';

  /// GET /api/v1/admin/device-requests/
  Future<List<DeviceRequest>> list() async {
    final response = await _dio.get(_requestsPath);
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Respuesta inválida del servidor');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(DeviceRequest.fromJson)
        .toList();
  }

  /// POST /api/v1/admin/device-requests/resolve-code/
  Future<DeviceRequest> resolveCode(String userCode) async {
    final response = await _dio.post(
      '${_requestsPath}resolve-code/',
      data: {'user_code': userCode},
    );
    return DeviceRequest.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/admin/device-requests/{id}/approve/
  Future<DeviceRequest> approve(
    int requestId,
    DeviceApprovalScope scope,
  ) async {
    final response = await _dio.post(
      '$_requestsPath$requestId/approve/',
      data: {'approval_scope': scope.wire},
    );
    return DeviceRequest.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/admin/device-requests/{id}/reject/
  Future<DeviceRequest> reject(int requestId) async {
    final response = await _dio.post('$_requestsPath$requestId/reject/');
    return DeviceRequest.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/v1/admin/equipos-confianza/
  /// Acepta respuesta plana o paginada ({results: [...]}).
  Future<List<EquipoConfianza>> listEquipos() async {
    final response = await _dio.get(_equiposPath);
    final data = response.data;
    final items = data is List
        ? data
        : (data is Map<String, dynamic> ? data['results'] : null);
    if (items is! List) {
      throw const FormatException('Respuesta inválida del servidor');
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(EquipoConfianza.fromJson)
        .toList();
  }

  /// Mensaje legible a partir de un error de red/backend.
  /// Nunca incluye tokens ni payloads.
  static String messageFromError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      switch (error.response?.statusCode) {
        case 401:
        case 403:
          return 'No tienes permisos para esta acción';
        case 404:
          return 'Código inválido o expirado';
        case 409:
          return 'La solicitud ya fue resuelta';
        case 429:
          return 'Demasiadas solicitudes, intenta en unos segundos';
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tiempo de conexión agotado';
        case DioExceptionType.connectionError:
          return 'Error de conexión. Verifica tu internet.';
        default:
          break;
      }
    }
    return 'Ocurrió un error inesperado';
  }
}
