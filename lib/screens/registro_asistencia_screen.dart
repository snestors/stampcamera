import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/providers/asistencia/asistencias_provider.dart';
import 'package:stampcamera/utils/gps_utils.dart';
import 'package:stampcamera/widgets/asistencia/dia_selector_widget.dart';
import 'package:stampcamera/widgets/asistencia/resumen_asistencia_widget.dart';
import 'package:stampcamera/widgets/asistencia/lista_asistencias_widget.dart';
import 'package:stampcamera/widgets/asistencia/modal_entrada.dart';
import 'package:geolocator/geolocator.dart';

class RegistroAsistenciaScreen extends ConsumerStatefulWidget {
  const RegistroAsistenciaScreen({super.key});

  @override
  ConsumerState<RegistroAsistenciaScreen> createState() =>
      _RegistroAsistenciaScreenState();
}

class _RegistroAsistenciaScreenState
    extends ConsumerState<RegistroAsistenciaScreen> {
  DateTime fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();

    _fetch();
  }

  void _fetch() {
    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
    ref
        .read(asistenciasDiariasProvider.notifier)
        .fetchAsistencias(fecha: fechaStr);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final asistenciasAsync = ref.watch(asistenciasDiariasProvider);
    final formOptionsAsync = ref.watch(asistenciaFormOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Registro de asistencia")),
      body: Column(
        children: [
          DiaSelectorWidget(
            fechaSeleccionada: fechaSeleccionada,
            onSeleccionar: (nuevaFecha) {
              if (!_isSameDay(nuevaFecha, fechaSeleccionada)) {
                setState(() => fechaSeleccionada = nuevaFecha);
                _fetch();
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
          final hayAsistencia = asistencias.isNotEmpty;
          final ultima = hayAsistencia
              ? asistencias.first.asistencias.firstOrNull
              : null;
          final hayActiva = ultima?.activo == true;

          if (!hayActiva) {
            return formOptionsAsync.when(
              data: (_) => FloatingActionButton.extended(
                onPressed: () => showMarcarEntradaBottomSheet(context, ref),
                icon: const Icon(Icons.login),
                label: const Text("Marcar entrada"),
              ),
              loading: () => null,
              error: (_, __) => null,
            );
          }

          return FloatingActionButton.extended(
            onPressed: () async {
              LocationPermission permission =
                  await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }

              if (permission == LocationPermission.denied ||
                  permission == LocationPermission.deniedForever) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permiso de ubicación denegado'),
                    ),
                  );
                }
                return; // Detiene el flujo si no hay permiso
              }
              final position = await obtenerGpsSeguro();
              final gps = "${position.latitude}, ${position.longitude}";

              final ok = await ref
                  .read(asistenciasDiariasProvider.notifier)
                  .marcarSalida(gps: gps);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? "Salida registrada correctamente"
                          : "Error al registrar salida",
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Marcar salida"),
            backgroundColor: Colors.red[400],
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}
