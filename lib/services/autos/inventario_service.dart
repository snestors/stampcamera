// services/inventario_base_service.dart
import 'package:dio/dio.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
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

  /// Listar inventarios agrupados con paginación - CORREGIDO PARA USAR MODELO TIPADO
  Future<InventarioListResponse> list({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: queryParameters,
      );

      return InventarioListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al listar inventarios: $e');
    }
  }

  /// Buscar inventarios - CORREGIDO PARA USAR MODELO TIPADO
  Future<InventarioListResponse> search(
    String query, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      final params = <String, dynamic>{'search': query, ...?filters};

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: params,
      );

      return InventarioListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Error en búsqueda de inventarios: $e');
    }
  }

  /// Cargar más inventarios (siguiente página) - CORREGIDO PARA USAR MODELO TIPADO
  Future<InventarioListResponse> loadMore(String url) async {
    try {
      final uri = Uri.parse(url);
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      final response = await _http.dio.get(path);

      return InventarioListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al cargar más inventarios: $e');
    }
  }

  /// Obtener inventario específico por información de unidad ID
  Future<InventarioBaseResponse> getByInformacionUnidad(
    int informacionUnidadId,
  ) async {
    try {
      print('/api/v1/autos/inventarios-base/$informacionUnidadId/');
      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/$informacionUnidadId/',
      );
      return InventarioBaseResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener inventario: $e');
    }
  }

  /// Crear inventario
  Future<InventarioBase> create({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
  }) async {
    try {
      // Agregar informacion_unidad_id a los datos
      final dataToSend = {
        ...inventarioData,
        'informacion_unidad_id': informacionUnidadId,
      };
      print(dataToSend);
      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base/',
        data: dataToSend,
      );

      return InventarioBase.fromJson(response.data);
    } on DioException catch (e) {
      print(e.response?.data);
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('detail')) {
            throw Exception(errorData['detail']);
          }

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

  /// Actualizar inventario completo
  Future<InventarioBase> update(
    int informacionUnidadId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _http.dio.put(
        '/api/v1/autos/inventarios-base/$informacionUnidadId/',
        data: data,
      );
      return InventarioBase.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  /// Actualizar inventario parcialmente
  Future<InventarioBase> partialUpdate(
    int informacionUnidadId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _http.dio.patch(
        '/api/v1/autos/inventarios-base/$informacionUnidadId/',
        data: data,
      );
      return InventarioBase.fromJson(response.data);
    } on DioException catch (e) {
      print("Error DIo: ${e.message}");
      throw Exception('Error al actualizar inventario: $e');
    }
  }

  /// Eliminar inventario
  Future<void> delete(int informacionUnidadId) async {
    try {
      await _http.dio.delete(
        '/api/v1/autos/inventarios-base/$informacionUnidadId/',
      );
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
        'imagen': await MultipartFile.fromFile(imagePath),
        if (descripcion != null) 'descripcion': descripcion,
      });

      final response = await _http.dio.post(
        '/api/v1/autos/inventarios-base/$informacionUnidadId/imagenes/',
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
        '/api/v1/autos/inventarios-base/$informacionUnidadId/imagenes/',
      );

      if (response.data is List) {
        final results = response.data as List;
        return results.map((json) => InventarioImagen.fromJson(json)).toList();
      }

      if (response.data is Map && response.data['results'] != null) {
        final results = response.data['results'] as List;
        return results.map((json) => InventarioImagen.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error al obtener imágenes: $e');
    }
  }

  /// Actualizar imagen de inventario
  Future<InventarioImagen> updateImage({
    required int informacionUnidadId,
    required int imageId,
    String? imagePath,
    String? descripcion,
  }) async {
    try {
      final formData = FormData();

      if (imagePath != null) {
        formData.files.add(
          MapEntry('imagen', await MultipartFile.fromFile(imagePath)),
        );
      }

      if (descripcion != null) {
        formData.fields.add(MapEntry('descripcion', descripcion));
      }

      final response = await _http.dio.patch(
        '/api/v1/autos/inventarios-base/$informacionUnidadId/imagenes/$imageId/',
        data: formData,
        options: Options(
          extra: imagePath != null
              ? {
                  'file_paths': {'imagen': imagePath},
                }
              : null,
        ),
      );

      return InventarioImagen.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al actualizar imagen: $e');
    }
  }

  /// Eliminar imagen de inventario
  Future<void> deleteImage({
    required int informacionUnidadId,
    required int imageId,
  }) async {
    try {
      await _http.dio.delete(
        '/api/v1/autos/inventarios-base/$informacionUnidadId/imagenes/$imageId/',
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
    final createdImages = <InventarioImagen>[];

    for (int i = 0; i < imagePaths.length; i++) {
      try {
        final imagen = await createImage(
          informacionUnidadId: informacionUnidadId,
          imagePath: imagePaths[i],
          descripcion: descripciones != null && i < descripciones.length
              ? descripciones[i]
              : null,
        );
        createdImages.add(imagen);
      } catch (e) {
        print('Error creando imagen ${i + 1}: $e');
      }
    }

    return createdImages;
  }

  /// Buscar inventarios por filtros específicos - CORREGIDO PARA USAR MODELO TIPADO
  Future<List<InventarioNave>> searchByFilters({
    int? marcaId,
    String? modelo,
    String? version,
    String? embarque,
    int? naveDescargaId,
    int? agenteId,
    bool? tieneInventario,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (marcaId != null) 'marca_id': marcaId,
        if (modelo != null && modelo.isNotEmpty) 'modelo': modelo,
        if (version != null && version.isNotEmpty) 'version': version,
        if (embarque != null && embarque.isNotEmpty) 'embarque': embarque,
        if (naveDescargaId != null) 'nave_descarga_id': naveDescargaId,
        if (agenteId != null) 'agente_id': agenteId,
        if (tieneInventario != null) 'tiene_inventario': tieneInventario,
      };

      final response = await _http.dio.get(
        '/api/v1/autos/inventarios-base/',
        queryParameters: queryParams,
      );

      final listResponse = InventarioListResponse.fromJson(response.data);
      return listResponse.results;
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
    String format = 'excel',
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
      final options = await getOptions(
        marcaId: marcaId,
        modelo: modelo,
        version: version,
      );

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

      if (campo.required && (value == null || value.toString().isEmpty)) {
        errors[campo.name] = '${campo.verboseName} es requerido';
        continue;
      }

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

  /// Crear inventario desde un objeto InventarioBase
  Future<InventarioBase> createFromInventario({
    required int informacionUnidadId,
    required InventarioBase inventario,
  }) async {
    return await create(
      informacionUnidadId: informacionUnidadId,
      inventarioData: inventario.toInventarioData(),
    );
  }

  /// Actualizar inventario desde un objeto InventarioBase
  Future<InventarioBase> updateFromInventario({
    required int informacionUnidadId,
    required InventarioBase inventario,
  }) async {
    return await partialUpdate(
      informacionUnidadId,
      inventario.toInventarioData(),
    );
  }

  /// Obtener lista de unidades sin inventario - CORREGIDO PARA USAR MODELO TIPADO
  Future<List<InventarioNave>> getUnidadesSinInventario({
    int? marcaId,
    int? agenteId,
    int? naveDescargaId,
  }) async {
    return await searchByFilters(
      marcaId: marcaId,
      agenteId: agenteId,
      naveDescargaId: naveDescargaId,
      tieneInventario: false,
    );
  }

  /// Obtener lista de unidades con inventario - CORREGIDO PARA USAR MODELO TIPADO
  Future<List<InventarioNave>> getUnidadesConInventario({
    int? marcaId,
    int? agenteId,
    int? naveDescargaId,
  }) async {
    return await searchByFilters(
      marcaId: marcaId,
      agenteId: agenteId,
      naveDescargaId: naveDescargaId,
      tieneInventario: true,
    );
  }

  /// Obtener inventarios por agente - CORREGIDO PARA USAR MODELO TIPADO
  Future<List<InventarioNave>> getInventariosByAgente(int agenteId) async {
    return await searchByFilters(agenteId: agenteId);
  }

  /// Obtener inventarios por nave - CORREGIDO PARA USAR MODELO TIPADO
  Future<List<InventarioNave>> getInventariosByNave(int naveId) async {
    return await searchByFilters(naveDescargaId: naveId);
  }

  /// Extraer primer error de campo para mostrar al usuario
  String? _extractFirstFieldError(Map<String, dynamic> errorData) {
    for (final entry in errorData.entries) {
      if (entry.key != 'detail' && entry.value is List) {
        final errors = entry.value as List;
        if (errors.isNotEmpty) {
          return '${entry.key}: ${errors.first}';
        }
      }
    }
    return null;
  }
}
