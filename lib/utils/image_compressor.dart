
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Comprime una imagen PNG y la convierte a JPG sin perder calidad excesiva.
/// Solo si la imagen original supera el peso máximo (330 KB).
Future<Uint8List> compressToJpg(Uint8List pngBytes, {int maxSizeKB = 330}) async {
  // Si el PNG ya pesa menos del límite, úsalo tal cual
  if (pngBytes.lengthInBytes <= maxSizeKB * 1024) {
    return pngBytes;
  }

  final originalImage = img.decodeImage(pngBytes);
  if (originalImage == null) {
    throw Exception('No se pudo decodificar la imagen.');
  }

  // No redimensionamos para preservar calidad
  final imageToCompress = originalImage;

  // Compresión controlada
  int quality = 90;
  late Uint8List jpgBytes;
  do {
    jpgBytes = Uint8List.fromList(img.encodeJpg(imageToCompress, quality: quality));
    quality -= 5;
  } while (jpgBytes.lengthInBytes > maxSizeKB * 1024 && quality >= 70);

  return jpgBytes;
}
