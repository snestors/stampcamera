/// Modelo para el reporte de pedeteo por jornadas
class ReportePedeteoJornadas {
  final String fecha;
  final List<JornadaReporte> jornadas;
  final int totalGeneral;

  const ReportePedeteoJornadas({
    required this.fecha,
    required this.jornadas,
    required this.totalGeneral,
  });

  factory ReportePedeteoJornadas.fromJson(Map<String, dynamic> json) {
    return ReportePedeteoJornadas(
      fecha: json['fecha'] ?? '',
      jornadas: (json['jornadas'] as List? ?? [])
          .map((j) => JornadaReporte.fromJson(j))
          .toList(),
      totalGeneral: json['total_general'] ?? 0,
    );
  }
}

class JornadaReporte {
  final String nombre;
  final String inicio;
  final String fin;
  final int total;
  final List<PersonaPedeteo> personas;

  const JornadaReporte({
    required this.nombre,
    required this.inicio,
    required this.fin,
    required this.total,
    required this.personas,
  });

  factory JornadaReporte.fromJson(Map<String, dynamic> json) {
    return JornadaReporte(
      nombre: json['nombre'] ?? '',
      inicio: json['inicio'] ?? '',
      fin: json['fin'] ?? '',
      total: json['total'] ?? 0,
      personas: (json['personas'] as List? ?? [])
          .map((p) => PersonaPedeteo.fromJson(p))
          .toList(),
    );
  }
}

class PersonaPedeteo {
  final String nombre;
  final int cantidad;
  final List<VinPedeteo> vins;
  final List<ResumenHora> resumenPorHora;

  const PersonaPedeteo({
    required this.nombre,
    required this.cantidad,
    required this.vins,
    required this.resumenPorHora,
  });

  factory PersonaPedeteo.fromJson(Map<String, dynamic> json) {
    return PersonaPedeteo(
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      vins: (json['vins'] as List? ?? [])
          .map((v) => VinPedeteo.fromJson(v))
          .toList(),
      resumenPorHora: (json['resumen_por_hora'] as List? ?? [])
          .map((r) => ResumenHora.fromJson(r))
          .toList(),
    );
  }
}

class ResumenHora {
  final String hora;
  final int cantidad;

  const ResumenHora({
    required this.hora,
    required this.cantidad,
  });

  factory ResumenHora.fromJson(Map<String, dynamic> json) {
    return ResumenHora(
      hora: json['hora'] ?? '',
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

class VinPedeteo {
  final String vin;
  final String condicion;
  final String hora;

  const VinPedeteo({
    required this.vin,
    required this.condicion,
    required this.hora,
  });

  factory VinPedeteo.fromJson(Map<String, dynamic> json) {
    return VinPedeteo(
      vin: json['vin'] ?? '',
      condicion: json['condicion'] ?? '',
      hora: json['hora'] ?? '',
    );
  }
}
