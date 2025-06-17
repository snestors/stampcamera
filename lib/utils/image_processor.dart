import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stampcamera/utils/date_formatter.dart';
import 'package:stampcamera/utils/image_compressor.dart';

Future<ui.Image> loadLogoImage() async {
  final byteData = await rootBundle.load('assets/logo.png');
  final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<void> scanFile(String path) async {
  const channel = MethodChannel('scan_file_channel');
  try {
    await channel.invokeMethod('scanFile', {'path': path});
  } catch (e) {
    debugPrint('❌ Error al forzar escaneo: $e');
  }
}

Future<void> processAndSaveImage(String imagePath) async {
  final bytes = await File(imagePath).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final original = frame.image;

  final logo = await loadLogoImage();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  // Dibujar imagen original
  canvas.drawImage(original, Offset.zero, paint);

  // 🔍 Tamaño del logo ajustado (15% más grande)
  const logoSize = 200.0;

  // 🖼 Logo en la esquina superior derecha
  final logoDst = Rect.fromLTWH(
    original.width - logoSize - 10, // derecha
    10,                              // arriba
    logoSize,
    logoSize,
  );
  final logoSrc = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());
  canvas.drawImageRect(logo, logoSrc, logoDst, paint);

  // 🕓 Timestamp en la esquina inferior derecha
  final formattedTime = formattedNow();

  final textPainter = TextPainter(
    text: TextSpan(
      text: formattedTime,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout(maxWidth: original.width.toDouble() - 40);
  final double textWidth = textPainter.width;
  final double textHeight = textPainter.height;

  // Posicionar texto en esquina inferior derecha
  final textOffset = Offset(
    original.width.toDouble() - textWidth - 10,
    original.height.toDouble() - textHeight - 10,
  );

  textPainter.paint(canvas, textOffset);

  final picture = recorder.endRecording();
  final markedImage = await picture.toImage(original.width, original.height);
  final byteData = await markedImage.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Guardar imagen final en galería
  final folder = Directory('/storage/emulated/0/DCIM/MiEmpresa');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  final now = DateTime.now();
  final filename = 'foto_marcada_${now.millisecondsSinceEpoch}.png';
  final filePath = '${folder.path}/$filename';
  final compressedBytes = await compressToJpg(pngBytes);
  final file = File(filePath);
  await file.writeAsBytes(compressedBytes);
  await scanFile(filePath);

  debugPrint('✅ Imagen guardada con logo y timestamp a la derecha: $filePath');
}