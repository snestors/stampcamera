// services/contenedor_service.dart
import 'package:dio/dio.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/models/paginated_response.dart';
import 'package:stampcamera/services/http_service.dart';

class ContenedorService {
  final _http = HttpService();

  /// Obtener opciones dinámicas para formulario
  Future<ContenedorOptions> getOptions() async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/contenedores/options/',
      );
      return ContenedorOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones: $e');
    }
  }

  /// Listar contenedores con paginación completa
  Future<PaginatedResponse<ContenedorModel>> searchContenedores({
    String? search,
    int? naveDescargaId,
    int? zonaInspeccionId,
    String? nextUrl, // Para usar el next URL completo de Django
  }) async {
    try {
      String endpoint;
      Map<String, dynamic>? queryParams;

      if (nextUrl != null) {
        // ✅ CORREGIDO: Si hay nextUrl, usar ese directamente
        final uri = Uri.parse(nextUrl);
        endpoint = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
        queryParams = null; // No enviar parámetros adicionales
      } else {
        // ✅ CORREGIDO: Si no hay nextUrl, crear la consulta inicial sin page
        endpoint = '/api/v1/autos/contenedores/';
        queryParams = <String, dynamic>{
          if (search != null && search.isNotEmpty) 'search': search,
          if (naveDescargaId != null) 'nave_descarga_id': naveDescargaId,
          if (zonaInspeccionId != null) 'zona_inspeccion_id': zonaInspeccionId,
          // ❌ ELIMINADO: 'page': page - Django maneja la paginación automáticamente
        };
      }

      final response = await _http.dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      return PaginatedResponse.fromJson(
        response.data,
        (json) => ContenedorModel.fromJson(json),
      );
    } catch (e) {
      throw Exception('Error en búsqueda: $e');
    }
  }

  /// Crear contenedor con fotos - CORREGIDO el campo nave_descarga_id
  Future<ContenedorModel> createContenedor({
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? fotoContenedorPath,
    String? precinto1,
    String? fotoPrecinto1Path,
    String? precinto2,
    String? fotoPrecinto2Path,
    String? fotoContenedorVacioPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'n_contenedor': nContenedor,
        'nave_descarga_id': naveDescarga, // ✅ CORREGIDO: usar nave_descarga_id
        if (zonaInspeccion != null)
          'zona_inspeccion_id':
              zonaInspeccion, // ✅ CORREGIDO: usar zona_inspeccion_id
        if (precinto1 != null && precinto1.isNotEmpty) 'precinto1': precinto1,
        if (precinto2 != null && precinto2.isNotEmpty) 'precinto2': precinto2,
      });

      // Agregar fotos si existen
      if (fotoContenedorPath != null) {
        formData.files.add(
          MapEntry(
            'foto_contenedor',
            await MultipartFile.fromFile(fotoContenedorPath),
          ),
        );
      }

      if (fotoPrecinto1Path != null) {
        formData.files.add(
          MapEntry(
            'foto_precinto1',
            await MultipartFile.fromFile(fotoPrecinto1Path),
          ),
        );
      }

      if (fotoPrecinto2Path != null) {
        formData.files.add(
          MapEntry(
            'foto_precinto2',
            await MultipartFile.fromFile(fotoPrecinto2Path),
          ),
        );
      }

      if (fotoContenedorVacioPath != null) {
        formData.files.add(
          MapEntry(
            'foto_contenedor_vacio',
            await MultipartFile.fromFile(fotoContenedorVacioPath),
          ),
        );
      }

      final response = await _http.dio.post(
        '/api/v1/autos/contenedores/',
        data: formData,
      );

      return ContenedorModel.fromJson(response.data);
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
      throw Exception('Error al crear contenedor: $e');
    }
  }

  /// Obtener detalles de un contenedor específico
  Future<ContenedorModel> getContenedor(int id) async {
    try {
      final response = await _http.dio.get('/api/v1/autos/contenedores/$id/');
      return ContenedorModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener contenedor: $e');
    }
  }

  /// Actualizar contenedor
  Future<ContenedorModel> updateContenedor({
    required int id,
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? precinto1,
    String? precinto2,
  }) async {
    try {
      final data = {
        'n_contenedor': nContenedor,
        'nave_descarga_id': naveDescarga, // ✅ CORREGIDO: usar nave_descarga_id
        if (zonaInspeccion != null)
          'zona_inspeccion_id':
              zonaInspeccion, // ✅ CORREGIDO: usar zona_inspeccion_id
        if (precinto1 != null) 'precinto1': precinto1,
        if (precinto2 != null) 'precinto2': precinto2,
      };

      final response = await _http.dio.patch(
        '/api/v1/autos/contenedores/$id/',
        data: data,
      );

      return ContenedorModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar contenedor: $e');
    }
  }

  /// Eliminar contenedor
  Future<void> deleteContenedor(int id) async {
    try {
      await _http.dio.delete('/api/v1/autos/contenedores/$id/');
    } catch (e) {
      throw Exception('Error al eliminar contenedor: $e');
    }
  }

  /// Extraer primer error de campo para mostrar al usuario
  String? _extractFirstFieldError(Map<String, dynamic> errorData) {
    for (final entry in errorData.entries) {
      if (entry.key != 'non_field_errors' && entry.value is List) {
        final errors = entry.value as List;
        if (errors.isNotEmpty) {
          // Mapear nombres de campos técnicos a nombres amigables
          String fieldName = _getFieldDisplayName(entry.key);
          return '$fieldName: ${errors.first}';
        }
      }
    }
    return null;
  }

  /// Mapear nombres técnicos de campos a nombres amigables
  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'n_contenedor':
        return 'Número de contenedor';
      case 'nave_descarga':
      case 'nave_descarga_id':
        return 'Nave de descarga';
      case 'zona_inspeccion':
      case 'zona_inspeccion_id':
        return 'Zona de inspección';
      case 'precinto1':
        return 'Precinto 1';
      case 'precinto2':
        return 'Precinto 2';
      case 'foto_contenedor':
        return 'Foto del contenedor';
      case 'foto_precinto1':
        return 'Foto del precinto 1';
      case 'foto_precinto2':
        return 'Foto del precinto 2';
      case 'foto_contenedor_vacio':
        return 'Foto del contenedor vacío';
      default:
        return fieldName;
    }
  }
}
