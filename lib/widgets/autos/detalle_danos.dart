import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/widgets/autos/detalle_imagen_preview.dart';

class DetalleDanos extends StatelessWidget {
  final List<Dano> danos;

  const DetalleDanos({super.key, required this.danos});

  @override
  Widget build(BuildContext context) {
    if (danos.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daños reportados',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...danos.map((d) {
          final condicionTexto =
              (d.condicion == "PUERTO" &&
                  (d.responsabilidad?.esp == "SNMP" ||
                      d.responsabilidad?.esp == "NAVIERA"))
              ? "ARRIBO"
              : d.condicion ?? "";

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condicionTexto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${d.tipoDano.esp} - ${d.areaDano.esp}'),
                  Text('Severidad: ${d.severidad.esp}'),
                  if (d.zonas.isNotEmpty)
                    Text(
                      'Zonas: ${d.zonas.map((z) => z.zona).join(', ')}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (d.descripcion != null && d.descripcion!.isNotEmpty)
                    Text('Descripción: ${d.descripcion}'),
                  if (d.nDocumento?.nDocumento != null)
                    Text('Doc: ${d.nDocumento!.nDocumento!}'),
                  if (d.responsabilidad?.esp != null)
                    Text('Responsabilidad: ${d.responsabilidad!.esp}'),
                  if (d.imagenes.isNotEmpty) const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: d.imagenes.map((img) {
                      return img.imagenThumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: NetworkImagePreview(
                                thumbnailUrl: img.imagenThumbnailUrl!,
                                fullImageUrl: img.imagenUrl!,
                              ),
                            )
                          : const SizedBox.shrink();
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                  if (d.createAt != null || d.createBy != null)
                    Text(
                      'Registrado: '
                      '${d.createAt ?? ''}'
                      '${d.createBy != null ? ' por ${d.createBy}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
