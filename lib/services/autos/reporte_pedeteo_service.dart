import 'package:stampcamera/models/autos/reporte_pedeteo_model.dart';
import 'package:stampcamera/services/http_service.dart';

/// Servicio para obtener reportes de pedeteo
class ReportePedeteoService {
  final _http = HttpService();

  /// Obtiene el reporte de pedeteo por jornadas de 8 horas
  ///
  /// - [fecha]: Fecha en formato YYYY-MM-DD (opcional, por defecto fecha actual)
  /// - [naveId]: ID de la nave de descarga (opcional)
  Future<ReportePedeteoJornadas> getReportePorJornadas({
    String? fecha,
    int? naveId,
  }) async {
    final queryParams = <String, String>{};

    if (fecha != null) {
      queryParams['fecha'] = fecha;
    }
    if (naveId != null) {
      queryParams['nave_id'] = naveId.toString();
    }

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _http.dio.get(
      '/api/v1/autos/registro-vin/reporte_pedeteo_jornadas/$queryString',
    );

    if (response.data['success'] == true) {
      return ReportePedeteoJornadas.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['error'] ?? 'Error al obtener reporte');
    }
  }
}
