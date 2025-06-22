import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  AuthNotifier? _authNotifier;

  void setAuthNotifier(AuthNotifier notifier) {
    _authNotifier = notifier;
  }

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
          // ✅ SOLUCIÓN: Solo manejar errores 401, dejar pasar otros errores
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains(refreshEndpoint)) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final newToken = await storage.read(key: 'access');

              // Creamos un nuevo Dio sin interceptores
              final retryDio = Dio();
              final retryOptions = error.requestOptions;

              // Prevención de reintentos infinitos
              if (retryOptions.extra['retried'] == true) {
                return handler.reject(error);
              }
              retryOptions.extra['retried'] = true;

              retryOptions.headers['Authorization'] = 'Bearer $newToken';

              try {
                final response = await retryDio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.reject(e as DioException);
              }
            }
          }

          // ✅ IMPORTANTE: Para otros errores (400, 500, etc.), simplemente rechazar sin modificar
          // Esto permite que el servicio maneje los errores como espera
          return handler.reject(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.read(key: 'refresh');
    if (refreshToken == null) {
      _authNotifier?.logout();
      return false;
    }

    try {
      final response = await dio.post(
        refreshEndpoint,
        data: {'refresh': refreshToken},
      );
      final newAccess = response.data['access'];
      await storage.write(key: 'access', value: newAccess);
      return true;
    } catch (_) {
      await storage.deleteAll();
      _authNotifier?.logout();
      return false;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }
}
