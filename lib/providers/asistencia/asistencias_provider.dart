import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/asistencia/asistencia_model.dart';
import 'package:stampcamera/providers/auth_provider.dart';
import 'package:stampcamera/providers/session_manager_provider.dart';
import 'package:stampcamera/services/http_service.dart';
import 'package:stampcamera/utils/gps_utils.dart';

enum AsistenciaStatus { idle, entradaLoading, salidaLoading, error }

final asistenciaStatusProvider = StateProvider<AsistenciaStatus>(
  (_) => AsistenciaStatus.idle,
);

/// Provider para obtener la asistencia activa del usuario
final asistenciaActivaProvider =
    AsyncNotifierProvider<AsistenciaActivaNotifier, AsistenciaActivaResponse>(
  () => AsistenciaActivaNotifier(),
);

class AsistenciaActivaNotifier extends AsyncNotifier<AsistenciaActivaResponse> {
  final _http = HttpService();

  @override
  FutureOr<AsistenciaActivaResponse> build() async {
    ref.keepAlive();
    return _fetchAsistenciaActiva();
  }

  Future<AsistenciaActivaResponse> _fetchAsistenciaActiva() async {
    final res = await _http.dio.get('/api/v1/asistencias/activa/');
    return AsistenciaActivaResponse.fromJson(res.data);
  }

  /// Refresca el estado de asistencia activa
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAsistenciaActiva());
  }

  // ------------------------------------------------------------------
  // ENTRADA
  // ------------------------------------------------------------------
  Future<bool> marcarEntrada({
    required int zonaTrabajoId,
    int? naveId,
    String? comentario,
    WidgetRef? wref,
  }) async {
    ref.read(asistenciaStatusProvider.notifier).state =
        AsistenciaStatus.entradaLoading;

    // Limpiar providers al iniciar asistencia
    if (wref != null) {
      ref.read(sessionManagerProvider.notifier).onStartAssistance(wref);
    }

    try {
      final gps = await _getGps();
      await _http.dio.post(
        '/api/v1/asistencias/entrada/',
        data: {
          'zona_trabajo_id': zonaTrabajoId,
          'ubicacion_entrada_gps': gps,
          if (naveId != null) 'nave_id': naveId,
          if (comentario != null) 'comentario_usuario': comentario,
        },
      );

      // Refrescar estado de asistencia
      ref.invalidateSelf();

      // Refrescar authProvider para actualizar ultimaAsistenciaActiva en HomeScreen
      await ref.read(authProvider.notifier).refreshUser();

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.read(asistenciaStatusProvider.notifier).state = AsistenciaStatus.error;
      return false;
    } finally {
      ref.read(asistenciaStatusProvider.notifier).state = AsistenciaStatus.idle;
    }
  }

  // ------------------------------------------------------------------
  // SALIDA
  // ------------------------------------------------------------------
  Future<bool> marcarSalida([WidgetRef? wref]) async {
    ref.read(asistenciaStatusProvider.notifier).state =
        AsistenciaStatus.salidaLoading;

    // Limpiar providers al terminar asistencia
    if (wref != null) {
      ref.read(sessionManagerProvider.notifier).onEndAssistance(wref);
    }

    try {
      final gps = await _getGps();
      await _http.dio.post(
        '/api/v1/asistencias/salida/',
        data: {'gps': gps},
      );

      // Refrescar estado de asistencia
      ref.invalidateSelf();

      // Refrescar authProvider para actualizar ultimaAsistenciaActiva en HomeScreen
      await ref.read(authProvider.notifier).refreshUser();

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.read(asistenciaStatusProvider.notifier).state = AsistenciaStatus.error;
      return false;
    } finally {
      ref.read(asistenciaStatusProvider.notifier).state = AsistenciaStatus.idle;
    }
  }

  Future<String> _getGps() async {
    final p = await obtenerGpsSeguro();
    return '${p.latitude},${p.longitude}';
  }
}

/// Provider para historial de asistencias (paginado)
final asistenciaHistorialProvider =
    FutureProvider.family<List<Asistencia>, ({String? fechaInicio, String? fechaFin})>(
  (ref, params) async {
    final queryParams = <String, dynamic>{};
    if (params.fechaInicio != null) {
      queryParams['fecha_inicio'] = params.fechaInicio;
    }
    if (params.fechaFin != null) {
      queryParams['fecha_fin'] = params.fechaFin;
    }

    final res = await HttpService().dio.get(
      '/api/v1/asistencias/historial/',
      queryParameters: queryParams,
    );

    final results = res.data['results'] as List? ?? res.data as List;
    return results.map((e) => Asistencia.fromJson(e)).toList();
  },
);

// ---------------------------------------------------------------------
// Opciones para el formulario de entrada
// ---------------------------------------------------------------------
class FormularioAsistenciaOptions {
  final List<ZonaTrabajo> zonas;
  final List<Nave> naves;

  FormularioAsistenciaOptions({
    required this.zonas,
    required this.naves,
  });
}

final asistenciaFormOptionsProvider =
    FutureProvider<FormularioAsistenciaOptions>((ref) async {
  final res = await HttpService().dio.get(
    '/api/v1/asistencias/formulario-options/',
  );

  // Parsear zonas y ordenar por tipo: PUERTO, OFICINA, ALMACEN-PDI, ALMACEN
  final zonas = (res.data['zonas'] as List)
      .map((e) => ZonaTrabajo.fromJson(e))
      .toList()
    ..sort((a, b) {
      // Primero por tipo (prioridad)
      final compareTipo = a.ordenPrioridad.compareTo(b.ordenPrioridad);
      if (compareTipo != 0) return compareTipo;
      // Luego alfabéticamente dentro del mismo tipo
      return a.value.compareTo(b.value);
    });

  return FormularioAsistenciaOptions(
    zonas: zonas,
    naves: (res.data['naves'] as List)
        .map((e) => Nave.fromJson(e))
        .toList(),
  );
});
