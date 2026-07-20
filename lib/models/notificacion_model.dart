/// Notificación del usuario (bandeja efímera, espejo de la web).
///
/// Dos orígenes con shapes distintos:
/// - REST `GET notificaciones/`:
///   {id, titulo, cuerpo, tipo, emitido_por, creado_en ("hace 5 minutos"),
///    creado_en_iso, url}
/// - WS `ws/app/` evento `notification`:
///   {id, title, message, tipo, url, timestamp}
class NotificacionModel {
  final int id;
  final String titulo;
  final String cuerpo;

  /// info | warning | error | success | message
  final String tipo;
  final String emitidoPor;
  final String? url;

  /// Instante de creación (ISO del backend); null solo si el backend
  /// no lo envió (deploy viejo) — se usa [creadoEnTexto] como fallback.
  final DateTime? creadoEn;

  /// Texto relativo pre-formateado del backend ("hace 5 minutos").
  final String? creadoEnTexto;

  const NotificacionModel({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    this.emitidoPor = '',
    this.url,
    this.creadoEn,
    this.creadoEnTexto,
  });

  factory NotificacionModel.fromApiJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: _asInt(json['id']),
      titulo: (json['titulo'] as String?) ?? 'Notificación',
      cuerpo: (json['cuerpo'] as String?) ?? '',
      tipo: (json['tipo'] as String?) ?? 'info',
      emitidoPor: (json['emitido_por'] as String?) ?? '',
      url: json['url'] as String?,
      creadoEn: _tryParseDate(json['creado_en_iso']),
      creadoEnTexto: json['creado_en'] as String?,
    );
  }

  factory NotificacionModel.fromWs(Map<String, dynamic> data) {
    return NotificacionModel(
      id: _asInt(data['id']),
      titulo: (data['title'] as String?) ?? 'Notificación',
      cuerpo: (data['message'] as String?) ?? '',
      tipo: (data['tipo'] as String?) ?? 'info',
      url: data['url'] as String?,
      creadoEn: _tryParseDate(data['timestamp']) ?? DateTime.now(),
    );
  }

  /// Cuerpos auto-generados que el backend excluye del listado REST
  /// (views.py de pushnotificacitons). Se replica el filtro para las que
  /// llegan por WS: ni banner ni bandeja las muestran.
  static const _cuerposExcluidos = [
    'Se ha registrado un nuevo ticket:',
    'Se ha registrado un nuevo VIN:',
  ];

  bool get esRuidoAutomatico => _cuerposExcluidos.any(cuerpo.startsWith);

  /// "ahora" / "hace 5 min" / "hace 2 h" / "hace 1 d"
  String get tiempoRelativo {
    final fecha = creadoEn;
    if (fecha == null) {
      return creadoEnTexto != null ? 'hace $creadoEnTexto' : '';
    }
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
