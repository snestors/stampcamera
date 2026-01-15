import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/config/camera/camera_config.dart';

/// Estado de la configuración de cámara
///
/// Permite configuración local y remota.
/// La configuración remota sobrescribe los valores por defecto
/// cuando se obtiene del servidor.
class CameraConfigState {
  final WatermarkConfig defaultConfig;
  final WatermarkConfig cameraConfig;
  final WatermarkConfig galleryConfig;
  final WatermarkConfig scannerConfig;
  final WatermarkConfig gpsConfig;
  final bool isRemoteConfigLoaded;
  final DateTime? lastRemoteSync;

  const CameraConfigState({
    this.defaultConfig = WatermarkPresets.camera,
    this.cameraConfig = WatermarkPresets.camera,
    this.galleryConfig = WatermarkPresets.gallery,
    this.scannerConfig = WatermarkPresets.scanner,
    this.gpsConfig = WatermarkPresets.withGps,
    this.isRemoteConfigLoaded = false,
    this.lastRemoteSync,
  });

  CameraConfigState copyWith({
    WatermarkConfig? defaultConfig,
    WatermarkConfig? cameraConfig,
    WatermarkConfig? galleryConfig,
    WatermarkConfig? scannerConfig,
    WatermarkConfig? gpsConfig,
    bool? isRemoteConfigLoaded,
    DateTime? lastRemoteSync,
  }) {
    return CameraConfigState(
      defaultConfig: defaultConfig ?? this.defaultConfig,
      cameraConfig: cameraConfig ?? this.cameraConfig,
      galleryConfig: galleryConfig ?? this.galleryConfig,
      scannerConfig: scannerConfig ?? this.scannerConfig,
      gpsConfig: gpsConfig ?? this.gpsConfig,
      isRemoteConfigLoaded: isRemoteConfigLoaded ?? this.isRemoteConfigLoaded,
      lastRemoteSync: lastRemoteSync ?? this.lastRemoteSync,
    );
  }
}

/// Provider principal de configuración de cámara
///
/// Uso básico:
/// ```dart
/// // Obtener configuración para cámara
/// final config = ref.watch(cameraConfigProvider).cameraConfig;
///
/// // Obtener configuración para galería
/// final galleryConfig = ref.watch(cameraConfigProvider).galleryConfig;
///
/// // Obtener configuración personalizada con GPS
/// final gpsConfig = ref.watch(cameraConfigProvider).gpsConfig;
/// ```
///
/// Para configuración remota (futuro):
/// ```dart
/// await ref.read(cameraConfigProvider.notifier).loadRemoteConfig();
/// ```
final cameraConfigProvider =
    StateNotifierProvider<CameraConfigNotifier, CameraConfigState>(
  (ref) => CameraConfigNotifier(),
);

class CameraConfigNotifier extends StateNotifier<CameraConfigState> {
  CameraConfigNotifier() : super(const CameraConfigState());

  /// Carga configuración desde API remota
  ///
  /// TODO: Implementar cuando la API esté lista
  /// Esta función será llamada al iniciar la app para obtener
  /// la configuración más reciente del servidor.
  Future<void> loadRemoteConfig() async {
    // TODO: Implementar llamada a API
    // final response = await _httpService.get('/api/v1/config/camera/');
    // if (response.statusCode == 200) {
    //   final json = response.data;
    //   state = state.copyWith(
    //     defaultConfig: WatermarkConfig.fromJson(json['default']),
    //     cameraConfig: WatermarkConfig.fromJson(json['camera']),
    //     galleryConfig: WatermarkConfig.fromJson(json['gallery']),
    //     scannerConfig: WatermarkConfig.fromJson(json['scanner']),
    //     gpsConfig: WatermarkConfig.fromJson(json['gps']),
    //     isRemoteConfigLoaded: true,
    //     lastRemoteSync: DateTime.now(),
    //   );
    // }
  }

  /// Actualiza la configuración de cámara
  void updateCameraConfig(WatermarkConfig config) {
    state = state.copyWith(cameraConfig: config);
  }

  /// Actualiza la configuración de galería
  void updateGalleryConfig(WatermarkConfig config) {
    state = state.copyWith(galleryConfig: config);
  }

  /// Actualiza la configuración del scanner
  void updateScannerConfig(WatermarkConfig config) {
    state = state.copyWith(scannerConfig: config);
  }

  /// Actualiza la configuración con GPS
  void updateGpsConfig(WatermarkConfig config) {
    state = state.copyWith(gpsConfig: config);
  }

  /// Resetea a valores por defecto
  void resetToDefaults() {
    state = const CameraConfigState();
  }

  /// Habilita/deshabilita logo globalmente
  void setShowLogo(bool show) {
    state = state.copyWith(
      cameraConfig: state.cameraConfig.copyWith(showLogo: show),
      galleryConfig: state.galleryConfig.copyWith(showLogo: show),
      scannerConfig: state.scannerConfig.copyWith(showLogo: show),
      gpsConfig: state.gpsConfig.copyWith(showLogo: show),
    );
  }

  /// Habilita/deshabilita timestamp globalmente
  void setShowTimestamp(bool show) {
    state = state.copyWith(
      cameraConfig: state.cameraConfig.copyWith(showTimestamp: show),
      galleryConfig: state.galleryConfig.copyWith(showTimestamp: show),
      scannerConfig: state.scannerConfig.copyWith(showTimestamp: show),
      gpsConfig: state.gpsConfig.copyWith(showTimestamp: show),
    );
  }

  /// Cambia la posición del logo globalmente
  void setLogoPosition(WatermarkPosition position) {
    state = state.copyWith(
      cameraConfig: state.cameraConfig.copyWith(logoPosition: position),
      galleryConfig: state.galleryConfig.copyWith(logoPosition: position),
      scannerConfig: state.scannerConfig.copyWith(logoPosition: position),
      gpsConfig: state.gpsConfig.copyWith(logoPosition: position),
    );
  }

  /// Cambia la calidad de compresión globalmente
  void setCompressionQuality(int quality) {
    final clampedQuality = quality.clamp(1, 100);
    state = state.copyWith(
      cameraConfig:
          state.cameraConfig.copyWith(compressionQuality: clampedQuality),
      galleryConfig:
          state.galleryConfig.copyWith(compressionQuality: clampedQuality),
      scannerConfig:
          state.scannerConfig.copyWith(compressionQuality: clampedQuality),
      gpsConfig: state.gpsConfig.copyWith(compressionQuality: clampedQuality),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS DE CONVENIENCIA
// ═══════════════════════════════════════════════════════════════════════

/// Provider directo para configuración de cámara
final watermarkCameraConfigProvider = Provider<WatermarkConfig>((ref) {
  return ref.watch(cameraConfigProvider).cameraConfig;
});

/// Provider directo para configuración de galería
final watermarkGalleryConfigProvider = Provider<WatermarkConfig>((ref) {
  return ref.watch(cameraConfigProvider).galleryConfig;
});

/// Provider directo para configuración de scanner
final watermarkScannerConfigProvider = Provider<WatermarkConfig>((ref) {
  return ref.watch(cameraConfigProvider).scannerConfig;
});

/// Provider directo para configuración con GPS
final watermarkGpsConfigProvider = Provider<WatermarkConfig>((ref) {
  return ref.watch(cameraConfigProvider).gpsConfig;
});

/// Provider para verificar si la configuración remota está cargada
final isRemoteConfigLoadedProvider = Provider<bool>((ref) {
  return ref.watch(cameraConfigProvider).isRemoteConfigLoaded;
});
