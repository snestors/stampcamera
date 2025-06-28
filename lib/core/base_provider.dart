/// Interface base para providers que manejan listas paginadas desde Django DRF
abstract class BaseListProvider<T> {
  // ============================================================================
  // PROPIEDADES DE ESTADO (solo lectura desde UI)
  // ============================================================================

  /// Indica si está cargando más elementos (paginación)
  bool get isLoadingMore;

  /// Indica si está ejecutando una búsqueda
  bool get isSearching;

  /// Indica si hay más páginas disponibles
  bool get hasNextPage;

  /// Query de búsqueda actual (null si no hay búsqueda activa)
  String? get currentSearchQuery;

  // ============================================================================
  // MÉTODOS DE NAVEGACIÓN Y CARGA
  // ============================================================================

  /// Carga inicial de datos (primera página)
  Future<List<T>> loadInitial();

  /// Carga más elementos (siguiente página)
  Future<void> loadMore();

  /// Refresca los datos actuales (pull-to-refresh)
  Future<void> refresh();

  // ============================================================================
  // MÉTODOS DE BÚSQUEDA
  // ============================================================================

  /// Búsqueda inmediata (para scanner, botón buscar, etc)
  Future<void> search(String query);

  /// Búsqueda con debounce (para TextField con cambios automáticos)
  void debouncedSearch(String query);

  /// Limpia la búsqueda y vuelve a la lista inicial
  Future<void> clearSearch();

  // ============================================================================
  // MÉTODOS DE MANEJO DE ESTADO
  // ============================================================================

  /// Limpia todos los datos y estado
  void clearAll();

  /// Fuerza invalidación del provider (para cambios externos)
  void forceInvalidate();

  // ============================================================================
  // MÉTODOS CRUD (opcionales, solo si el provider los maneja)
  // ============================================================================

  /// Crear nuevo elemento
  Future<T?> createItem(Map<String, dynamic> data);

  /// Actualizar elemento existente
  Future<T?> updateItem(int id, Map<String, dynamic> data);

  /// Eliminar elemento
  Future<bool> deleteItem(int id);

  /// Obtener elemento por ID (detalle)
  Future<T?> getById(int id);
}

/// Interface para providers que manejan un solo elemento (detalle)
abstract class BaseDetailProvider<T> {
  /// Cargar datos del elemento
  Future<T> load(int id);

  /// Actualizar elemento
  Future<T?> updateItem(Map<String, dynamic> data);

  /// Eliminar elemento
  Future<bool> deleteItem();

  /// Refrescar datos
  Future<void> refresh();

  /// Limpiar datos
  void clear();
}

/// Interface para providers que manejan formularios
abstract class BaseFormProvider<T> {
  /// Estado de carga del formulario
  bool get isLoading;

  /// Errores de validación
  Map<String, String> get errors;

  /// Enviar formulario
  Future<T?> submit(Map<String, dynamic> data);

  /// Validar campo individual
  String? validateField(String field, dynamic value);

  /// Limpiar errores
  void clearErrors();

  /// Resetear formulario
  void reset();
}
