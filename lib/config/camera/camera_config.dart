/// Configuración centralizada del sistema de cámara.
///
/// Este archivo contiene todas las constantes y valores por defecto
/// para el procesamiento de imágenes, watermarking y compresión.
///
/// DISEÑADO PARA: Configuración remota vía API en el futuro.
/// Los valores pueden ser sobrescritos por un provider que obtenga
/// configuración del servidor.
library;

import 'package:camera/camera.dart';

// Re-exportamos los tipos del image_processor para uso centralizado
export 'package:stampcamera/utils/image_processor.dart'
    show WatermarkConfig, WatermarkPosition, FontSize;

// Importamos para usar en las constantes
import 'package:stampcamera/utils/image_processor.dart'
    show WatermarkConfig, WatermarkPosition, FontSize;

/// Configuración global de la cámara
///
/// Todos los valores por defecto están aquí centralizados.
/// Para configuración remota, estos valores pueden ser sobrescritos
/// por el CameraConfigProvider al iniciar la app.
abstract class CameraDefaults {
  // ═══════════════════════════════════════════════════════════════
  // WATERMARK - LOGO
  // ═══════════════════════════════════════════════════════════════
  static const bool showLogo = true;
  static const WatermarkPosition logoPosition = WatermarkPosition.topRight;
  static const double logoSizeRatioAuto = 0.0;
  static const int logoMinSize = 60;
  static const int logoMaxSize = 200;
  static const int logoPadding = 10;

  // Ratios por resolución (auto-calculados)
  static const double logoRatioSmall = 0.20; // < 1920px
  static const double logoRatioMedium = 0.15; // 1920-3840px
  static const double logoRatioLarge = 0.12; // > 3840px

  // ═══════════════════════════════════════════════════════════════
  // WATERMARK - TIMESTAMP
  // ═══════════════════════════════════════════════════════════════
  static const bool showTimestamp = true;
  static const WatermarkPosition timestampPosition =
      WatermarkPosition.bottomRight;
  static const FontSize timestampFontSize = FontSize.auto;
  static const String timestampFormat = 'dd/MM/yyyy HH:mm:ss';
  static const int textPadding = 10;

  // ═══════════════════════════════════════════════════════════════
  // WATERMARK - UBICACIÓN (GPS)
  // ═══════════════════════════════════════════════════════════════
  static const bool showLocation = false;
  static const WatermarkPosition locationPosition =
      WatermarkPosition.bottomLeft;
  static const FontSize locationFontSize = FontSize.auto;

  // GPS Settings
  static const int gpsTimeoutSeconds = 10;
  static const int gpsCacheDurationMinutes = 5;
  static const int geocodingTimeoutSeconds = 5;

  // ═══════════════════════════════════════════════════════════════
  // COMPRESIÓN (75% = balance velocidad/calidad)
  // ═══════════════════════════════════════════════════════════════
  static const int compressionQualityDefault = 75;
  static const int compressionQualityCamera = 75;
  static const int compressionQualityGallery = 75;
  static const int compressionQualityScanner = 75;

  // ═══════════════════════════════════════════════════════════════
  // RESOLUCIÓN DE CÁMARA
  // ═══════════════════════════════════════════════════════════════
  static const ResolutionPreset cameraResolutionDefault = ResolutionPreset.high;
  static const ResolutionPreset cameraResolutionHigh =
      ResolutionPreset.veryHigh;
  static const ResolutionPreset scannerResolution = ResolutionPreset.medium;

  // ═══════════════════════════════════════════════════════════════
  // ALMACENAMIENTO
  // ═══════════════════════════════════════════════════════════════
  static const String storageFolder = 'StampCamera';
  static const String filePrefix = 'IMG';
  static const String fileExtension = 'jpg';

  // ═══════════════════════════════════════════════════════════════
  // FUENTES (tamaños en pixels)
  // ═══════════════════════════════════════════════════════════════
  static const int fontSizeSmall = 14;
  static const int fontSizeMedium = 24;
  static const int fontSizeLarge = 48;

  // Resolución para selección automática de fuente
  static const int resolutionThresholdSmall = 1920;
  static const int resolutionThresholdLarge = 3840;

  // ═══════════════════════════════════════════════════════════════
  // SOMBRAS DE TEXTO
  // ═══════════════════════════════════════════════════════════════
  static const int shadowRadiusTimestamp = 3;
  static const int shadowRadiusLocation = 2;
  static const int shadowOffsetX = 2;
  static const int shadowOffsetY = 2;
}

/// Presets predefinidos para diferentes contextos de uso
abstract class WatermarkPresets {
  /// Configuración estándar para cámara principal
  static const WatermarkConfig camera = WatermarkConfig(
    showLogo: CameraDefaults.showLogo,
    showTimestamp: CameraDefaults.showTimestamp,
    showLocation: false,
    logoPosition: CameraDefaults.logoPosition,
    timestampPosition: CameraDefaults.timestampPosition,
    compressionQuality: CameraDefaults.compressionQualityCamera,
    timestampFontSize: CameraDefaults.timestampFontSize,
    locationFontSize: CameraDefaults.locationFontSize,
  );

  /// Configuración para imágenes de galería
  static const WatermarkConfig gallery = WatermarkConfig(
    showLogo: CameraDefaults.showLogo,
    showTimestamp: CameraDefaults.showTimestamp,
    showLocation: false,
    logoPosition: CameraDefaults.logoPosition,
    timestampPosition: CameraDefaults.timestampPosition,
    compressionQuality: CameraDefaults.compressionQualityGallery,
    timestampFontSize: CameraDefaults.timestampFontSize,
    locationFontSize: CameraDefaults.locationFontSize,
  );

  /// Configuración para scanner (con GPS)
  static const WatermarkConfig scanner = WatermarkConfig(
    showLogo: CameraDefaults.showLogo,
    showTimestamp: CameraDefaults.showTimestamp,
    showLocation: true,
    logoPosition: CameraDefaults.logoPosition,
    timestampPosition: CameraDefaults.timestampPosition,
    locationPosition: CameraDefaults.locationPosition,
    compressionQuality: CameraDefaults.compressionQualityScanner,
    timestampFontSize: FontSize.medium,
    locationFontSize: FontSize.medium,
  );

  /// Configuración con GPS habilitado
  static const WatermarkConfig withGps = WatermarkConfig(
    showLogo: CameraDefaults.showLogo,
    showTimestamp: CameraDefaults.showTimestamp,
    showLocation: true,
    logoPosition: CameraDefaults.logoPosition,
    timestampPosition: CameraDefaults.timestampPosition,
    locationPosition: CameraDefaults.locationPosition,
    compressionQuality: CameraDefaults.compressionQualityDefault,
    timestampFontSize: CameraDefaults.timestampFontSize,
    locationFontSize: CameraDefaults.locationFontSize,
  );

  /// Configuración sin watermark (solo compresión)
  static const WatermarkConfig none = WatermarkConfig(
    showLogo: false,
    showTimestamp: false,
    showLocation: false,
    compressionQuality: CameraDefaults.compressionQualityDefault,
  );

  /// Configuración solo con logo
  static const WatermarkConfig logoOnly = WatermarkConfig(
    showLogo: true,
    showTimestamp: false,
    showLocation: false,
    logoPosition: CameraDefaults.logoPosition,
    compressionQuality: CameraDefaults.compressionQualityDefault,
  );

  /// Configuración solo con timestamp
  static const WatermarkConfig timestampOnly = WatermarkConfig(
    showLogo: false,
    showTimestamp: true,
    showLocation: false,
    timestampPosition: CameraDefaults.timestampPosition,
    compressionQuality: CameraDefaults.compressionQualityDefault,
    timestampFontSize: CameraDefaults.timestampFontSize,
  );
}
