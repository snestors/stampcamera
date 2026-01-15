// lib/providers/autos/queue_state_provider.dart - OPTIMIZADO (reemplaza el actual)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/registro_vin_service.dart';

// ============================================================================
// MODELO DE ESTADO DE LA COLA - MANTENER IGUAL
// ============================================================================

class QueueState {
  final List<Map<String, dynamic>> allRecords;
  final int pendingCount;
  final int failedCount;
  final int completedCount;
  final DateTime? lastUpdated;

  const QueueState({
    required this.allRecords,
    required this.pendingCount,
    required this.failedCount,
    required this.completedCount,
    this.lastUpdated,
  });

  factory QueueState.fromRecords(List<Map<String, dynamic>> records) {
    final pending = records.where((r) => r['status'] == 'pending').length;
    final failed = records.where((r) => r['status'] == 'failed').length;
    final completed = records.where((r) => r['status'] == 'completed').length;

    return QueueState(
      allRecords: records,
      pendingCount: pending,
      failedCount: failed,
      completedCount: completed,
      lastUpdated: DateTime.now(),
    );
  }
}

// ============================================================================
// ✅ OPTIMIZACIÓN: UN SOLO PROVIDER EN LUGAR DE MÚLTIPLES
// ============================================================================

final queueStateProvider =
    StateNotifierProvider<QueueStateNotifier, QueueState>((ref) {
      return QueueStateNotifier();
    });

class QueueStateNotifier extends StateNotifier<QueueState> {
  QueueStateNotifier()
    : super(
        const QueueState(
          allRecords: [],
          pendingCount: 0,
          failedCount: 0,
          completedCount: 0,
        ),
      ) {
    _loadInitialState();
    // NOTA: Timer eliminado - BackgroundQueueService ya llama refreshState()
    // después de procesar la cola, evitando timers duplicados
  }

  final RegistroVinService _service = RegistroVinService();

  Future<void> _loadInitialState() async {
    try {
      final records = await _service.getPendingRecordsList();
      state = QueueState.fromRecords(records);
    } catch (e) {
      print('Error loading initial queue state: $e');
    }
  }

  /// ✅ MÉTODO PÚBLICO: Refrescar estado manualmente
  Future<void> refreshState() async {
    try {
      final records = await _service.getPendingRecordsList();
      state = QueueState.fromRecords(records);
    } catch (e) {
      print('Error refreshing queue state: $e');
    }
  }

  /// ✅ MÉTODO PÚBLICO: Procesar cola
  Future<void> processQueue() async {
    try {
      await _service.processPendingQueue();
      await refreshState(); // Actualizar después de procesar
    } catch (e) {
      print('Error processing queue: $e');
      rethrow;
    }
  }

  /// ✅ MÉTODO PÚBLICO: Limpiar completados
  Future<void> clearCompleted() async {
    try {
      await _service.clearCompleted();
      await refreshState();
    } catch (e) {
      print('Error clearing completed: $e');
      rethrow;
    }
  }

  /// ✅ MÉTODO PÚBLICO: Limpiar fallidos
  Future<void> clearFailed() async {
    try {
      await _service.clearFailedRecords();
      await refreshState();
    } catch (e) {
      print('Error clearing failed: $e');
      rethrow;
    }
  }

  /// ✅ MÉTODO PÚBLICO: Retry específico
  Future<void> retryRecord(String recordId) async {
    try {
      await _service.retrySpecificRecord(recordId);
      await refreshState();
    } catch (e) {
      print('Error retrying record: $e');
      rethrow;
    }
  }

  /// ✅ MÉTODO PÚBLICO: Eliminar específico
  Future<void> deleteRecord(String recordId) async {
    try {
      await _service.deleteSpecificRecord(recordId);
      await refreshState();
    } catch (e) {
      print('Error deleting record: $e');
      rethrow;
    }
  }
}

// ============================================================================
// ✅ PROVIDERS DERIVADOS OPTIMIZADOS (EN LUGAR DE MÚLTIPLES STREAMPROVIDERS)
// ============================================================================

/// Provider para el badge (solo el count) - REEMPLAZA pendingQueueCountProvider
final pendingQueueCountProvider = Provider<int>((ref) {
  final queueState = ref.watch(queueStateProvider);
  return queueState.pendingCount;
});

/// Provider para la lista completa - REEMPLAZA pendingRecordsListProvider
final pendingRecordsListProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final queueState = ref.watch(queueStateProvider);
  return queueState.allRecords;
});

/// Provider para estadísticas - MANTENER PARA COMPATIBILIDAD
final queueStatsProvider = Provider<Map<String, int>>((ref) {
  final queueState = ref.watch(queueStateProvider);
  return {
    'pending': queueState.pendingCount,
    'failed': queueState.failedCount,
    'completed': queueState.completedCount,
    'total': queueState.allRecords.length,
  };
});

// ============================================================================
// ✅ MANTENER COMPATIBILIDAD CON TU PEDETEO_PROVIDER EXISTENTE
// ============================================================================

/// Helper para invalidar desde pedeteo_provider
extension QueueRefresh on WidgetRef {
  void refreshQueue() {
    read(queueStateProvider.notifier).refreshState();
  }
}
