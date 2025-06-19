import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/services/http_service.dart';

final registroDetalleProvider =
    FutureProvider.family<DetalleRegistroModel, String>((ref, vin) async {
      return await _getByVin(vin);
    });

Future<DetalleRegistroModel> _getByVin(String vin) async {
  final res = await HttpService().dio.get(
    '/api/v1/autos/registro-general/$vin/',
  );
  return DetalleRegistroModel.fromJson(res.data);
}
