import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/utils/debouncer.dart';
import 'package:dio/dio.dart';
import '../../models/autos/registro_general_model.dart';
import '../../models/paginated_response.dart';
import '../../services/http_service.dart';

final registroGeneralProvider =
    AsyncNotifierProvider<RegistroGeneralNotifier, List<RegistroGeneral>>(
      RegistroGeneralNotifier.new,
    );

class RegistroGeneralNotifier extends AsyncNotifier<List<RegistroGeneral>> {
  String? _nextUrl;
  String? _searchNextUrl;
  String? _searchQuery;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  int _searchToken = 0;
  final _debouncer = Debouncer();

  // ✅ Getters públicos para el UI
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNextPage {
    if (_searchQuery != null) {
      return _searchNextUrl != null;
    }
    return _nextUrl != null;
  }

  @override
  Future<List<RegistroGeneral>> build() async {
    // ✅ KeepAlive para mantener datos en memoria durante la sesión
    ref.keepAlive();

    return await _loadInitial();
  }

  // ============================================================================
  // MÉTODOS PRIVADOS - CORE FUNCTIONALITY
  // ============================================================================

  Future<List<RegistroGeneral>> _loadInitial() async {
    try {
      final res = await HttpService().dio.get(
        '/api/v1/autos/registro-general/',
      );

      final paginated = PaginatedResponse<RegistroGeneral>.fromJson(
        res.data,
        RegistroGeneral.fromJson,
      );

      _nextUrl = paginated.next;
      _searchQuery = null;
      _searchNextUrl = null;
      _isSearching = false;

      return paginated.results;
    } catch (e, st) {
      final errorMsg = _parseError(e);
      state = AsyncValue.error(errorMsg, st);
      return [];
    }
  }

  // ✅ Manejo específico de errores de red
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
            return 'No tienes permisos para ver estos registros';
          } else if (status == 404) {
            return 'Servicio no encontrado';
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

  // ============================================================================
  // MÉTODOS PÚBLICOS - API PARA EL UI
  // ============================================================================

  // ✅ Limpiar búsqueda y volver a lista inicial
  Future<void> clearSearch() async {
    if (_searchQuery == null) return; // Ya está en modo inicial

    state = const AsyncValue.loading();
    _searchQuery = null;
    _searchNextUrl = null;
    _isSearching = false;

    try {
      final initial = await _loadInitial();
      state = AsyncValue.data(initial);
    } catch (e, st) {
      state = AsyncValue.error(_parseError(e), st);
    }
  }

  // ✅ Cargar más elementos (paginación)
  Future<void> loadMore() async {
    if (_isLoadingMore) return;

    final url = _searchQuery != null ? _searchNextUrl : _nextUrl;
    if (url == null) return;

    _isLoadingMore = true;
    final dio = HttpService().dio;

    try {
      final uri = Uri.parse(url);
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      final res = await dio.get(path);

      final paginated = PaginatedResponse<RegistroGeneral>.fromJson(
        res.data,
        RegistroGeneral.fromJson,
      );

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
      // ✅ Error silencioso en loadMore - no romper UI existente
      // Solo logear para debug, no cambiar estado
      debugPrint('❌ Error cargando más resultados: ${_parseError(e)}');
    } finally {
      _isLoadingMore = false;
      // ✅ Trigger rebuild para actualizar isLoadingMore
      state = AsyncValue.data([...?state.value]);
    }
  }

  // ✅ Búsqueda con debounce - para search automático
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

  // ✅ Búsqueda inmediata - para scanner o enter
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return clearSearch();
    }

    // ✅ Evitar búsquedas duplicadas
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
      final res = await HttpService().dio.get(
        '/api/v1/autos/registro-general/',
        queryParameters: {'search': trimmed},
      );

      // ✅ Verificar si esta búsqueda aún es relevante
      if (_searchToken != currentToken) {
        debugPrint('🔥 Ignorando respuesta de búsqueda obsoleta');
        return;
      }

      final paginated = PaginatedResponse<RegistroGeneral>.fromJson(
        res.data,
        RegistroGeneral.fromJson,
      );

      _searchNextUrl = paginated.next;
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      if (_searchToken == currentToken) {
        final errorMsg = _parseError(e);
        state = AsyncValue.error(errorMsg, st);
      }
    } finally {
      if (_searchToken == currentToken) {
        _isSearching = false;
        // ✅ Rebuild para actualizar isSearching flag
        state = AsyncValue.data([...?state.value]);
      }
    }
  }

  // ✅ Refresh manual - para pull-to-refresh
  Future<void> refresh() async {
    if (_searchQuery != null) {
      // Si estamos en búsqueda, rehacer la búsqueda
      await search(_searchQuery!);
    } else {
      // Si estamos en lista inicial, recargar desde inicio
      state = const AsyncValue.loading();
      final initial = await _loadInitial();
      state = AsyncValue.data(initial);
    }
  }

  // ✅ Forzar invalidación - para cambios de permisos
  void forceInvalidate() {
    ref.invalidateSelf();
  }
}
