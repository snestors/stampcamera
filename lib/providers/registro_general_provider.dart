import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/registro_general_model.dart';
import '../models/paginated_response.dart';
import '../services/http_service.dart';

final registroGeneralProvider =
    AsyncNotifierProvider<RegistroGeneralNotifier, List<RegistroGeneral>>(
        RegistroGeneralNotifier.new);

class RegistroGeneralNotifier extends AsyncNotifier<List<RegistroGeneral>> {
  String? _nextUrl;
  String? _searchNextUrl;
  String? _searchQuery;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  bool _searchingFromApi = false;

  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  bool get searchingFromApi => _searchingFromApi;
  bool get hasNextPage =>
    _searchQuery != null ? _searchNextUrl != null : _nextUrl != null;

  @override
  Future<List<RegistroGeneral>> build() async {
    return await _loadInitial();
  }

  Future<List<RegistroGeneral>> _loadInitial() async {
    try {
      final res = await HttpService().dio.get('/api/v1/registro-general/');
      final paginated = PaginatedResponse<RegistroGeneral>.fromJson(
        res.data,
        RegistroGeneral.fromJson,
      );
      _nextUrl = paginated.next;
      _searchQuery = null;
      _searchNextUrl = null;
      _isSearching = false;
      _searchingFromApi = false;
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
    } catch (e, st) {
      //state = AsyncValue.error(e, st);
      // No tocamos el state principal
    } finally {
      _isLoadingMore = false;
      // Notificamos cambio para que rebuild del ListView funcione
      state = AsyncValue.data([...?state.value]);
    }
  }

  Future<void> search(String query) async {
    final current = state.value ?? [];

    _isSearching = true;
    _searchQuery = query;

    final localMatches = current.where((e) {
      final q = query.toLowerCase();
      return e.vin.toLowerCase().contains(q) ||
          (e.serie?.toLowerCase() ?? '').contains(q);
    }).toList();

    if (localMatches.isNotEmpty) {
      _searchingFromApi = false;
      state = AsyncValue.data(localMatches);
      _isSearching = false;
      return;
    }

    _searchingFromApi = true;

    try {
      final res = await HttpService().dio.get(
        '/api/v1/registro-general/',
        queryParameters: {'search': query},
      );
      final paginated = PaginatedResponse<RegistroGeneral>.fromJson(
        res.data,
        RegistroGeneral.fromJson,
      );
      _searchNextUrl = paginated.next;
      state = AsyncValue.data(paginated.results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isSearching = false;
      _searchingFromApi = false;
    }
  }
}
