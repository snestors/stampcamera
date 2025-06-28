// providers/autos/contenedor_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/services/contenedor_service.dart';
import 'package:stampcamera/utils/debouncer.dart';

// Provider del servicio
final contenedorServiceProvider = Provider((ref) => ContenedorService());

// Provider de opciones
final contenedorOptionsProvider = FutureProvider<ContenedorOptions>((ref) {
  final service = ref.read(contenedorServiceProvider);
  return service.getOptions();
});

// Provider principal de contenedores con paginación
final contenedorProvider =
    StateNotifierProvider<
      ContenedorNotifier,
      AsyncValue<List<ContenedorModel>>
    >((ref) {
      final service = ref.read(contenedorServiceProvider);
      return ContenedorNotifier(service);
    });

class ContenedorNotifier
    extends StateNotifier<AsyncValue<List<ContenedorModel>>> {
  final ContenedorService _service;
  final _debouncer = Debouncer();

  // Estado interno para paginación
  String? _searchQuery;
  String? _nextUrl; // Para lista inicial
  String? _searchNextUrl; // Para búsqueda
  bool _isLoadingMore = false;
  bool _isSearching = false;
  int _searchToken = 0; // Para cancelar búsquedas obsoletas

  ContenedorNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  // Getters públicos
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  String? get searchQuery => _searchQuery;

  /// Cargar datos iniciales
  Future<void> _loadInitial() async {
    try {
      // ✅ CORREGIDO: No pasar page=1, Django maneja la paginación automáticamente
      final paginated = await _service.searchContenedores();
      _nextUrl = paginated.next;
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Búsqueda con debounce automático
  void debouncedSearch(String query) {
    _debouncer.run(() {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        clearFilters();
      } else {
        search(trimmed);
      }
    });
  }

  /// Búsqueda inmediata
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return clearFilters();
    }

    // Evitar búsquedas duplicadas
    if (_searchQuery == trimmed && state.hasValue) {
      return;
    }

    debugPrint('🔍 Buscando contenedores: "$trimmed"');

    _isSearching = true;
    state = const AsyncValue.loading();
    _searchQuery = trimmed;
    _searchToken++;
    final currentToken = _searchToken;

    try {
      // ✅ CORREGIDO: No pasar page=1, solo los filtros de búsqueda
      final paginated = await _service.searchContenedores(search: trimmed);

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
        // Trigger rebuild para actualizar isSearching
        if (!state.hasError) {
          state = AsyncValue.data([...?state.value]);
        }
      }
    }
  }

  /// Limpiar filtros y volver a lista inicial
  Future<void> clearFilters() async {
    if (_searchQuery == null) return; // Ya está en modo inicial

    debugPrint('🔄 Limpiando filtros de contenedores');

    state = const AsyncValue.loading();
    _searchQuery = null;
    _searchNextUrl = null;
    _isSearching = false;

    try {
      // ✅ CORREGIDO: No pasar page=1 para cargar inicial
      final paginated = await _service.searchContenedores();
      _nextUrl = paginated.next;
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Cargar más elementos (paginación) - CORREGIDO para usar next URL completo
  Future<void> loadMore() async {
    if (_isLoadingMore) return;

    // Usar el next URL apropiado según si estamos en búsqueda o no
    final nextUrl = _searchQuery != null ? _searchNextUrl : _nextUrl;
    if (nextUrl == null) return;

    _isLoadingMore = true;

    try {
      // ✅ CORREGIDO: Usar nextUrl directamente en lugar de construir /?page1
      final paginated = await _service.searchContenedores(nextUrl: nextUrl);

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
      // Error silencioso en loadMore - no romper UI existente
      debugPrint('❌ Error cargando más contenedores: ${_parseError(e)}');
    } finally {
      _isLoadingMore = false;
      // Trigger rebuild para actualizar isLoadingMore
      state = AsyncValue.data([...?state.value]);
    }
  }

  /// Refresh manual (pull-to-refresh)
  Future<void> refresh() async {
    if (_searchQuery != null) {
      // Si estamos en búsqueda, rehacer la búsqueda
      await search(_searchQuery!);
    } else {
      // Si estamos en lista inicial, recargar
      state = const AsyncValue.loading();
      await _loadInitial();
    }
  }

  /// Crear nuevo contenedor
  Future<bool> createContenedor({
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? fotoContenedorPath,
    String? precinto1,
    String? fotoPrecinto1Path,
    String? precinto2,
    String? fotoPrecinto2Path,
    String? fotoContenedorVacioPath,
  }) async {
    try {
      debugPrint('📦 Creando contenedor: $nContenedor');

      final newContenedor = await _service.createContenedor(
        nContenedor: nContenedor,
        naveDescarga: naveDescarga,
        zonaInspeccion: zonaInspeccion,
        fotoContenedorPath: fotoContenedorPath,
        precinto1: precinto1,
        fotoPrecinto1Path: fotoPrecinto1Path,
        precinto2: precinto2,
        fotoPrecinto2Path: fotoPrecinto2Path,
        fotoContenedorVacioPath: fotoContenedorVacioPath,
      );

      // Actualizar lista agregando al inicio
      final current = state.value ?? [];
      state = AsyncValue.data([newContenedor, ...current]);

      debugPrint('✅ Contenedor creado exitosamente: ${newContenedor.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error creando contenedor: $e');
      rethrow;
    }
  }

  /// Actualizar contenedor existente
  Future<bool> updateContenedor({
    required int id,
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? precinto1,
    String? precinto2,
  }) async {
    try {
      final updatedContenedor = await _service.updateContenedor(
        id: id,
        nContenedor: nContenedor,
        naveDescarga: naveDescarga,
        zonaInspeccion: zonaInspeccion,
        precinto1: precinto1,
        precinto2: precinto2,
      );

      // Actualizar en la lista
      final current = state.value ?? [];
      final updatedList = current.map((contenedor) {
        return contenedor.id == id ? updatedContenedor : contenedor;
      }).toList();

      state = AsyncValue.data(updatedList);
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando contenedor: $e');
      rethrow;
    }
  }

  /// Eliminar contenedor
  Future<bool> deleteContenedor(int id) async {
    try {
      await _service.deleteContenedor(id);

      // Remover de la lista
      final current = state.value ?? [];
      final updatedList = current
          .where((contenedor) => contenedor.id != id)
          .toList();

      state = AsyncValue.data(updatedList);
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando contenedor: $e');
      return false;
    }
  }

  /// Parsear errores para mostrar mensajes amigables
  String _parseError(Object error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Exception: ')) {
        return message.replaceAll('Exception: ', '');
      }
      return message;
    }
    return 'Error inesperado: ${error.toString()}';
  }
}
