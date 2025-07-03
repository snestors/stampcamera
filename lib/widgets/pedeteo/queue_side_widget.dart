// lib/widgets/pedeteo/queue_side_widget.dart - CAMBIOS MÍNIMOS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/autos/queue_state_provider.dart';

class QueueSideWidget extends ConsumerWidget {
  const QueueSideWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cola de Registros'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: const QueueContent(),
      ),
    );
  }
}

class QueueContent extends ConsumerWidget {
  const QueueContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ SOLO CAMBIO: Usar los providers optimizados
    final records = ref.watch(pendingRecordsListProvider);
    final stats = ref.watch(queueStatsProvider);

    return Column(
      children: [
        // Header con estadísticas y acciones
        _buildHeader(stats, ref, context),

        // Lista de registros
        Expanded(child: _buildRecordsList(records, ref, context)),
      ],
    );
  }

  Widget _buildHeader(
    Map<String, int> stats,
    WidgetRef ref,
    BuildContext context,
  ) {
    final pending = stats['pending'] ?? 0;
    final failed = stats['failed'] ?? 0;
    final completed = stats['completed'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Estadísticas
          Row(
            children: [
              _buildStatChip('Pendientes', pending, Colors.orange),
              const SizedBox(width: 8),
              _buildStatChip('Errores', failed, Colors.red),
              const SizedBox(width: 8),
              _buildStatChip('Completados', completed, Colors.green),
            ],
          ),

          const SizedBox(height: 12),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: pending > 0
                      ? () => _processQueue(ref, context)
                      : null,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Procesar Cola'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: completed > 0
                      ? () => _clearCompleted(ref, context)
                      : null,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

          // Fila adicional para limpiar errores
          if (failed > 0) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _clearFailedRecords(ref, context),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red[600],
                ),
                label: Text('Eliminar Registros con Error ($failed)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[300]!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(
    List<Map<String, dynamic>> records,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay registros en cola',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Los nuevos registros offline aparecerán aquí',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return QueueRecordTile(
          record: record,
          onRetry: () => _retryRecord(record, ref, context),
          onDelete: () => _deleteRecord(record, ref, context),
        );
      },
    );
  }

  // ============================================================================
  // ✅ CAMBIOS MÍNIMOS: Usar el provider optimizado en lugar del servicio directo
  // ============================================================================

  void _processQueue(WidgetRef ref, BuildContext context) async {
    try {
      // ✅ OPTIMIZACIÓN: Usar el provider unificado
      await ref.read(queueStateProvider.notifier).processQueue();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cola procesada exitosamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _clearCompleted(WidgetRef ref, BuildContext context) async {
    try {
      // ✅ OPTIMIZACIÓN: Usar el provider unificado
      await ref.read(queueStateProvider.notifier).clearCompleted();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registros completados eliminados')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _clearFailedRecords(WidgetRef ref, BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Eliminar Registros'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todos los registros que fallaron?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // ✅ OPTIMIZACIÓN: Usar el provider unificado
                await ref.read(queueStateProvider.notifier).clearFailed();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registros con error eliminados'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _retryRecord(
    Map<String, dynamic> record,
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      // ✅ OPTIMIZACIÓN: Usar el provider unificado
      await ref.read(queueStateProvider.notifier).retryRecord(record['id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reintentando envío de ${record['vin']}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _deleteRecord(
    Map<String, dynamic> record,
    WidgetRef ref,
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: Text('¿Eliminar el registro del VIN ${record['vin']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // ✅ OPTIMIZACIÓN: Usar el provider unificado
                await ref
                    .read(queueStateProvider.notifier)
                    .deleteRecord(record['id']);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registro ${record['vin']} eliminado'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET PARA CADA REGISTRO - MANTENER EXACTO
// ============================================================================

class QueueRecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  const QueueRecordTile({
    super.key,
    required this.record,
    required this.onRetry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String;
    final vin = record['vin'] as String;
    final condicion = record['condicion'] as String;
    final createdAt = DateTime.parse(record['created_at']);
    final retryCount = record['retry_count'] ?? 0;
    final errorMessage = record['error'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildStatusIcon(status),
        title: Text(
          'VIN: $vin',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Condición: $condicion'),
            Text('Creado: ${_formatDateTime(createdAt)}'),
            if (retryCount > 0)
              Text(
                'Reintentos: $retryCount/3',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (errorMessage != null)
              Text(
                'Error: $errorMessage',
                style: TextStyle(color: Colors.red[600], fontSize: 12),
              ),
          ],
        ),
        trailing: _buildActionButton(status),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildActionButton(String status) {
    if (status == 'failed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.blue),
            tooltip: 'Reintentar',
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: Colors.red[600]),
            tooltip: 'Eliminar',
          ),
        ],
      );
    }

    if (status == 'completed') {
      return Icon(Icons.check_circle, color: Colors.green[600], size: 24);
    }

    if (status == 'pending') {
      return Icon(Icons.schedule, color: Colors.orange[600], size: 24);
    }

    return const SizedBox.shrink();
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
