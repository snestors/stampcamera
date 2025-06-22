import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../models/user_model.dart';
import '../models/auth_state.dart';
import '../services/http_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(
  (ref) {
    final notifier = AuthNotifier();
    HttpService().setAuthNotifier(notifier);
    return notifier;
  },
);

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _initializeAuth();
  }

  final _storage = const FlutterSecureStorage();
  final _http = HttpService();

  // Control de reintentos
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Inicialización más robusta
  Future<void> _initializeAuth() async {
    try {
      await _checkAuthWithRetry();
    } catch (e) {
      // Si falla la inicialización, establecer como logged out
      state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
    }
  }

  /// Login con manejo específico de errores
  Future<void> login(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      state = AsyncValue.data(
        AuthState(
          status: AuthStatus.loggedOut,
          errorMessage: 'Usuario y contraseña son requeridos',
        ),
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final response = await _http.dio.post(
        'api/v1/token/',
        data: {'username': username.trim(), 'password': password.trim()},
      );

      // Validar respuesta del servidor
      final accessToken = response.data['access'] as String?;
      final refreshToken = response.data['refresh'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Respuesta inválida del servidor');
      }

      // El servidor ya valida los tokens, no necesitamos validación adicional

      // Guardar tokens
      await _storage.write(key: 'access', value: accessToken);
      await _storage.write(key: 'refresh', value: refreshToken);

      // Obtener datos del usuario
      await _fetchUserAndSetState();
    } catch (e) {
      final errorMessage = _handleGenericError(e);
      state = AsyncValue.data(
        AuthState(status: AuthStatus.loggedOut, errorMessage: errorMessage),
      );
    }
  }

  /// Manejo de errores compatible con cualquier versión de Dio
  String _handleGenericError(dynamic error) {
    // Si es un error de Dio (cualquier versión)
    if (error.runtimeType.toString().contains('Dio')) {
      final response = _getResponseFromError(error);
      final errorType = _getErrorTypeFromError(error);

      // Manejo por tipo de error
      if (errorType?.toString().contains('timeout') == true) {
        return 'Tiempo de conexión agotado. Verifica tu conexión a internet.';
      }

      if (errorType?.toString().contains('other') == true ||
          errorType?.toString().contains('connection') == true) {
        return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      }

      // Manejo por código de estado HTTP
      final statusCode = response?.statusCode;
      switch (statusCode) {
        case 400:
          return 'Datos de login inválidos';
        case 401:
          return 'Usuario o contraseña incorrectos';
        case 403:
          return 'Acceso denegado. Contacta al administrador.';
        case 429:
          return 'Demasiados intentos de login. Intenta más tarde.';
        case 500:
          return 'Error del servidor. Intenta más tarde.';
        case 503:
          return 'Servicio no disponible. Intenta más tarde.';
        default:
          return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
      }
    }

    // Para otros tipos de errores
    return 'Error inesperado: ${error.toString()}';
  }

  /// Extraer response de cualquier versión de DioError
  Response? _getResponseFromError(dynamic error) {
    try {
      return error.response as Response?;
    } catch (e) {
      return null;
    }
  }

  /// Extraer tipo de error de cualquier versión
  dynamic _getErrorTypeFromError(dynamic error) {
    try {
      return error.type;
    } catch (e) {
      return null;
    }
  }

  /// Verificación de tokens con reintentos
  Future<void> _checkAuthWithRetry() async {
    final access = await _storage.read(key: 'access');
    if (access == null) {
      state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
      return;
    }

    // Verificar conectividad básica antes de validar con el servidor
    // No verificamos expiración local ya que el servidor maneja eso

    // Intentar validar con el servidor con reintentos
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _fetchUserAndSetState();
        return; // Éxito, salir del loop
      } catch (e) {
        if (attempt == _maxRetries) {
          // Último intento fallido
          await logout();
          return;
        }

        // Esperar antes del siguiente intento
        await Future.delayed(_retryDelay * attempt);
      }
    }
  }

  /// Fetch de usuario con mejor manejo de errores
  Future<void> _fetchUserAndSetState() async {
    try {
      final response = await _http.dio.get('api/v1/check-auth/');

      // Validar estructura de respuesta
      final userData = response.data['user'];
      if (userData == null) {
        throw Exception('Respuesta del servidor no contiene datos de usuario');
      }

      final user = UserModel.fromJson(userData);
      state = AsyncValue.data(
        AuthState(status: AuthStatus.loggedIn, user: user),
      );
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        throw Exception('Sesión expirada');
      } else if (_isConnectionError(e)) {
        throw Exception('Error de conexión');
      } else {
        throw Exception('Error al verificar usuario');
      }
    }
  }

  /// Verificar si es error 401
  bool _isUnauthorizedError(dynamic error) {
    try {
      if (error.runtimeType.toString().contains('Dio')) {
        final response = _getResponseFromError(error);
        return response?.statusCode == 401;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si es error de conexión
  bool _isConnectionError(dynamic error) {
    try {
      if (error.runtimeType.toString().contains('Dio')) {
        final errorType = _getErrorTypeFromError(error);
        return errorType?.toString().contains('timeout') == true ||
            errorType?.toString().contains('other') == true ||
            errorType?.toString().contains('connection') == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout con limpieza completa
  Future<void> logout() async {
    // Cambiar estado inmediatamente para feedback visual
    state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));

    try {
      // Intentar notificar al servidor (opcional, puede fallar)
      await _http.dio
          .post('/api/v1/auth/logout/')
          .timeout(
            Duration(seconds: 5),
            onTimeout: () => Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
            ),
          );
    } catch (e) {
      // Ignorar errores de logout del servidor
    }

    // Limpiar storage local
    try {
      await _http.logout(); // Limpia el HttpService
      await _storage.deleteAll(); // Limpia el storage
    } catch (e) {
      // En caso extremo, limpiar keys específicas
      await _storage.delete(key: 'access');
      await _storage.delete(key: 'refresh');
    }
  }

  /// Refresh manual de datos de usuario
  Future<void> refreshUser() async {
    if (!isLoggedIn) return;

    try {
      await _fetchUserAndSetState();
    } catch (e) {
      // Mantener el estado actual si falla el refresh
      // No hacer logout automático en refresh manual
    }
  }

  /// Accesos rápidos
  bool get isLoggedIn => state.value?.status == AuthStatus.loggedIn;
  UserModel? get user => state.value?.user;
  String? get errorMessage => state.value?.errorMessage;
  bool get isLoading => state.isLoading;
  bool get hasError => state.hasError;
}
