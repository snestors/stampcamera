import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Comprime una imagen PNG y la convierte a JPG con calidad fija del 70%.
Uint8List compressToJpg(Uint8List pngBytes) {
  final originalImage = img.decodeImage(pngBytes);
  if (originalImage == null) {
    throw Exception('No se pudo decodificar la imagen.');
  }

  return Uint8List.fromList(img.encodeJpg(originalImage, quality: 80));
}
