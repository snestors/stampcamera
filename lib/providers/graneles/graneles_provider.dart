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

  @override
  Future<List<ServicioGranel>> loadInitial() async {
    try {
      final paginated = await service.list();
      return paginated.results;
    } catch (e) {
      throw Exception('Error al cargar servicios: $e');
    }
  }
}

/// Provider para servicio seleccionado
final servicioSeleccionadoProvider = StateProvider<ServicioGranel?>((ref) => null);

/// Provider para dashboard del servicio
final servicioDashboardProvider =
    FutureProvider.autoDispose.family<ServicioDashboard, int>((ref, servicioId) async {
  final service = ref.watch(serviciosGranelesServiceProvider);
  return service.getDashboard(servicioId);
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

  @override
  TicketMuelleService get service => ref.read(ticketMuelleServiceProvider);

  /// Establecer el servicio ID para filtrar los tickets
  void setServicioId(int? servicioId) {
    if (_servicioId == servicioId) return;
    _servicioId = servicioId;
    service.setServicioId(servicioId);
    refresh();
  }

  /// Obtener el servicio ID actual
  int? get servicioId => _servicioId;

  @override
  Future<List<TicketMuelle>> loadInitial() async {
    try {
      final paginated = await service.list();
      return paginated.results;
    } catch (e) {
      throw Exception('Error al cargar tickets: $e');
    }
  }

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
    try {
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
    } catch (e) {
      return null;
    }
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
    try {
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
    } catch (e) {
      return null;
    }
  }
}

/// Provider para opciones del formulario de ticket
final ticketMuelleOptionsProvider =
    FutureProvider.autoDispose.family<TicketMuelleOptions, int>((ref, servicioId) async {
  final service = ref.watch(ticketMuelleServiceProvider);
  return service.getFormOptions(servicioId);
});

/// Provider para detalle de un ticket específico
final ticketMuelleDetalleProvider =
    FutureProvider.autoDispose.family<TicketMuelle, int>((ref, ticketId) async {
  final service = ref.watch(ticketMuelleServiceProvider);
  return service.retrieve(ticketId);
});

// ===========================================================================
// BALANZAS
// ===========================================================================

/// Provider para lista de balanzas por servicio
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
// SILOS
// ===========================================================================

/// Provider para lista de silos por servicio
final silosProvider =
    FutureProvider.autoDispose.family<List<Silos>, int>((ref, servicioId) async {
  final service = ref.watch(silosServiceProvider);
  final response = await service.getByServicio(servicioId);
  return response.results;
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
