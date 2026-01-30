// =============================================================================
// PROVIDERS PARA GRANELES
// =============================================================================
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/base_provider_imp.dart';
import 'package:stampcamera/services/graneles/graneles_service.dart';
import 'package:stampcamera/models/graneles/servicio_granel_model.dart';

// ===========================================================================
// SERVICE PROVIDERS
// ===========================================================================

final ticketMuelleServiceProvider = Provider<TicketMuelleService>((ref) {
  return TicketMuelleService();
});

final serviciosGranelesServiceProvider = Provider<ServiciosGranelesService>((ref) {
  return ServiciosGranelesService();
});

final balanzaServiceProvider = Provider<BalanzaService>((ref) {
  return BalanzaService();
});

final silosServiceProvider = Provider<SilosService>((ref) {
  return SilosService();
});

final almacenServiceProvider = Provider<AlmacenService>((ref) {
  return AlmacenService();
});

// ===========================================================================
// FILTROS DE PENDIENTES
// ===========================================================================

/// Filtro para mostrar solo tickets pendientes (sin balanza)
final ticketsPendientesFilterProvider = StateProvider<bool>((ref) => false);

/// Filtro para mostrar solo balanzas pendientes (sin almacén)
final balanzasPendientesFilterProvider = StateProvider<bool>((ref) => false);

// ===========================================================================
// SERVICIOS DE GRANELES (con paginación)
// ===========================================================================

/// Provider principal para servicios de graneles con paginación
final serviciosGranelesProvider =
    AsyncNotifierProvider<ServiciosGranelesNotifier, List<ServicioGranel>>(
  ServiciosGranelesNotifier.new,
);

/// Notifier para servicios de graneles - implementa BaseListProviderImpl
class ServiciosGranelesNotifier extends BaseListProviderImpl<ServicioGranel> {
  @override
  ServiciosGranelesService get service => ref.read(serviciosGranelesServiceProvider);
  // NO sobrescribir loadInitial - usar el del base que setea _nextUrl
}

/// Provider para servicio seleccionado
final servicioSeleccionadoProvider = StateProvider<ServicioGranel?>((ref) => null);

/// Provider para dashboard del servicio
final servicioDashboardProvider =
    FutureProvider.autoDispose.family<ServicioDashboard, int>((ref, servicioId) async {
  final service = ref.watch(serviciosGranelesServiceProvider);
  return service.getDashboard(servicioId);
});

/// Provider para permisos del usuario en módulo graneles
/// Cachea los permisos para evitar llamadas repetidas
final userGranelesPermissionsProvider =
    FutureProvider<UserGranelesPermissions>((ref) async {
  final service = ref.watch(serviciosGranelesServiceProvider);
  try {
    return await service.getUserPermissions();
  } catch (e) {
    // Si falla, retornar permisos por defecto (todo visible para no bloquear al usuario)
    return UserGranelesPermissions.defaults();
  }
});

// ===========================================================================
// TICKETS MUELLE - PROVIDER CON PAGINACIÓN Y BÚSQUEDA
// ===========================================================================

/// Provider principal para tickets de muelle con paginación
final ticketsMuelleProvider =
    AsyncNotifierProvider<TicketMuelleNotifier, List<TicketMuelle>>(
  TicketMuelleNotifier.new,
);

/// Notifier para tickets de muelle - implementa BaseListProviderImpl
class TicketMuelleNotifier extends BaseListProviderImpl<TicketMuelle> {
  int? _servicioId;
  bool _filterSinBalanza = false;

  @override
  TicketMuelleService get service => ref.read(ticketMuelleServiceProvider);

  /// Establecer el servicio ID para filtrar los tickets
  void setServicioId(int? servicioId) {
    if (_servicioId == servicioId) return;
    _servicioId = servicioId;
    service.setServicioId(servicioId);
    _reloadWithCurrentFilters();
  }

  /// Obtener el servicio ID actual
  int? get servicioId => _servicioId;

  /// Estado actual del filtro sin balanza
  bool get filterSinBalanza => _filterSinBalanza;

  /// Filtrar por tickets sin balanza (server-side)
  void setFilterSinBalanza(bool value) {
    if (_filterSinBalanza == value) return;
    _filterSinBalanza = value;
    _reloadWithCurrentFilters();
  }

  /// Recargar con los filtros actuales (usa listWithFilters que SÍ setea _searchNextUrl)
  void _reloadWithCurrentFilters() {
    if (_filterSinBalanza) {
      listWithFilters({'sin_balanza': 'true'});
    } else {
      // Limpiar filtro y recargar normal (esto llama al loadInitial del base)
      clearSearch();
    }
  }

  // NO sobrescribir loadInitial - usar el del base que setea _nextUrl correctamente

  /// Crear ticket con foto
  Future<TicketMuelle?> createTicket({
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
    final ticket = await service.createTicket(
      numeroTicket: numeroTicket,
      blId: blId,
      distribucionId: distribucionId,
      placaId: placaId,
      transporteId: transporteId,
      inicioDescarga: inicioDescarga,
      finDescarga: finDescarga,
      observaciones: observaciones,
      foto: foto,
    );

    // Agregar al inicio de la lista
    final current = state.value ?? [];
    state = AsyncValue.data([ticket, ...current]);

    return ticket;
  }

  /// Actualizar ticket existente
  Future<TicketMuelle?> updateTicket({
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
    final ticket = await service.updateTicket(
      ticketId: ticketId,
      numeroTicket: numeroTicket,
      blId: blId,
      distribucionId: distribucionId,
      placaId: placaId,
      transporteId: transporteId,
      inicioDescarga: inicioDescarga,
      finDescarga: finDescarga,
      observaciones: observaciones,
      foto: foto,
    );

    // Actualizar en la lista
    final current = state.value ?? [];
    final updatedList = current.map((t) => t.id == ticketId ? ticket : t).toList();
    state = AsyncValue.data(updatedList);

    return ticket;
  }
}

/// Parámetros para obtener opciones de formulario de ticket
class TicketFormOptionsParams {
  final int? servicioId;
  final int? ticketId;
  final int? embarqueId;  // Para filtrar BLs por la nave de la asistencia activa

  const TicketFormOptionsParams({this.servicioId, this.ticketId, this.embarqueId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketFormOptionsParams &&
          runtimeType == other.runtimeType &&
          servicioId == other.servicioId &&
          ticketId == other.ticketId &&
          embarqueId == other.embarqueId;

  @override
  int get hashCode => servicioId.hashCode ^ ticketId.hashCode ^ embarqueId.hashCode;
}

/// Provider para opciones del formulario de ticket (NUEVO - con parámetros flexibles)
final ticketMuelleOptionsFlexProvider =
    FutureProvider.autoDispose.family<TicketMuelleOptions, TicketFormOptionsParams>((ref, params) async {
  final service = ref.watch(ticketMuelleServiceProvider);
  return service.getFormOptions(
    servicioId: params.servicioId,
    ticketId: params.ticketId,
    embarqueId: params.embarqueId,
  );
});

/// Provider para opciones del formulario de ticket (LEGACY - mantener compatibilidad)
final ticketMuelleOptionsProvider =
    FutureProvider.autoDispose.family<TicketMuelleOptions, int>((ref, servicioId) async {
  final service = ref.watch(ticketMuelleServiceProvider);
  return service.getFormOptions(servicioId: servicioId);
});

/// Provider para detalle de un ticket específico
final ticketMuelleDetalleProvider =
    FutureProvider.autoDispose.family<TicketMuelle, int>((ref, ticketId) async {
  final service = ref.watch(ticketMuelleServiceProvider);
  return service.retrieve(ticketId);
});

// ===========================================================================
// BALANZAS - PROVIDER CON PAGINACIÓN Y BÚSQUEDA (como Tickets)
// ===========================================================================

/// Provider principal para balanzas con paginación
final balanzasListProvider =
    AsyncNotifierProvider<BalanzaNotifier, List<Balanza>>(
  BalanzaNotifier.new,
);

/// Notifier para balanzas - implementa BaseListProviderImpl
class BalanzaNotifier extends BaseListProviderImpl<Balanza> {
  bool _filterSinAlmacen = false;

  @override
  BalanzaService get service => ref.read(balanzaServiceProvider);

  /// Estado actual del filtro sin almacén
  bool get filterSinAlmacen => _filterSinAlmacen;

  /// Filtrar por balanzas sin almacén (server-side)
  void setFilterSinAlmacen(bool value) {
    if (_filterSinAlmacen == value) return;
    _filterSinAlmacen = value;
    _reloadWithCurrentFilters();
  }

  /// Recargar con los filtros actuales (usa listWithFilters que SÍ setea _searchNextUrl)
  void _reloadWithCurrentFilters() {
    if (_filterSinAlmacen) {
      listWithFilters({'sin_almacen': 'true'});
    } else {
      // Limpiar filtro y recargar normal (esto llama al loadInitial del base)
      clearSearch();
    }
  }

  // NO sobrescribir loadInitial - usar el del base que setea _nextUrl correctamente
}

/// Provider para lista de balanzas por servicio (legacy - mantener compatibilidad)
final balanzasProvider =
    FutureProvider.autoDispose.family<List<Balanza>, int>((ref, servicioId) async {
  final service = ref.watch(balanzaServiceProvider);
  final response = await service.getByServicio(servicioId);
  return response.results;
});

/// Provider para opciones del formulario de balanza
final balanzaOptionsProvider =
    FutureProvider.autoDispose.family<BalanzaOptions, int>((ref, servicioId) async {
  final service = ref.watch(balanzaServiceProvider);
  return service.getFormOptions(servicioId);
});

/// Provider para detalle de una balanza
final balanzaDetalleProvider =
    FutureProvider.autoDispose.family<Balanza, int>((ref, balanzaId) async {
  final service = ref.watch(balanzaServiceProvider);
  return service.retrieve(balanzaId);
});

// ===========================================================================
// SILOS - PROVIDER CON PAGINACIÓN Y BÚSQUEDA (como Tickets)
// ===========================================================================

/// Provider principal para silos con paginación
final silosListProvider =
    AsyncNotifierProvider<SilosNotifier, List<Silos>>(
  SilosNotifier.new,
);

/// Notifier para silos - implementa BaseListProviderImpl
class SilosNotifier extends BaseListProviderImpl<Silos> {
  @override
  SilosService get service => ref.read(silosServiceProvider);
  // Ordenamiento se hace en SilosService.list()
}

/// Provider para lista de silos por servicio (legacy - mantener compatibilidad)
final silosProvider =
    FutureProvider.autoDispose.family<List<Silos>, int>((ref, servicioId) async {
  final service = ref.watch(silosServiceProvider);
  final response = await service.getByServicio(servicioId);
  return response.results;
});

/// Parámetros para obtener opciones del formulario de silos
class SilosFormOptionsParams {
  final int? embarqueId;  // ID de la nave para filtrar BLs
  final int? blId;        // ID del BL para cargar distribuciones y jornadas

  const SilosFormOptionsParams({this.embarqueId, this.blId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SilosFormOptionsParams &&
          runtimeType == other.runtimeType &&
          embarqueId == other.embarqueId &&
          blId == other.blId;

  @override
  int get hashCode => embarqueId.hashCode ^ blId.hashCode;
}

/// Provider para opciones del formulario de silos
final silosOptionsProvider =
    FutureProvider.autoDispose.family<SilosOptions, SilosFormOptionsParams>((ref, params) async {
  final service = ref.watch(silosServiceProvider);
  return service.getFormOptions(
    embarqueId: params.embarqueId,
    blId: params.blId,
  );
});

// ===========================================================================
// ALMACÉN - PROVIDER CON PAGINACIÓN Y BÚSQUEDA (como Tickets)
// ===========================================================================

/// Provider principal para almacén con paginación
final almacenListProvider =
    AsyncNotifierProvider<AlmacenNotifier, List<AlmacenGranel>>(
  AlmacenNotifier.new,
);

/// Notifier para almacén - implementa BaseListProviderImpl
class AlmacenNotifier extends BaseListProviderImpl<AlmacenGranel> {
  @override
  AlmacenService get service => ref.read(almacenServiceProvider);
  // NO sobrescribir loadInitial - usar el del base que setea _nextUrl
}

/// Provider para detalle de un almacén
final almacenDetalleProvider =
    FutureProvider.autoDispose.family<AlmacenGranel, int>((ref, almacenId) async {
  final service = ref.watch(almacenServiceProvider);
  return service.retrieve(almacenId);
});

// ===========================================================================
// NOTIFIER PARA OPERACIONES DE FORMULARIO
// ===========================================================================

/// Estado del formulario de graneles
class GranelesFormState {
  final bool isLoading;
  final String? error;
  final bool success;

  const GranelesFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  GranelesFormState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return GranelesFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Notifier para operaciones de formulario de Graneles
class GranelesFormNotifier extends StateNotifier<GranelesFormState> {
  final TicketMuelleService _ticketService;

  GranelesFormNotifier(this._ticketService) : super(const GranelesFormState());

  /// Crear ticket de muelle
  Future<TicketMuelle?> createTicketMuelle({
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
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      final ticket = await _ticketService.createTicket(
        numeroTicket: numeroTicket,
        blId: blId,
        distribucionId: distribucionId,
        placaId: placaId,
        transporteId: transporteId,
        inicioDescarga: inicioDescarga,
        finDescarga: finDescarga,
        observaciones: observaciones,
        foto: foto,
      );
      state = state.copyWith(isLoading: false, success: true);
      return ticket;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Resetear estado
  void reset() {
    state = const GranelesFormState();
  }
}

/// Provider para el notifier de operaciones de formulario
final granelesFormProvider =
    StateNotifierProvider.autoDispose<GranelesFormNotifier, GranelesFormState>((ref) {
  final service = ref.watch(ticketMuelleServiceProvider);
  return GranelesFormNotifier(service);
});
