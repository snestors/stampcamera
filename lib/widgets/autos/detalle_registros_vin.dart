import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';

class DetalleRegistrosVin extends StatelessWidget {
  final List<RegistroVin> items;

  const DetalleRegistrosVin({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de condiciones',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (e) => Card(
            child: ListTile(
              title: Text(e.condicion),
              subtitle: Text('${e.zonaInspeccion} - ${e.fecha ?? ''}'),
              trailing: e.fotoVinThumbnailUrl != null
                  ? NetworkImagePreview(
                      fullImageUrl: e.fotoVinUrl!,
                      thumbnailUrl: e.fotoVinThumbnailUrl!,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
