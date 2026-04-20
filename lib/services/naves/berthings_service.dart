import 'package:dio/dio.dart';
import 'package:stampcamera/models/naves/berthing_model.dart';
import 'package:stampcamera/services/http_service.dart';

class BerthingsService {
  final _http = HttpService();

  /// GET /api/v1/berthings/form_options/
  /// Devuelve estados disponibles + transiciones permitidas (backend cachea 1h).
  Future<BerthingsFormOptions> getFormOptions() async {
    try {
      final response = await _http.dio.get('/api/v1/berthings/form_options/');
      return BerthingsFormOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al cargar opciones de nave: $e');
    }
  }

  /// GET /api/v1/berthings/{naveId}/
  /// Devuelve el detalle actual de la nave (estatus + fechas).
  Future<BerthingDetail> getBerthing(int naveId) async {
    try {
      final response = await _http.dio.get('/api/v1/berthings/$naveId/');
      return BerthingDetail.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al cargar datos de la nave: $e');
    }
  }

  /// PATCH /api/v1/berthings/{naveId}/
  /// Actualiza estatus y/o fechas de la nave.
  Future<void> updateBerthing(int naveId, BerthingUpdatePayload payload) async {
    try {
      await _http.dio.patch(
        '/api/v1/berthings/$naveId/',
        data: payload.toJson(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('No tienes permisos para cambiar el estado de la nave');
      }
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final firstError = _extractFirstFieldError(data);
          if (firstError != null) throw Exception(firstError);
        }
        throw Exception('Datos inválidos');
      }
      throw Exception('Error del servidor (${e.response?.statusCode})');
    } catch (e) {
      throw Exception('Error al actualizar nave: $e');
    }
  }

  String? _extractFirstFieldError(Map<String, dynamic> errorData) {
    for (final entry in errorData.entries) {
      if (entry.key == 'detail' && entry.value is String) {
        return entry.value as String;
      }
      if (entry.value is List && (entry.value as List).isNotEmpty) {
        return '${entry.key}: ${(entry.value as List).first}';
      }
    }
    return null;
  }
}
