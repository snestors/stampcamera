// lib/services/autos/detalle_registro_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/services/http_service.dart';

/// Servicio completo para manejar detalles de registro y sus operaciones
class DetalleRegistroService {
  final _http = HttpService();

  // ============================================================================
  // OPERACIONES PRINCIPALES
  // ============================================================================

  /// Obtener detalle completo por VIN
  /// GET /api/v1/autos/registro-general/{vin}/
  Future<DetalleRegistroModel> getByVin(String vin) async {
    final response = await _http.dio.get(
      '/api/v1/autos/registro-general/$vin/',
    );
    return DetalleRegistroModel.fromJson(response.data);
  }

  // ============================================================================
  // REGISTRO VIN OPERATIONS
  // ============================================================================

  /// Obtener opciones de registro VIN
  Future<Map<String, dynamic>> getRegistroVinOptions() async {
    final response = await _http.dio.get('/api/v1/autos/registro-vin/options/?registros=True');
    return response.data;
  }

  /// Crear registro VIN simple - FIX para capturar errores 400
  Future<Map<String, dynamic>> createRegistroVin({
    required String vin,
    required String condicion,
    required int zonaInspeccion,
    required File fotoVin,
    int? bloque,
    int? fila,
    int? posicion,
    int? contenedorId,
  }) async {
    final formData = FormData();

    // Campos obligatorios
    formData.fields.addAll([
      MapEntry('vin', vin),
      MapEntry('condicion', condicion),
      MapEntry('zona_inspeccion', zonaInspeccion.toString()),
    ]);

    // Campos opcionales
    if (bloque != null) {
      formData.fields.add(MapEntry('bloque', bloque.toString()));
    }
    if (fila != null) {
      formData.fields.add(MapEntry('fila', fila.toString()));
    }
    if (posicion != null) {
      formData.fields.add(MapEntry('posicion', posicion.toString()));
    }
    if (contenedorId != null) {
      formData.fields.add(MapEntry('contenedor', contenedorId.toString()));
    }

    // Foto obligatoria
    formData.files.add(
      MapEntry('foto_vin', await MultipartFile.fromFile(fotoVin.path)),
    );

    try {
      final response = await _http.dio.post(
        '/api/v1/autos/registro-vin/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'foto_vin': fotoVin.path},
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      // ✅ Si es error 400, devolver la respuesta como si fuera exitosa
      // para que el provider pueda leer el mensaje de error
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        debugPrint(
          '🔧 Interceptando error 400, devolviendo data: ${e.response!.data}',
        );
        return e.response!.data as Map<String, dynamic>;
      }

      // ✅ Para otros errores, re-lanzar la excepción
      rethrow;
    }
  }

  /// Actualizar registro VIN
  /// PUT /api/v1/autos/registro-vin/{id}/
  Future<Map<String, dynamic>> updateRegistroVin({
    required int registroVinId,
    String? condicion,
    int? zonaInspeccion,
    File? fotoVin,
    int? bloque,
    int? fila,
    int? posicion,
    int? contenedorId,
  }) async {
    final formData = FormData();

    // Solo agregar campos que se van a actualizar
    if (condicion != null) {
      formData.fields.add(MapEntry('condicion', condicion));
    }
    if (zonaInspeccion != null) {
      formData.fields.add(
        MapEntry('zona_inspeccion', zonaInspeccion.toString()),
      );
    }
    if (bloque != null) {
      formData.fields.add(MapEntry('bloque', bloque.toString()));
    }
    if (fila != null) {
      formData.fields.add(MapEntry('fila', fila.toString()));
    }
    if (posicion != null) {
      formData.fields.add(MapEntry('posicion', posicion.toString()));
    }
    if (contenedorId != null) {
      formData.fields.add(MapEntry('contenedor', contenedorId.toString()));
    }

    // Nueva foto si se proporciona
    if (fotoVin != null) {
      formData.files.add(
        MapEntry('foto_vin', await MultipartFile.fromFile(fotoVin.path)),
      );
    }

    final response = await _http.dio.put(
      '/api/v1/autos/registro-vin/$registroVinId/',
      data: formData,
    );

    return response.data;
  }

  /// Eliminar registro VIN
  /// DELETE /api/v1/autos/registro-vin/{id}/
  /// Retorna mensaje de error si no tiene permisos
  Future<Map<String, dynamic>> deleteRegistroVin(int registroVinId) async {
    try {
      await _http.dio.delete('/api/v1/autos/registro-vin/$registroVinId/');
      return {'success': true, 'message': 'Registro eliminado correctamente'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorMsg = e.response?.data?['error'] ?? 'No tienes permisos para eliminar este registro';
        return {'success': false, 'error': errorMsg};
      }
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        return e.response!.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  // ============================================================================
  // FOTOS DE PRESENTACIÓN OPERATIONS
  // ============================================================================

  /// GET /api/v1/autos/fotos-presentacion/options/
  Future<Map<String, dynamic>> getFotosOptions() async {
    final response = await _http.dio.get(
      '/api/v1/autos/fotos-presentacion/options/',
    );
    return response.data;
  }

  /// Crear foto individual
  /// POST /api/v1/autos/fotos-presentacion/
  Future<Map<String, dynamic>> createFoto({
    required int registroVinId,
    required String tipo,
    required File imagen,
    String? nDocumento,
  }) async {
    final formData = FormData.fromMap({
      'registro_vin': registroVinId,
      'tipo': tipo,
      'imagen': await MultipartFile.fromFile(imagen.path),
      if (nDocumento != null && nDocumento.isNotEmpty)
        'n_documento': nDocumento,
    });

    try {
      final response = await _http.dio.post(
        '/api/v1/autos/fotos-presentacion/',
        data: formData,
        options: Options(
          extra: {
            'file_paths': {'foto_vin': imagen.path},
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      // ✅ Si es error 400, devolver la respuesta como si fuera exitosa
      // para que el provider pueda leer el mensaje de error
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        return e.response!.data as Map<String, dynamic>;
      }

      rethrow;
    }
  }

  /// Actualizar foto (parcialmente)
  /// PATCH /api/v1/autos/fotos-presentacion/{id}/
  Future<Map<String, dynamic>> updateFoto({
    required int fotoId,
    String? tipo,
    File? imagen,
    String? nDocumento,
  }) async {
    final formData = FormData();

    // Solo agregar campos que se van a actualizar
    if (tipo != null) {
      formData.fields.add(MapEntry('tipo', tipo));
    }

    // n_documento puede ser string vacío para limpiar el campo
    if (nDocumento != null) {
      formData.fields.add(MapEntry('n_documento', nDocumento));
    }

    // Nueva imagen si se proporciona
    if (imagen != null) {
      formData.files.add(
        MapEntry('imagen', await MultipartFile.fromFile(imagen.path)),
      );
    }

    // Usar PATCH para actualización parcial (no requiere todos los campos)
    final response = await _http.dio.patch(
      '/api/v1/autos/fotos-presentacion/$fotoId/',
      data: formData,
    );

    return response.data;
  }

  /// Eliminar foto
  /// DELETE /api/v1/autos/fotos-presentacion/{id}/
  /// Retorna mensaje de error si no tiene permisos
  Future<Map<String, dynamic>> deleteFoto(int fotoId) async {
    try {
      await _http.dio.delete('/api/v1/autos/fotos-presentacion/$fotoId/');
      return {'success': true, 'message': 'Foto eliminada correctamente'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorMsg = e.response?.data?['error'] ?? 'No tienes permisos para eliminar esta foto';
        return {'success': false, 'error': errorMsg};
      }
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        return e.response!.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  // ============================================================================
  // DAÑOS OPERATIONS - IMPLEMENTACIÓN COMPLETA SEGÚN MANUAL API
  // ============================================================================

  /// Obtener opciones de daños
  /// GET /api/v1/autos/danos/options/
  Future<Map<String, dynamic>> getDanosOptions() async {
    final response = await _http.dio.get('/api/v1/autos/danos/options/');
    return response.data;
  }

  /// ✅ CREAR DAÑO CON MÚLTIPLES IMÁGENES - IMPLEMENTACIÓN SEGÚN MANUAL
  /// POST /api/v1/autos/danos/
  /// Formato FormData con imagen_0, imagen_1, imagen_2, etc.
  Future<Map<String, dynamic>> createDanoWithFormData({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<File>? imagenes,
    int? nDocumento,
  }) async {
    debugPrint('🔧 createDanoWithFormData - Parámetros:');
    debugPrint('   registroVinId: $registroVinId');
    debugPrint('   tipoDano: $tipoDano');
    debugPrint('   areaDano: $areaDano');
    debugPrint('   severidad: $severidad');
    debugPrint('   zonas: $zonas');
    debugPrint('   descripcion: $descripcion');
    debugPrint('   responsabilidad: $responsabilidad');
    debugPrint('   relevante: $relevante');
    debugPrint('   imagenes: ${imagenes?.length ?? 0}');

    final formData = FormData();

    // ✅ Campos obligatorios
    formData.fields.addAll([
      MapEntry('registro_vin', registroVinId.toString()),
      MapEntry('tipo_dano', tipoDano.toString()),
      MapEntry('area_dano', areaDano.toString()),
      MapEntry('severidad', severidad.toString()),
      MapEntry('relevante', relevante.toString()),
    ]);

    // ✅ Campos opcionales
    if (zonas != null && zonas.isNotEmpty) {
      for (final zona in zonas) {
        formData.fields.add(MapEntry('zonas', zona.toString()));
      }
    }

    if (descripcion != null && descripcion.isNotEmpty) {
      formData.fields.add(MapEntry('descripcion', descripcion));
    }

    if (responsabilidad != null) {
      formData.fields.add(
        MapEntry('responsabilidad', responsabilidad.toString()),
      );
    }

    if (nDocumento != null) {
      formData.fields.add(MapEntry('n_documento', nDocumento.toString()));
    }

    // ✅ Preparar mapa de file paths para múltiples imágenes
    final Map<String, String> filePaths = {};

    // ✅ Múltiples imágenes con formato imagen_0, imagen_1, imagen_2, etc.
    if (imagenes != null && imagenes.isNotEmpty) {
      for (int i = 0; i < imagenes.length; i++) {
        final fieldName = 'imagen_$i';
        final filePath = imagenes[i].path;

        // Agregar archivo al FormData
        formData.files.add(
          MapEntry(fieldName, await MultipartFile.fromFile(filePath)),
        );

        // ✅ CRUCIAL: Guardar path para reconexión automática
        filePaths[fieldName] = filePath;
      }
    }

    // 🐛 DEBUG: Mostrar datos finales a enviar
    debugPrint('🔧 FormData fields (${formData.fields.length}):');
    for (var field in formData.fields) {
      debugPrint('   ${field.key}: ${field.value}');
    }
    debugPrint('🔧 FormData files (${formData.files.length}):');
    for (var file in formData.files) {
      debugPrint('   ${file.key}: ${file.value.filename}');
    }
    debugPrint('🔧 File paths for reconnection: $filePaths');

    try {
      final response = await _http.requestWithConnectivity(
        '/api/v1/autos/danos/',
        method: 'POST',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          extra: {
            'file_paths': filePaths, // ✅ Esencial para reconexión automática
          },
        ),
      );

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('✅ Response data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      debugPrint('❌ DioException en createDanoWithFormData:');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');

      // ✅ Si es error 400, devolver la respuesta para que el provider pueda leer el error
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        return e.response!.data as Map<String, dynamic>;
      }

      rethrow;
    } catch (e) {
      debugPrint('❌ Error general en createDanoWithFormData: $e');
      rethrow;
    }
  }

  /// ✅ ACTUALIZAR DAÑO - IMPLEMENTACIÓN SEGÚN MANUAL
  /// PUT /api/v1/autos/danos/{id}/
  Future<Map<String, dynamic>> updateDano({
    required int danoId,
    required registroVinId,
    int? tipoDano,
    int? areaDano,
    int? severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool? relevante,
    int? nDocumento,
    List<File>? newImages, // ✅ Nuevas imágenes a agregar (opcional)
  }) async {
    debugPrint('🔧 updateDano - Parámetros:');
    debugPrint('   danoId: $danoId');
    debugPrint('   tipoDano: $tipoDano');
    debugPrint('   areaDano: $areaDano');
    debugPrint('   severidad: $severidad');
    debugPrint('   zonas: $zonas');
    debugPrint('   descripcion: $descripcion');
    debugPrint('   responsabilidad: $responsabilidad');
    debugPrint('   relevante: $relevante');
    debugPrint('   newImages: ${newImages?.length ?? 0}');

    final formData = FormData();

    // ✅ Solo agregar campos que no sean null
    if (registroVinId != null) {
      formData.fields.add(MapEntry('registro_vin', registroVinId.toString()));
    }
    if (tipoDano != null) {
      formData.fields.add(MapEntry('tipo_dano', tipoDano.toString()));
    }
    if (areaDano != null) {
      formData.fields.add(MapEntry('area_dano', areaDano.toString()));
    }
    if (severidad != null) {
      formData.fields.add(MapEntry('severidad', severidad.toString()));
    }
    if (nDocumento != null) {
      formData.fields.add(MapEntry('n_documento', nDocumento.toString()));
    }
    if (zonas != null && zonas.isNotEmpty) {
      // Agregar múltiples valores para zonas
      for (final zona in zonas) {
        formData.fields.add(MapEntry('zonas', zona.toString()));
      }
    }
    if (descripcion != null) {
      formData.fields.add(MapEntry('descripcion', descripcion));
    }
    if (responsabilidad != null) {
      formData.fields.add(
        MapEntry('responsabilidad', responsabilidad.toString()),
      );
    }
    if (relevante != null) {
      formData.fields.add(MapEntry('relevante', relevante.toString()));
    }

    // ✅ Preparar mapa de file paths para múltiples imágenes
    final Map<String, String> filePaths = {};

    // ✅ Agregar nuevas imágenes (0, 1, o múltiples)
    if (newImages != null && newImages.isNotEmpty) {
      for (int i = 0; i < newImages.length; i++) {
        final fieldName = 'imagen_$i';
        final filePath = newImages[i].path;

        // Agregar archivo al FormData
        formData.files.add(
          MapEntry(fieldName, await MultipartFile.fromFile(filePath)),
        );

        // ✅ CRUCIAL: Guardar path para reconexión automática
        filePaths[fieldName] = filePath;
      }
    }

    // 🐛 DEBUG: Mostrar datos finales a enviar
    debugPrint('🔧 FormData fields (${formData.fields.length}):');
    for (var field in formData.fields) {
      debugPrint('   ${field.key}: ${field.value}');
    }
    debugPrint('🔧 FormData files (${formData.files.length}):');
    for (var file in formData.files) {
      debugPrint('   ${file.key}: ${file.value.filename}');
    }
    debugPrint('🔧 File paths for reconnection: $filePaths');

    try {
      final response = await _http.requestWithConnectivity(
        '/api/v1/autos/danos/$danoId/',
        method: 'PATCH',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          extra: {
            'file_paths': filePaths, // ✅ Esencial para reconexión automática
          },
        ),
      );

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('✅ Response data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      debugPrint('❌ DioException en updateDano:');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');

      // ✅ Si es error 400, devolver la respuesta para que el provider pueda leer el error
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        return e.response!.data as Map<String, dynamic>;
      }

      rethrow;
    } catch (e) {
      debugPrint('❌ Error general en updateDano: $e');
      rethrow;
    }
  }

  /// ✅ ELIMINAR DAÑO - IMPLEMENTACIÓN SEGÚN MANUAL
  /// DELETE /api/v1/autos/danos/{id}/
  /// Retorna mensaje de error si no tiene permisos
  Future<Map<String, dynamic>> deleteDano(int danoId) async {
    try {
      final response = await _http.dio.delete('/api/v1/autos/danos/$danoId/');
      // El backend puede retornar data con success y message
      if (response.data != null && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Daño eliminado correctamente'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorMsg = e.response?.data?['error'] ?? 'No tienes permisos para eliminar este daño';
        return {'success': false, 'error': errorMsg};
      }
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        return e.response!.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  /// ✅ AGREGAR IMAGEN INDIVIDUAL A DAÑO - IMPLEMENTACIÓN SEGÚN MANUAL
  /// POST /api/v1/autos/danos/{id}/add_image/
  Future<Map<String, dynamic>> addImagenToDano({
    required int danoId,
    required File imagen,
  }) async {
    final formData = FormData();

    formData.files.add(
      MapEntry('imagen', await MultipartFile.fromFile(imagen.path)),
    );

    final response = await _http.dio.post(
      '/api/v1/autos/danos/$danoId/add_image/',
      data: formData,
    );

    return response.data;
  }

  /// ✅ ELIMINAR IMAGEN INDIVIDUAL DE DAÑO - IMPLEMENTACIÓN SEGÚN MANUAL
  /// DELETE /api/v1/autos/danos/{id}/remove_image/
  /// Payload: {"imagen_id": 1}
  /// Retorna mensaje de error si no tiene permisos
  Future<Map<String, dynamic>> removeImagenFromDano({
    required int danoId,
    required int imagenId,
  }) async {
    debugPrint('🔧 removeImagenFromDano:');
    debugPrint('   danoId: $danoId');
    debugPrint('   imagenId: $imagenId');

    try {
      final response = await _http.dio.delete(
        '/api/v1/autos/danos/$danoId/remove_image/?imagen_id=$imagenId',
      );

      debugPrint('✅ removeImagenFromDano response: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorMsg = e.response?.data?['error'] ?? 'No tienes permisos para eliminar imágenes';
        return {'success': false, 'error': errorMsg};
      }
      if (e.response?.statusCode == 400 && e.response?.data != null) {
        return e.response!.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  /// ✅ AGREGAR MÚLTIPLES IMÁGENES A DAÑO EXISTENTE - IMPLEMENTACIÓN SEGÚN MANUAL
  /// POST /api/v1/autos/danos/{id}/add_multiple_images/
  /// Formato: imagen_0, imagen_1, imagen_2, etc.
  Future<Map<String, dynamic>> addMultipleImagenesToDano({
    required int danoId,
    required List<File> imagenes,
  }) async {
    final formData = FormData();

    for (int i = 0; i < imagenes.length; i++) {
      formData.files.add(
        MapEntry('imagen_$i', await MultipartFile.fromFile(imagenes[i].path)),
      );
    }

    final response = await _http.dio.post(
      '/api/v1/autos/danos/$danoId/add_multiple_images/',
      data: formData,
    );

    return response.data;
  }

  // ============================================================================
  // MÉTODO LEGACY (MANTENER PARA COMPATIBILIDAD)
  // ============================================================================

  /// Crear daño con múltiples imágenes (MÉTODO LEGACY - PARA COMPATIBILIDAD)
  /// Este método usa el enfoque de dos pasos del código anterior

  Future<Map<String, dynamic>> createDanoWithImages({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<File>? imagenes,
    int? nDocumento,
  }) async {
    // Redirigir al método nuevo
    return await createDanoWithFormData(
      registroVinId: registroVinId,
      tipoDano: tipoDano,
      areaDano: areaDano,
      severidad: severidad,
      zonas: zonas,
      descripcion: descripcion,
      responsabilidad: responsabilidad,
      relevante: relevante,
      imagenes: imagenes,
      nDocumento: nDocumento,
    );
  }
}
