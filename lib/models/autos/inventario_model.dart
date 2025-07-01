// models/autos/inventario_base_model.dart

/// Modelo para la respuesta del API de inventario base (DETALLE)
class InventarioBaseResponse {
  final InformacionUnidad informacionUnidad;
  final List<InventarioImagen> imagenes;
  final InventarioBase? inventario;

  const InventarioBaseResponse({
    required this.informacionUnidad,
    required this.imagenes,
    this.inventario,
  });

  factory InventarioBaseResponse.fromJson(Map<String, dynamic> json) {
    return InventarioBaseResponse(
      informacionUnidad: InformacionUnidad.fromJson(
        json['informacion_unidad'] ?? {},
      ),
      imagenes:
          (json['imagenes'] as List?)
              ?.map((x) => InventarioImagen.fromJson(x))
              .toList() ??
          [],
      inventario: json['inventario'] != null
          ? InventarioBase.fromJson(json['inventario'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'informacion_unidad': informacionUnidad.toJson(),
      'imagenes': imagenes.map((x) => x.toJson()).toList(),
      'inventario': inventario?.toJson(),
    };
  }

  bool get hasInventario => inventario != null;
  bool get hasImages => imagenes.isNotEmpty;
  int get imageCount => imagenes.length;
}

/// Modelo para la lista de inventarios (LISTA)
class InventarioListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<InventarioNave> results;

  const InventarioListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory InventarioListResponse.fromJson(Map<String, dynamic> json) {
    return InventarioListResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
          (json['results'] as List?)
              ?.map((x) => InventarioNave.fromJson(x))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((x) => x.toJson()).toList(),
    };
  }
}

/// Modelo para nave en la lista de inventarios
class InventarioNave {
  final int naveDescargaId;
  final String naveDescargaNombre;
  final String naveDescargaPuerto;
  final String naveDescargaRubro;
  final String naveDescargaFechaAtraque;
  final List<InventarioModelo> modelos;

  const InventarioNave({
    required this.naveDescargaId,
    required this.naveDescargaNombre,
    required this.naveDescargaPuerto,
    required this.naveDescargaRubro,
    required this.naveDescargaFechaAtraque,
    required this.modelos,
  });

  factory InventarioNave.fromJson(Map<String, dynamic> json) {
    return InventarioNave(
      naveDescargaId: json['nave_descarga_id'] ?? 0,
      naveDescargaNombre: json['nave_descarga_nombre'] ?? '',
      naveDescargaPuerto: json['nave_descarga_puerto'] ?? '',
      naveDescargaRubro: json['nave_descarga_rubro'] ?? '',
      naveDescargaFechaAtraque: json['nave_descarga_fecha_atraque'] ?? '',
      modelos:
          (json['modelos'] as List?)
              ?.map((x) => InventarioModelo.fromJson(x))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nave_descarga_id': naveDescargaId,
      'nave_descarga_nombre': naveDescargaNombre,
      'nave_descarga_puerto': naveDescargaPuerto,
      'nave_descarga_rubro': naveDescargaRubro,
      'nave_descarga_fecha_atraque': naveDescargaFechaAtraque,
      'modelos': modelos.map((x) => x.toJson()).toList(),
    };
  }

  // Getters calculados
  bool get isFPR => naveDescargaRubro.toUpperCase().contains('FPR');
  bool get isSIC => naveDescargaRubro.toUpperCase().contains('SIC');

  int get totalUnidades {
    return modelos.fold(0, (sum, modelo) => sum + modelo.cantidadUnidades);
  }

  int get totalDescargadoPuerto {
    return modelos.fold(0, (sum, modelo) => sum + modelo.descargadoPuerto);
  }

  int get totalDescargadoAlmacen {
    return modelos.fold(0, (sum, modelo) => sum + modelo.descargadoAlmacen);
  }

  int get totalDescargadoRecepcion {
    return modelos.fold(0, (sum, modelo) => sum + modelo.descargadoRecepcion);
  }

  int get totalDescargadas {
    return isFPR ? totalDescargadoPuerto : totalDescargadoAlmacen;
  }
}

/// Modelo para modelo de vehículo en inventario
class InventarioModelo {
  final String marca;
  final String modelo;
  final int cantidadUnidades;
  final int descargadoPuerto;
  final int descargadoAlmacen;
  final int descargadoRecepcion;
  final String agente;
  final List<InventarioVersion> versiones;

  const InventarioModelo({
    required this.marca,
    required this.modelo,
    required this.cantidadUnidades,
    required this.descargadoPuerto,
    required this.descargadoAlmacen,
    required this.descargadoRecepcion,
    required this.agente,
    required this.versiones,
  });

  factory InventarioModelo.fromJson(Map<String, dynamic> json) {
    return InventarioModelo(
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      cantidadUnidades: json['cantidad_unidades'] ?? 0,
      descargadoPuerto: json['descargado_puerto'] ?? 0,
      descargadoAlmacen: json['descargado_almacen'] ?? 0,
      descargadoRecepcion: json['descargado_recepcion'] ?? 0,
      agente: json['agente'] ?? '',
      versiones:
          (json['versiones'] as List?)
              ?.map((x) => InventarioVersion.fromJson(x))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marca': marca,
      'modelo': modelo,
      'cantidad_unidades': cantidadUnidades,
      'descargado_puerto': descargadoPuerto,
      'descargado_almacen': descargadoAlmacen,
      'descargado_recepcion': descargadoRecepcion,
      'agente': agente,
      'versiones': versiones.map((x) => x.toJson()).toList(),
    };
  }

  int get versionesConInventario {
    return versiones.where((v) => v.inventario).length;
  }
}

/// Modelo para versión de vehículo en inventario
class InventarioVersion {
  final int informacionUnidadId;
  final String version;
  final int cantidadUnidades;
  final bool inventario;

  const InventarioVersion({
    required this.informacionUnidadId,
    required this.version,
    required this.cantidadUnidades,
    required this.inventario,
  });

  factory InventarioVersion.fromJson(Map<String, dynamic> json) {
    return InventarioVersion(
      informacionUnidadId: json['informacion_unidad_id'] ?? 0,
      version: json['version'] ?? '',
      cantidadUnidades: json['cantidad_unidades'] ?? 0,
      inventario: json['inventario'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'informacion_unidad_id': informacionUnidadId,
      'version': version,
      'cantidad_unidades': cantidadUnidades,
      'inventario': inventario,
    };
  }
}

/// Modelo para inventario base (sin cambios - está correcto)
class InventarioBase {
  final int? id;
  final int llaveSimple;
  final int llaveComando;
  final int llaveInteligente;
  final int encendedor;
  final int cenicero;
  final int cableUsbOAux;
  final int retrovisor;
  final int pisos;
  final int logos;
  final int estucheManual;
  final int manualesEstuche;
  final int pinDeRemolque;
  final int tapaPinDeRemolque;
  final int portaplaca;
  final int copasTapasDeAros;
  final int taponesChasis;
  final int cobertor;
  final int botiquin;
  final int pernoSeguroRueda;
  final int ambientadores;
  final int estucheHerramienta;
  final int desarmador;
  final int llaveBocaCombinada;
  final int alicate;
  final int llaveDeRueda;
  final int palancaDeGata;
  final int gata;
  final int llantaDeRepuesto;
  final int trianguloDeEmergencia;
  final int malla;
  final int antena;
  final int extra;
  final int cableCargador;
  final int cajaDeFusibles;
  final int extintor;
  final int chalecoReflectivo;
  final int conos;
  final int extension;
  final String otros;

  const InventarioBase({
    this.id,
    required this.llaveSimple,
    required this.llaveComando,
    required this.llaveInteligente,
    required this.encendedor,
    required this.cenicero,
    required this.cableUsbOAux,
    required this.retrovisor,
    required this.pisos,
    required this.logos,
    required this.estucheManual,
    required this.manualesEstuche,
    required this.pinDeRemolque,
    required this.tapaPinDeRemolque,
    required this.portaplaca,
    required this.copasTapasDeAros,
    required this.taponesChasis,
    required this.cobertor,
    required this.botiquin,
    required this.pernoSeguroRueda,
    required this.ambientadores,
    required this.estucheHerramienta,
    required this.desarmador,
    required this.llaveBocaCombinada,
    required this.alicate,
    required this.llaveDeRueda,
    required this.palancaDeGata,
    required this.gata,
    required this.llantaDeRepuesto,
    required this.trianguloDeEmergencia,
    required this.malla,
    required this.antena,
    required this.extra,
    required this.cableCargador,
    required this.cajaDeFusibles,
    required this.extintor,
    required this.chalecoReflectivo,
    required this.conos,
    required this.extension,
    required this.otros,
  });

  factory InventarioBase.fromJson(Map<String, dynamic> json) {
    return InventarioBase(
      id: json['id'],
      llaveSimple: json['LLAVE_SIMPLE'] ?? 0,
      llaveComando: json['LLAVE_COMANDO'] ?? 0,
      llaveInteligente: json['LLAVE_INTELIGENTE'] ?? 0,
      encendedor: json['ENCENDEDOR'] ?? 0,
      cenicero: json['CENICERO'] ?? 0,
      cableUsbOAux: json['CABLE_USB_O_AUX'] ?? 0,
      retrovisor: json['RETROVISOR'] ?? 0,
      pisos: json['PISOS'] ?? 0,
      logos: json['LOGOS'] ?? 0,
      estucheManual: json['ESTUCHE_MANUAL'] ?? 0,
      manualesEstuche: json['MANUALES_ESTUCHE'] ?? 0,
      pinDeRemolque: json['PIN_DE_REMOLQUE'] ?? 0,
      tapaPinDeRemolque: json['TAPA_PIN_DE_REMOLQUE'] ?? 0,
      portaplaca: json['PORTAPLACA'] ?? 0,
      copasTapasDeAros: json['COPAS_TAPAS_DE_AROS'] ?? 0,
      taponesChasis: json['TAPONES_CHASIS'] ?? 0,
      cobertor: json['COBERTOR'] ?? 0,
      botiquin: json['BOTIQUIN'] ?? 0,
      pernoSeguroRueda: json['PERNO_SEGURO_RUEDA'] ?? 0,
      ambientadores: json['AMBIENTADORES'] ?? 0,
      estucheHerramienta: json['ESTUCHE_HERRAMIENTA'] ?? 0,
      desarmador: json['DESARMADOR'] ?? 0,
      llaveBocaCombinada: json['LLAVE_BOCA_COMBINADA'] ?? 0,
      alicate: json['ALICATE'] ?? 0,
      llaveDeRueda: json['LLAVE_DE_RUEDA'] ?? 0,
      palancaDeGata: json['PALANCA_DE_GATA'] ?? 0,
      gata: json['GATA'] ?? 0,
      llantaDeRepuesto: json['LLANTA_DE_REPUESTO'] ?? 0,
      trianguloDeEmergencia: json['TRIANGULO_DE_EMERGENCIA'] ?? 0,
      malla: json['MALLA'] ?? 0,
      antena: json['ANTENA'] ?? 0,
      extra: json['EXTRA'] ?? 0,
      cableCargador: json['CABLE_CARGADOR'] ?? 0,
      cajaDeFusibles: json['CAJA_DE_FUSIBLES'] ?? 0,
      extintor: json['EXTINTOR'] ?? 0,
      chalecoReflectivo: json['CHALECO_REFLECTIVO'] ?? 0,
      conos: json['CONOS'] ?? 0,
      extension: json['EXTENSION'] ?? 0,
      otros: json['OTROS'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'LLAVE_SIMPLE': llaveSimple,
      'LLAVE_COMANDO': llaveComando,
      'LLAVE_INTELIGENTE': llaveInteligente,
      'ENCENDEDOR': encendedor,
      'CENICERO': cenicero,
      'CABLE_USB_O_AUX': cableUsbOAux,
      'RETROVISOR': retrovisor,
      'PISOS': pisos,
      'LOGOS': logos,
      'ESTUCHE_MANUAL': estucheManual,
      'MANUALES_ESTUCHE': manualesEstuche,
      'PIN_DE_REMOLQUE': pinDeRemolque,
      'TAPA_PIN_DE_REMOLQUE': tapaPinDeRemolque,
      'PORTAPLACA': portaplaca,
      'COPAS_TAPAS_DE_AROS': copasTapasDeAros,
      'TAPONES_CHASIS': taponesChasis,
      'COBERTOR': cobertor,
      'BOTIQUIN': botiquin,
      'PERNO_SEGURO_RUEDA': pernoSeguroRueda,
      'AMBIENTADORES': ambientadores,
      'ESTUCHE_HERRAMIENTA': estucheHerramienta,
      'DESARMADOR': desarmador,
      'LLAVE_BOCA_COMBINADA': llaveBocaCombinada,
      'ALICATE': alicate,
      'LLAVE_DE_RUEDA': llaveDeRueda,
      'PALANCA_DE_GATA': palancaDeGata,
      'GATA': gata,
      'LLANTA_DE_REPUESTO': llantaDeRepuesto,
      'TRIANGULO_DE_EMERGENCIA': trianguloDeEmergencia,
      'MALLA': malla,
      'ANTENA': antena,
      'EXTRA': extra,
      'CABLE_CARGADOR': cableCargador,
      'CAJA_DE_FUSIBLES': cajaDeFusibles,
      'EXTINTOR': extintor,
      'CHALECO_REFLECTIVO': chalecoReflectivo,
      'CONOS': conos,
      'EXTENSION': extension,
      'OTROS': otros,
    };
  }

  InventarioBase copyWith({
    int? id,
    int? llaveSimple,
    int? llaveComando,
    int? llaveInteligente,
    int? encendedor,
    int? cenicero,
    int? cableUsbOAux,
    int? retrovisor,
    int? pisos,
    int? logos,
    int? estucheManual,
    int? manualesEstuche,
    int? pinDeRemolque,
    int? tapaPinDeRemolque,
    int? portaplaca,
    int? copasTapasDeAros,
    int? taponesChasis,
    int? cobertor,
    int? botiquin,
    int? pernoSeguroRueda,
    int? ambientadores,
    int? estucheHerramienta,
    int? desarmador,
    int? llaveBocaCombinada,
    int? alicate,
    int? llaveDeRueda,
    int? palancaDeGata,
    int? gata,
    int? llantaDeRepuesto,
    int? trianguloDeEmergencia,
    int? malla,
    int? antena,
    int? extra,
    int? cableCargador,
    int? cajaDeFusibles,
    int? extintor,
    int? chalecoReflectivo,
    int? conos,
    int? extension,
    String? otros,
  }) {
    return InventarioBase(
      id: id ?? this.id,
      llaveSimple: llaveSimple ?? this.llaveSimple,
      llaveComando: llaveComando ?? this.llaveComando,
      llaveInteligente: llaveInteligente ?? this.llaveInteligente,
      encendedor: encendedor ?? this.encendedor,
      cenicero: cenicero ?? this.cenicero,
      cableUsbOAux: cableUsbOAux ?? this.cableUsbOAux,
      retrovisor: retrovisor ?? this.retrovisor,
      pisos: pisos ?? this.pisos,
      logos: logos ?? this.logos,
      estucheManual: estucheManual ?? this.estucheManual,
      manualesEstuche: manualesEstuche ?? this.manualesEstuche,
      pinDeRemolque: pinDeRemolque ?? this.pinDeRemolque,
      tapaPinDeRemolque: tapaPinDeRemolque ?? this.tapaPinDeRemolque,
      portaplaca: portaplaca ?? this.portaplaca,
      copasTapasDeAros: copasTapasDeAros ?? this.copasTapasDeAros,
      taponesChasis: taponesChasis ?? this.taponesChasis,
      cobertor: cobertor ?? this.cobertor,
      botiquin: botiquin ?? this.botiquin,
      pernoSeguroRueda: pernoSeguroRueda ?? this.pernoSeguroRueda,
      ambientadores: ambientadores ?? this.ambientadores,
      estucheHerramienta: estucheHerramienta ?? this.estucheHerramienta,
      desarmador: desarmador ?? this.desarmador,
      llaveBocaCombinada: llaveBocaCombinada ?? this.llaveBocaCombinada,
      alicate: alicate ?? this.alicate,
      llaveDeRueda: llaveDeRueda ?? this.llaveDeRueda,
      palancaDeGata: palancaDeGata ?? this.palancaDeGata,
      gata: gata ?? this.gata,
      llantaDeRepuesto: llantaDeRepuesto ?? this.llantaDeRepuesto,
      trianguloDeEmergencia:
          trianguloDeEmergencia ?? this.trianguloDeEmergencia,
      malla: malla ?? this.malla,
      antena: antena ?? this.antena,
      extra: extra ?? this.extra,
      cableCargador: cableCargador ?? this.cableCargador,
      cajaDeFusibles: cajaDeFusibles ?? this.cajaDeFusibles,
      extintor: extintor ?? this.extintor,
      chalecoReflectivo: chalecoReflectivo ?? this.chalecoReflectivo,
      conos: conos ?? this.conos,
      extension: extension ?? this.extension,
      otros: otros ?? this.otros,
    );
  }

  int get totalElementos {
    return llaveSimple +
        llaveComando +
        llaveInteligente +
        encendedor +
        cenicero +
        cableUsbOAux +
        retrovisor +
        pisos +
        logos +
        estucheManual +
        manualesEstuche +
        pinDeRemolque +
        tapaPinDeRemolque +
        portaplaca +
        copasTapasDeAros +
        taponesChasis +
        cobertor +
        botiquin +
        pernoSeguroRueda +
        ambientadores +
        estucheHerramienta +
        desarmador +
        llaveBocaCombinada +
        alicate +
        llaveDeRueda +
        palancaDeGata +
        gata +
        llantaDeRepuesto +
        trianguloDeEmergencia +
        malla +
        antena +
        extra +
        cableCargador +
        cajaDeFusibles +
        extintor +
        chalecoReflectivo +
        conos +
        extension;
  }

  Map<String, dynamic> toInventarioData() {
    return {
      'LLAVE_SIMPLE': llaveSimple,
      'LLAVE_COMANDO': llaveComando,
      'LLAVE_INTELIGENTE': llaveInteligente,
      'ENCENDEDOR': encendedor,
      'CENICERO': cenicero,
      'CABLE_USB_O_AUX': cableUsbOAux,
      'RETROVISOR': retrovisor,
      'PISOS': pisos,
      'LOGOS': logos,
      'ESTUCHE_MANUAL': estucheManual,
      'MANUALES_ESTUCHE': manualesEstuche,
      'PIN_DE_REMOLQUE': pinDeRemolque,
      'TAPA_PIN_DE_REMOLQUE': tapaPinDeRemolque,
      'PORTAPLACA': portaplaca,
      'COPAS_TAPAS_DE_AROS': copasTapasDeAros,
      'TAPONES_CHASIS': taponesChasis,
      'COBERTOR': cobertor,
      'BOTIQUIN': botiquin,
      'PERNO_SEGURO_RUEDA': pernoSeguroRueda,
      'AMBIENTADORES': ambientadores,
      'ESTUCHE_HERRAMIENTA': estucheHerramienta,
      'DESARMADOR': desarmador,
      'LLAVE_BOCA_COMBINADA': llaveBocaCombinada,
      'ALICATE': alicate,
      'LLAVE_DE_RUEDA': llaveDeRueda,
      'PALANCA_DE_GATA': palancaDeGata,
      'GATA': gata,
      'LLANTA_DE_REPUESTO': llantaDeRepuesto,
      'TRIANGULO_DE_EMERGENCIA': trianguloDeEmergencia,
      'MALLA': malla,
      'ANTENA': antena,
      'EXTRA': extra,
      'CABLE_CARGADOR': cableCargador,
      'CAJA_DE_FUSIBLES': cajaDeFusibles,
      'EXTINTOR': extintor,
      'CHALECO_REFLECTIVO': chalecoReflectivo,
      'CONOS': conos,
      'EXTENSION': extension,
      'OTROS': otros,
    };
  }
}

/// Resto de modelos sin cambios...
class InformacionUnidad {
  final int id;
  final String embarque;
  final Marca marca;
  final String modelo;
  final String version;
  final String tipo;
  final int cantidadVins;

  const InformacionUnidad({
    required this.id,
    required this.embarque,
    required this.marca,
    required this.modelo,
    required this.version,
    required this.tipo,
    required this.cantidadVins,
  });

  factory InformacionUnidad.fromJson(Map<String, dynamic> json) {
    return InformacionUnidad(
      id: json['id'] ?? 0,
      embarque: json['embarque'] ?? '',
      marca: Marca.fromJson(json['marca'] ?? {}),
      modelo: json['modelo'] ?? '',
      version: json['version'] ?? '',
      tipo: json['tipo'] ?? '',
      cantidadVins: json['cantidad_vins'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'embarque': embarque,
      'marca': marca.toJson(),
      'modelo': modelo,
      'version': version,
      'tipo': tipo,
      'cantidad_vins': cantidadVins,
    };
  }
}

class Marca {
  final int id;
  final String marca;
  final String abrev;

  const Marca({required this.id, required this.marca, required this.abrev});

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      id: json['id'] ?? 0,
      marca: json['marca'] ?? '',
      abrev: json['abrev'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'marca': marca, 'abrev': abrev};
  }
}

class InventarioImagen {
  final int id;
  final int informacionUnidadId;
  final String? descripcion;
  final String? imagenUrl;
  final String? imagenThumbnailUrl;
  final String? createAt;
  final String? createBy;

  const InventarioImagen({
    required this.id,
    required this.informacionUnidadId,
    this.descripcion,
    this.imagenUrl,
    this.imagenThumbnailUrl,
    this.createAt,
    this.createBy,
  });

  factory InventarioImagen.fromJson(Map<String, dynamic> json) {
    return InventarioImagen(
      id: json['id'] ?? 0,
      informacionUnidadId: json['informacion_unidad'] is Map
          ? json['informacion_unidad']['id']
          : json['informacion_unidad'] ?? 0,
      descripcion: json['descripcion'],
      imagenUrl: json['imagen_url'],
      imagenThumbnailUrl: json['imagen_thumbnail_url'],
      createAt: json['create_at'],
      createBy: json['create_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'informacion_unidad': informacionUnidadId,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
      'imagen_thumbnail_url': imagenThumbnailUrl,
      'create_at': createAt,
      'create_by': createBy,
    };
  }

  bool get hasValidImage => imagenUrl != null && imagenUrl!.isNotEmpty;
  String? get displayUrl => imagenThumbnailUrl ?? imagenUrl;
}

// Resto de modelos para opciones...
class InventarioOptions {
  final Map<String, dynamic> inventarioPrevio;
  final List<CampoInventario> camposInventario;

  const InventarioOptions({
    required this.inventarioPrevio,
    required this.camposInventario,
  });

  factory InventarioOptions.fromJson(Map<String, dynamic> json) {
    return InventarioOptions(
      inventarioPrevio: json['inventario_previo'] ?? {},
      camposInventario:
          (json['campos_inventario'] as List?)
              ?.map((x) => CampoInventario.fromJson(x))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventario_previo': inventarioPrevio,
      'campos_inventario': camposInventario.map((x) => x.toJson()).toList(),
    };
  }
}

class CampoInventario {
  final String name;
  final String verboseName;
  final String type;
  final bool required;
  final dynamic defaultValue;

  const CampoInventario({
    required this.name,
    required this.verboseName,
    required this.type,
    required this.required,
    this.defaultValue,
  });

  factory CampoInventario.fromJson(Map<String, dynamic> json) {
    return CampoInventario(
      name: json['name'] ?? '',
      verboseName: json['verbose_name'] ?? '',
      type: json['type'] ?? '',
      required: json['required'] ?? false,
      defaultValue: json['default'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'verbose_name': verboseName,
      'type': type,
      'required': required,
      'default': defaultValue,
    };
  }

  bool get isNumericField => type == 'IntegerField';
  bool get isTextField => type == 'CharField';
}
