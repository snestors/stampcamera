import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';

class BotonMarcarSalida extends ConsumerWidget {
  final DateTime fechaSeleccionada;
  const BotonMarcarSalida({super.key, required this.fechaSeleccionada});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(asistenciaStatusProvider);
    final cargando = status == AsistenciaStatus.salidaLoading;

    return FloatingActionButton.extended(
      label: const Text('Marcar salida'),
      backgroundColor: Colors.deepOrange[400],
      icon: cargando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.logout),
      onPressed: cargando
          ? null
          : () async {
              final ok = await ref
                  .read(asistenciasDiariasProvider(fechaSeleccionada).notifier)
                  .marcarSalida(ref);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al marcar salida')),
                );
              }
            },
    );
  }
}
