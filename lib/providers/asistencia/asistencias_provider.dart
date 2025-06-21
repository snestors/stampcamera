import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';
import 'package:stampcamera/services/http_service.dart';
import 'package:stampcamera/utils/gps_utils.dart';

enum AsistenciaStatus { idle, entradaLoading, salidaLoading, error }

final asistenciaStatusProvider = StateProvider<AsistenciaStatus>(
  (_) => AsistenciaStatus.idle,
);

final asistenciasDiariasProvider =
    AsyncNotifierProvider.family<
      AsistenciasNotifier,
      List<AsistenciaDiaria>,
      DateTime
    >(() => AsistenciasNotifier());

class AsistenciasNotifier
    extends FamilyAsyncNotifier<List<AsistenciaDiaria>, DateTime> {
  final _http = HttpService();

  // Mantener vivo
  @override
  FutureOr<List<AsistenciaDiaria>> build(DateTime fecha) async {
    ref.keepAlive();
    return _fetchAsistencias(fecha);
  }

  Future<List<AsistenciaDiaria>> _fetchAsistencias(DateTime fecha) async {
    final f = fecha.toIso8601String().split('T').first;
    final res = await _http.dio.get(
      '/api/v1/asistencias/asistencias-diarias/',
      queryParameters: {'fecha': f},
    );
    return (res.data['results'] as List)
        .map((e) => AsistenciaDiaria.fromJson(e))
        .toList();
  }

  // ------------------------------------------------------------------
  // ENTRADA
  // ------------------------------------------------------------------
  Future<bool> marcarEntrada({
    required int zonaTrabajoId,
    required int turnoId,
    int? naveId,
    String? comentario,
  }) async {
    ref.read(asistenciaStatusProvider.notifier).state =
        AsistenciaStatus.entradaLoading;

    try {
      final gps = await _getGps();
      await _http.dio.post(
        '/api/v1/asistencias/asistencias-diarias/entrada/',
        data: {
          'zona_trabajo_id': zonaTrabajoId,
          'turno_id': turnoId,
          'ubicacion_entrada_gps': gps,
          if (naveId != null) 'nave_id': naveId,
          if (comentario != null) 'comentario_usuario': comentario,
        },
      );

      // 🔥 disparo un refetch obligatorio
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.read(asistenciaStatusProvider.notifier).state =
          AsistenciaStatus.error;
      return false;
    } finally {
      ref.read(asistenciaStatusProvider.notifier).state = AsistenciaStatus.idle;
    }
  }

  // ------------------------------------------------------------------
  // SALIDA
  // ------------------------------------------------------------------
  Future<bool> marcarSalida() async {
    ref.read(asistenciaStatusProvider.notifier).state =
        AsistenciaStatus.salidaLoading;

    try {
      final gps = await _getGps();
      await _http.dio.post(
        '/api/v1/asistencias/asistencias-diarias/salida/',
        data: {'gps': gps},
      );

      // 🔥 disparo un refetch obligatorio
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.read(asistenciaStatusProvider.notifier).state =
          AsistenciaStatus.error;
      return false;
    } finally {
      ref.read(asistenciaStatusProvider.notifier).state = AsistenciaStatus.idle;
    }
  }

  // util
  Future<String> _getGps() async {
    final p = await obtenerGpsSeguro();
    return '${p.latitude},${p.longitude}';
  }
}

// ---------------------------------------------------------------------
// Opciones para el formulario de entrada
// ---------------------------------------------------------------------
class FormularioAsistenciaOptions {
  final List<ZonaTrabajo> zonas;
  final List<Nave> naves;
  FormularioAsistenciaOptions({required this.zonas, required this.naves});
}

final asistenciaFormOptionsProvider =
    FutureProvider<FormularioAsistenciaOptions>((ref) async {
      final res = await HttpService().dio.get(
        '/api/v1/asistencias/asistencias-diarias/formulario-options/',
      );
      return FormularioAsistenciaOptions(
        zonas: (res.data['zonas'] as List)
            .map((e) => ZonaTrabajo.fromJson(e))
            .toList(),
        naves: (res.data['naves'] as List)
            .map((e) => Nave.fromJson(e))
            .toList(),
      );
    });
