// providers/inventario_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/utils/debouncer.dart';
import 'package:dio/dio.dart';
import '../../models/autos/inventario_model.dart';
import '../../services/inventario_service.dart';

// ====================================================================
// PROVIDERS PRINCIPALES
// ====================================================================

final inventarioProvider =
    AsyncNotifierProvider<InventarioNotifier, List<InventarioBase>>(
      InventarioNotifier.new,
    );

final inventarioOptionsProvider =
    FutureProvider.family<InventarioOptions, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final service = InventarioService();
      return await service.getOptions(
        marcaId: params['marcaId'],
        modelo: params['modelo'],
        version: params['version'],
      );
    });

// ====================================================================
// NOTIFIER PRINCIPAL
// ====================================================================

class InventarioNotifier extends AsyncNotifier<List<InventarioBase>> {
  final _service = InventarioService();
  final _debouncer = Debouncer();

  String? _searchQuery;
  int? _informacionUnidadIdFilter;
  bool _isSearching = false;
  int _searchToken = 0;

  // ✅ Getters públicos para el UI
  bool get isSearching => _isSearching;

  @override
  Future<List<InventarioBase>> build() async {
    return await _loadInitial();
  }

  // ====================================================================
  // MÉTODOS PRIVADOS - CORE FUNCTIONALITY
  // ====================================================================

  Future<List<InventarioBase>> _loadInitial() async {
    try {
      final inventarios = await _service.searchInventarios(page: 1);
      _searchQuery = null;
      _informacionUnidadIdFilter = null;
      _isSearching = false;

      return inventarios;
    } catch (e) {
      final errorMsg = _parseError(e);
      throw Exception(errorMsg);
    }
  }

  String _parseError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Conexión lenta - Revisa tu internet y vuelve a intentar';
        case DioExceptionType.receiveTimeout:
          return 'El servidor tardó demasiado en responder';
        case DioExceptionType.sendTimeout:
          return 'Error enviando datos - Revisa tu conexión';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 401) {
            return 'Sesión expirada - Vuelve a iniciar sesión';
          } else if (status == 403) {
            return 'No tienes permisos para ver estos inventarios';
          } else if (status == 404) {
            return 'Servicio no encontrado';
          } else if (status != null && status >= 500) {
            return 'Error del servidor - Intenta más tarde';
          }
          return 'Error del servidor (${status ?? 'desconocido'})';
        case DioExceptionType.cancel:
          return 'Operación cancelada';
        case DioExceptionType.connectionError:
          return 'Sin conexión a internet';
        case DioExceptionType.badCertificate:
          return 'Error de seguridad en la conexión';
        case DioExceptionType.unknown:
          return 'Error de conexión - Revisa tu internet';
      }
    }
    return 'Error inesperado: ${error.toString()}';
  }

  // ====================================================================
  // MÉTODOS PÚBLICOS - API PARA EL UI
  // ====================================================================

  /// Limpiar filtros y volver a lista inicial
  Future<void> clearFilters() async {
    if (_searchQuery == null && _informacionUnidadIdFilter == null) {
      return; // Ya está en modo inicial
    }

    state = const AsyncValue.loading();
    _searchQuery = null;
    _informacionUnidadIdFilter = null;
    _isSearching = false;

    try {
      final initial = await _loadInitial();
      state = AsyncValue.data(initial);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Búsqueda con debounce
  void debouncedSearch(String query) {
    _debouncer.run(() {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        clearFilters();
      } else {
        search(trimmed);
      }
    });
  }

  /// Búsqueda inmediata
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return clearFilters();
    }

    if (_searchQuery == trimmed && state.hasValue) {
      return;
    }

    debugPrint('🔍 Buscando inventarios: "$trimmed"');

    _isSearching = true;
    state = const AsyncValue.loading();
    _searchQuery = trimmed;
    _searchToken++;
    final currentToken = _searchToken;

    try {
      final inventarios = await _service.searchInventarios(
        search: trimmed,
        informacionUnidadId: _informacionUnidadIdFilter,
        page: 1,
      );

      if (_searchToken != currentToken) {
        debugPrint('🔥 Ignorando respuesta de búsqueda obsoleta');
        return;
      }

      state = AsyncValue.data(inventarios);
    } catch (e, st) {
      if (_searchToken == currentToken) {
        final errorMsg = _parseError(e);
        state = AsyncValue.error(Exception(errorMsg), st);
      }
    } finally {
      if (_searchToken == currentToken) {
        _isSearching = false;
        if (!state.hasError) {
          state = AsyncValue.data([...?state.value]);
        }
      }
    }
  }

  /// Filtrar por información de unidad
  Future<void> filterByInformacionUnidad(int? unidadId) async {
    if (_informacionUnidadIdFilter == unidadId) return;

    state = const AsyncValue.loading();
    _informacionUnidadIdFilter = unidadId;
    _searchToken++;
    final currentToken = _searchToken;

    try {
      final inventarios = await _service.searchInventarios(
        search: _searchQuery,
        informacionUnidadId: unidadId,
        page: 1,
      );

      if (_searchToken != currentToken) return;

      state = AsyncValue.data(inventarios);
    } catch (e, st) {
      if (_searchToken == currentToken) {
        final errorMsg = _parseError(e);
        state = AsyncValue.error(Exception(errorMsg), st);
      }
    }
  }

  /// Refresh manual
  Future<void> refresh() async {
    if (_searchQuery != null || _informacionUnidadIdFilter != null) {
      // Rehacer filtros actuales
      state = const AsyncValue.loading();
      try {
        final inventarios = await _service.searchInventarios(
          search: _searchQuery,
          informacionUnidadId: _informacionUnidadIdFilter,
          page: 1,
        );
        state = AsyncValue.data(inventarios);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    } else {
      // Recargar lista inicial
      state = const AsyncValue.loading();
      try {
        final initial = await _loadInitial();
        state = AsyncValue.data(initial);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Crear inventario completo
  Future<bool> createInventario({
    required int informacionUnidadId,
    required int llaveSimple,
    required int llaveComando,
    required int llaveInteligente,
    required int encendedor,
    required int cenicero,
    required int cableUsbOAux,
    required int retrovisor,
    required int pisos,
    required int logos,
    required int estucheManual,
    required int manualesEstuche,
    required int pinDeRemolque,
    required int tapaPinDeRemolque,
    required int portaplaca,
    required int copasTapasDeAros,
    required int tapones,
    required int cobertor,
    required int botiquin,
    required int pernoSeguroRueda,
    required int ambientadores,
    required int estucheHerramienta,
    required int desarmador,
    required int llaveBocaCombinada,
    required int alicate,
    required int llaveDeRueda,
    required int palancaDeGata,
    required int gata,
    required int llantaDeRepuesto,
    required int trianguloDeEmergencia,
    required int malla,
    required int antena,
    required int extra,
    required int cableCargador,
    required int cajaDeFusibles,
    required int extintor,
    required int chalecoReflectivo,
    required int conos,
    required int extension,
    required String otros,
  }) async {
    try {
      final inventarioData = {
        'LLAVE_SIMPLE': llaveSimple,
        'LLAVE_COMANDO': llaveComando,
        'LLAVE_INTELIGENTE': llaveInteligente,
        'ENCENDEDOR': encendedor,
        'CENICERO': cenicero,
        'CABLE_USB_O_AUX': cableUsbOAux,
        'RETROVISOR': retrovisor,
        'PISOS': pisos,
        'LOGOS': logos,
        'ESTUCHE_MANUAL': estucheManual,
        'MANUALES_ESTUCHE': manualesEstuche,
        'PIN_DE_REMOLQUE': pinDeRemolque,
        'TAPA_PIN_DE_REMOLQUE': tapaPinDeRemolque,
        'PORTAPLACA': portaplaca,
        'COPAS_TAPAS_DE_AROS': copasTapasDeAros,
        'TAPONES_CHASIS': tapones,
        'COBERTOR': cobertor,
        'BOTIQUIN': botiquin,
        'PERNO_SEGURO_RUEDA': pernoSeguroRueda,
        'AMBIENTADORES': ambientadores,
        'ESTUCHE_HERRAMIENTA': estucheHerramienta,
        'DESARMADOR': desarmador,
        'LLAVE_BOCA_COMBINADA': llaveBocaCombinada,
        'ALICATE': alicate,
        'LLAVE_DE_RUEDA': llaveDeRueda,
        'PALANCA_DE_GATA': palancaDeGata,
        'GATA': gata,
        'LLANTA_DE_REPUESTO': llantaDeRepuesto,
        'TRIANGULO_DE_EMERGENCIA': trianguloDeEmergencia,
        'MALLA': malla,
        'ANTENA': antena,
        'EXTRA': extra,
        'CABLE_CARGADOR': cableCargador,
        'CAJA_DE_FUSIBLES': cajaDeFusibles,
        'EXTINTOR': extintor,
        'CHALECO_REFLECTIVO': chalecoReflectivo,
        'CONOS': conos,
        'EXTENSION': extension,
        'OTROS': otros,
      };

      await _service.createOrUpdateInventario(
        informacionUnidadId: informacionUnidadId,
        inventarioData: inventarioData,
      );

      await refresh();
      return true;
    } catch (e) {
      debugPrint('❌ Error creando inventario: $e');
      return false;
    }
  }

  /// Eliminar inventario
  Future<bool> deleteInventario(int id) async {
    try {
      await _service.deleteInventario(id);
      await refresh();
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando inventario: $e');
      return false;
    }
  }

  /// Agregar imagen a inventario
  Future<bool> addImageToInventario({
    required int informacionUnidadId,
    required String imagePath,
    String? descripcion,
  }) async {
    try {
      await _service.createInventarioImage(
        informacionUnidadId: informacionUnidadId,
        imagePath: imagePath,
        descripcion: descripcion,
      );

      await refresh();
      return true;
    } catch (e) {
      debugPrint('❌ Error agregando imagen: $e');
      return false;
    }
  }

  void clearAll() {
    _searchQuery = null;
    _informacionUnidadIdFilter = null;
    _isSearching = false;
    _searchToken = 0;
    state = const AsyncValue.loading();
  }

  void forceInvalidate() {
    ref.invalidateSelf();
  }
}

// ====================================================================
// PROVIDERS AUXILIARES
// ====================================================================

// Provider para obtener un inventario específico por unidad
final inventarioByUnidadProvider = FutureProvider.family<InventarioBase?, int>((
  ref,
  informacionUnidadId,
) async {
  final service = InventarioService();
  return await service.getInventarioByUnidad(informacionUnidadId);
});

// Provider para obtener imágenes de un inventario
final inventarioImagesProvider =
    FutureProvider.family<List<InventarioImagen>, int>((
      ref,
      informacionUnidadId,
    ) async {
      final service = InventarioService();
      return await service.getInventarioImages(informacionUnidadId);
    });
