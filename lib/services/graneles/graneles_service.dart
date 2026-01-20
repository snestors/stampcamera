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
    final response = await _http.dio.get(url);
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
  Future<TicketMuelleOptions> getFormOptions(int servicioId) async {
    final response = await _http.dio.get(
      '${endpoint}options_form/',
      queryParameters: {'servicio_id': servicioId},
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
    final response = await _http.dio.get(url);
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
}

// =============================================================================
// SERVICIO DE BALANZAS
// =============================================================================

class BalanzaService {
  final HttpService _http;

  BalanzaService([HttpService? http]) : _http = http ?? HttpService();

  String get endpoint => '/api/v1/graneles/balanzas/';

  Future<PaginatedResponse<Balanza>> getByServicio(int servicioId) async {
    final response = await _http.dio.get(
      endpoint,
      queryParameters: {'servicio_id': servicioId},
    );
    return PaginatedResponse.fromJson(response.data, Balanza.fromJson);
  }

  Future<Balanza> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return Balanza.fromJson(response.data);
  }

  Future<BalanzaOptions> getFormOptions(int servicioId) async {
    final response = await _http.dio.get(
      '${endpoint}options_form/',
      queryParameters: {'servicio_id': servicioId},
    );
    return BalanzaOptions.fromJson(response.data);
  }
}

// =============================================================================
// SERVICIO DE SILOS
// =============================================================================

class SilosService {
  final HttpService _http;

  SilosService([HttpService? http]) : _http = http ?? HttpService();

  String get endpoint => '/api/v1/graneles/silos/';

  Future<PaginatedResponse<Silos>> getByServicio(int servicioId) async {
    final response = await _http.dio.get(
      endpoint,
      queryParameters: {'servicio_id': servicioId},
    );
    return PaginatedResponse.fromJson(response.data, Silos.fromJson);
  }

  Future<Silos> retrieve(int id) async {
    final response = await _http.dio.get('$endpoint$id/');
    return Silos.fromJson(response.data);
  }
}
