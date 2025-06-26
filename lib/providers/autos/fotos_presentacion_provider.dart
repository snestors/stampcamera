// lib/providers/autos/fotos_presentacion_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/fotos_presentacion_service.dart';
import 'package:stampcamera/providers/autos/queue_state_provider.dart';

// ============================================================================
// SERVICIO PROVIDER
// ============================================================================

/// Provider del servicio de fotos de presentación
final fotosPresentacionServiceProvider = Provider<FotosPresentacionService>((
  ref,
) {
  return FotosPresentacionService();
});

// ============================================================================
// PROVIDER DE OPCIONES (CACHED)
// ============================================================================

/// Provider que obtiene las opciones de tipos de fotos (una sola vez)
final fotosOptionsProvider = FutureProvider<FotosOptions>((ref) async {
  final service = ref.read(fotosPresentacionServiceProvider);
  return await service.getOptions();
});

/// Provider que expone solo los tipos disponibles
final tiposFotosDisponiblesProvider = Provider<List<TipoFotoOption>>((ref) {
  final optionsAsync = ref.watch(fotosOptionsProvider);
  return optionsAsync.value?.tiposDisponibles ?? [];
});

// ============================================================================
// PROVIDER PRINCIPAL DE FOTOS
// ============================================================================

/// Provider principal que maneja el estado de fotos de presentación
final fotosPresentacionStateProvider =
    StateNotifierProvider<FotosPresentacionNotifier, FotosPresentacionState>((
      ref,
    ) {
      return FotosPresentacionNotifier(ref);
    });

// ============================================================================
// ESTADO DEL PROVIDER
// ============================================================================

class FotosPresentacionState {
  final int? selectedRegistroVinId;
  final bool isUploading;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic> uploadProgress; // {"foto_1": 0.5, "foto_2": 1.0}

  const FotosPresentacionState({
    this.selectedRegistroVinId,
    this.isUploading = false,
    this.errorMessage,
    this.successMessage,
    this.uploadProgress = const {},
  });

  FotosPresentacionState copyWith({
    int? selectedRegistroVinId,
    bool? isUploading,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? uploadProgress,
    bool clearSelectedVin = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearProgress = false,
  }) {
    return FotosPresentacionState(
      selectedRegistroVinId: clearSelectedVin
          ? null
          : (selectedRegistroVinId ?? this.selectedRegistroVinId),
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      uploadProgress: clearProgress
          ? {}
          : (uploadProgress ?? this.uploadProgress),
    );
  }

  /// Helper: ¿Está en progreso alguna subida?
  bool get hasActiveUploads => uploadProgress.isNotEmpty;

  /// Helper: ¿Hay un registro seleccionado?
  bool get hasSelectedRegistro => selectedRegistroVinId != null;
}

// ============================================================================
// NOTIFIER PRINCIPAL
// ============================================================================

class FotosPresentacionNotifier extends StateNotifier<FotosPresentacionState> {
  final Ref ref;

  FotosPresentacionNotifier(this.ref) : super(const FotosPresentacionState());

  // ============================================================================
  // MÉTODO DE CONFIGURACIÓN
  // ============================================================================

  /// Seleccionar registro VIN para trabajar
  void selectRegistroVin(int registroVinId) {
    state = state.copyWith(
      selectedRegistroVinId: registroVinId,
      clearError: true,
      clearSuccess: true,
    );
  }

  /// Limpiar registro seleccionado
  void clearSelectedRegistro() {
    state = state.copyWith(
      clearSelectedVin: true,
      clearError: true,
      clearSuccess: true,
    );
  }

  // ============================================================================
  // MÉTODOS OFFLINE-FIRST (AMBOS ENFOQUES)
  // ============================================================================

  /// Agregar foto individual (offline-first) para un registro específico
  Future<void> addFotoOfflineFirst({
    required int registroVinId,
    required String tipo,
    required String imagenPath,
    String? nDocumento,
  }) async {
    state = state.copyWith(
      isUploading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = ref.read(fotosPresentacionServiceProvider);

      final success = await service.createFotoOfflineFirst(
        registroVinId: registroVinId,
        tipo: tipo,
        imagenPath: imagenPath,
        nDocumento: nDocumento,
      );

      if (success) {
        // Refrescar estado de queue
        ref.read(queueStateProvider.notifier).refreshState();

        state = state.copyWith(
          isUploading: false,
          successMessage:
              'Foto guardada exitosamente. Se enviará automáticamente.',
        );

        // Auto-limpiar mensaje después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            state = state.copyWith(clearSuccess: true);
          }
        });
      } else {
        state = state.copyWith(
          isUploading: false,
          errorMessage: 'Error al guardar la foto',
        );
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isUploading: false, errorMessage: errorMessage);
    }
  }

  /// Agregar foto al registro seleccionado (enfoque con estado)
  Future<void> addFotoToSelected({
    required String tipo,
    required String imagenPath,
    String? nDocumento,
  }) async {
    if (state.selectedRegistroVinId == null) {
      state = state.copyWith(
        errorMessage: 'Debe seleccionar un registro VIN primero',
      );
      return;
    }

    await addFotoOfflineFirst(
      registroVinId: state.selectedRegistroVinId!,
      tipo: tipo,
      imagenPath: imagenPath,
      nDocumento: nDocumento,
    );
  }

  /// Agregar múltiples fotos (offline-first) para un registro específico
  Future<void> addMultipleFotosOfflineFirst({
    required int registroVinId,
    required List<FotoCreate> fotos,
  }) async {
    state = state.copyWith(
      isUploading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = ref.read(fotosPresentacionServiceProvider);

      final success = await service.createMultipleFotosOfflineFirst(
        registroVinId: registroVinId,
        fotos: fotos,
      );

      if (success) {
        // Refrescar estado de queue
        ref.read(queueStateProvider.notifier).refreshState();

        state = state.copyWith(
          isUploading: false,
          successMessage:
              '${fotos.length} fotos guardadas exitosamente. Se enviarán automáticamente.',
        );

        // Auto-limpiar mensaje después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            state = state.copyWith(clearSuccess: true);
          }
        });
      } else {
        state = state.copyWith(
          isUploading: false,
          errorMessage: 'Error al guardar las fotos',
        );
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isUploading: false, errorMessage: errorMessage);
    }
  }

  /// Agregar múltiples fotos al registro seleccionado
  Future<void> addMultipleFotosToSelected({
    required List<FotoCreate> fotos,
  }) async {
    if (state.selectedRegistroVinId == null) {
      state = state.copyWith(
        errorMessage: 'Debe seleccionar un registro VIN primero',
      );
      return;
    }

    await addMultipleFotosOfflineFirst(
      registroVinId: state.selectedRegistroVinId!,
      fotos: fotos,
    );
  }

  // ============================================================================
  // MÉTODOS DE LIMPIEZA Y UTILIDAD
  // ============================================================================

  /// Limpiar mensajes de error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Limpiar mensajes de éxito
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Limpiar todo el estado
  void resetState() {
    state = const FotosPresentacionState();
  }

  // ============================================================================
  // HELPER METHODS PARA WIDGETS (AMBOS ENFOQUES)
  // ============================================================================

  /// Método helper genérico para ReusableCameraCard (con parámetro)
  Future<void> addFotoWithType({
    required int registroVinId,
    required String tipo,
    required String imagenPath,
    String? nDocumento,
  }) async {
    await addFotoOfflineFirst(
      registroVinId: registroVinId,
      tipo: tipo,
      imagenPath: imagenPath,
      nDocumento: nDocumento,
    );
  }

  /// Método helper para widgets que usan selectedRegistroVinId
  Future<void> addFotoWithTypeToSelected({
    required String tipo,
    required String imagenPath,
    String? nDocumento,
  }) async {
    await addFotoToSelected(
      tipo: tipo,
      imagenPath: imagenPath,
      nDocumento: nDocumento,
    );
  }

  /// Helper para validar si un tipo está disponible
  bool isTipoDisponible(String tipo) {
    final tiposDisponibles = ref.read(tiposFotosDisponiblesProvider);
    return tiposDisponibles.any((t) => t.value == tipo);
  }

  /// Helper para obtener el label de un tipo
  String? getLabelForTipo(String tipo) {
    final tiposDisponibles = ref.read(tiposFotosDisponiblesProvider);
    final tipoOption = tiposDisponibles
        .where((t) => t.value == tipo)
        .firstOrNull;
    return tipoOption?.label;
  }
}

// ============================================================================
// PROVIDERS DERIVADOS PARA WIDGETS ESPECÍFICOS
// ============================================================================

/// Provider que expone si hay fotos cargando
final fotosIsUploadingProvider = Provider<bool>((ref) {
  final state = ref.watch(fotosPresentacionStateProvider);
  return state.isUploading;
});

/// Provider que expone si hay mensajes de error
final fotosHasErrorProvider = Provider<bool>((ref) {
  final state = ref.watch(fotosPresentacionStateProvider);
  return state.errorMessage != null;
});

/// Provider que expone si hay un registro seleccionado
final fotosHasSelectedRegistroProvider = Provider<bool>((ref) {
  final state = ref.watch(fotosPresentacionStateProvider);
  return state.hasSelectedRegistro;
});

/// Provider que expone el ID del registro seleccionado
final fotosSelectedRegistroIdProvider = Provider<int?>((ref) {
  final state = ref.watch(fotosPresentacionStateProvider);
  return state.selectedRegistroVinId;
});

/// Provider para obtener el primer tipo disponible (útil como default)
final defaultTipoFotoProvider = Provider<String?>((ref) {
  final tipos = ref.watch(tiposFotosDisponiblesProvider);
  return tipos.isNotEmpty ? tipos.first.value : null;
});

/// Provider que expone los tipos como Map<String, String> para dropdowns
final tiposFotosMapProvider = Provider<Map<String, String>>((ref) {
  final tipos = ref.watch(tiposFotosDisponiblesProvider);
  return {for (var tipo in tipos) tipo.value: tipo.label};
});

// ============================================================================
// PROVIDER ESPECÍFICO PARA REGISTRO VIN (FAMILY)
// ============================================================================

/// Provider para el estado de fotos de un registro VIN específico
/// Mantiene track de las fotos locales por registro
final fotosForRegistroProvider = StateProvider.family<List<String>, int>((
  ref,
  registroVinId,
) {
  // Lista de paths de fotos para un registro específico
  return <String>[];
});

/// Provider simplificado para agregar foto directamente a un registro específico
final addFotoDirectProvider =
    Provider.family<
      Future<void> Function(String, String, {String? nDocumento}),
      int
    >((ref, registroVinId) {
      return (String tipo, String imagenPath, {String? nDocumento}) async {
        // Usar el notifier principal pero con el registroVinId específico
        await ref
            .read(fotosPresentacionStateProvider.notifier)
            .addFotoWithType(
              registroVinId: registroVinId,
              tipo: tipo,
              imagenPath: imagenPath,
              nDocumento: nDocumento,
            );

        // Agregar a la lista local para tracking
        final currentFotos = ref.read(
          fotosForRegistroProvider(registroVinId).notifier,
        );
        currentFotos.state = [...currentFotos.state, imagenPath];
      };
    });
