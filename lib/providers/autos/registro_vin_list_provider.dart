// lib/providers/autos/registro_vin_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/base_provider_imp.dart';
import 'package:stampcamera/models/autos/registro_vin_list_model.dart';
import 'package:stampcamera/services/autos/registro_vin_list_service.dart';

// ============================================================================
// PROVIDER DEL SERVICIO
// ============================================================================

final registroVinListServiceProvider = Provider<RegistroVinListService>((ref) {
  return RegistroVinListService();
});

// ============================================================================
// PROVIDER PRINCIPAL DE LISTA (registros VIN individuales, recientes primero)
// ============================================================================

final registroVinListProvider =
    AsyncNotifierProvider<RegistroVinListNotifier, List<RegistroVinListItem>>(
      RegistroVinListNotifier.new,
    );

class RegistroVinListNotifier extends BaseListProviderImpl<RegistroVinListItem> {
  @override
  RegistroVinListService get service =>
      ref.read(registroVinListServiceProvider);

  /// Buscar registros con filtros combinados (search, create_by, condicion)
  Future<void> searchWithFilters(Map<String, dynamic> filters) async {
    await listWithFilters(filters);
  }
}

// ============================================================================
// PROVIDER DE USUARIOS REGISTRADORES (para el filtro por usuario)
// ============================================================================

final usuariosRegistradoresProvider =
    FutureProvider<List<UsuarioRegistrador>>((ref) async {
      final service = ref.read(registroVinListServiceProvider);
      return service.getUsuariosRegistradores();
    });
