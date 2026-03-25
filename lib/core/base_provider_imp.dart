import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:stampcamera/core/helpers/debouncer.dart';
import 'package:stampcamera/core/base_provider.dart';
import 'package:stampcamera/core/base_service.dart';
import 'package:stampcamera/core/has_id.dart';

/// Implementación base para providers de listas paginadas
abstract class BaseListProviderImpl<T> extends AsyncNotifier<List<T>>
    implements BaseListProvider<T> {
  // Servicio a implementar por cada provider hijo
  BaseService<T> get service;

  final _debouncer = Debouncer();

  String? _nextUrl;
  String? _searchNextUrl;
  String? _searchQuery;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  int _searchToken = 0;

  // ============================================================================
  // PROPIEDADES DE ESTADO
  // ============================================================================

  @override
  bool get isLoadingMore => _isLoadingMore;

  @override
  bool get isSearching => _isSearching;

  @override
  bool get hasNextPage {
    if (_searchQuery != null) {
      return _searchNextUrl != null;
    }
    return _nextUrl != null;
  }

  @override
  String? get currentSearchQuery => _searchQuery;

  // ============================================================================
  // INICIALIZACIÓN
  // ============================================================================

  // TODO: Evaluar si keepAlive() es necesario para TODOS los providers.
  // Actualmente TODOS los que extienden BaseListProviderImpl se mantienen vivos,
  // lo que evita re-fetches innecesarios pero consume memoria.
  // Candidatos a autoDispose (no necesitan keepAlive):
  //   - Providers de detalle (detalleRegistroProvider, inventarioDetalleProvider)
  //   - Providers usados en una sola pantalla
  // Providers que SÍ necesitan keepAlive:
  //   - registroGeneralProvider, contenedorProvider (listas principales)
  //   - inventarioBaseProvider (lista principal inventario)
  //   - serviciosGranelesProvider (lista principal graneles)
  // NO se cambió porque remover keepAlive puede causar que providers se destruyan
  // al navegar entre pantallas, perdiendo datos cargados y forzando re-fetches.
  // Requiere pruebas exhaustivas pantalla por pantalla.
  @override
  Future<List<T>> build() async {
    ref.keepAlive();
    return await loadInitial();
  }

  // ============================================================================
  // MÉTODOS DE NAVEGACIÓN Y CARGA
  // ============================================================================

  @override
  Future<List<T>> loadInitial() async {
    try {
      final paginated = await service.list();

      _nextUrl = paginated.next;
      _searchQuery = null;
      _searchNextUrl = null;
      _isSearching = false;

      return paginated.results;
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  @override
  Future<void> loadMore() async {
    if (_isLoadingMore) return;

    final url = _searchQuery != null ? _searchNextUrl : _nextUrl;
    if (url == null) return;

    _isLoadingMore = true;

    try {
      final paginated = await service.loadMore(url);
      final current = state.value ?? [];
      final newResults = [...current, ...paginated.results];

      state = AsyncValue.data(newResults);

      // Actualizar URLs para siguiente página
      if (_searchQuery != null) {
        _searchNextUrl = paginated.next;
      } else {
        _nextUrl = paginated.next;
      }
    } catch (e) {
      debugPrint('❌ Error cargando más resultados: ${_parseError(e)}');
    } finally {
      _isLoadingMore = false;
      state = AsyncValue.data([...?state.value]);
    }
  }

  @override
  Future<void> refresh() async {
    if (_searchQuery != null) {
      await search(_searchQuery!);
    } else {
      state = const AsyncValue.loading();
      try {
        final initial = await loadInitial();
        state = AsyncValue.data(initial);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  // ============================================================================
  // MÉTODOS DE BÚSQUEDA
  // ============================================================================

  @override
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return clearSearch();
    }

    // Evitar búsquedas duplicadas
    if (_searchQuery == trimmed && state.hasValue) {
      return;
    }

    debugPrint('🔍 Buscando: "$trimmed"');

    _isSearching = true;
    state = const AsyncValue.loading();
    _searchQuery = trimmed;
    _searchToken++;
    final currentToken = _searchToken;

    try {
      final paginated = await service.search(trimmed);

      // Verificar si esta búsqueda aún es relevante
      if (_searchToken != currentToken) {
        debugPrint('🔥 Ignorando respuesta de búsqueda obsoleta');
        return;
      }

      _searchNextUrl = paginated.next;
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      if (_searchToken == currentToken) {
        final errorMsg = _parseError(e);
        state = AsyncValue.error(Exception(errorMsg), st);
      }
    } finally {
      if (_searchToken == currentToken) {
        _isSearching = false;
        if (!state.hasError) {
          state = AsyncValue.data([...?state.value]);
        }
      }
    }
  }

  @override
  void debouncedSearch(String query) {
    _debouncer.run(() {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        clearSearch();
      } else {
        search(trimmed);
      }
    });
  }

  /// Lista con filtros personalizados y soporte de paginación.
  /// Los filtros se preservan automáticamente en las URLs de paginación del backend.
  Future<void> listWithFilters(Map<String, dynamic> filters) async {
    _isSearching = true;
    state = const AsyncValue.loading();
    _searchQuery = '__filter__'; // Marker para indicar modo filtro
    _searchToken++;
    final currentToken = _searchToken;

    try {
      final paginated = await service.list(queryParameters: filters);

      if (_searchToken != currentToken) return;

      _searchNextUrl = paginated.next;
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      if (_searchToken == currentToken) {
        state = AsyncValue.error(Exception(_parseError(e)), st);
      }
    } finally {
      if (_searchToken == currentToken) {
        _isSearching = false;
        if (!state.hasError) {
          state = AsyncValue.data([...?state.value]);
        }
      }
    }
  }

  @override
  Future<void> clearSearch() async {
    if (_searchQuery == null) return;

    state = const AsyncValue.loading();
    _searchQuery = null;
    _searchNextUrl = null;
    _isSearching = false;

    try {
      final initial = await loadInitial();
      state = AsyncValue.data(initial);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ============================================================================
  // MÉTODOS DE MANEJO DE ESTADO
  // ============================================================================

  @override
  void clearAll() {
    _nextUrl = null;
    _searchNextUrl = null;
    _searchQuery = null;
    _isLoadingMore = false;
    _isSearching = false;
    _searchToken = 0;
    state = const AsyncValue.loading();
  }

  @override
  void forceInvalidate() {
    ref.invalidateSelf();
  }

  // ============================================================================
  // MÉTODOS CRUD (implementación por defecto)
  // ============================================================================

  @override
  Future<T?> createItem(Map<String, dynamic> data) async {
    try {
      final newItem = await service.create(data);

      // Agregar al inicio de la lista actual
      final current = state.value ?? [];
      state = AsyncValue.data([newItem, ...current]);

      return newItem;
    } catch (e) {
      debugPrint('❌ Error creando elemento: ${_parseError(e)}');
      return null;
    }
  }

  @override
  Future<T?> updateItem(int id, Map<String, dynamic> data) async {
    try {
      final updatedItem = await service.update(id, data);

      // Actualizar en la lista actual
      final current = state.value ?? [];
      final updatedList = current.map((item) {
        if (item is HasId && item.id == id) {
          return updatedItem;
        }
        return item;
      }).toList();

      state = AsyncValue.data(updatedList);
      return updatedItem;
    } catch (e) {
      debugPrint('❌ Error actualizando elemento: ${_parseError(e)}');
      return null;
    }
  }

  @override
  Future<bool> deleteItem(int id) async {
    try {
      await service.delete(id);

      // Remover de la lista actual
      final current = state.value ?? [];
      final filteredList = current.where((item) {
        return item is! HasId || item.id != id;
      }).toList();

      state = AsyncValue.data(filteredList);
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando elemento: ${_parseError(e)}');
      return false;
    }
  }

  @override
  Future<T?> getById(int id) async {
    try {
      return await service.retrieve(id);
    } catch (e) {
      debugPrint('❌ Error obteniendo elemento: ${_parseError(e)}');
      return null;
    }
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================

  String _parseError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Conexión lenta - Revisa tu internet y vuelve a intentar';
        case DioExceptionType.receiveTimeout:
          return 'El servidor tardó demasiado en responder';
        case DioExceptionType.sendTimeout:
          return 'Error enviando datos - Revisa tu conexión';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 401) {
            return 'Sesión expirada - Vuelve a iniciar sesión';
          } else if (status == 403) {
            return 'No tienes permisos para realizar esta acción';
          } else if (status == 404) {
            return 'Recurso no encontrado';
          } else if (status != null && status >= 500) {
            return 'Error del servidor - Intenta más tarde';
          }
          return 'Error del servidor (${status ?? 'desconocido'})';
        case DioExceptionType.cancel:
          return 'Operación cancelada';
        case DioExceptionType.connectionError:
          return 'Sin conexión a internet';
        case DioExceptionType.badCertificate:
          return 'Error de seguridad en la conexión';
        case DioExceptionType.unknown:
          return 'Error de conexión - Revisa tu internet';
      }
    }
    return 'Error inesperado: ${error.toString()}';
  }
}
