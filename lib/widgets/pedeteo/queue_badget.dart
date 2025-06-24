// lib/widgets/pedeteo/queue_badge.dart - CAMBIOS MÍNIMOS
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/autos/queue_state_provider.dart'; // ✅ Solo cambiar import
import 'package:stampcamera/widgets/pedeteo/queue_side_widget.dart';

class QueueBadge extends ConsumerWidget {
  const QueueBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ SOLO CAMBIO: Usar el provider optimizado
    final count = ref.watch(pendingQueueCountProvider);

    return IconButton(
      onPressed: () => _showProcessDialog(context, ref),
      tooltip: 'Registros pendientes: $count',
      icon: count > 0
          ? Badge(
              label: Text('$count'),
              child: const Icon(Icons.cloud_upload_outlined),
            )
          : const Icon(Icons.cloud_upload_outlined),
    );
  }

  void _showProcessDialog(BuildContext context, WidgetRef ref) {
    // ✅ MANTENER IGUAL: Tu lógica de mostrar panel
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: const QueueSideWidget(),
        );
      },
    );
  }
}
