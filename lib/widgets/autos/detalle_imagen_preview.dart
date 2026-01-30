import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stampcamera/widgets/common/fullscreen_image_viewer.dart';

/// Widget para mostrar preview de imagen de red con tap para ver fullscreen
class NetworkImagePreview extends StatelessWidget {
  final String thumbnailUrl;
  final String fullImageUrl;
  final double size;

  const NetworkImagePreview({
    super.key,
    required this.thumbnailUrl,
    required this.fullImageUrl,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FullscreenImageViewer.open(
        context,
        imageUrl: fullImageUrl,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => SizedBox(
            width: size,
            height: size,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) =>
              const Text("Error al cargar imagen"),
        ),
      ),
    );
  }
}
