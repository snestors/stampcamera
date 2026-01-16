// lib/providers/simple_connectivity_provider.dart
// Versión más simple que solo verifica conectividad del dispositivo
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

enum NetworkStatus { online, offline, checking }

class ConnectivityState {
  final NetworkStatus status;
  final List<ConnectivityResult> connectivityResult;
  final DateTime lastChecked;

  const ConnectivityState({
    required this.status,
    required this.connectivityResult,
    required this.lastChecked,
  });

  ConnectivityState copyWith({
    NetworkStatus? status,
    List<ConnectivityResult>? connectivityResult,
    DateTime? lastChecked,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      connectivityResult: connectivityResult ?? this.connectivityResult,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  bool get isOnline => status == NetworkStatus.online;
  bool get canAttemptRequests => isOnline;
  bool get hasAnyConnection =>
      connectivityResult.isNotEmpty &&
      !connectivityResult.contains(ConnectivityResult.none);
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier();
    });

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier()
    : super(
        ConnectivityState(
          status: NetworkStatus.checking,
          connectivityResult: [ConnectivityResult.none],
          lastChecked: DateTime.now(),
        ),
      ) {
    _init();
  }

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  void _init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    await _onConnectivityChanged(result);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    state = state.copyWith(
      connectivityResult: results,
      lastChecked: DateTime.now(),
    );

    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      state = state.copyWith(status: NetworkStatus.offline);
    } else {
      state = state.copyWith(status: NetworkStatus.online);
    }
  }

  Future<void> forceCheck() async {
    state = state.copyWith(status: NetworkStatus.checking);
    final result = await Connectivity().checkConnectivity();
    await _onConnectivityChanged(result);
  }

  bool canMakeRequest() {
    return state.canAttemptRequests;
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});

final canMakeRequestsProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).canAttemptRequests;
});
