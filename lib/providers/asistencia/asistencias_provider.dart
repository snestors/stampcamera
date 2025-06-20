import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';
import 'package:stampcamera/services/http_service.dart';

final asistenciasDiariasProvider =
    StateNotifierProvider<
      AsistenciasNotifier,
      AsyncValue<List<AsistenciaDiaria>>
    >((ref) => AsistenciasNotifier());

class AsistenciasNotifier
    extends StateNotifier<AsyncValue<List<AsistenciaDiaria>>> {
  AsistenciasNotifier() : super(const AsyncValue.loading()) {
    fetchAsistencias(); // carga inicial
  }

  final _http = HttpService();

  Future<void> fetchAsistencias({String? fecha}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _http.dio.get(
        '/api/v1/asistencias/asistencias-diarias/',
        queryParameters: {if (fecha != null) 'fecha': fecha},
      );
      final List<AsistenciaDiaria> results = [];
      final rawList = response.data['results'] as List;
      for (var i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        try {
          final asistencia = AsistenciaDiaria.fromJson(item);
          results.add(asistencia);
        } catch (e, st) {
          print('❌ Error al parsear item $i');
          print('🧾 JSON: $item');
          print('📛 Error: $e');
          print('📍 Stack: $st');
        }
      }
      print('response.data: ${response.data}');

      state = AsyncValue.data([...results]); // fuerza nueva instancia
      print('state: ${state}');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> marcarEntrada({
    required int zonaTrabajoId,
    required int turnoId,
    required String gps,
    int? naveId,
    String? comentario,
  }) async {
    try {
      final payload = {
        'zona_trabajo_id': zonaTrabajoId,
        'turno_id': turnoId,
        'ubicacion_entrada_gps': gps,
        if (naveId != null) 'nave_id': naveId,
        if (comentario != null) 'comentario_usuario': comentario,
      };
      await _http.dio.post(
        '/api/v1/asistencias/asistencias-diarias/entrada/',
        data: payload,
      );
      await fetchAsistencias();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> marcarSalida({required String gps}) async {
    try {
      await _http.dio.post(
        '/api/v1/asistencias/asistencias-diarias/salida/',
        data: {'gps': gps},
      );
      await fetchAsistencias();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final asistenciaFormOptionsProvider =
    FutureProvider<FormularioAsistenciaOptions>((ref) async {
      final response = await HttpService().dio.get(
        '/api/v1/asistencias/asistencias-diarias/formulario-options/',
      );
      final zonas = (response.data['zonas'] as List)
          .map((e) => ZonaTrabajo.fromJson(e))
          .toList();
      final naves = (response.data['naves'] as List)
          .map((e) => Nave.fromJson(e))
          .toList();
      return FormularioAsistenciaOptions(zonas: zonas, naves: naves);
    });

class FormularioAsistenciaOptions {
  final List<ZonaTrabajo> zonas;
  final List<Nave> naves;

  FormularioAsistenciaOptions({required this.zonas, required this.naves});
}
