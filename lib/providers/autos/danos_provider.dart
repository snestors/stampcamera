// lib/providers/autos/danos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/services/danos_service.dart';
import 'package:stampcamera/providers/autos/queue_state_provider.dart';

// ============================================================================
// SERVICIO PROVIDER
// ============================================================================

/// Provider del servicio de daños
final danosServiceProvider = Provider<DanosService>((ref) {
  return DanosService();
});

// ============================================================================
// PROVIDER DE OPCIONES (CACHED)
// ============================================================================

/// Provider que obtiene las opciones de daños (una sola vez)
final danosOptionsProvider = FutureProvider<DanosOptions>((ref) async {
  final service = ref.read(danosServiceProvider);
  return await service.getOptions();
});

/// Providers individuales para cada tipo de opción
final tiposDanoProvider = Provider<List<TipoDanoOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.tiposDano ?? [];
});

final areasDanoProvider = Provider<List<AreaDanoOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.areasDano ?? [];
});

final severidadesProvider = Provider<List<SeveridadOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.severidades ?? [];
});

final zonasDanosProvider = Provider<List<ZonaDanoOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.zonasDanos ?? [];
});

final responsabilidadesProvider = Provider<List<ResponsabilidadOption>>((ref) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.responsabilidades ?? [];
});

/// Provider para los permisos de campos
final danosFieldPermissionsProvider = Provider<Map<String, FieldPermission>>((
  ref,
) {
  final optionsAsync = ref.watch(danosOptionsProvider);
  return optionsAsync.value?.fieldPermissions ?? {};
});

// ============================================================================
// PROVIDER PARA REGISTROS VIN DISPONIBLES (DESDE DETALLE)
// ============================================================================

/// Provider que obtiene los registros VIN disponibles desde el detalle de registro-general
/// Este provider debe ser configurado cuando se carga el detalle de un VIN
final registrosVinDisponiblesProvider = StateProvider<List<Map<String, dynamic>>>((
  ref,
) {
  // Lista de registros VIN del detalle (registros_vin del GET /registro-general/{vin}/)
  return <Map<String, dynamic>>[];
});

/// Helper para obtener solo los IDs de los registros VIN disponibles
final registrosVinIdsProvider = Provider<List<int>>((ref) {
  final registros = ref.watch(registrosVinDisponiblesProvider);
  return registros.map((r) => r['id'] as int).toList();
});

/// Helper para obtener un registro VIN específico por ID
final getRegistroVinByIdProvider = Provider.family<Map<String, dynamic>?, int>((
  ref,
  registroId,
) {
  final registros = ref.watch(registrosVinDisponiblesProvider);
  try {
    return registros.firstWhere((r) => r['id'] == registroId);
  } catch (e) {
    return null;
  }
});

// ============================================================================
// PROVIDER PRINCIPAL DE DAÑOS
// ============================================================================

/// Provider principal que maneja el estado de daños
final danosStateProvider = StateNotifierProvider<DanosNotifier, DanosState>((
  ref,
) {
  return DanosNotifier(ref);
});

// ============================================================================
// ESTADO DEL PROVIDER
// ============================================================================

class DanosState {
  final int? selectedRegistroVinId;
  final bool isCreating;
  final bool isAddingImages;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic> creationProgress; // Para tracking de creación
  final List<String> pendingImages; // Imágenes pendientes por subir

  const DanosState({
    this.selectedRegistroVinId,
    this.isCreating = false,
    this.isAddingImages = false,
    this.errorMessage,
    this.successMessage,
    this.creationProgress = const {},
    this.pendingImages = const [],
  });

  DanosState copyWith({
    int? selectedRegistroVinId,
    bool? isCreating,
    bool? isAddingImages,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? creationProgress,
    List<String>? pendingImages,
    bool clearSelectedVin = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearProgress = false,
    bool clearPendingImages = false,
  }) {
    return DanosState(
      selectedRegistroVinId: clearSelectedVin
          ? null
          : (selectedRegistroVinId ?? this.selectedRegistroVinId),
      isCreating: isCreating ?? this.isCreating,
      isAddingImages: isAddingImages ?? this.isAddingImages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      creationProgress: clearProgress
          ? {}
          : (creationProgress ?? this.creationProgress),
      pendingImages: clearPendingImages
          ? []
          : (pendingImages ?? this.pendingImages),
    );
  }

  /// Helper: ¿Hay operaciones activas?
  bool get isLoading => isCreating || isAddingImages;

  /// Helper: ¿Hay un registro seleccionado?
  bool get hasSelectedRegistro => selectedRegistroVinId != null;

  /// Helper: ¿Hay imágenes pendientes?
  bool get hasPendingImages => pendingImages.isNotEmpty;
}

// ============================================================================
// NOTIFIER PRINCIPAL
// ============================================================================

class DanosNotifier extends StateNotifier<DanosState> {
  final Ref ref;

  DanosNotifier(this.ref) : super(const DanosState());

  // ============================================================================
  // MÉTODO DE CONFIGURACIÓN
  // ============================================================================

  /// Seleccionar registro VIN para trabajar
  void selectRegistroVin(int registroVinId) {
    state = state.copyWith(
      selectedRegistroVinId: registroVinId,
      clearError: true,
      clearSuccess: true,
      clearPendingImages: true,
    );
  }

  /// Limpiar registro seleccionado
  void clearSelectedRegistro() {
    state = state.copyWith(
      clearSelectedVin: true,
      clearError: true,
      clearSuccess: true,
      clearPendingImages: true,
    );
  }

  // ============================================================================
  // MÉTODOS OFFLINE-FIRST PARA CREAR DAÑOS (AMBOS ENFOQUES)
  // ============================================================================

  /// Crear daño (offline-first) para un registro específico
  Future<void> createDanoOfflineFirst({
    required int registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<String>? imagePaths,
  }) async {
    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final service = ref.read(danosServiceProvider);

      final success = await service.createDanoOfflineFirst(
        registroVinId: registroVinId,
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
        // Refrescar estado de queue
        ref.read(queueStateProvider.notifier).refreshState();

        final imageCount = imagePaths?.length ?? 0;
        final message = imageCount > 0
            ? 'Daño creado con $imageCount imágenes. Se enviará automáticamente.'
            : 'Daño creado exitosamente. Se enviará automáticamente.';

        state = state.copyWith(isCreating: false, successMessage: message);

        // Auto-limpiar mensaje después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            state = state.copyWith(clearSuccess: true);
          }
        });
      } else {
        state = state.copyWith(
          isCreating: false,
          errorMessage: 'Error al crear el daño',
        );
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isCreating: false, errorMessage: errorMessage);
    }
  }

  /// Crear daño al registro seleccionado (enfoque con estado)
  Future<void> createDanoToSelected({
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<String>? imagePaths,
  }) async {
    if (state.selectedRegistroVinId == null) {
      state = state.copyWith(
        errorMessage: 'Debe seleccionar un registro VIN primero',
      );
      return;
    }

    await createDanoOfflineFirst(
      registroVinId: state.selectedRegistroVinId!,
      tipoDano: tipoDano,
      areaDano: areaDano,
      severidad: severidad,
      zonas: zonas,
      descripcion: descripcion,
      responsabilidad: responsabilidad,
      relevante: relevante,
      imagePaths: imagePaths,
    );
  }

  // ============================================================================
  // MÉTODOS PARA MANEJO DE IMÁGENES PENDIENTES
  // ============================================================================

  /// Agregar imagen a la lista de pendientes
  void addPendingImage(String imagePath) {
    final currentImages = List<String>.from(state.pendingImages);
    if (!currentImages.contains(imagePath)) {
      currentImages.add(imagePath);
      state = state.copyWith(pendingImages: currentImages);
    }
  }

  /// Remover imagen de la lista de pendientes
  void removePendingImage(String imagePath) {
    final currentImages = List<String>.from(state.pendingImages);
    currentImages.remove(imagePath);
    state = state.copyWith(pendingImages: currentImages);
  }

  /// Limpiar todas las imágenes pendientes
  void clearPendingImages() {
    state = state.copyWith(clearPendingImages: true);
  }

  /// Crear daño con las imágenes pendientes
  Future<void> createDanoWithPendingImages({
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
  }) async {
    final imagePaths = state.pendingImages.isNotEmpty
        ? state.pendingImages
        : null;

    if (state.selectedRegistroVinId != null) {
      await createDanoToSelected(
        tipoDano: tipoDano,
        areaDano: areaDano,
        severidad: severidad,
        zonas: zonas,
        descripcion: descripcion,
        responsabilidad: responsabilidad,
        relevante: relevante,
        imagePaths: imagePaths,
      );

      // Limpiar imágenes pendientes después de crear
      if (state.successMessage != null) {
        clearPendingImages();
      }
    } else {
      state = state.copyWith(
        errorMessage: 'Debe seleccionar un registro VIN primero',
      );
    }
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
    state = const DanosState();
  }

  // ============================================================================
  // HELPER METHODS PARA WIDGETS
  // ============================================================================

  /// Helper para obtener el label de un tipo de daño
  String? getLabelForTipoDano(int tipoId) {
    final tipos = ref.read(tiposDanoProvider);
    final tipo = tipos.where((t) => t.value == tipoId).firstOrNull;
    return tipo?.label;
  }

  /// Helper para obtener el label de un área de daño
  String? getLabelForAreaDano(int areaId) {
    final areas = ref.read(areasDanoProvider);
    final area = areas.where((a) => a.value == areaId).firstOrNull;
    return area?.label;
  }

  /// Helper para obtener el label de una severidad
  String? getLabelForSeveridad(int severidadId) {
    final severidades = ref.read(severidadesProvider);
    final severidad = severidades
        .where((s) => s.value == severidadId)
        .firstOrNull;
    return severidad?.label;
  }

  /// Helper para validar si todos los campos requeridos están completos
  bool validateDanoData({
    required int? tipoDano,
    required int? areaDano,
    required int? severidad,
  }) {
    return tipoDano != null && areaDano != null && severidad != null;
  }
}

// ============================================================================
// PROVIDERS DERIVADOS PARA WIDGETS ESPECÍFICOS
// ============================================================================

/// Provider que expone si hay operaciones cargando
final danosIsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(danosStateProvider);
  return state.isLoading;
});

/// Provider que expone si hay mensajes de error
final danosHasErrorProvider = Provider<bool>((ref) {
  final state = ref.watch(danosStateProvider);
  return state.errorMessage != null;
});

/// Provider que expone si hay mensajes de éxito
final danosHasSuccessProvider = Provider<bool>((ref) {
  final state = ref.watch(danosStateProvider);
  return state.successMessage != null;
});

/// Provider que expone si hay un registro seleccionado
final danosHasSelectedRegistroProvider = Provider<bool>((ref) {
  final state = ref.watch(danosStateProvider);
  return state.hasSelectedRegistro;
});

/// Provider que expone el ID del registro seleccionado
final danosSelectedRegistroIdProvider = Provider<int?>((ref) {
  final state = ref.watch(danosStateProvider);
  return state.selectedRegistroVinId;
});

/// Provider que expone el conteo de imágenes pendientes
final danosPendingImagesCountProvider = Provider<int>((ref) {
  final state = ref.watch(danosStateProvider);
  return state.pendingImages.length;
});

/// Provider que expone las imágenes pendientes
final danosPendingImagesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(danosStateProvider);
  return state.pendingImages;
});

// ============================================================================
// PROVIDERS DE MAPAS PARA DROPDOWNS
// ============================================================================

/// Provider que expone tipos de daño como Map<int, String>
final tiposDanoMapProvider = Provider<Map<int, String>>((ref) {
  final tipos = ref.watch(tiposDanoProvider);
  return {for (var tipo in tipos) tipo.value: tipo.label};
});

/// Provider que expone áreas de daño como Map<int, String>
final areasDanoMapProvider = Provider<Map<int, String>>((ref) {
  final areas = ref.watch(areasDanoProvider);
  return {for (var area in areas) area.value: area.label};
});

/// Provider que expone severidades como Map<int, String>
final severidadesMapProvider = Provider<Map<int, String>>((ref) {
  final severidades = ref.watch(severidadesProvider);
  return {for (var severidad in severidades) severidad.value: severidad.label};
});

/// Provider que expone zonas como Map<int, String>
final zonasDanosMapProvider = Provider<Map<int, String>>((ref) {
  final zonas = ref.watch(zonasDanosProvider);
  return {for (var zona in zonas) zona.value: zona.label};
});

/// Provider que expone responsabilidades como Map<int, String>
final responsabilidadesMapProvider = Provider<Map<int, String>>((ref) {
  final responsabilidades = ref.watch(responsabilidadesProvider);
  return {for (var resp in responsabilidades) resp.value: resp.label};
});

// ============================================================================
// PROVIDER ESPECÍFICO PARA REGISTRO VIN (FAMILY)
// ============================================================================

/// Provider para el estado de daños de un registro VIN específico
/// Mantiene track de los daños locales por registro
final danosForRegistroProvider =
    StateProvider.family<List<Map<String, dynamic>>, int>((ref, registroVinId) {
      // Lista de daños para un registro específico
      return <Map<String, dynamic>>[];
    });

/// Provider simplificado para crear daño directamente a un registro específico
final createDanoDirectProvider =
    Provider.family<Future<void> Function(Map<String, dynamic>), int>((
      ref,
      registroVinId,
    ) {
      return (Map<String, dynamic> danoData) async {
        final notifier = ref.read(danosStateProvider.notifier);

        await notifier.createDanoOfflineFirst(
          registroVinId: registroVinId,
          tipoDano: danoData['tipoDano'],
          areaDano: danoData['areaDano'],
          severidad: danoData['severidad'],
          zonas: danoData['zonas'],
          descripcion: danoData['descripcion'],
          responsabilidad: danoData['responsabilidad'],
          relevante: danoData['relevante'] ?? false,
          imagePaths: danoData['imagePaths'],
        );

        // Agregar a la lista local para tracking
        final currentDanos = ref.read(
          danosForRegistroProvider(registroVinId).notifier,
        );
        currentDanos.state = [...currentDanos.state, danoData];
      };
    });
