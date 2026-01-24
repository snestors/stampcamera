class DetalleRegistroModel {
  final String vin;
  final String? serie;
  final String? color;
  final String? factura;
  final String? bl;
  final String? naveDescarga;
  final String? puertoDescarga;
  final String? fechaAtraque;
  final String? destinatario;
  final String? agenteAduanal;
  final String? nombreEmbarque;
  final String? nViaje;
  final int? cantidadEmbarque;
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
    this.puertoDescarga,
    this.fechaAtraque,
    this.destinatario,
    this.agenteAduanal,
    this.nombreEmbarque,
    this.nViaje,
    this.cantidadEmbarque,
    this.informacionUnidad,
    required this.registrosVin,
    required this.fotosPresentacion,
    required this.danos,
  });

  factory DetalleRegistroModel.fromJson(Map<String, dynamic> json) {
    return DetalleRegistroModel(
      vin: json['vin'] ?? '',
      serie: json['serie'],
      color: json['color'],
      factura: json['factura'],
      bl: json['bl'],
      naveDescarga: json['nave_descarga'],
      puertoDescarga: json['puerto_descarga'],
      fechaAtraque: json['fecha_atraque'],
      destinatario: json['destinatario'],
      agenteAduanal: json['agente_aduanal'],
      nombreEmbarque: json['nombre_embarque'],
      nViaje: json['n_viaje'],
      cantidadEmbarque: json['cantidad_embarque'],
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
  final int? id;
  final String modelo;
  final String? version;
  final String? tipo;
  final Marca marca;
  final bool inventario;

  InformacionUnidad({
    this.id,
    required this.modelo,
    this.version,
    this.tipo,
    required this.marca,
    required this.inventario,
  });

  factory InformacionUnidad.fromJson(Map<String, dynamic> json) {
    return InformacionUnidad(
      id: json['id'],
      modelo: json['modelo'] ?? '',
      version: json['version'],
      tipo: json['tipo'],
      marca: Marca.fromJson(json['marca']),
      inventario: json['inventario'] ?? false,
    );
  }
}

class Marca {
  final int? id;
  final String marca;
  final String? abrev;

  Marca({this.id, required this.marca, this.abrev});

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      id: json['id'],
      marca: json['marca'] ?? '',
      abrev: json['abrev'],
    );
  }
}

// ✅ CORREGIDO: RegistroVin con manejo seguro de nulls
class RegistroVin {
  final int id;
  final String vin;
  final String condicion;
  final IdValuePair? zonaInspeccion;
  final IdValuePair? bloque;
  final IdValuePair? contenedor;
  final int? fila;
  final int? posicion;
  final String? fotoVinUrl;
  final String? fotoVinThumbnailUrl;
  final String? fecha;
  final String? createBy;

  RegistroVin({
    required this.id,
    required this.vin,
    required this.condicion,
    this.zonaInspeccion,
    this.bloque,
    this.contenedor,
    this.fila,
    this.posicion,
    this.fotoVinUrl,
    this.fotoVinThumbnailUrl,
    this.fecha,
    this.createBy,
  });

  factory RegistroVin.fromJson(Map<String, dynamic> json) {
    return RegistroVin(
      // ✅ FIX: Validar que id no sea null
      id:
          json['id'] ??
          (throw ArgumentError('RegistroVin id no puede ser null: $json')),
      vin: json['vin'] ?? '',
      condicion: json['condicion'] ?? '',

      // ✅ FIX: Verificar que el objeto no sea null Y que sea un Map antes de parsearlo
      zonaInspeccion:
          json['zona_inspeccion'] != null && json['zona_inspeccion'] is Map
          ? IdValuePair.fromJson(json['zona_inspeccion'])
          : null,
      bloque: json['bloque'] != null && json['bloque'] is Map
          ? IdValuePair.fromJson(json['bloque'])
          : null,
      contenedor: json['contenedor'] != null && json['contenedor'] is Map
          ? IdValuePair.fromJson(json['contenedor'])
          : null,

      fila: json['fila'],
      posicion: json['posicion'],
      fotoVinUrl: json['foto_vin_url'],
      fotoVinThumbnailUrl: json['foto_vin_thumbnail_url'],
      fecha: json['fecha'],
      createBy: json['create_by'],
    );
  }
}

// ✅ ACTUALIZADO: FotoPresentacion con condicion formato {id, value}
class FotoPresentacion {
  final int id;
  final String tipo;
  final String? nDocumento;
  final IdValuePair? condicion;
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
      tipo: json['tipo'] ?? '',
      nDocumento: json['n_documento'],
      condicion: json['condicion'] != null && json['condicion'] is Map
          ? IdValuePair.fromJson(json['condicion'])
          : null,
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
      createBy: json['create_by'],
    );
  }
}

// ✅ ACTUALIZADO: Dano con condicion formato {id, value}
class Dano {
  final int id;
  final String? descripcion;
  final IdValuePair? condicion;
  final TipoDano tipoDano;
  final AreaDano areaDano;
  final Severidad severidad;
  final FotoPresentacion? nDocumento;
  final List<ZonaDano> zonas;
  final List<DanoImagen> imagenes;
  final Responsabilidad? responsabilidad;
  final String? createAt;
  final String? createBy;
  final bool relevante;
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
    required this.relevante,
    required this.verificadoBool,
    this.verificado,
  });

  factory Dano.fromJson(Map<String, dynamic> json) {
    return Dano(
      id: json['id'],
      descripcion: json['descripcion'],
      condicion: json['condicion'] != null && json['condicion'] is Map
          ? IdValuePair.fromJson(json['condicion'])
          : null,
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
      relevante: json['relevante'] ?? false,
      verificadoBool: json['verificado_bool'] ?? false,
      verificado: json['verificado'],
    );
  }
}

// ✅ MEJORADO: IdValuePair con manejo de errores más robusto
class IdValuePair {
  final int id;
  final String value;

  IdValuePair({required this.id, required this.value});

  factory IdValuePair.fromJson(Map<String, dynamic> json) {
    return IdValuePair(id: json['id'], value: json['value']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'value': value};
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdValuePair && other.id == id && other.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}

class TipoDano {
  final int id;
  final String esp;

  TipoDano({required this.id, required this.esp});

  factory TipoDano.fromJson(Map<String, dynamic> json) {
    return TipoDano(id: json['id'], esp: json['esp'] ?? '');
  }
}

class AreaDano {
  final int id;
  final String esp;

  AreaDano({required this.id, required this.esp});

  factory AreaDano.fromJson(Map<String, dynamic> json) {
    return AreaDano(id: json['id'], esp: json['esp'] ?? '');
  }
}

class Severidad {
  final int id;
  final String esp;

  Severidad({required this.id, required this.esp});

  factory Severidad.fromJson(Map<String, dynamic> json) {
    return Severidad(id: json['id'], esp: json['esp'] ?? '');
  }
}

class DanoImagen {
  final int id;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;
  final String? createBy;

  DanoImagen({
    required this.id,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
    this.createBy,
  });

  factory DanoImagen.fromJson(Map<String, dynamic> json) {
    return DanoImagen(
      id: json['id'],
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
      createBy: json['create_by'],
    );
  }
}

class Responsabilidad {
  final int id;
  final String esp;
  final String? eng;

  Responsabilidad({required this.id, required this.esp, this.eng});

  factory Responsabilidad.fromJson(Map<String, dynamic> json) {
    return Responsabilidad(
      id: json['id'],
      esp: json['esp'] ?? '',
      eng: json['eng'],
    );
  }
}

class ZonaDano {
  final int id;
  final String zona;

  ZonaDano({required this.id, required this.zona});

  factory ZonaDano.fromJson(Map<String, dynamic> json) {
    return ZonaDano(id: json['id'], zona: json['zona'] ?? '');
  }
}
