/// Fases del flujo de login con autorización de equipos (auth/login/start/)
enum LoginFlowPhase {
  /// Formulario de usuario y contraseña
  credentials,

  /// El backend envió un código de 6 dígitos al correo del usuario
  otp,

  /// El backend emitió un user_code visible; se espera aprobación de un admin
  adminApproval,
}

/// Estado del flujo de login por estados
class LoginFlowState {
  final LoginFlowPhase phase;
  final bool isLoading;
  final String? errorMessage;

  /// Correo enmascarado al que se envió el OTP (fase otp)
  final String? maskedEmail;

  /// Código visible tipo ABCD-2345 que el admin debe aprobar (fase adminApproval)
  final String? userCode;

  /// Momento en que expira el paso actual (otp o aprobación admin)
  final DateTime? expiresAt;

  const LoginFlowState({
    this.phase = LoginFlowPhase.credentials,
    this.isLoading = false,
    this.errorMessage,
    this.maskedEmail,
    this.userCode,
    this.expiresAt,
  });

  LoginFlowState copyWith({
    LoginFlowPhase? phase,
    bool? isLoading,
    String? errorMessage,
    String? maskedEmail,
    String? userCode,
    DateTime? expiresAt,
  }) {
    return LoginFlowState(
      phase: phase ?? this.phase,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      userCode: userCode ?? this.userCode,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isCredentials => phase == LoginFlowPhase.credentials;
  bool get isOtp => phase == LoginFlowPhase.otp;
  bool get isAdminApproval => phase == LoginFlowPhase.adminApproval;
}

/// Respuesta unificada de los endpoints del flujo de login.
/// `status` refleja el campo `status` del backend:
/// authenticated | pending_otp | pending_admin | rejected | expired
/// más los internos `gone` (400: la solicitud ya no existe) y `error`.
class LoginFlowResult {
  final String status;
  final String? access;
  final String? refresh;
  final String? deviceId;
  final String? flowSecret;
  final String? maskedEmail;
  final String? userCode;
  final int? expiresIn;
  final int? pollInterval;
  final String? error;

  /// true si el error fue de red (el flujo puede seguir intentando)
  final bool isNetworkError;

  const LoginFlowResult({
    required this.status,
    this.access,
    this.refresh,
    this.deviceId,
    this.flowSecret,
    this.maskedEmail,
    this.userCode,
    this.expiresIn,
    this.pollInterval,
    this.error,
    this.isNetworkError = false,
  });

  factory LoginFlowResult.fromJson(Map<String, dynamic> json) {
    return LoginFlowResult(
      status: json['status']?.toString() ?? 'error',
      access: json['access'],
      refresh: json['refresh'],
      deviceId: json['device_id'],
      flowSecret: json['flow_secret'],
      maskedEmail: json['masked_email'],
      userCode: json['user_code'],
      expiresIn: json['expires_in'],
      pollInterval: json['poll_interval'],
    );
  }

  factory LoginFlowResult.error(String message, {bool isNetworkError = false}) {
    return LoginFlowResult(
      status: 'error',
      error: message,
      isNetworkError: isNetworkError,
    );
  }

  /// La solicitud ya no existe o no está disponible (HTTP 400 en status/)
  factory LoginFlowResult.gone(String message) {
    return LoginFlowResult(status: 'gone', error: message);
  }

  bool get isAuthenticated =>
      status == 'authenticated' && access != null && refresh != null;
  bool get isPendingOtp => status == 'pending_otp';
  bool get isPendingAdmin => status == 'pending_admin';
  bool get isPending => isPendingOtp || isPendingAdmin;
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';
  bool get isGone => status == 'gone';
  bool get isError => status == 'error';
}
