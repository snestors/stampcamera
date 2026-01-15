import 'package:flutter/material.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';

class ResumenAsistenciaWidget extends StatelessWidget {
  final Asistencia asistencia;
  const ResumenAsistenciaWidget({super.key, required this.asistencia});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003B5C);
    const accent = Color(0xFF00B4D8);

    final hayActiva = asistencia.activo;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withValues(alpha: 0.16),
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment(-0.8, -0.8),
              radius: 1.2,
              colors: [Color(0xFFF9FBFC), Color(0xFFF3F6F8)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: .8),
                blurRadius: 4,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 8,
                offset: const Offset(3, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ChipIcon(icon: Icons.access_time, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      "Resumen de jornada",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                Row(
                  children: [
                    _ChipIcon(icon: Icons.work, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      "Horas trabajadas:",
                      style: TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      asistencia.horasTrabajadasDisplay,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ChipIcon(
                      icon: Icons.flag_circle,
                      color: hayActiva ? Colors.orange : primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hayActiva
                            ? "En ${asistencia.zonaTrabajo?.value ?? 'zona desconocida'}"
                            : "Asistencia cerrada",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: hayActiva
                              ? Colors.orange[800]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reutilizamos el mismo mini-chip
class _ChipIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ChipIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
