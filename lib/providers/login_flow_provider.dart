import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/login_flow_model.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/providers/device_provider.dart';
import 'package:stampcamera/services/device_service.dart';
import 'package:stampcamera/services/login_flow_service.dart';

/// Provider del flujo de login con autorización de equipos
final loginFlowProvider =
    StateNotifierProvider<LoginFlowNotifier, LoginFlowState>((ref) {
  return LoginFlowNotifier(ref);
});

class LoginFlowNotifier extends StateNotifier<LoginFlowState> {
  LoginFlowNotifier(this._ref) : super(const LoginFlowState());

  final Ref _ref;
  final _service = LoginFlowService();
  final _deviceService = DeviceService();

  String? _flowSecret;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Inicia el login. Según la respuesta del backend el flujo termina
  /// (equipo de confianza) o pasa a verificación OTP / aprobación admin.
  Future<void> start(String username, String password) async {
    _stopPolling();
    _flowSecret = null;
    state = const LoginFlowState(isLoading: true);

    final result = await _service.startLogin(
      username: username,
      password: password,
    );

    if (!mounted) return;

    if (result.isAuthenticated) {
      await _completeAuthenticated(result, username: username);
    } else if (result.isPendingOtp) {
      _flowSecret = result.flowSecret;
      await _adoptDeviceId(result.deviceId);
      state = LoginFlowState(
        phase: LoginFlowPhase.otp,
        maskedEmail: result.maskedEmail,
        expiresAt: _deadline(result.expiresIn, fallbackSeconds: 300),
      );
    } else if (result.isPendingAdmin) {
      _flowSecret = result.flowSecret;
      await _adoptDeviceId(result.deviceId);
      state = LoginFlowState(
        phase: LoginFlowPhase.adminApproval,
        userCode: result.userCode,
        expiresAt: _deadline(result.expiresIn, fallbackSeconds: 600),
      );
      _startPolling(result.pollInterval ?? 4);
    } else {
      state = LoginFlowState(
        errorMessage: result.error ?? 'No se pudo iniciar sesión',
      );
    }
  }

  /// Verifica el código de 6 dígitos enviado al correo
  Future<void> verifyOtp(String code) async {
    final secret = _flowSecret;
    if (secret == null) {
      _resetWithError('La verificación ya no está disponible. Inicia nuevamente.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _service.verifyOtp(flowSecret: secret, code: code);

    if (!mounted) return;

    if (result.isAuthenticated) {
      await _completeAuthenticated(result);
    } else {
      // Mantener la fase OTP para que reintente o pida aprobación admin
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error ?? 'El código no es válido o ya expiró.',
      );
    }
  }

  /// Cambia el OTP vigente por aprobación administrativa
  /// (para usuarios a los que no les llegó el correo)
  Future<void> requestAdminApproval() async {
    final secret = _flowSecret;
    if (secret == null) {
      _resetWithError('La verificación ya no está disponible. Inicia nuevamente.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _service.requestAdminApproval(flowSecret: secret);

    if (!mounted) return;

    if (result.isPendingAdmin) {
      state = LoginFlowState(
        phase: LoginFlowPhase.adminApproval,
        userCode: result.userCode,
        expiresAt: _deadline(result.expiresIn, fallbackSeconds: 600),
      );
      _startPolling(result.pollInterval ?? 4);
    } else if (result.isGone) {
      _resetWithError(
        result.error ?? 'La verificación ya no está disponible. Inicia nuevamente.',
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error ?? 'No se pudo solicitar la aprobación',
      );
    }
  }

  /// Cancela el flujo y vuelve al formulario de credenciales
  void cancel() {
    _stopPolling();
    _flowSecret = null;
    state = const LoginFlowState();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  // ---------------------------------------------------------------------
  // Polling de aprobación administrativa
  // ---------------------------------------------------------------------

  void _startPolling(int intervalSeconds) {
    _stopPolling();
    _pollTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _pollTick(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
  }

  Future<void> _pollTick() async {
    if (_pollInFlight) return;
    final secret = _flowSecret;
    if (secret == null) {
      _stopPolling();
      return;
    }

    // Expiración local como respaldo del estado del servidor
    final expiresAt = state.expiresAt;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      _stopPolling();
      _flowSecret = null;
      _resetWithError('El código expiró. Vuelve a iniciar sesión.');
      return;
    }

    _pollInFlight = true;
    try {
      final result = await _service.checkApprovalStatus(flowSecret: secret);

      if (!mounted) return;
      // El usuario canceló mientras el request estaba en vuelo
      if (_pollTimer == null || _flowSecret == null) return;

      if (result.isAuthenticated) {
        _stopPolling();
        await _completeAuthenticated(result);
      } else if (result.isRejected) {
        _stopPolling();
        _flowSecret = null;
        _resetWithError('La solicitud fue rechazada por el administrador.');
      } else if (result.isExpired || result.isGone) {
        _stopPolling();
        _flowSecret = null;
        _resetWithError(
          result.error ?? 'La solicitud expiró. Vuelve a iniciar sesión.',
        );
      }
      // pending_admin / errores de red transitorios → seguir esperando
    } finally {
      _pollInFlight = false;
    }
  }

  // ---------------------------------------------------------------------
  // Finalización
  // ---------------------------------------------------------------------

  /// Adopta y persiste el device_id emitido por el servidor,
  /// registra la info del equipo y entrega los tokens al authProvider.
  Future<void> _completeAuthenticated(
    LoginFlowResult result, {
    String? username,
  }) async {
    _stopPolling();
    _flowSecret = null;

    state = state.copyWith(isLoading: true, errorMessage: null);

    await _adoptDeviceId(result.deviceId);
    await _refreshStoredDeviceInfo(fallbackUsername: username);

    await _ref.read(authProvider.notifier).completeLoginWithTokens(
          access: result.access!,
          refresh: result.refresh!,
        );

    if (!mounted) return;
    state = const LoginFlowState();
  }

  Future<void> _adoptDeviceId(String? deviceId) async {
    if (deviceId == null || deviceId.isEmpty) return;
    try {
      await _deviceService.storeDeviceId(deviceId);
    } catch (e) {
      debugPrint('⚠️ LoginFlow: error guardando device_id - $e');
    }
  }

  /// Consulta check-device para persistir tipo/nombre/usuario del equipo
  /// y actualiza el deviceProvider sin pasar por el estado `checking`
  /// (que redirige al splash).
  Future<void> _refreshStoredDeviceInfo({String? fallbackUsername}) async {
    try {
      final deviceId = await _deviceService.getStoredDeviceId();
      if (deviceId == null) return;

      final status = await _deviceService.checkDevice();
      if (!status.registered) return;

      await _deviceService.storeDeviceInfo(
        deviceId: deviceId,
        type: status.type ?? 'personal',
        deviceName: status.deviceName,
        username: status.user?.username ?? fallbackUsername,
      );

      _ref.read(deviceProvider.notifier).markRegistered(
            deviceId: deviceId,
            type: status.type,
            deviceName: status.deviceName,
            user: status.user,
          );
    } catch (e) {
      // No bloquear el login por esto: el equipo ya quedó de confianza
      debugPrint('⚠️ LoginFlow: error actualizando info del equipo - $e');
    }
  }

  void _resetWithError(String message) {
    state = LoginFlowState(errorMessage: message);
  }

  DateTime _deadline(int? expiresIn, {required int fallbackSeconds}) {
    return DateTime.now().add(Duration(seconds: expiresIn ?? fallbackSeconds));
  }
}
