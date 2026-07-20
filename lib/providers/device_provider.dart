import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/device_service.dart';
import 'package:stampcamera/services/http_service.dart';

/// Estados posibles del dispositivo.
/// La autorización del equipo la resuelve el flujo de login
/// (auth/login/start/); aquí solo se valida el device_id almacenado.
enum DeviceRegistrationStatus {
  /// Estado inicial, verificando
  checking,
  /// No registrado, necesita registro
  notRegistered,
  /// Registrado y válido
  registered,
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
  final String? errorMessage;
  final bool isLoading;

  const DeviceState({
    this.status = DeviceRegistrationStatus.checking,
    this.deviceId,
    this.deviceType,
    this.deviceName,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  DeviceState copyWith({
    DeviceRegistrationStatus? status,
    String? deviceId,
    String? deviceType,
    String? deviceName,
    DeviceUser? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return DeviceState(
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      user: user ?? this.user,
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

  /// Marca el equipo como registrado sin pasar por `checking`
  /// (el flujo de login ya validó contra el servidor; `checking` redirige al splash)
  void markRegistered({
    required String deviceId,
    String? type,
    String? deviceName,
    DeviceUser? user,
  }) {
    state = state.copyWith(
      status: DeviceRegistrationStatus.registered,
      deviceId: deviceId,
      deviceType: type,
      deviceName: deviceName,
      user: user,
      isLoading: false,
      errorMessage: null,
    );
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
}
