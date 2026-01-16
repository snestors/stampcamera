// lib/providers/autos/inventario_base_provider.dart
import 'package:dio/dio.dart';
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
// PROVIDER PRINCIPAL DE LISTA AGRUPADA - CORREGIDO PARA USAR MODELO TIPADO
// ============================================================================

final inventarioBaseProvider =
    AsyncNotifierProvider<InventarioBaseNotifier, List<InventarioNave>>(
      InventarioBaseNotifier.new,
    );

class InventarioBaseNotifier extends AsyncNotifier<List<InventarioNave>> {
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
  Future<List<InventarioNave>> build() async {
    _service = ref.read(inventarioBaseServiceProvider);
    ref.keepAlive(); // Restaurar keepAlive para evitar rebuilds innecesarios
    return await loadInitial();
  }

  // ============================================================================
  // MÉTODOS DE NAVEGACIÓN Y CARGA
  // ============================================================================

  Future<List<InventarioNave>> loadInitial() async {
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

  Future<void> searchByFilters({
    int? marcaId,
    String? modelo,
    String? version,
    String? embarque,
    int? naveDescargaId,
    int? agenteId,
    bool? tieneInventario,
  }) async {
    state = const AsyncValue.loading();

    try {
      final naves = await _service.searchByFilters(
        marcaId: marcaId,
        modelo: modelo,
        version: version,
        embarque: embarque,
        naveDescargaId: naveDescargaId,
        agenteId: agenteId,
        tieneInventario: tieneInventario,
      );

      _searchQuery = 'filters';
      _nextUrl = null;
      state = AsyncValue.data(naves);
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    }
  }

  Future<void> filterSinInventario({
    int? marcaId,
    int? agenteId,
    int? naveDescargaId,
  }) async {
    await searchByFilters(
      marcaId: marcaId,
      agenteId: agenteId,
      naveDescargaId: naveDescargaId,
      tieneInventario: false,
    );
  }

  Future<void> filterConInventario({
    int? marcaId,
    int? agenteId,
    int? naveDescargaId,
  }) async {
    await searchByFilters(
      marcaId: marcaId,
      agenteId: agenteId,
      naveDescargaId: naveDescargaId,
      tieneInventario: true,
    );
  }

  // ============================================================================
  // MÉTODOS PRIVADOS AUXILIARES
  // ============================================================================

  void _notifyState() {
    if (state.hasValue) {
      state = AsyncValue.data([...state.value!]);
    }
  }
}

// ============================================================================
// PROVIDER PARA INVENTARIO ESPECÍFICO - SIN CAMBIOS
// ============================================================================

final inventarioDetalleProvider =
    AsyncNotifierProvider.family<
      InventarioDetalleNotifier,
      InventarioBaseResponse,
      int
    >(InventarioDetalleNotifier.new);

class InventarioDetalleNotifier
    extends FamilyAsyncNotifier<InventarioBaseResponse, int> {
  @override
  Future<InventarioBaseResponse> build(int informacionUnidadId) async {
    final service = ref.read(inventarioBaseServiceProvider);
    // Siempre traer datos frescos del servidor
    return await service.getByInformacionUnidad(informacionUnidadId);
  }

  Future<InventarioBase> createInventario(
    Map<String, dynamic> inventarioData,
  ) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final inventario = await service.create(
        informacionUnidadId: arg,
        inventarioData: inventarioData,
      );

      final current = state.value;
      if (current != null) {
        final updated = InventarioBaseResponse(
          informacionUnidad: current.informacionUnidad,
          imagenes: current.imagenes,
          inventario: inventario,
        );
        state = AsyncValue.data(updated);
      }

      return inventario;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<InventarioBase> updateInventario(
    Map<String, dynamic> inventarioData,
  ) async {
    try {
      print("arg: $arg, invetarioData: $inventarioData");
      final service = ref.read(inventarioBaseServiceProvider);
      final inventario = await service.partialUpdate(arg, inventarioData);

      final current = state.value;
      if (current != null) {
        final updated = InventarioBaseResponse(
          informacionUnidad: current.informacionUnidad,
          imagenes: current.imagenes,
          inventario: inventario,
        );
        state = AsyncValue.data(updated);
      }

      return inventario;
    } on DioException catch (e) {
      print("Error: ${e.message}");
      throw Exception(parseError(e));
    }
  }

  Future<void> deleteInventario() async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      await service.delete(arg);

      final current = state.value;
      if (current != null) {
        final updated = InventarioBaseResponse(
          informacionUnidad: current.informacionUnidad,
          imagenes: current.imagenes,
          inventario: null,
        );
        state = AsyncValue.data(updated);
      }
    } catch (e) {
      throw Exception(parseError(e));
    }
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

      final current = state.value;
      if (current != null) {
        final updated = InventarioBaseResponse(
          informacionUnidad: current.informacionUnidad,
          imagenes: [...current.imagenes, newImage],
          inventario: current.inventario,
        );
        state = AsyncValue.data(updated);
      }
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<void> deleteImage(int imageId) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      await service.deleteImage(informacionUnidadId: arg, imageId: imageId);

      final current = state.value;
      if (current != null) {
        final filtered = current.imagenes
            .where((img) => img.id != imageId)
            .toList();
        final updated = InventarioBaseResponse(
          informacionUnidad: current.informacionUnidad,
          imagenes: filtered,
          inventario: current.inventario,
        );
        state = AsyncValue.data(updated);
      }
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final response = await service.getByInformacionUnidad(arg);
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    }
  }

  Future<InventarioBase> syncWithPrevious({
    int? marcaId,
    String? modelo,
    String? version,
  }) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final inventario = await service.syncWithPrevious(
        informacionUnidadId: arg,
        marcaId: marcaId,
        modelo: modelo,
        version: version,
      );

      final current = state.value;
      if (current != null) {
        final updated = InventarioBaseResponse(
          informacionUnidad: current.informacionUnidad,
          imagenes: current.imagenes,
          inventario: inventario,
        );
        state = AsyncValue.data(updated);
      }

      return inventario;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }
}

// ============================================================================
// PROVIDER DE OPCIONES - SIN CAMBIOS
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
// PROVIDER DE ESTADÍSTICAS - SIN CAMBIOS
// ============================================================================

final inventarioStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.read(inventarioBaseServiceProvider);
  return await service.getStats();
});

// ============================================================================
// PROVIDER PARA MANEJO DE IMÁGENES - SIN CAMBIOS
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

  Future<void> updateImage({
    required int imageId,
    String? imagePath,
    String? descripcion,
  }) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      final updatedImage = await service.updateImage(
        informacionUnidadId: arg,
        imageId: imageId,
        imagePath: imagePath,
        descripcion: descripcion,
      );

      final current = state.value ?? [];
      final updatedList = current.map((img) {
        if (img.id == imageId) {
          return updatedImage;
        }
        return img;
      }).toList();

      state = AsyncValue.data(updatedList);
    } catch (e) {
      throw Exception(parseError(e));
    }
  }

  Future<void> deleteImage(int imageId) async {
    try {
      final service = ref.read(inventarioBaseServiceProvider);
      await service.deleteImage(informacionUnidadId: arg, imageId: imageId);

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

// ============================================================================
// PROVIDERS DE FILTROS ESPECÍFICOS - CORREGIDOS PARA USAR MODELO TIPADO
// ============================================================================

final unidadesSinInventarioProvider =
    FutureProvider.family<List<InventarioNave>, Map<String, dynamic>>((
      ref,
      filters,
    ) async {
      final service = ref.read(inventarioBaseServiceProvider);
      return await service.getUnidadesSinInventario(
        marcaId: filters['marcaId'],
        agenteId: filters['agenteId'],
        naveDescargaId: filters['naveDescargaId'],
      );
    });

final unidadesConInventarioProvider =
    FutureProvider.family<List<InventarioNave>, Map<String, dynamic>>((
      ref,
      filters,
    ) async {
      final service = ref.read(inventarioBaseServiceProvider);
      return await service.getUnidadesConInventario(
        marcaId: filters['marcaId'],
        agenteId: filters['agenteId'],
        naveDescargaId: filters['naveDescargaId'],
      );
    });

final inventariosByAgenteProvider =
    FutureProvider.family<List<InventarioNave>, int>((ref, agenteId) async {
      final service = ref.read(inventarioBaseServiceProvider);
      return await service.getInventariosByAgente(agenteId);
    });

final inventariosByNaveProvider =
    FutureProvider.family<List<InventarioNave>, int>((ref, naveId) async {
      final service = ref.read(inventarioBaseServiceProvider);
      return await service.getInventariosByNave(naveId);
    });

// ============================================================================
// PROVIDERS AUXILIARES - SIN CAMBIOS
// ============================================================================

final inventarioFormProvider =
    NotifierProvider.family<InventarioFormNotifier, Map<String, dynamic>, int>(
      InventarioFormNotifier.new,
    );

class InventarioFormNotifier extends FamilyNotifier<Map<String, dynamic>, int> {
  @override
  Map<String, dynamic> build(int informacionUnidadId) {
    return {};
  }

  void updateField(String field, dynamic value) {
    state = {...state, field: value};
  }

  void updateMultipleFields(Map<String, dynamic> fields) {
    state = {...state, ...fields};
  }

  void resetForm() {
    state = {};
  }

  void loadFromOptions(InventarioOptions options) {
    state = Map<String, dynamic>.from(options.inventarioPrevio);
  }

  void loadFromInventario(InventarioBase inventario) {
    state = inventario.toInventarioData();
  }

  Map<String, String> validateForm(List<CampoInventario> campos) {
    final service = ref.read(inventarioBaseServiceProvider);
    return service.validateInventarioData(state, campos);
  }

  Future<InventarioBase> submitForm() async {
    final service = ref.read(inventarioBaseServiceProvider);
    final inventario = await service.create(
      informacionUnidadId: arg,
      inventarioData: state,
    );

    resetForm();
    return inventario;
  }

  Future<InventarioBase> updateForm() async {
    final service = ref.read(inventarioBaseServiceProvider);
    final inventario = await service.partialUpdate(arg, state);

    return inventario;
  }
}
