// =============================================================================
// MODELOS DEL EXPLORADOR DE ARCHIVOS - Casos y Documentos
// =============================================================================

// ─── Enums ─────────────────────────────────────────────────────────────

enum TipoCarpeta { caso, documento, general }

TipoCarpeta? parseTipoCarpeta(String? value) {
  if (value == null) return null;
  switch (value.toUpperCase()) {
    case 'CASO':
      return TipoCarpeta.caso;
    case 'DOCUMENTO':
      return TipoCarpeta.documento;
    case 'GENERAL':
      return TipoCarpeta.general;
    default:
      return null;
  }
}

enum Visibilidad { todos, restringido }

Visibilidad parseVisibilidad(String? value) {
  if (value == null || value.toUpperCase() == 'TODOS') {
    return Visibilidad.todos;
  }
  return Visibilidad.restringido;
}

// ─── CasoSimple ────────────────────────────────────────────────────────

class CasoSimple {
  final int id;
  final String nCaso;
  final String fecha;
  final String? rubroNombre;
  final String? destinatarioNombre;
  final String? asuntoDetalle;

  const CasoSimple({
    required this.id,
    required this.nCaso,
    required this.fecha,
    this.rubroNombre,
    this.destinatarioNombre,
    this.asuntoDetalle,
  });

  factory CasoSimple.fromJson(Map<String, dynamic> json) {
    return CasoSimple(
      id: json['id'] as int,
      nCaso: json['n_caso'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      rubroNombre: json['rubro_nombre'] as String?,
      destinatarioNombre: json['destinatario_nombre'] as String?,
      asuntoDetalle: json['asunto_detalle'] as String?,
    );
  }
}

// ─── DocumentoSimple ───────────────────────────────────────────────────

class DocumentoSimple {
  final int id;
  final String nDocumento;
  final String tipoDocumento;
  final String? asuntoDetalle;

  const DocumentoSimple({
    required this.id,
    required this.nDocumento,
    required this.tipoDocumento,
    this.asuntoDetalle,
  });

  factory DocumentoSimple.fromJson(Map<String, dynamic> json) {
    return DocumentoSimple(
      id: json['id'] as int,
      nDocumento: json['n_documento'] as String? ?? '',
      tipoDocumento: json['tipo_documento'] as String? ?? '',
      asuntoDetalle: json['asunto_detalle'] as String?,
    );
  }
}

// ─── UsuarioPermitido ──────────────────────────────────────────────────

class UsuarioPermitido {
  final int id;
  final String username;
  final String nombre;

  const UsuarioPermitido({
    required this.id,
    required this.username,
    required this.nombre,
  });

  factory UsuarioPermitido.fromJson(Map<String, dynamic> json) {
    return UsuarioPermitido(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
    );
  }
}

// ─── Carpeta ───────────────────────────────────────────────────────────

class Carpeta {
  final int id;
  final String nombre;
  final TipoCarpeta? tipo;
  final int? parent;
  final int? caso;
  final CasoSimple? casoInfo;
  final int? documento;
  final DocumentoSimple? documentoInfo;
  final int archivosCount;
  final int subcarpetasCount;
  final int totalSize;
  final String totalSizeDisplay;
  final String rutaCompleta;
  final bool esRaiz;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final String? createdByName;
  final bool isDeleted;
  final DateTime? deletedAt;
  final int? deletedBy;
  final String? deletedByName;
  final Visibilidad visibilidad;
  final List<UsuarioPermitido> usuariosPermitidosInfo;
  final bool puedeEditarPermisos;

  const Carpeta({
    required this.id,
    required this.nombre,
    this.tipo,
    this.parent,
    this.caso,
    this.casoInfo,
    this.documento,
    this.documentoInfo,
    this.archivosCount = 0,
    this.subcarpetasCount = 0,
    this.totalSize = 0,
    this.totalSizeDisplay = '0 B',
    this.rutaCompleta = '',
    this.esRaiz = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdByName,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.deletedByName,
    this.visibilidad = Visibilidad.todos,
    this.usuariosPermitidosInfo = const [],
    this.puedeEditarPermisos = false,
  });

  factory Carpeta.fromJson(Map<String, dynamic> json) {
    return Carpeta(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      tipo: parseTipoCarpeta(json['tipo'] as String?),
      parent: json['parent'] as int?,
      caso: json['caso'] as int?,
      casoInfo: json['caso_info'] != null
          ? CasoSimple.fromJson(json['caso_info'] as Map<String, dynamic>)
          : null,
      documento: json['documento'] as int?,
      documentoInfo: json['documento_info'] != null
          ? DocumentoSimple.fromJson(
              json['documento_info'] as Map<String, dynamic>)
          : null,
      archivosCount: json['archivos_count'] as int? ?? 0,
      subcarpetasCount: json['subcarpetas_count'] as int? ?? 0,
      totalSize: json['total_size'] as int? ?? 0,
      totalSizeDisplay: json['total_size_display'] as String? ?? '0 B',
      rutaCompleta: json['ruta_completa'] as String? ?? '',
      esRaiz: json['es_raiz'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by'] as int?,
      createdByName: json['created_by_name'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deletedBy: json['deleted_by'] as int?,
      deletedByName: json['deleted_by_name'] as String?,
      visibilidad: parseVisibilidad(json['visibilidad'] as String?),
      usuariosPermitidosInfo: (json['usuarios_permitidos_info'] as List?)
              ?.map((e) =>
                  UsuarioPermitido.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      puedeEditarPermisos: json['puede_editar_permisos'] as bool? ?? false,
    );
  }
}

// ─── Archivo ───────────────────────────────────────────────────────────

class Archivo {
  final int id;
  final int carpeta;
  final int? documento;
  final String nombre;
  final String archivo;
  final String? archivoUrl;
  final String mimeType;
  final int size;
  final String sizeDisplay;
  final DocumentoSimple? documentoInfo;
  final bool esImagen;
  final bool esPdf;
  final String extension;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final String? createdByName;
  final bool isDeleted;
  final DateTime? deletedAt;
  final int? deletedBy;
  final String? deletedByName;
  final bool isTemporary;

  const Archivo({
    required this.id,
    required this.carpeta,
    this.documento,
    required this.nombre,
    this.archivo = '',
    this.archivoUrl,
    this.mimeType = 'application/octet-stream',
    this.size = 0,
    this.sizeDisplay = '0 B',
    this.documentoInfo,
    this.esImagen = false,
    this.esPdf = false,
    this.extension = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdByName,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.deletedByName,
    this.isTemporary = false,
  });

  factory Archivo.fromJson(Map<String, dynamic> json) {
    return Archivo(
      id: json['id'] as int,
      carpeta: json['carpeta'] as int? ?? 0,
      documento: json['documento'] as int?,
      nombre: json['nombre'] as String? ?? '',
      archivo: json['archivo'] as String? ?? '',
      archivoUrl: json['archivo_url'] as String?,
      mimeType:
          json['mime_type'] as String? ?? 'application/octet-stream',
      size: json['size'] as int? ?? 0,
      sizeDisplay: json['size_display'] as String? ?? '0 B',
      documentoInfo: json['documento_info'] != null
          ? DocumentoSimple.fromJson(
              json['documento_info'] as Map<String, dynamic>)
          : null,
      esImagen: json['es_imagen'] as bool? ?? false,
      esPdf: json['es_pdf'] as bool? ?? false,
      extension: json['extension'] as String? ?? '',
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by'] as int?,
      createdByName: json['created_by_name'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deletedBy: json['deleted_by'] as int?,
      deletedByName: json['deleted_by_name'] as String?,
    );
  }

  /// Constructor para archivos temporales (optimistic update)
  factory Archivo.temporary(String nombre, int carpetaId) {
    final now = DateTime.now();
    return Archivo(
      id: -now.millisecondsSinceEpoch,
      carpeta: carpetaId,
      nombre: nombre,
      createdAt: now,
      updatedAt: now,
      isTemporary: true,
    );
  }
}

// ─── Responses ─────────────────────────────────────────────────────────

class CarpetaContenidoResponse {
  final Carpeta carpetaPrincipal;
  final CasoSimple? caso;
  final List<Carpeta> subcarpetas;
  final List<Archivo> archivos;
  final int totalCarpetas;
  final int totalArchivos;

  const CarpetaContenidoResponse({
    required this.carpetaPrincipal,
    this.caso,
    required this.subcarpetas,
    required this.archivos,
    required this.totalCarpetas,
    required this.totalArchivos,
  });

  factory CarpetaContenidoResponse.fromJson(Map<String, dynamic> json) {
    return CarpetaContenidoResponse(
      carpetaPrincipal: Carpeta.fromJson(
          json['carpeta_principal'] as Map<String, dynamic>),
      caso: json['caso'] != null
          ? CasoSimple.fromJson(json['caso'] as Map<String, dynamic>)
          : null,
      subcarpetas: (json['subcarpetas'] as List)
          .map((e) => Carpeta.fromJson(e as Map<String, dynamic>))
          .toList(),
      archivos: (json['archivos'] as List)
          .map((e) => Archivo.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCarpetas: json['total_carpetas'] as int? ?? 0,
      totalArchivos: json['total_archivos'] as int? ?? 0,
    );
  }
}

class UploadMultipleResponse {
  final List<Archivo> creados;
  final List<UploadError> errores;
  final int totalCreados;
  final int totalErrores;

  const UploadMultipleResponse({
    required this.creados,
    required this.errores,
    required this.totalCreados,
    required this.totalErrores,
  });

  factory UploadMultipleResponse.fromJson(Map<String, dynamic> json) {
    return UploadMultipleResponse(
      creados: (json['creados'] as List)
          .map((e) => Archivo.fromJson(e as Map<String, dynamic>))
          .toList(),
      errores: (json['errores'] as List)
          .map((e) => UploadError.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCreados: json['total_creados'] as int? ?? 0,
      totalErrores: json['total_errores'] as int? ?? 0,
    );
  }
}

class UploadError {
  final String archivo;
  final String error;

  const UploadError({required this.archivo, required this.error});

  factory UploadError.fromJson(Map<String, dynamic> json) {
    return UploadError(
      archivo: json['archivo'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

// ─── WebSocket Models ──────────────────────────────────────────────────

class UsuarioConectado {
  final int userId;
  final String username;
  final String nombre;
  final int? carpetaId;
  final String? carpetaNombre;
  final List<SeleccionItem> seleccion;

  const UsuarioConectado({
    required this.userId,
    required this.username,
    required this.nombre,
    this.carpetaId,
    this.carpetaNombre,
    this.seleccion = const [],
  });

  factory UsuarioConectado.fromJson(Map<String, dynamic> json) {
    return UsuarioConectado(
      userId: json['user_id'] as int,
      username: json['username'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      carpetaId: json['carpeta_id'] as int?,
      carpetaNombre: json['carpeta_nombre'] as String?,
      seleccion: (json['seleccion'] as List?)
              ?.map((e) =>
                  SeleccionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SeleccionItem {
  final int id;
  final String tipo; // 'archivo' | 'carpeta'

  const SeleccionItem({required this.id, required this.tipo});

  factory SeleccionItem.fromJson(Map<String, dynamic> json) {
    return SeleccionItem(
      id: json['id'] as int,
      tipo: json['tipo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'tipo': tipo};
}

// ─── Historial ─────────────────────────────────────────────────────────

class HistorialEntry {
  final int? id;
  final String fecha;
  final String tipo;
  final String objeto;
  final String nombre;
  final String usuario;
  final bool isDeleted;

  const HistorialEntry({
    this.id,
    required this.fecha,
    required this.tipo,
    required this.objeto,
    required this.nombre,
    required this.usuario,
    this.isDeleted = false,
  });

  factory HistorialEntry.fromJson(Map<String, dynamic> json) {
    return HistorialEntry(
      id: json['id'] as int?,
      fecha: json['fecha'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      objeto: json['objeto'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      usuario: json['usuario'] as String? ?? '',
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }
}

// ─── Rubro (agrupación de carpetas) ────────────────────────────────────

class RubroGroup {
  final String nombre;
  final int count;
  final List<Carpeta> carpetas;

  const RubroGroup({
    required this.nombre,
    required this.count,
    required this.carpetas,
  });
}
