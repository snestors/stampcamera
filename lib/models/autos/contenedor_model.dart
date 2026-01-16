// models/autos/contenedor_model.dart
class ContenedorModel {
  final int id;
  final String nContenedor;
  final NaveDescargaModel naveDescarga; // ✅ CAMBIO: Ahora es un objeto
  final ZonaInspeccionModel? zonaInspeccion;
  final String? precinto1;
  final String? precinto2;
  final String? fotoContenedor;
  final String? fotoContenedorUrl;
  final String? imagenThumbnailUrl;
  final String? fotoPrecinto1;
  final String? fotoPrecinto1Url;
  final String? imagenThumbnailPrecintoUrl;
  final String? fotoPrecinto2;
  final String? fotoPrecinto2Url;
  final String? imagenThumbnailPrecinto2Url;
  final String? fotoContenedorVacio;
  final String? fotoContenedorVacioUrl;
  final String? imagenThumbnailContenedorVacioUrl;
  final String createAt;
  final String createBy;
  final List<dynamic> fotos;

  ContenedorModel({
    required this.id,
    required this.nContenedor,
    required this.naveDescarga,
    this.zonaInspeccion,
    this.precinto1,
    this.precinto2,
    this.fotoContenedor,
    this.fotoContenedorUrl,
    this.imagenThumbnailUrl,
    this.fotoPrecinto1,
    this.fotoPrecinto1Url,
    this.imagenThumbnailPrecintoUrl,
    this.fotoPrecinto2,
    this.fotoPrecinto2Url,
    this.imagenThumbnailPrecinto2Url,
    this.fotoContenedorVacio,
    this.fotoContenedorVacioUrl,
    this.imagenThumbnailContenedorVacioUrl,
    required this.createAt,
    required this.createBy,
    this.fotos = const [],
  });

  factory ContenedorModel.fromJson(Map<String, dynamic> json) {
    return ContenedorModel(
      id: json['id'] ?? 0,
      nContenedor: json['n_contenedor'] ?? '',
      // ✅ CAMBIO: Parsear nave_descarga como objeto
      naveDescarga: NaveDescargaModel.fromJson(json['nave_descarga'] ?? {}),
      zonaInspeccion: json['zona_inspeccion'] != null
          ? ZonaInspeccionModel.fromJson(json['zona_inspeccion'])
          : null,
      precinto1: json['precinto1'],
      precinto2: json['precinto2'],
      fotoContenedor: json['foto_contenedor'],
      fotoContenedorUrl: json['foto_contenedor_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      fotoPrecinto1: json['foto_precinto1'],
      fotoPrecinto1Url: json['foto_precinto1_url'],
      imagenThumbnailPrecintoUrl: json['imagen_thumbnail_precinto_url'],
      fotoPrecinto2: json['foto_precinto2'],
      fotoPrecinto2Url: json['foto_precinto2_url'],
      imagenThumbnailPrecinto2Url: json['imagen_thumbnail_precinto2_url'],
      fotoContenedorVacio: json['foto_contenedor_vacio'],
      fotoContenedorVacioUrl: json['foto_contenedor_vacio_url'],
      imagenThumbnailContenedorVacioUrl:
          json['imagen_thumbnail_contenedor_vacio_url'],
      createAt: json['create_at'] ?? '',
      createBy: json['create_by'] ?? '',
      fotos: json['fotos'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'n_contenedor': nContenedor,
      // ✅ CAMBIO: Solo enviar el ID de la nave
      'nave_descarga_id': naveDescarga.id,
      'zona_inspeccion': zonaInspeccion?.toJson(),
      'precinto1': precinto1,
      'precinto2': precinto2,
      'create_at': createAt,
      'create_by': createBy,
    };
  }

  ContenedorModel copyWith({
    int? id,
    String? nContenedor,
    NaveDescargaModel? naveDescarga, // ✅ CAMBIO: Tipo actualizado
    ZonaInspeccionModel? zonaInspeccion,
    String? precinto1,
    String? precinto2,
    String? fotoContenedor,
    String? fotoContenedorUrl,
    String? imagenThumbnailUrl,
    String? fotoPrecinto1,
    String? fotoPrecinto1Url,
    String? imagenThumbnailPrecintoUrl,
    String? fotoPrecinto2,
    String? fotoPrecinto2Url,
    String? imagenThumbnailPrecinto2Url,
    String? fotoContenedorVacio,
    String? fotoContenedorVacioUrl,
    String? imagenThumbnailContenedorVacioUrl,
    String? createAt,
    String? createBy,
    List<dynamic>? fotos,
  }) {
    return ContenedorModel(
      id: id ?? this.id,
      nContenedor: nContenedor ?? this.nContenedor,
      naveDescarga: naveDescarga ?? this.naveDescarga,
      zonaInspeccion: zonaInspeccion ?? this.zonaInspeccion,
      precinto1: precinto1 ?? this.precinto1,
      precinto2: precinto2 ?? this.precinto2,
      fotoContenedor: fotoContenedor ?? this.fotoContenedor,
      fotoContenedorUrl: fotoContenedorUrl ?? this.fotoContenedorUrl,
      imagenThumbnailUrl: imagenThumbnailUrl ?? this.imagenThumbnailUrl,
      fotoPrecinto1: fotoPrecinto1 ?? this.fotoPrecinto1,
      fotoPrecinto1Url: fotoPrecinto1Url ?? this.fotoPrecinto1Url,
      imagenThumbnailPrecintoUrl:
          imagenThumbnailPrecintoUrl ?? this.imagenThumbnailPrecintoUrl,
      fotoPrecinto2: fotoPrecinto2 ?? this.fotoPrecinto2,
      fotoPrecinto2Url: fotoPrecinto2Url ?? this.fotoPrecinto2Url,
      imagenThumbnailPrecinto2Url:
          imagenThumbnailPrecinto2Url ?? this.imagenThumbnailPrecinto2Url,
      fotoContenedorVacio: fotoContenedorVacio ?? this.fotoContenedorVacio,
      fotoContenedorVacioUrl:
          fotoContenedorVacioUrl ?? this.fotoContenedorVacioUrl,
      imagenThumbnailContenedorVacioUrl:
          imagenThumbnailContenedorVacioUrl ??
          this.imagenThumbnailContenedorVacioUrl,
      createAt: createAt ?? this.createAt,
      createBy: createBy ?? this.createBy,
      fotos: fotos ?? this.fotos,
    );
  }

  // Métodos de utilidad
  bool get hasContenedorPhoto => fotoContenedorUrl?.isNotEmpty == true;
  bool get hasPrecinto1Photo => fotoPrecinto1Url?.isNotEmpty == true;
  bool get hasPrecinto2Photo => fotoPrecinto2Url?.isNotEmpty == true;
  bool get hasContenedorVacioPhoto =>
      fotoContenedorVacioUrl?.isNotEmpty == true;

  String? get displayContenedorImage => imagenThumbnailUrl ?? fotoContenedorUrl;
  String? get displayPrecinto1Image =>
      imagenThumbnailPrecintoUrl ?? fotoPrecinto1Url;
  String? get displayPrecinto2Image =>
      imagenThumbnailPrecinto2Url ?? fotoPrecinto2Url;
  String? get displayContenedorVacioImage =>
      imagenThumbnailContenedorVacioUrl ?? fotoContenedorVacioUrl;
}

// ✅ NUEVO: Modelo para nave de descarga
class NaveDescargaModel {
  final int id;
  final String naveDescarga;

  NaveDescargaModel({required this.id, required this.naveDescarga});

  factory NaveDescargaModel.fromJson(Map<String, dynamic> json) {
    return NaveDescargaModel(
      id: json['id'] ?? 0,
      naveDescarga: json['nave_descarga'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nave_descarga': naveDescarga};
  }

  // Getter para mostrar solo el nombre limpio
  String get displayName => naveDescarga;
}

// Modelo para zona de inspección
class ZonaInspeccionModel {
  final int id;
  final String value;

  ZonaInspeccionModel({required this.id, required this.value});

  factory ZonaInspeccionModel.fromJson(Map<String, dynamic> json) {
    return ZonaInspeccionModel(id: json['id'] ?? 0, value: json['value'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'value': value};
  }
}

// Modelo para opciones dinámicas
class ContenedorOptions {
  final List<NaveDisponible> navesDisponibles;
  final List<ZonaDisponible> zonasDisponibles;
  final Map<String, FieldPermission> fieldPermissions;
  final Map<String, dynamic> initialValues;

  ContenedorOptions({
    required this.navesDisponibles,
    required this.zonasDisponibles,
    required this.fieldPermissions,
    required this.initialValues,
  });

  factory ContenedorOptions.fromJson(Map<String, dynamic> json) {
    return ContenedorOptions(
      navesDisponibles:
          (json['naves_disponibles'] as List?)
              ?.map((e) => NaveDisponible.fromJson(e))
              .toList() ??
          [],
      zonasDisponibles:
          (json['zonas_disponibles'] as List?)
              ?.map((e) => ZonaDisponible.fromJson(e))
              .toList() ??
          [],
      fieldPermissions:
          (json['field_permissions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, FieldPermission.fromJson(v)),
          ) ??
          {},
      initialValues: json['initial_values'] ?? {},
    );
  }
}

class NaveDisponible {
  final int id;
  final String nombre;

  NaveDisponible({required this.id, required this.nombre});

  factory NaveDisponible.fromJson(Map<String, dynamic> json) {
    return NaveDisponible(id: json['id'] ?? 0, nombre: json['nombre'] ?? '');
  }
}

class ZonaDisponible {
  final int id;
  final String nombre;

  ZonaDisponible({required this.id, required this.nombre});

  factory ZonaDisponible.fromJson(Map<String, dynamic> json) {
    return ZonaDisponible(id: json['id'] ?? 0, nombre: json['nombre'] ?? '');
  }
}

class FieldPermission {
  final bool editable;
  final bool required;

  FieldPermission({required this.editable, required this.required});

  factory FieldPermission.fromJson(Map<String, dynamic> json) {
    return FieldPermission(
      editable: json['editable'] ?? true,
      required: json['required'] ?? false,
    );
  }
}
