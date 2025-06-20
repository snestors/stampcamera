// models/asistencia_model.dart

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
    horaInicio: json['hora_inicio'],
    horaFin: json['hora_fin'],
    horasDescanso: json['horas_descanso'],
  );
}

class ZonaTrabajo {
  final int id;
  final String value;

  ZonaTrabajo({required this.id, required this.value});

  factory ZonaTrabajo.fromJson(Map<String, dynamic> json) =>
      ZonaTrabajo(id: json['id'], value: json['value']);
}

class Nave {
  final int id;
  final String value;

  Nave({required this.id, required this.value});

  factory Nave.fromJson(Map<String, dynamic> json) =>
      Nave(id: json['id'], value: json['value']);
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
  final ZonaTrabajo zonaTrabajo;
  final Nave? nave;
  final Turno turno;

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
    required this.zonaTrabajo,
    this.nave,
    required this.turno,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) => Asistencia(
    id: json['id'],
    usuario: json['usuario'],
    fechaHoraEntrada: DateTime.parse(json['fecha_hora_entrada']),
    ubicacionEntradaGps: json['ubicacion_entrada_gps'],
    fechaHoraSalida: json['fecha_hora_salida'] != null
        ? DateTime.parse(json['fecha_hora_salida'])
        : null,
    ubicacionSalidaGps: json['ubicacion_salida_gps'],
    activo: json['activo'],
    comentarioUsuario: json['comentario_usuario'],
    comentarioAdmin: json['comentario_admin'],
    zonaTrabajo: ZonaTrabajo.fromJson(json['zona_trabajo']),
    nave: json['nave'] != null ? Nave.fromJson(json['nave']) : null,
    turno: Turno.fromJson(json['turno']),
  );
}

class AsistenciaDiaria {
  final int id;
  final String usuario;
  final String fecha;
  final String horasTrabajadas;
  final String horasExtras;
  final String horasDebe;
  final Turno? turno;
  final String estado;
  final String? motivoInasistencia;
  final List<Asistencia> asistencias;

  AsistenciaDiaria({
    required this.id,
    required this.usuario,
    required this.fecha,
    required this.horasTrabajadas,
    required this.horasExtras,
    required this.horasDebe,
    this.turno,
    required this.estado,
    this.motivoInasistencia,
    required this.asistencias,
  });

  factory AsistenciaDiaria.fromJson(Map<String, dynamic> json) =>
      AsistenciaDiaria(
        id: json['id'],
        usuario: json['usuario'],
        fecha: json['fecha'],
        horasTrabajadas: json['horas_trabajadas'],
        horasExtras: json['horas_extras'],
        horasDebe: json['horas_debe'],
        turno: json['turno'] != null ? Turno.fromJson(json['turno']) : null,
        estado: json['estado'],
        motivoInasistencia: json['motivo_inasistencia'],
        asistencias: (json['asistencias'] as List)
            .map((e) => Asistencia.fromJson(e))
            .toList(),
      );
}
