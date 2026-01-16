// services/autos/contenedor_service.dart
import 'package:stampcamera/core/base_service_imp.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
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

  /// Crear contenedor con archivos
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

  /// Actualizar contenedor (MEJORADO para limpiar campos)
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
      // ✅ Para limpiar zona_inspeccion, enviar null explícitamente
      'zona_inspeccion_id': zonaInspeccion,
      // ✅ Para limpiar precintos, enviar string vacío o null
      'precinto1': precinto1?.isEmpty == true ? null : precinto1,
      'precinto2': precinto2?.isEmpty == true ? null : precinto2,
    };
    print("ContenedorService.updateContenedor: $data");
    return await partialUpdate(id, data);
  }

  /// Limpiar campos específicos del contenedor
  Future<ContenedorModel> clearContenedorFields({
    required int id,
    bool clearPrecinto1 = false,
    bool clearPrecinto2 = false,
    bool clearZonaInspeccion = false,
    bool clearFotoPrecinto1 = false,
    bool clearFotoPrecinto2 = false,
    bool clearFotoContenedorVacio = false,
  }) async {
    final data = <String, dynamic>{};

    // ✅ Para limpiar campos de texto
    if (clearPrecinto1) data['precinto1'] = null;
    if (clearPrecinto2) data['precinto2'] = null;
    if (clearZonaInspeccion) data['zona_inspeccion_id'] = null;

    // ✅ Para eliminar fotos específicas
    if (clearFotoPrecinto1) data['foto_precinto1'] = null;
    if (clearFotoPrecinto2) data['foto_precinto2'] = null;
    if (clearFotoContenedorVacio) data['foto_contenedor_vacio'] = null;

    if (data.isEmpty) {
      throw Exception('No se especificaron campos para limpiar');
    }

    print("ContenedorService.clearContenedorFields: $data");
    return await partialUpdate(id, data);
  }

  /// Actualizar con archivos nuevos y limpieza de campos
  Future<ContenedorModel> updateContenedorWithFiles({
    required int id,
    String? nContenedor,
    int? naveDescarga,
    int? zonaInspeccion,
    String? precinto1,
    String? precinto2,
    String? fotoContenedorPath,
    String? fotoPrecinto1Path,
    String? fotoPrecinto2Path,
    String? fotoContenedorVacioPath,
    // ✅ Flags para eliminar fotos existentes
    bool removeFotoContenedor = false,
    bool removeFotoPrecinto1 = false,
    bool removeFotoPrecinto2 = false,
    bool removeFotoContenedorVacio = false,
  }) async {
    try {
      final data = <String, dynamic>{};
      final filePaths = <String, String>{};

      // ✅ Actualizar campos básicos
      if (nContenedor != null) data['n_contenedor'] = nContenedor;
      if (naveDescarga != null) data['nave_descarga_id'] = naveDescarga;

      // ✅ Manejar zona_inspeccion (null para limpiar)
      if (zonaInspeccion != null) {
        data['zona_inspeccion_id'] = zonaInspeccion;
      }

      // ✅ Manejar precintos (null o string vacío para limpiar)
      if (precinto1 != null) {
        data['precinto1'] = precinto1.isEmpty ? null : precinto1;
      }
      if (precinto2 != null) {
        data['precinto2'] = precinto2.isEmpty ? null : precinto2;
      }

      // ✅ Eliminar fotos existentes
      if (removeFotoContenedor) data['foto_contenedor'] = null;
      if (removeFotoPrecinto1) data['foto_precinto1'] = null;
      if (removeFotoPrecinto2) data['foto_precinto2'] = null;
      if (removeFotoContenedorVacio) data['foto_contenedor_vacio'] = null;

      // ✅ Agregar nuevas fotos
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

      // ✅ Usar updateWithFiles si hay archivos, sino partialUpdate
      if (filePaths.isNotEmpty) {
        return await updateWithFiles(id, data, filePaths);
      } else {
        return await partialUpdate(id, data);
      }
    } catch (e) {
      throw Exception('Error al actualizar contenedor: $e');
    }
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
