import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/widgets/asistencia/dia_selector_widget.dart';
import 'package:stampcamera/widgets/asistencia/marcar_salida.dart';
import 'package:stampcamera/widgets/asistencia/resumen_asistencia_widget.dart';
import 'package:stampcamera/widgets/asistencia/lista_asistencias_widget.dart';
import 'package:stampcamera/widgets/asistencia/modal_entrada.dart';

class RegistroAsistenciaScreen extends ConsumerStatefulWidget {
  const RegistroAsistenciaScreen({super.key});

  @override
  ConsumerState<RegistroAsistenciaScreen> createState() =>
      _RegistroAsistenciaScreenState();
}

class _RegistroAsistenciaScreenState
    extends ConsumerState<RegistroAsistenciaScreen> {
  DateTime fechaSeleccionada = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final asistenciasAsync = ref.watch(
      asistenciasDiariasProvider(fechaSeleccionada),
    );
    final formOptionsAsync = ref.watch(asistenciaFormOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Registro de asistencia")),
      body: Column(
        children: [
          DiaSelectorWidget(
            fechaSeleccionada: fechaSeleccionada,
            onSeleccionar: (nuevaFecha) {
              print(nuevaFecha);
              if (!_isSameDay(nuevaFecha, fechaSeleccionada)) {
                setState(() => fechaSeleccionada = nuevaFecha);
              }
            },
          ),
          Expanded(
            child: asistenciasAsync.when(
              data: (asistencias) {
                if (asistencias.isEmpty) {
                  return const Center(
                    child: Text("No hay asistencia registrada para este día."),
                  );
                }

                final asistenciaDelDia = asistencias.first;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResumenAsistenciaWidget(
                        asistenciaDiaria: asistenciaDelDia,
                      ),
                      ListaAsistenciasWidget(
                        asistencias: asistenciaDelDia.asistencias,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
      floatingActionButton: asistenciasAsync.when(
        data: (asistencias) {
          if (asistencias.isEmpty) return null;

          final asistenciaDelDia = asistencias.first;
          final hayActiva = asistenciaDelDia.asistenciaActiva;

          if (hayActiva) {
            return BotonMarcarSalida(fechaSeleccionada: fechaSeleccionada);
          } else {
            return formOptionsAsync.when(
              data: (_) => FloatingActionButton.extended(
                onPressed: () => showMarcarEntradaBottomSheet(
                  context,
                  ref,
                  fechaSeleccionada,
                ),
                icon: const Icon(Icons.login),
                label: const Text("Marcar entrada"),
              ),
              loading: () => null,
              error: (_, __) => null,
            );
          }
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}
