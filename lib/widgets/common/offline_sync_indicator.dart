// lib/widgets/common/offline_sync_indicator.dart
// Widget que muestra el estado de sincronización offline
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/offline_queue_provider.dart';
import 'package:stampcamera/services/offline_first_queue.dart';

/// Indicador compacto de sincronización para AppBar o cualquier lugar
class OfflineSyncIndicator extends ConsumerWidget {
  const OfflineSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingCountProvider);

    if (pendingCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$pendingCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner más visible para mostrar en la parte superior de una pantalla
class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(offlineQueueStateProvider);

    return queueState.when(
      data: (state) {
        if (!state.hasPending) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade200),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getMessage(state),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              if (state.failedCount > 0)
                TextButton(
                  onPressed: () => _retryFailed(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  String _getMessage(OfflineQueueState state) {
    final total = state.pendingCount + state.syncingCount;

    if (state.syncingCount > 0) {
      return 'Sincronizando $total registro${total > 1 ? 's' : ''}...';
    }

    if (state.failedCount > 0) {
      return '${state.failedCount} registro${state.failedCount > 1 ? 's' : ''} con error';
    }

    return '$total registro${total > 1 ? 's' : ''} pendiente${total > 1 ? 's' : ''}';
  }

  void _retryFailed() {
    offlineFirstQueue.forceSync();
  }
}
