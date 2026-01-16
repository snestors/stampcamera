import '../models/user_model.dart';

// lib/models/auth_state.dart - Versión actualizada
enum AuthStatus {
  loggedIn,
  loggedOut,
  offline, // ✅ NUEVO: Estado para cuando hay sesión pero sin conectividad
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isOfflineMode; // ✅ NUEVO: Indicador de modo offline

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isOfflineMode = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isOfflineMode,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }

  // ✅ Helpers útiles
  bool get isLoggedIn => status == AuthStatus.loggedIn;
  bool get isOffline => isOfflineMode;
  bool get hasUserData => user != null;

  @override
  String toString() {
    return 'AuthState(status: $status, hasUser: ${user != null}, offline: $isOfflineMode, error: $errorMessage)';
  }
}

// Si prefieres mantener el modelo original, usa esta versión alternativa:
class AuthStateAlternative {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthStateAlternative({
    required this.status,
    this.user,
    this.errorMessage,
  });

  // ✅ Método para detectar si estamos en modo offline
  bool get isOfflineMode =>
      status == AuthStatus.loggedIn &&
      user == null &&
      errorMessage?.contains('conexión') == true;
  bool get isLoggedIn => status == AuthStatus.loggedIn;
  bool get hasUserData => user != null;
}
