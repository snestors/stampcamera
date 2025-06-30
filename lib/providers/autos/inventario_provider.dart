// lib/providers/autos/inventario_base_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/services/autos/inventario_service.dart';

// Función helper para parsear errores
String parseError(dynamic error) {
  if (error is Exception) {
    return error.toString().replaceFirst('Exception: ', '');
  }
  return error.toString();
}

// ============================================================================
// PROVIDER DEL SERVICIO
// ============================================================================

final inventarioBaseServiceProvider = Provider<InventarioBaseService>((ref) {
  return InventarioBaseService();
});

// ============================================================================
// PROVIDER PRINCIPAL DE LISTA
// ============================================================================

final inventarioBaseProvider =
    AsyncNotifierProvider<InventarioBaseNotifier, List<InventarioBase>>(
      InventarioBaseNotifier.new,
    );

class InventarioBaseNotifier extends AsyncNotifier<List<InventarioBase>> {
  late final InventarioBaseService _service;

  String? _searchQuery;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String? _nextUrl;

  // ============================================================================
  // GETTERS PARA UI
  // ============================================================================

  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  bool get hasNextPage => _nextUrl != null;
  String? get currentSearchQuery => _searchQuery;

  @override
  Future<List<InventarioBase>> build() async {
    _service = ref.read(inventarioBaseServiceProvider);
    ref.keepAlive();
    return await loadInitial();
  }

  // ============================================================================
  // MÉTODOS DE NAVEGACIÓN Y CARGA
  // ============================================================================

  Future<List<InventarioBase>> loadInitial() async {
    try {
      final paginated = await _service.list();
      _nextUrl = paginated.next;
      _searchQuery = null;
      _isSearching = false;
      return paginated.results;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextUrl == null) return;

    _isLoadingMore = true;
    _notifyState();

    try {
      final paginated = await _service.loadMore(_nextUrl!);
      final current = state.value ?? [];
      final newResults = [...current, ...paginated.results];

      _nextUrl = paginated.next;
      state = AsyncValue.data(newResults);
    } catch (e) {
      // No cambiar el estado en caso de error, solo log
      print('❌ Error cargando más resultados: ${parseError(e)}');
    } finally {
      _isLoadingMore = false;
      _notifyState();
    }
  }

  Future<void> refresh() async {
    if (_searchQuery != null) {
      await search(_searchQuery!);
    } else {
      state = const AsyncValue.loading();
      try {
        final initial = await loadInitial();
        state = AsyncValue.data(initial);
      } catch (e, st) {
        state = AsyncValue.error(Exception(parseError(e)), st);
      }
    }
  }

  // ============================================================================
  // MÉTODOS DE BÚSQUEDA
  // ============================================================================

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return clearSearch();
    }

    _isSearching = true;
    _searchQuery = trimmed;
    state = const AsyncValue.loading();

    try {
      final paginated = await _service.search(trimmed);
      _nextUrl = paginated.next;
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    } finally {
      _isSearching = false;
      _notifyState();
    }
  }

  void debouncedSearch(String query) {
    // Implementación simple sin debounce por ahora
    search(query);
  }

  Future<void> clearSearch() async {
    if (_searchQuery == null) return;

    _searchQuery = null;
    _isSearching = false;
    state = const AsyncValue.loading();

    try {
      final initial = await loadInitial();
      state = AsyncValue.data(initial);
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    }
  }

  // ============================================================================
  // MÉTODOS ESPECÍFICOS DEL DOMINIO
  // ============================================================================

  /// Buscar inventarios por filtros específicos
  Future<void> searchByFilters({
    int? marcaId,
    String? modelo,
    String? version,
    String? embarque,
  }) async {
    state = const AsyncValue.loading();

    try {
      final inventarios = await _service.searchByFilters(
        marcaId: marcaId,
        modelo: modelo,
        version: version,
        embarque: embarque,
      );

      _searchQuery = 'filters';
      _nextUrl = null; // Los filtros no tienen paginación por ahora
      state = AsyncValue.data(inventarios);
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    }
  }

  /// Obtener inventario por información de unidad
  Future<InventarioBase?> getByInformacionUnidad(
    int informacionUnidadId,
  ) async {
    try {
      return await _service.getByInformacionUnidad(informacionUnidadId);
    } catch (e) {
      return null;
    }
  }

  /// Crear inventario con datos específicos
  Future<InventarioBase?> createInventario({
    required int informacionUnidadId,
    required Map<String, dynamic> inventarioData,
  }) async {
    try {
      final inventario = await _service.create(
        informacionUnidadId: informacionUnidadId,
        inventarioData: inventarioData,
      );

      // Agregar al inicio de la lista actual
      final current = state.value ?? [];
      state = AsyncValue.data([inventario, ...current]);

      return inventario;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  /// Actualizar inventario existente
  Future<InventarioBase?> updateInventario({
    required int inventarioId,
    required Map<String, dynamic> inventarioData,
  }) async {
    try {
      final updatedInventario = await _service.partialUpdate(
        inventarioId,
        inventarioData,
      );

      // Actualizar en la lista actual
      final current = state.value ?? [];
      final updatedList = current.map((item) {
        if (item.id == inventarioId) {
          return updatedInventario;
        }
        return item;
      }).toList();

      state = AsyncValue.data(updatedList);
      return updatedInventario;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  /// Eliminar inventario
  Future<bool> deleteInventario(int inventarioId) async {
    try {
      await _service.delete(inventarioId);

      // Remover de la lista actual
      final current = state.value ?? [];
      final filteredList = current
          .where((item) => item.id != inventarioId)
          .toList();

      state = AsyncValue.data(filteredList);
      return true;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  /// Sincronizar con inventario base previo
  Future<InventarioBase?> syncWithPrevious({
    required int informacionUnidadId,
    int? marcaId,
    String? modelo,
    String? version,
  }) async {
    try {
      final inventario = await _service.syncWithPrevious(
        informacionUnidadId: informacionUnidadId,
        marcaId: marcaId,
        modelo: modelo,
        version: version,
      );

      // Agregar al inicio de la lista actual
      final current = state.value ?? [];
      state = AsyncValue.data([inventario, ...current]);

      return inventario;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  // ============================================================================
  // MÉTODOS PRIVADOS AUXILIARES
  // ============================================================================

  void _notifyState() {
    // Forzar notificación del estado para actualizar UI
    if (state.hasValue) {
      state = AsyncValue.data([...state.value!]);
    }
  }
}

// ============================================================================
// PROVIDER DE OPCIONES
// ============================================================================

final inventarioOptionsProvider =
    FutureProvider.family<InventarioOptions, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final service = ref.read(inventarioBaseServiceProvider);
      return await service.getOptions(
        marcaId: params['marcaId'],
        modelo: params['modelo'],
        version: params['version'],
      );
    });

// ============================================================================
// PROVIDER DE DETALLE POR INFORMACIÓN DE UNIDAD
// ============================================================================

final inventarioByUnidadProvider = FutureProvider.family<InventarioBase?, int>((
  ref,
  informacionUnidadId,
) async {
  final service = ref.read(inventarioBaseServiceProvider);
  try {
    return await service.getByInformacionUnidad(informacionUnidadId);
  } catch (e) {
    return null;
  }
});

// ============================================================================
// PROVIDER DE ESTADÍSTICAS
// ============================================================================

final inventarioStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.read(inventarioBaseServiceProvider);
  return await service.getStats();
});

// ============================================================================
// PROVIDER PARA MANEJO DE IMÁGENES
// ============================================================================

final inventarioImageProvider =
    AsyncNotifierProvider.family<
      InventarioImageNotifier,
      List<InventarioImagen>,
      int
    >(InventarioImageNotifier.new);

class InventarioImageNotifier
    extends FamilyAsyncNotifier<List<InventarioImagen>, int> {
  @override
  Future<List<InventarioImagen>> build(int informacionUnidadId) async {
    final service = ref.read(inventarioBaseServiceProvider);
    return await service.getImages(informacionUnidadId);
  }

  Future<void> addImage({
    required String imagePath,
    String? descripcion,
  }) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final newImage = await service.createImage(
        informacionUnidadId: arg,
        imagePath: imagePath,
        descripcion: descripcion,
      );

      final current = state.value ?? [];
      state = AsyncValue.data([...current, newImage]);
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<void> addMultipleImages({
    required List<String> imagePaths,
    List<String>? descripciones,
  }) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final newImages = await service.createMultipleImages(
        informacionUnidadId: arg,
        imagePaths: imagePaths,
        descripciones: descripciones,
      );

      final current = state.value ?? [];
      state = AsyncValue.data([...current, ...newImages]);
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<void> deleteImage(int imageId) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      await service.deleteImage(imageId);

      final current = state.value ?? [];
      final filtered = current.where((img) => img.id != imageId).toList();
      state = AsyncValue.data(filtered);
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final images = await service.getImages(arg);
      state = AsyncValue.data(images);
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    }
  }
}
