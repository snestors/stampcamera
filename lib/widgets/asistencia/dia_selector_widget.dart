import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef OnFechaSeleccionada = void Function(DateTime fecha);

class DiaSelectorWidget extends StatefulWidget {
  final DateTime fechaSeleccionada;
  final OnFechaSeleccionada onSeleccionar;

  const DiaSelectorWidget({
    super.key,
    required this.fechaSeleccionada,
    required this.onSeleccionar,
  });

  @override
  State<DiaSelectorWidget> createState() => _DiaSelectorWidgetState();
}

class _DiaSelectorWidgetState extends State<DiaSelectorWidget> {
  late List<DateTime> dias;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    dias = List.generate(7, (i) => hoy.subtract(Duration(days: 6 - i)));

    // Asegurar que el día actual esté centrado al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = dias.indexWhere(
        (d) => isSameDay(d, widget.fechaSeleccionada),
      );
      if (index >= 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          index * 90.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          DateFormat('dd/MM/yyyy').format(widget.fechaSeleccionada),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: dias.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final dia = dias[index];
              final esSeleccionado = isSameDay(widget.fechaSeleccionada, dia);
              final isToday = isSameDay(dia, DateTime.now());

              return GestureDetector(
                onTap: () => widget.onSeleccionar(dia),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: esSeleccionado
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF003B5C),
                              Color.fromARGB(255, 215, 215, 230),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: esSeleccionado ? null : Colors.white,
                    border: Border.all(
                      color: esSeleccionado
                          ? Colors.transparent
                          : Colors.grey.shade300,
                    ),
                    boxShadow: esSeleccionado
                        ? [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E(
                          'es',
                        ).format(dia).toUpperCase(), // MON, TUE
                        style: TextStyle(
                          color: esSeleccionado ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.d().format(dia), // 23
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: esSeleccionado ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isToday && !esSeleccionado)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
