import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';

class DetalleFotosPresentacion extends StatelessWidget {
  final List<FotoPresentacion> items;

  const DetalleFotosPresentacion({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos de presentación',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((f) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (f.imagenThumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkImagePreview(
                      thumbnailUrl: f.imagenThumbnailUrl!,
                      fullImageUrl: f.imagenUrl!,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(f.tipo, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
