import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;

  late Dio dio;
  final storage = const FlutterSecureStorage();

  static const baseUrl = 'https://www.aygajustadores.com/';
  static const tokenEndpoint = 'token/';
  static const refreshEndpoint = 'api/v1/token/refresh/';

  HttpService._internal() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains(refreshEndpoint)) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final retryRequest = error.requestOptions;
              final newToken = await storage.read(key: 'access');
              retryRequest.headers['Authorization'] = 'Bearer $newToken';
              final response = await dio.fetch(retryRequest);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.read(key: 'refresh');
    if (refreshToken == null) return false;

    try {
      final response = await dio.post(refreshEndpoint, data: {
        'refresh': refreshToken,
      });

      final newAccess = response.data['access'];
      await storage.write(key: 'access', value: newAccess);
      return true;
    } catch (_) {
      await storage.deleteAll();
      return false;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }
}
