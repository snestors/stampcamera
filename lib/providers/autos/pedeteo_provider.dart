// lib/providers/autos/pedeteo_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/registro_vin_options.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/providers/autos/queue_state_provider.dart';
import 'package:stampcamera/services/registro_vin_service.dart';

// ============================================================================
// 🎯 TRACKING DE PEDETEOS EN TIEMPO REAL
// ============================================================================

/// Set de VINs pedeteados en esta sesión (actualización instantánea)
final pedeteadosEnSesionProvider = StateProvider<Set<String>>((ref) => {});

/// Contador de pedeteos del día (para mostrar progreso)
final pedeteosHoyCountProvider = StateProvider<int>((ref) => 0);

/// Verifica si un VIN está pedeteado (combina servidor + sesión local)
bool isVinPedeteado(WidgetRef ref, String vin, bool serverPedeteado) {
  final pedeteadosLocal = ref.watch(pedeteadosEnSesionProvider);
  return serverPedeteado || pedeteadosLocal.contains(vin);
}

// ============================================================================
// SERVICIO PROVIDER - MANTENER IGUAL
// ============================================================================

/// Provider del servicio de registro VIN
final registroVinServiceProvider = Provider<RegistroVinService>((ref) {
  return RegistroVinService();
});

// ============================================================================
// PROVIDERS PRINCIPALES PARA PEDETEO - MANTENER IGUAL
// ============================================================================

/// Provider que obtiene las opciones del endpoint /options una sola vez
final pedeteoOptionsProvider = FutureProvider<RegistroVinOptions>((ref) async {
  final service = ref.read(registroVinServiceProvider);
  return await service.getOptions();
});

/// Provider para el query de búsqueda actual
final pedeteoSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider que filtra localmente los VINs disponibles usando RegistroGeneral
final pedeteoSearchResultsProvider = Provider<List<RegistroGeneral>>((ref) {
  final query = ref.watch(pedeteoSearchQueryProvider);
  final optionsAsync = ref.watch(pedeteoOptionsProvider);

  // Si no hay query o las opciones están cargando, retorna lista vacía
  if (query.isEmpty || optionsAsync.isLoading || optionsAsync.hasError) {
    return <RegistroGeneral>[];
  }

  final vinsDisponibles = optionsAsync.value?.vinsDisponibles ?? [];

  // Filtrar por VIN o Serie (case insensitive)
  return vinsDisponibles.where((registro) {
    final searchLower = query.toLowerCase();
    final vinMatch = registro.vin.toLowerCase().contains(searchLower);
    final serieMatch =
        registro.serie?.toLowerCase().contains(searchLower) ?? false;
    return vinMatch || serieMatch;
  }).toList();
});

/// Provider para el VIN seleccionado actualmente
final pedeteoSelectedVinProvider = StateProvider<RegistroGeneral?>(
  (ref) => null,
);

/// Provider para el estado del formulario (si está mostrando el form completo)
final pedeteoShowFormProvider = StateProvider<bool>((ref) => false);

// ============================================================================
// PROVIDER NOTIFIER PARA MANEJO COMPLETO DEL ESTADO DE PEDETEO - MANTENER IGUAL
// ============================================================================

/// Provider principal que maneja todo el estado de la pantalla de Pedeteo
final pedeteoStateProvider =
    StateNotifierProvider<PedeteoStateNotifier, PedeteoState>((ref) {
      return PedeteoStateNotifier(ref);
    });

class PedeteoState {
  final String searchQuery;
  final RegistroGeneral? selectedVin;
  final bool showForm;
  final bool showScanner;
  final String? capturedImagePath;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic> formData;

  const PedeteoState({
    this.searchQuery = '',
    this.selectedVin,
    this.showForm = false,
    this.showScanner = false,
    this.capturedImagePath,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.formData = const {},
  });

  PedeteoState copyWith({
    String? searchQuery,
    RegistroGeneral? selectedVin,
    bool? showForm,
    bool? showScanner,
    String? capturedImagePath,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? formData,
    bool clearSelectedVin = false,
    bool clearImagePath = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearFormData = false,
  }) {
    return PedeteoState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedVin: clearSelectedVin ? null : (selectedVin ?? this.selectedVin),
      showForm: showForm ?? this.showForm,
      showScanner: showScanner ?? this.showScanner,
      capturedImagePath: clearImagePath
          ? null
          : (capturedImagePath ?? this.capturedImagePath),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      formData: clearFormData ? {} : (formData ?? this.formData),
    );
  }
}

class PedeteoStateNotifier extends StateNotifier<PedeteoState> {
  final Ref ref;

  PedeteoStateNotifier(this.ref) : super(const PedeteoState());

  // ============================================================================
  // TODOS TUS MÉTODOS EXISTENTES - MANTENER EXACTAMENTE IGUAL
  // ============================================================================

  void updateSearchQuery(String query) {
    // Actualizar el provider de búsqueda
    ref.read(pedeteoSearchQueryProvider.notifier).state = query;

    state = state.copyWith(searchQuery: query);

    // Si llegamos a 17 caracteres, búsqueda automática
    if (query.length == 17) {
      _performAutoSearch(query);
    }
  }

  void _performAutoSearch(String vin) {
    // Obtener resultados del provider de búsqueda local
    final results = ref.read(pedeteoSearchResultsProvider);

    if (results.isNotEmpty) {
      // Buscar coincidencia exacta por VIN
      final exactMatch = results.firstWhere(
        (r) => r.vin.toLowerCase() == vin.toLowerCase(),
        orElse: () => results.first,
      );

      selectVin(exactMatch);
    }
  }

  void selectVin(RegistroGeneral vin) {
    // Actualizar también el provider individual
    ref.read(pedeteoSelectedVinProvider.notifier).state = vin;
    ref.read(pedeteoShowFormProvider.notifier).state = true;

    state = state.copyWith(
      selectedVin: vin,
      searchQuery: vin.vin,
      showForm: true,
    );
  }

  void toggleScanner() {
    state = state.copyWith(
      showScanner: !state.showScanner,
      showForm: state.showScanner
          ? state.showForm
          : false, // Si cerramos scanner, mantener form
    );
  }

  void onBarcodeScanned(String vin) {
    state = state.copyWith(searchQuery: vin, showScanner: false);

    // Actualizar el provider de búsqueda también
    ref.read(pedeteoSearchQueryProvider.notifier).state = vin;

    // Si el VIN escaneado tiene 17 caracteres, búsqueda automática
    if (vin.length == 17) {
      _performAutoSearch(vin);
    }
  }

  void setCapturedImage(String imagePath) {
    state = state.copyWith(capturedImagePath: imagePath);
  }

  void updateFormField(String field, dynamic value) {
    final newFormData = Map<String, dynamic>.from(state.formData);
    newFormData[field] = value;
    state = state.copyWith(formData: newFormData);
  }

  void initializeFormWithDefaults(Map<String, dynamic> initialValues) {
    final formData = Map<String, dynamic>.from(initialValues);
    state = state.copyWith(formData: formData);
  }

  // ============================================================================
  // MÉTODOS DE GUARDADO
  // ============================================================================

  /// Validates required fields and extracts form data for registro creation.
  /// Returns null and sets error state if validation fails.
  Future<_RegistroData?> _prepareRegistroData() async {
    if (state.selectedVin == null || state.capturedImagePath == null) {
      state = state.copyWith(
        errorMessage: 'Faltan datos requeridos: VIN y foto son obligatorios',
      );
      return null;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final options = await ref.read(pedeteoOptionsProvider.future);

    final condicion =
        state.formData['condicion'] ?? options.initialValues['condicion'];
    final zonaInspeccion =
        state.formData['zona_inspeccion'] ??
        options.initialValues['zona_inspeccion'];
    final bloque =
        state.formData['bloque'] ?? options.initialValues['bloque'];

    if (condicion == null || (condicion is String && condicion.isEmpty)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: Debe seleccionar una condición',
      );
      return null;
    }

    if (zonaInspeccion == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: Debe seleccionar una zona de inspección',
      );
      return null;
    }

    return _RegistroData(
      vin: state.selectedVin!.vin,
      condicion: condicion.toString(),
      zonaInspeccion: zonaInspeccion as int,
      fotoPath: state.capturedImagePath!,
      bloqueId: bloque as int?,
    );
  }

  /// Guarda registro esperando respuesta del servidor.
  Future<void> saveRegistro() async {
    final data = await _prepareRegistroData();
    if (data == null) return;

    try {
      final service = ref.read(registroVinServiceProvider);
      await service.createRegistro(
        vin: data.vin,
        condicion: data.condicion,
        zonaInspeccion: data.zonaInspeccion,
        fotoPath: data.fotoPath,
        bloqueId: data.bloqueId,
      );

      resetForm();
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    }
  }

  /// Guarda registro con estrategia offline-first.
  Future<void> saveRegistroOfflineFirst() async {
    final data = await _prepareRegistroData();
    if (data == null) return;

    try {
      final service = ref.read(registroVinServiceProvider);
      final success = await service.createRegistroOfflineFirst(
        vin: data.vin,
        condicion: data.condicion,
        zonaInspeccion: data.zonaInspeccion,
        fotoPath: data.fotoPath,
        bloqueId: data.bloqueId,
      );

      if (success) {
        final currentSet = ref.read(pedeteadosEnSesionProvider);
        ref.read(pedeteadosEnSesionProvider.notifier).state = {...currentSet, data.vin};
        ref.read(pedeteosHoyCountProvider.notifier).state++;
        ref.read(queueStateProvider.notifier).refreshState();

        state = state.copyWith(
          isLoading: false,
          successMessage: '✅ Registro guardado exitosamente',
        );

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) resetForm();
        });
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al guardar el registro',
        );
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    }
  }

  // ============================================================================
  // MÉTODOS DE LIMPIEZA - MANTENER EXACTOS
  // ============================================================================

  void resetForm() {
    // Limpiar también los providers individuales
    ref.read(pedeteoSearchQueryProvider.notifier).state = '';
    ref.read(pedeteoSelectedVinProvider.notifier).state = null;
    ref.read(pedeteoShowFormProvider.notifier).state = false;

    state = const PedeteoState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

// ============================================================================
// PROVIDERS ADICIONALES PARA COMPATIBILIDAD - MANTENER EXACTOS
// ============================================================================

/// Provider que expone solo las opciones para widgets que las necesiten
final pedeteoCondicionesProvider = Provider<List<CondicionOption>>((ref) {
  final optionsAsync = ref.watch(pedeteoOptionsProvider);
  return optionsAsync.value?.condiciones ?? [];
});

/// Provider que expone las zonas de inspección
final pedeteoZonasInspeccionProvider = Provider<List<ZonaInspeccionOption>>((
  ref,
) {
  final optionsAsync = ref.watch(pedeteoOptionsProvider);
  return optionsAsync.value?.zonasInspeccion ?? [];
});

/// Provider que expone los bloques disponibles
final pedeteoBloqueProvider = Provider<List<BloqueOption>>((ref) {
  final optionsAsync = ref.watch(pedeteoOptionsProvider);
  return optionsAsync.value?.bloques ?? [];
});

/// Provider que expone los permisos de campos
final pedeteoFieldPermissionsProvider = Provider<Map<String, FieldPermission>>((
  ref,
) {
  final optionsAsync = ref.watch(pedeteoOptionsProvider);
  return optionsAsync.value?.fieldPermissions ?? {};
});

// ============================================================================
// HELPER: Validated registro data for save methods
// ============================================================================

class _RegistroData {
  final String vin;
  final String condicion;
  final int zonaInspeccion;
  final String fotoPath;
  final int? bloqueId;

  const _RegistroData({
    required this.vin,
    required this.condicion,
    required this.zonaInspeccion,
    required this.fotoPath,
    this.bloqueId,
  });
}
