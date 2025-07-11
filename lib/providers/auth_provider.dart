import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:stampcamera/providers/session_manager_provider.dart';
import 'dart:async';
import 'dart:convert';

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

  Future<void> _initializeAuth() async {
    try {
      await _checkAuthWithRetry();
      await _loadPersistedAuthState();
    } catch (e) {
      final currentState = state.value;
      if (currentState?.status != AuthStatus.loggedIn) {
        state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
      }
    }
  }

  Future<void> _loadPersistedAuthState() async {
    try {
      final access = await _storage.read(key: 'access');
      final userDataJson = await _storage.read(key: 'user_data');

      if (access != null) {
        if (userDataJson != null) {
          final userData = jsonDecode(userDataJson);
          final user = UserModel.fromJson(userData);

          state = AsyncValue.data(
            AuthState(
              status: AuthStatus.loggedIn,
              user: user,
              errorMessage: null,
            ),
          );
        } else {
          state = AsyncValue.data(
            AuthState(
              status: AuthStatus.loggedIn,
              user: null,
              errorMessage: 'Datos de usuario no disponibles offline',
            ),
          );
        }
      } else {
        state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
      }
    } catch (e) {
      state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
    }
  }

  Future<void> _persistUserData(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: 'user_data', value: userJson);
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> _clearPersistedUserData() async {
    try {
      await _storage.delete(key: 'user_data');
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> login(String username, String password, {bool isBiometricLogin = false}) async {
    print('🔐 AuthProvider: Iniciando login para: $username');

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

      final accessToken = response.data['access'] as String?;
      final refreshToken = response.data['refresh'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Respuesta inválida del servidor');
      }

      await _storage.write(key: 'access', value: accessToken);
      await _storage.write(key: 'refresh', value: refreshToken);

      await _fetchUserAndSetState();

      print('✅ Login exitoso para: ${username.trim()}');
    } catch (e) {
      print('❌ AuthProvider: Error en login: $e');

      final errorMessage = _handleGenericError(e);
      
      // Si es login biométrico y el error es 401, tratar como sesión expirada
      // En lugar de "credenciales incorrectas"
      final finalErrorMessage = isBiometricLogin && 
          (errorMessage.contains('Usuario o contraseña incorrectos') || 
           errorMessage.contains('Datos de login inválidos'))
          ? 'Sesión expirada. Vuelve a autenticarte.'
          : errorMessage;
      
      state = AsyncValue.data(
        AuthState(status: AuthStatus.loggedOut, errorMessage: finalErrorMessage),
      );
    }
  }

  Future<void> _checkAuthWithRetry() async {
    final access = await _storage.read(key: 'access');
    if (access == null) {
      state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
      return;
    }

    try {
      await _fetchUserAndSetStateWithRetry();
      return;
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        await logout();
      } else {
        final currentState = state.value;
        if (currentState?.user == null &&
            currentState?.status == AuthStatus.loggedIn) {
          state = AsyncValue.data(
            currentState!.copyWith(
              errorMessage: 'Sin conexión - datos no actualizados',
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchUserAndSetState() async {
    try {
      final response = await _http.dio.get('api/v1/check-auth/');

      final userData = response.data['user'];
      if (userData == null) {
        throw Exception('Respuesta del servidor no contiene datos de usuario');
      }

      final user = UserModel.fromJson(userData);
      await _persistUserData(user);

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

  Future<void> _fetchUserAndSetStateWithRetry() async {
    const maxRetries = 2;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _fetchUserAndSetState();
        return;
      } catch (e) {
        final isConnectionIssue = _isConnectionError(e);
        final isUnauthorized = _isUnauthorizedError(e);

        if (isUnauthorized) {
          throw Exception('Sesión expirada');
        }

        if (isConnectionIssue) {
          if (attempt == maxRetries) {
            final access = await _storage.read(key: 'access');
            if (access != null) {
              state = AsyncValue.data(
                AuthState(
                  status: AuthStatus.loggedIn,
                  user: null,
                  errorMessage: 'Sin conexión - datos no actualizados',
                ),
              );
              return;
            }
          } else {
            await Future.delayed(baseDelay * attempt);
            continue;
          }
        }

        if (attempt == maxRetries) {
          throw Exception('Error al verificar usuario');
        }
      }
    }
  }

  void clearError() {
    final currentState = state.value;
    if (currentState != null && currentState.errorMessage != null) {
      state = AsyncValue.data(
        AuthState(
          status: currentState.status,
          user: currentState.user,
          errorMessage: null,
        ),
      );
    }
  }

  Future<void> logout([WidgetRef? ref]) async {
    if (ref != null) {
      ref.read(sessionManagerProvider.notifier).clearSession(ref);
    }

    state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));

    try {
      // ✅ SOLO borrar claves específicas del AUTH, NO deleteAll()
      await _storage.delete(key: 'access');
      await _storage.delete(key: 'refresh');
      await _storage.delete(key: 'user_data');
      await _clearPersistedUserData();

      print(
        '🗑️ AuthProvider: Solo limpiando datos de autenticación (manteniendo biometría)',
      );
    } catch (e) {
      // Fallback si falla el borrado individual
      await _storage.delete(key: 'access');
      await _storage.delete(key: 'refresh');
      await _storage.delete(key: 'user_data');
      print('❌ AuthProvider: Error en logout, usando fallback');
    }
  }

  Future<void> refreshUser() async {
    if (!isLoggedIn) return;

    try {
      await _fetchUserAndSetState();
    } catch (e) {
      // Mantener estado actual si falla
    }
  }

  String _handleGenericError(dynamic error) {
    if (error.runtimeType.toString().contains('Dio')) {
      final response = _getResponseFromError(error);
      final errorType = _getErrorTypeFromError(error);

      if (errorType?.toString().contains('timeout') == true) {
        return 'Tiempo de conexión agotado. Verifica tu conexión a internet.';
      }

      if (errorType?.toString().contains('other') == true ||
          errorType?.toString().contains('connection') == true) {
        return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      }

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

    return 'Error inesperado: ${error.toString()}';
  }

  Response? _getResponseFromError(dynamic error) {
    try {
      return error.response as Response?;
    } catch (e) {
      return null;
    }
  }

  dynamic _getErrorTypeFromError(dynamic error) {
    try {
      return error.type;
    } catch (e) {
      return null;
    }
  }

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

  bool _isConnectionError(dynamic error) {
    try {
      if (error.runtimeType.toString().contains('Dio')) {
        final errorType = _getErrorTypeFromError(error);
        final errorString = error.toString().toLowerCase();

        return errorType?.toString().contains('timeout') == true ||
            errorType?.toString().contains('other') == true ||
            errorType?.toString().contains('connection') == true ||
            errorString.contains('network') ||
            errorString.contains('socket') ||
            errorString.contains('connection failed') ||
            errorString.contains('no address associated with hostname');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool get isLoggedIn => state.value?.status == AuthStatus.loggedIn;
  UserModel? get user => state.value?.user;
  String? get errorMessage => state.value?.errorMessage;
  bool get isLoading => state.isLoading;
  bool get hasError => state.hasError;
}
