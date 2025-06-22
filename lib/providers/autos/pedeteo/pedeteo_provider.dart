// lib/providers/autos/pedeteo_provider.dart - CORRECCIÓN PARA VIN COMO STRING
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/pedeteo/registro_vin_options.dart';
import 'package:stampcamera/models/autos/registro_general_model.dart';
import 'package:stampcamera/services/registro_vin_service.dart';

// ============================================================================
// SERVICIO PROVIDER
// ============================================================================

/// Provider del servicio de registro VIN
final registroVinServiceProvider = Provider<RegistroVinService>((ref) {
  return RegistroVinService();
});

// ============================================================================
// PROVIDERS PRINCIPALES PARA PEDETEO
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
// PROVIDER NOTIFIER PARA MANEJO COMPLETO DEL ESTADO DE PEDETEO
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
  final Map<String, dynamic> formData; // ✅ Agregado para datos del formulario

  const PedeteoState({
    this.searchQuery = '',
    this.selectedVin,
    this.showForm = false,
    this.showScanner = false,
    this.capturedImagePath,
    this.isLoading = false,
    this.errorMessage,
    this.formData = const {}, // ✅ Inicializar vacío
  });

  PedeteoState copyWith({
    String? searchQuery,
    RegistroGeneral? selectedVin,
    bool? showForm,
    bool? showScanner,
    String? capturedImagePath,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? formData,
    bool clearSelectedVin = false,
    bool clearImagePath = false,
    bool clearError = false,
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
      formData: clearFormData
          ? {}
          : (formData ?? this.formData), // ✅ Manejar formData
    );
  }
}

class PedeteoStateNotifier extends StateNotifier<PedeteoState> {
  final Ref ref;

  PedeteoStateNotifier(this.ref) : super(const PedeteoState());

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

  Future<void> saveRegistro() async {
    if (state.selectedVin == null || state.capturedImagePath == null) {
      state = state.copyWith(
        errorMessage: 'Faltan datos requeridos: VIN y foto son obligatorios',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final service = ref.read(registroVinServiceProvider);
      final options = await ref.read(pedeteoOptionsProvider.future);

      // ✅ Usar valores del formulario o fallback a initialValues
      final condicion =
          state.formData['condicion'] ?? options.initialValues['condicion'];
      final zonaInspeccion =
          state.formData['zona_inspeccion'] ??
          options.initialValues['zona_inspeccion'];
      final bloque =
          state.formData['bloque'] ?? options.initialValues['bloque'];

      // ✅ VALIDACIÓN: Verificar que los campos requeridos estén disponibles
      if (condicion == null || (condicion is String && condicion.isEmpty)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error: Debe seleccionar una condición',
        );
        return;
      }

      if (zonaInspeccion == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error: Debe seleccionar una zona de inspección',
        );
        return;
      }

      // ✅ Llamar al servicio con los valores correctos
      await service.createRegistro(
        vin: state.selectedVin!.vin,
        condicion: condicion.toString(),
        zonaInspeccion: zonaInspeccion as int,
        fotoPath: state.capturedImagePath!,
        bloqueId: bloque as int?, // Opcional
      );

      // Si todo sale bien, limpiar el formulario
      resetForm();
    } catch (e) {
      // ✅ DEBUG: Ver qué tipo de error estamos recibiendo
      print('🔍 DEBUG - Provider caught exception:');
      print('   Exception Type: ${e.runtimeType}');
      print('   Exception String: $e');
      print('   Exception toString(): ${e.toString()}');

      // ✅ Manejo simplificado - el servicio ya envía mensajes limpios
      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      print('🔍 DEBUG - Final error message: $errorMessage');

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    }
  }

  void resetForm() {
    // Limpiar también los providers individuales
    ref.read(pedeteoSearchQueryProvider.notifier).state = '';
    ref.read(pedeteoSelectedVinProvider.notifier).state = null;
    ref.read(pedeteoShowFormProvider.notifier).state = false;

    state = const PedeteoState(); // ✅ Esto ya limpia formData también
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================================================
// PROVIDERS ADICIONALES PARA COMPATIBILIDAD
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
