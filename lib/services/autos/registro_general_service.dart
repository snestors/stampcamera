// lib/services/autos/registro_general_service.dart

import 'package:stampcamera/core/base_service_imp.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/models/paginated_response.dart';
import 'package:stampcamera/services/http_service.dart';

/// Servicio para manejar registros generales usando Django DRF ViewSet
class RegistroGeneralService extends BaseServiceImpl<RegistroGeneral> {
  @override
  String get endpoint => '/api/v1/autos/registro-general/';

  @override
  RegistroGeneral Function(Map<String, dynamic>) get fromJson =>
      RegistroGeneral.fromJson;

  // ============================================================================
  // MÉTODOS ESPECÍFICOS DEL DOMINIO (si los hay)
  // ============================================================================

  /// Obtener registro por VIN
  Future<RegistroGeneral> getByVin(String vin) async {
    final response = await HttpService().dio.get('$endpoint$vin/');
    return fromJson(response.data);
  }

  /// Verificar si existe un VIN
  Future<bool> vinExists(String vin) async {
    try {
      await getByVin(vin);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtener registros con daños
  Future<PaginatedResponse<RegistroGeneral>> getWithDanos({
    Map<String, dynamic>? filters,
  }) async {
    return await search('', filters: {'danos': true, ...?filters});
  }

  /// Obtener registros pedeteados
  Future<PaginatedResponse<RegistroGeneral>> getPedeteados({
    Map<String, dynamic>? filters,
  }) async {
    return await search('', filters: {'pedeteado': true, ...?filters});
  }
}
