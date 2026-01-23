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

  /// Buscar registros con filtros personalizados (con paginación)
  Future<void> searchWithFilters(Map<String, dynamic> filters) async {
    await listWithFilters(filters);
  }

  /// Buscar registros con daños
  Future<void> searchWithDanos({Map<String, dynamic>? filters}) async {
    await listWithFilters({'danos': true, ...?filters});
  }

  /// Buscar registros pedeteados
  Future<void> searchPedeteados({Map<String, dynamic>? filters}) async {
    await listWithFilters({'pedeteado': true, ...?filters});
  }

  /// Limpiar filtros y volver a la lista normal
  @override
  Future<void> clearSearch() async {
    await super.clearSearch();
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
