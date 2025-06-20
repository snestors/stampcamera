import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/utils/debouncer.dart';
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
  bool get isSearching => _isSearching;
  int _searchToken = 0;
  final _debouncer = Debouncer();

  bool get isLoadingMore => _isLoadingMore;

  bool get hasNextPage {
    if (_searchQuery != null) {
      return _searchNextUrl != null;
    }
    return _nextUrl != null;
  }

  @override
  Future<List<RegistroGeneral>> build() async {
    return await _loadInitial();
  }

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
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  Future<void> clearSearch() async {
    state = const AsyncValue.loading();
    final initial = await _loadInitial();
    state = AsyncValue.data(initial);
  }

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
      state = AsyncValue.data([...current, ...paginated.results]);

      if (_searchQuery != null) {
        _searchNextUrl = paginated.next;
      } else {
        _nextUrl = paginated.next;
      }
    } catch (_) {
      // Silent fail
    } finally {
      _isLoadingMore = false;
      state = AsyncValue.data([...?state.value]);
    }
  }

  void debouncedSearch(String query) {
    _debouncer.run(() {
      if (query.trim().isEmpty) {
        clearSearch();
      } else {
        search(query);
      }
    });
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return clearSearch();
    }

    // ignore: avoid_print
    print('🔍 Buscando en la API: "$trimmed"');
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

      if (_searchToken != currentToken) {
        // ignore: avoid_print
        print('🔥 Ignorando respuesta vieja de búsqueda');
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
        state = AsyncValue.error(e, st);
      }
    } finally {
      // ✅ Esto debe ejecutarse siempre
      _isSearching = false;
      // Notificamos para que el widget se reconstruya si depende de isSearching
      state = AsyncValue.data([...?state.value]);
    }
  }
}
