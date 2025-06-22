import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../services/http_service.dart';

// Enum para estados de conectividad
enum NetworkStatus {
  online,
  offline,
  checking,
  limited, // Hay conexión pero el servidor no responde
}

// Modelo de estado de conectividad
class ConnectivityState {
  final NetworkStatus status;
  final ConnectivityResult connectivityResult;
  final DateTime lastChecked;
  final String? errorMessage;

  const ConnectivityState({
    required this.status,
    required this.connectivityResult,
    required this.lastChecked,
    this.errorMessage,
  });

  ConnectivityState copyWith({
    NetworkStatus? status,
    ConnectivityResult? connectivityResult,
    DateTime? lastChecked,
    String? errorMessage,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      connectivityResult: connectivityResult ?? this.connectivityResult,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isOnline => status == NetworkStatus.online;
  bool get hasLimitedConnection => status == NetworkStatus.limited;
  bool get canAttemptRequests => isOnline || hasLimitedConnection;
}

// Provider principal de conectividad
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier();
    });

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier()
    : super(
        ConnectivityState(
          status: NetworkStatus.checking,
          connectivityResult: ConnectivityResult.none,
          lastChecked: DateTime.now(),
        ),
      ) {
    _init();
  }

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _healthCheckTimer;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _serverTimeout = Duration(seconds: 10);

  void _init() {
    // Escuchar cambios de conectividad del dispositivo
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Verificación inicial
    _checkInitialConnectivity();

    // Timer periódico para verificar salud del servidor
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      if (state.connectivityResult != ConnectivityResult.none) {
        _checkServerHealth();
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    await _onConnectivityChanged(result);
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    // Actualizar el resultado de conectividad inmediatamente
    state = state.copyWith(
      connectivityResult: result,
      lastChecked: DateTime.now(),
    );

    if (result == ConnectivityResult.none) {
      // Sin conectividad del dispositivo
      state = state.copyWith(
        status: NetworkStatus.offline,
        errorMessage: 'Sin conexión a internet',
      );
    } else {
      // Hay conectividad, verificar si el servidor responde
      state = state.copyWith(status: NetworkStatus.checking);
      await _checkServerHealth();
    }
  }

  Future<void> _checkServerHealth() async {
    try {
      final response = await HttpService().dio.get(
        '/api/v1/health/',
        options: Options(
          sendTimeout: _serverTimeout,
          receiveTimeout: _serverTimeout,
          headers: {'Cache-Control': 'no-cache'},
        ),
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          status: NetworkStatus.online,
          lastChecked: DateTime.now(),
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: NetworkStatus.limited,
          lastChecked: DateTime.now(),
          errorMessage: 'Servidor no disponible',
        );
      }
    } catch (e) {
      // Error al conectar con el servidor
      final isNetworkError = _isNetworkError(e);

      state = state.copyWith(
        status: isNetworkError ? NetworkStatus.offline : NetworkStatus.limited,
        lastChecked: DateTime.now(),
        errorMessage: isNetworkError
            ? 'Sin conexión a internet'
            : 'Servidor no disponible temporalmente',
      );
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket');
  }

  // Método público para forzar verificación
  Future<void> forceCheck() async {
    state = state.copyWith(status: NetworkStatus.checking);
    await _checkServerHealth();
  }

  // Método para verificar si podemos hacer una request específica
  bool canMakeRequest() {
    return state.canAttemptRequests;
  }

  // Método para obtener mensaje de error apropiado
  String getErrorMessage() {
    return state.errorMessage ?? 'Estado de conexión desconocido';
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}

// Provider helper para acceso rápido al estado
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});

final canMakeRequestsProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).canAttemptRequests;
});
