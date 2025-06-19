import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';

class DetalleInfoGeneral extends StatelessWidget {
  final DetalleRegistroModel r;

  const DetalleInfoGeneral({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.serie != null ? '${r.vin} (${r.serie})' : r.vin,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Marca: ${r.informacionUnidad?.marca.marca ?? 'N/A'}'),
            Text('Modelo: ${r.informacionUnidad?.modelo ?? 'N/A'}'),
            Text('Versión: ${r.informacionUnidad?.version ?? 'N/A'}'),
            Text('Color: ${r.color ?? 'N/A'}'),
            Text('Factura: ${r.factura ?? 'N/A'}'),
            Text('BL: ${r.bl ?? 'N/A'}'),
            Text('Nave descarga: ${r.naveDescarga ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}
