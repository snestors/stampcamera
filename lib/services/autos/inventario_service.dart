// services/inventario_base_service.dart
import 'package:dio/dio.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/models/paginated_response.dart';
import 'package:stampcamera/services/http_service.dart';

class InventarioBaseService {
  final _http = HttpService();

  /// Obtener opciones de inventario con datos previos
  Future<InventarioOptions> getOptions({
    int? marcaId,
    String? modelo,
    String? version,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (marcaId != null) queryParams['marca_id'] = marcaId;
      if (modelo != null && modelo.isNotEmpty) queryParams['modelo'] = modelo;
      if (version != null && version.isNotEmpty) {
        queryParams['version'] = version;
      }

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/options/',
        queryParameters: queryParams,
      );

      return InventarioOptions.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener opciones de inventario: $e');
    }
  }

  /// Listar inventarios con paginación
  Future<PaginatedResponse<InventarioBase>> list({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: queryParameters,
      );
      return PaginatedResponse<InventarioBase>.fromJson(
        response.data,
        (json) => InventarioBase.fromJson(json),
      );
    } catch (e) {
      throw Exception('Error al listar inventarios: $e');
    }
  }

  /// Buscar inventarios
  Future<PaginatedResponse<InventarioBase>> search(
    String query, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      final params = <String, dynamic>{'search': query, ...?filters};

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: params,
      );
      return PaginatedResponse<InventarioBase>.fromJson(
        response.data,
        (json) => InventarioBase.fromJson(json),
      );
    } catch (e) {
      throw Exception('Error en búsqueda de inventarios: $e');
    }
  }

  /// Cargar más inventarios (siguiente página)
  Future<PaginatedResponse<InventarioBase>> loadMore(String url) async {
    try {
      final uri = Uri.parse(url);
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      final response = await _http.dio.get(path);
      return PaginatedResponse<InventarioBase>.fromJson(
        response.data,
        (json) => InventarioBase.fromJson(json),
      );
    } catch (e) {
      throw Exception('Error al cargar más inventarios: $e');
    }
  }

  /// Obtener inventario por ID
  Future<InventarioBase> retrieve(int id) async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/$id/',
      );
      return InventarioBase.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener inventario: $e');
    }
  }

  /// Obtener inventario por información de unidad
  Future<InventarioBase?> getByInformacionUnidad(
    int informacionUnidadId,
  ) async {
    try {
      final response = await list(
        queryParameters: {'informacion_unidad_id': informacionUnidadId},
      );

      return response.results.isNotEmpty ? response.results.first : null;
    } catch (e) {
      throw Exception('Error al obtener inventario por unidad: $e');
    }
  }

  /// Crear inventario
  Future<InventarioBase> create({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
  }) async {
    try {
      final data = {
        'informacion_unidad': informacionUnidadId,
        ...inventarioData,
      };

      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base/',
        data: data,
      );

      return InventarioBase.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          // Errores globales
          if (errorData.containsKey('non_field_errors')) {
            final nonFieldErrors = errorData['non_field_errors'];
            if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
              throw Exception(nonFieldErrors.first.toString());
            }
          }

          // Errores por campo
          final firstError = _extractFirstFieldError(errorData);
          if (firstError != null) {
            throw Exception(firstError);
          }
        }

        throw Exception('Error de validación en los datos');
      }

      if (e.response?.statusCode == 404) {
        throw Exception('Información de unidad no encontrada');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Sesión expirada, inicia sesión nuevamente');
      }

      throw Exception('Error del servidor (${e.response?.statusCode})');
    } catch (e) {
      throw Exception('Error al crear inventario: $e');
    }
  }

  /// Crear inventario desde objeto InventarioBase
  Future<InventarioBase> createFromInventario(InventarioBase inventario) async {
    return await create(
      informacionUnidadId: inventario.informacionUnidad.id,
      inventarioData: inventario.toInventarioData(),
    );
  }

  /// Actualizar inventario completo
  Future<InventarioBase> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _http.dio.put(
        '/api/v1/autos/inventarios-base/$id/',
        data: data,
      );
      return InventarioBase.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  /// Actualizar inventario parcialmente
  Future<InventarioBase> partialUpdate(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _http.dio.patch(
        '/api/v1/autos/inventarios-base/$id/',
        data: data,
      );
      return InventarioBase.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  /// Eliminar inventario
  Future<void> delete(int id) async {
    try {
      await _http.dio.delete('/api/v1/autos/inventarios-base/$id/');
    } catch (e) {
      throw Exception('Error al eliminar inventario: $e');
    }
  }

  /// Crear imagen de inventario
  Future<InventarioImagen> createImage({
    required int informacionUnidadId,
    required String imagePath,
    String? descripcion,
  }) async {
    try {
      final formData = FormData.fromMap({
        'informacion_unidad': informacionUnidadId,
        'imagen': await MultipartFile.fromFile(imagePath),
        if (descripcion != null) 'descripcion': descripcion,
      });

      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base-imagenes/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'imagen': imagePath},
          },
        ),
      );

      return InventarioImagen.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear imagen de inventario: $e');
    }
  }

  /// Listar imágenes de inventario
  Future<List<InventarioImagen>> getImages(int informacionUnidadId) async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base-imagenes/',
        queryParameters: {'informacion_unidad_id': informacionUnidadId},
      );

      final results = response.data['results'] as List;
      return results.map((json) => InventarioImagen.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener imágenes: $e');
    }
  }

  /// Eliminar imagen de inventario
  Future<void> deleteImage(int imageId) async {
    try {
      await _http.dio.delete(
        '/api/v1/autos/inventarios-base-imagenes/$imageId/',
      );
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Crear múltiples imágenes de inventario
  Future<List<InventarioImagen>> createMultipleImages({
    required int informacionUnidadId,
    required List<String> imagePaths,
    List<String>? descripciones,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(
        MapEntry('informacion_unidad', informacionUnidadId.toString()),
      );

      // Agregar imágenes
      for (int i = 0; i < imagePaths.length; i++) {
        formData.files.add(
          MapEntry('imagen_$i', await MultipartFile.fromFile(imagePaths[i])),
        );

        // Agregar descripción si existe
        if (descripciones != null && i < descripciones.length) {
          formData.fields.add(MapEntry('descripcion_$i', descripciones[i]));
        }
      }

      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base-imagenes/bulk_create/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': Map.fromIterables(
              imagePaths.asMap().keys.map((i) => 'imagen_$i'),
              imagePaths,
            ),
          },
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final imagenes = data['imagenes'] as List;
      return imagenes.map((json) => InventarioImagen.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al crear múltiples imágenes: $e');
    }
  }

  /// Buscar inventarios por filtros específicos
  Future<List<InventarioBase>> searchByFilters({
    int? marcaId,
    String? modelo,
    String? version,
    String? embarque,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (marcaId != null) 'marca_id': marcaId,
        if (modelo != null && modelo.isNotEmpty) 'modelo': modelo,
        if (version != null && version.isNotEmpty) 'version': version,
        if (embarque != null && embarque.isNotEmpty) 'embarque': embarque,
        'page': page,
      };

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: queryParams,
      );

      final results = response.data['results'] as List;
      return results.map((json) => InventarioBase.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en búsqueda por filtros: $e');
    }
  }

  /// Obtener estadísticas de inventario
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/stats/',
      );
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Exportar inventarios a Excel/CSV
  Future<String> exportToFile({
    String format = 'excel', // 'excel' o 'csv'
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format, ...?filters};

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/export/',
        queryParameters: queryParams,
      );

      return response.data['download_url'];
    } catch (e) {
      throw Exception('Error al exportar inventarios: $e');
    }
  }

  /// Sincronizar inventario con inventario base previo
  Future<InventarioBase> syncWithPrevious({
    required int informacionUnidadId,
    int? marcaId,
    String? modelo,
    String? version,
  }) async {
    try {
      // Obtener opciones con inventario previo
      final options = await getOptions(
        marcaId: marcaId,
        modelo: modelo,
        version: version,
      );

      // Crear inventario con datos previos
      final inventarioData = Map<String, dynamic>.from(
        options.inventarioPrevio,
      );

      return await create(
        informacionUnidadId: informacionUnidadId,
        inventarioData: inventarioData,
      );
    } catch (e) {
      throw Exception('Error al sincronizar con inventario previo: $e');
    }
  }

  /// Validar datos de inventario antes de envío
  Map<String, String> validateInventarioData(
    Map<String, dynamic> data,
    List<CampoInventario> campos,
  ) {
    final errors = <String, String>{};

    for (final campo in campos) {
      final value = data[campo.name];

      // Validar campos requeridos
      if (campo.required && (value == null || value.toString().isEmpty)) {
        errors[campo.name] = '${campo.verboseName} es requerido';
        continue;
      }

      // Validar tipos de datos
      if (value != null) {
        if (campo.isNumericField && value is! int) {
          try {
            int.parse(value.toString());
          } catch (e) {
            errors[campo.name] = '${campo.verboseName} debe ser un número';
          }
        }
      }
    }

    return errors;
  }

  /// Extraer primer error de campo para mostrar al usuario
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
