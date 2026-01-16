import '../models/paginated_response.dart';

/// Interface base para servicios que interactúan con Django DRF ViewSets
abstract class BaseService<T> {
  /// Endpoint base del ViewSet (ej: '/api/v1/autos/registro-general/')
  String get endpoint;

  /// Parser function para convertir JSON a modelo
  T Function(Map<String, dynamic>) get fromJson;

  // ============================================================================
  // MÉTODOS CRUD BÁSICOS (Django DRF ViewSet estándar)
  // ============================================================================

  /// GET {endpoint}/ - Lista con paginación
  Future<PaginatedResponse<T>> list({Map<String, dynamic>? queryParameters});

  /// GET {endpoint}/?search=query - Búsqueda con paginación
  Future<PaginatedResponse<T>> search(
    String query, {
    Map<String, dynamic>? filters,
  });

  /// GET {url} - Cargar siguiente página desde URL de paginación
  Future<PaginatedResponse<T>> loadMore(String url);

  /// GET {endpoint}/{id}/ - Detalle por ID
  Future<T> retrieve(int id);

  /// POST {endpoint}/ - Crear nuevo registro
  Future<T> create(Map<String, dynamic> data);

  /// PUT {endpoint}/{id}/ - Actualizar registro completo
  Future<T> update(int id, Map<String, dynamic> data);

  /// PATCH {endpoint}/{id}/ - Actualizar parcialmente
  Future<T> partialUpdate(int id, Map<String, dynamic> data);

  /// DELETE {endpoint}/{id}/ - Eliminar registro
  Future<void> delete(int id);

  // ============================================================================
  // MÉTODOS PARA ACTIONS PERSONALIZADAS (Django @action)
  // ============================================================================

  /// POST {endpoint}/{id}/{action}/ - Action con POST
  Future<Map<String, dynamic>> executeAction(
    String action, {
    int? id,
    Map<String, dynamic>? data,
  });

  /// GET {endpoint}/{action}/ - Action con GET
  Future<Map<String, dynamic>> getAction(
    String action, {
    Map<String, dynamic>? queryParameters,
  });

  // ============================================================================
  // MÉTODOS PARA MANEJO DE ARCHIVOS (MultiPartParser)
  // ============================================================================

  /// POST con FormData para upload de archivos
  Future<T> createWithFiles(
    Map<String, dynamic> data,
    Map<String, String> filePaths,
  );

  /// PATCH con FormData para actualizar con archivos
  Future<T> updateWithFiles(
    int id,
    Map<String, dynamic> data,
    Map<String, String> filePaths,
  );
}
