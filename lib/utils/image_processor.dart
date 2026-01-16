// utils/image_processor.dart (VERSIÓN CORREGIDA)
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ===================================
// ENUMS Y CONFIGURACIÓN
// ===================================
enum FontSize {
  auto, // Calcula automáticamente según resolución
  small, // arial14
  medium, // arial24
  large, // arial48
}

enum WatermarkPosition {
  topLeft,
  topCenter,
  topRight,
  leftCenter,
  center,
  rightCenter,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

// ===================================
// CONFIGURACIÓN PRINCIPAL SIMPLIFICADA
// ===================================
class WatermarkConfig {
  final bool showLogo;
  final bool showTimestamp;
  final bool showLocation;
  final double logoSizeRatio;
  final WatermarkPosition logoPosition;
  final WatermarkPosition timestampPosition;
  final WatermarkPosition locationPosition;
  final int compressionQuality;
  final String? locationText;
  final FontSize timestampFontSize;
  final FontSize locationFontSize;

  const WatermarkConfig({
    this.showLogo = true,
    this.showTimestamp = true,
    this.showLocation = false,
    this.logoSizeRatio = 0.0, // 0.0 = auto-calculate based on resolution
    this.logoPosition = WatermarkPosition.topRight,
    this.timestampPosition = WatermarkPosition.bottomRight,
    this.locationPosition = WatermarkPosition.bottomRight,
    this.compressionQuality = 90,
    this.locationText,
    this.timestampFontSize = FontSize.auto, // Auto-calculate based on resolution
    this.locationFontSize = FontSize.auto, // Auto-calculate based on resolution
  });

  // Método para crear una copia con GPS
  WatermarkConfig withGPS(String? gpsLocation) {
    return WatermarkConfig(
      showLogo: showLogo,
      showTimestamp: showTimestamp,
      showLocation: gpsLocation != null,
      logoSizeRatio: logoSizeRatio,
      logoPosition: logoPosition,
      timestampPosition: timestampPosition,
      locationPosition: locationPosition,
      compressionQuality: compressionQuality,
      locationText: gpsLocation,
      timestampFontSize: timestampFontSize,
      locationFontSize: locationFontSize,
    );
  }

  // Método para crear copia con cambios específicos
  WatermarkConfig copyWith({
    bool? showLogo,
    bool? showTimestamp,
    bool? showLocation,
    double? logoSizeRatio,
    WatermarkPosition? logoPosition,
    WatermarkPosition? timestampPosition,
    WatermarkPosition? locationPosition,
    int? compressionQuality,
    String? locationText,
    FontSize? timestampFontSize,
    FontSize? locationFontSize,
  }) {
    return WatermarkConfig(
      showLogo: showLogo ?? this.showLogo,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      showLocation: showLocation ?? this.showLocation,
      logoSizeRatio: logoSizeRatio ?? this.logoSizeRatio,
      logoPosition: logoPosition ?? this.logoPosition,
      timestampPosition: timestampPosition ?? this.timestampPosition,
      locationPosition: locationPosition ?? this.locationPosition,
      compressionQuality: compressionQuality ?? this.compressionQuality,
      locationText: locationText ?? this.locationText,
      timestampFontSize: timestampFontSize ?? this.timestampFontSize,
      locationFontSize: locationFontSize ?? this.locationFontSize,
    );
  }
}

// ===================================
// SERVICIO DE UBICACIÓN GPS CON CACHE
// ===================================
class LocationService {
  // Cache de ubicación para evitar bloqueos
  static String? _cachedLocation;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Timeout reducido para GPS (antes era 60s, ahora 10s)
  static const Duration _gpsTimeout = Duration(seconds: 10);

  /// Obtiene la ubicación usando cache si está disponible y es reciente
  static Future<String?> getCurrentLocationString({bool useCache = true}) async {
    // Verificar cache primero
    if (useCache && _isCacheValid()) {
      debugPrint('📍 Usando ubicación cacheada: $_cachedLocation');
      return _cachedLocation;
    }

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Permisos de ubicación denegados');
          return _cachedLocation; // Retornar cache aunque esté expirado
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permisos de ubicación denegados permanentemente');
        return _cachedLocation;
      }

      // Verificar si el GPS está habilitado
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        debugPrint('⚠️ Servicio de ubicación deshabilitado');
        return _cachedLocation;
      }

      debugPrint('📍 Obteniendo ubicación GPS (timeout: ${_gpsTimeout.inSeconds}s)...');

      // Obtener posición actual con timeout REDUCIDO (10 segundos)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _gpsTimeout,
        ),
      );

      debugPrint('✅ GPS obtenido: ${position.latitude}, ${position.longitude}');

      // Intentar obtener dirección legible
      String? locationString;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5)); // Timeout para geocoding

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          // Formatear dirección de forma inteligente
          String address = '';

          if (place.locality != null && place.locality!.isNotEmpty) {
            address += place.locality!;
          }

          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += place.administrativeArea!;
          }

          if (place.isoCountryCode != null &&
              place.isoCountryCode!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += place.isoCountryCode!;
          }

          if (address.isNotEmpty) {
            locationString = address;
            debugPrint('🏠 Dirección obtenida: $address');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error obteniendo dirección: $e');
      }

      // Fallback: usar coordenadas
      locationString ??=
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      debugPrint('📐 Ubicación final: $locationString');

      // Actualizar cache
      _updateCache(locationString);

      return locationString;
    } catch (e) {
      debugPrint('❌ Error obteniendo ubicación: $e');
      // Retornar cache aunque esté expirado en caso de error
      return _cachedLocation;
    }
  }

  /// Método para obtener solo coordenadas (más rápido)
  static Future<String?> getCurrentCoordinates({bool useCache = true}) async {
    // Verificar cache primero
    if (useCache && _isCacheValid()) {
      debugPrint('📍 Usando coordenadas cacheadas');
      return _cachedLocation;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _cachedLocation;
      }

      if (permission == LocationPermission.deniedForever) return _cachedLocation;

      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) return _cachedLocation;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _gpsTimeout, // Usar timeout reducido
        ),
      );

      final coords = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      _updateCache(coords);
      return coords;
    } catch (e) {
      debugPrint('❌ Error obteniendo coordenadas: $e');
      return _cachedLocation;
    }
  }

  /// Precarga la ubicación en background (llamar al abrir cámara)
  static Future<void> preloadLocation() async {
    debugPrint('🔄 Precargando ubicación en background...');
    await getCurrentLocationString(useCache: false);
  }

  /// Verificar si los permisos están disponibles sin pedirlos
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Verificar si el cache es válido
  static bool _isCacheValid() {
    if (_cachedLocation == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }

  /// Actualizar el cache
  static void _updateCache(String location) {
    _cachedLocation = location;
    _cacheTimestamp = DateTime.now();
    debugPrint('💾 Cache de ubicación actualizado');
  }

  /// Limpiar cache (útil para forzar nueva ubicación)
  static void clearCache() {
    _cachedLocation = null;
    _cacheTimestamp = null;
    debugPrint('🗑️ Cache de ubicación limpiado');
  }

  /// Obtener ubicación cacheada sin intentar obtener nueva
  static String? getCachedLocation() => _cachedLocation;
}

// ===================================
// SINGLETON PARA GESTIÓN DE CACHÉ
// ===================================
class ImageProcessorCache {
  static final ImageProcessorCache _instance = ImageProcessorCache._internal();
  factory ImageProcessorCache() => _instance;
  ImageProcessorCache._internal();

  ui.Image? _cachedLogo;
  Uint8List? _cachedLogoBytes;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🚀 Inicializando ImageProcessorCache...');
    final stopwatch = Stopwatch()..start();

    try {
      // Cargar logo
      await _loadLogo();

      _isInitialized = true;
      stopwatch.stop();
      debugPrint('✅ Cache inicializado en ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Error inicializando cache: $e');
      rethrow;
    }
  }

  Future<void> _loadLogo() async {
    try {
      final byteData = await rootBundle.load('assets/logo.png');
      _cachedLogoBytes = byteData.buffer.asUint8List();

      final codec = await ui.instantiateImageCodec(_cachedLogoBytes!);
      final frame = await codec.getNextFrame();
      _cachedLogo = frame.image;

      debugPrint(
        '✅ Logo cargado: ${_cachedLogo!.width}x${_cachedLogo!.height}',
      );
    } catch (e) {
      debugPrint('⚠️ Logo no encontrado en assets/logo.png');
    }
  }

  ui.Image? get logo => _cachedLogo;
  Uint8List? get logoBytes => _cachedLogoBytes;

  void dispose() {
    _cachedLogo?.dispose();
    _cachedLogo = null;
    _cachedLogoBytes = null;
    _isInitialized = false;
  }
}

// ===================================
// UTILIDAD PARA FUENTES BITMAP
// ===================================
class FontHelper {
  /// Calcula el tamaño de fuente óptimo según la resolución de la imagen
  /// CORREGIDO: Usar fuentes más pequeñas para que no se vean gigantes
  /// - < 1920px: small (14px) - imágenes pequeñas/720p
  /// - 1920-3840px: medium (24px) - Full HD / 2K
  /// - > 3840px: medium (24px) - 4K+ (NO usar large, se ve enorme)
  static FontSize calculateOptimalSize(int imageWidth, int imageHeight) {
    final maxDimension = imageWidth > imageHeight ? imageWidth : imageHeight;

    if (maxDimension < 1920) {
      return FontSize.small; // 14px para imágenes pequeñas
    } else {
      return FontSize.medium; // 24px para HD, 2K y 4K (NO large)
    }
  }

  /// Calcula el ratio del logo según la resolución
  /// CORREGIDO: Logos más pequeños para que no dominen la imagen
  /// - < 1920px: 15% del ancho
  /// - 1920-3840px: 12% del ancho
  /// - > 3840px: 10% del ancho
  static double calculateLogoRatio(int imageWidth) {
    if (imageWidth < 1920) {
      return 0.15; // 15% para imágenes pequeñas
    } else if (imageWidth < 3840) {
      return 0.12; // 12% para Full HD / 2K
    } else {
      return 0.10; // 10% para 4K+
    }
  }

  static img.BitmapFont getFontForSize(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.auto:
        // Default a medium si no se especifica resolución
        return img.arial24;
      case FontSize.small:
        return img.arial14;
      case FontSize.medium:
        return img.arial24;
      case FontSize.large:
        return img.arial48;
    }
  }

  static double getCharacterWidth(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.auto:
        return 18.0; // Default a medium
      case FontSize.small:
        return 12.0; // arial14
      case FontSize.medium:
        return 18.0; // arial24
      case FontSize.large:
        return 32.0; // arial48
    }
  }

  static double getLineHeight(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.auto:
        return 36.0; // Default a medium
      case FontSize.small:
        return 24.0; // arial14
      case FontSize.medium:
        return 36.0; // arial24
      case FontSize.large:
        return 64.0; // arial48
    }
  }
}

// ===================================
// CLASE PRINCIPAL DEL PROCESADOR
// ===================================
class ImageProcessor {
  static final ImageProcessor _instance = ImageProcessor._internal();
  factory ImageProcessor() => _instance;
  ImageProcessor._internal();

  final _cache = ImageProcessorCache();
  final _methodChannel = const MethodChannel('scan_file_channel');

  Future<void> initialize() async {
    await _cache.initialize();
  }

  Future<String> processAndSaveImage(
    String imagePath, {
    WatermarkConfig? config,
    String? customTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Verificar que el cache esté inicializado
      if (!_cache.isInitialized) {
        await initialize();
      }

      // Leer imagen original
      final originalBytes = await File(imagePath).readAsBytes();
      if (originalBytes.isEmpty) {
        throw Exception('Archivo de imagen vacío');
      }

      // Configuración por defecto
      final finalConfig = config ?? const WatermarkConfig();

      // Procesar en isolate
      final processingData = ProcessingData(
        imageBytes: originalBytes,
        logoBytes: _cache.logoBytes,
        timestamp: customTimestamp ?? _formatTimestamp(),
        config: finalConfig,
      );

      final result = await compute(_processImageInIsolate, processingData);

      // Guardar resultado
      final savedPath = await _saveProcessedImage(result, finalConfig);

      stopwatch.stop();
      debugPrint(
        '✅ Imagen procesada en ${stopwatch.elapsedMilliseconds}ms: $savedPath',
      );
      return savedPath;
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Error procesando imagen: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _scanFile(String path) async {
    try {
      await _methodChannel.invokeMethod('scanFile', {'path': path});
      debugPrint('✅ Archivo escaneado: $path');
    } catch (e) {
      debugPrint('⚠️ Error al escanear archivo: $e');
    }
  }

  Future<String> _saveProcessedImage(
    Uint8List imageBytes,
    WatermarkConfig config,
  ) async {
    try {
      // Determinar directorio de guardado
      Directory saveDirectory;

      if (Platform.isAndroid) {
        // Android: DCIM/StampCamera (visible en galería)
        saveDirectory = Directory('/storage/emulated/0/DCIM/StampCamera');
      } else {
        // iOS: Documents
        final appDir = await getApplicationDocumentsDirectory();
        saveDirectory = Directory(path.join(appDir.path, 'StampCamera'));
      }

      if (!await saveDirectory.exists()) {
        await saveDirectory.create(recursive: true);
      }

      // Generar nombre único con prefijo IMG
      final now = DateTime.now();
      final filename = 'IMG_${now.millisecondsSinceEpoch}.jpg';
      final filePath = path.join(saveDirectory.path, filename);

      // Escribir archivo
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Escanear archivo en Android
      if (Platform.isAndroid) {
        unawaited(_scanFile(filePath));
      }

      final fileSizeMB = (imageBytes.length / 1024 / 1024).toStringAsFixed(2);
      debugPrint('💾 Archivo guardado: ${fileSizeMB}MB en $filePath');

      return filePath;
    } catch (e) {
      debugPrint('❌ Error guardando imagen: $e');
      rethrow;
    }
  }

  void dispose() {
    _cache.dispose();
  }
}

// ===================================
// PROCESAMIENTO EN ISOLATE
// ===================================
class ProcessingData {
  final Uint8List imageBytes;
  final Uint8List? logoBytes;
  final String timestamp;
  final WatermarkConfig config;

  ProcessingData({
    required this.imageBytes,
    this.logoBytes,
    required this.timestamp,
    required this.config,
  });
}

Future<Uint8List> _processImageInIsolate(ProcessingData data) async {
  try {
    // 1. Decodificar imagen original
    final originalImage = img.decodeImage(data.imageBytes);
    if (originalImage == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    debugPrint(
      '📷 Procesando imagen: ${originalImage.width}x${originalImage.height}',
    );

    // 2. Aplicar marca de agua
    final watermarkedImage = _applyWatermark(
      originalImage,
      data.logoBytes,
      data.timestamp,
      data.config,
    );

    debugPrint("✅ Marca de agua aplicada");

    // 3. Comprimir
    final compressedBytes = _compressImage(
      watermarkedImage,
      data.config.compressionQuality,
    );

    debugPrint("✅ Compresión completada");
    return compressedBytes;
  } catch (e, stackTrace) {
    debugPrint('❌ Error en isolate: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

img.Image _applyWatermark(
  img.Image image,
  Uint8List? logoBytes,
  String timestamp,
  WatermarkConfig config,
) {
  // OPTIMIZACIÓN: Trabajar directamente sobre la imagen original
  // (no necesitamos la copia, ahorra ~500ms en imágenes 4K)
  debugPrint("🎨 Aplicando marca de agua...");
  debugPrint("📐 Resolución: ${image.width}x${image.height}");

  // Calcular tamaños dinámicos si están en modo auto
  final resolvedConfig = _resolveAutoSizes(config, image.width, image.height);

  // Aplicar logo si está configurado
  if (resolvedConfig.showLogo && logoBytes != null) {
    _addLogo(image, logoBytes, resolvedConfig);
  }

  // Aplicar timestamp si está configurado
  if (resolvedConfig.showTimestamp) {
    _addTimestamp(image, timestamp, resolvedConfig);
  }

  // Aplicar ubicación si está configurada
  if (resolvedConfig.showLocation && resolvedConfig.locationText != null) {
    _addLocation(image, resolvedConfig.locationText!, resolvedConfig);
  }

  return image;
}

/// Resuelve los valores "auto" a valores concretos basados en la resolución
WatermarkConfig _resolveAutoSizes(WatermarkConfig config, int width, int height) {
  // Calcular tamaño de fuente óptimo si está en auto
  FontSize resolvedTimestampSize = config.timestampFontSize;
  FontSize resolvedLocationSize = config.locationFontSize;

  if (config.timestampFontSize == FontSize.auto) {
    resolvedTimestampSize = FontHelper.calculateOptimalSize(width, height);
    debugPrint('📏 Timestamp font auto → ${resolvedTimestampSize.name}');
  }

  if (config.locationFontSize == FontSize.auto) {
    resolvedLocationSize = FontHelper.calculateOptimalSize(width, height);
    debugPrint('📏 Location font auto → ${resolvedLocationSize.name}');
  }

  // Calcular ratio del logo si es 0.0 (auto)
  double resolvedLogoRatio = config.logoSizeRatio;
  if (config.logoSizeRatio <= 0.0) {
    resolvedLogoRatio = FontHelper.calculateLogoRatio(width);
    debugPrint('📏 Logo ratio auto → ${(resolvedLogoRatio * 100).toStringAsFixed(0)}%');
  }

  return config.copyWith(
    timestampFontSize: resolvedTimestampSize,
    locationFontSize: resolvedLocationSize,
    logoSizeRatio: resolvedLogoRatio,
  );
}

void _addLogo(img.Image image, Uint8List logoBytes, WatermarkConfig config) {
  final logoImage = img.decodeImage(logoBytes);
  if (logoImage == null) return;

  // Calcular tamaño del logo
  final logoSize = (image.width * config.logoSizeRatio).round();
  final logoResized = img.copyResize(
    logoImage,
    width: logoSize,
    height: logoSize,
    interpolation: img.Interpolation.cubic,
  );

  // Calcular posición
  final position = _calculatePosition(
    image.width,
    image.height,
    logoResized.width,
    logoResized.height,
    config.logoPosition,
  );

  // Componer logo con transparencia
  img.compositeImage(
    image,
    logoResized,
    dstX: position.dx.round(),
    dstY: position.dy.round(),
    blend: img.BlendMode.alpha,
  );
}

// Helper para calcular el ancho real del texto
int _calculateTextWidth(String text, FontSize fontSize) {
  // Para fuentes monoespaciadas, podemos usar un cálculo más preciso
  // basado en el tamaño real de los caracteres
  switch (fontSize) {
    case FontSize.auto:
      return (text.length * 14).round(); // Default a medium
    case FontSize.small:
      return (text.length * 8).round(); // arial14 es más estrecha
    case FontSize.medium:
      return (text.length * 14).round(); // arial24
    case FontSize.large:
      return (text.length * 28).round(); // arial48
  }
}

/// Trunca el texto si excede el porcentaje máximo del ancho de imagen
/// Por defecto limita al 40% del ancho
String _truncateTextIfNeeded(String text, FontSize fontSize, int imageWidth, {double maxWidthRatio = 0.4}) {
  final maxWidth = (imageWidth * maxWidthRatio).round();
  final textWidth = _calculateTextWidth(text, fontSize);

  if (textWidth <= maxWidth) {
    return text; // No necesita truncar
  }

  // Calcular cuántos caracteres caben
  final charWidth = _calculateTextWidth('A', fontSize);
  final maxChars = (maxWidth / charWidth).floor() - 3; // -3 para "..."

  if (maxChars <= 0) {
    return text; // No truncar si es muy pequeño
  }

  debugPrint('⚠️ Texto truncado de ${text.length} a $maxChars caracteres');
  return '${text.substring(0, maxChars)}...';
}

void _addTimestamp(img.Image image, String timestamp, WatermarkConfig config) {
  // Usar fuente bitmap
  final font = FontHelper.getFontForSize(config.timestampFontSize);
  final lineHeight = FontHelper.getLineHeight(config.timestampFontSize);

  // Calcular ancho real del texto
  final textWidth = _calculateTextWidth(timestamp, config.timestampFontSize);
  final textHeight = lineHeight.round();

  // Calcular posición base
  var position = _calculatePosition(
    image.width,
    image.height,
    textWidth,
    textHeight,
    config.timestampPosition,
    padding: 10,
  );

  // Si hay GPS y ambos están en la misma posición, ajustar el timestamp
  if (config.showLocation &&
      config.locationText != null &&
      config.timestampPosition == config.locationPosition) {
    final locationLineHeight = FontHelper.getLineHeight(
      config.locationFontSize,
    );

    // Determinar si es una posición bottom
    bool isBottomPosition =
        config.timestampPosition == WatermarkPosition.bottomLeft ||
        config.timestampPosition == WatermarkPosition.bottomCenter ||
        config.timestampPosition == WatermarkPosition.bottomRight;

    if (isBottomPosition) {
      // Si están en el bottom, mover el timestamp más arriba
      position = Offset(
        position.dx,
        position.dy - locationLineHeight - 5, // 5px de separación
      );
    } else {
      // Si están en el top, mover el timestamp más abajo
      position = Offset(position.dx, position.dy + locationLineHeight + 5);
    }
  }

  // Dibujar con sombra simple (offset de 2px para legibilidad)
  _drawTextWithShadow(
    image,
    timestamp,
    font,
    position.dx.round(),
    position.dy.round(),
    img.ColorRgb8(255, 255, 255),
    img.ColorRgb8(0, 0, 0),
    shadowOffset: 2,
  );
}

void _addLocation(
  img.Image image,
  String locationText,
  WatermarkConfig config,
) {
  // Nota: Los emojis pueden no renderizarse correctamente con las fuentes bitmap
  // Truncar texto si excede 40% del ancho de imagen
  final text = _truncateTextIfNeeded(
    locationText,
    config.locationFontSize,
    image.width,
  );

  // Usar fuente bitmap
  final font = FontHelper.getFontForSize(config.locationFontSize);
  final lineHeight = FontHelper.getLineHeight(config.locationFontSize);

  // Calcular ancho real del texto
  final textWidth = _calculateTextWidth(text, config.locationFontSize);
  final textHeight = lineHeight.round();

  // Calcular posición con padding de 10px
  var position = _calculatePosition(
    image.width,
    image.height,
    textWidth,
    textHeight,
    config.locationPosition,
    padding: 10,
  );

  // Si el timestamp está visible y en la misma posición, usar la misma X que el timestamp
  if (config.showTimestamp &&
      config.timestampPosition == config.locationPosition) {
    // Calcular la misma X que tendría el timestamp
    final timestampText =
        "00/00/0000 00:00:00"; // Texto de referencia para el ancho
    final timestampWidth = _calculateTextWidth(
      timestampText,
      config.timestampFontSize,
    );

    // Recalcular la posición X usando el ancho del timestamp para mantener alineación
    final timestampPosition = _calculatePosition(
      image.width,
      image.height,
      timestampWidth,
      textHeight,
      config.timestampPosition,
      padding: 10,
    );

    // Usar la misma X que el timestamp
    position = Offset(timestampPosition.dx, position.dy);
  }

  // Dibujar con sombra simple (offset de 2px para legibilidad)
  _drawTextWithShadow(
    image,
    text,
    font,
    position.dx.round(),
    position.dy.round(),
    img.ColorRgb8(255, 255, 255),
    img.ColorRgb8(0, 0, 0),
    shadowOffset: 2,
  );
}

Offset _calculatePosition(
  int imageWidth,
  int imageHeight,
  int elementWidth,
  int elementHeight,
  WatermarkPosition position, {
  int padding = 10,
}) {
  switch (position) {
    case WatermarkPosition.topLeft:
      return Offset(padding.toDouble(), padding.toDouble());
    case WatermarkPosition.topCenter:
      return Offset(
        ((imageWidth - elementWidth) / 2).toDouble(),
        padding.toDouble(),
      );
    case WatermarkPosition.topRight:
      return Offset(
        (imageWidth - elementWidth - padding).toDouble(),
        padding.toDouble(),
      );
    case WatermarkPosition.leftCenter:
      return Offset(
        padding.toDouble(),
        ((imageHeight - elementHeight) / 2).toDouble(),
      );
    case WatermarkPosition.center:
      return Offset(
        ((imageWidth - elementWidth) / 2).toDouble(),
        ((imageHeight - elementHeight) / 2).toDouble(),
      );
    case WatermarkPosition.rightCenter:
      return Offset(
        (imageWidth - elementWidth - padding).toDouble(),
        ((imageHeight - elementHeight) / 2).toDouble(),
      );
    case WatermarkPosition.bottomLeft:
      return Offset(
        padding.toDouble(),
        (imageHeight - elementHeight - padding).toDouble(),
      );
    case WatermarkPosition.bottomCenter:
      return Offset(
        ((imageWidth - elementWidth) / 2).toDouble(),
        (imageHeight - elementHeight - padding).toDouble(),
      );
    case WatermarkPosition.bottomRight:
      return Offset(
        (imageWidth - elementWidth - padding).toDouble(),
        (imageHeight - elementHeight - padding).toDouble(),
      );
  }
}

void _drawTextWithShadow(
  img.Image image,
  String text,
  img.BitmapFont font,
  int x,
  int y,
  img.Color textColor,
  img.Color shadowColor, {
  int shadowOffset = 1,
}) {
  // Sombra simple: solo 1 dibujo con offset (MUCHO más rápido)
  // Antes: dibujaba 48+ veces con radius=3
  // Ahora: solo 1 vez con offset
  img.drawString(
    image,
    text,
    font: font,
    x: x + shadowOffset,
    y: y + shadowOffset,
    color: shadowColor,
  );

  // Dibujar texto principal
  img.drawString(image, text, font: font, x: x, y: y, color: textColor);
}

Uint8List _compressImage(img.Image image, int quality) {
  debugPrint('🗜️ Comprimiendo con calidad $quality%');

  final jpegBytes = img.encodeJpg(image, quality: quality);
  final sizeMB = (jpegBytes.length / 1024 / 1024).toStringAsFixed(2);

  debugPrint('📊 Tamaño final: ${sizeMB}MB');

  return Uint8List.fromList(jpegBytes);
}

// ===================================
// FUNCIONES DE UTILIDAD
// ===================================
void unawaited(Future<void> future) {
  // Helper para evitar warnings de unawaited futures
}

// Función de inicialización global
Future<void> initializeImageProcessor() async {
  await ImageProcessor().initialize();
}

// Función principal de procesamiento con GPS automático
Future<String> processImageWithWatermark(
  String imagePath, {
  WatermarkConfig? config,
  String? customTimestamp,
  bool autoGPS = false,
}) async {
  WatermarkConfig finalConfig = config ?? const WatermarkConfig();

  if (autoGPS) {
    // Obtener GPS y crear configuración con GPS
    final gpsLocation = await LocationService.getCurrentLocationString();
    finalConfig = finalConfig.withGPS(gpsLocation);
  }

  return await ImageProcessor().processAndSaveImage(
    imagePath,
    config: finalConfig,
    customTimestamp: customTimestamp,
  );
}

// Función de procesamiento rápido solo con coordenadas
Future<String> processImageWithCoordinates(
  String imagePath, {
  String? customTimestamp,
}) async {
  final coordinates = await LocationService.getCurrentCoordinates();

  final config = const WatermarkConfig().withGPS(coordinates);

  return await ImageProcessor().processAndSaveImage(
    imagePath,
    config: config,
    customTimestamp: customTimestamp,
  );
}
