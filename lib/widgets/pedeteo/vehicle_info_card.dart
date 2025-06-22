// =====================================================
// 9. widgets/pedeteo/vehicle_info_card.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';

class VehicleInfoCard extends StatelessWidget {
  final RegistroGeneral vehicleInfo;

  const VehicleInfoCard({super.key, required this.vehicleInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Vehículo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('VIN:', vehicleInfo.vin),
            _buildInfoRow('Serie:', vehicleInfo.serie ?? 'N/A'),
            _buildInfoRow('Marca:', vehicleInfo.marca ?? 'N/A'),
            _buildInfoRow('Modelo:', vehicleInfo.modelo ?? 'N/A'),
            _buildInfoRow('Color:', vehicleInfo.color ?? 'N/A'),
            _buildInfoRow('Nave:', vehicleInfo.naveDescarga ?? 'N/A'),
            _buildInfoRow('BL:', vehicleInfo.bl ?? 'N/A'),
            _buildInfoRow('Versión:', vehicleInfo.version ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
