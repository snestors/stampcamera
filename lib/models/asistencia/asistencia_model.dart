// models/asistencia_model.dart
import 'package:intl/intl.dart';

class Turno {
  final int id;
  final String nombre;
  final String horaInicio;
  final String horaFin;
  final String horasDescanso;

  Turno({
    required this.id,
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
    required this.horasDescanso,
  });

  factory Turno.fromJson(Map<String, dynamic> json) => Turno(
    id: json['id'],
    nombre: json['nombre'],
    horaInicio: json['hora_inicio'] ?? '08:00:00',
    horaFin: json['hora_fin'] ?? '17:30:00',
    horasDescanso: json['horas_descanso'] ?? '01:00:00',
  );
}

class ZonaTrabajo {
  final int id;
  final String value;
  final String? tipo; // PUERTO, OFICINA, ALMACEN-PDI, ALMACEN

  ZonaTrabajo({required this.id, required this.value, this.tipo});

  factory ZonaTrabajo.fromJson(Map<String, dynamic> json) => ZonaTrabajo(
        id: json['id'],
        value: json['value'],
        tipo: json['tipo'],
      );

  /// Orden de prioridad para ordenamiento
  int get ordenPrioridad {
    switch (tipo?.toUpperCase()) {
      case 'PUERTO':
        return 0;
      case 'OFICINA':
        return 1;
      case 'ALMACEN-PDI':
        return 2;
      case 'ALMACEN':
        return 3;
      default:
        return 99;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZonaTrabajo && other.id == id && other.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}

class Nave {
  final int id;
  final String value;

  Nave({required this.id, required this.value});

  factory Nave.fromJson(Map<String, dynamic> json) =>
      Nave(id: json['id'], value: json['value']);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Nave && other.id == id && other.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}

class Asistencia {
  final int id;
  final String usuario;
  final DateTime fechaHoraEntrada;
  final String ubicacionEntradaGps;
  final DateTime? fechaHoraSalida;
  final String? ubicacionSalidaGps;
  final bool activo;
  final String? comentarioUsuario;
  final String? comentarioAdmin;
  final ZonaTrabajo? zonaTrabajo;
  final Nave? nave;
  final String horasTrabajadasDisplay;

  Asistencia({
    required this.id,
    required this.usuario,
    required this.fechaHoraEntrada,
    required this.ubicacionEntradaGps,
    this.fechaHoraSalida,
    this.ubicacionSalidaGps,
    required this.activo,
    this.comentarioUsuario,
    this.comentarioAdmin,
    this.zonaTrabajo,
    this.nave,
    required this.horasTrabajadasDisplay,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    final formato = DateFormat("dd/MM/yyyy HH:mm");

    return Asistencia(
      id: json['id'],
      usuario: json['usuario'] ?? '',
      fechaHoraEntrada: formato.parse(json['fecha_hora_entrada']),
      ubicacionEntradaGps: json['ubicacion_entrada_gps'] ?? '',
      fechaHoraSalida: json['fecha_hora_salida'] != null
          ? formato.parse(json['fecha_hora_salida'])
          : null,
      ubicacionSalidaGps: json['ubicacion_salida_gps'],
      activo: json['activo'] ?? false,
      comentarioUsuario: json['comentario_usuario'],
      comentarioAdmin: json['comentario_admin'],
      zonaTrabajo: json['zona_trabajo'] != null
          ? ZonaTrabajo.fromJson(json['zona_trabajo'])
          : null,
      nave: json['nave'] != null ? Nave.fromJson(json['nave']) : null,
      horasTrabajadasDisplay: json['horas_trabajadas_display'] ?? '0h 0m',
    );
  }
}

/// Respuesta del endpoint /activa/
class AsistenciaActivaResponse {
  final bool tieneAsistenciaActiva;
  final Asistencia? asistencia;

  AsistenciaActivaResponse({
    required this.tieneAsistenciaActiva,
    this.asistencia,
  });

  factory AsistenciaActivaResponse.fromJson(Map<String, dynamic> json) {
    return AsistenciaActivaResponse(
      tieneAsistenciaActiva: json['tiene_asistencia_activa'] ?? false,
      asistencia: json['asistencia'] != null
          ? Asistencia.fromJson(json['asistencia'])
          : null,
    );
  }
}
