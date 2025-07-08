// lib/providers/autos/registro_general_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/base_provider_imp.dart';
import 'package:stampcamera/utils/error_parse.dart';
import '../../models/autos/registro_general_model.dart';
import '../../services/autos/registro_general_service.dart';

// ============================================================================
// PROVIDER DEL SERVICIO
// ============================================================================

final registroGeneralServiceProvider = Provider<RegistroGeneralService>((ref) {
  return RegistroGeneralService();
});

// ============================================================================
// PROVIDER PRINCIPAL DE LISTA
// ============================================================================

final registroGeneralProvider =
    AsyncNotifierProvider<RegistroGeneralNotifier, List<RegistroGeneral>>(
      RegistroGeneralNotifier.new,
    );

class RegistroGeneralNotifier extends BaseListProviderImpl<RegistroGeneral> {
  @override
  RegistroGeneralService get service =>
      ref.read(registroGeneralServiceProvider);

  // ============================================================================
  // MÉTODOS ESPECÍFICOS DEL DOMINIO
  // ============================================================================

  /// Buscar registros con daños
  Future<void> searchWithDanos({Map<String, dynamic>? filters}) async {
    state = const AsyncValue.loading();

    try {
      final paginated = await service.getWithDanos(filters: filters);
      _updateSearchState(paginated, query: 'con_danos');
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    }
  }

  /// Buscar registros pedeteados
  Future<void> searchPedeteados({Map<String, dynamic>? filters}) async {
    state = const AsyncValue.loading();

    try {
      final paginated = await service.getPedeteados(filters: filters);
      _updateSearchState(paginated, query: 'pedeteados');
    } catch (e, st) {
      state = AsyncValue.error(Exception(parseError(e)), st);
    }
  }

  /// Verificar si un VIN existe
  Future<bool> vinExists(String vin) async {
    return await service.vinExists(vin);
  }

  /// Obtener registro por VIN
  Future<RegistroGeneral?> getByVin(String vin) async {
    try {
      return await service.getByVin(vin);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // MÉTODOS PRIVADOS AUXILIARES
  // ============================================================================

  void _updateSearchState(dynamic paginated, {String? query}) {
    // Simular búsqueda para mantener consistencia con BaseListProviderImpl
    if (query != null) {}

    state = AsyncValue.data(paginated.results);
  }

  // Acceso a variables privadas de la clase base (workaround)
}

// ============================================================================
// PROVIDER DE DETALLE POR VIN
// ============================================================================

final registroDetalleByVinProvider =
    FutureProvider.family<RegistroGeneral?, String>((ref, vin) async {
      final service = ref.read(registroGeneralServiceProvider);
      try {
        return await service.getByVin(vin);
      } catch (e) {
        return null;
      }
    });

// ============================================================================
// PROVIDER PARA VERIFICACIÓN DE VIN
// ============================================================================

final vinExistsProvider = FutureProvider.family<bool, String>((ref, vin) async {
  final service = ref.read(registroGeneralServiceProvider);
  return await service.vinExists(vin);
});

// ============================================================================
// PROVIDERS DE FILTROS ESPECÍFICOS
// ============================================================================

/// Provider para registros con daños
final registrosConDanosProvider =
    AsyncNotifierProvider<RegistrosConDanosNotifier, List<RegistroGeneral>>(
      RegistrosConDanosNotifier.new,
    );

class RegistrosConDanosNotifier extends BaseListProviderImpl<RegistroGeneral> {
  @override
  RegistroGeneralService get service =>
      ref.read(registroGeneralServiceProvider);

  @override
  Future<List<RegistroGeneral>> loadInitial() async {
    try {
      final paginated = await service.getWithDanos();
      return paginated.results;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }
}

/// Provider para registros pedeteados
final registrosPedeteadosProvider =
    AsyncNotifierProvider<RegistrosPedeteadosNotifier, List<RegistroGeneral>>(
      RegistrosPedeteadosNotifier.new,
    );

class RegistrosPedeteadosNotifier
    extends BaseListProviderImpl<RegistroGeneral> {
  @override
  RegistroGeneralService get service =>
      ref.read(registroGeneralServiceProvider);

  @override
  Future<List<RegistroGeneral>> loadInitial() async {
    try {
      final paginated = await service.getPedeteados();
      return paginated.results;
    } catch (e) {
      throw Exception(parseError(e));
    }
  }
}
