// services/autos/contenedor_service.dart
import 'package:stampcamera/core/base_service_imp.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/models/paginated_response.dart';
import 'package:dio/dio.dart';

class ContenedorService extends BaseServiceImpl<ContenedorModel> {
  @override
  String get endpoint => '/api/v1/autos/contenedores/';

  @override
  ContenedorModel Function(Map<String, dynamic>) get fromJson =>
      ContenedorModel.fromJson;

  // ============================================================================
  // MÉTODOS ESPECÍFICOS DE CONTENEDORES
  // ============================================================================

  /// Obtener opciones dinámicas para formulario
  Future<ContenedorOptions> getOptions() async {
    try {
      final response = await getAction('options');
      return ContenedorOptions.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener opciones: $e');
    }
  }

  /// Crear contenedor con archivos (sobrescribir método base para manejar FormData complejo)
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
      final data = <String, dynamic>{
        'n_contenedor': nContenedor,
        'nave_descarga_id': naveDescarga,
        if (zonaInspeccion != null) 'zona_inspeccion_id': zonaInspeccion,
        if (precinto1 != null && precinto1.isNotEmpty) 'precinto1': precinto1,
        if (precinto2 != null && precinto2.isNotEmpty) 'precinto2': precinto2,
      };

      final filePaths = <String, String>{};
      if (fotoContenedorPath != null) {
        filePaths['foto_contenedor'] = fotoContenedorPath;
      }
      if (fotoPrecinto1Path != null) {
        filePaths['foto_precinto1'] = fotoPrecinto1Path;
      }
      if (fotoPrecinto2Path != null) {
        filePaths['foto_precinto2'] = fotoPrecinto2Path;
      }
      if (fotoContenedorVacioPath != null) {
        filePaths['foto_contenedor_vacio'] = fotoContenedorVacioPath;
      }

      return await createWithFiles(data, filePaths);
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

  /// Actualizar contenedor (usar método base partialUpdate)
  Future<ContenedorModel> updateContenedor({
    required int id,
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? precinto1,
    String? precinto2,
  }) async {
    final data = {
      'n_contenedor': nContenedor,
      'nave_descarga_id': naveDescarga,
      if (zonaInspeccion != null) 'zona_inspeccion_id': zonaInspeccion,
      if (precinto1 != null) 'precinto1': precinto1,
      if (precinto2 != null) 'precinto2': precinto2,
    };

    return await partialUpdate(id, data);
  }

  // ============================================================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ============================================================================

  /// Extraer primer error de campo para mostrar al usuario
  String? _extractFirstFieldError(Map<String, dynamic> errorData) {
    for (final entry in errorData.entries) {
      if (entry.key != 'non_field_errors' && entry.value is List) {
        final errors = entry.value as List;
        if (errors.isNotEmpty) {
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
