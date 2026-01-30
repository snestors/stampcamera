// =============================================================================
// SERVICE PARA API DE GRANELES
// =============================================================================
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:stampcamera/core/base_service.dart';
import 'package:stampcamera/models/paginated_response.dart';
import 'package:stampcamera/services/http_service.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';

// =============================================================================
// SERVICIO DE TICKETS MUELLE (implementa BaseService para paginación)
// =============================================================================

class TicketMuelleService implements BaseService<TicketMuelle> {
  final HttpService _http;
  int? _currentServicioId;

  TicketMuelleService([HttpService? http]) : _http = http ?? HttpService();

  @override
  String get endpoint => '/api/v1/graneles/tickets-muelle/';

  @override
  TicketMuelle Function(Map<String, dynamic>) get fromJson => TicketMuelle.fromJson;

  /// Establecer el servicio actual para filtrar
  void setServicioId(int? servicioId) {
    _currentServicioId = servicioId;
  }

  @override
  Future<PaginatedResponse<TicketMuelle>> list({Map<String, dynamic>? queryParameters}) async {
    final params = <String, dynamic>{...?queryParameters};
    if (_currentServicioId != null) {
      params['servicio_id'] = _currentServicioId;
    }
    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<TicketMuelle>> search(String query, {Map<String, dynamic>? filters}) async {
    final params = <String, dynamic>{'search': query};
    if (_currentServicioId != null) {
      params['servicio_id'] = _currentServicioId;
    }
    if (filters != null) params.addAll(filters);
    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<TicketMuelle>> loadMore(String url) async {
    // Extraer solo el path de la URL (DRF retorna URLs completas)
    final uri = Uri.parse(url);
    final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    final response = await _http.dio.get(path);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<TicketMuelle> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return fromJson(response.data);
  }

  @override
  Future<TicketMuelle> create(Map<String, dynamic> data) async {
    final response = await _http.dio.post(endpoint, data: data);
    return fromJson(response.data);
  }

  @override
  Future<TicketMuelle> update(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.put('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<TicketMuelle> partialUpdate(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.patch('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<void> delete(int id) async {
    await _http.dio.delete('$endpoint$id/');
  }

  @override
  Future<Map<String, dynamic>> executeAction(String action, {int? id, Map<String, dynamic>? data}) async {
    final url = id != null ? '$endpoint$id/$action/' : '$endpoint$action/';
    final response = await _http.dio.post(url, data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAction(String action, {Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get('$endpoint$action/', queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<TicketMuelle> createWithFiles(Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.post(endpoint, data: formData);
    return fromJson(response.data);
  }

  @override
  Future<TicketMuelle> updateWithFiles(int id, Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.patch('$endpoint$id/', data: formData);
    return fromJson(response.data);
  }

  // ===========================================================================
  // MÉTODOS ESPECÍFICOS
  // ===========================================================================

  /// Obtener opciones para formulario
  ///
  /// Parámetros opcionales:
  /// - [servicioId]: ID del servicio para filtrar BLs y distribuciones
  /// - [ticketId]: ID del ticket que se está editando (incluye BLs de su nave aunque no esté en operación)
  /// - [embarqueId]: ID del embarque (nave) de la asistencia activa para filtrar BLs
  ///
  /// Si no se pasa ningún parámetro, retorna BLs de todas las naves en operación (estatus 03/04)
  Future<TicketMuelleOptions> getFormOptions({int? servicioId, int? ticketId, int? embarqueId}) async {
    final queryParams = <String, dynamic>{};
    if (servicioId != null) queryParams['servicio_id'] = servicioId;
    if (ticketId != null) queryParams['ticket_id'] = ticketId;
    if (embarqueId != null) queryParams['embarque_id'] = embarqueId;

    final response = await _http.dio.get(
      '${endpoint}options_form/',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return TicketMuelleOptions.fromJson(response.data);
  }

  /// Buscar placas por número
  Future<List<OptionItem>> searchPlacas(String query) async {
    if (query.length < 2) return [];
    final response = await _http.dio.get(
      '${endpoint}search_placas/',
      queryParameters: {'q': query},
    );
    return (response.data['results'] as List)
        .map((e) => OptionItem.fromJson(e))
        .toList();
  }

  /// Buscar tickets sin balanza (global, sin necesidad de servicioId)
  Future<PaginatedResponse<TicketMuelle>> getTicketsSinBalanza({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _http.dio.get(
      '${endpoint}sin_balanza/',
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(response.data, TicketMuelle.fromJson);
  }

  /// Buscar transportes por nombre o RUC
  Future<List<OptionItem>> searchTransportes(String query) async {
    if (query.length < 2) return [];
    final response = await _http.dio.get(
      '${endpoint}search_transportes/',
      queryParameters: {'q': query},
    );
    return (response.data['results'] as List)
        .map((e) => OptionItem.fromJson(e))
        .toList();
  }

  /// Crear ticket con foto
  Future<TicketMuelle> createTicket({
    required String numeroTicket,
    required int blId,
    required int distribucionId,
    int? placaId,
    int? transporteId,
    required DateTime inicioDescarga,
    required DateTime finDescarga,
    String? observaciones,
    File? foto,
  }) async {
    final formData = FormData.fromMap({
      'numero_ticket': numeroTicket,
      'bl': blId,
      'distribucion': distribucionId,
      if (placaId != null) 'placa': placaId,
      if (transporteId != null) 'transporte': transporteId,
      'inicio_descarga': inicioDescarga.toIso8601String(),
      'fin_descarga': finDescarga.toIso8601String(),
      if (observaciones != null) 'observaciones': observaciones,
      if (foto != null)
        'foto': await MultipartFile.fromFile(
          foto.path,
          filename: 'ticket_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
    });

    final response = await _http.dio.post(endpoint, data: formData);
    return fromJson(response.data);
  }

  /// Actualizar ticket existente
  Future<TicketMuelle> updateTicket({
    required int ticketId,
    String? numeroTicket,
    int? blId,
    int? distribucionId,
    int? placaId,
    int? transporteId,
    DateTime? inicioDescarga,
    DateTime? finDescarga,
    String? observaciones,
    File? foto,
  }) async {
    final Map<String, dynamic> data = {};

    if (numeroTicket != null) data['numero_ticket'] = numeroTicket;
    if (blId != null) data['bl'] = blId;
    if (distribucionId != null) data['distribucion'] = distribucionId;
    if (placaId != null) data['placa'] = placaId;
    if (transporteId != null) data['transporte'] = transporteId;
    if (inicioDescarga != null) data['inicio_descarga'] = inicioDescarga.toIso8601String();
    if (finDescarga != null) data['fin_descarga'] = finDescarga.toIso8601String();
    if (observaciones != null) data['observaciones'] = observaciones;

    if (foto != null) {
      final formData = FormData.fromMap({
        ...data,
        'foto': await MultipartFile.fromFile(
          foto.path,
          filename: 'ticket_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final response = await _http.dio.patch('$endpoint$ticketId/', data: formData);
      return fromJson(response.data);
    }

    final response = await _http.dio.patch('$endpoint$ticketId/', data: data);
    return fromJson(response.data);
  }
}

// =============================================================================
// SERVICIO DE SERVICIOS GRANELES (con paginación)
// =============================================================================

class ServiciosGranelesService implements BaseService<ServicioGranel> {
  final HttpService _http;

  ServiciosGranelesService([HttpService? http]) : _http = http ?? HttpService();

  @override
  String get endpoint => '/api/v1/graneles/servicios/';

  @override
  ServicioGranel Function(Map<String, dynamic>) get fromJson => ServicioGranel.fromJson;

  @override
  Future<PaginatedResponse<ServicioGranel>> list({Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get(endpoint, queryParameters: queryParameters);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<ServicioGranel>> search(String query, {Map<String, dynamic>? filters}) async {
    final params = <String, dynamic>{'search': query};
    if (filters != null) params.addAll(filters);
    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<ServicioGranel>> loadMore(String url) async {
    // Extraer solo el path de la URL (DRF retorna URLs completas)
    final uri = Uri.parse(url);
    final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    final response = await _http.dio.get(path);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<ServicioGranel> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return fromJson(response.data);
  }

  @override
  Future<ServicioGranel> create(Map<String, dynamic> data) async {
    final response = await _http.dio.post(endpoint, data: data);
    return fromJson(response.data);
  }

  @override
  Future<ServicioGranel> update(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.put('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<ServicioGranel> partialUpdate(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.patch('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<void> delete(int id) async {
    await _http.dio.delete('$endpoint$id/');
  }

  @override
  Future<Map<String, dynamic>> executeAction(String action, {int? id, Map<String, dynamic>? data}) async {
    final url = id != null ? '$endpoint$id/$action/' : '$endpoint$action/';
    final response = await _http.dio.post(url, data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAction(String action, {Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get('$endpoint$action/', queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<ServicioGranel> createWithFiles(Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.post(endpoint, data: formData);
    return fromJson(response.data);
  }

  @override
  Future<ServicioGranel> updateWithFiles(int id, Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.patch('$endpoint$id/', data: formData);
    return fromJson(response.data);
  }

  /// Obtener dashboard del servicio
  Future<ServicioDashboard> getDashboard(int servicioId) async {
    final response = await _http.dio.get('$endpoint$servicioId/dashboard/');
    return ServicioDashboard.fromJson(response.data);
  }

  /// Obtener permisos del usuario para módulo graneles
  Future<UserGranelesPermissions> getUserPermissions() async {
    final response = await _http.dio.get('${endpoint}user_permissions/');
    return UserGranelesPermissions.fromJson(response.data);
  }
}

// =============================================================================
// MODELO PARA PERMISOS DE USUARIO EN GRANELES
// =============================================================================

class TabPermission {
  final bool visible;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;

  TabPermission({
    required this.visible,
    required this.canAdd,
    required this.canEdit,
    this.canDelete = false,
  });

  factory TabPermission.fromJson(Map<String, dynamic> json) => TabPermission(
    visible: json['visible'] ?? false,
    canAdd: json['can_add'] ?? false,
    canEdit: json['can_edit'] ?? false,
    canDelete: json['can_delete'] ?? false,
  );

  factory TabPermission.hidden() => TabPermission(
    visible: false,
    canAdd: false,
    canEdit: false,
    canDelete: false,
  );
}

class UserGranelesPermissions {
  final bool isSuperuser;
  final List<String> groups;
  final String? zonaTipo;
  final int? naveId;
  final String? naveNombre;
  final bool tieneNaveGraneles;
  final TabPermission servicios;
  final TabPermission muelle;
  final TabPermission balanza;
  final TabPermission almacen;
  final TabPermission silos;

  UserGranelesPermissions({
    required this.isSuperuser,
    required this.groups,
    this.zonaTipo,
    this.naveId,
    this.naveNombre,
    this.tieneNaveGraneles = false,
    required this.servicios,
    required this.muelle,
    required this.balanza,
    required this.almacen,
    required this.silos,
  });

  factory UserGranelesPermissions.fromJson(Map<String, dynamic> json) {
    final tabs = json['tabs'] as Map<String, dynamic>? ?? {};
    return UserGranelesPermissions(
      isSuperuser: json['is_superuser'] ?? false,
      groups: (json['groups'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      zonaTipo: json['zona_tipo'],
      naveId: json['nave_id'],
      naveNombre: json['nave_nombre'],
      tieneNaveGraneles: json['tiene_nave_graneles'] ?? false,
      servicios: TabPermission.fromJson(tabs['servicios'] ?? {}),
      muelle: TabPermission.fromJson(tabs['muelle'] ?? {}),
      balanza: TabPermission.fromJson(tabs['balanza'] ?? {}),
      almacen: TabPermission.fromJson(tabs['almacen'] ?? {}),
      silos: TabPermission.fromJson(tabs['silos'] ?? {}),
    );
  }

  /// Permisos por defecto (restrictivos - solo ver, no editar)
  /// Se usan cuando los permisos aún no han cargado o hay error
  factory UserGranelesPermissions.defaults() => UserGranelesPermissions(
    isSuperuser: false,
    groups: [],
    zonaTipo: null,
    naveId: null,
    naveNombre: null,
    tieneNaveGraneles: false,
    servicios: TabPermission(visible: true, canAdd: false, canEdit: false),
    muelle: TabPermission(visible: true, canAdd: false, canEdit: false),
    balanza: TabPermission(visible: true, canAdd: false, canEdit: false),
    almacen: TabPermission(visible: true, canAdd: false, canEdit: false),
    silos: TabPermission(visible: true, canAdd: false, canEdit: false),
  );

  /// Lista de tabs visibles (en orden)
  List<String> get visibleTabs {
    final tabs = <String>[];
    if (servicios.visible) tabs.add('servicios');
    if (muelle.visible) tabs.add('muelle');
    if (balanza.visible) tabs.add('balanza');
    if (almacen.visible) tabs.add('almacen');
    if (silos.visible) tabs.add('silos');
    return tabs;
  }

  bool get isCoordinacion => groups.contains('COORDINACION GRANELES') || groups.contains('COORDINACION');
  bool get isInspector => groups.contains('INSPECTOR');
  bool get isGestor => groups.contains('GESTORES');
}

// =============================================================================
// SERVICIO DE BALANZAS (implementa BaseService para paginación)
// =============================================================================

class BalanzaService implements BaseService<Balanza> {
  final HttpService _http;

  BalanzaService([HttpService? http]) : _http = http ?? HttpService();

  @override
  String get endpoint => '/api/v1/graneles/balanzas/';

  @override
  Balanza Function(Map<String, dynamic>) get fromJson => Balanza.fromJson;

  @override
  Future<PaginatedResponse<Balanza>> list({Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get(endpoint, queryParameters: queryParameters);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<Balanza>> search(String query, {Map<String, dynamic>? filters}) async {
    final params = <String, dynamic>{'search': query};
    if (filters != null) params.addAll(filters);
    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<Balanza>> loadMore(String url) async {
    // Extraer solo el path de la URL (DRF retorna URLs completas)
    final uri = Uri.parse(url);
    final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    final response = await _http.dio.get(path);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<Balanza> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return fromJson(response.data);
  }

  @override
  Future<Balanza> create(Map<String, dynamic> data) async {
    final response = await _http.dio.post(endpoint, data: data);
    return fromJson(response.data);
  }

  @override
  Future<Balanza> update(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.put('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<Balanza> partialUpdate(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.patch('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<void> delete(int id) async {
    await _http.dio.delete('$endpoint$id/');
  }

  @override
  Future<Map<String, dynamic>> executeAction(String action, {int? id, Map<String, dynamic>? data}) async {
    final url = id != null ? '$endpoint$id/$action/' : '$endpoint$action/';
    final response = await _http.dio.post(url, data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAction(String action, {Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get('$endpoint$action/', queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<Balanza> createWithFiles(Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.post(endpoint, data: formData);
    return fromJson(response.data);
  }

  @override
  Future<Balanza> updateWithFiles(int id, Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.patch('$endpoint$id/', data: formData);
    return fromJson(response.data);
  }

  // ===========================================================================
  // MÉTODOS ESPECÍFICOS DE BALANZA
  // ===========================================================================

  /// Buscar balanzas sin almacén (global, sin necesidad de servicioId)
  Future<PaginatedResponse<Balanza>> getBalanzasSinAlmacen({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _http.dio.get(
      '${endpoint}sin_almacen/',
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(response.data, Balanza.fromJson);
  }

  Future<PaginatedResponse<Balanza>> getByServicio(int servicioId) async {
    final response = await _http.dio.get(
      endpoint,
      queryParameters: {'servicio_id': servicioId},
    );
    return PaginatedResponse.fromJson(response.data, Balanza.fromJson);
  }

  Future<BalanzaOptions> getFormOptions(int servicioId) async {
    final response = await _http.dio.get(
      '${endpoint}options_form/',
      queryParameters: {'servicio_id': servicioId},
    );
    return BalanzaOptions.fromJson(response.data);
  }

  /// Buscar precintos disponibles (sin ticket asignado)
  Future<List<OptionItem>> buscarPrecintos({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _http.dio.get(
      '${endpoint}buscar_precintos/',
      queryParameters: params,
    );
    return (response.data as List)
        .map((e) => OptionItem.fromJson(e))
        .toList();
  }

  /// Crear registro de balanza
  Future<Balanza> createBalanza({
    required String guia,
    required int ticketId,
    required int distribucionAlmacenId,
    int? precintoId,
    int? permisoId,
    required DateTime fechaEntradaBalanza,
    required DateTime fechaSalidaBalanza,
    String? balanzaEntrada,
    String? balanzaSalida,
    required double pesoBruto,
    required double pesoTara,
    required double pesoNeto,
    int? bags,
    required DateTime fechaEnvioWp,
    String? observaciones,
    File? foto1,
    File? foto2,
  }) async {
    final formData = FormData.fromMap({
      'guia': guia,
      'ticket': ticketId,
      'distribucion_almacen': distribucionAlmacenId,
      if (precintoId != null) 'precinto': precintoId,
      if (permisoId != null) 'permiso': permisoId,
      'fecha_entrada_balanza': fechaEntradaBalanza.toIso8601String(),
      'fecha_salida_balanza': fechaSalidaBalanza.toIso8601String(),
      if (balanzaEntrada != null) 'balanza_entrada': balanzaEntrada,
      if (balanzaSalida != null) 'balanza_salida': balanzaSalida,
      'peso_bruto': pesoBruto,
      'peso_tara': pesoTara,
      'peso_neto': pesoNeto,
      if (bags != null) 'bags': bags,
      'fecha_envio_wp': fechaEnvioWp.toIso8601String(),
      if (observaciones != null) 'observaciones': observaciones,
      if (foto1 != null)
        'foto1': await MultipartFile.fromFile(
          foto1.path,
          filename: 'balanza_${DateTime.now().millisecondsSinceEpoch}_1.jpg',
        ),
      if (foto2 != null)
        'foto2': await MultipartFile.fromFile(
          foto2.path,
          filename: 'balanza_${DateTime.now().millisecondsSinceEpoch}_2.jpg',
        ),
    });

    final response = await _http.dio.post(endpoint, data: formData);
    return Balanza.fromJson(response.data);
  }

  /// Actualizar registro de balanza
  Future<Balanza> updateBalanza({
    required int balanzaId,
    String? guia,
    int? distribucionAlmacenId,
    int? precintoId,
    int? permisoId,
    DateTime? fechaEntradaBalanza,
    DateTime? fechaSalidaBalanza,
    String? balanzaEntrada,
    String? balanzaSalida,
    double? pesoBruto,
    double? pesoTara,
    double? pesoNeto,
    int? bags,
    DateTime? fechaEnvioWp,
    String? observaciones,
    File? foto1,
    File? foto2,
  }) async {
    final Map<String, dynamic> data = {};

    if (guia != null) data['guia'] = guia;
    if (distribucionAlmacenId != null) data['distribucion_almacen'] = distribucionAlmacenId;
    if (precintoId != null) data['precinto'] = precintoId;
    if (permisoId != null) data['permiso'] = permisoId;
    if (fechaEntradaBalanza != null) data['fecha_entrada_balanza'] = fechaEntradaBalanza.toIso8601String();
    if (fechaSalidaBalanza != null) data['fecha_salida_balanza'] = fechaSalidaBalanza.toIso8601String();
    if (balanzaEntrada != null) data['balanza_entrada'] = balanzaEntrada;
    if (balanzaSalida != null) data['balanza_salida'] = balanzaSalida;
    if (pesoBruto != null) data['peso_bruto'] = pesoBruto;
    if (pesoTara != null) data['peso_tara'] = pesoTara;
    if (pesoNeto != null) data['peso_neto'] = pesoNeto;
    if (bags != null) data['bags'] = bags;
    if (fechaEnvioWp != null) data['fecha_envio_wp'] = fechaEnvioWp.toIso8601String();
    if (observaciones != null) data['observaciones'] = observaciones;

    if (foto1 != null || foto2 != null) {
      final formData = FormData.fromMap({
        ...data,
        if (foto1 != null)
          'foto1': await MultipartFile.fromFile(
            foto1.path,
            filename: 'balanza_${DateTime.now().millisecondsSinceEpoch}_1.jpg',
          ),
        if (foto2 != null)
          'foto2': await MultipartFile.fromFile(
            foto2.path,
            filename: 'balanza_${DateTime.now().millisecondsSinceEpoch}_2.jpg',
          ),
      });
      final response = await _http.dio.patch('$endpoint$balanzaId/', data: formData);
      return Balanza.fromJson(response.data);
    }

    final response = await _http.dio.patch('$endpoint$balanzaId/', data: data);
    return Balanza.fromJson(response.data);
  }
}

// =============================================================================
// SERVICIO DE SILOS (implementa BaseService para paginación)
// =============================================================================

class SilosService implements BaseService<Silos> {
  final HttpService _http;

  SilosService([HttpService? http]) : _http = http ?? HttpService();

  @override
  String get endpoint => '/api/v1/graneles/silos/';

  @override
  Silos Function(Map<String, dynamic>) get fromJson => Silos.fromJson;

  @override
  Future<PaginatedResponse<Silos>> list({Map<String, dynamic>? queryParameters}) async {
    // Ordenar por fecha descendente (más reciente primero)
    final params = <String, dynamic>{
      'ordering': '-fecha_pesaje',
      ...?queryParameters,
    };
    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<Silos>> search(String query, {Map<String, dynamic>? filters}) async {
    final params = <String, dynamic>{
      'search': query,
      'ordering': '-fecha_pesaje',  // Mantener ordenamiento en búsqueda
    };
    if (filters != null) params.addAll(filters);
    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<Silos>> loadMore(String url) async {
    // Extraer solo el path de la URL (DRF retorna URLs completas)
    final uri = Uri.parse(url);
    final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    final response = await _http.dio.get(path);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<Silos> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return fromJson(response.data);
  }

  @override
  Future<Silos> create(Map<String, dynamic> data) async {
    final response = await _http.dio.post(endpoint, data: data);
    return fromJson(response.data);
  }

  @override
  Future<Silos> update(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.put('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<Silos> partialUpdate(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.patch('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<void> delete(int id) async {
    await _http.dio.delete('$endpoint$id/');
  }

  @override
  Future<Map<String, dynamic>> executeAction(String action, {int? id, Map<String, dynamic>? data}) async {
    final url = id != null ? '$endpoint$id/$action/' : '$endpoint$action/';
    final response = await _http.dio.post(url, data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAction(String action, {Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get('$endpoint$action/', queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<Silos> createWithFiles(Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.post(endpoint, data: formData);
    return fromJson(response.data);
  }

  @override
  Future<Silos> updateWithFiles(int id, Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.patch('$endpoint$id/', data: formData);
    return fromJson(response.data);
  }

  // ===========================================================================
  // MÉTODOS ESPECÍFICOS DE SILOS
  // ===========================================================================

  Future<PaginatedResponse<Silos>> getByServicio(int servicioId) async {
    final response = await _http.dio.get(
      endpoint,
      queryParameters: {'servicio_id': servicioId},
    );
    return PaginatedResponse.fromJson(response.data, Silos.fromJson);
  }

  /// Obtener opciones para el formulario de silos
  /// [embarqueId] - ID de la nave para filtrar BLs (de asistencia activa)
  /// [blId] - ID del BL para cargar distribuciones y jornadas
  Future<SilosOptions> getFormOptions({int? embarqueId, int? blId}) async {
    final queryParams = <String, dynamic>{};
    if (embarqueId != null) queryParams['embarque_id'] = embarqueId;
    if (blId != null) queryParams['bl_id'] = blId;

    final response = await _http.dio.get(
      '${endpoint}options_form/',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return SilosOptions.fromJson(response.data);
  }
}

// =============================================================================
// SERVICIO DE ALMACÉN (implementa BaseService para paginación)
// =============================================================================

class AlmacenService implements BaseService<AlmacenGranel> {
  final HttpService _http;

  AlmacenService([HttpService? http]) : _http = http ?? HttpService();

  @override
  String get endpoint => '/api/v1/graneles/almacen/';

  @override
  AlmacenGranel Function(Map<String, dynamic>) get fromJson => AlmacenGranel.fromJson;

  @override
  Future<PaginatedResponse<AlmacenGranel>> list({Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get(endpoint, queryParameters: queryParameters);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<AlmacenGranel>> search(String query, {Map<String, dynamic>? filters}) async {
    final params = <String, dynamic>{'search': query};
    if (filters != null) params.addAll(filters);
    final response = await _http.dio.get(endpoint, queryParameters: params);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<PaginatedResponse<AlmacenGranel>> loadMore(String url) async {
    // Extraer solo el path de la URL (DRF retorna URLs completas)
    final uri = Uri.parse(url);
    final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
    final response = await _http.dio.get(path);
    return PaginatedResponse.fromJson(response.data, fromJson);
  }

  @override
  Future<AlmacenGranel> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return fromJson(response.data);
  }

  @override
  Future<AlmacenGranel> create(Map<String, dynamic> data) async {
    final response = await _http.dio.post(endpoint, data: data);
    return fromJson(response.data);
  }

  @override
  Future<AlmacenGranel> update(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.put('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<AlmacenGranel> partialUpdate(int id, Map<String, dynamic> data) async {
    final response = await _http.dio.patch('$endpoint$id/', data: data);
    return fromJson(response.data);
  }

  @override
  Future<void> delete(int id) async {
    await _http.dio.delete('$endpoint$id/');
  }

  @override
  Future<Map<String, dynamic>> executeAction(String action, {int? id, Map<String, dynamic>? data}) async {
    final url = id != null ? '$endpoint$id/$action/' : '$endpoint$action/';
    final response = await _http.dio.post(url, data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getAction(String action, {Map<String, dynamic>? queryParameters}) async {
    final response = await _http.dio.get('$endpoint$action/', queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<AlmacenGranel> createWithFiles(Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.post(endpoint, data: formData);
    return fromJson(response.data);
  }

  @override
  Future<AlmacenGranel> updateWithFiles(int id, Map<String, dynamic> data, Map<String, String> filePaths) async {
    final formData = FormData.fromMap(data);
    for (final entry in filePaths.entries) {
      formData.files.add(MapEntry(
        entry.key,
        await MultipartFile.fromFile(entry.value),
      ));
    }
    final response = await _http.dio.patch('$endpoint$id/', data: formData);
    return fromJson(response.data);
  }

  // ===========================================================================
  // MÉTODOS ESPECÍFICOS DE ALMACÉN
  // ===========================================================================

  /// Crear registro de almacén con fotos
  Future<AlmacenGranel> createAlmacen({
    required int balanzaId,
    required DateTime fechaEntradaAlmacen,
    required DateTime fechaSalidaAlmacen,
    required double pesoBruto,
    required double pesoTara,
    required double pesoNeto,
    int? bags,
    String? observaciones,
    File? foto1,
    File? foto2,
  }) async {
    final formData = FormData.fromMap({
      'balanza': balanzaId,
      'fecha_entrada_almacen': fechaEntradaAlmacen.toIso8601String(),
      'fecha_salida_almacen': fechaSalidaAlmacen.toIso8601String(),
      'peso_bruto': pesoBruto,
      'peso_tara': pesoTara,
      'peso_neto': pesoNeto,
      if (bags != null) 'bags': bags,
      if (observaciones != null) 'observaciones': observaciones,
      if (foto1 != null)
        'foto1': await MultipartFile.fromFile(
          foto1.path,
          filename: 'almacen_${DateTime.now().millisecondsSinceEpoch}_1.jpg',
        ),
      if (foto2 != null)
        'foto2': await MultipartFile.fromFile(
          foto2.path,
          filename: 'almacen_${DateTime.now().millisecondsSinceEpoch}_2.jpg',
        ),
    });

    final response = await _http.dio.post(endpoint, data: formData);
    return AlmacenGranel.fromJson(response.data);
  }

  /// Actualizar registro de almacén
  Future<AlmacenGranel> updateAlmacen({
    required int almacenId,
    DateTime? fechaEntradaAlmacen,
    DateTime? fechaSalidaAlmacen,
    double? pesoBruto,
    double? pesoTara,
    double? pesoNeto,
    int? bags,
    String? observaciones,
    File? foto1,
    File? foto2,
  }) async {
    final Map<String, dynamic> data = {};

    if (fechaEntradaAlmacen != null) data['fecha_entrada_almacen'] = fechaEntradaAlmacen.toIso8601String();
    if (fechaSalidaAlmacen != null) data['fecha_salida_almacen'] = fechaSalidaAlmacen.toIso8601String();
    if (pesoBruto != null) data['peso_bruto'] = pesoBruto;
    if (pesoTara != null) data['peso_tara'] = pesoTara;
    if (pesoNeto != null) data['peso_neto'] = pesoNeto;
    if (bags != null) data['bags'] = bags;
    if (observaciones != null) data['observaciones'] = observaciones;

    if (foto1 != null || foto2 != null) {
      final formData = FormData.fromMap({
        ...data,
        if (foto1 != null)
          'foto1': await MultipartFile.fromFile(
            foto1.path,
            filename: 'almacen_${DateTime.now().millisecondsSinceEpoch}_1.jpg',
          ),
        if (foto2 != null)
          'foto2': await MultipartFile.fromFile(
            foto2.path,
            filename: 'almacen_${DateTime.now().millisecondsSinceEpoch}_2.jpg',
          ),
      });
      final response = await _http.dio.patch('$endpoint$almacenId/', data: formData);
      return AlmacenGranel.fromJson(response.data);
    }

    final response = await _http.dio.patch('$endpoint$almacenId/', data: data);
    return AlmacenGranel.fromJson(response.data);
  }
}
