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
          // Solo manejar errores 401 y no del endpoint de refresh
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains(refreshEndpoint)) {
            // Prevenir reintentos infinitos
            if (error.requestOptions.extra['retried'] == true) {
              _authNotifier?.logout();
              return handler.reject(error);
            }

            final refreshed = await _refreshToken();

            if (refreshed) {
              final newToken = await storage.read(key: 'access');

              // ✅ CLAVE: Crear un nuevo Dio limpio pero con la misma baseUrl
              final cleanDio = Dio(
                BaseOptions(
                  baseUrl: baseUrl,
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
                ),
              );

              // Configurar la request con el nuevo token
              final retryOptions = error.requestOptions.copyWith();
              retryOptions.extra['retried'] = true;
              retryOptions.headers['Authorization'] = 'Bearer $newToken';

              // ✅ CRÍTICO: Si es FormData, hay que recrearla porque ya está finalizada
              if (retryOptions.data is FormData) {
                final originalFormData = retryOptions.data as FormData;
                final newFormData = FormData();

                // Copiar todos los campos de la FormData original
                for (final entry in originalFormData.fields) {
                  newFormData.fields.add(MapEntry(entry.key, entry.value));
                }

                // ✅ CRÍTICO: Recrear MultipartFile usando paths guardados en extra
                final filePaths =
                    retryOptions.extra['file_paths'] as Map<String, String>?;

                if (filePaths != null) {
                  for (final entry in filePaths.entries) {
                    final fieldName = entry.key;
                    final filePath = entry.value;

                    try {
                      final newFile = await MultipartFile.fromFile(
                        filePath,
                        filename: filePath.split('/').last,
                      );
                      newFormData.files.add(MapEntry(fieldName, newFile));
                    } catch (e) {
                      // Error silencioso al recrear archivo
                    }
                  }
                }

                retryOptions.data = newFormData;
              }

              try {
                final response = await cleanDio.fetch(retryOptions);

                // ✅ IMPORTANTE: Esto debe resolver la promesa original
                return handler.resolve(response);
              } catch (retryError) {
                return handler.reject(retryError as DioException);
              }
            } else {
              _authNotifier?.logout();
              return handler.reject(error);
            }
          }

          // Para otros errores (400, 500, etc.), simplemente rechazar
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
      // ✅ IMPORTANTE: Usar un Dio completamente limpio para el refresh
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await refreshDio.post(
        refreshEndpoint,
        data: {'refresh': refreshToken},
      );

      final newAccess = response.data['access'];
      await storage.write(key: 'access', value: newAccess);
      return true;
    } catch (e) {
      await storage.deleteAll();
      _authNotifier?.logout();
      return false;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }

  // ✅ MÉTODO ALTERNATIVO: Wrapper para requests críticas
  Future<Response<T>> requestWithAutoRetry<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    String method = 'GET',
    Options? options,
  }) async {
    try {
      Response<T> response;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await dio.post<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case 'PUT':
          response = await dio.put<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case 'DELETE':
          response = await dio.delete<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        default:
          response = await dio.get<T>(
            path,
            queryParameters: queryParameters,
            options: options,
          );
      }

      return response;
    } catch (e) {
      // Si llega aquí, significa que el interceptor ya manejó el retry
      // o que es un error diferente al 401
      rethrow;
    }
  }

  // ✅ MÉTODO ESPECIALIZADO para FormData (multipart/form-data)
  Future<Response<Map<String, dynamic>>> postFormData(
    String path,
    FormData formData, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: onSendProgress,
      );

      return response;
    } catch (e) {
      // El interceptor ya manejó el retry si era necesario
      rethrow;
    }
  }
}
