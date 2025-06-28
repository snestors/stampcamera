// lib/services/autos/detalle_registro_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/autos/detalle_registro_model.dart';
import '../http_service.dart';

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

  /// Crear registro VIN simple
  /// POST /api/v1/autos/registro-vin/
  Future<Map<String, dynamic>> createRegistroVin({
    required String vin,
    required String condicion,
    required int zonaInspeccion,
    required File fotoVin, // ✅ OBLIGATORIA
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

    final response = await _http.dio.post(
      '/api/v1/autos/registro-vin/',
      data: formData,
    );

    return response.data;
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

  // ============================================================================
  // FOTOS DE PRESENTACIÓN OPERATIONS
  // ============================================================================

  /// Obtener tipos de documento disponibles
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
    final formData = FormData();

    formData.fields.addAll([
      MapEntry('registro_vin', registroVinId.toString()),
      MapEntry('tipo', tipo),
      if (nDocumento != null) MapEntry('n_documento', nDocumento),
    ]);

    formData.files.add(
      MapEntry('imagen', await MultipartFile.fromFile(imagen.path)),
    );

    final response = await _http.dio.post(
      '/api/v1/autos/fotos-presentacion/',
      data: formData,
    );

    return response.data;
  }

  /// Actualizar foto
  /// PUT /api/v1/autos/fotos-presentacion/{id}/
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
    if (nDocumento != null) {
      formData.fields.add(MapEntry('n_documento', nDocumento));
    }

    // Nueva imagen si se proporciona
    if (imagen != null) {
      formData.files.add(
        MapEntry('imagen', await MultipartFile.fromFile(imagen.path)),
      );
    }

    final response = await _http.dio.put(
      '/api/v1/autos/fotos-presentacion/$fotoId/',
      data: formData,
    );

    return response.data;
  }

  /// Eliminar foto
  /// DELETE /api/v1/autos/fotos-presentacion/{id}/
  Future<void> deleteFoto(int fotoId) async {
    await _http.dio.delete('/api/v1/autos/fotos-presentacion/$fotoId/');
  }

  // ============================================================================
  // DAÑOS OPERATIONS
  // ============================================================================

  /// Obtener opciones de daños
  /// GET /api/v1/autos/danos/options/
  Future<Map<String, dynamic>> getDanosOptions() async {
    final response = await _http.dio.get('/api/v1/autos/danos/options/');
    return response.data;
  }

  /// Crear daño con múltiples imágenes (MÉTODO ÚNICO)
  /// POST /api/v1/autos/danos/ + POST /api/v1/autos/danos/{id}/add_multiple_images/
  /// Este método unifica la creación del daño y la adición de imágenes en una sola operación
  Future<Map<String, dynamic>> createDanoWithImages({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<File>? imagenes, // ✅ Fotos opcionales
  }) async {
    // 1. Crear el daño primero
    final danoPayload = {
      'registro_vin': registroVinId,
      'tipo_dano': tipoDano,
      'area_dano': areaDano,
      'severidad': severidad,
      'relevante': relevante,
    };

    if (zonas != null) danoPayload['zonas'] = zonas;
    if (descripcion != null) danoPayload['descripcion'] = descripcion;
    if (responsabilidad != null)
      danoPayload['responsabilidad'] = responsabilidad;

    final danoResponse = await _http.dio.post(
      '/api/v1/autos/danos/',
      data: danoPayload,
    );

    final danoData = danoResponse.data;

    // 2. Si hay imágenes, agregarlas al daño creado
    if (imagenes != null && imagenes.isNotEmpty) {
      final danoId =
          danoData['data']['id']; // Asumir que la respuesta tiene este formato

      final formData = FormData();

      for (int i = 0; i < imagenes.length; i++) {
        formData.files.add(
          MapEntry('imagen_$i', await MultipartFile.fromFile(imagenes[i].path)),
        );
      }

      final imagenesResponse = await _http.dio.post(
        '/api/v1/autos/danos/$danoId/add_multiple_images/',
        data: formData,
      );

      // 3. Combinar respuestas
      return {
        'success': true,
        'message': 'Daño creado con ${imagenes.length} imágenes',
        'dano': danoData['data'],
        'imagenes': imagenesResponse.data['data'],
      };
    }

    // Si no hay imágenes, solo retornar el daño creado
    return {
      'success': true,
      'message': 'Daño creado sin imágenes',
      'dano': danoData['data'],
      'imagenes': [],
    };
  }

  /// Actualizar daño
  /// PUT /api/v1/autos/danos/{id}/
  Future<Map<String, dynamic>> updateDano({
    required int danoId,
    int? tipoDano,
    int? areaDano,
    int? severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool? relevante,
  }) async {
    final payload = <String, dynamic>{};

    // Solo agregar campos que se van a actualizar
    if (tipoDano != null) payload['tipo_dano'] = tipoDano;
    if (areaDano != null) payload['area_dano'] = areaDano;
    if (severidad != null) payload['severidad'] = severidad;
    if (zonas != null) payload['zonas'] = zonas;
    if (descripcion != null) payload['descripcion'] = descripcion;
    if (responsabilidad != null) payload['responsabilidad'] = responsabilidad;
    if (relevante != null) payload['relevante'] = relevante;

    final response = await _http.dio.put(
      '/api/v1/autos/danos/$danoId/',
      data: payload,
    );

    return response.data;
  }

  /// Eliminar daño
  /// DELETE /api/v1/autos/danos/{id}/
  Future<void> deleteDano(int danoId) async {
    await _http.dio.delete('/api/v1/autos/danos/$danoId/');
  }

  /// Agregar imagen a daño existente
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

  /// Eliminar imagen de daño
  /// DELETE /api/v1/autos/danos/{id}/remove_image/
  Future<Map<String, dynamic>> removeImagenFromDano({
    required int danoId,
    required int imagenId,
  }) async {
    final response = await _http.dio.delete(
      '/api/v1/autos/danos/$danoId/remove_image/',
      data: {'imagen_id': imagenId},
    );

    return response.data;
  }
}

// ============================================================================
// CLASES DE DATOS AUXILIARES
// ============================================================================

class FotoData {
  final File file;
  final String tipo;
  final String? nDocumento;

  const FotoData({required this.file, required this.tipo, this.nDocumento});
}

class DanoData {
  final int tipoDano;
  final int areaDano;
  final int severidad;
  final List<int>? zonas;
  final String? descripcion;
  final int? responsabilidad;
  final bool relevante;
  final List<File>? imagenes; // ✅ Fotos opcionales para el método unificado

  const DanoData({
    required this.tipoDano,
    required this.areaDano,
    required this.severidad,
    this.zonas,
    this.descripcion,
    this.responsabilidad,
    this.relevante = false,
    this.imagenes,
  });
}
