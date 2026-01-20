// utils/image_processor.dart (VERSIÓN ULTRA-OPTIMIZADA CON CANVAS NATIVO)
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// ===================================
// ENUMS Y CONFIGURACIÓN
// ===================================
enum FontSize {
  auto,
  small,  // 14px
  medium, // 24px
  large,  // 48px
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
// CONFIGURACIÓN PRINCIPAL
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
    this.logoSizeRatio = 0.0,
    this.logoPosition = WatermarkPosition.topRight,
    this.timestampPosition = WatermarkPosition.bottomRight,
    this.locationPosition = WatermarkPosition.bottomRight,
    this.compressionQuality = 100, // Sin pérdida de calidad
    this.locationText,
    this.timestampFontSize = FontSize.auto,
    this.locationFontSize = FontSize.auto,
  });

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
  static String? _cachedLocation;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static const Duration _gpsTimeout = Duration(seconds: 10);

  static Future<String?> getCurrentLocationString({bool useCache = true}) async {
    if (useCache && _isCacheValid()) {
      debugPrint('📍 Usando ubicación cacheada: $_cachedLocation');
      return _cachedLocation;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _cachedLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _cachedLocation;
      }

      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        return _cachedLocation;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _gpsTimeout,
        ),
      );

      String? locationString;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
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
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error obteniendo dirección: $e');
      }

      locationString ??=
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      _updateCache(locationString);
      return locationString;
    } catch (e) {
      debugPrint('❌ Error obteniendo ubicación: $e');
      return _cachedLocation;
    }
  }

  static Future<String?> getCurrentCoordinates({bool useCache = true}) async {
    if (useCache && _isCacheValid()) {
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
          timeLimit: _gpsTimeout,
        ),
      );

      final coords = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      _updateCache(coords);
      return coords;
    } catch (e) {
      return _cachedLocation;
    }
  }

  static Future<void> preloadLocation() async {
    await getCurrentLocationString(useCache: false);
  }

  static bool _isCacheValid() {
    if (_cachedLocation == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }

  static void _updateCache(String location) {
    _cachedLocation = location;
    _cacheTimestamp = DateTime.now();
  }

  static void clearCache() {
    _cachedLocation = null;
    _cacheTimestamp = null;
  }

  static String? getCachedLocation() => _cachedLocation;
}

// ===================================
// CACHE DE RECURSOS
// ===================================
class ImageProcessorCache {
  static final ImageProcessorCache _instance = ImageProcessorCache._internal();
  factory ImageProcessorCache() => _instance;
  ImageProcessorCache._internal();

  ui.Image? _cachedLogo;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  ui.Image? get logo => _cachedLogo;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🚀 Inicializando ImageProcessorCache...');
    final stopwatch = Stopwatch()..start();

    try {
      await _loadLogo();
      _isInitialized = true;
      stopwatch.stop();
      debugPrint('✅ Cache inicializado en ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Error inicializando cache: $e');
    }
  }

  Future<void> _loadLogo() async {
    try {
      final byteData = await rootBundle.load('assets/logo.png');
      final bytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _cachedLogo = frame.image;
      debugPrint('✅ Logo cargado: ${_cachedLogo!.width}x${_cachedLogo!.height}');
    } catch (e) {
      debugPrint('⚠️ Logo no encontrado en assets/logo.png');
    }
  }

  void dispose() {
    _cachedLogo?.dispose();
    _cachedLogo = null;
    _isInitialized = false;
  }
}

// ===================================
// CLASE PRINCIPAL DEL PROCESADOR (CANVAS NATIVO)
// ===================================
class ImageProcessor {
  static final ImageProcessor _instance = ImageProcessor._internal();
  factory ImageProcessor() => _instance;
  ImageProcessor._internal();

  final _cache = ImageProcessorCache();
  final _methodChannel = const MethodChannel('scan_file_channel');

  // Solo redimensionar si la imagen es MÁS GRANDE que esto
  static const int _maxImageSize = 2560; // 2K - mantiene calidad en la mayoría de dispositivos

  Future<void> initialize() async {
    await _cache.initialize();
  }

  /// FLUJO ULTRA-OPTIMIZADO CON CANVAS NATIVO:
  /// 1. Redimensionar con flutter_image_compress (NATIVO)
  /// 2. Decodificar con dart:ui (NATIVO)
  /// 3. Dibujar watermark con Canvas (NATIVO - Skia/Impeller)
  /// 4. Codificar a PNG con dart:ui (NATIVO)
  /// 5. Comprimir a JPEG con flutter_image_compress (NATIVO)
  Future<String> processAndSaveImage(
    String imagePath, {
    WatermarkConfig? config,
    String? customTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final stepwatch = Stopwatch();

    try {
      if (!_cache.isInitialized) {
        await initialize();
      }

      final finalConfig = config ?? const WatermarkConfig();

      // ========== PASO 1: REDIMENSIONAR (NATIVO) ==========
      stepwatch.start();
      final resizedBytes = await _resizeWithNative(imagePath);
      stepwatch.stop();
      debugPrint('⚡ Paso 1 - Redimensionar: ${stepwatch.elapsedMilliseconds}ms');

      // ========== PASO 2: DECODIFICAR CON DART:UI (NATIVO) ==========
      stepwatch.reset();
      stepwatch.start();
      final originalImage = await _decodeImage(resizedBytes);
      stepwatch.stop();
      debugPrint('⚡ Paso 2 - Decodificar: ${stepwatch.elapsedMilliseconds}ms (${originalImage.width}x${originalImage.height})');

      // ========== PASO 3: DIBUJAR WATERMARK CON CANVAS (NATIVO) ==========
      stepwatch.reset();
      stepwatch.start();
      final watermarkedBytes = await _applyWatermarkWithCanvas(
        originalImage,
        customTimestamp ?? _formatTimestamp(),
        finalConfig,
      );
      originalImage.dispose();
      stepwatch.stop();
      debugPrint('⚡ Paso 3 - Watermark (Canvas): ${stepwatch.elapsedMilliseconds}ms');

      // ========== PASO 4: CONVERTIR A JPEG (NATIVO) ==========
      stepwatch.reset();
      stepwatch.start();
      final Uint8List finalBytes;
      if (finalConfig.compressionQuality >= 100) {
        // Sin compresión - convertir PNG a JPEG de alta calidad
        finalBytes = await FlutterImageCompress.compressWithList(
          watermarkedBytes,
          quality: 100,
          format: CompressFormat.jpeg,
        );
        debugPrint('⚡ Paso 4 - Convertir a JPEG (sin compresión): ${stepwatch.elapsedMilliseconds}ms');
      } else {
        finalBytes = await _compressWithNative(
          watermarkedBytes,
          finalConfig.compressionQuality,
        );
        debugPrint('⚡ Paso 4 - Comprimir: ${stepwatch.elapsedMilliseconds}ms');
      }
      stepwatch.stop();

      // ========== PASO 5: GUARDAR ==========
      final savedPath = await _saveProcessedImage(finalBytes);

      stopwatch.stop();
      debugPrint('✅ TOTAL: ${stopwatch.elapsedMilliseconds}ms → $savedPath');
      return savedPath;
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('❌ Error procesando imagen: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Redimensiona usando código nativo SOLO si es necesario
  Future<Uint8List> _resizeWithNative(String imagePath) async {
    final file = File(imagePath);
    final originalBytes = await file.readAsBytes();

    // Decodificar para verificar tamaño
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();

    debugPrint('📷 Original: ${width}x$height (${(originalBytes.length / 1024).toStringAsFixed(0)}KB)');

    // Si la imagen ya es pequeña, no redimensionar (evita degradación)
    if (width <= _maxImageSize && height <= _maxImageSize) {
      debugPrint('✅ No necesita redimensionar');
      return originalBytes;
    }

    // Solo redimensionar si excede el máximo
    debugPrint('📐 Redimensionando a max ${_maxImageSize}px...');
    final result = await FlutterImageCompress.compressWithFile(
      imagePath,
      minWidth: _maxImageSize,
      minHeight: _maxImageSize,
      quality: 95,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('No se pudo redimensionar la imagen');
    }

    debugPrint('📦 Redimensionado: ${(result.length / 1024).toStringAsFixed(0)}KB');
    return result;
  }

  /// Decodifica imagen usando dart:ui (nativo)
  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Aplica watermark usando Canvas nativo (Skia/Impeller)
  Future<Uint8List> _applyWatermarkWithCanvas(
    ui.Image image,
    String timestamp,
    WatermarkConfig config,
  ) async {
    final width = image.width;
    final height = image.height;

    // Crear recorder y canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // Dibujar imagen original
    canvas.drawImage(image, Offset.zero, Paint());

    // Calcular tamaños según resolución
    final fontSize = _calculateFontSize(width, height);
    final logoRatio = _calculateLogoRatio(width);
    final padding = 16.0;

    // Dibujar logo si está configurado
    if (config.showLogo && _cache.logo != null) {
      _drawLogo(canvas, _cache.logo!, width, height, logoRatio, config.logoPosition, padding);
    }

    // Preparar estilo de texto con sombra
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black),
        Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Colors.black54),
      ],
    );

    // Calcular offset para ubicación si está en misma posición que timestamp
    double locationOffset = 0;
    if (config.showLocation &&
        config.locationText != null &&
        config.timestampPosition == config.locationPosition) {
      locationOffset = fontSize + 8;
    }

    // Dibujar timestamp si está configurado
    if (config.showTimestamp) {
      _drawText(
        canvas,
        timestamp,
        textStyle,
        width,
        height,
        config.timestampPosition,
        padding,
        extraOffset: locationOffset,
      );
    }

    // Dibujar ubicación si está configurada
    if (config.showLocation && config.locationText != null) {
      final locationText = _truncateText(config.locationText!, width, fontSize);
      _drawText(
        canvas,
        locationText,
        textStyle,
        width,
        height,
        config.locationPosition,
        padding,
      );
    }

    // Convertir a imagen
    final picture = recorder.endRecording();
    final outputImage = await picture.toImage(width, height);

    // Codificar a PNG (nativo, rápido)
    final byteData = await outputImage.toByteData(format: ui.ImageByteFormat.png);
    outputImage.dispose();
    picture.dispose();

    if (byteData == null) {
      throw Exception('No se pudo codificar la imagen');
    }

    return byteData.buffer.asUint8List();
  }

  /// Dibuja el logo en la posición especificada
  void _drawLogo(
    Canvas canvas,
    ui.Image logo,
    int imageWidth,
    int imageHeight,
    double ratio,
    WatermarkPosition position,
    double padding,
  ) {
    final logoSize = (imageWidth * ratio).round();
    final srcRect = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());

    final offset = _calculateOffset(
      imageWidth,
      imageHeight,
      logoSize,
      logoSize,
      position,
      padding,
    );

    final dstRect = Rect.fromLTWH(offset.dx, offset.dy, logoSize.toDouble(), logoSize.toDouble());

    canvas.drawImageRect(logo, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);
  }

  /// Dibuja texto en la posición especificada
  void _drawText(
    Canvas canvas,
    String text,
    TextStyle style,
    int imageWidth,
    int imageHeight,
    WatermarkPosition position,
    double padding, {
    double extraOffset = 0,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    var offset = _calculateOffset(
      imageWidth,
      imageHeight,
      textPainter.width.round(),
      textPainter.height.round(),
      position,
      padding,
    );

    // Aplicar offset extra para cuando hay múltiples textos en misma posición
    if (extraOffset > 0) {
      final isBottom = position == WatermarkPosition.bottomLeft ||
          position == WatermarkPosition.bottomCenter ||
          position == WatermarkPosition.bottomRight;

      if (isBottom) {
        offset = Offset(offset.dx, offset.dy - extraOffset);
      } else {
        offset = Offset(offset.dx, offset.dy + extraOffset);
      }
    }

    textPainter.paint(canvas, offset);
  }

  /// Calcula la posición del elemento
  Offset _calculateOffset(
    int imageWidth,
    int imageHeight,
    int elementWidth,
    int elementHeight,
    WatermarkPosition position,
    double padding,
  ) {
    switch (position) {
      case WatermarkPosition.topLeft:
        return Offset(padding, padding);
      case WatermarkPosition.topCenter:
        return Offset((imageWidth - elementWidth) / 2, padding);
      case WatermarkPosition.topRight:
        return Offset(imageWidth - elementWidth - padding, padding);
      case WatermarkPosition.leftCenter:
        return Offset(padding, (imageHeight - elementHeight) / 2);
      case WatermarkPosition.center:
        return Offset((imageWidth - elementWidth) / 2, (imageHeight - elementHeight) / 2);
      case WatermarkPosition.rightCenter:
        return Offset(imageWidth - elementWidth - padding, (imageHeight - elementHeight) / 2);
      case WatermarkPosition.bottomLeft:
        return Offset(padding, imageHeight - elementHeight - padding);
      case WatermarkPosition.bottomCenter:
        return Offset((imageWidth - elementWidth) / 2, imageHeight - elementHeight - padding);
      case WatermarkPosition.bottomRight:
        return Offset(imageWidth - elementWidth - padding, imageHeight - elementHeight - padding);
    }
  }

  /// Calcula el tamaño de fuente según resolución
  double _calculateFontSize(int width, int height) {
    final maxDimension = width > height ? width : height;
    if (maxDimension < 1280) {
      return 18.0; // Pequeño
    } else if (maxDimension < 1920) {
      return 24.0; // Mediano
    } else {
      return 32.0; // Grande
    }
  }

  /// Calcula el ratio del logo según resolución
  double _calculateLogoRatio(int width) {
    if (width < 1280) {
      return 0.15;
    } else if (width < 1920) {
      return 0.12;
    } else {
      return 0.10;
    }
  }

  /// Trunca el texto si es muy largo
  String _truncateText(String text, int imageWidth, double fontSize) {
    final maxChars = (imageWidth * 0.4 / (fontSize * 0.6)).round();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars - 3)}...';
  }

  /// Comprime usando código nativo
  Future<Uint8List> _compressWithNative(Uint8List bytes, int quality) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    debugPrint('🗜️ Comprimido: ${(result.length / 1024).toStringAsFixed(0)}KB (quality: $quality)');
    return result;
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

  Future<String> _saveProcessedImage(Uint8List imageBytes) async {
    try {
      Directory saveDirectory;

      if (Platform.isAndroid) {
        saveDirectory = Directory('/storage/emulated/0/DCIM/StampCamera');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        saveDirectory = Directory(path.join(appDir.path, 'StampCamera'));
      }

      if (!await saveDirectory.exists()) {
        await saveDirectory.create(recursive: true);
      }

      final now = DateTime.now();
      final filename = 'IMG_${now.millisecondsSinceEpoch}.jpg';
      final filePath = path.join(saveDirectory.path, filename);

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      if (Platform.isAndroid) {
        _scanFile(filePath);
      }

      final fileSizeMB = (imageBytes.length / 1024 / 1024).toStringAsFixed(2);
      debugPrint('💾 Guardado: ${fileSizeMB}MB → $filePath');

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
// FUNCIONES DE UTILIDAD
// ===================================

Future<void> initializeImageProcessor() async {
  await ImageProcessor().initialize();
}

Future<String> processImageWithWatermark(
  String imagePath, {
  WatermarkConfig? config,
  String? customTimestamp,
  bool autoGPS = false,
}) async {
  WatermarkConfig finalConfig = config ?? const WatermarkConfig();

  if (autoGPS) {
    final gpsLocation = await LocationService.getCurrentLocationString();
    finalConfig = finalConfig.withGPS(gpsLocation);
  }

  return await ImageProcessor().processAndSaveImage(
    imagePath,
    config: finalConfig,
    customTimestamp: customTimestamp,
  );
}

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
