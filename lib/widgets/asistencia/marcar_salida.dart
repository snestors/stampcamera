import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';

class BotonMarcarSalida extends ConsumerStatefulWidget {
  final DateTime fechaSeleccionada;
  const BotonMarcarSalida({super.key, required this.fechaSeleccionada});

  @override
  ConsumerState<BotonMarcarSalida> createState() => _BotonMarcarSalidaState();
}

class _BotonMarcarSalidaState extends ConsumerState<BotonMarcarSalida> {

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      label: const Text('Marcar salida'),
      backgroundColor: Colors.deepOrange[400],
      icon: const Icon(Icons.logout), // ✅ Siempre ícono normal (modal maneja loading)
      onPressed: () async {
              // 🚨 BLOQUEO INMEDIATO - Mostrar modal de loading
              _showLoadingModal(context);
              
              // 🚨 Cambiar estado global para coordinación
              ref.read(asistenciaStatusProvider.notifier).state = 
                  AsistenciaStatus.salidaLoading;
              
              try {
                final ok = await ref
                    .read(asistenciasDiariasProvider(widget.fechaSeleccionada).notifier)
                    .marcarSalida(ref); // 🏁 Ya pasa ref para limpieza de providers
                
                // 🚨 Cerrar modal de loading
                if (context.mounted) Navigator.of(context).pop();
                
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al marcar salida')),
                  );
                }
              } catch (e) {
                // 🚨 Cerrar modal en caso de error
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } finally {
                // 🔄 Restaurar estado global
                ref.read(asistenciaStatusProvider.notifier).state = AsistenciaStatus.idle;
              }
            },
    );
  }

  /// 🚨 Muestra modal de loading que bloquea navegación
  void _showLoadingModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❌ No se puede cerrar tocando afuera
      builder: (context) => PopScope(
        canPop: false, // ❌ No se puede cerrar con botón atrás
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text('Marcando salida...'),
            ],
          ),
        ),
      ),
    );
  }
}
