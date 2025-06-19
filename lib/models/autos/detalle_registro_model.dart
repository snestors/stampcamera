class DetalleRegistroModel {
  final String vin;
  final String? serie;
  final String? color;
  final String? factura;
  final String? bl;
  final String? naveDescarga;
  final InformacionUnidad? informacionUnidad;
  final List<RegistroVin> registrosVin;
  final List<FotoPresentacion> fotosPresentacion;
  final List<Dano> danos;

  DetalleRegistroModel({
    required this.vin,
    this.serie,
    this.color,
    this.factura,
    this.bl,
    this.naveDescarga,
    this.informacionUnidad,
    required this.registrosVin,
    required this.fotosPresentacion,
    required this.danos,
  });

  factory DetalleRegistroModel.fromJson(Map<String, dynamic> json) {
    return DetalleRegistroModel(
      vin: json['vin'],
      serie: json['serie'],
      color: json['color'],
      factura: json['factura'],
      bl: json['bl'],
      naveDescarga: json['nave_descarga'],
      informacionUnidad: json['informacion_unidad'] != null
          ? InformacionUnidad.fromJson(json['informacion_unidad'])
          : null,
      registrosVin:
          (json['registros_vin'] as List<dynamic>?)
              ?.map((e) => RegistroVin.fromJson(e))
              .toList() ??
          [],
      fotosPresentacion:
          (json['fotos_presentacion'] as List<dynamic>?)
              ?.map((e) => FotoPresentacion.fromJson(e))
              .toList() ??
          [],
      danos:
          (json['danos'] as List<dynamic>?)
              ?.map((e) => Dano.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class InformacionUnidad {
  final String modelo;
  final String? version;
  final String? tipo;
  final Marca marca;

  InformacionUnidad({
    required this.modelo,
    this.version,
    this.tipo,
    required this.marca,
  });

  factory InformacionUnidad.fromJson(Map<String, dynamic> json) {
    return InformacionUnidad(
      modelo: json['modelo'],
      version: json['version'],
      tipo: json['tipo'],
      marca: Marca.fromJson(json['marca']),
    );
  }
}

class Marca {
  final String marca;
  final String? abrev;

  Marca({required this.marca, this.abrev});

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(marca: json['marca'], abrev: json['abrev']);
  }
}

class RegistroVin {
  final String vin;
  final String condicion;
  final String? zonaInspeccion;
  final String? bloque;
  final String? fotoVinUrl;
  final String? fotoVinThumbnailUrl;
  final String? fecha;
  final String? createBy;

  RegistroVin({
    required this.vin,
    required this.condicion,
    this.zonaInspeccion,
    this.bloque,
    this.fotoVinUrl,
    this.fotoVinThumbnailUrl,
    this.fecha,
    this.createBy,
  });

  factory RegistroVin.fromJson(Map<String, dynamic> json) {
    return RegistroVin(
      vin: json['vin'],
      condicion: json['condicion'],
      zonaInspeccion: json['zona_inspeccion'],
      bloque: json['bloque'],
      fotoVinUrl: json['foto_vin_url'],
      fotoVinThumbnailUrl: json['foto_vin_thumbnail_url'],
      fecha: json['fecha'],
      createBy: json['create_by'],
    );
  }
}

class FotoPresentacion {
  final int id;
  final String tipo;
  final String? nDocumento;
  final String? condicion;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;
  final String? createBy;

  FotoPresentacion({
    required this.id,
    required this.tipo,
    this.nDocumento,
    this.condicion,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
    this.createBy,
  });

  factory FotoPresentacion.fromJson(Map<String, dynamic> json) {
    return FotoPresentacion(
      id: json['id'],
      tipo: json['tipo'],
      nDocumento: json['n_documento'],
      condicion: json['condicion'],
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
      createBy: json['create_by'],
    );
  }
}

class Dano {
  final int id;
  final String? descripcion;
  final String? condicion;
  final TipoDano tipoDano;
  final AreaDano areaDano;
  final Severidad severidad;
  final FotoPresentacion? nDocumento;
  final List<ZonaDano> zonas;
  final List<DanoImagen> imagenes;
  final Responsabilidad? responsabilidad;
  final String? createAt;
  final String? createBy;
  final bool verificadoBool;
  final int? verificado;

  Dano({
    required this.id,
    this.descripcion,
    this.condicion,
    required this.tipoDano,
    required this.areaDano,
    required this.severidad,
    this.nDocumento,
    required this.zonas,
    required this.imagenes,
    this.responsabilidad,
    this.createAt,
    this.createBy,
    required this.verificadoBool,
    this.verificado,
  });

  factory Dano.fromJson(Map<String, dynamic> json) {
    return Dano(
      id: json['id'],
      descripcion: json['descripcion'],
      condicion: json['condicion'],
      tipoDano: TipoDano.fromJson(json['tipo_dano']),
      areaDano: AreaDano.fromJson(json['area_dano']),
      severidad: Severidad.fromJson(json['severidad']),
      nDocumento: json['n_documento'] != null
          ? FotoPresentacion.fromJson(json['n_documento'])
          : null,
      imagenes:
          (json['imagenes'] as List<dynamic>?)
              ?.map((e) => DanoImagen.fromJson(e))
              .toList() ??
          [],
      responsabilidad: json['responsabilidad'] != null
          ? Responsabilidad.fromJson(json['responsabilidad'])
          : null,
      zonas: (json['zonas'] as List<dynamic>? ?? [])
          .map((e) => ZonaDano.fromJson(e))
          .toList(),
      createAt: json['create_at'],
      createBy: json['create_by'],
      verificadoBool: json['verificado_bool'] ?? false,
      verificado: json['verificado'],
    );
  }
}

class TipoDano {
  final String esp;

  TipoDano({required this.esp});

  factory TipoDano.fromJson(Map<String, dynamic> json) {
    return TipoDano(esp: json['esp']);
  }
}

class AreaDano {
  final String esp;

  AreaDano({required this.esp});

  factory AreaDano.fromJson(Map<String, dynamic> json) {
    return AreaDano(esp: json['esp']);
  }
}

class Severidad {
  final String esp;

  Severidad({required this.esp});

  factory Severidad.fromJson(Map<String, dynamic> json) {
    return Severidad(esp: json['esp']);
  }
}

class DanoImagen {
  final int id;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;

  DanoImagen({
    required this.id,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
  });

  factory DanoImagen.fromJson(Map<String, dynamic> json) {
    return DanoImagen(
      id: json['id'],
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
    );
  }
}

class Responsabilidad {
  final int id;
  final String esp;
  final String? eng;

  Responsabilidad({required this.id, required this.esp, this.eng});

  factory Responsabilidad.fromJson(Map<String, dynamic> json) {
    return Responsabilidad(id: json['id'], esp: json['esp'], eng: json['eng']);
  }
}

class ZonaDano {
  final int id;
  final String zona;

  ZonaDano({required this.id, required this.zona});

  factory ZonaDano.fromJson(Map<String, dynamic> json) {
    return ZonaDano(id: json['id'], zona: json['zona']);
  }
}
