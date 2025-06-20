import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';

class DetalleRegistroCard extends StatelessWidget {
  final RegistroGeneral registro;

  const DetalleRegistroCard({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    final r = registro;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.serie != null && r.serie!.isNotEmpty
                  ? '${r.vin} (${r.serie})'
                  : r.vin,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${r.marca ?? ''} - ${r.modelo ?? ''}'),
            Text('Color: ${r.color ?? 'N/A'}'),
            Text('Versión: ${r.version ?? 'N/A'}'),
            Text('Nave: ${r.naveDescarga ?? 'N/A'}'),
            Text('BL: ${r.bl ?? 'N/A'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  r.pedeteado ? Icons.check_circle : Icons.cancel,
                  color: r.pedeteado ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text('Pedeteado', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Icon(
                  r.danos ? Icons.check_circle : Icons.cancel,
                  color: r.danos ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text('Daños', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
