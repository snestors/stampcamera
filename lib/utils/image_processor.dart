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
    this.logoSizeRatio = 0.25,
    this.logoPosition = WatermarkPosition.topRight,
    this.timestampPosition = WatermarkPosition.bottomRight,
    this.locationPosition = WatermarkPosition.bottomRight,
    this.compressionQuality = 90,
    this.locationText,
    this.timestampFontSize = FontSize.large,
    this.locationFontSize = FontSize.large,
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
// SERVICIO DE UBICACIÓN GPS
// ===================================
class LocationService {
  static Future<String?> getCurrentLocationString() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Permisos de ubicación denegados');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permisos de ubicación denegados permanentemente');
        return null;
      }

      // Verificar si el GPS está habilitado
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        debugPrint('⚠️ Servicio de ubicación deshabilitado');
        return null;
      }

      debugPrint('📍 Obteniendo ubicación GPS...');

      // Obtener posición actual con timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 60),
        ),
      );

      debugPrint('✅ GPS obtenido: ${position.latitude}, ${position.longitude}');

      // Intentar obtener dirección legible
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

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

          // Si no hay dirección, usar coordenadas
          if (address.isEmpty) {
            address =
                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          }

          debugPrint('🏠 Dirección obtenida: $address');
          return address;
        }
      } catch (e) {
        debugPrint('⚠️ Error obteniendo dirección: $e');
      }

      // Fallback: usar coordenadas
      final coords =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      debugPrint('📐 Usando coordenadas: $coords');
      return coords;
    } catch (e) {
      debugPrint('❌ Error obteniendo ubicación: $e');
      return null;
    }
  }

  // Método para obtener solo coordenadas (más rápido)
  static Future<String?> getCurrentCoordinates() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) return null;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 60),
        ),
      );

      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (e) {
      debugPrint('❌ Error obteniendo coordenadas: $e');
      return null;
    }
  }

  // Verificar si los permisos están disponibles sin pedirlos
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
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
  static img.BitmapFont getFontForSize(FontSize fontSize) {
    switch (fontSize) {
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
        // Android: DCIM/MiEmpresa
        saveDirectory = Directory('/storage/emulated/0/DCIM/MiEmpresa');
      } else {
        // iOS: Documents
        final appDir = await getApplicationDocumentsDirectory();
        saveDirectory = Directory(path.join(appDir.path, 'MiEmpresa'));
      }

      if (!await saveDirectory.exists()) {
        await saveDirectory.create(recursive: true);
      }

      // Generar nombre único
      final now = DateTime.now();
      final filename = 'doc_${now.millisecondsSinceEpoch}.jpg';
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
  final processed = img.Image.from(image);
  debugPrint("🎨 Aplicando marca de agua...");

  // Aplicar logo si está configurado
  if (config.showLogo && logoBytes != null) {
    _addLogo(processed, logoBytes, config);
  }

  // Aplicar timestamp si está configurado
  if (config.showTimestamp) {
    _addTimestamp(processed, timestamp, config);
  }

  // Aplicar ubicación si está configurada
  if (config.showLocation && config.locationText != null) {
    _addLocation(processed, config.locationText!, config);
  }

  return processed;
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
    case FontSize.small:
      return (text.length * 8).round(); // arial14 es más estrecha
    case FontSize.medium:
      return (text.length * 14).round(); // arial24
    case FontSize.large:
      return (text.length * 28).round(); // arial48
  }
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

  // Dibujar con sombra
  _drawTextWithShadow(
    image,
    timestamp,
    font,
    position.dx.round(),
    position.dy.round(),
    img.ColorRgb8(255, 255, 255),
    img.ColorRgb8(0, 0, 0),
    shadowRadius: 3,
  );
}

void _addLocation(
  img.Image image,
  String locationText,
  WatermarkConfig config,
) {
  // Nota: Los emojis pueden no renderizarse correctamente con las fuentes bitmap
  // Considera usar "GPS: " en lugar de "📍 "
  final text = locationText;

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

  // Dibujar con sombra
  _drawTextWithShadow(
    image,
    text,
    font,
    position.dx.round(),
    position.dy.round(),
    img.ColorRgb8(255, 255, 255),
    img.ColorRgb8(0, 0, 0),
    shadowRadius: 2,
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
  int shadowRadius = 2,
}) {
  // Dibujar sombra
  for (int dx = -shadowRadius; dx <= shadowRadius; dx++) {
    for (int dy = -shadowRadius; dy <= shadowRadius; dy++) {
      if (dx != 0 || dy != 0) {
        img.drawString(
          image,
          text,
          font: font,
          x: x + dx,
          y: y + dy,
          color: shadowColor,
        );
      }
    }
  }

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
