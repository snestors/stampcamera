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
        return _AnimatedAsistenciaItem(
          asistencia: asistencias[index],
          index: index,
        );
      },
    );
  }
}

//-------------------  WIDGET ANIMADO  -------------------
class _AnimatedAsistenciaItem extends StatefulWidget {
  final Asistencia asistencia;
  final int index;
  const _AnimatedAsistenciaItem({
    required this.asistencia,
    required this.index,
  });

  @override
  State<_AnimatedAsistenciaItem> createState() =>
      _AnimatedAsistenciaItemState();
}

class _AnimatedAsistenciaItemState extends State<_AnimatedAsistenciaItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ); // opacidad
    _slide = Tween<Offset>(
      begin: const Offset(0, .10), // 10 % hacia abajo
      end: Offset.zero,
    ).animate(_fade); // se sincroniza con _fade

    // Pequeño retraso escalonado
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _AsistenciaCard(asistencia: widget.asistencia),
      ),
    );
  }
}

//-------------------  TARJETA ORIGINAL  -------------------
class _AsistenciaCard extends StatelessWidget {
  final Asistencia asistencia;
  const _AsistenciaCard({required this.asistencia});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003B5C);
    const accent = Color(0xFF00B4D8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA), // gris muy claro
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Franja lateral
            Container(
              width: 6,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Línea Entrada / Salida
                    Row(
                      children: [
                        _ChipIcon(icon: Icons.login, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          "Entrada: ${_formatHora(asistencia.fechaHoraEntrada)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (asistencia.fechaHoraSalida != null)
                          Row(
                            children: [
                              _ChipIcon(icon: Icons.logout, color: Colors.red),
                              const SizedBox(width: 6),
                              Text(
                                _formatHora(asistencia.fechaHoraSalida!),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Zona de trabajo
                    if (asistencia.zonaTrabajo != null)
                      Row(
                        children: [
                          _ChipIcon(icon: Icons.place, color: Colors.blueGrey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              asistencia.zonaTrabajo!.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                    // Nave (opcional)
                    if (asistencia.nave != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _ChipIcon(
                            icon: Icons.directions_boat,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              asistencia.nave!.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHora(DateTime dt) => DateFormat.Hm().format(dt);
}

//----- Mini “chip” circular para iconos -----
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
