import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';

void showMarcarEntradaBottomSheet(
  BuildContext context,
  WidgetRef ref,
  DateTime fechaSeleccionada,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => ModalMarcarEntrada(fechaSeleccionada: fechaSeleccionada),
  );
}

class ModalMarcarEntrada extends ConsumerStatefulWidget {
  final DateTime fechaSeleccionada;

  const ModalMarcarEntrada({super.key, required this.fechaSeleccionada});

  @override
  ConsumerState<ModalMarcarEntrada> createState() => _ModalMarcarEntradaState();
}

class _ModalMarcarEntradaState extends ConsumerState<ModalMarcarEntrada> {
  ZonaTrabajo? zonaSeleccionada;
  Nave? naveSeleccionada;
  final TextEditingController comentarioCtrl = TextEditingController();

  @override
  void dispose() {
    comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formOptionsAsync = ref.watch(asistenciaFormOptionsProvider);
    final status = ref.watch(asistenciaStatusProvider);
    final notifier = ref.read(
      asistenciasDiariasProvider(widget.fechaSeleccionada).notifier,
    );

    return formOptionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
      data: (opciones) {
        final zonas = opciones.zonas;
        final naves = opciones.naves;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Marcar entrada",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<ZonaTrabajo>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Zona de trabajo'),
                value: zonaSeleccionada,
                items: zonas.map((zona) {
                  return DropdownMenuItem(value: zona, child: Text(zona.value));
                }).toList(),
                onChanged: (value) => setState(() => zonaSeleccionada = value),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<Nave>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nave (opcional)'),
                value: naveSeleccionada,
                items: [
                  ...naves.map(
                    (nave) =>
                        DropdownMenuItem(value: nave, child: Text(nave.value)),
                  ),
                ],
                onChanged: (value) => setState(() => naveSeleccionada = value),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: comentarioCtrl,
                decoration: const InputDecoration(
                  labelText: "Comentario (opcional)",
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: status == AsistenciaStatus.entradaLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: const Text('Confirmar entrada'),
                onPressed: (status == AsistenciaStatus.entradaLoading)
                    ? null
                    : () async {
                        if (zonaSeleccionada == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecciona una zona de trabajo'),
                            ),
                          );
                          return;
                        }

                        final ok = await notifier.marcarEntrada(
                          zonaTrabajoId: zonaSeleccionada!.id,
                          turnoId: 1, // <-- pon aquí tu lógica real
                          naveId: naveSeleccionada?.id,
                          comentario: comentarioCtrl.text.trim().isEmpty
                              ? null
                              : comentarioCtrl.text.trim(),
                        );

                        if (ok && context.mounted) {
                          Navigator.of(context).pop(); // el rebuild ocurre solo
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
