// lib/providers/autos/inventarios_provider.dart
// 📋 PROVIDER OFFLINE-FIRST PARA INVENTARIOS
// ✅ Siguiendo patrón establecido pero con mayor complejidad
// ✅ Soporte para plantillas dinámicas por modelo/versión
// ✅ Campos configurables desde backend

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/inventarios_model.dart';
import 'package:stampcamera/services/inventarios_service.dart' as service;
import 'package:stampcamera/providers/autos/queue_state_provider.dart';

// ============================================================================
// SERVICIO PROVIDER
// ============================================================================

/// Provider del servicio de inventarios
final inventariosServiceProvider = Provider<service.InventariosService>((ref) {
  return service.InventariosService();
});

// ============================================================================
// PROVIDER DE OPCIONES DINÁMICAS (CACHED POR MODELO/VERSIÓN)
// ============================================================================

/// Provider que obtiene las opciones dinámicas basadas en modelo y versión
/// Se mantiene en caché por combinación de modelo/versión
final inventarioOptionsProvider =
    FutureProvider.family<InventarioOptions, (String, String?)>((
      ref,
      params,
    ) async {
      final (modelo, version) = params;
      final serviceInstance = ref.read(inventariosServiceProvider);
      final serviceOptions = await serviceInstance.getInventarioOptions(
        modelo: modelo,
        version: version,
      );

      // Convertir del modelo del servicio al modelo del provider
      return InventarioOptions(
        modelo: serviceOptions.modelo,
        version: serviceOptions.version,
        campos: serviceOptions.campos.map((campo) {
          return CampoInventario(
            nombre: campo.nombre,
            tipo: CampoTipo.values.firstWhere(
              (t) => t.name == campo.tipo.name,
              orElse: () => CampoTipo.texto,
            ),
            requerido: campo.requerido,
            label: campo.label,
            opciones: campo.opciones,
            valorPorDefecto: campo.valorPorDefecto,
            placeholder: campo.placeholder,
            validaciones: campo.validaciones != null
                ? CampoValidaciones.fromJson(campo.validaciones!.toJson())
                : null,
          );
        }).toList(),
        configuracion: InventarioConfiguracion(
          permiteMultiplesInventarios:
              serviceOptions.configuracion.permiteMultiplesInventarios,
          requiereFotos: serviceOptions.configuracion.requiereFotos,
          maxFotos: serviceOptions.configuracion.maxFotos,
          tiposFotoPermitidos: serviceOptions.configuracion.tiposFotoPermitidos,
        ),
      );
    });

// Providers derivados para acceso rápido
final camposInventarioProvider =
    Provider.family<List<CampoInventario>, (String, String?)>((ref, params) {
      final optionsAsync = ref.watch(inventarioOptionsProvider(params));
      return optionsAsync.value?.campos ?? [];
    });

final configuracionInventarioProvider =
    Provider.family<InventarioConfiguracion?, (String, String?)>((ref, params) {
      final optionsAsync = ref.watch(inventarioOptionsProvider(params));
      return optionsAsync.value?.configuracion;
    });

// ============================================================================
// PROVIDER PRINCIPAL DE INVENTARIOS POR VIN
// ============================================================================

/// Provider que maneja los inventarios de un VIN específico
final inventariosPorVinProvider =
    AsyncNotifierProvider.family<InventariosNotifier, List<Inventario>, String>(
      () => InventariosNotifier(),
    );

class InventariosNotifier
    extends FamilyAsyncNotifier<List<Inventario>, String> {
  late service.InventariosService _service;

  @override
  Future<List<Inventario>> build(String vin) async {
    ref.keepAlive();
    _service = ref.read(inventariosServiceProvider);

    // TODO: Implementar cuando haya endpoint de listado de inventarios por VIN
    // Por ahora retornamos lista vacía ya que el servicio se enfoca en creación
    return <Inventario>[];
  }

  /// Crear o actualizar inventario offline-first
  Future<bool> createOrUpdateInventario({
    required String modelo,
    String? version,
    required Map<String, dynamic> camposData,
    List<String>? fotoPaths,
  }) async {
    try {
      state = const AsyncLoading();

      final success = await _service.createOrUpdateInventarioOfflineFirst(
        vin: arg,
        modelo: modelo,
        version: version,
        camposData: camposData,
        fotoPaths: fotoPaths,
      );

      if (success) {
        // Refrescar el provider unificado de cola
        ref.read(queueStateProvider.notifier).refreshState();

        // Recargar inventarios
        state = await AsyncValue.guard(() => build(arg));

        return true;
      } else {
        state = AsyncError(
          'Error al guardar el inventario',
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
  Future<bool> createInventarioFromForm(InventarioFormData formData) async {
    return await createOrUpdateInventario(
      modelo: formData.modelo,
      version: formData.version,
      camposData: formData.camposData,
      fotoPaths: formData.fotoPaths,
    );
  }
}

// ============================================================================
// PROVIDER DE ESTADO PARA CREACIÓN DE INVENTARIOS
// ============================================================================

/// Provider que maneja el estado complejo de creación de inventarios
final inventarioCreationStateProvider =
    StateNotifierProvider.family<
      InventarioCreationNotifier,
      InventarioCreationState,
      String
    >((ref, vin) {
      return InventarioCreationNotifier(vin, ref);
    });

// ============================================================================
// MODELOS DE DATOS PARA EL PROVIDER
// ============================================================================

class InventarioFormData {
  final String vin;
  final String modelo;
  final String? version;
  final Map<String, dynamic> camposData;
  final List<String> fotoPaths;

  const InventarioFormData({
    required this.vin,
    required this.modelo,
    this.version,
    required this.camposData,
    this.fotoPaths = const [],
  });
}

class InventarioValidationErrors {
  final String? modelo;
  final Map<String, String> camposErrors;

  const InventarioValidationErrors({this.modelo, this.camposErrors = const {}});

  InventarioValidationErrors copyWith({
    String? modelo,
    Map<String, String>? camposErrors,
    bool clearModelo = false,
    String? clearCampoError,
  }) {
    Map<String, String> newCamposErrors = Map.from(this.camposErrors);

    if (clearCampoError != null) {
      newCamposErrors.remove(clearCampoError);
    }

    if (camposErrors != null) {
      newCamposErrors.addAll(camposErrors);
    }

    return InventarioValidationErrors(
      modelo: clearModelo ? null : (modelo ?? this.modelo),
      camposErrors: newCamposErrors,
    );
  }

  bool get hasErrors => modelo != null || camposErrors.isNotEmpty;
  bool get isEmpty => !hasErrors;
}

class InventarioCreationState {
  // Configuración básica
  final String? modeloSeleccionado;
  final String? versionSeleccionada;

  // Datos dinámicos de campos
  final Map<String, dynamic> camposData;

  // Fotos
  final List<String> fotoPaths;
  final int maxFotos;

  // Estados UI
  final bool isCreating;
  final bool isLoadingOptions;
  final bool showImagePicker;
  final String? errorMessage;
  final String? successMessage;
  final InventarioValidationErrors validationErrors;

  const InventarioCreationState({
    this.modeloSeleccionado,
    this.versionSeleccionada,
    this.camposData = const {},
    this.fotoPaths = const [],
    this.maxFotos = 10,
    this.isCreating = false,
    this.isLoadingOptions = false,
    this.showImagePicker = false,
    this.errorMessage,
    this.successMessage,
    this.validationErrors = const InventarioValidationErrors(),
  });

  InventarioCreationState copyWith({
    String? modeloSeleccionado,
    String? versionSeleccionada,
    Map<String, dynamic>? camposData,
    List<String>? fotoPaths,
    int? maxFotos,
    bool? isCreating,
    bool? isLoadingOptions,
    bool? showImagePicker,
    String? errorMessage,
    String? successMessage,
    InventarioValidationErrors? validationErrors,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearModelo = false,
    bool clearVersion = false,
    bool clearCamposData = false,
  }) {
    return InventarioCreationState(
      modeloSeleccionado: clearModelo
          ? null
          : (modeloSeleccionado ?? this.modeloSeleccionado),
      versionSeleccionada: clearVersion
          ? null
          : (versionSeleccionada ?? this.versionSeleccionada),
      camposData: clearCamposData ? {} : (camposData ?? this.camposData),
      fotoPaths: fotoPaths ?? this.fotoPaths,
      maxFotos: maxFotos ?? this.maxFotos,
      isCreating: isCreating ?? this.isCreating,
      isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
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
    return modeloSeleccionado != null && validationErrors.isEmpty;
  }

  /// Verificar si puede agregar más fotos
  bool get canAddMoreFotos => fotoPaths.length < maxFotos;

  /// Verificar si tiene configuración cargada
  bool get hasConfiguration => modeloSeleccionado != null;

  /// Obtener datos del formulario para envío
  InventarioFormData? get formData {
    if (modeloSeleccionado == null) return null;

    return InventarioFormData(
      vin: '', // Se asigna en el notifier
      modelo: modeloSeleccionado!,
      version: versionSeleccionada,
      camposData: camposData,
      fotoPaths: fotoPaths,
    );
  }
}

class InventarioCreationNotifier
    extends StateNotifier<InventarioCreationState> {
  final String vin;
  final Ref ref;

  InventarioCreationNotifier(this.vin, this.ref)
    : super(const InventarioCreationState());

  // Métodos de configuración básica
  Future<void> selectModelo(String modelo) async {
    state = state.copyWith(
      modeloSeleccionado: modelo,
      isLoadingOptions: true,
      clearVersion: true,
      clearCamposData: true,
      validationErrors: state.validationErrors.copyWith(clearModelo: true),
    );

    try {
      // Cargar opciones para el modelo seleccionado
      await ref.read(inventarioOptionsProvider((modelo, null)).future);

      state = state.copyWith(isLoadingOptions: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingOptions: false,
        errorMessage: 'Error al cargar configuración del modelo: $e',
      );
    }
  }

  void selectVersion(String? version) {
    state = state.copyWith(
      versionSeleccionada: version,
      clearCamposData: true, // Limpiar datos cuando cambia versión
    );
  }

  // Métodos de campos dinámicos
  void updateCampoValue(String nombreCampo, dynamic value) {
    final newCamposData = Map<String, dynamic>.from(state.camposData);
    newCamposData[nombreCampo] = value;

    state = state.copyWith(
      camposData: newCamposData,
      validationErrors: state.validationErrors.copyWith(
        clearCampoError: nombreCampo,
      ),
    );
  }

  void removeCampoValue(String nombreCampo) {
    final newCamposData = Map<String, dynamic>.from(state.camposData);
    newCamposData.remove(nombreCampo);

    state = state.copyWith(camposData: newCamposData);
  }

  void resetCamposData() {
    state = state.copyWith(clearCamposData: true);
  }

  // Métodos de fotos
  void addFoto(String fotoPath) {
    if (state.canAddMoreFotos) {
      final newFotos = List<String>.from(state.fotoPaths);
      newFotos.add(fotoPath);
      state = state.copyWith(fotoPaths: newFotos);
    }
  }

  void removeFoto(int index) {
    final newFotos = List<String>.from(state.fotoPaths);
    if (index >= 0 && index < newFotos.length) {
      newFotos.removeAt(index);
      state = state.copyWith(fotoPaths: newFotos);
    }
  }

  void removeFotoByPath(String fotoPath) {
    final newFotos = List<String>.from(state.fotoPaths);
    newFotos.remove(fotoPath);
    state = state.copyWith(fotoPaths: newFotos);
  }

  void clearAllFotos() {
    state = state.copyWith(fotoPaths: []);
  }

  void toggleImagePicker() {
    state = state.copyWith(showImagePicker: !state.showImagePicker);
  }

  // Validación y envío
  Future<InventarioValidationErrors> _validateForm() async {
    final errors = <String, String>{};

    if (state.modeloSeleccionado == null) {
      return InventarioValidationErrors(modelo: 'Debe seleccionar un modelo');
    }

    try {
      // Obtener configuración de campos
      final options = await ref.read(
        inventarioOptionsProvider((
          state.modeloSeleccionado!,
          state.versionSeleccionada,
        )).future,
      );

      // Validar cada campo requerido
      for (final campo in options.campos) {
        if (campo.requerido) {
          final valor = state.camposData[campo.nombre];
          if (valor == null || (valor is String && valor.isEmpty)) {
            errors[campo.nombre] = '${campo.label} es requerido';
          }
        }

        // Validar según el tipo de campo
        if (state.camposData.containsKey(campo.nombre)) {
          final valor = state.camposData[campo.nombre];
          final validationError = _validateCampoValue(campo, valor);
          if (validationError != null) {
            errors[campo.nombre] = validationError;
          }
        }
      }

      return InventarioValidationErrors(camposErrors: errors);
    } catch (e) {
      return InventarioValidationErrors(
        modelo: 'Error validando configuración: $e',
      );
    }
  }

  String? _validateCampoValue(CampoInventario campo, dynamic value) {
    if (value == null) return null;

    switch (campo.tipo) {
      case CampoTipo.numero:
        if (value is! num && double.tryParse(value.toString()) == null) {
          return '${campo.label} debe ser un número válido';
        }
        break;
      case CampoTipo.email:
        if (!RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(value.toString())) {
          return '${campo.label} debe ser un email válido';
        }
        break;
      case CampoTipo.telefono:
        if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value.toString())) {
          return '${campo.label} debe ser un teléfono válido';
        }
        break;
      default:
        break;
    }

    // Validaciones personalizadas
    if (campo.validaciones != null) {
      final validaciones = campo.validaciones!;
      final valueStr = value.toString();

      if (validaciones.minLength != null &&
          valueStr.length < validaciones.minLength!) {
        return '${campo.label} debe tener al menos ${validaciones.minLength} caracteres';
      }

      if (validaciones.maxLength != null &&
          valueStr.length > validaciones.maxLength!) {
        return '${campo.label} no puede exceder ${validaciones.maxLength} caracteres';
      }

      if (validaciones.patron != null) {
        if (!RegExp(validaciones.patron!).hasMatch(valueStr)) {
          return validaciones.mensajePatron ??
              '${campo.label} tiene formato inválido';
        }
      }
    }

    return null;
  }

  Future<void> createInventario() async {
    // Validar formulario
    final errors = await _validateForm();
    if (errors.hasErrors) {
      state = state.copyWith(
        validationErrors: errors,
        errorMessage: 'Complete todos los campos requeridos correctamente',
      );
      return;
    }

    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final inventariosNotifier = ref.read(
        inventariosPorVinProvider(vin).notifier,
      );
      final formData = state.formData!.copyWith(vin: vin);
      final success = await inventariosNotifier.createInventarioFromForm(
        formData,
      );

      if (success) {
        state = state.copyWith(
          isCreating: false,
          successMessage: 'Inventario registrado exitosamente',
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
          errorMessage: 'Error al registrar el inventario',
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
    state = const InventarioCreationState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void clearValidationErrors() {
    state = state.copyWith(
      validationErrors: const InventarioValidationErrors(),
    );
  }
}

// ============================================================================
// PROVIDER DE ESTADO COMBINADO
// ============================================================================

/// Provider que combina opciones, inventarios y estado de creación
final inventariosCompleteStateProvider =
    Provider.family<InventariosCompleteState, String>((ref, vin) {
      final inventariosAsync = ref.watch(inventariosPorVinProvider(vin));
      final creationState = ref.watch(inventarioCreationStateProvider(vin));
      final queueState = ref.watch(queueStateProvider);

      // Opciones dinámicas basadas en modelo/versión seleccionados
      final optionsAsync = creationState.hasConfiguration
          ? ref.watch(
              inventarioOptionsProvider((
                creationState.modeloSeleccionado!,
                creationState.versionSeleccionada,
              )),
            )
          : const AsyncValue<InventarioOptions>.loading();

      return InventariosCompleteState(
        vin: vin,
        inventarios: inventariosAsync.value ?? [],
        options: optionsAsync.value,
        isLoading: inventariosAsync.isLoading || optionsAsync.isLoading,
        error: inventariosAsync.error ?? optionsAsync.error,
        creationState: creationState,
        pendingCount: queueState.pendingCount,
      );
    });

class InventariosCompleteState {
  final String vin;
  final List<Inventario> inventarios;
  final InventarioOptions? options;
  final bool isLoading;
  final Object? error;
  final InventarioCreationState creationState;
  final int pendingCount;

  const InventariosCompleteState({
    required this.vin,
    required this.inventarios,
    this.options,
    required this.isLoading,
    this.error,
    required this.creationState,
    required this.pendingCount,
  });

  bool get hasError => error != null;
  bool get hasInventarios => inventarios.isNotEmpty;
  bool get hasOptions => options != null;
  int get totalInventarios => inventarios.length;

  /// Verificar si el formulario dinámico está listo
  bool get isFormReady => options != null && !creationState.isLoadingOptions;
}

// ============================================================================
// PROVIDERS DE CONVENIENCIA
// ============================================================================

/// Provider para obtener conteo de inventarios pendientes
final inventariosPendientesCountProvider = FutureProvider<int>((ref) async {
  final serviceInstance = ref.read(inventariosServiceProvider);
  return await serviceInstance.getPendingCount();
});

/// Provider para obtener modelos disponibles (lista estática o del backend)
final modelosDisponiblesProvider = FutureProvider<List<String>>((ref) async {
  final serviceInstance = ref.read(inventariosServiceProvider);
  return await serviceInstance.getModelosDisponibles();
});

/// Provider para obtener versiones por modelo
final versionesPorModeloProvider = FutureProvider.family<List<String>, String>((
  ref,
  modelo,
) async {
  final serviceInstance = ref.read(inventariosServiceProvider);
  return await serviceInstance.getVersionesPorModelo(modelo);
});

// Extension helper para InventarioFormData
extension InventarioFormDataExtension on InventarioFormData {
  InventarioFormData copyWith({
    String? vin,
    String? modelo,
    String? version,
    Map<String, dynamic>? camposData,
    List<String>? fotoPaths,
  }) {
    return InventarioFormData(
      vin: vin ?? this.vin,
      modelo: modelo ?? this.modelo,
      version: version ?? this.version,
      camposData: camposData ?? this.camposData,
      fotoPaths: fotoPaths ?? this.fotoPaths,
    );
  }
}
