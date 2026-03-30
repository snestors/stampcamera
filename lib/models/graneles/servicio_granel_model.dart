// =============================================================================
// MODELOS DE GRANELES
// =============================================================================

import 'package:stampcamera/core/has_id.dart';

/// Helper para parsear double desde string o número (el backend puede devolver ambos)
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

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
class ServicioGranel with HasId {
  @override
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

/// Datos de balanza anidados en el detalle del ticket
class BalanzaResumen {
  final int id;
  final String guia;
  final double pesoBruto;
  final double pesoTara;
  final double pesoNeto;
  final int? bags;
  final DateTime? fechaEntradaBalanza;
  final DateTime? fechaSalidaBalanza;
  final String? balanzaEntrada;
  final String? balanzaSalida;
  final String? almacen;
  final String? precinto;
  final String? permiso;
  final String? observaciones;
  final String? foto1Url;
  final String? foto2Url;
  // IDs para edicion
  final int? distribucionAlmacenId;
  final int? precintoId;
  final int? permisoId;

  const BalanzaResumen({
    required this.id,
    required this.guia,
    required this.pesoBruto,
    required this.pesoTara,
    required this.pesoNeto,
    this.bags,
    this.fechaEntradaBalanza,
    this.fechaSalidaBalanza,
    this.balanzaEntrada,
    this.balanzaSalida,
    this.almacen,
    this.precinto,
    this.permiso,
    this.observaciones,
    this.foto1Url,
    this.foto2Url,
    this.distribucionAlmacenId,
    this.precintoId,
    this.permisoId,
  });

  factory BalanzaResumen.fromJson(Map<String, dynamic> json) {
    return BalanzaResumen(
      id: json['id'] ?? 0,
      guia: json['guia']?.toString() ?? '',
      pesoBruto: _parseDouble(json['peso_bruto']),
      pesoTara: _parseDouble(json['peso_tara']),
      pesoNeto: _parseDouble(json['peso_neto']),
      bags: json['bags'],
      fechaEntradaBalanza: (json['fecha_entrada'] ?? json['fecha_entrada_balanza']) != null
          ? DateTime.tryParse((json['fecha_entrada'] ?? json['fecha_entrada_balanza']).toString())
          : null,
      fechaSalidaBalanza: (json['fecha_salida'] ?? json['fecha_salida_balanza']) != null
          ? DateTime.tryParse((json['fecha_salida'] ?? json['fecha_salida_balanza']).toString())
          : null,
      balanzaEntrada: json['balanza_entrada']?.toString(),
      balanzaSalida: json['balanza_salida']?.toString(),
      almacen: json['almacen_nombre']?.toString() ?? json['almacen']?.toString(),
      precinto: json['precinto_str']?.toString() ?? json['precinto']?.toString(),
      permiso: json['permiso_str']?.toString() ?? json['permiso']?.toString(),
      observaciones: json['observaciones']?.toString(),
      foto1Url: json['foto1_url']?.toString(),
      foto2Url: json['foto2_url']?.toString(),
      distribucionAlmacenId: json['distribucion_almacen'],
      precintoId: json['precinto'] is int ? json['precinto'] : null,
      permisoId: json['permiso'] is int ? json['permiso'] : null,
    );
  }
}

/// Datos de almacén anidados en el detalle del ticket
class AlmacenResumen {
  final int id;
  final double pesoBruto;
  final double pesoTara;
  final double pesoNeto;
  final int? bags;
  final DateTime? fechaEntradaAlmacen;
  final DateTime? fechaSalidaAlmacen;
  final String? observaciones;
  final String? foto1Url;
  final String? foto2Url;

  const AlmacenResumen({
    required this.id,
    required this.pesoBruto,
    required this.pesoTara,
    required this.pesoNeto,
    this.bags,
    this.fechaEntradaAlmacen,
    this.fechaSalidaAlmacen,
    this.observaciones,
    this.foto1Url,
    this.foto2Url,
  });

  factory AlmacenResumen.fromJson(Map<String, dynamic> json) {
    return AlmacenResumen(
      id: json['id'] ?? 0,
      pesoBruto: _parseDouble(json['peso_bruto']),
      pesoTara: _parseDouble(json['peso_tara']),
      pesoNeto: _parseDouble(json['peso_neto']),
      bags: json['bags'],
      fechaEntradaAlmacen: (json['fecha_entrada'] ?? json['fecha_entrada_almacen']) != null
          ? DateTime.tryParse((json['fecha_entrada'] ?? json['fecha_entrada_almacen']).toString())
          : null,
      fechaSalidaAlmacen: (json['fecha_salida'] ?? json['fecha_salida_almacen']) != null
          ? DateTime.tryParse((json['fecha_salida'] ?? json['fecha_salida_almacen']).toString())
          : null,
      observaciones: json['observaciones']?.toString(),
      foto1Url: json['foto1_url']?.toString(),
      foto2Url: json['foto2_url']?.toString(),
    );
  }
}

/// Ticket de muelle
class TicketMuelle with HasId {
  @override
  final int id;
  final String numeroTicket;
  final String? placaStr;
  final String? productoNombre;
  final String? blStr;
  final String? bodega;
  final DateTime? inicioDescarga;
  final DateTime? finDescarga;
  final String? tiempoCargio;
  final String? estado; // pendiente_balanza, pendiente_almacen, completo
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
  // Datos anidados para detalle
  final BalanzaResumen? balanzaData;
  final AlmacenResumen? almacenData;

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
    this.estado,
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
    this.balanzaData,
    this.almacenData,
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
      estado: json['estado']?.toString(),
      tieneBalanza: json['tiene_balanza'] ?? (json['estado'] != 'pendiente_balanza'),
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
      balanzaData: (json['balanza'] ?? json['balanza_data']) != null
          ? BalanzaResumen.fromJson(json['balanza'] ?? json['balanza_data'])
          : null,
      almacenData: (json['almacen'] ?? json['almacen_data']) != null
          ? AlmacenResumen.fromJson(json['almacen'] ?? json['almacen_data'])
          : null,
    );
  }
}

/// Registro de balanza
class Balanza with HasId {
  @override
  final int id;
  final int? servicioId;
  final String? servicioCodigo;
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
  final bool tieneAlmacen;
  // IDs para edición
  final int? ticketId;
  final int? distribucionAlmacenId;
  final int? precintoId;
  final int? permisoId;

  const Balanza({
    required this.id,
    this.servicioId,
    this.servicioCodigo,
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
    this.tieneAlmacen = false,
    this.ticketId,
    this.distribucionAlmacenId,
    this.precintoId,
    this.permisoId,
  });

  factory Balanza.fromJson(Map<String, dynamic> json) {
    return Balanza(
      id: json['id'] ?? 0,
      servicioId: json['servicio_id'],
      servicioCodigo: json['servicio_codigo'],
      guia: json['guia']?.toString() ?? '',
      ticketNumero: json['ticket_numero'],
      placaStr: json['placa_str'],
      almacen: json['almacen'],
      pesoBruto: _parseDouble(json['peso_bruto']),
      pesoTara: _parseDouble(json['peso_tara']),
      pesoNeto: _parseDouble(json['peso_neto']),
      bags: json['bags'],
      fechaEntradaBalanza: (json['fecha_entrada'] ?? json['fecha_entrada_balanza']) != null
          ? DateTime.tryParse((json['fecha_entrada'] ?? json['fecha_entrada_balanza']).toString())
          : null,
      fechaSalidaBalanza: (json['fecha_salida'] ?? json['fecha_salida_balanza']) != null
          ? DateTime.tryParse((json['fecha_salida'] ?? json['fecha_salida_balanza']).toString())
          : null,
      foto1Url: json['foto1_url'],
      foto2Url: json['foto2_url'],
      observaciones: json['observaciones'],
      precintoStr: json['precinto_str'],
      permisoStr: json['permiso_str'],
      balanzaEntrada: json['balanza_entrada'],
      balanzaSalida: json['balanza_salida'],
      tieneAlmacen: json['tiene_almacen'] ?? false,
      ticketId: json['ticket_id'],
      distribucionAlmacenId: json['distribucion_almacen_id'],
      precintoId: json['precinto_id'],
      permisoId: json['permiso_id'],
    );
  }
}

/// Registro de silos
class Silos with HasId {
  @override
  final int id;
  final int? numeroSilo;  // n_camion en el modelo Django
  final String? productoNombre;
  final double? peso;  // cantidad (peso neto) en el modelo Django
  final double? pesoBruto;  // peso_bruto en el modelo Django
  final double? pesoTara;   // peso_tara en el modelo Django
  final int? bags;
  final DateTime? fechaHora;  // fecha_pesaje en el modelo Django
  final String? fotoUrl;

  const Silos({
    required this.id,
    this.numeroSilo,
    this.productoNombre,
    this.peso,
    this.pesoBruto,
    this.pesoTara,
    this.bags,
    this.fechaHora,
    this.fotoUrl,
  });

  factory Silos.fromJson(Map<String, dynamic> json) {
    return Silos(
      id: json['id'] ?? 0,
      numeroSilo: json['numero_silo'],
      productoNombre: json['producto_nombre'],
      peso: json['peso'] != null ? _parseDouble(json['peso']) : null,
      pesoBruto: json['peso_bruto'] != null ? _parseDouble(json['peso_bruto']) : null,
      pesoTara: json['peso_tara'] != null ? _parseDouble(json['peso_tara']) : null,
      bags: json['bags'],
      fechaHora: json['fecha_hora'] != null
          ? DateTime.tryParse(json['fecha_hora'])
          : null,
      fotoUrl: json['foto_url'],
    );
  }
}

/// Opciones para formularios (item simple)
class OptionItem {
  final int id;
  final String label;
  final String? extra;
  final int? productoId;

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

/// BL con distribuciones, distribuciones almacén, permisos y jornadas anidadas
class BlOption {
  final int id;
  final String label;
  final int? productoId;
  final List<OptionItem> distribuciones;
  final List<OptionItem> distribucionesAlmacen;
  final List<OptionItem> permisos;
  final List<OptionItem> jornadas;

  const BlOption({
    required this.id,
    required this.label,
    this.productoId,
    this.distribuciones = const [],
    this.distribucionesAlmacen = const [],
    this.permisos = const [],
    this.jornadas = const [],
  });

  factory BlOption.fromJson(Map<String, dynamic> json) {
    return BlOption(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      productoId: json['producto_id'],
      distribuciones: (json['distribuciones'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      distribucionesAlmacen: (json['distribuciones_almacen'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      permisos: (json['permisos'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      jornadas: (json['jornadas'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Opciones para crear ticket de muelle
class TicketMuelleOptions {
  final List<BlOption> bls;
  final List<OptionItem> placas;
  final List<OptionItem> placasTracto;
  final List<OptionItem> transportes;
  final List<OptionItem> choferes;

  const TicketMuelleOptions({
    this.bls = const [],
    this.placas = const [],
    this.placasTracto = const [],
    this.transportes = const [],
    this.choferes = const [],
  });

  factory TicketMuelleOptions.fromJson(Map<String, dynamic> json) {
    return TicketMuelleOptions(
      bls: (json['bls'] as List?)
              ?.map((e) => BlOption.fromJson(e))
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
      totalManifestado: _parseDouble(json['total_manifestado']),
      totalDescargado: _parseDouble(json['total_descargado']),
      totalDespachado: _parseDouble(json['total_despachado']),
      porcentajeDescarga: _parseDouble(json['porcentaje_descarga']),
      porcentajeDespacho: _parseDouble(json['porcentaje_despacho']),
      viajesMuelle: json['viajes_muelle'] ?? 0,
      viajesBalanza: json['viajes_balanza'] ?? 0,
      viajesAlmacen: json['viajes_almacen'] ?? 0,
      saldoDescarga: _parseDouble(json['saldo_descarga']),
      saldoDespacho: _parseDouble(json['saldo_despacho']),
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
      manifestado: _parseDouble(json['manifestado']),
      pesoBalanza: _parseDouble(json['peso_balanza_distribucion']),
      viajesBalanza: json['viajes_balanza_distribucion'] ?? 0,
      viajesTransito: json['viajes_transito'] ?? 0,
      pesoAlmacen: _parseDouble(json['peso_almacen']),
      viajesAlmacen: json['viajes_almacen'] ?? 0,
      saldo: _parseDouble(json['saldo']),
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
      pesoManifestado: _parseDouble(json['peso_manifestado']),
      pesoDescargado: _parseDouble(json['peso_descargado']),
      pesoDespachado: _parseDouble(json['peso_despachado']),
      porcentajeDescarga: _parseDouble(json['porcentaje_descarga']),
      porcentajeDespacho: _parseDouble(json['porcentaje_despacho']),
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
      peso: _parseDouble(json['peso']),
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
      totalPeso: _parseDouble(json['total_peso']),
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
      manifestado: _parseDouble(json['manifestado']),
      descargado: _parseDouble(json['descargado']),
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
      totalManifestado: _parseDouble(json['total_manifestado']),
      totalDescargado: _parseDouble(json['total_descargado']),
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

/// Opciones para crear silos
class SilosOptions {
  final List<OptionItem> bls;
  final List<OptionItem> distribuciones;
  final List<OptionItem> jornadas;

  const SilosOptions({
    this.bls = const [],
    this.distribuciones = const [],
    this.jornadas = const [],
  });

  factory SilosOptions.fromJson(Map<String, dynamic> json) {
    return SilosOptions(
      bls: (json['bls'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      distribuciones: (json['distribuciones'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      jornadas: (json['jornadas'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Registro de almacén
class AlmacenGranel with HasId {
  @override
  final int id;
  final String? guia;
  final String? ticketNumero;
  final String? placaStr;
  final String? almacenNombre;
  final String? servicioCodigo;
  final DateTime? fechaEntradaAlmacen;
  final DateTime? fechaSalidaAlmacen;
  final double pesoBruto;
  final double pesoTara;
  final double pesoNeto;
  final int? bags;
  final String? foto1Url;
  final String? observaciones;

  const AlmacenGranel({
    required this.id,
    this.guia,
    this.ticketNumero,
    this.placaStr,
    this.almacenNombre,
    this.servicioCodigo,
    this.fechaEntradaAlmacen,
    this.fechaSalidaAlmacen,
    this.pesoBruto = 0,
    this.pesoTara = 0,
    this.pesoNeto = 0,
    this.bags,
    this.foto1Url,
    this.observaciones,
  });

  factory AlmacenGranel.fromJson(Map<String, dynamic> json) {
    return AlmacenGranel(
      id: json['id'] ?? 0,
      guia: json['guia'],
      ticketNumero: json['ticket_numero'],
      placaStr: json['placa_str'],
      almacenNombre: json['almacen_nombre'],
      servicioCodigo: json['servicio_codigo'],
      fechaEntradaAlmacen: (json['fecha_entrada'] ?? json['fecha_entrada_almacen']) != null
          ? DateTime.tryParse((json['fecha_entrada'] ?? json['fecha_entrada_almacen']).toString())
          : null,
      fechaSalidaAlmacen: (json['fecha_salida'] ?? json['fecha_salida_almacen']) != null
          ? DateTime.tryParse((json['fecha_salida'] ?? json['fecha_salida_almacen']).toString())
          : null,
      pesoBruto: _parseDouble(json['peso_bruto']),
      pesoTara: _parseDouble(json['peso_tara']),
      pesoNeto: _parseDouble(json['peso_neto']),
      bags: json['bags'],
      foto1Url: json['foto1_url'],
      observaciones: json['observaciones'],
    );
  }
}

// =============================================================================
// MODELO DE PARALIZACIÓN
// =============================================================================

class Paralizacion with HasId {
  @override
  final int id;
  final int? servicioId;
  final String? servicioCodigo;
  final String? naveNombre;
  final String? consignatarioNombre;
  final String bodega;
  final String? motivoStr;
  final int? motivoId;
  final DateTime? inicio;
  final DateTime? fin;
  final String? duracion;
  final String? jornadaStr;
  final String? observacion;
  final String? createByNombre;
  final DateTime? createAt;

  const Paralizacion({
    required this.id,
    this.servicioId,
    this.servicioCodigo,
    this.naveNombre,
    this.consignatarioNombre,
    required this.bodega,
    this.motivoStr,
    this.motivoId,
    this.inicio,
    this.fin,
    this.duracion,
    this.jornadaStr,
    this.observacion,
    this.createByNombre,
    this.createAt,
  });

  factory Paralizacion.fromJson(Map<String, dynamic> json) {
    return Paralizacion(
      id: json['id'] ?? 0,
      servicioId: json['servicio'] ?? json['servicio_id'],
      servicioCodigo: json['servicio_codigo'],
      naveNombre: json['nave_nombre'],
      consignatarioNombre: json['consignatario_nombre'],
      bodega: json['bodega'] ?? '',
      motivoStr: json['motivo_str'],
      motivoId: json['motivo'] is int ? json['motivo'] : json['motivo_id'],
      inicio: json['inicio'] != null ? DateTime.tryParse(json['inicio'].toString()) : null,
      fin: json['fin'] != null ? DateTime.tryParse(json['fin'].toString()) : null,
      duracion: json['duracion'],
      jornadaStr: json['jornada_str'],
      observacion: json['observacion'],
      createByNombre: json['create_by_nombre'],
      createAt: json['create_at'] != null ? DateTime.tryParse(json['create_at'].toString()) : null,
    );
  }
}

/// Opciones para formulario de paralizaciones
class ParalizacionOptions {
  final List<OptionItem> motivos;
  final List<String> bodegas;
  final List<OptionItem> servicios;

  const ParalizacionOptions({
    this.motivos = const [],
    this.bodegas = const [],
    this.servicios = const [],
  });

  factory ParalizacionOptions.fromJson(Map<String, dynamic> json) {
    return ParalizacionOptions(
      motivos: (json['motivos'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      bodegas: (json['bodegas'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      servicios: (json['servicios'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// =============================================================================
// MODELO DE CONTROL HUMEDAD / TEMPERATURA
// =============================================================================

class ControlHumedad with HasId {
  @override
  final int id;
  final int? servicioId;
  final String? servicioCodigo;
  final String? naveNombre;
  final String? consignatarioNombre;
  final String? distribucionStr;
  final int? distribucionId;
  final String? jornadaStr;
  final int? jornadaId;
  final DateTime? horaMuestra;
  final double? temperatura;
  final double? humedad;
  final String? observaciones;
  final String? fotoTemperaturaUrl;     // thumbnail
  final String? fotoTemperaturaFullUrl; // original
  final String? fotoHumedadUrl;         // thumbnail
  final String? fotoHumedadFullUrl;     // original
  final String? fotoExtraUrl;           // thumbnail
  final String? fotoExtraFullUrl;       // original
  final String? createByNombre;
  final DateTime? createAt;

  const ControlHumedad({
    required this.id,
    this.servicioId,
    this.servicioCodigo,
    this.naveNombre,
    this.consignatarioNombre,
    this.distribucionStr,
    this.distribucionId,
    this.jornadaStr,
    this.jornadaId,
    this.horaMuestra,
    this.temperatura,
    this.humedad,
    this.observaciones,
    this.fotoTemperaturaUrl,
    this.fotoTemperaturaFullUrl,
    this.fotoHumedadUrl,
    this.fotoHumedadFullUrl,
    this.fotoExtraUrl,
    this.fotoExtraFullUrl,
    this.createByNombre,
    this.createAt,
  });

  factory ControlHumedad.fromJson(Map<String, dynamic> json) {
    return ControlHumedad(
      id: json['id'] ?? 0,
      servicioId: json['servicio'] ?? json['servicio_id'],
      servicioCodigo: json['servicio_codigo'],
      naveNombre: json['nave_nombre'],
      consignatarioNombre: json['consignatario_nombre'],
      distribucionStr: json['distribucion_str'],
      distribucionId: json['distribucion'] is int ? json['distribucion'] : json['distribucion_id'],
      jornadaStr: json['jornada_str'],
      jornadaId: json['jornada'] is int ? json['jornada'] : json['jornada_id'],
      horaMuestra: json['hora_muestra'] != null
          ? DateTime.tryParse(json['hora_muestra'].toString())
          : null,
      temperatura: json['temperatura'] != null ? _parseDouble(json['temperatura']) : null,
      humedad: json['humedad'] != null ? _parseDouble(json['humedad']) : null,
      observaciones: json['observaciones'],
      fotoTemperaturaUrl: json['foto_temperatura_url'],
      fotoTemperaturaFullUrl: json['foto_temperatura_full_url'] ?? json['foto_temperatura_url'],
      fotoHumedadUrl: json['foto_humedad_url'],
      fotoHumedadFullUrl: json['foto_humedad_full_url'] ?? json['foto_humedad_url'],
      fotoExtraUrl: json['foto_extra_url'],
      fotoExtraFullUrl: json['foto_extra_full_url'] ?? json['foto_extra_url'],
      createByNombre: json['create_by_nombre'],
      createAt: json['create_at'] != null ? DateTime.tryParse(json['create_at'].toString()) : null,
    );
  }
}

/// Opciones para formulario de control humedad
class ControlHumedadOptions {
  final List<OptionItem> distribuciones;
  final List<OptionItem> jornadas;
  final List<OptionItem> servicios;

  const ControlHumedadOptions({
    this.distribuciones = const [],
    this.jornadas = const [],
    this.servicios = const [],
  });

  factory ControlHumedadOptions.fromJson(Map<String, dynamic> json) {
    return ControlHumedadOptions(
      distribuciones: (json['distribuciones'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      jornadas: (json['jornadas'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
      servicios: (json['servicios'] as List?)
              ?.map((e) => OptionItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// =============================================================================
// RESUMEN DE JORNADAS (tabla pivote descarga/despacho)
// =============================================================================

/// Cabecera de bodega en resumen de jornadas
class JornadaCabeceraBodega {
  final String bodega;
  final String producto;
  final double pesoManifestado;
  final int bagsManifestados;

  const JornadaCabeceraBodega({
    required this.bodega,
    required this.producto,
    this.pesoManifestado = 0,
    this.bagsManifestados = 0,
  });

  factory JornadaCabeceraBodega.fromJson(Map<String, dynamic> json) {
    return JornadaCabeceraBodega(
      bodega: json['bodega'] ?? '',
      producto: json['producto'] ?? '',
      pesoManifestado: _parseDouble(json['peso_manifestado']),
      bagsManifestados: json['bags_manifestados'] ?? 0,
    );
  }
}

/// Cabecera de almacen en resumen de jornadas
class JornadaCabeceraAlmacen {
  final String almacen;
  final String producto;
  final double pesoManifestado;
  final int bagsManifestados;

  const JornadaCabeceraAlmacen({
    required this.almacen,
    required this.producto,
    this.pesoManifestado = 0,
    this.bagsManifestados = 0,
  });

  factory JornadaCabeceraAlmacen.fromJson(Map<String, dynamic> json) {
    return JornadaCabeceraAlmacen(
      almacen: json['almacen'] ?? '',
      producto: json['producto'] ?? '',
      pesoManifestado: _parseDouble(json['peso_manifestado']),
      bagsManifestados: json['bags_manifestados'] ?? 0,
    );
  }
}

/// Producto por bodega dentro de una jornada
class JornadaProductoBodega {
  final String bodega;
  final String producto;
  final int viajesMuelle;
  final int viajesSilos;
  final double peso;
  final double pesoSilos;
  final int bags;

  const JornadaProductoBodega({
    required this.bodega,
    required this.producto,
    this.viajesMuelle = 0,
    this.viajesSilos = 0,
    this.peso = 0,
    this.pesoSilos = 0,
    this.bags = 0,
  });

  factory JornadaProductoBodega.fromJson(Map<String, dynamic> json) {
    return JornadaProductoBodega(
      bodega: json['bodega'] ?? '',
      producto: json['producto'] ?? '',
      viajesMuelle: json['viajes_muelle'] ?? 0,
      viajesSilos: json['viajes_silos'] ?? 0,
      peso: _parseDouble(json['peso']),
      pesoSilos: _parseDouble(json['peso_silos']),
      bags: json['bags'] ?? 0,
    );
  }
}

/// Producto por almacen dentro de una jornada
class JornadaProductoAlmacen {
  final String almacen;
  final String producto;
  final int viajes;
  final double peso;
  final int bags;

  const JornadaProductoAlmacen({
    required this.almacen,
    required this.producto,
    this.viajes = 0,
    this.peso = 0,
    this.bags = 0,
  });

  factory JornadaProductoAlmacen.fromJson(Map<String, dynamic> json) {
    return JornadaProductoAlmacen(
      almacen: json['almacen'] ?? '',
      producto: json['producto'] ?? '',
      viajes: json['viajes'] ?? 0,
      peso: _parseDouble(json['peso']),
      bags: json['bags'] ?? 0,
    );
  }
}

/// Una jornada individual
class JornadaResumen {
  final String jornada;
  final int nJornada;
  final String turno;
  final List<JornadaProductoBodega> productosBodega;
  final List<JornadaProductoAlmacen> productosAlmacen;
  final double totalPesoBodega;
  final int totalViajesMuelleBodega;
  final int totalViajesSilosBodega;
  final int totalBagsBodega;
  final double totalPesoAlmacen;
  final int totalViajesAlmacen;
  final int totalBagsAlmacen;

  const JornadaResumen({
    required this.jornada,
    required this.nJornada,
    required this.turno,
    this.productosBodega = const [],
    this.productosAlmacen = const [],
    this.totalPesoBodega = 0,
    this.totalViajesMuelleBodega = 0,
    this.totalViajesSilosBodega = 0,
    this.totalBagsBodega = 0,
    this.totalPesoAlmacen = 0,
    this.totalViajesAlmacen = 0,
    this.totalBagsAlmacen = 0,
  });

  factory JornadaResumen.fromJson(Map<String, dynamic> json) {
    return JornadaResumen(
      jornada: json['jornada'] ?? '',
      nJornada: json['n_jornada'] ?? 0,
      turno: json['turno'] ?? '',
      productosBodega: (json['productos_bodega'] as List?)
              ?.map((e) => JornadaProductoBodega.fromJson(e))
              .toList() ??
          [],
      productosAlmacen: (json['productos_almacen'] as List?)
              ?.map((e) => JornadaProductoAlmacen.fromJson(e))
              .toList() ??
          [],
      totalPesoBodega: _parseDouble(json['total_peso_bodega']),
      totalViajesMuelleBodega: json['total_viajes_muelle_bodega'] ?? 0,
      totalViajesSilosBodega: json['total_viajes_silos_bodega'] ?? 0,
      totalBagsBodega: json['total_bags_bodega'] ?? 0,
      totalPesoAlmacen: _parseDouble(json['total_peso_almacen']),
      totalViajesAlmacen: json['total_viajes_almacen'] ?? 0,
      totalBagsAlmacen: json['total_bags_almacen'] ?? 0,
    );
  }
}

/// Total por bodega
class JornadaTotalBodega {
  final String bodega;
  final String producto;
  final double totalPeso;
  final int totalViajes;
  final int totalBags;

  const JornadaTotalBodega({
    required this.bodega,
    required this.producto,
    this.totalPeso = 0,
    this.totalViajes = 0,
    this.totalBags = 0,
  });

  factory JornadaTotalBodega.fromJson(Map<String, dynamic> json) {
    return JornadaTotalBodega(
      bodega: json['bodega'] ?? '',
      producto: json['producto'] ?? '',
      totalPeso: _parseDouble(json['total_peso']),
      totalViajes: json['total_viajes'] ?? 0,
      totalBags: json['total_bags'] ?? 0,
    );
  }
}

/// Total por almacen
class JornadaTotalAlmacen {
  final String almacen;
  final String producto;
  final double totalPeso;
  final int totalViajes;
  final int totalBags;

  const JornadaTotalAlmacen({
    required this.almacen,
    required this.producto,
    this.totalPeso = 0,
    this.totalViajes = 0,
    this.totalBags = 0,
  });

  factory JornadaTotalAlmacen.fromJson(Map<String, dynamic> json) {
    return JornadaTotalAlmacen(
      almacen: json['almacen'] ?? '',
      producto: json['producto'] ?? '',
      totalPeso: _parseDouble(json['total_peso']),
      totalViajes: json['total_viajes'] ?? 0,
      totalBags: json['total_bags'] ?? 0,
    );
  }
}

/// Saldo por bodega
class JornadaSaldoBodega {
  final String bodega;
  final double saldo;
  final int saldoBags;

  const JornadaSaldoBodega({
    required this.bodega,
    this.saldo = 0,
    this.saldoBags = 0,
  });

  factory JornadaSaldoBodega.fromJson(Map<String, dynamic> json) {
    return JornadaSaldoBodega(
      bodega: json['bodega'] ?? '',
      saldo: _parseDouble(json['saldo']),
      saldoBags: json['saldo_bags'] ?? 0,
    );
  }
}

/// Saldo por almacen
class JornadaSaldoAlmacen {
  final String almacen;
  final double saldo;
  final int saldoBags;

  const JornadaSaldoAlmacen({
    required this.almacen,
    this.saldo = 0,
    this.saldoBags = 0,
  });

  factory JornadaSaldoAlmacen.fromJson(Map<String, dynamic> json) {
    return JornadaSaldoAlmacen(
      almacen: json['almacen'] ?? '',
      saldo: _parseDouble(json['saldo']),
      saldoBags: json['saldo_bags'] ?? 0,
    );
  }
}

/// Respuesta completa del endpoint resumen_jornadas
class ResumenJornadas {
  final List<JornadaCabeceraBodega> cabecerasBodega;
  final List<JornadaCabeceraAlmacen> cabecerasAlmacen;
  final List<JornadaResumen> jornadas;
  final List<JornadaTotalBodega> totalesBodega;
  final List<JornadaTotalAlmacen> totalesAlmacen;
  final List<JornadaSaldoBodega> saldosBodega;
  final List<JornadaSaldoAlmacen> saldosAlmacen;
  // Totales generales
  final double totalPesoBodega;
  final int totalViajesBodega;
  final int totalBagsBodega;
  final double totalPesoAlmacen;
  final int totalViajesAlmacen;
  final int totalBagsAlmacen;
  // Totales manifestados
  final double totalManifestadoBodega;
  final int totalBagsManifestadosBodega;
  final double totalManifestadoAlmacen;
  final int totalBagsManifestadosAlmacen;
  // Saldos totales
  final double saldoTotalBodega;
  final int saldoTotalBagsBodega;
  final double saldoTotalAlmacen;
  final int saldoTotalBagsAlmacen;

  const ResumenJornadas({
    this.cabecerasBodega = const [],
    this.cabecerasAlmacen = const [],
    this.jornadas = const [],
    this.totalesBodega = const [],
    this.totalesAlmacen = const [],
    this.saldosBodega = const [],
    this.saldosAlmacen = const [],
    this.totalPesoBodega = 0,
    this.totalViajesBodega = 0,
    this.totalBagsBodega = 0,
    this.totalPesoAlmacen = 0,
    this.totalViajesAlmacen = 0,
    this.totalBagsAlmacen = 0,
    this.totalManifestadoBodega = 0,
    this.totalBagsManifestadosBodega = 0,
    this.totalManifestadoAlmacen = 0,
    this.totalBagsManifestadosAlmacen = 0,
    this.saldoTotalBodega = 0,
    this.saldoTotalBagsBodega = 0,
    this.saldoTotalAlmacen = 0,
    this.saldoTotalBagsAlmacen = 0,
  });

  factory ResumenJornadas.fromJson(Map<String, dynamic> json) {
    return ResumenJornadas(
      cabecerasBodega: (json['cabeceras_bodega'] as List?)
              ?.map((e) => JornadaCabeceraBodega.fromJson(e))
              .toList() ??
          [],
      cabecerasAlmacen: (json['cabeceras_almacen'] as List?)
              ?.map((e) => JornadaCabeceraAlmacen.fromJson(e))
              .toList() ??
          [],
      jornadas: (json['jornadas'] as List?)
              ?.map((e) => JornadaResumen.fromJson(e))
              .toList() ??
          [],
      totalesBodega: (json['totales_bodega'] as List?)
              ?.map((e) => JornadaTotalBodega.fromJson(e))
              .toList() ??
          [],
      totalesAlmacen: (json['totales_almacen'] as List?)
              ?.map((e) => JornadaTotalAlmacen.fromJson(e))
              .toList() ??
          [],
      saldosBodega: (json['saldos_bodega'] as List?)
              ?.map((e) => JornadaSaldoBodega.fromJson(e))
              .toList() ??
          [],
      saldosAlmacen: (json['saldos_almacen'] as List?)
              ?.map((e) => JornadaSaldoAlmacen.fromJson(e))
              .toList() ??
          [],
      totalPesoBodega: _parseDouble(json['total_peso_bodega']),
      totalViajesBodega: json['total_viajes_bodega'] ?? 0,
      totalBagsBodega: json['total_bags_bodega'] ?? 0,
      totalPesoAlmacen: _parseDouble(json['total_peso_almacen']),
      totalViajesAlmacen: json['total_viajes_almacen'] ?? 0,
      totalBagsAlmacen: json['total_bags_almacen'] ?? 0,
      totalManifestadoBodega: _parseDouble(json['total_manifestado_bodega']),
      totalBagsManifestadosBodega: json['total_bags_manifestados_bodega'] ?? 0,
      totalManifestadoAlmacen: _parseDouble(json['total_manifestado_almacen']),
      totalBagsManifestadosAlmacen: json['total_bags_manifestados_almacen'] ?? 0,
      saldoTotalBodega: _parseDouble(json['saldo_total_bodega']),
      saldoTotalBagsBodega: json['saldo_total_bags_bodega'] ?? 0,
      saldoTotalAlmacen: _parseDouble(json['saldo_total_almacen']),
      saldoTotalBagsAlmacen: json['saldo_total_bags_almacen'] ?? 0,
    );
  }

  bool get hasData => cabecerasBodega.isNotEmpty || cabecerasAlmacen.isNotEmpty;
}
