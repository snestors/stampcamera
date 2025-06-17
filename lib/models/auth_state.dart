import '../models/user_model.dart';

enum AuthStatus {
  loading,
  loggedIn,
  loggedOut,
}


class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.initial() => const AuthState(
        status: AuthStatus.loading,
        user: null,
        errorMessage: null,
      );

  

  bool get isLoggedIn => status == AuthStatus.loggedIn;
  bool get isLoggedOut => status == AuthStatus.loggedOut;
}
