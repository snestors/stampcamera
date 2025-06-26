// lib/providers/autos/danos_provider.dart
// 🔧 PROVIDER OFFLINE-FIRST PARA DAÑOS
// ✅ Siguiendo patrón de PedeteoProvider + FotosPresentacionProvider
// ✅ Soporte para múltiples imágenes por daño
// ✅ Estados complejos para creación de daños

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/danos_model.dart';
import 'package:stampcamera/models/autos/detalle_registro_model.dart';
import 'package:stampcamera/services/danos_service.dart' as service;
import 'package:stampcamera/providers/autos/queue_state_provider.dart';

// ============================================================================
// SERVICIO PROVIDER
// ============================================================================

/// Provider del servicio de daños
final danosServiceProvider = Provider<service.DanosService>((ref) {
  return service.DanosService();
});

// ============================================================================
// PROVIDER DE OPCIONES (CACHED)
// ============================================================================

/// Provider que obtiene las opciones del endpoint /options una sola vez
final danosOptionsProvider = FutureProvider<DanosOptions>((ref) async {
  final serviceInstance = ref.read(danosServiceProvider);
  final serviceOptions = await serviceInstance.getOptions();

  // Convertir del modelo del servicio al modelo del provider
  return DanosOptions(
    tiposDano: serviceOptions.tiposDano.map((tipo) {
      return TipoDanoOption(value: tipo.value, label: tipo.label);
    }).toList(),
    areasDano: serviceOptions.areasDano.map((area) {
      return AreaDanoOption(value: area.value, label: area.label);
    }).toList(),
    severidades: serviceOptions.severidades.map((sev) {
      return SeveridadOption(value: sev.value, label: sev.label);
    }).toList(),
    zonasDanos: serviceOptions.zonasDanos.map((zona) {
      return ZonaDanoOption(value: zona.value, label: zona.label);
    }).toList(),
    responsabilidades: serviceOptions.responsabilidades.map((resp) {
      return ResponsabilidadOption(value: resp.value, label: resp.label);
    }).toList(),
  );
});

// Providers derivados para fácil acceso en widgets
final tiposDanoDisponiblesProvider = Provider<List<TipoDanoOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.tiposDano ?? [];
});

final areasDanoDisponiblesProvider = Provider<List<AreaDanoOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.areasDano ?? [];
});

final severidadesDisponiblesProvider = Provider<List<SeveridadOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.severidades ?? [];
});

final zonasDanosDisponiblesProvider = Provider<List<ZonaDanoOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.zonasDanos ?? [];
});

final responsabilidadesDisponiblesProvider =
    Provider<List<ResponsabilidadOption>>((ref) {
      final optionsAsync = ref.watch(danosOptionsProvider);
      return optionsAsync.value?.responsabilidades ?? [];
    });

// ============================================================================
// PROVIDER PRINCIPAL DE DAÑOS POR REGISTRO VIN
// ============================================================================

/// Provider que maneja los daños de un registro VIN específico
final danosPorRegistroProvider =
    AsyncNotifierProvider.family<DanosNotifier, List<Dano>, int>(
      () => DanosNotifier(),
    );

class DanosNotifier extends FamilyAsyncNotifier<List<Dano>, int> {
  late service.DanosService _service;

  @override
  Future<List<Dano>> build(int registroVinId) async {
    ref.keepAlive();
    _service = ref.read(danosServiceProvider);

    // TODO: Implementar cuando haya endpoint de listado de daños por registro
    // Por ahora retornamos lista vacía ya que el servicio se enfoca en creación
    return <Dano>[];
  }

  /// Crear daño offline-first con múltiples imágenes
  Future<bool> createDano({
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<String>? imagePaths,
  }) async {
    try {
      state = const AsyncLoading();

      final success = await _service.createDanoOfflineFirst(
        registroVinId: arg,
        tipoDano: tipoDano,
        areaDano: areaDano,
        severidad: severidad,
        zonas: zonas,
        descripcion: descripcion,
        responsabilidad: responsabilidad,
        relevante: relevante,
        imagePaths: imagePaths,
      );

      if (success) {
        // Refrescar el provider unificado de cola
        ref.read(queueStateProvider.notifier).refreshState();

        // Recargar daños (cuando se implemente el endpoint)
        state = await AsyncValue.guard(() => build(arg));

        return true;
      } else {
        state = AsyncError('Error al guardar el daño', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  /// Método de conveniencia para crear daño desde formulario
  Future<bool> createDanoFromForm(DanoFormData formData) async {
    return await createDano(
      tipoDano: formData.tipoDano,
      areaDano: formData.areaDano,
      severidad: formData.severidad,
      zonas: formData.zonas,
      descripcion: formData.descripcion,
      responsabilidad: formData.responsabilidad,
      relevante: formData.relevante,
      imagePaths: formData.imagePaths,
    );
  }
}

// ============================================================================
// PROVIDER DE ESTADO PARA CREACIÓN DE DAÑOS
// ============================================================================

/// Provider que maneja el estado complejo de creación de daños
final danoCreationStateProvider =
    StateNotifierProvider.family<DanoCreationNotifier, DanoCreationState, int>((
      ref,
      registroVinId,
    ) {
      return DanoCreationNotifier(registroVinId, ref);
    });

// ============================================================================
// MODELOS DE DATOS PARA EL PROVIDER
// ============================================================================

class DanoFormData {
  final int tipoDano;
  final int areaDano;
  final int severidad;
  final List<int>? zonas;
  final String? descripcion;
  final int? responsabilidad;
  final bool relevante;
  final List<String> imagePaths;

  const DanoFormData({
    required this.tipoDano,
    required this.areaDano,
    required this.severidad,
    this.zonas,
    this.descripcion,
    this.responsabilidad,
    this.relevante = false,
    this.imagePaths = const [],
  });
}

class DanoValidationErrors {
  final String? tipoDano;
  final String? areaDano;
  final String? severidad;

  const DanoValidationErrors({this.tipoDano, this.areaDano, this.severidad});

  DanoValidationErrors copyWith({
    String? tipoDano,
    String? areaDano,
    String? severidad,
    bool clearTipoDano = false,
    bool clearAreaDano = false,
    bool clearSeveridad = false,
  }) {
    return DanoValidationErrors(
      tipoDano: clearTipoDano ? null : (tipoDano ?? this.tipoDano),
      areaDano: clearAreaDano ? null : (areaDano ?? this.areaDano),
      severidad: clearSeveridad ? null : (severidad ?? this.severidad),
    );
  }

  bool get hasErrors =>
      tipoDano != null || areaDano != null || severidad != null;
  bool get isEmpty => !hasErrors;
}

class DanoCreationState {
  // Campos del formulario
  final int? tipoDanoSeleccionado;
  final int? areaDanoSeleccionada;
  final int? severidadSeleccionada;
  final List<int> zonasSeleccionadas;
  final String? descripcion;
  final int? responsabilidadSeleccionada;
  final bool relevante;

  // Imágenes
  final List<String> imagePaths;
  final int maxImages;

  // Estados UI
  final bool isCreating;
  final bool showImagePicker;
  final String? errorMessage;
  final String? successMessage;
  final DanoValidationErrors validationErrors;

  const DanoCreationState({
    this.tipoDanoSeleccionado,
    this.areaDanoSeleccionada,
    this.severidadSeleccionada,
    this.zonasSeleccionadas = const [],
    this.descripcion,
    this.responsabilidadSeleccionada,
    this.relevante = false,
    this.imagePaths = const [],
    this.maxImages = 15,
    this.isCreating = false,
    this.showImagePicker = false,
    this.errorMessage,
    this.successMessage,
    this.validationErrors = const DanoValidationErrors(),
  });

  DanoCreationState copyWith({
    int? tipoDanoSeleccionado,
    int? areaDanoSeleccionada,
    int? severidadSeleccionada,
    List<int>? zonasSeleccionadas,
    String? descripcion,
    int? responsabilidadSeleccionada,
    bool? relevante,
    List<String>? imagePaths,
    int? maxImages,
    bool? isCreating,
    bool? showImagePicker,
    String? errorMessage,
    String? successMessage,
    DanoValidationErrors? validationErrors,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearTipoDano = false,
    bool clearAreaDano = false,
    bool clearSeveridad = false,
    bool clearResponsabilidad = false,
  }) {
    return DanoCreationState(
      tipoDanoSeleccionado: clearTipoDano
          ? null
          : (tipoDanoSeleccionado ?? this.tipoDanoSeleccionado),
      areaDanoSeleccionada: clearAreaDano
          ? null
          : (areaDanoSeleccionada ?? this.areaDanoSeleccionada),
      severidadSeleccionada: clearSeveridad
          ? null
          : (severidadSeleccionada ?? this.severidadSeleccionada),
      zonasSeleccionadas: zonasSeleccionadas ?? this.zonasSeleccionadas,
      descripcion: descripcion ?? this.descripcion,
      responsabilidadSeleccionada: clearResponsabilidad
          ? null
          : (responsabilidadSeleccionada ?? this.responsabilidadSeleccionada),
      relevante: relevante ?? this.relevante,
      imagePaths: imagePaths ?? this.imagePaths,
      maxImages: maxImages ?? this.maxImages,
      isCreating: isCreating ?? this.isCreating,
      showImagePicker: showImagePicker ?? this.showImagePicker,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  /// Verificar si el formulario es válido
  bool get isValid {
    return tipoDanoSeleccionado != null &&
        areaDanoSeleccionada != null &&
        severidadSeleccionada != null &&
        validationErrors.isEmpty;
  }

  /// Verificar si puede agregar más imágenes
  bool get canAddMoreImages => imagePaths.length < maxImages;

  /// Obtener datos del formulario para envío
  DanoFormData get formData {
    return DanoFormData(
      tipoDano: tipoDanoSeleccionado!,
      areaDano: areaDanoSeleccionada!,
      severidad: severidadSeleccionada!,
      zonas: zonasSeleccionadas.isNotEmpty ? zonasSeleccionadas : null,
      descripcion: descripcion?.trim().isNotEmpty == true ? descripcion : null,
      responsabilidad: responsabilidadSeleccionada,
      relevante: relevante,
      imagePaths: imagePaths,
    );
  }
}

class DanoCreationNotifier extends StateNotifier<DanoCreationState> {
  final int registroVinId;
  final Ref ref;

  DanoCreationNotifier(this.registroVinId, this.ref)
    : super(const DanoCreationState());

  // Métodos de formulario
  void selectTipoDano(int tipoDano) {
    state = state.copyWith(
      tipoDanoSeleccionado: tipoDano,
      validationErrors: state.validationErrors.copyWith(clearTipoDano: true),
    );
  }

  void selectAreaDano(int areaDano) {
    state = state.copyWith(
      areaDanoSeleccionada: areaDano,
      validationErrors: state.validationErrors.copyWith(clearAreaDano: true),
    );
  }

  void selectSeveridad(int severidad) {
    state = state.copyWith(
      severidadSeleccionada: severidad,
      validationErrors: state.validationErrors.copyWith(clearSeveridad: true),
    );
  }

  void toggleZona(int zona) {
    final currentZonas = List<int>.from(state.zonasSeleccionadas);
    if (currentZonas.contains(zona)) {
      currentZonas.remove(zona);
    } else {
      currentZonas.add(zona);
    }
    state = state.copyWith(zonasSeleccionadas: currentZonas);
  }

  void updateDescripcion(String descripcion) {
    state = state.copyWith(descripcion: descripcion);
  }

  void selectResponsabilidad(int? responsabilidad) {
    state = state.copyWith(responsabilidadSeleccionada: responsabilidad);
  }

  void toggleRelevante() {
    state = state.copyWith(relevante: !state.relevante);
  }

  // Métodos de imágenes
  void addImage(String imagePath) {
    if (state.canAddMoreImages) {
      final newImages = List<String>.from(state.imagePaths);
      newImages.add(imagePath);
      state = state.copyWith(imagePaths: newImages);
    }
  }

  void removeImage(int index) {
    final newImages = List<String>.from(state.imagePaths);
    if (index >= 0 && index < newImages.length) {
      newImages.removeAt(index);
      state = state.copyWith(imagePaths: newImages);
    }
  }

  void removeImageByPath(String imagePath) {
    final newImages = List<String>.from(state.imagePaths);
    newImages.remove(imagePath);
    state = state.copyWith(imagePaths: newImages);
  }

  void clearAllImages() {
    state = state.copyWith(imagePaths: []);
  }

  void toggleImagePicker() {
    state = state.copyWith(showImagePicker: !state.showImagePicker);
  }

  // Validación y envío
  DanoValidationErrors _validateForm() {
    return DanoValidationErrors(
      tipoDano: state.tipoDanoSeleccionado == null
          ? 'Debe seleccionar un tipo de daño'
          : null,
      areaDano: state.areaDanoSeleccionada == null
          ? 'Debe seleccionar un área de daño'
          : null,
      severidad: state.severidadSeleccionada == null
          ? 'Debe seleccionar una severidad'
          : null,
    );
  }

  Future<void> createDano() async {
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
      final danosNotifier = ref.read(
        danosPorRegistroProvider(registroVinId).notifier,
      );
      final success = await danosNotifier.createDanoFromForm(state.formData);

      if (success) {
        state = state.copyWith(
          isCreating: false,
          successMessage: 'Daño registrado exitosamente',
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
          errorMessage: 'Error al registrar el daño',
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
    state = const DanoCreationState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void clearValidationErrors() {
    state = state.copyWith(validationErrors: const DanoValidationErrors());
  }
}

// ============================================================================
// PROVIDER DE ESTADO COMBINADO
// ============================================================================

/// Provider que combina opciones, daños y estado de creación
final danosCompleteStateProvider = Provider.family<DanosCompleteState, int>((
  ref,
  registroVinId,
) {
  final danosAsync = ref.watch(danosPorRegistroProvider(registroVinId));
  final optionsAsync = ref.watch(danosOptionsProvider);
  final creationState = ref.watch(danoCreationStateProvider(registroVinId));
  final queueState = ref.watch(queueStateProvider);

  return DanosCompleteState(
    danos: danosAsync.value ?? [],
    options: optionsAsync.value,
    isLoading: danosAsync.isLoading || optionsAsync.isLoading,
    error: danosAsync.error ?? optionsAsync.error,
    creationState: creationState,
    pendingCount: queueState.pendingCount,
  );
});

class DanosCompleteState {
  final List<Dano> danos;
  final DanosOptions? options;
  final bool isLoading;
  final Object? error;
  final DanoCreationState creationState;
  final int pendingCount;

  const DanosCompleteState({
    required this.danos,
    this.options,
    required this.isLoading,
    this.error,
    required this.creationState,
    required this.pendingCount,
  });

  bool get hasError => error != null;
  bool get hasDanos => danos.isNotEmpty;
  bool get hasOptions => options != null;
  int get totalDanos => danos.length;
}

// ============================================================================
// PROVIDERS DE CONVENIENCIA
// ============================================================================

/// Provider para obtener conteo de daños pendientes
final danosPendientesCountProvider = FutureProvider.family<int, int>((
  ref,
  registroVinId,
) async {
  final serviceInstance = ref.read(danosServiceProvider);
  return await serviceInstance.getPendingCount();
});
