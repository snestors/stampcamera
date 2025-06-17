import '../models/user_model.dart';

enum AuthStatus {
  loading,
  loggedIn,
  loggedOut,
}


class AuthState {
  final AuthStatus status;
  final UserModel? user;

  AuthState({
    required this.status,
    this.user,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.loading);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }

  bool get isLoggedIn => status == AuthStatus.loggedIn;
  bool get isLoggedOut => status == AuthStatus.loggedOut;
}
