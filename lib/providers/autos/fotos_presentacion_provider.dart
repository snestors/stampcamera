// lib/providers/autos/fotos_presentacion_provider.dart
// 📸 PROVIDER OFFLINE-FIRST PARA FOTOS DE PRESENTACIÓN
// ✅ Siguiendo patrón de PedeteoProvider
// ✅ Integración con ReusableCameraCard
// ✅ Queue management unificado

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/fotos_presentacion_model.dart';
import 'package:stampcamera/services/fotos_presentacion_service.dart'
    as service;
import 'package:stampcamera/providers/autos/queue_state_provider.dart';

// ============================================================================
// SERVICIO PROVIDER
// ============================================================================

/// Provider del servicio de fotos de presentación
final fotosPresentacionServiceProvider =
    Provider<service.FotosPresentacionService>((ref) {
      return service.FotosPresentacionService();
    });

// ============================================================================
// PROVIDER DE OPCIONES (CACHED)
// ============================================================================

/// Provider que obtiene las opciones del endpoint /options una sola vez
/// Se mantiene en caché durante la sesión
final fotosOptionsProvider = FutureProvider<FotosOptions>((ref) async {
  final serviceInstance = ref.read(fotosPresentacionServiceProvider);
  final serviceOptions = await serviceInstance.getOptions();

  // Convertir del modelo del servicio al modelo del provider
  return FotosOptions(
    tiposDisponibles: serviceOptions.tiposDisponibles.map((tipo) {
      return TipoFotoOption(value: tipo.value, label: tipo.label);
    }).toList(),
  );
});

/// Provider que expone solo los tipos disponibles para widgets
final tiposFotosDisponiblesProvider = Provider<List<TipoFotoOption>>((ref) {
  final optionsAsync = ref.watch(fotosOptionsProvider);
  return optionsAsync.value?.tiposDisponibles ?? [];
});

// ============================================================================
// PROVIDER PRINCIPAL DE FOTOS POR REGISTRO VIN
// ============================================================================

/// Provider que maneja las fotos de un registro VIN específico
/// Patrón AsyncNotifier para datos del backend con estado offline-first
final fotosPorRegistroProvider =
    AsyncNotifierProvider.family<
      FotosPresentacionNotifier,
      List<FotoPresentacion>,
      int
    >(() => FotosPresentacionNotifier());

class FotosPresentacionNotifier
    extends FamilyAsyncNotifier<List<FotoPresentacion>, int> {
  late service.FotosPresentacionService _service;

  @override
  Future<List<FotoPresentacion>> build(int registroVinId) async {
    // Keepalive para mantener en caché
    ref.keepAlive();

    // Inicializar servicio
    _service = ref.read(fotosPresentacionServiceProvider);

    // TODO: Aquí irían las fotos del backend si hay endpoint de listado
    // Por ahora retornamos lista vacía ya que el servicio se enfoca en creación
    return <FotoPresentacion>[];
  }

  // ============================================================================
  // MÉTODOS OFFLINE-FIRST
  // ============================================================================

  /// Agregar una foto individual offline-first
  /// Se integra perfectamente con ReusableCameraCard
  Future<bool> addFoto({
    required String tipo,
    required String imagenPath,
    String? nDocumento,
  }) async {
    try {
      // Actualizar estado a loading
      state = const AsyncLoading();

      // Usar método offline-first del servicio
      final success = await _service.createFotoOfflineFirst(
        registroVinId: arg,
        tipo: tipo,
        imagenPath: imagenPath,
        nDocumento: nDocumento,
      );

      if (success) {
        // Refrescar el provider unificado de cola
        ref.read(queueStateProvider.notifier).refreshState();

        // Recargar fotos (esto podría optimizarse con estado local)
        state = await AsyncValue.guard(() => build(arg));

        return true;
      } else {
        state = AsyncError('Error al guardar la foto', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  /// Agregar múltiples fotos offline-first
  /// Útil para subida masiva desde galería
  Future<bool> addMultipleFotos(List<FotoCreate> fotos) async {
    try {
      state = const AsyncLoading();

      // Convertir modelos del provider a modelos del servicio
      final serviceFotos = fotos.map((foto) {
        return service.FotoCreate(
          tipo: foto.tipo,
          imagenPath: foto.imagenPath,
          nDocumento: foto.nDocumento,
        );
      }).toList();

      final success = await _service.createMultipleFotosOfflineFirst(
        registroVinId: arg,
        fotos: serviceFotos,
      );

      if (success) {
        // Refrescar queue state
        ref.read(queueStateProvider.notifier).refreshState();

        // Recargar fotos
        state = await AsyncValue.guard(() => build(arg));

        return true;
      } else {
        state = AsyncError('Error al guardar las fotos', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  /// Método de conveniencia para ReusableCameraCard
  /// Callback directo que puede usarse en onImageSelected
  Future<void> onCameraImageSelected({
    required String imagePath,
    required String tipoFoto,
    String? numeroDocumento,
  }) async {
    await addFoto(
      tipo: tipoFoto,
      imagenPath: imagePath,
      nDocumento: numeroDocumento,
    );
  }
}

// ============================================================================
// PROVIDER DE ESTADO DE CARGA ESPECÍFICO
// ============================================================================

/// Provider que maneja estados específicos para la UI
final fotosUiStateProvider =
    StateNotifierProvider.family<FotosUiStateNotifier, FotosUiState, int>((
      ref,
      registroVinId,
    ) {
      return FotosUiStateNotifier(registroVinId, ref);
    });

class FotosUiState {
  final bool isUploading;
  final int pendingCount;
  final String? currentTipoSeleccionado;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, String?> capturedImages; // tipo -> path

  const FotosUiState({
    this.isUploading = false,
    this.pendingCount = 0,
    this.currentTipoSeleccionado,
    this.errorMessage,
    this.successMessage,
    this.capturedImages = const {},
  });

  FotosUiState copyWith({
    bool? isUploading,
    int? pendingCount,
    String? currentTipoSeleccionado,
    String? errorMessage,
    String? successMessage,
    Map<String, String?>? capturedImages,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearTipoSeleccionado = false,
  }) {
    return FotosUiState(
      isUploading: isUploading ?? this.isUploading,
      pendingCount: pendingCount ?? this.pendingCount,
      currentTipoSeleccionado: clearTipoSeleccionado
          ? null
          : (currentTipoSeleccionado ?? this.currentTipoSeleccionado),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      capturedImages: capturedImages ?? this.capturedImages,
    );
  }
}

class FotosUiStateNotifier extends StateNotifier<FotosUiState> {
  final int registroVinId;
  final Ref ref;

  FotosUiStateNotifier(this.registroVinId, this.ref)
    : super(const FotosUiState());

  /// Seleccionar tipo de foto actual para ReusableCameraCard
  void selectTipoFoto(String tipo) {
    state = state.copyWith(currentTipoSeleccionado: tipo);
  }

  /// Limpiar tipo seleccionado
  void clearTipoSeleccionado() {
    state = state.copyWith(clearTipoSeleccionado: true);
  }

  /// Agregar imagen capturada localmente (para preview)
  void addCapturedImage(String tipo, String imagePath) {
    final newImages = Map<String, String?>.from(state.capturedImages);
    newImages[tipo] = imagePath;
    state = state.copyWith(capturedImages: newImages);
  }

  /// Remover imagen capturada
  void removeCapturedImage(String tipo) {
    final newImages = Map<String, String?>.from(state.capturedImages);
    newImages.remove(tipo);
    state = state.copyWith(capturedImages: newImages);
  }

  /// Actualizar estado desde queue manager - ahora usando FutureProvider
  Future<void> updateFromQueue() async {
    try {
      final service = ref.read(fotosPresentacionServiceProvider);
      final pendingCount = await service.getPendingCount();
      state = state.copyWith(pendingCount: pendingCount);
    } catch (e) {
      // No hacer nada si falla, el conteo se actualiza desde otro provider
    }
  }

  /// Mostrar mensaje de éxito
  void showSuccess(String message) {
    state = state.copyWith(successMessage: message);

    // Auto limpiar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(clearSuccess: true);
      }
    });
  }

  /// Mostrar mensaje de error
  void showError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset completo del estado
  void reset() {
    state = const FotosUiState();
  }
}

// ============================================================================
// PROVIDERS DE CONVENIENCIA PARA WIDGETS
// ============================================================================

/// Provider que obtiene el conteo específico de fotos pendientes usando UnifiedQueueService
final fotosPendientesCountProvider = FutureProvider.family<int, int>((
  ref,
  registroVinId,
) async {
  final serviceInstance = ref.read(fotosPresentacionServiceProvider);
  return await serviceInstance.getPendingCount();
});

/// Provider que verifica si una foto específica está en cola
final fotoTipoEstaPendienteProvider = Provider.family<bool, (int, String)>((
  ref,
  params,
) {
  final (registroVinId, tipo) = params;
  final uiState = ref.watch(fotosUiStateProvider(registroVinId));
  return uiState.capturedImages.containsKey(tipo);
});

/// Provider que combina el estado de las fotos con las opciones disponibles
final fotosCompleteStateProvider = Provider.family<FotosCompleteState, int>((
  ref,
  registroVinId,
) {
  final fotosAsync = ref.watch(fotosPorRegistroProvider(registroVinId));
  final optionsAsync = ref.watch(fotosOptionsProvider);
  final uiState = ref.watch(fotosUiStateProvider(registroVinId));

  // Obtener pending count de forma síncrona desde el queue state general
  final queueState = ref.watch(queueStateProvider);

  return FotosCompleteState(
    fotos: fotosAsync.value ?? [],
    tiposDisponibles: optionsAsync.value?.tiposDisponibles ?? [],
    isLoading: fotosAsync.isLoading || optionsAsync.isLoading,
    error: fotosAsync.error ?? optionsAsync.error,
    uiState: uiState.copyWith(pendingCount: queueState.pendingCount),
  );
});

class FotosCompleteState {
  final List<FotoPresentacion> fotos;
  final List<TipoFotoOption> tiposDisponibles;
  final bool isLoading;
  final Object? error;
  final FotosUiState uiState;

  const FotosCompleteState({
    required this.fotos,
    required this.tiposDisponibles,
    required this.isLoading,
    this.error,
    required this.uiState,
  });

  bool get hasError => error != null;
  bool get hasFotos => fotos.isNotEmpty;
  int get totalFotos => fotos.length + uiState.capturedImages.length;
}
