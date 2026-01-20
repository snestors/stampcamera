// lib/providers/offline_queue_provider.dart
// Provider para exponer el estado de la cola offline a la UI
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/offline_first_queue.dart';

/// Provider que expone el estado de la cola offline
final offlineQueueStateProvider = StreamProvider<OfflineQueueState>((ref) {
  return offlineFirstQueue.stateStream;
});

/// Provider para obtener el conteo de pendientes
final pendingCountProvider = Provider<int>((ref) {
  final state = ref.watch(offlineQueueStateProvider);
  return state.maybeWhen(
    data: (data) => data.pendingCount + data.syncingCount,
    orElse: () => 0,
  );
});

/// Provider para saber si hay pendientes
final hasPendingRecordsProvider = Provider<bool>((ref) {
  return ref.watch(pendingCountProvider) > 0;
});
