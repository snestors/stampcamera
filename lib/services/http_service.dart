import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:collection';
import '../providers/auth_provider.dart';

// Modelo para requests pendientes
class PendingRequest {
  final String id;
  final String method;
  final String path;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final Options? options;
  final DateTime createdAt;
  final Completer<Response> completer;

  PendingRequest({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
    this.options,
    required this.createdAt,
    required this.completer,
  });
}

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

  // Control de refresh para evitar race conditions
  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshCompleters = [];

  // Cola de requests offline
  final Queue<PendingRequest> _pendingRequests = Queue();
  bool _isProcessingQueue = false;
  static const Duration _requestTimeout = Duration(minutes: 5);

  HttpService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
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
        onError: (error, handler) async {
          // Verificar si es error de conectividad
          if (_isNetworkError(error)) {
            return handler.reject(error); // Propagar error de red sin retry
          }

          // Solo manejar errores 401 y no del endpoint de refresh
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains(refreshEndpoint)) {
            // Prevenir reintentos infinitos
            if (error.requestOptions.extra['retried'] == true) {
              _authNotifier?.logout();
              return handler.reject(error);
            }

            // Intentar refresh token
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

  /// Verificar si es un error de red/conectividad
  bool _isNetworkError(DioException error) {
    final errorString = error.toString().toLowerCase();
    return error.type.toString().contains('timeout') ||
        error.type.toString().contains('other') ||
        errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection failed') ||
        errorString.contains('no address associated with hostname');
  }

  /// Refresh thread-safe con cola de requests
  Future<bool> _safeRefreshToken() async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final result = await _refreshToken();

      for (final completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }
      _refreshCompleters.clear();

      return result;
    } catch (e) {
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
      final newRefresh = response.data['refresh'];

      await storage.write(key: 'access', value: newAccess);

      if (newRefresh != null) {
        await storage.write(key: 'refresh', value: newRefresh);
      }

      return true;
    } catch (e) {
      await _handleAuthFailure();
      return false;
    }
  }

  Future<void> _handleAuthFailure() async {
    await storage.deleteAll();
    _authNotifier?.logout();
  }

  Future<FormData> _recreateFormData(
    FormData originalFormData,
    Map<String, dynamic> extra,
  ) async {
    final newFormData = FormData();

    for (final entry in originalFormData.fields) {
      newFormData.fields.add(MapEntry(entry.key, entry.value));
    }

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
          debugPrint('Error recreando archivo $filePath: $e');
        }
      }
    }

    return newFormData;
  }

  /// NUEVO: Método principal que maneja conectividad automáticamente
  Future<Response<T>> requestWithConnectivity<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    String method = 'GET',
    Options? options,
    bool allowOfflineQueue = true,
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
        case 'PATCH':
          response = await dio.patch<T>(
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
    } on DioException catch (e) {
      if (_isNetworkError(e) && allowOfflineQueue && _shouldQueue(method)) {
        // Error de red y podemos hacer cola, agregar a cola offline
        return await _queueRequest<T>(
          method: method,
          path: path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Verificar si el método HTTP puede ir en cola
  bool _shouldQueue(String method) {
    // Solo hacer cola de operaciones no críticas
    final upperMethod = method.toUpperCase();
    return upperMethod == 'POST' ||
        upperMethod == 'PUT' ||
        upperMethod == 'PATCH';
  }

  /// Agregar request a la cola offline
  Future<Response<T>> _queueRequest<T>({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final completer = Completer<Response<T>>();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    final pendingRequest = PendingRequest(
      id: requestId,
      method: method,
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      createdAt: DateTime.now(),
      completer: completer as Completer<Response>,
    );

    _pendingRequests.add(pendingRequest);

    // Configurar timeout para la request en cola
    Timer(_requestTimeout, () {
      if (!completer.isCompleted) {
        _pendingRequests.removeWhere((req) => req.id == requestId);
        completer.completeError(
          DioException(
            requestOptions: RequestOptions(path: path),
            error: 'Request timeout en cola offline',
          ),
        );
      }
    });

    return completer.future;
  }

  /// NUEVO: Procesar cola de requests pendientes cuando hay conectividad
  Future<void> processPendingRequests() async {
    if (_isProcessingQueue || _pendingRequests.isEmpty) return;

    _isProcessingQueue = true;

    try {
      while (_pendingRequests.isNotEmpty) {
        final request = _pendingRequests.removeFirst();

        // Verificar si la request no ha expirado
        if (DateTime.now().difference(request.createdAt) > _requestTimeout) {
          if (!request.completer.isCompleted) {
            request.completer.completeError(
              DioException(
                requestOptions: RequestOptions(path: request.path),
                error: 'Request expirada en cola offline',
              ),
            );
          }
          continue;
        }

        try {
          final response = await requestWithConnectivity(
            request.path,
            method: request.method,
            data: request.data,
            queryParameters: request.queryParameters,
            options: request.options,
            allowOfflineQueue: false, // No volver a hacer cola
          );

          if (!request.completer.isCompleted) {
            request.completer.complete(response);
          }
        } catch (e) {
          if (!request.completer.isCompleted) {
            request.completer.completeError(e);
          }
        }

        // Pausa pequeña entre requests para no saturar
        await Future.delayed(Duration(milliseconds: 100));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// NUEVO: Método para limpiar requests expiradas
  void cleanExpiredRequests() {
    _pendingRequests.removeWhere((request) {
      final isExpired =
          DateTime.now().difference(request.createdAt) > _requestTimeout;
      if (isExpired && !request.completer.isCompleted) {
        request.completer.completeError(
          DioException(
            requestOptions: RequestOptions(path: request.path),
            error: 'Request expirada en cola offline',
          ),
        );
      }
      return isExpired;
    });
  }

  /// Getter para número de requests pendientes
  int get pendingRequestsCount => _pendingRequests.length;

  Future<void> logout() async {
    // Limpiar cola de requests pendientes al hacer logout
    while (_pendingRequests.isNotEmpty) {
      final request = _pendingRequests.removeFirst();
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          DioException(
            requestOptions: RequestOptions(path: request.path),
            error: 'Sesión cerrada',
          ),
        );
      }
    }

    await storage.deleteAll();
  }
}
