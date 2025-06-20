import 'package:flutter/material.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';

class ResumenAsistenciaWidget extends StatelessWidget {
  final AsistenciaDiaria asistenciaDiaria;

  const ResumenAsistenciaWidget({super.key, required this.asistenciaDiaria});

  @override
  Widget build(BuildContext context) {
    final ultimaAsistencia = asistenciaDiaria.asistencias.firstOrNull;
    final hayActiva = ultimaAsistencia?.activo == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "Resumen de jornada",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.work, color: Colors.green),
                const SizedBox(width: 8),
                const Text("Horas trabajadas:"),
                const Spacer(),
                Text(
                  asistenciaDiaria.horasTrabajadas,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.flag_circle, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  hayActiva
                      ? "En ${ultimaAsistencia?.zonaTrabajo.value ?? 'Zona desconocida'}"
                      : "Sin asistencia",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hayActiva ? Colors.orange[800] : Colors.grey[700],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
