// lib/providers/autos/contenedores_provider.dart
// 📦 PROVIDER OFFLINE-FIRST PARA CONTENEDORES
// ✅ Alineado con ContenedoresService existente
// ✅ Soporte para precintos y múltiples fotos
// ✅ Estados complejos para creación de contenedores

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/contenedores_service.dart' as service;
import 'package:stampcamera/providers/autos/queue_state_provider.dart';

// ============================================================================
// SERVICIO PROVIDER
// ============================================================================

/// Provider del servicio de contenedores
final contenedoresServiceProvider = Provider<service.ContenedoresService>((
  ref,
) {
  return service.ContenedoresService();
});

// ============================================================================
// PROVIDER DE OPCIONES (CACHED)
// ============================================================================

/// Provider que obtiene las opciones del endpoint /options una sola vez
final contenedoresOptionsProvider = FutureProvider<service.ContenedoresOptions>(
  (ref) async {
    final serviceInstance = ref.read(contenedoresServiceProvider);
    return await serviceInstance.getOptions();
  },
);

// Providers derivados para fácil acceso en widgets
final navesDisponiblesProvider = Provider<List<service.NaveDisponible>>((ref) {
  final optionsAsync = ref.watch(contenedoresOptionsProvider);
  return optionsAsync.value?.navesDisponibles ?? [];
});

final zonasDisponiblesProvider = Provider<List<service.ZonaDisponible>>((ref) {
  final optionsAsync = ref.watch(contenedoresOptionsProvider);
  return optionsAsync.value?.zonasDisponibles ?? [];
});

final fieldPermissionsProvider = Provider<Map<String, service.FieldPermission>>(
  (ref) {
    final optionsAsync = ref.watch(contenedoresOptionsProvider);
    return optionsAsync.value?.fieldPermissions ?? {};
  },
);

final initialValuesProvider = Provider<Map<String, dynamic>>((ref) {
  final optionsAsync = ref.watch(contenedoresOptionsProvider);
  return optionsAsync.value?.initialValues ?? {};
});

// ============================================================================
// PROVIDER PRINCIPAL DE CONTENEDORES
// ============================================================================

/// Provider que maneja los contenedores
final contenedoresListProvider =
    AsyncNotifierProvider<ContenedoresNotifier, List<service.Contenedor>>(
      () => ContenedoresNotifier(),
    );

class ContenedoresNotifier extends AsyncNotifier<List<service.Contenedor>> {
  late service.ContenedoresService _service;

  @override
  Future<List<service.Contenedor>> build() async {
    ref.keepAlive();
    _service = ref.read(contenedoresServiceProvider);

    // TODO: Implementar cuando haya endpoint de listado
    // Por ahora retornamos lista vacía ya que el servicio se enfoca en creación
    return <service.Contenedor>[];
  }

  /// Crear contenedor offline-first
  Future<bool> createContenedor({
    required String nContenedor,
    required int naveDescarga,
    int? zonaInspeccion,
    String? fotoContenedorPath,
    String? precinto1,
    String? fotoPrecinto1Path,
    String? precinto2,
    String? fotoPrecinto2Path,
  }) async {
    try {
      state = const AsyncLoading();

      final success = await _service.createContenedorOfflineFirst(
        nContenedor: nContenedor,
        naveDescarga: naveDescarga,
        zonaInspeccion: zonaInspeccion,
        fotoContenedorPath: fotoContenedorPath,
        precinto1: precinto1,
        fotoPrecinto1Path: fotoPrecinto1Path,
        precinto2: precinto2,
        fotoPrecinto2Path: fotoPrecinto2Path,
      );

      if (success) {
        // Refrescar el provider unificado de cola
        ref.read(queueStateProvider.notifier).refreshState();

        // Recargar contenedores
        state = await AsyncValue.guard(() => build());

        return true;
      } else {
        state = AsyncError(
          'Error al guardar el contenedor',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  /// Método de conveniencia para crear desde formulario
  Future<bool> createContenedorFromForm(ContenedorFormData formData) async {
    return await createContenedor(
      nContenedor: formData.nContenedor,
      naveDescarga: formData.naveDescargaId,
      zonaInspeccion: formData.zonaInspeccionId,
      fotoContenedorPath: formData.fotoContenedorPath,
      precinto1: formData.precinto1,
      fotoPrecinto1Path: formData.fotoPrecinto1Path,
      precinto2: formData.precinto2,
      fotoPrecinto2Path: formData.fotoPrecinto2Path,
    );
  }
}

// ============================================================================
// PROVIDER DE ESTADO PARA CREACIÓN DE CONTENEDORES
// ============================================================================

/// Provider que maneja el estado de creación de contenedores
final contenedorCreationStateProvider =
    StateNotifierProvider<ContenedorCreationNotifier, ContenedorCreationState>((
      ref,
    ) {
      return ContenedorCreationNotifier(ref);
    });

// ============================================================================
// MODELOS DE DATOS PARA EL PROVIDER
// ============================================================================

class ContenedorFormData {
  final String nContenedor;
  final int naveDescargaId;
  final int? zonaInspeccionId;
  final String? fotoContenedorPath;
  final String? precinto1;
  final String? fotoPrecinto1Path;
  final String? precinto2;
  final String? fotoPrecinto2Path;

  const ContenedorFormData({
    required this.nContenedor,
    required this.naveDescargaId,
    this.zonaInspeccionId,
    this.fotoContenedorPath,
    this.precinto1,
    this.fotoPrecinto1Path,
    this.precinto2,
    this.fotoPrecinto2Path,
  });
}

class ContenedorValidationErrors {
  final String? nContenedor;
  final String? naveDescarga;
  final String? precinto1;

  const ContenedorValidationErrors({
    this.nContenedor,
    this.naveDescarga,
    this.precinto1,
  });

  ContenedorValidationErrors copyWith({
    String? nContenedor,
    String? naveDescarga,
    String? precinto1,
    bool clearNContenedor = false,
    bool clearNaveDescarga = false,
    bool clearPrecinto1 = false,
  }) {
    return ContenedorValidationErrors(
      nContenedor: clearNContenedor ? null : (nContenedor ?? this.nContenedor),
      naveDescarga: clearNaveDescarga
          ? null
          : (naveDescarga ?? this.naveDescarga),
      precinto1: clearPrecinto1 ? null : (precinto1 ?? this.precinto1),
    );
  }

  bool get hasErrors =>
      nContenedor != null || naveDescarga != null || precinto1 != null;
  bool get isEmpty => !hasErrors;
}

class ContenedorCreationState {
  // Campos del formulario
  final String? nContenedor;
  final int? naveDescargaSeleccionada;
  final int? zonaInspeccionSeleccionada;
  final String? precinto1;
  final String? precinto2;

  // Fotos específicas según el servicio
  final String? fotoContenedorPath;
  final String? fotoPrecinto1Path;
  final String? fotoPrecinto2Path;

  // Estados UI
  final bool isCreating;
  final String? errorMessage;
  final String? successMessage;
  final ContenedorValidationErrors validationErrors;

  const ContenedorCreationState({
    this.nContenedor,
    this.naveDescargaSeleccionada,
    this.zonaInspeccionSeleccionada,
    this.precinto1,
    this.precinto2,
    this.fotoContenedorPath,
    this.fotoPrecinto1Path,
    this.fotoPrecinto2Path,
    this.isCreating = false,
    this.errorMessage,
    this.successMessage,
    this.validationErrors = const ContenedorValidationErrors(),
  });

  ContenedorCreationState copyWith({
    String? nContenedor,
    int? naveDescargaSeleccionada,
    int? zonaInspeccionSeleccionada,
    String? precinto1,
    String? precinto2,
    String? fotoContenedorPath,
    String? fotoPrecinto1Path,
    String? fotoPrecinto2Path,
    bool? isCreating,
    String? errorMessage,
    String? successMessage,
    ContenedorValidationErrors? validationErrors,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearNaveDescarga = false,
    bool clearZonaInspeccion = false,
    bool clearFotoContenedor = false,
    bool clearFotoPrecinto1 = false,
    bool clearFotoPrecinto2 = false,
  }) {
    return ContenedorCreationState(
      nContenedor: nContenedor ?? this.nContenedor,
      naveDescargaSeleccionada: clearNaveDescarga
          ? null
          : (naveDescargaSeleccionada ?? this.naveDescargaSeleccionada),
      zonaInspeccionSeleccionada: clearZonaInspeccion
          ? null
          : (zonaInspeccionSeleccionada ?? this.zonaInspeccionSeleccionada),
      precinto1: precinto1 ?? this.precinto1,
      precinto2: precinto2 ?? this.precinto2,
      fotoContenedorPath: clearFotoContenedor
          ? null
          : (fotoContenedorPath ?? this.fotoContenedorPath),
      fotoPrecinto1Path: clearFotoPrecinto1
          ? null
          : (fotoPrecinto1Path ?? this.fotoPrecinto1Path),
      fotoPrecinto2Path: clearFotoPrecinto2
          ? null
          : (fotoPrecinto2Path ?? this.fotoPrecinto2Path),
      isCreating: isCreating ?? this.isCreating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  /// Verificar si el formulario es válido
  bool get isValid {
    return nContenedor != null &&
        nContenedor!.isNotEmpty &&
        naveDescargaSeleccionada != null &&
        validationErrors.isEmpty;
  }

  /// Obtener datos del formulario para envío
  ContenedorFormData get formData {
    return ContenedorFormData(
      nContenedor: nContenedor!,
      naveDescargaId: naveDescargaSeleccionada!,
      zonaInspeccionId: zonaInspeccionSeleccionada,
      fotoContenedorPath: fotoContenedorPath,
      precinto1: precinto1?.trim().isNotEmpty == true ? precinto1 : null,
      fotoPrecinto1Path: fotoPrecinto1Path,
      precinto2: precinto2?.trim().isNotEmpty == true ? precinto2 : null,
      fotoPrecinto2Path: fotoPrecinto2Path,
    );
  }

  /// Verificar si tiene foto del contenedor
  bool get hasFotoContenedor => fotoContenedorPath != null;

  /// Verificar si tiene foto del precinto 1
  bool get hasFotoPrecinto1 => fotoPrecinto1Path != null;

  /// Verificar si tiene foto del precinto 2
  bool get hasFotoPrecinto2 => fotoPrecinto2Path != null;

  /// Verificar si tiene precinto 2
  bool get hasPrecinto2 => precinto2 != null && precinto2!.isNotEmpty;
}

class ContenedorCreationNotifier
    extends StateNotifier<ContenedorCreationState> {
  final Ref ref;

  ContenedorCreationNotifier(this.ref) : super(const ContenedorCreationState());

  // Métodos de formulario
  void updateNContenedor(String nContenedor) {
    state = state.copyWith(
      nContenedor: nContenedor,
      validationErrors: state.validationErrors.copyWith(clearNContenedor: true),
    );
  }

  void selectNaveDescarga(int naveId) {
    state = state.copyWith(
      naveDescargaSeleccionada: naveId,
      validationErrors: state.validationErrors.copyWith(
        clearNaveDescarga: true,
      ),
    );
  }

  void selectZonaInspeccion(int? zonaId) {
    state = state.copyWith(zonaInspeccionSeleccionada: zonaId);
  }

  void updatePrecinto1(String precinto1) {
    state = state.copyWith(
      precinto1: precinto1,
      validationErrors: state.validationErrors.copyWith(clearPrecinto1: true),
    );
  }

  void updatePrecinto2(String precinto2) {
    state = state.copyWith(precinto2: precinto2);
  }

  // Métodos de fotos específicas
  void setFotoContenedor(String? fotoPath) {
    state = state.copyWith(fotoContenedorPath: fotoPath);
  }

  void setFotoPrecinto1(String? fotoPath) {
    state = state.copyWith(fotoPrecinto1Path: fotoPath);
  }

  void setFotoPrecinto2(String? fotoPath) {
    state = state.copyWith(fotoPrecinto2Path: fotoPath);
  }

  void removeFotoContenedor() {
    state = state.copyWith(clearFotoContenedor: true);
  }

  void removeFotoPrecinto1() {
    state = state.copyWith(clearFotoPrecinto1: true);
  }

  void removeFotoPrecinto2() {
    state = state.copyWith(clearFotoPrecinto2: true);
  }

  // Validación y envío
  ContenedorValidationErrors _validateForm() {
    return ContenedorValidationErrors(
      nContenedor: (state.nContenedor?.isEmpty ?? true)
          ? 'Debe ingresar el número de contenedor'
          : null,
      naveDescarga: state.naveDescargaSeleccionada == null
          ? 'Debe seleccionar una nave'
          : null,
      // Precinto1 no es requerido según el servicio
    );
  }

  Future<void> createContenedor() async {
    // Validar formulario
    final errors = _validateForm();
    if (errors.hasErrors) {
      state = state.copyWith(
        validationErrors: errors,
        errorMessage: 'Complete todos los campos requeridos',
      );
      return;
    }

    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final contenedoresNotifier = ref.read(contenedoresListProvider.notifier);
      final success = await contenedoresNotifier.createContenedorFromForm(
        state.formData,
      );

      if (success) {
        state = state.copyWith(
          isCreating: false,
          successMessage: 'Contenedor registrado exitosamente',
        );

        // Auto-limpiar formulario después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            resetForm();
          }
        });
      } else {
        state = state.copyWith(
          isCreating: false,
          errorMessage: 'Error al registrar el contenedor',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  // Métodos de limpieza
  void resetForm() {
    state = const ContenedorCreationState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void clearValidationErrors() {
    state = state.copyWith(
      validationErrors: const ContenedorValidationErrors(),
    );
  }
}

// ============================================================================
// PROVIDER DE ESTADO COMBINADO
// ============================================================================

/// Provider que combina opciones, contenedores y estado de creación
final contenedoresCompleteStateProvider = Provider<ContenedoresCompleteState>((
  ref,
) {
  final contenedoresAsync = ref.watch(contenedoresListProvider);
  final optionsAsync = ref.watch(contenedoresOptionsProvider);
  final creationState = ref.watch(contenedorCreationStateProvider);
  final queueState = ref.watch(queueStateProvider);

  return ContenedoresCompleteState(
    contenedores: contenedoresAsync.value ?? [],
    options: optionsAsync.value,
    isLoading: contenedoresAsync.isLoading || optionsAsync.isLoading,
    error: contenedoresAsync.error ?? optionsAsync.error,
    creationState: creationState,
    pendingCount: queueState.pendingCount,
  );
});

class ContenedoresCompleteState {
  final List<service.Contenedor> contenedores;
  final service.ContenedoresOptions? options;
  final bool isLoading;
  final Object? error;
  final ContenedorCreationState creationState;
  final int pendingCount;

  const ContenedoresCompleteState({
    required this.contenedores,
    this.options,
    required this.isLoading,
    this.error,
    required this.creationState,
    required this.pendingCount,
  });

  bool get hasError => error != null;
  bool get hasContenedores => contenedores.isNotEmpty;
  bool get hasOptions => options != null;
  int get totalContenedores => contenedores.length;
}

// ============================================================================
// PROVIDERS DE CONVENIENCIA
// ============================================================================

/// Provider para obtener conteo de contenedores pendientes
final contenedoresPendientesCountProvider = FutureProvider<int>((ref) async {
  final serviceInstance = ref.read(contenedoresServiceProvider);
  return await serviceInstance.getPendingCount();
});
