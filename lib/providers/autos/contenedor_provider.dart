// providers/autos/contenedor_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/core/base_provider_imp.dart';
import 'package:stampcamera/models/autos/contenedor_model.dart';
import 'package:stampcamera/services/contenedor_service.dart';

// ============================================================================
// PROVIDER DEL SERVICIO
// ============================================================================

final contenedorServiceProvider = Provider<ContenedorService>((ref) {
  return ContenedorService();
});

// ============================================================================
// PROVIDER DE OPCIONES
// ============================================================================

final contenedorOptionsProvider = FutureProvider<ContenedorOptions>((ref) {
  final service = ref.read(contenedorServiceProvider);
  return service.getOptions();
});

// ============================================================================
// PROVIDER PRINCIPAL DE LISTA (usando AsyncNotifierProvider)
// ============================================================================

final contenedorProvider =
    AsyncNotifierProvider<ContenedorNotifier, List<ContenedorModel>>(
      ContenedorNotifier.new,
    );

class ContenedorNotifier extends BaseListProviderImpl<ContenedorModel> {
  @override
  ContenedorService get service => ref.read(contenedorServiceProvider);

  // ============================================================================
  // MÉTODOS ESPECÍFICOS DEL DOMINIO (CRUD)
  // ============================================================================

  /// Crear nuevo contenedor con fotos
  Future<bool> createContenedor({
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? fotoContenedorPath,
    String? precinto1,
    String? fotoPrecinto1Path,
    String? precinto2,
    String? fotoPrecinto2Path,
    String? fotoContenedorVacioPath,
  }) async {
    try {
      final newContenedor = await service.createContenedor(
        nContenedor: nContenedor,
        naveDescarga: naveDescarga,
        zonaInspeccion: zonaInspeccion,
        fotoContenedorPath: fotoContenedorPath,
        precinto1: precinto1,
        fotoPrecinto1Path: fotoPrecinto1Path,
        precinto2: precinto2,
        fotoPrecinto2Path: fotoPrecinto2Path,
        fotoContenedorVacioPath: fotoContenedorVacioPath,
      );

      // Agregar al inicio de la lista actual
      final current = state.value ?? [];
      state = AsyncValue.data([newContenedor, ...current]);

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar contenedor existente
  Future<bool> updateContenedor({
    required int id,
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? precinto1,
    String? precinto2,
  }) async {
    try {
      final updatedContenedor = await service.updateContenedor(
        id: id,
        nContenedor: nContenedor,
        naveDescarga: naveDescarga,
        zonaInspeccion: zonaInspeccion,
        precinto1: precinto1,
        precinto2: precinto2,
      );
      print('Contenedor actualizado: $updatedContenedor');

      // Actualizar en la lista
      final current = state.value ?? [];
      final updatedList = current.map((contenedor) {
        return contenedor.id == id ? updatedContenedor : contenedor;
      }).toList();

      state = AsyncValue.data(updatedList);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ NUEVO: Limpiar campos específicos del contenedor
  Future<bool> clearContenedorFields({
    required int id,
    bool clearPrecinto1 = false,
    bool clearPrecinto2 = false,
    bool clearZonaInspeccion = false,
    bool clearFotoPrecinto1 = false,
    bool clearFotoPrecinto2 = false,
    bool clearFotoContenedorVacio = false,
  }) async {
    try {
      final updatedContenedor = await service.clearContenedorFields(
        id: id,
        clearPrecinto1: clearPrecinto1,
        clearPrecinto2: clearPrecinto2,
        clearZonaInspeccion: clearZonaInspeccion,
        clearFotoPrecinto1: clearFotoPrecinto1,
        clearFotoPrecinto2: clearFotoPrecinto2,
        clearFotoContenedorVacio: clearFotoContenedorVacio,
      );

      // Actualizar en la lista
      final current = state.value ?? [];
      final updatedList = current.map((contenedor) {
        return contenedor.id == id ? updatedContenedor : contenedor;
      }).toList();

      state = AsyncValue.data(updatedList);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ NUEVO: Actualizar contenedor con archivos y limpieza
  Future<bool> updateContenedorWithFiles({
    required int id,
    String? nContenedor,
    int? naveDescarga,
    int? zonaInspeccion,
    String? precinto1,
    String? precinto2,
    String? fotoContenedorPath,
    String? fotoPrecinto1Path,
    String? fotoPrecinto2Path,
    String? fotoContenedorVacioPath,
    bool removeFotoContenedor = false,
    bool removeFotoPrecinto1 = false,
    bool removeFotoPrecinto2 = false,
    bool removeFotoContenedorVacio = false,
  }) async {
    try {
      final updatedContenedor = await service.updateContenedorWithFiles(
        id: id,
        nContenedor: nContenedor,
        naveDescarga: naveDescarga,
        zonaInspeccion: zonaInspeccion,
        precinto1: precinto1,
        precinto2: precinto2,
        fotoContenedorPath: fotoContenedorPath,
        fotoPrecinto1Path: fotoPrecinto1Path,
        fotoPrecinto2Path: fotoPrecinto2Path,
        fotoContenedorVacioPath: fotoContenedorVacioPath,
        removeFotoContenedor: removeFotoContenedor,
        removeFotoPrecinto1: removeFotoPrecinto1,
        removeFotoPrecinto2: removeFotoPrecinto2,
        removeFotoContenedorVacio: removeFotoContenedorVacio,
      );

      // Actualizar en la lista
      final current = state.value ?? [];
      final updatedList = current.map((contenedor) {
        return contenedor.id == id ? updatedContenedor : contenedor;
      }).toList();

      state = AsyncValue.data(updatedList);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar contenedor
  Future<bool> deleteContenedor(int id) async {
    try {
      await service.delete(id);

      // Remover de la lista actual
      final current = state.value ?? [];
      final filteredList = current.where((item) => item.id != id).toList();

      state = AsyncValue.data(filteredList);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtener contenedor por ID
  @override
  Future<ContenedorModel?> getById(int id) async {
    try {
      return await service.retrieve(id);
    } catch (e) {
      return null;
    }
  }
}

// ============================================================================
// PROVIDER DE DETALLE POR ID
// ============================================================================

final contenedorDetalleProvider = FutureProvider.family<ContenedorModel?, int>((
  ref,
  id,
) async {
  final service = ref.read(contenedorServiceProvider);
  try {
    return await service.retrieve(id);
  } catch (e) {
    return null;
  }
});
