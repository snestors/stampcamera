import 'package:flutter/material.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';
import 'package:intl/intl.dart';

class ListaAsistenciasWidget extends StatelessWidget {
  final List<Asistencia> asistencias;

  const ListaAsistenciasWidget({super.key, required this.asistencias});

  @override
  Widget build(BuildContext context) {
    if (asistencias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Sin registros de asistencia en este día."),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: asistencias.length,
      itemBuilder: (context, index) {
        final asistencia = asistencias[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.login, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "Entrada: ${_formatHora(asistencia.fechaHoraEntrada)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (asistencia.fechaHoraSalida != null)
                      Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(_formatHora(asistencia.fechaHoraSalida!)),
                        ],
                      )
                    else
                      const SizedBox(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(asistencia.zonaTrabajo.value),
                  ],
                ),
                if (asistencia.nave != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_boat,
                        size: 18,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(asistencia.nave!.value)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatHora(DateTime dt) {
    return DateFormat.Hm().format(dt); // 09:32
  }
}
