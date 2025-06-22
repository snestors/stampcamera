// services/registro_vin_service.dart
import 'package:dio/dio.dart';
import 'package:stampcamera/models/autos/registro_vin_options.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/services/http_service.dart';

class RegistroVinService {
  final _http = HttpService();

  Future<RegistroVinOptions> getOptions() async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/registro-vin/options/',
      );
      return RegistroVinOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones: $e');
    }
  }

  Future<List<RegistroGeneral>> searchRegistros({
    String? search,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      };

      final response = await _http.dio.get(
        '/api/v1/autos/registro-vin/',
        queryParameters: queryParams,
      );

      final results = response.data['results'] as List;
      return results.map((json) => RegistroGeneral.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en búsqueda: $e');
    }
  }

  Future<RegistroGeneral> createRegistro({
    required String vin,
    required String condicion,
    required int zonaInspeccion,
    required String fotoPath,
    int? bloqueId,
    int? fila,
    int? posicion,
    int? contenedorId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'vin': vin,
        'condicion': condicion,
        'zona_inspeccion': zonaInspeccion,
        'foto_vin': await MultipartFile.fromFile(fotoPath),
        if (bloqueId != null) 'bloque': bloqueId,
        if (fila != null) 'fila': fila,
        if (posicion != null) 'posicion': posicion,
        if (contenedorId != null) 'contenedor': contenedorId,
      });

      final response = await _http.dio.post(
        '/api/v1/autos/registro-vin/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'foto_vin': fotoPath},
          },
        ),
      );

      return RegistroGeneral.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('non_field_errors')) {
          final nonFieldErrors = errorData['non_field_errors'];
          if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
            throw Exception(nonFieldErrors.first.toString());
          }
        }

        if (errorData is Map<String, dynamic>) {
          final firstError = _extractFirstFieldError(errorData);
          if (firstError != null) {
            throw Exception(firstError);
          }
        }

        throw Exception('Error de validación en los datos');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Sesión expirada, inicia sesión nuevamente');
      }

      throw Exception('Error del servidor (${e.response?.statusCode})');
    } catch (e) {
      throw Exception('Error al crear registro: $e');
    }
  }

  String? _extractFirstFieldError(Map<String, dynamic> errorData) {
    for (final entry in errorData.entries) {
      if (entry.key != 'non_field_errors' && entry.value is List) {
        final errors = entry.value as List;
        if (errors.isNotEmpty) {
          return '${entry.key}: ${errors.first}';
        }
      }
    }
    return null;
  }
}
