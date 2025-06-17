import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import '../models/auth_state.dart';
import '../services/http_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  final _storage = const FlutterSecureStorage();
  final _http = HttpService();

  /// Login con username y password
  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    print('Intentando iniciar sesión con $username');
    try {
      final response = await _http.dio.post('api/v1/token/', data: {
        'username': username,
        'password': password,
      });
      print('Login response: ${response.data}');
      await _storage.write(key: 'access', value: response.data['access']);
      await _storage.write(key: 'refresh', value: response.data['refresh']);

      await _fetchUserAndSetState();
    } catch (e, st) {
      state = AsyncValue.error('Error al iniciar sesión', st);
    }
  }

  /// Verifica si hay token guardado y lo valida con el backend
  Future<void> _checkAuth() async {
    final access = await _storage.read(key: 'access');
    if (access == null) {
      state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
      return;
    }

    await _fetchUserAndSetState();
  }

  /// Llama al backend y obtiene el usuario actual
  Future<void> _fetchUserAndSetState() async {
    try {
      final response = await _http.dio.get('api/v1/check-auth/');
      final userData = UserModel.fromJson(response.data['user']);
      state = AsyncValue.data(AuthState(
        status: AuthStatus.loggedIn,
        user: userData,
      ));
    } catch (e) {
      await logout(); // Limpieza si falla check-auth
    }
  }

  /// Cierra sesión y limpia todo
  Future<void> logout() async {
    try {
      await _http.logout();
    } catch (_) {}
    await _storage.deleteAll();
    state = AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
  }

  /// Accesos rápidos
  bool get isLoggedIn => state.value?.status == AuthStatus.loggedIn;
  UserModel? get user => state.value?.user;
}
