// =============================================================================
// CASOS SERVICE - API REST para Casos y Documentos
// =============================================================================
//
// Endpoints: /api/casos-documentos/
// Maneja: Carpetas, Archivos, Historial, Upload, Mover, Eliminar, Restaurar
// =============================================================================

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:stampcamera/models/casos/explorador_models.dart';
import 'package:stampcamera/services/http_service.dart';

class CasosService {
  static final CasosService _instance = CasosService._internal();
  factory CasosService() => _instance;
  CasosService._internal();

  final _http = HttpService();
  static const String _basePath = 'api/casos-documentos';

  // ─── Carpetas ──────────────────────────────────────────────────────────

  /// Listar carpetas raíz (agrupables por rubro)
  Future<List<Carpeta>> getCarpetasRaiz({int? page}) async {
    final queryParams = <String, dynamic>{'solo_raiz': 'true'};
    if (page != null) queryParams['page'] = page;

    final response = await _http.dio.get(
      '$_basePath/carpetas/',
      queryParameters: queryParams,
    );

    final results = response.data['results'] as List;
    return results
        .map((e) => Carpeta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtener contenido completo de una carpeta
  Future<CarpetaContenidoResponse> getContenidoCarpeta(
    int carpetaId, {
    bool showDeleted = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (showDeleted) queryParams['show_deleted'] = 'true';

    final response = await _http.dio.get(
      '$_basePath/carpetas/$carpetaId/contenido-completo/',
      queryParameters: queryParams,
    );

    return CarpetaContenidoResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Crear subcarpeta
  Future<Carpeta> crearCarpeta({
    required String nombre,
    required int parentId,
  }) async {
    final response = await _http.dio.post(
      '$_basePath/carpetas/',
      data: {'nombre': nombre, 'parent': parentId},
    );

    return Carpeta.fromJson(response.data as Map<String, dynamic>);
  }

  /// Eliminar carpeta (soft delete)
  Future<void> eliminarCarpeta(int carpetaId) async {
    await _http.dio.delete('$_basePath/carpetas/$carpetaId/');
  }

  /// Restaurar carpeta (solo superadmin)
  Future<Carpeta> restaurarCarpeta(int carpetaId) async {
    final response = await _http.dio.post(
      '$_basePath/carpetas/$carpetaId/restaurar/',
    );
    return Carpeta.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mover múltiples carpetas a un destino
  Future<Map<String, dynamic>> moverCarpetas({
    required List<int> carpetaIds,
    required int destinoId,
  }) async {
    final response = await _http.dio.post(
      '$_basePath/carpetas/mover-multiple/',
      data: {
        'carpeta_ids': carpetaIds,
        'destino_id': destinoId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Obtener historial de una carpeta (solo superadmin)
  Future<List<HistorialEntry>> getHistorial(int carpetaId) async {
    final response = await _http.dio.get(
      '$_basePath/carpetas/$carpetaId/historial/',
    );

    final historial = response.data['historial'] as List;
    return historial
        .map((e) => HistorialEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Archivos ──────────────────────────────────────────────────────────

  /// Subir múltiples archivos a una carpeta
  Future<UploadMultipleResponse> uploadArchivos({
    required int carpetaId,
    required List<File> archivos,
    void Function(double)? onProgress,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('carpeta', carpetaId.toString()));

    for (final file in archivos) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      formData.files.add(MapEntry(
        'archivos',
        await MultipartFile.fromFile(file.path, filename: fileName),
      ));
    }

    final response = await _http.dio.post(
      '$_basePath/archivos/upload-multiple/',
      data: formData,
      onSendProgress: onProgress != null
          ? (sent, total) {
              if (total > 0) onProgress(sent / total);
            }
          : null,
    );

    return UploadMultipleResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Eliminar archivo (soft delete)
  Future<void> eliminarArchivo(int archivoId) async {
    await _http.dio.delete('$_basePath/archivos/$archivoId/');
  }

  /// Restaurar archivo (solo superadmin)
  Future<Archivo> restaurarArchivo(int archivoId) async {
    final response = await _http.dio.post(
      '$_basePath/archivos/$archivoId/restaurar/',
    );
    return Archivo.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mover múltiples archivos a otra carpeta
  Future<Map<String, dynamic>> moverArchivos({
    required List<int> archivoIds,
    required int carpetaDestinoId,
  }) async {
    final response = await _http.dio.post(
      '$_basePath/archivos/mover-multiple/',
      data: {
        'archivo_ids': archivoIds,
        'carpeta_destino_id': carpetaDestinoId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Descargar selección como ZIP
  Future<Response<List<int>>> downloadZip({
    List<int> archivoIds = const [],
    List<int> carpetaIds = const [],
  }) async {
    final response = await _http.dio.post<List<int>>(
      '$_basePath/archivos/download-selection-zip/',
      data: {
        'archivo_ids': archivoIds,
        'carpeta_ids': carpetaIds,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return response;
  }
}
