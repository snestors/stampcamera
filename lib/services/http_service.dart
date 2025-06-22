import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import 'dart:convert';
import 'dart:async';

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

  // ✅ SOLUCIÓN: Control de refresh para evitar race conditions
  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshCompleters = [];

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

            // ✅ SOLUCIÓN: Gestión thread-safe del refresh
            final refreshed = await _safeRefreshToken();

            if (refreshed) {
              final newToken = await storage.read(key: 'access');

              if (newToken != null) {
                // Crear un nuevo Dio limpio para el retry
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

                // Manejar FormData si es necesario
                if (retryOptions.data is FormData) {
                  retryOptions.data = await _recreateFormData(
                    retryOptions.data as FormData,
                    retryOptions.extra,
                  );
                }

                try {
                  final response = await cleanDio.fetch(retryOptions);
                  return handler.resolve(response);
                } catch (retryError) {
                  return handler.reject(retryError as DioException);
                }
              }
            }

            // Si no se pudo refrescar el token, hacer logout
            _authNotifier?.logout();
            return handler.reject(error);
          }

          // Para otros errores, simplemente rechazar
          return handler.reject(error);
        },
      ),
    );
  }

  // ✅ SOLUCIÓN: Refresh thread-safe con cola de requests
  Future<bool> _safeRefreshToken() async {
    // Si ya se está refrescando, esperar a que termine
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final result = await _refreshToken();

      // Notificar a todos los completers que esperaban
      for (final completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }
      _refreshCompleters.clear();

      return result;
    } catch (e) {
      // Notificar error a todos los completers
      for (final completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
      _refreshCompleters.clear();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.read(key: 'refresh');
    if (refreshToken == null) {
      await _handleAuthFailure();
      return false;
    }

    try {
      // Usar un Dio completamente limpio para el refresh
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
      final newRefresh = response
          .data['refresh']; // ✅ Django suele devolver nuevo refresh también

      await storage.write(key: 'access', value: newAccess);

      // ✅ MEJORA: Actualizar refresh token si viene en la respuesta
      if (newRefresh != null) {
        await storage.write(key: 'refresh', value: newRefresh);
      }

      return true;
    } catch (e) {
      await _handleAuthFailure();
      return false;
    }
  }

  // ✅ MEJORA: Centralizar manejo de fallos de autenticación
  Future<void> _handleAuthFailure() async {
    await storage.deleteAll();
    _authNotifier?.logout();
  }

  // ✅ MEJORA: Método para recrear FormData de manera más robusta
  Future<FormData> _recreateFormData(
    FormData originalFormData,
    Map<String, dynamic> extra,
  ) async {
    final newFormData = FormData();

    // Copiar todos los campos de la FormData original
    for (final entry in originalFormData.fields) {
      newFormData.fields.add(MapEntry(entry.key, entry.value));
    }

    // Recrear MultipartFile usando paths guardados en extra
    final filePaths = extra['file_paths'] as Map<String, String>?;

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
          // ✅ MEJORA: Log más detallado del error
          //print('Error recreando archivo $filePath: $e');
        }
      }
    }

    return newFormData;
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }

  // ✅ MEJORA: Método con manejo de errores más específico
  Future<Response<T>> requestWithAutoRetry<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    String method = 'GET',
    Options? options,
    Duration? timeout,
  }) async {
    try {
      Response<T> response;

      // ✅ MEJORA: Configurar timeout si se proporciona
      final finalOptions = options ?? Options();
      if (timeout != null) {
        finalOptions.sendTimeout = timeout;
        finalOptions.receiveTimeout = timeout;
      }

      switch (method.toUpperCase()) {
        case 'POST':
          response = await dio.post<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: finalOptions,
          );
          break;
        case 'PUT':
          response = await dio.put<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: finalOptions,
          );
          break;
        case 'PATCH':
          response = await dio.patch<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: finalOptions,
          );
          break;
        case 'DELETE':
          response = await dio.delete<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: finalOptions,
          );
          break;
        default:
          response = await dio.get<T>(
            path,
            queryParameters: queryParameters,
            options: finalOptions,
          );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ MEJORA: Método para FormData con mejor manejo de archivos
  Future<Response<Map<String, dynamic>>> postFormData(
    String path,
    FormData formData, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
    Map<String, String>? filePaths, // ✅ Para tracking de archivos
  }) async {
    try {
      // ✅ MEJORA: Guardar rutas de archivos para posible retry
      final options = Options(headers: {'Content-Type': 'multipart/form-data'});
      if (filePaths != null) {
        options.extra ??= {};
        options.extra!['file_paths'] = filePaths;
      }

      final response = await dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ NUEVA: Método para verificar si el token está próximo a expirar
  Future<bool> isTokenExpiringSoon() async {
    final token = await storage.read(key: 'access');
    if (token == null) return true;

    try {
      // Decodificar JWT para verificar exp
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      // Agregar padding si es necesario
      final padded = payload + '=' * (4 - payload.length % 4);
      final decoded = utf8.decode(base64Url.decode(padded));
      final json = jsonDecode(decoded);

      final exp = json['exp'] as int?;
      if (exp == null) return true;

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      // Considerar que expira pronto si queda menos de 5 minutos
      return expirationTime.difference(now).inMinutes < 5;
    } catch (e) {
      return true; // Si no se puede decodificar, asumir que expira
    }
  }

  // ✅ NUEVA: Método para refrescar token proactivamente
  Future<void> refreshTokenIfNeeded() async {
    if (await isTokenExpiringSoon()) {
      await _safeRefreshToken();
    }
  }
}
