import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stampcamera/models/asistencia/asistencia_model.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/utils/gps_utils.dart';

void showMarcarEntradaBottomSheet(BuildContext context, WidgetRef ref) {
  final formOptions = ref.read(asistenciaFormOptionsProvider).value;
  if (formOptions == null) return;

  final zonas = formOptions.zonas;
  final naves = formOptions.naves;
  bool isLoading = false;
  ZonaTrabajo? zonaSeleccionada = zonas.firstOrNull;
  Nave? naveSeleccionada;
  final comentarioController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Registrar entrada",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Zona de trabajo
                  DropdownButtonFormField<ZonaTrabajo>(
                    value: zonaSeleccionada,
                    isExpanded: true, // ✅ importante para evitar overflow
                    items: zonas
                        .map(
                          (z) => DropdownMenuItem(
                            value: z,
                            child: Text(
                              z.value,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (zona) => setState(() {
                      zonaSeleccionada = zona;
                    }),
                    decoration: const InputDecoration(
                      labelText: "Zona de trabajo",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nave opcional
                  DropdownButtonFormField<Nave>(
                    value: naveSeleccionada,
                    items: naves
                        .map(
                          (n) =>
                              DropdownMenuItem(value: n, child: Text(n.value)),
                        )
                        .toList(),
                    onChanged: (n) => setState(() {
                      naveSeleccionada = n;
                    }),
                    decoration: const InputDecoration(
                      labelText: "Embarque (opcional)",
                      border: OutlineInputBorder(),
                    ),
                    isDense: true,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 12),

                  // Comentario
                  TextFormField(
                    controller: comentarioController,
                    decoration: const InputDecoration(
                      labelText: "Comentario",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Botón confirmar
                  ElevatedButton.icon(
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      isLoading ? "Procesando..." : "Confirmar entrada",
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => isLoading = true);

                            final position = await obtenerGpsSeguro();
                            final gps =
                                "${position.latitude},${position.longitude}";

                            final ok = await ref
                                .read(asistenciasDiariasProvider.notifier)
                                .marcarEntrada(
                                  zonaTrabajoId: zonaSeleccionada!.id,
                                  turnoId: 1,
                                  gps: gps,
                                  naveId: naveSeleccionada?.id,
                                  comentario: comentarioController.text.trim(),
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? "Entrada registrada correctamente"
                                        : "Error al registrar entrada",
                                  ),
                                ),
                              );
                            }

                            setState(() => isLoading = false);
                          },
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
