import 'package:dio/dio.dart';
import '../models/paginated_response.dart';
import '../services/http_service.dart';
import 'base_service.dart';

/// Implementación base para servicios Django DRF
abstract class BaseServiceImpl<T> implements BaseService<T> {
  final _http = HttpService();

  // ============================================================================
  // MÉTODOS CRUD BÁSICOS
  // ============================================================================

  @override
  Future<PaginatedResponse<T>> list({
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _http.dio.get(
      endpoint,
      queryParameters: queryParameters,
    );
    return PaginatedResponse<T>.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<T>> search(
    String query, {
    Map<String, dynamic>? filters,
  }) async {
    final params = <String, dynamic>{'search': query, ...?filters};

    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse<T>.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<T>> loadMore(String url) async {
    final uri = Uri.parse(url);
    final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    final response = await _http.dio.get(path);
    return PaginatedResponse<T>.fromJson(response.data, fromJson);
  }

  @override
  Future<T> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return fromJson(response.data);
  }

  @override
  Future<T> create(Map<String, dynamic> data) async {
    final response = await _http.dio.post(endpoint, data: data);
    return fromJson(response.data);
  }

  @override
  Future<T> update(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.put('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<T> partialUpdate(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.patch('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<void> delete(int id) async {
    await _http.dio.delete('$endpoint$id/');
  }

  // ============================================================================
  // MÉTODOS PARA ACTIONS PERSONALIZADAS
  // ============================================================================

  @override
  Future<Map<String, dynamic>> executeAction(
    String action, {
    int? id,
    Map<String, dynamic>? data,
  }) async {
    final url = id != null ? '$endpoint$id/$action/' : '$endpoint$action/';
    final response = await _http.dio.post(url, data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAction(
    String action, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _http.dio.get(
      '$endpoint$action/',
      queryParameters: queryParameters,
    );
    return response.data;
  }

  // ============================================================================
  // MÉTODOS PARA MANEJO DE ARCHIVOS
  // ============================================================================

  @override
  Future<T> createWithFiles(
    Map<String, dynamic> data,
    Map<String, String> filePaths,
  ) async {
    final formData = await _buildFormData(data, filePaths);
    final response = await _http.dio.post(
      endpoint,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return fromJson(response.data);
  }

  @override
  Future<T> updateWithFiles(
    int id,
    Map<String, dynamic> data,
    Map<String, String> filePaths,
  ) async {
    final formData = await _buildFormData(data, filePaths);
    final response = await _http.dio.patch(
      '$endpoint$id/',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return fromJson(response.data);
  }

  // ============================================================================
  // MÉTODOS PRIVADOS AUXILIARES
  // ============================================================================

  Future<FormData> _buildFormData(
    Map<String, dynamic> data,
    Map<String, String> filePaths,
  ) async {
    final formData = FormData();

    // Agregar datos regulares
    data.forEach((key, value) {
      formData.fields.add(MapEntry(key, value.toString()));
    });

    // Agregar archivos
    for (final entry in filePaths.entries) {
      formData.files.add(
        MapEntry(entry.key, await MultipartFile.fromFile(entry.value)),
      );
    }

    return formData;
  }
}
