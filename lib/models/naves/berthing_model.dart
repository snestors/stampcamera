/// Detalle de una nave (berthing) — solo los campos editables.
/// Se obtiene de GET /api/v1/berthings/{id}/.
class BerthingDetail {
  final int id;
  final BerthingEstatus? estatus;
  final DateTime? fechaArribo;
  final DateTime? fechaAtraque;
  final DateTime? fechaFinOperacion;

  const BerthingDetail({
    required this.id,
    this.estatus,
    this.fechaArribo,
    this.fechaAtraque,
    this.fechaFinOperacion,
  });

  factory BerthingDetail.fromJson(Map<String, dynamic> json) {
    return BerthingDetail(
      id: json['id'] ?? 0,
      estatus: BerthingEstatus.fromCode(json['estatus'] as String?),
      fechaArribo: _parseDate(json['fecha_arribo']),
      fechaAtraque: _parseDate(json['fecha_atraque']),
      fechaFinOperacion: _parseDate(json['fecha_fin_operacion']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Modelo del estado de una nave (BerthingsModel en backend)
enum BerthingEstatus {
  nuevo('01', 'Nuevo'),
  confirmado('02', 'Confirmado'),
  operacion('03', 'En operación'),
  finalizado('04', 'Finalizado'),
  cancelado('05', 'Cancelado'),
  paralizado('06', 'Paralizado');

  final String code;
  final String label;
  const BerthingEstatus(this.code, this.label);

  static BerthingEstatus? fromCode(String? code) {
    if (code == null) return null;
    for (final e in BerthingEstatus.values) {
      if (e.code == code) return e;
    }
    return null;
  }
}

/// Form options de /api/v1/berthings/form_options/ — solo los campos que usamos
class BerthingsFormOptions {
  final List<BerthingEstatus> estatusDisponibles;
  final Map<String, List<String>> estatusTransiciones;

  const BerthingsFormOptions({
    required this.estatusDisponibles,
    required this.estatusTransiciones,
  });

  factory BerthingsFormOptions.fromJson(Map<String, dynamic> json) {
    final estatusList = (json['estatus'] as List?) ?? [];
    final estatus = estatusList
        .map((e) => BerthingEstatus.fromCode(e['value'] as String?))
        .whereType<BerthingEstatus>()
        .toList();

    final transicionesRaw =
        (json['estatus_transiciones'] as Map<String, dynamic>?) ?? {};
    final transiciones = transicionesRaw.map(
      (k, v) => MapEntry(k, List<String>.from(v as List? ?? [])),
    );

    return BerthingsFormOptions(
      estatusDisponibles: estatus,
      estatusTransiciones: transiciones,
    );
  }

  /// Estados a los que se puede transicionar desde [actual].
  /// Incluye el actual cuando el backend lo contempla (típicamente sí).
  List<BerthingEstatus> transicionesDesde(BerthingEstatus? actual) {
    if (actual == null) return estatusDisponibles;
    final codes = estatusTransiciones[actual.code] ?? const <String>[];
    return codes
        .map((c) => BerthingEstatus.fromCode(c))
        .whereType<BerthingEstatus>()
        .toList();
  }
}

/// Payload de update para PATCH /api/v1/berthings/{id}/
class BerthingUpdatePayload {
  final BerthingEstatus? estatus;
  final DateTime? fechaArribo;
  final DateTime? fechaAtraque;
  final DateTime? fechaFinOperacion;

  const BerthingUpdatePayload({
    this.estatus,
    this.fechaArribo,
    this.fechaAtraque,
    this.fechaFinOperacion,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (estatus != null) data['estatus'] = estatus!.code;
    if (fechaArribo != null) {
      data['fecha_arribo'] = fechaArribo!.toIso8601String();
    }
    if (fechaAtraque != null) {
      data['fecha_atraque'] = fechaAtraque!.toIso8601String();
    }
    if (fechaFinOperacion != null) {
      data['fecha_fin_operacion'] = fechaFinOperacion!.toIso8601String();
    }
    return data;
  }
}
