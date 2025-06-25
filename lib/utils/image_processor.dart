// utils/image_processor.dart (CÓDIGO COMPLETO FINAL)
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:stampcamera/utils/date_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

// ===================================
// CACHE GLOBAL OPTIMIZADO
// ===================================
ui.Image? _cachedLogo;
Uint8List? _cachedLogoBytes;

Future<void> initImageCache() async {
  if (_cachedLogo != null) return;

  debugPrint('🚀 Inicializando cache de logo...');
  final stopwatch = Stopwatch()..start();

  final byteData = await rootBundle.load('assets/logo.png');
  _cachedLogoBytes = byteData.buffer.asUint8List();

  final codec = await ui.instantiateImageCodec(_cachedLogoBytes!);
  final frame = await codec.getNextFrame();
  _cachedLogo = frame.image;

  stopwatch.stop();
  debugPrint('✅ Logo cacheado en ${stopwatch.elapsedMilliseconds}ms');
}

Future<ui.Image> loadLogoImage() async {
  if (_cachedLogo != null) return _cachedLogo!;
  await initImageCache();
  return _cachedLogo!;
}

Future<void> scanFile(String path) async {
  const channel = MethodChannel('scan_file_channel');
  try {
    await channel.invokeMethod('scanFile', {'path': path});
  } catch (e) {
    debugPrint('❌ Error al forzar escaneo: $e');
  }
}

// ===================================
// FUNCIÓN PRINCIPAL OPTIMIZADA
// ===================================
Future<String> processAndSaveImage(String imagePath) async {
  final stopwatch = Stopwatch()..start();

  try {
    // 1. Pre-cargar logo si no está en cache
    if (_cachedLogo == null || _cachedLogoBytes == null) {
      await initImageCache();
    }

    // 2. Leer imagen solo una vez
    final originalBytes = await File(imagePath).readAsBytes();

    // 3. Procesar en isolate para mejor performance
    final processingData = ProcessingData(
      imageBytes: originalBytes,
      logoBytes: _cachedLogoBytes!,
      timestamp: formattedNow(),
    );

    final result = await compute(_processImageOptimized, processingData);

    // 4. Guardar resultado
    final savedPath = await _saveProcessedImage(result);

    stopwatch.stop();
    debugPrint(
      '✅ Imagen procesada OPTIMIZADA en ${stopwatch.elapsedMilliseconds}ms: $savedPath',
    );
    return savedPath;
  } catch (e) {
    debugPrint('❌ Error procesando imagen: $e');
    rethrow;
  }
}

// ===================================
// CLASES Y FUNCIONES AUXILIARES
// ===================================

class ProcessingData {
  final Uint8List imageBytes;
  final Uint8List logoBytes;
  final String timestamp;

  ProcessingData({
    required this.imageBytes,
    required this.logoBytes,
    required this.timestamp,
  });
}

// Procesamiento optimizado en background isolate
Future<Uint8List> _processImageOptimized(ProcessingData data) async {
  try {
    // 1. Decodificar imagen original
    final originalImage = img.decodeImage(data.imageBytes);
    if (originalImage == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    debugPrint(
      '📷 Imagen original: ${originalImage.width}x${originalImage.height}',
    );

    // 2. Redimensionar solo si es necesario
    final processedImage = _smartResize(originalImage);

    // 3. Cargar y redimensionar logo
    final logoImage = img.decodeImage(data.logoBytes);
    if (logoImage == null) {
      throw Exception('No se pudo cargar el logo');
    }

    // 4. Agregar watermark optimizado
    final finalImage = _addWatermarkOptimized(
      processedImage,
      logoImage,
      data.timestamp,
    );

    // 5. Comprimir de forma inteligente
    final compressedBytes = _compressImage(finalImage);

    return compressedBytes;
  } catch (e) {
    debugPrint('❌ Error en background processing: $e');
    rethrow;
  }
}

// Redimensionamiento inteligente
img.Image _smartResize(img.Image original) {
  const maxDimension = 1600;
  const minQualityDimension = 800;

  final width = original.width;
  final height = original.height;
  final maxSide = width > height ? width : height;

  // No redimensionar si ya está en rango óptimo
  if (maxSide <= maxDimension && maxSide >= minQualityDimension) {
    debugPrint('📏 Tamaño óptimo, sin redimensión necesaria');
    return original;
  }

  // Calcular escala
  double scale;
  if (maxSide > maxDimension) {
    scale = maxDimension / maxSide;
  } else {
    scale = minQualityDimension / maxSide;
  }

  final newWidth = (width * scale).round();
  final newHeight = (height * scale).round();

  debugPrint(
    '📏 Redimensionando a ${newWidth}x$newHeight (factor: ${scale.toStringAsFixed(2)})',
  );

  return img.copyResize(
    original,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.linear,
  );
}

// Watermark SIMPLE con estándar fijo
img.Image _addWatermarkOptimized(
  img.Image original,
  img.Image logo,
  String timestamp,
) {
  final processed = img.Image.from(original);

  // 1. Logo estándar 20% del ancho
  final logoSize = (original.width * 0.20).round();
  final logoResized = img.copyResize(
    logo,
    width: logoSize,
    height: logoSize,
    interpolation: img.Interpolation.cubic,
  );

  // 2. Posición del logo (esquina superior derecha)
  final logoX = original.width - logoResized.width - 30;
  final logoY = 30;

  // 3. Componer logo
  img.compositeImage(
    processed,
    logoResized,
    dstX: logoX,
    dstY: logoY,
    blend: img.BlendMode.alpha,
  );

  // 4. Timestamp ESTÁNDAR con arial48
  final textPadding = -35;
  final textHeight = 48;
  final charWidth = 28.0;
  final textWidth = (timestamp.length * charWidth).round();

  final textX = original.width - textWidth - textPadding;
  final textY = original.height - textHeight;

  // 5. Dibujar sombra negra estándar
  for (int dx = -3; dx <= 3; dx++) {
    for (int dy = -3; dy <= 3; dy++) {
      if (dx != 0 || dy != 0) {
        img.drawString(
          processed,
          timestamp,
          font: img.arial48,
          x: textX + dx,
          y: textY + dy,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
  }

  // 6. Dibujar texto principal blanco
  img.drawString(
    processed,
    timestamp,
    font: img.arial48,
    x: textX,
    y: textY,
    color: img.ColorRgb8(255, 255, 255),
  );

  return processed;
}

// Compresión inteligente
Uint8List _compressImage(img.Image image) {
  final area = image.width * image.height;
  int quality;

  if (area > 2500000) {
    quality = 85;
  } else if (area > 1500000) {
    quality = 90;
  } else {
    quality = 92;
  }

  debugPrint('🗜️ Comprimiendo con calidad $quality% (área: $area pixels)');

  final jpegBytes = img.encodeJpg(image, quality: quality);
  final sizeMB = (jpegBytes.length / 1024 / 1024).toStringAsFixed(2);
  debugPrint('📊 Compresión completada: ${sizeMB}MB');

  return Uint8List.fromList(jpegBytes);
}

// Guardar imagen procesada
Future<String> _saveProcessedImage(Uint8List imageBytes) async {
  final folder = Directory('/storage/emulated/0/DCIM/MiEmpresa');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  final now = DateTime.now();
  final filename = 'doc_${now.millisecondsSinceEpoch}.jpg';
  final filePath = '${folder.path}/$filename';

  final file = File(filePath);
  await file.writeAsBytes(imageBytes);

  unawaited(scanFile(filePath));

  final fileSizeMB = (imageBytes.length / 1024 / 1024).toStringAsFixed(2);
  debugPrint('💾 Archivo guardado: ${fileSizeMB}MB en $filePath');

  return filePath;
}

// Función de inicialización
Future<void> warmUpImageProcessor() async {
  debugPrint('🔥 Calentando procesador de imágenes...');
  await initImageCache();
  debugPrint('✅ Procesador de imágenes listo');
}

void unawaited(Future<void> future) {
  // Helper para evitar warnings
}
