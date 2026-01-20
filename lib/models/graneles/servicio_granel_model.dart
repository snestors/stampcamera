// =============================================================================
// MODELOS DE GRANELES
// =============================================================================

/// Producto dentro de un servicio de granel
class ProductoGranel {
  final int id;
  final String producto;
  final String cantidad;

  const ProductoGranel({
    required this.id,
    required this.producto,
    required this.cantidad,
  });

  factory ProductoGranel.fromJson(Map<String, dynamic> json) {
    return ProductoGranel(
      id: json['id'] ?? 0,
      producto: json['producto'] ?? '',
      cantidad: json['cantidad'] ?? '0',
    );
  }
}

/// Servicio de granel (descarga de nave)
class ServicioGranel {
  final int id;
  final String codigo;
  final String? naveNombre;
  final String? consignatarioNombre;
  final String? puerto;
  final DateTime? fechaAtraque;
  final DateTime? inicioDescarga;
  final DateTime? finDescarga;
  final bool cierreServicio;
  final List<ProductoGranel> productos;
  final int totalTickets;

  const ServicioGranel({
    required this.id,
    required this.codigo,
    this.naveNombre,
    this.consignatarioNombre,
    this.puerto,
    this.fechaAtraque,
    this.inicioDescarga,
    this.finDescarga,
    this.cierreServicio = false,
    this.productos = const [],
    this.totalTickets = 0,
  });

  factory ServicioGranel.fromJson(Map<String, dynamic> json) {
    return ServicioGranel(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      naveNombre: json['nave_nombre'],
      consignatarioNombre: json['consignatario_nombre'],
      puerto: json['puerto'],
      fechaAtraque: json['fecha_atraque'] != null
          ? DateTime.tryParse(json['fecha_atraque'])
          : null,
      inicioDescarga: json['inicio_descarga'] != null
          ? DateTime.tryParse(json['inicio_descarga'])
          : null,
      finDescarga: json['fin_descarga'] != null
          ? DateTime.tryParse(json['fin_descarga'])
          : null,
      cierreServicio: json['cierre_servicio'] ?? false,
      productos: (json['productos'] as List?)
              ?.map((p) => ProductoGranel.fromJson(p))
              .toList() ??
          [],
      totalTickets: json['total_tickets'] ?? 0,
    );
  }

  /// Obtiene el nombre del producto principal
  String get productosPrincipales {
    if (productos.isEmpty) return 'Sin productos';
    return productos.map((p) => p.producto).join(', ');
  }
}

/// Ticket de muelle
class TicketMuelle {
  final int id;
  final String numeroTicket;
  final String? placaStr;
  final String? productoNombre;
  final String? blStr;
  final String? bodega;
  final DateTime? inicioDescarga;
  final DateTime? finDescarga;
  final String? tiempoCargio;
  final bool tieneBalanza;
  final String? fotoUrl;
  final String? observaciones;
  // Campos adicionales para detalle
  final String? transporteNombre;
  final String? choferNombre;
  final String? placaTractoStr;
  // Campos del servicio
  final int? servicioId;
  final String? servicioCodigo;
  final String? servicioNave;
  // IDs para edición
  final int? blId;
  final int? distribucionId;
  final int? placaId;
  final int? placaTractoId;
  final int? transporteId;
  final int? choferId;

  const TicketMuelle({
    required this.id,
    required this.numeroTicket,
    this.placaStr,
    this.productoNombre,
    this.blStr,
    this.bodega,
    this.inicioDescarga,
    this.finDescarga,
    this.tiempoCargio,
    this.tieneBalanza = false,
    this.fotoUrl,
    this.observaciones,
    this.transporteNombre,
    this.choferNombre,
    this.placaTractoStr,
    this.servicioId,
    this.servicioCodigo,
    this.servicioNave,
    this.blId,
    this.distribucionId,
    this.placaId,
    this.placaTractoId,
    this.transporteId,
    this.choferId,
  });

  factory TicketMuelle.fromJson(Map<String, dynamic> json) {
    return TicketMuelle(
      id: json['id'] ?? 0,
      numeroTicket: json['numero_ticket'] ?? '',
      placaStr: json['placa_str'],
      productoNombre: json['producto_nombre'],
      blStr: json['bl_str'],
      bodega: json['bodega'],
      inicioDescarga: json['inicio_descarga'] != null
          ? DateTime.tryParse(json['inicio_descarga'])
          : null,
      finDescarga: json['fin_descarga'] != null
          ? DateTime.tryParse(json['fin_descarga'])
          : null,
      tiempoCargio: json['tiempo_cargio'],
      tieneBalanza: json['tiene_balanza'] ?? false,
      fotoUrl: json['foto_url'],
      observaciones: json['observaciones'],
      transporteNombre: json['transporte_nombre'],
      choferNombre: json['chofer_nombre'],
      placaTractoStr: json['placa_tracto_str'],
      servicioId: json['servicio_id'],
      servicioCodigo: json['servicio_codigo'],
      servicioNave: json['servicio_nave'],
      blId: json['bl'],
      distribucionId: json['distribucion'],
      placaId: json['placa'],
      placaTractoId: json['placa_tracto'],
      transporteId: json['transporte'],
      choferId: json['chofer'],
    );
  }
}

/// Registro de balanza
class Balanza {
  final int id;
  final String guia;
  final String? ticketNumero;
  final String? placaStr;
  final String? almacen;
  final double pesoBruto;
  final double pesoTara;
  final double pesoNeto;
  final int? bags;
  final DateTime? fechaEntradaBalanza;
  final DateTime? fechaSalidaBalanza;
  final String? foto1Url;
  final String? foto2Url;
  final String? observaciones;
  final String? precintoStr;
  final String? permisoStr;
  final String? balanzaEntrada;
  final String? balanzaSalida;

  const Balanza({
    required this.id,
    required this.guia,
    this.ticketNumero,
    this.placaStr,
    this.almacen,
    required this.pesoBruto,
    required this.pesoTara,
    required this.pesoNeto,
    this.bags,
    this.fechaEntradaBalanza,
    this.fechaSalidaBalanza,
    this.foto1Url,
    this.foto2Url,
    this.observaciones,
    this.precintoStr,
    this.permisoStr,
    this.balanzaEntrada,
    this.balanzaSalida,
  });

  factory Balanza.fromJson(Map<String, dynamic> json) {
    return Balanza(
      id: json['id'] ?? 0,
      guia: json['guia'] ?? '',
      ticketNumero: json['ticket_numero'],
      placaStr: json['placa_str'],
      almacen: json['almacen'],
      pesoBruto: (json['peso_bruto'] ?? 0).toDouble(),
      pesoTara: (json['peso_tara'] ?? 0).toDouble(),
      pesoNeto: (json['peso_neto'] ?? 0).toDouble(),
      bags: json['bags'],
      fechaEntradaBalanza: json['fecha_entrada_balanza'] != null
          ? DateTime.tryParse(json['fecha_entrada_balanza'])
          : null,
      fechaSalidaBalanza: json['fecha_salida_balanza'] != null
          ? DateTime.tryParse(json['fecha_salida_balanza'])
          : null,
      foto1Url: json['foto1_url'],
      foto2Url: json['foto2_url'],
      observaciones: json['observaciones'],
      precintoStr: json['precinto_str'],
      permisoStr: json['permiso_str'],
      balanzaEntrada: json['balanza_entrada'],
      balanzaSalida: json['balanza_salida'],
    );
  }
}

/// Registro de silos
class Silos {
  final int id;
  final int? numeroSilo;  // n_camion en el modelo Django
  final String? productoNombre;
  final double? peso;  // cantidad en el modelo Django
  final int? bags;
  final DateTime? fechaHora;  // fecha_pesaje en el modelo Django
  final String? fotoUrl;

  const Silos({
    required this.id,
    this.numeroSilo,
    this.productoNombre,
    this.peso,
    this.bags,
    this.fechaHora,
    this.fotoUrl,
  });

  factory Silos.fromJson(Map<String, dynamic> json) {
    return Silos(
      id: json['id'] ?? 0,
      numeroSilo: json['numero_silo'],
      productoNombre: json['producto_nombre'],
      peso: json['peso']?.toDouble(),
      bags: json['bags'],
      fechaHora: json['fecha_hora'] != null
          ? DateTime.tryParse(json['fecha_hora'])
          : null,
      fotoUrl: json['foto_url'],
    );
  }
}

/// Opciones para formularios
class OptionItem {
  final int id;
  final String label;
  final String? extra;
  final int? productoId;  // Para relacionar BL con Distribución

  const OptionItem({
    required this.id,
    required this.label,
    this.extra,
    this.productoId,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      extra: json['extra'] ?? json['placa'] ?? json['bl'] ?? json['bodega'],
      productoId: json['producto_id'],
    );
  }
}

/// Opciones para crear ticket de muelle
class TicketMuelleOptions {
  final List<OptionItem> bls;
  final List<OptionItem> distribuciones;
  final List<OptionItem> placas;
  final List<OptionItem> placasTracto;
  final List<OptionItem> transportes;
  final List<OptionItem> choferes;

  const TicketMuelleOptions({
    this.bls = const [],
    this.distribuciones = const [],
    this.placas = const [],
    this.placasTracto = const [],
    this.transportes = const [],
    this.choferes = const [],
  });

  factory TicketMuelleOptions.fromJson(Map<String, dynamic> json) {
    return TicketMuelleOptions(
      bls: (json['bls'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      distribuciones: (json['distribuciones'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      placas: (json['placas'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      placasTracto: (json['placas_tracto'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      transportes: (json['transportes'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      choferes: (json['choferes'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// =============================================================================
// MODELO DASHBOARD SERVICIO
// =============================================================================

/// Información del servicio en el dashboard
class DashboardServicioInfo {
  final int id;
  final String codigo;
  final String? naveNombre;
  final String? consignatario;
  final String? puerto;
  final DateTime? fechaAtraque;
  final DateTime? inicioDescarga;
  final DateTime? finDescarga;
  final bool cierreServicio;

  const DashboardServicioInfo({
    required this.id,
    required this.codigo,
    this.naveNombre,
    this.consignatario,
    this.puerto,
    this.fechaAtraque,
    this.inicioDescarga,
    this.finDescarga,
    this.cierreServicio = false,
  });

  factory DashboardServicioInfo.fromJson(Map<String, dynamic> json) {
    return DashboardServicioInfo(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      naveNombre: json['nave_nombre'],
      consignatario: json['consignatario'],
      puerto: json['puerto'],
      fechaAtraque: json['fecha_atraque'] != null
          ? DateTime.tryParse(json['fecha_atraque'].toString())
          : null,
      inicioDescarga: json['inicio_descarga'] != null
          ? DateTime.tryParse(json['inicio_descarga'].toString())
          : null,
      finDescarga: json['fin_descarga'] != null
          ? DateTime.tryParse(json['fin_descarga'].toString())
          : null,
      cierreServicio: json['cierre_servicio'] ?? false,
    );
  }
}

/// KPIs del dashboard
class DashboardKpis {
  final double totalManifestado;
  final double totalDescargado;
  final double totalDespachado;
  final double porcentajeDescarga;
  final double porcentajeDespacho;
  final int viajesMuelle;
  final int viajesBalanza;
  final int viajesAlmacen;
  final double saldoDescarga;
  final double saldoDespacho;

  const DashboardKpis({
    this.totalManifestado = 0,
    this.totalDescargado = 0,
    this.totalDespachado = 0,
    this.porcentajeDescarga = 0,
    this.porcentajeDespacho = 0,
    this.viajesMuelle = 0,
    this.viajesBalanza = 0,
    this.viajesAlmacen = 0,
    this.saldoDescarga = 0,
    this.saldoDespacho = 0,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      totalManifestado: (json['total_manifestado'] ?? 0).toDouble(),
      totalDescargado: (json['total_descargado'] ?? 0).toDouble(),
      totalDespachado: (json['total_despachado'] ?? 0).toDouble(),
      porcentajeDescarga: (json['porcentaje_descarga'] ?? 0).toDouble(),
      porcentajeDespacho: (json['porcentaje_despacho'] ?? 0).toDouble(),
      viajesMuelle: json['viajes_muelle'] ?? 0,
      viajesBalanza: json['viajes_balanza'] ?? 0,
      viajesAlmacen: json['viajes_almacen'] ?? 0,
      saldoDescarga: (json['saldo_descarga'] ?? 0).toDouble(),
      saldoDespacho: (json['saldo_despacho'] ?? 0).toDouble(),
    );
  }
}

/// Distribución de almacén
class DistribucionAlmacenDashboard {
  final String almacen;
  final double manifestado;
  final double pesoBalanza;
  final int viajesBalanza;
  final int viajesTransito;
  final double pesoAlmacen;
  final int viajesAlmacen;
  final double saldo;

  const DistribucionAlmacenDashboard({
    required this.almacen,
    this.manifestado = 0,
    this.pesoBalanza = 0,
    this.viajesBalanza = 0,
    this.viajesTransito = 0,
    this.pesoAlmacen = 0,
    this.viajesAlmacen = 0,
    this.saldo = 0,
  });

  factory DistribucionAlmacenDashboard.fromJson(Map<String, dynamic> json) {
    return DistribucionAlmacenDashboard(
      almacen: json['almacen'] ?? '',
      manifestado: (json['manifestado'] ?? 0).toDouble(),
      pesoBalanza: (json['peso_balanza_distribucion'] ?? 0).toDouble(),
      viajesBalanza: json['viajes_balanza_distribucion'] ?? 0,
      viajesTransito: json['viajes_transito'] ?? 0,
      pesoAlmacen: (json['peso_almacen'] ?? 0).toDouble(),
      viajesAlmacen: json['viajes_almacen'] ?? 0,
      saldo: (json['saldo'] ?? 0).toDouble(),
    );
  }
}

/// Producto en el dashboard
class DashboardProducto {
  final String producto;
  final double pesoManifestado;
  final double pesoDescargado;
  final double pesoDespachado;
  final double porcentajeDescarga;
  final double porcentajeDespacho;
  final int viajesMuelle;
  final int viajesBalanza;
  final int viajesAlmacen;
  final List<DistribucionAlmacenDashboard> distribuciones;
  final List<BodegaItem> bodegas;

  const DashboardProducto({
    required this.producto,
    this.pesoManifestado = 0,
    this.pesoDescargado = 0,
    this.pesoDespachado = 0,
    this.porcentajeDescarga = 0,
    this.porcentajeDespacho = 0,
    this.viajesMuelle = 0,
    this.viajesBalanza = 0,
    this.viajesAlmacen = 0,
    this.distribuciones = const [],
    this.bodegas = const [],
  });

  factory DashboardProducto.fromJson(Map<String, dynamic> json) {
    return DashboardProducto(
      producto: json['producto'] ?? '',
      pesoManifestado: (json['peso_manifestado'] ?? 0).toDouble(),
      pesoDescargado: (json['peso_descargado'] ?? 0).toDouble(),
      pesoDespachado: (json['peso_despachado'] ?? 0).toDouble(),
      porcentajeDescarga: (json['porcentaje_descarga'] ?? 0).toDouble(),
      porcentajeDespacho: (json['porcentaje_despacho'] ?? 0).toDouble(),
      viajesMuelle: json['viajes_muelle'] ?? 0,
      viajesBalanza: json['viajes_balanza'] ?? 0,
      viajesAlmacen: json['viajes_almacen'] ?? 0,
      distribuciones: (json['distribuciones'] as List?)
              ?.map((e) => DistribucionAlmacenDashboard.fromJson(e))
              .toList() ??
          [],
      bodegas: (json['bodegas'] as List?)
              ?.map((e) => BodegaItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Silos por producto
class SilosProducto {
  final String producto;
  final double peso;
  final int bags;
  final int viajes;

  const SilosProducto({
    required this.producto,
    this.peso = 0,
    this.bags = 0,
    this.viajes = 0,
  });

  factory SilosProducto.fromJson(Map<String, dynamic> json) {
    return SilosProducto(
      producto: json['producto'] ?? '',
      peso: (json['peso'] ?? 0).toDouble(),
      bags: json['bags'] ?? 0,
      viajes: json['viajes'] ?? 0,
    );
  }
}

/// Resumen de silos del servicio
class DashboardSilos {
  final double totalPeso;
  final int totalBags;
  final int totalViajes;
  final List<SilosProducto> porProducto;

  const DashboardSilos({
    this.totalPeso = 0,
    this.totalBags = 0,
    this.totalViajes = 0,
    this.porProducto = const [],
  });

  factory DashboardSilos.fromJson(Map<String, dynamic> json) {
    return DashboardSilos(
      totalPeso: (json['total_peso'] ?? 0).toDouble(),
      totalBags: json['total_bags'] ?? 0,
      totalViajes: json['total_viajes'] ?? 0,
      porProducto: (json['por_producto'] as List?)
              ?.map((e) => SilosProducto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Item de bodega de la nave (BODEGA 1, BODEGA 2, etc.)
class BodegaItem {
  final String bodega;
  final double manifestado;
  final double descargado;
  final int viajes;

  const BodegaItem({
    required this.bodega,
    this.manifestado = 0,
    this.descargado = 0,
    this.viajes = 0,
  });

  factory BodegaItem.fromJson(Map<String, dynamic> json) {
    return BodegaItem(
      bodega: json['bodega'] ?? '',
      manifestado: (json['manifestado'] ?? 0).toDouble(),
      descargado: (json['descargado'] ?? 0).toDouble(),
      viajes: json['viajes'] ?? 0,
    );
  }

  /// Porcentaje de descarga
  double get porcentajeDescarga {
    if (manifestado <= 0) return 0;
    return (descargado / manifestado * 100).clamp(0, 100);
  }
}

/// Resumen de bodegas de la nave del servicio
class DashboardBodegas {
  final double totalManifestado;
  final double totalDescargado;
  final int totalViajes;
  final List<BodegaItem> porBodega;

  const DashboardBodegas({
    this.totalManifestado = 0,
    this.totalDescargado = 0,
    this.totalViajes = 0,
    this.porBodega = const [],
  });

  factory DashboardBodegas.fromJson(Map<String, dynamic> json) {
    return DashboardBodegas(
      totalManifestado: (json['total_manifestado'] ?? 0).toDouble(),
      totalDescargado: (json['total_descargado'] ?? 0).toDouble(),
      totalViajes: json['total_viajes'] ?? 0,
      porBodega: (json['por_bodega'] as List?)
              ?.map((e) => BodegaItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Dashboard completo del servicio
class ServicioDashboard {
  final DashboardServicioInfo servicio;
  final DashboardKpis kpis;
  final List<DashboardProducto> productos;
  final DashboardSilos silos;
  final DashboardBodegas bodegas;

  const ServicioDashboard({
    required this.servicio,
    required this.kpis,
    this.productos = const [],
    this.silos = const DashboardSilos(),
    this.bodegas = const DashboardBodegas(),
  });

  factory ServicioDashboard.fromJson(Map<String, dynamic> json) {
    return ServicioDashboard(
      servicio: DashboardServicioInfo.fromJson(json['servicio'] ?? {}),
      kpis: DashboardKpis.fromJson(json['kpis'] ?? {}),
      productos: (json['productos'] as List?)
              ?.map((e) => DashboardProducto.fromJson(e))
              .toList() ??
          [],
      silos: DashboardSilos.fromJson(json['silos'] ?? {}),
      bodegas: DashboardBodegas.fromJson(json['bodegas'] ?? {}),
    );
  }
}

/// Opciones para crear balanza
class BalanzaOptions {
  final List<TicketMuelle> ticketsSinBalanza;
  final List<OptionItem> distribucionesAlmacen;
  final List<OptionItem> precintos;
  final List<OptionItem> permisos;

  const BalanzaOptions({
    this.ticketsSinBalanza = const [],
    this.distribucionesAlmacen = const [],
    this.precintos = const [],
    this.permisos = const [],
  });

  factory BalanzaOptions.fromJson(Map<String, dynamic> json) {
    return BalanzaOptions(
      ticketsSinBalanza: (json['tickets_sin_balanza'] as List?)
              ?.map((e) => TicketMuelle.fromJson(e))
              .toList() ??
          [],
      distribucionesAlmacen: (json['distribuciones_almacen'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      precintos: (json['precintos'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      permisos: (json['permisos'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
