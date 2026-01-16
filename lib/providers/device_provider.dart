import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/device_service.dart';
import '../services/http_service.dart';

/// Estados posibles del dispositivo
enum DeviceRegistrationStatus {
  /// Estado inicial, verificando
  checking,
  /// No registrado, necesita registro
  notRegistered,
  /// Registrado y válido
  registered,
  /// Esperando código de verificación
  awaitingCode,
  /// Esperando token de admin (usuario sin email)
  awaitingToken,
  /// Error en la verificación/registro
  error,
}

/// Estado del dispositivo
class DeviceState {
  final DeviceRegistrationStatus status;
  final String? deviceId;
  final String? deviceType; // 'personal' | 'shared'
  final String? deviceName;
  final DeviceUser? user;
  final String? maskedEmail;
  final String? errorMessage;
  final bool isLoading;

  const DeviceState({
    this.status = DeviceRegistrationStatus.checking,
    this.deviceId,
    this.deviceType,
    this.deviceName,
    this.user,
    this.maskedEmail,
    this.errorMessage,
    this.isLoading = false,
  });

  DeviceState copyWith({
    DeviceRegistrationStatus? status,
    String? deviceId,
    String? deviceType,
    String? deviceName,
    DeviceUser? user,
    String? maskedEmail,
    String? errorMessage,
    bool? isLoading,
  }) {
    return DeviceState(
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      user: user ?? this.user,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isRegistered => status == DeviceRegistrationStatus.registered;
  bool get needsRegistration => status == DeviceRegistrationStatus.notRegistered;
  bool get isPersonal => deviceType == 'personal';
  bool get isShared => deviceType == 'shared';
}

/// Provider del estado del dispositivo
final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  return DeviceNotifier();
});

class DeviceNotifier extends StateNotifier<DeviceState> {
  DeviceNotifier() : super(const DeviceState()) {
    _init();
    // Configurar callback para cuando el dispositivo sea invalidado
    HttpService().setOnDeviceInvalidated(_onDeviceInvalidated);
  }

  final _deviceService = DeviceService();

  /// Callback cuando el dispositivo es invalidado desde el servidor
  void _onDeviceInvalidated() {
    state = const DeviceState(
      status: DeviceRegistrationStatus.notRegistered,
    );
  }

  /// Inicializa verificando el estado del dispositivo
  Future<void> _init() async {
    await checkDeviceStatus();
  }

  /// Verifica el estado del dispositivo con el servidor
  Future<void> checkDeviceStatus() async {
    state = state.copyWith(
      status: DeviceRegistrationStatus.checking,
      isLoading: true,
      errorMessage: null,
    );

    final deviceId = await _deviceService.getStoredDeviceId();

    if (deviceId == null) {
      state = state.copyWith(
        status: DeviceRegistrationStatus.notRegistered,
        isLoading: false,
      );
      return;
    }

    final result = await _deviceService.checkDevice();

    if (result.error != null) {
      state = state.copyWith(
        status: DeviceRegistrationStatus.error,
        errorMessage: result.error,
        isLoading: false,
      );
      return;
    }

    if (result.registered) {
      state = state.copyWith(
        status: DeviceRegistrationStatus.registered,
        deviceId: deviceId,
        deviceType: result.type,
        deviceName: result.deviceName,
        user: result.user,
        isLoading: false,
      );
    } else {
      // Device ID almacenado pero no válido en servidor
      await _deviceService.clearDeviceInfo();
      state = state.copyWith(
        status: DeviceRegistrationStatus.notRegistered,
        isLoading: false,
      );
    }
  }

  /// Solicita código de verificación para registrar dispositivo
  Future<RequestCodeResult> requestCode({
    required String username,
    String? deviceName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deviceService.requestCode(
      username: username,
      deviceName: deviceName,
    );

    if (result.success) {
      if (result.method == 'email') {
        state = state.copyWith(
          status: DeviceRegistrationStatus.awaitingCode,
          deviceId: result.deviceId,
          maskedEmail: result.maskedEmail,
          isLoading: false,
        );
      } else if (result.method == 'admin') {
        state = state.copyWith(
          status: DeviceRegistrationStatus.awaitingToken,
          deviceId: result.deviceId,
          isLoading: false,
        );
      } else {
        // Método desconocido - fallback a token
        state = state.copyWith(
          status: DeviceRegistrationStatus.awaitingToken,
          deviceId: result.deviceId,
          isLoading: false,
          errorMessage: 'Método de verificación no reconocido: ${result.method}',
        );
      }
    } else {
      state = state.copyWith(
        errorMessage: result.error ?? 'Error desconocido al solicitar código',
        isLoading: false,
      );
    }

    return result;
  }

  /// Registra el dispositivo con código de email
  Future<RegisterDeviceResult> registerWithCode(String code) async {
    final deviceId = state.deviceId;
    if (deviceId == null) {
      return RegisterDeviceResult.error('No hay device_id. Solicite código nuevamente.');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deviceService.registerDevice(
      deviceId: deviceId,
      code: code,
    );

    if (result.success) {
      state = state.copyWith(
        status: DeviceRegistrationStatus.registered,
        deviceType: result.type,
        deviceName: result.deviceName,
        user: result.user,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        errorMessage: result.error,
        isLoading: false,
      );
    }

    return result;
  }

  /// Registra el dispositivo con token de admin
  Future<RegisterDeviceResult> registerWithToken(String token) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Si no hay device_id, generar uno nuevo
    String deviceId = state.deviceId ?? await _deviceService.getStoredDeviceId() ?? '';

    if (deviceId.isEmpty) {
      // Generar nuevo device_id
      deviceId = const Uuid().v4();
      await _deviceService.storeDeviceId(deviceId);
    }

    final result = await _deviceService.registerDevice(
      deviceId: deviceId,
      token: token,
    );

    if (result.success) {
      state = state.copyWith(
        status: DeviceRegistrationStatus.registered,
        deviceId: deviceId,
        deviceType: result.type,
        deviceName: result.deviceName,
        user: result.user,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        errorMessage: result.error,
        isLoading: false,
      );
    }

    return result;
  }

  /// Limpia el error actual
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Establece un mensaje de error
  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  /// Resetea al estado inicial (no registrado)
  void reset() {
    state = const DeviceState(
      status: DeviceRegistrationStatus.notRegistered,
    );
  }

  /// Vuelve al paso de solicitar código
  void backToRequestCode() {
    state = state.copyWith(
      status: DeviceRegistrationStatus.notRegistered,
      maskedEmail: null,
      errorMessage: null,
    );
  }
}
